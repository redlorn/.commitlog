#!/bin/bash
set -o errexit -o pipefail -o privileged -o nounset
shopt -s extglob

declare -r _SOURCEBASE="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
declare -r _OPWD="$PWD"

trap_exit () {
  cd "$_OPWD"
}

trap 'trap_exit' EXIT

main () {
  local gitUser commitUser
  gitUser="$(git config --global user.name) $(git config --global user.email)"
  commitUser="$(git log -1 HEAD | head -2 | tail -1 | awk '{print $2 " " substr($3,2,length($3)-2)}')"

  [[ "$gitUser" == "$commitUser" ]] || {
    echo "skipping commitlog for non-default user"
    exit 0
  }

  local repo branch commitid time relpath
  repo="$(git config --get remote.origin.url)"
  branch="$(git branch --show-current)"
  commitid="$(git log -1 HEAD | head -1 | gawk '{print $2}')"
  time="$(date +'%s')"
  relpath="$(date +'./%Y/%m/%d.log.txt')"

  local diff
  diff="$(git diff --shortstat HEAD~1 HEAD)"

  local -A diffstats
  diffstats[lines]="$(echo "$diff" | gawk '{print $1}' || echo '0')"
  diffstats[insertions]="$(echo "$diff" | grep -oE '([0-9]+) insertion' | grep -oE '([0-9]+)' || echo '0')"
  diffstats[deletions]="$(echo "$diff" | grep -oE '([0-9]+) deletion' | grep -oE '([0-9]+)' || echo '0')"

  cd "$_SOURCEBASE"

  git pull --rebase

  mkdir -p "$(dirname "$relpath")"

  cat <<HEREDOC >>"$relpath"
$repo
$branch
$commitid
$time
${diffstats[lines]} ${diffstats[insertions]} ${diffstats[deletions]}
HEREDOC

  git add .
  git commit -m "$repo / $branch"
  git push

  exit 0
}

main "$@"
