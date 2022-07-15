#!/bin/bash

git tag -d 1.2
git push --delete origin 1.2
git tag 1.2
git push origin 1.2

