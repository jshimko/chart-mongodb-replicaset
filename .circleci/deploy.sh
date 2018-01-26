#!/bin/bash

set -e

# add Launchdock chart repo (S3 bucket)
helm repo add launchdock s3://charts.launchdock.io/stable

# build tar of the chart
helm package $CHART_DIR

# update the index file
helm repo index $CHART_DIR --url s3://charts.launchdock.io/stable

# deploy to S3 bucket
helm s3 push $CHART_DIR-$CIRCLE_TAG.tgz launchdock
