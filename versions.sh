#!/bin/bash
set -euo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
	json='{}'
else
	json="$(< versions.json)"
fi
versions=( "${versions[@]%/}" )

defaultDrushVersion='11.4.0'
declare -A drushVersions=(
	[6]='7.4.0'
	[7]='8.3.2'
	[9.2]='10.3.6'
	[9.3]='10.4.3'
)

for version in "${versions[@]}"; do
	export version

	doc='{}'

	rcGrepV='-v'
	rcVersion="${version%-rc}"
	if [ "$rcVersion" != "$version" ]; then
		rcGrepV=
	fi

	case "$rcVersion" in
		6)
            continue;
			;;
		7)
			# e.g. 7.x
			drupalRelease="${rcVersion%%.*}.x"
			;;
		*)
			# there is no https://updates.drupal.org/release-history/drupal/9.x
			# (07/2020) current could also be used for 8.9, 9.x
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
	if [ -z "$fullVersion" ]; then
		echo >&2 "error: cannot find release for $version"
		exit 1
	fi
	md5="${fullVersion##* }"
	fullVersion="${fullVersion% $md5}"
	if [ -n "$md5" ]; then
		export md5
		doc="$(jq <<<"$doc" -c '.md5 = env.md5')"
	fi

	composerVersion="$(
		wget -qO- "https://github.com/drupal/drupal/raw/$fullVersion/composer.lock" \
			| jq -r '
				(.packages, ."packages-dev")[]
				| select(.name == "composer/composer")
				| .version
				| split(".")[0:1] | join(".")
			' \
			|| :
	)"
	[ "$version" == '7' ] && composerVersion="1"
	if [ "$version" != '7' ] && [ -z "$composerVersion" ]; then
		echo >&2 "error: cannot find composer version for '$version' ('$fullVersion')"
		exit 1
	fi
	if [ -n "$composerVersion" ]; then
		export composerVersion
		doc="$(jq <<<"$doc" -c '.composer = { version: env.composerVersion }')"
	fi

	echo "$version: $fullVersion${composerVersion:+ (composer $composerVersion)}"
	drushVersion=${drushVersions[$version]:-$defaultDrushVersion}
	if [ -n "$drushVersion" ]; then
		export drushVersion
		doc="$(jq <<<"$doc" -c '.drush = { version: env.drushVersion }')"
	fi
	echo "addons: ${drushVersion:+ (drush $drushVersion)}"

	export fullVersion
	json="$(
		jq <<<"$json" -c --argjson doc "$doc" '
			.[env.version] = {
				version: env.fullVersion,
				variants: [
					"bullseye",
					"buster",
					"alpine3.17",
					"alpine3.16"
					| if startswith("alpine") then empty else "apache-" + . end,
						"fpm-" + .
				],
				phpVersions: (
					# https://www.drupal.org/docs/system-requirements/php-requirements
					# https://www.drupal.org/docs/7/system-requirements/php-requirements
					if env.version == "7" then
						[ "8.0" ]
					elif env.version | startswith("9.") then
						[ "8.1", "8.0" ]
					else
						# https://www.drupal.org/node/3264830
						# Require PHP 8.1 for Drupal 10
						[ "8.1" ]
					end
				),
			} + $doc
		'
	)"
done

jq <<<"$json" -S . > versions.json
