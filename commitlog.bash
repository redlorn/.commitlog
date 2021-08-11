#!/bin/bash
set -o errexit -o pipefail -o privileged -o nounset
shopt -s extglob

_gitUser="$(git config --global user.name) $(git config --global user.email)"
_commitUser="$(git log -1 HEAD | head -2 | tail -1 | awk '{print $2 " " substr($3,2,length($3)-2)}')"

[[ "$_gitUser" == "$_commitUser" ]] || {
  echo "skipping commitlog for non-default user"
  exit 0
}

_COMMITLOG_PATH="$HOME/project/.commitlog"

_pwd="$PWD"
_repo="$(git config --get remote.origin.url)"
_branch="$(git branch --show-current)"
_commitid="$(git log -1 HEAD | head -1 | gawk '{print $2}')"
_time="$(date +'%s')"
_relpath="$(date +'./%Y/%m/%d.log.txt')"

_diff="$(git diff --shortstat HEAD~1 HEAD)"
declare -A _diffstats
_diffstats[lines]="$(echo "$_diff" | gawk '{print $1}' || echo '0')"
_diffstats[insertions]="$(echo "$_diff" | grep -oE '([0-9]+) insertion' | grep -oE '([0-9]+)' || echo '0')"
_diffstats[deletions]="$(echo "$_diff" | grep -oE '([0-9]+) deletion' | grep -oE '([0-9]+)' || echo '0')"

cd "$_COMMITLOG_PATH"

git pull --rebase

mkdir -p "$(dirname "$_relpath")"

cat <<HEREDOC >> "$_relpath"
$_repo
$_branch
$_commitid
$_time
${_diffstats[lines]} ${_diffstats[insertions]} ${_diffstats[deletions]}
HEREDOC

git add .
git commit -m "$_repo / $_branch"
git push

cd "$_pwd"