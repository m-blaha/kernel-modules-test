#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
project_dir=$(cd -- "$script_dir/.." && pwd)
specs_dir="$project_dir/fixtures/specs"
repos_dir="$project_dir/fixtures/repos"
topdir="$project_dir/fixtures/.rpmbuild"

rm -rf -- "$repos_dir" "$topdir"

while IFS= read -r -d '' spec; do
    repo_name=$(basename -- "$(dirname -- "$spec")")
    repo_dir="$repos_dir/$repo_name"
    mkdir -p -- "$repo_dir"

    rpmbuild --quiet -bb "$spec" \
        --define "_topdir $topdir" \
        --define "_rpmdir $repo_dir"
done < <(find "$specs_dir" -mindepth 2 -maxdepth 2 -name '*.spec' -print0 | sort -z)

while IFS= read -r -d '' repo_dir; do
    createrepo_c --quiet --simple-md-filenames "$repo_dir"
done < <(find "$repos_dir" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

rm -rf -- "$topdir"
