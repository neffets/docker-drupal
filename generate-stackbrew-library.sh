#!/usr/bin/env bash
set -Eeuo pipefail

declare -A aliases=(
	[8.9]='8'
	[9.1]='9 latest'
	[9.2-rc]='rc'
)

defaultDebianSuite='buster'
declare -A debianSuites=(
	#[9.0]='buster'
)
defaultAlpineVersion='3.12'

defaultPhpVersion='php8.0'
declare -A defaultPhpVersions=(
# https://www.drupal.org/docs/7/system-requirements/php-requirements#php_required
	[7]='php7.4'
	[8.9]='php7.4'
	[9.0]='php7.4'
)

self="$(basename "$BASH_SOURCE")"
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

if [ "$#" -eq 0 ]; then
	versions="$(jq -r 'keys | map(@sh) | join(" ")' versions.json)"
	eval "set -- $versions"
fi

# sort version numbers with highest first
IFS=$'\n'; set -- $(sort -rV <<<"$*"); unset IFS

# get the most recent commit which modified any of "$@"
fileCommit() {
	git log -1 --format='format:%H' HEAD -- "$@"
}

# get the most recent commit which modified "$1/Dockerfile" or any file COPY'd from "$1/Dockerfile"
dirCommit() {
	local dir="$1"; shift
	(
		cd "$dir"
		fileCommit \
			Dockerfile \
			$(git show HEAD:./Dockerfile | awk '
				toupper($1) == "COPY" {
					for (i = 2; i < NF; i++) {
						if ($i ~ /^--from=/) {
							next
						}
						print $i
					}
				}
			')
	)
}

gawkParents='
	{ cmd = toupper($1) }
	cmd == "FROM" {
		print $2
		next
	}
	cmd == "COPY" {
		for (i = 2; i < NF; i++) {
			if ($i ~ /^--from=/) {
				gsub(/^--from=/, "", $i)
				print $i
				next
			}
		}
	}
'

getArches() {
	local repo="$1"; shift

	local parentRepoToArchesStr
	parentRepoToArchesStr="$(
		find -name 'Dockerfile' -exec gawk "$gawkParents" '{}' + \
			| sort -u \
			| gawk -v officialImagesUrl='https://github.com/docker-library/official-images/raw/master/library/' '
				$1 !~ /^('"$repo"'|scratch|.*\/.*)(:|$)/ {
					printf "%s%s\n", officialImagesUrl, $1
				}
			' \
			| xargs -r bashbrew cat --format '["{{ .RepoName }}:{{ .TagName }}"]="{{ join " " .TagEntry.Architectures }}"'
	)"
	eval "declare -g -A parentRepoToArches=( $parentRepoToArchesStr )"
}
getArches 'drupal'

cat <<-EOH
# this file is generated via https://github.com/docker-library/drupal/blob/$(fileCommit "$self")/$self

Maintainers: Tianon Gravi <admwiggin@gmail.com> (@tianon),
             Joseph Ferguson <yosifkit@gmail.com> (@yosifkit)
GitRepo: https://github.com/docker-library/drupal.git
EOH

# prints "$2$1$3$1...$N"
join() {
	local sep="$1"; shift
	local out; printf -v out "${sep//%/%%}%s" "$@"
	echo "${out#$sep}"
}

for version; do
	export version

	phpVersions="$(jq -r '.[env.version].phpVersions | map(@sh) | join(" ")' versions.json)"
	eval "phpVersions=( $phpVersions )"
	variants="$(jq -r '.[env.version].variants | map(@sh) | join(" ")' versions.json)"
	eval "variants=( $variants )"

	fullVersion="$(jq -r '.[env.version].version' versions.json)"

	rcVersion="${version%-rc}"
	versionAliases=()
	while [ "$fullVersion" != "$rcVersion" -a "${fullVersion%[.]*}" != "$fullVersion" ]; do
		versionAliases+=( $fullVersion )
		fullVersion="${fullVersion%[.]*}"
	done
	versionAliases+=(
		$version
		${aliases[$version]:-}
	)

	for phpVersion in "${phpVersions[@]}"; do
		phpVersion="php$phpVersion"
		for variant in "${variants[@]}"; do
			dir="$version/$phpVersion/$variant"
			[ -f "$dir/Dockerfile" ] || continue

			commit="$(dirCommit "$dir")"

			phpVersionAliases=( "${versionAliases[@]/%/-$phpVersion}" )
			phpVersionAliases=( "${phpVersionAliases[@]//latest-/}" )

			variantSuffixes=( "$variant" )
			debianSuite="${debianSuites[$version]:-$defaultDebianSuite}"
			case "$variant" in
				*-"$debianSuite") # "-apache-buster", -> "-apache"
					variantSuffixes+=( "${variant%-$debianSuite}" )
					;;
				fpm-"alpine${defaultAlpineVersion}")
					variantSuffixes+=( fpm-alpine )
					;;
			esac
			variantAliases=()
			phpVersionVariantAliases=()
			for variantSuffix in "${variantSuffixes[@]}"; do
				variantAliases+=( "${versionAliases[@]/%/-$variantSuffix}" )
				phpVersionVariantAliases+=( "${phpVersionAliases[@]/%/-$variantSuffix}" )
			done
			variantAliases=( "${variantAliases[@]//latest-/}" )
			phpVersionVariantAliases=( "${phpVersionVariantAliases[@]//latest-/}" )

			fullAliases=()
			fullAliases+=( "${phpVersionVariantAliases[@]}" )
			versionDefaultPhpVersion="${defaultPhpVersions[$version]:-$defaultPhpVersion}"
			if [ "$phpVersion" = "$versionDefaultPhpVersion" ]; then
				fullAliases+=( "${variantAliases[@]}" )
				if [[ "$variant" = apache-* ]]; then
					fullAliases+=( "${versionAliases[@]}" )
					fullAliases+=( "${phpVersionAliases[@]}" )
				fi
			fi

			variantParents="$(gawk "$gawkParents" "$dir/Dockerfile")"
			variantArches=
			for variantParent in $variantParents; do
				parentArches="${parentRepoToArches[$variantParent]:-}"
				if [ -z "$parentArches" ]; then
					continue
				elif [ -z "$variantArches" ]; then
					variantArches="$parentArches"
				else
					variantArches="$(
						comm -12 \
							<(xargs -n1 <<<"$variantArches" | sort -u) \
							<(xargs -n1 <<<"$parentArches" | sort -u)
					)"
				fi
			done

			echo
			cat <<-EOE
				Tags: $(join ', ' "${fullAliases[@]}")
				Architectures: $(join ', ' $variantArches)
				GitCommit: $commit
				Directory: $dir
			EOE
		done
	done
done
