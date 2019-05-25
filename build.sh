#!/bin/sh
cd themes/suka
yarn install --production
cd $TRAVIS_BUILD_DIR
sed -i'' "/^ *repo/s~github\.com~${GH_TOKEN}@github.com~" _config.yml
hexo clean
hexo generate
