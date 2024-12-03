set positional-arguments := true
set dotenv-load := true

# show recipes
[private]
@help:
    just --list --list-prefix "  "

# tag and optionally push the tag
[group("release")]
release tag push="localonly":
    #!/usr/bin/env bash
    set -eo pipefail

    git diff --quiet || (echo "--> git is dirty" && exit 1)
    tag="{{ tag }}"
    push="{{ push }}"
    git tag "$tag" -m"release: $tag"
    case "$push" in
      push|github)
        git push --all
        git push --tags
        ;;
      *)
        ;;
    esac
