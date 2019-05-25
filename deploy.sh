#!/bin/sh
git config --global user.name "Mike Yuan" 
git config --global user.email "me@yhndnzj.com"
sed -i "s/GH_TOKEN/$GH_TOKEN" _config.yml
git clone https://github.com/YHNdnzj/yhndnzj.github.io.git -b master .deploy_git
hexo deploy
