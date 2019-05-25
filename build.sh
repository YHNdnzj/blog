#!/bin/sh
cd themes/suka
yarn install --production
cd $TRAVIS_BUILD_DIR
hexo clean
hexo generate
