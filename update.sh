#!/bin/bash
set -eo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

# https://www.drupal.org/docs/8/system-requirements/php-requirements#php_required
defaultPhpVersion='7.3'
declare -A phpVersions=(
	# https://www.drupal.org/docs/7/system-requirements/php-requirements#php_required
	#[7]='7.2'
	[6]='5.6'
	[7]='7.2'
	[8.5]='7.2'
	[8.6]='7.2'
	[8.7]='7.3'
	[8.8]='7.3'
	[8.9]='7.3'
	[9.0]='7.4'
)
defaultDrushVersion='10.2.2'
declare -A drushVersions=(
	[6]='7.4.0'
	[7]='8.3.2'
	[8.5]='9.7.2'
	[8.6]='10.2.2'
	[8.7]='10.2.2'
	[8.8]='10.2.2'
	[8.9]='10.2.2'
	[9.0]='10.2.2'
)

for version in "${versions[@]}"; do
	rcGrepV='-v'
	rcVersion="${version%-rc}"
	if [ "$rcVersion" != "$version" ]; then
		rcGrepV=
	fi
    oldVersion=""
    if [ "6" == "$version" ]; then
        fullVersion="6.38"
        md5="2ece34c3bb74e8bff5708593fa83eaac"
        oldVersion="6"
    fi

	case "$rcVersion" in
		6|7|8.*)
			# e.g. 7.x or 8.x
			drupalRelease="${rcVersion%%.*}.x"
			;;
		9.*)
			# there is no https://updates.drupal.org/release-history/drupal/9.x (or 9.0.x)
			# (07/2020) current could also be used for 8.7, 8.8, 8.9, 9.0, 9.1
			drupalRelease='current'
			;;
	esac

	fullVersion="$(
		wget -qO- "https://updates.drupal.org/release-history/drupal/$drupalRelease" \
			| awk -v RS='[<>]' '
					$1 == "release" { release = 1; version = ""; mdhash = ""; tag = ""; next }
					release && $1 ~ /^version|mdhash$/ { tag = $1; next }
					release && tag == "version" { version = $1 }
					release && tag == "mdhash" { mdhash = $1 }
					release { tag = "" }
					release && $1 == "/release" { release = 0; print version, mdhash }
				' \
			| grep -E "^${rcVersion}[. -]" \
			| grep $rcGrepV -E -- '-rc|-beta|-alpha|-dev' \
			| head -1
	)"
    if [ "6" == "$version" ]; then
        fullVersion="6.54 from-git-php72-ready"
    fi
	if [ -z "$fullVersion" ]; then
		#echo >&2 "error: cannot find release for $version"
		#exit 1
		echo "error: cannot find release for $version"
        continue
	fi
	md5="${fullVersion##* }"
	fullVersion="${fullVersion% $md5}"

	echo "$version: $fullVersion ($md5)"

	for variant in fpm-alpine fpm apache; do
		dist='debian'
		if [[ "$variant" = *alpine ]]; then
			dist='alpine'
		fi

		[ -d "$version/$variant/" ] || continue
		(
		#set -x
		sed -r \
			-e 's/%%PHP_VERSION%%/'"${phpVersions[$version]:-$defaultPhpVersion}"'/' \
			-e 's/%%VARIANT%%/'"$variant"'/' \
			-e 's/%%VERSION%%/'"$fullVersion"'/' \
			-e 's/%%MD5%%/'"$md5"'/' \
			-e 's/%%DRUSH_VERSION%%/'"${drushVersions[$version]:-$defaultDrushVersion}"'/' \
		"./Dockerfile$oldVersion-$dist.template" > "$version/$variant/Dockerfile" || echo "Version $version failed"
		)

		travisEnv='\n  - VERSION='"$version"' VARIANT='"$variant$travisEnv"
	done
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml

( grep -v "ENV DRUPAL_VERSION" README.md > README.md.tmp; grep -R -h "ENV DRUPAL_VERSION" */apache/* >> README.md.tmp; mv -f README.md.tmp README.md );

