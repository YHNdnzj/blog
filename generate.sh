#!/bin/bash -e
(
cd themes/suka
yarn install --production
)
yarn run build
