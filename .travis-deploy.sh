#!/bin/bash
git config --global user.name "Mike Yuan" 
git config --global user.email "me@yhndnzj.com"
sed -i "s/GH_TOKEN/$GH_TOKEN/" _config.yml
yarn run deploy
