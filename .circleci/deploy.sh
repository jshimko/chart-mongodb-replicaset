#!/bin/bash

set -e

# add chart repo (S3 bucket)
helm repo add $CHART_REPO_NAME $CHART_REPO_URL

# build tar of the chart
helm package $CHART_DIR

# update the index file
helm repo index $CHART_DIR --url $CHART_REPO_URL

# deploy to S3 bucket
helm s3 push $CHART_DIR-$CIRCLE_TAG.tgz $CHART_REPO_NAME
