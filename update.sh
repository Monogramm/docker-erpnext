#!/bin/bash
set -eo pipefail

declare -A base=(
	[stretch]='debian'
	[stretch-slim]='debian'
	[alpine]='alpine'
)

declare -A compose=(
	[stretch]='mariadb'
	[stretch-slim]='mariadb'
	[alpine]='postgres'
)

variants=(
	stretch
	stretch-slim
	alpine
)


# version_greater_or_equal A B returns whether A >= B
function version_greater_or_equal() {
	[[ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" || "$1" == "$2" ]];
}

min_version=10.1

dockerRepo="monogramm/docker-frappe"
latestsFrappe=( $( curl -fsSL 'https://api.github.com/repos/frappe/erpnext/tags' |tac|tac| \
	grep -oE '[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+' | \
	sort -urV ) 10.1.81 )

latestsBench=( 4.1 master )

# Remove existing images
echo "reset docker images"
find ./images -maxdepth 1 -type d -regextype sed -regex '\./images/[[:digit:]]\+\.[[:digit:]]\+' -exec rm -r '{}' \;

echo "update docker images"
travisEnv=
for latest in "${latestsFrappe[@]}"; do
	version=$(echo "$latest" | cut -d. -f1-2)

	# Only add versions >= "$min_version"
	if version_greater_or_equal "$version" "$min_version"; then

		for variant in "${variants[@]}"; do
			# Create the version+variant directory with a Dockerfile.
			dir="images/$version/$variant"
			if [ -d "$dir" ]; then
				continue
			fi
			echo "generating frappe $latest [$version] ($variant)"
			mkdir -p "$dir"

			template="Dockerfile-${base[$variant]}.template"
			cp "$template" "$dir/Dockerfile"

			# Replace the variables.
			sed -ri -e '
				s/%%VARIANT%%/'"$variant"'/g;
				s/%%VERSION%%/'"$latest"'/g;
				s/%%FRAPPE_VERSION%%/'"$version"'/g;
			' "$dir/Dockerfile"

			# Copy the docker files
			for name in nginx.conf .env; do
				cp "docker-$name" "$dir/$name"
				chmod 755 "$dir/$name"
				sed -i \
					-e 's/{{ NGINX_SERVER_NAME }}/localhost/g' \
				"$dir/$name"
			done

			cp ".dockerignore" "$dir/.dockerignore"
			cp "docker-compose_${compose[$variant]}.yml" "$dir/docker-compose.yml"

			travisEnv='\n    - VERSION='"$version"' VARIANT='"$variant$travisEnv"

			if [[ $1 == 'build' ]]; then
				tag="$version-$variant"
				echo "Build Dockerfile for ${tag}"
				docker build -t ${dockerRepo}:${tag} $dir
			fi
		done

	fi

done

# update .travis.yml
travis="$(awk -v 'RS=\n\n' '$1 == "env:" && $2 == "#" && $3 == "Environments" { $0 = "env: # Environments'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
