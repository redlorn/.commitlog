#!/bin/bash
set -o errexit -o pipefail -o privileged -o nounset
shopt -s extglob

_COMMITLOG_PATH="$HOME/project/.commitlog"

_pwd="$PWD"
_repo="$(git config --get remote.origin.url)"
_branch="$(git branch --show-current)"
_commitid="$(git log -1 HEAD | head -1 | awk '{print $2}')"
_time="$(date +'%s')"
_relpath="$(date +'./%Y/%m/%d.txt')"

cd "$_COMMITLOG_PATH"

git pull --rebase

mkdir -p "$(dirname "$_relpath")"

echo "$_repo" >> "$_relpath"
echo "$_branch" >> "$_relpath"
echo "$_commitid" >> "$_relpath"
echo "$_time" >> "$_relpath"

git add .
git commit -m "$_repo / $_branch"
git push

cd "$_pwd"