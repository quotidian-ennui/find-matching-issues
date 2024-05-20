# find-matching-issues

Selects all issues matching a query

## Historical Context

I was just a little bit frustrated by https://github.com/lee-dohm/select-matching-issues not because it doesn't work, but because of the way nodejs pulls the rug from under your feet. When you don't care enough about javascript, even with dependabot helping out you'll just be annoyed by github notifications. The functionality can be replicated using the `gh api graphql`.

> The original is being forced to run with Node16 by github right now, and it is working. However, in a couple of years (maybe not even that, github says something like Oct2024), when Node20 is forced upon us it may stop working because of openssl which eventually leads us to `ERR_OSSL_EVP_UNSUPPORTED`. Upgrading is certainly possible (you would also have to fixup the tests that mock the github API) but honestly I don't enjoy working with node enough to do it.

This scratches my own personal itch around my use-case when searching for issues vis-a-vis json & jsonlines.

## Usage

It goes something like this...

```
- name: Query issues
  id: query_issues
  uses: quotidian-ennui/find-matching-issues@main
  with:
    query: is:issue is:open tfsha:${{ hashFiles('terraform/*.tf') }}
    token: ${{ secrets.GITHUB_TOKEN }}
    format: list
- name: Create issue
  id: create_issue
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    gh issue create -l terraform -F "${{ steps.query_issues.outputs.path }}" -t "Issue List" -R "${{ github.repository }}"
```

## Releases

It's always an explicit semver (v1.0.0 or similar) with no additional convenience tags like `@v1`, `@v1.1`. This isn't because I don't enjoy the convenience that something like `@v1` gives you, but I've seen far too many things _break_ because someone thought things were more compatible than they really were. It's a github action, which means you have access to dependabot, which means this shouldn't be an issue for you.
