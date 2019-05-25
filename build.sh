#!/bin/sh
yarn install
cd themes/suka
yarn install --production
cd $TRAVIS_BUILD_DIR
hexo clean
