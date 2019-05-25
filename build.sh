#!/bin/sh
cd themes/suka
npm install --production
cd $TRAVIS_BUILD_DIR
hexo clean
hexo generate
