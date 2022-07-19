#!/bin/bash

TAG=0.2.0

git tag -d $TAG
git push --delete origin $TAG
git tag $TAG
git push origin $TAG

