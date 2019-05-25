#!/bin/sh
cd themes/suka
yarn install --production
cd $TRAVIS_BUILD_DIR
sed -i "s/GH_TOKEN/$GH_TOKEN" _config.yml
hexo clean
hexo generate
