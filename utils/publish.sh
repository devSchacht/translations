#!/bin/bash

USAGE="\nОтправка черновика на Medium
Использование:
$ publish.sh <file> [--token]
где:
    file          Путь к локальному файлу в формате md
    -t, --token   Токен для API Medium.
                  Необязательно, если это не первая публикация через данный скрипт
"

if [ -z $1 ] || [ ! -f $1 ]; then
  printf "$USAGE"
  exit 0
fi

ARTICLE_FILE=$1
REPO_URL="https://github.com/devSchacht/translations/tree/master/"
PUBLISH_COMMAND="markdown-to-medium $ARTICLE_FILE --publication=devSchacht --tags=devschacht"
ARTICLE_FOOTER="[Статья на GitHub]($REPO_URL$ARTICLE_FILE)"

OPTS=$(getopt --o ":t" --long "token:" -- "$@")

eval set -- "$OPTS"

while true ; do
  case "$1" in
    -t | --token ) TOKEN=$2; shift 2;;
    --) shift; break;;
    *) echo Error; exit 1;;
  esac
done

if [ ! -z ${TOKEN} ]; then
  PUBLISH_COMMAND="$PUBLISH_COMMAND --token=$TOKEN"
fi

if [[ $(eval "tail -n 1 $ARTICLE_FILE") != $ARTICLE_FOOTER ]]; then
  printf "\n%s" "$ARTICLE_FOOTER" >> $ARTICLE_FILE
fi

$PUBLISH_COMMAND

git checkout $ARTICLE_FILE
