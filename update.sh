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
dockerLatest='13.0.0-beta.10'

dockerRepo="monogramm/docker-erpnext"
latests=(
	13.0.0-beta.10
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
mkdir -p ./images

echo "update docker images"
travisEnv=
for latest in "${latests[@]}"; do
	version=$(echo "$latest" | cut -d. -f1-2)
	major=$(echo "$latest" | cut -d. -f1-1)
	if [ "$latest" = "version-11-hotfix" ]; then
		major=11
	fi

	# Only add versions >= "$min_version"
	if version_greater_or_equal "$version" "$min_version"; then

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

			# Create a list of "alias" tags for DockerHub post_push
			if [ "$latest" = 'develop' ]; then
				if [ "$variant" = 'alpine' ]; then
					echo "develop-$variant develop " > "$dir/.dockertags"
				else
					echo "develop-$variant " > "$dir/.dockertags"
				fi
			elif [ "$latest" = 'version-11-hotfix' ]; then
				if [ "$variant" = 'alpine' ]; then
					echo "11-$variant 11 " > "$dir/.dockertags"
				else
					echo "11-$variant " > "$dir/.dockertags"
				fi
			elif [ "$latest" = "$dockerLatest" ]; then
				if [ "$variant" = 'alpine' ]; then
					echo "$latest-$variant $version-$variant $major-$variant $variant $latest $version $major " > "$dir/.dockertags"
				else
					echo "$latest-$variant $version-$variant $major-$variant $variant " > "$dir/.dockertags"
				fi
			else
				if [ "$variant" = 'alpine' ]; then
					echo "$latest-$variant $version-$variant $major-$variant $latest $version $major " > "$dir/.dockertags"
				else
					echo "$latest-$variant $version-$variant $major-$variant " > "$dir/.dockertags"
				fi
			fi

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

# update .travis.yml
travis="$(awk -v 'RS=\n\n' '$1 == "env:" && $2 == "#" && $3 == "Environments" { $0 = "env: # Environments'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
