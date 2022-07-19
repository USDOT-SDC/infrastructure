#!/bin/bash

# https://stackoverflow.com/questions/59895/how-can-i-get-the-source-directory-of-a-bash-script-from-within-the-script-itsel
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# /python/lib/python3.7/site-packages

ZIP_FILE=log4sdc-common.zip
LAMBDA_LAYER=log4sdc
WORK_DIR=$SCRIPT_DIR

# replace with the actual bucket name for deployment
S3_LAMBDA_BUCKET=${S3_LAMBDA_BUCKET}

#echo zip -r $WORK_DIR/log4sdc.zip $WORK_DIR/src/*

CURR_DIR=`pwd`

rm -f $WORK_DIR/$ZIP_FILE
rm -rf $WORK_DIR/python
mkdir -p $WORK_DIR/python/lib/python3.7/site-packages 
mkdir -p $WORK_DIR/python/lib/python3.8/site-packages 
mkdir -p $WORK_DIR/python/lib/python3.9/site-packages 
cp -R $WORK_DIR/../src/* $WORK_DIR/python/lib/python3.7/site-packages
cp -R $WORK_DIR/../src/* $WORK_DIR/python/lib/python3.8/site-packages
cp -R $WORK_DIR/../src/* $WORK_DIR/python/lib/python3.9/site-packages


cd $WORK_DIR/package
#zip -r $WORK_DIR/$ZIP_FILE .

cd $WORK_DIR/src/
zip -r $WORK_DIR/$ZIP_FILE python

cd $CURR_DIR

aws s3 cp $WORK_DIR/$ZIP_FILE s3://$S3_LAMBDA_BUCKET/log4sdc/ --sse
echo https://s3.amazonaws.com/$S3_LAMBDA_BUCKET/log4sdc/$ZIP_FILE

###aws lambda update-function-code --function-name  $LAMBDA_LAYER --zip-file fileb://$WORK_DIR/$ZIP_FILE
#aws lambda update-function-code --function-name  v-test --zip-file https://s3.amazonaws.com/$S3_LAMBDA_BUCKET/log4sdc/log4sdc.zip

aws lambda publish-layer-version \
    --layer-name $LAMBDA_LAYER \
    --description "$LAMBDA_LAYER" \
    --content S3Bucket=$S3_LAMBDA_BUCKET,S3Key=log4sdc/$ZIP_FILE \
    --compatible-runtimes python3.7 python3.8 python3.9

