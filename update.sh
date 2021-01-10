#!/bin/bash
set -euo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

# https://www.drupal.org/docs/8/system-requirements/php-requirements#php_required
defaultPhpVersion='8.0'
declare -A phpVersions=(
	# https://www.drupal.org/docs/7/system-requirements/php-requirements#php_required
	#[7]='7.4'
	[6]='5.6'
	[7]='7.2'
	[8.6]='7.2'
	[8.7]='7.3'
	[8.8]='7.3'
	[8.9]='7.3'
	[9.0]='7.4'
	[9.1]='8.0'
)
defaultDrushVersion='10.3.6'
declare -A drushVersions=(
	[6]='7.4.0'
	[7]='8.3.2'
	[8.6]='10.2.2'
	[8.7]='10.2.2'
	[8.8]='10.2.2'
	[8.9]='10.3.6'
	[9.0]='10.3.6'
	[9.1]='10.3.6'
)

defaultComposerVersion='1.10'
declare -A composerVersions=(
	[8.9]='1.10' # https://github.com/drupal/drupal/blob/8.9.12/composer.lock#L4357-L4358
	[9.0]='1.10' # https://github.com/drupal/drupal/blob/9.0.10/composer.lock#L4448-L4449
	[9.1]='2.0' # https://github.com/drupal/drupal/blob/9.1.2/composer.lock#L4730-L4731
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

	for variant in {apache,fpm}-buster fpm-alpine3.12 apache; do
		[ -e "$version/$variant" ] || continue
		dist='debian'
		if [[ "$variant" = *alpine* ]]; then
			dist='alpine'
		fi

		phpImage="${phpVersions[$version]:-$defaultPhpVersion}-$variant"
		sedArgs=(
			-e 's/%%PHP_VERSION%%/'"${phpImage}"'/'
			-e 's/%%VERSION%%/'"$fullVersion"'/'
			-e 's/%%MD5%%/'"$md5"'/'
			-e 's/%%DRUSH_VERSION%%/'"${drushVersions[$version]:-$defaultDrushVersion}"'/'
		)

		template="Dockerfile-$dist.template"
        case "$version" in
			# 6|7|<=8.7 has no release in drupal/recommended-project
			# so its Dockerfile is based on the old template
		    6|7 )
				template="Dockerfile-${version}-$dist.template"
				;;
            "8.6" | "8.7" )
				template="Dockerfile-8-$dist.template"
				;;
            * )
				composerVersion="${composerVersions[$version]:-$defaultComposerVersion}"
				sedArgs+=( -e 's/%%COMPOSER_VERSION%%/'"$composerVersion"'/' )
                ;;
        esac

		sed -r "${sedArgs[@]}" "$template" > "$version/$variant/Dockerfile"
	done
done

( grep -v "ENV DRUPAL_VERSION" README.md > README.md.tmp; grep -R -h "ENV DRUPAL_VERSION" */apache*/* >> README.md.tmp; mv -f README.md.tmp README.md );

