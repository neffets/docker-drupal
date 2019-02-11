#!/bin/bash
set -eo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

defaultPhpVersion='7.2'
declare -A phpVersions=(
	[6]='5.6'
	[7]='7.0'
	[8.3]='7.1'
	[8.4]='7.1'
	[8.5]='7.2'
	[8.6]='7.2'
)
defaultDrushVersion='7.4.0'
declare -A drushVersions=(
	[6]='6.7.0'
	[7]='7.4.0'
	[8.5]='8.1.18'
	[8.6]='8.1.18'
)

curl -o release -fsSL 'https://www.drupal.org/node/3060/release' -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:63.0) Gecko/20100101 Firefox/63.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Accept-Language: de-DE,eo;q=0.8,de;q=0.6,en-US;q=0.4,en;q=0.2'
trap 'rm -f release' EXIT

travisEnv=
for version in "${versions[@]}"; do
	rcGrepV='-v'
	rcVersion="${version%-rc}"
	if [ "$rcVersion" != "$version" ]; then
		rcGrepV=
	fi
    oldVersion=""
    drushVersion=""
    if [ "6" == "$version" ]; then
        fullVersion="6.38"
        md5="2ece34c3bb74e8bff5708593fa83eaac"
        oldVersion="6"
    else
	  fullVersion="$(
		grep -E '>drupal-'"$rcVersion"'\.[0-9a-z.-]+\.tar\.gz<' release \
			| sed -r 's!.*<a[^>]+>drupal-([^<]+)\.tar\.gz</a>.*!\1!' \
			| grep $rcGrepV -E -- '-rc|-beta|-alpha|-dev' \
			| head -1
	  )"
	  if [ -z "$fullVersion" ]; then
		echo >&2 "error: cannot find release for $version"
		exit 1
	  fi
	  md5="$(grep -A6 -m1 '>drupal-'"$fullVersion"'.tar.gz<' release | grep -A1 -m1 '"md5 hash"' | tail -1 | awk '{ print $1 }')"
    fi
    # old drupal - old drush
    if [ "7" == "$version" ]; then
        drushVersion="7.4.0"
    fi


	#for variant in fpm-alpine fpm apache; do
	for variant in apache; do
		dist='debian'
		if [[ "$variant" = *alpine ]]; then
			dist='alpine'
		fi

		(
			set -x
			sed -r \
				-e 's/%%PHP_VERSION%%/'"${phpVersions[$version]:-$defaultPhpVersion}"'/' \
				-e 's/%%VARIANT%%/'"$variant"'/' \
				-e 's/%%VERSION%%/'"$fullVersion"'/' \
				-e 's/%%MD5%%/'"$md5"'/' \
				-e 's/%%DRUSH_VERSION%%/'"${drushVersions[$version]:-$defaultDrushVersion}"'/' \
			"./Dockerfile$oldVersion-$dist.template" > "$version/$variant/Dockerfile"
		)

		travisEnv='\n  - VERSION='"$version"' VARIANT='"$variant$travisEnv"
	done
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
