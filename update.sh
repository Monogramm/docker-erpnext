#!/bin/bash
set -eo pipefail

declare -A base=(
	[debian]='debian'
	[debian-slim]='debian'
	[alpine]='alpine'
)

variants=(
	debian
	debian-slim
	alpine
)


# version_greater_or_equal A B returns whether A >= B
function version_greater_or_equal() {
	[[ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" || "$1" == "$2" ]];
}

min_version=10
dockerLatest='13.0.0-beta.11'
dockerDefaultVariant='alpine'

dockerRepo="monogramm/docker-erpnext"
latests=(
	13.0.0-beta.11
	$( curl -fsSL 'https://api.github.com/repos/frappe/erpnext/tags' |tac|tac| \
	grep -oE '[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+' | \
	sort -urV )
	version-11-hotfix
	10.x.x
	develop
)

# Remove existing images
echo "reset docker images"
rm -rf ./images/
mkdir ./images/

echo "update docker images"
readmeTags=
githubEnv=
travisEnv=
for latest in "${latests[@]}"; do
	version=$(echo "$latest" | cut -d. -f1-2)
	major=$(echo "$latest" | cut -d. -f1-1)
	if [ "$latest" = "version-11-hotfix" ]; then
		version=11.x
		major=11
	fi

	# Only add versions >= "$min_version"
	if version_greater_or_equal "$version" "$min_version"; then

		if [ ! -d "images/$major" ]; then
			# Add GitHub Actions env var
			githubEnv="'$major', $githubEnv"
		fi

		for variant in "${variants[@]}"; do
			# Create the version+variant directory with a Dockerfile.
			dir="images/$major/$variant"
			if [ -d "$dir" ]; then
				continue
			fi
			echo "generating frappe $latest [$major] ($variant)"
			mkdir -p "$dir"

			# Copy the docker files
			for name in redis_cache.conf nginx.conf .env; do
				cp "template/$name" "$dir/$name"
				sed -i \
					-e 's/{{ NGINX_SERVER_NAME }}/localhost/g' \
					"$dir/$name"
			done

			cp "template/docker-compose_mariadb.yml" "$dir/docker-compose.mariadb.yml"
			case $latest in
				10.*|11.*) echo "Postgres not supported for $latest";;
				*) cp "template/docker-compose_postgres.yml" "$dir/docker-compose.postgres.yml";;
			esac

			template="template/Dockerfile.${base[$variant]}.template"
			cp "$template" "$dir/Dockerfile"

			cp "template/.dockerignore" "$dir/.dockerignore"
			cp -r "./template/hooks" "$dir/hooks"
			cp -r "./template/test" "$dir/"
			cp -r "template/docker-compose.test.yml" "$dir/docker-compose.test.yml"

			# Replace the variables.
			if [ "$latest" = "develop" ] || [ "$latest" = "version-11-hotfix" ]; then
				sed -ri -e '
					s/%%VARIANT%%/'"$variant"'/g;
					s/%%VERSION%%/'"$latest"'/g;
					s/%%PIP_VERSION%%/3/g;
					s/%%FRAPPE_VERSION%%/'"$major"'/g;
					s/%%ERPNEXT_VERSION%%/'"$major"'/g;
				' "$dir/Dockerfile" "$dir/test/Dockerfile" "$dir/docker-compose."*.yml
			elif [ "$latest" = "10.x.x" ]; then
				# FIXME https://github.com/frappe/frappe/issues/7737
				sed -ri -e '
					s/%%VARIANT%%/'"$variant"'/g;
					s/%%VERSION%%/'"v$latest"'/g;
					s/%%PIP_VERSION%%//g;
					s/%%FRAPPE_VERSION%%/10/g;
					s/%%ERPNEXT_VERSION%%/10/g;
				' "$dir/Dockerfile" "$dir/test/Dockerfile" "$dir/docker-compose."*.yml
			else
				sed -ri -e '
					s/%%VARIANT%%/'"$variant"'/g;
					s/%%VERSION%%/'"v$latest"'/g;
					s/%%PIP_VERSION%%/3/g;
					s/%%FRAPPE_VERSION%%/'"$major"'/g;
					s/%%ERPNEXT_VERSION%%/'"$major"'/g;
				' "$dir/Dockerfile" "$dir/test/Dockerfile" "$dir/docker-compose."*.yml
			fi

			sed -ri -e '
				s|DOCKER_TAG=.*|DOCKER_TAG='"$version"'|g;
				s|DOCKER_REPO=.*|DOCKER_REPO='"$dockerRepo"'|g;
				' "$dir/hooks/run"

			# Create a list of "alias" tags for DockerHub post_push
			if [ "$version" = "$dockerLatest" ]; then
				if [ "$variant" = "$dockerDefaultVariant" ]; then
					export DOCKER_TAGS="$latest-$variant $version-$variant $major-$variant $variant $latest $version $major latest "
				else
					export DOCKER_TAGS="$latest-$variant $version-$variant $major-$variant $variant "
				fi
			elif [ "$version" = "$latest" ]; then
				if [ "$variant" = "$dockerDefaultVariant" ]; then
					export DOCKER_TAGS="$latest-$variant $latest "
				else
					export DOCKER_TAGS="$latest-$variant "
				fi
			else
				if [ "$variant" = "$dockerDefaultVariant" ]; then
					export DOCKER_TAGS="$latest-$variant $version-$variant $major-$variant $latest $version $major "
				else
					export DOCKER_TAGS="$latest-$variant $version-$variant $major-$variant "
				fi
			fi
			echo "${DOCKER_TAGS} " > "$dir/.dockertags"

			# Add README tags
			readmeTags="$readmeTags\n-   ${DOCKER_TAGS} (\`$dir/Dockerfile\`)"

			# Add Travis-CI env var
			travisEnv='\n  - VERSION='"$major"' VARIANT='"$variant"' DATABASE=mariadb'"$travisEnv"
			case $latest in
				10.*|11.*) echo "Postgres not supported for $latest";;
				*) travisEnv='\n  - VERSION='"$major"' VARIANT='"$variant"' DATABASE=postgres'"$travisEnv";;
			esac

			if [[ $1 == 'build' ]]; then
				tag="$major-$variant"
				echo "Build Dockerfile for ${tag}"
				docker build -t "${dockerRepo}:${tag}" "$dir"
			fi
		done

	fi

done

# update README.md
sed '/^<!-- >Docker Tags -->/,/^<!-- <Docker Tags -->/{/^<!-- >Docker Tags -->/!{/^<!-- <Docker Tags -->/!d}}' README.md > README.md.tmp
sed -e "s|<!-- >Docker Tags -->|<!-- >Docker Tags -->\n$readmeTags\n|g" README.md.tmp > README.md
rm README.md.tmp

# update .github workflows
sed -i -e "s|version: \[.*\]|version: [${githubEnv}]|g" .github/workflows/hooks.yml

# update .travis.yml
travis="$(awk -v 'RS=\n\n' '$1 == "env:" && $2 == "#" && $3 == "Environments" { $0 = "env: # Environments'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
