#!/bin/bash
set -o errexit -o pipefail -o privileged -o nounset
shopt -s extglob

_gitUser="$(git config --global user.name) $(git config --global user.email)"
_commitUser="$(git log -1 HEAD | head -2 | tail -1 | awk '{print $2 " " substr($3,2, length($3)-2)}')"

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
_diffstats="$(git diff --shortstat HEAD HEAD~1 | gawk '{print $1,$4,$6}' | sed -e's/\s*$//g')"
_relpath="$(date +'./%Y/%m/%d.txt')"

cd "$_COMMITLOG_PATH"

git pull --rebase

mkdir -p "$(dirname "$_relpath")"

echo "$_repo" >> "$_relpath"
echo "$_branch" >> "$_relpath"
echo "$_commitid" >> "$_relpath"
echo "$_time" >> "$_relpath"
echo "$_diffstats" >> "$_relpath"

git add .
git commit -m "$_repo / $_branch"
git push

cd "$_pwd"