#!/bin/bash

git tag -d 2.1
git push --delete origin 2.1
git tag 2.1
git push origin 2.1

