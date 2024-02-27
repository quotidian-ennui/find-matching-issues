#!/usr/bin/env bash
#
# Required Environment variables:
# SEARCH_QUERY: the search query
# OUTPUT_FORMAT: the output format
# GITHUB_TOKEN: the token for gh
# GITHUB_REPO: the repo e.g. quotidian-ennui/find-matching-issues (added to the query) if required.
#
set -euo pipefail

export GH_PAGER="cat"

function query_issues() {
  searchQuery=$(buildQueryString)
  # shellcheck disable=SC2016
  query='query($searchQuery: String!, $endCursor: String) {
  search(first: 100, query: $searchQuery, type: ISSUE, after: $endCursor) {
    pageInfo {
      hasNextPage,
      endCursor
    }
    nodes {
      ... on Issue {
        title
        url
      }
    }
  }
}'
  gh api graphql --paginate -F searchQuery="$searchQuery" --raw-field query="$(internal::compressQuery "$query")"
}

# This is clearly a bout of premature optimisation and saving
# a few newlines & spaces shouldn't be high on anyone's list
function internal::compressQuery() {
  echo "$1" | tr -s ' ' | tr -d '\n'
}

function buildQueryString() {
  if grep -q "repo:" <<< "$SEARCH_QUERY"; then
    echo "$SEARCH_QUERY"
  else
    echo "repo:$GITHUB_REPO $SEARCH_QUERY"
  fi
}

function executeQuery() {
  case "$OUTPUT_FORMAT" in
    simple|raw)
      query_issues | jq -r ".data.search.nodes | .[] | .url"
      ;;
    jsonl)
      query_issues | jq -r -c ".data.search.nodes | .[]"
      ;;
    json)
      # Because pagination we turn it into json lines and
      # reslurp it into a single json array. Probably
      # not efficient.
      query_issues | jq -r -c ".data.search.nodes | .[]" | jq --slurp "."
      ;;
    markdown|list)
      query_issues | jq -r ".data.search.nodes | .[] | \"- [\(.title)](\(.url))\""
      ;;
    *)
      echo "::error::invalid output format: $OUTPUT_FORMAT"
      exit 1
      ;;
  esac
}

OUTPUT_FILE=$(mktemp --tmpdir="${RUNNER_TEMP}" find-matching-issues.XXXXXXXXXX)
echo "path=$OUTPUT_FILE" >> "$GITHUB_OUTPUT"
executeQuery > "$OUTPUT_FILE"
