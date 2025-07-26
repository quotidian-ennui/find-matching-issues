set positional-arguments := true
set dotenv-load := true
set unstable := true
set script-interpreter := ['/usr/bin/env', 'bash']

# show recipes
[private]
@help:
    just --list --list-prefix "  "

[doc("Show next version as proposed by git-semver")]
[group("release")]
[script]
next:
    #
    set -eo pipefail

    bumpMinor() {
      local version="$1"
      local majorVersion
      local minorVersion
      majorVersion=$(echo "$version " | sed -E 's#^([0-9]+)\.([0-9]+)\.([0-9]+).*$#\1#')
      minorVersion=$(echo "$version " | sed -E 's#^([0-9]+)\.([0-9]+)\.([0-9]+).*$#\2#')
      minorVersion=$((minorVersion + 1))
      echo "$majorVersion.$minorVersion.0"
    }

    bumpPatch() {
      local version="$1"
      local majorVersion
      local minorVersion
      local patchVersion

      majorVersion=$(echo "$version" | sed -E 's#^([0-9]+)\.([0-9]+)\.([0-9]+).*$#\1#')
      minorVersion=$(echo "$version" | sed -E 's#^([0-9]+)\.([0-9]+)\.([0-9]+).*$#\2#')
      patchVersion=$(echo "$version" | sed -E 's#^([0-9]+)\.([0-9]+)\.([0-9]+).*$#\3#')
      patchVersion=$((patchVersion + 1))
      echo "$majorVersion.$minorVersion.$patchVersion"
    }

    lastTag=$(git tag -l | sort -rV | head -n1)
    lastTaggedVersion=${lastTag#"v"}
    majorVersion=$(echo "$lastTaggedVersion" | sed -E 's#^([0-9]+)\.([0-9]+)\.([0-9]+).*$#\1#')
    semver_arg=""
    if [[ -z "$majorVersion" || "$majorVersion" = "0" ]]; then
      semver_arg="--stable=false"
    fi

    # git semver only works if this branch has the latest tag in its history.
    # FATA[0000] Latest tag is not on HEAD...
    computedVersion=$(git semver next "$semver_arg" 2>/dev/null || true)
    if [[ -n "$computedVersion" ]]; then
      if [[ "$computedVersion" == "$lastTaggedVersion" ]]; then
        bumpMinor "$lastTaggedVersion"
      else
        echo "$computedVersion"
      fi
    else
      closestAncestorTag=$(git describe --abbrev=0)
      closestTagVersion=${closestAncestorTag#"v"}
      bumpPatch "$closestTagVersion"
    fi

[doc('auto-generate tag and release')]
[group("release")]
[script]
autotag push="localonly":
    #
    set -eo pipefail

    next="$(just next)"
    just release $next "{{ push }}"

# tag and optionally push the tag
[group("release")]
[script]
release tag push="localonly":
    #
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
