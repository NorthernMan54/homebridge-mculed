#! /bin/sh

if ~/npm/bin/nsp check --filter 2; then
  rm *orig* *toc\.* lua/*orig* lua/*toc\.*
  npm run-script document
  git add .
  git commit -m "$1"
  npm version patch
  npm publish
  git commit -m "$1"
  git push origin master --tags
else
  echo "Not publishing due to security vulnerabilites"
fi
