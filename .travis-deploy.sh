#!/bin/bash
git config --global user.name "Mike Yuan" 
git config --global user.email "me@yhndnzj.com"
git clone https://github.com/YHNdnzj/yhndnzj.github.io.git -b master .deploy_git
sed -i "s/GH_TOKEN/$GH_TOKEN/" _config.yml
hexo deploy
