#!/bin/bash

set -x -e
# set -x echo all commands
# set -e immediatelly stop script

# DEVELOPMENT ALIAS VERSION

aws lambda get-alias \
  --function-name $DEPLOY_FUNCTION_NAME \
  --name $DEPLOY_ALIAS_NAME \
  > output.json
DEVELOPMENT_ALIAS_VERSION=$(cat output.json | jq -r '.FunctionVersion')

aws lambda publish-version \
  --function-name $DEPLOY_FUNCTION_NAME

#LATEST_VERSION=$((DEVELOPMENT_ALIAS_VERSION + 1))

cat > $DEPLOY_APPSPEC_FILE <<- EOM
version: 0.0
Resources:
  - myLambdaFunction:
      Type: AWS::Lambda::Function
	  Properties:
	    Name: "$DEPLOY_FUNCTION_NAME"
		Alias: "$DEPLOY_ALIAS_NAME"
		CurrentVersion: "$DEVELOPMENT_ALIAS_VERSION"
		TargetVersion: "$LATEST_VERSION"
EOM

aws s3 cp \
	$DEPLOY_APPSPEC_FILE \
	s3://$DEPLOY_BUCKET_NAME/$DEPLOY_APPSPEC_FILE

export REVISION="revisionType=S3,s3Location{bucket=$DEPLOY_BUCKET_NAME,key=$DEPLOY_BUCKET_NAME/$DEPLOY_APPSPEC_FILE,bundleType=YAML}"

aws deploy create-deployment \
    --application-name=$DEPLOY_APPLICATION_NAME \
    --deployment-group-name=$DEPLOYMENT_GROUP_NAME \ 
    --revision=$REVISION \
    --deployment-config-name='CodeDeployDefault.LambdaCanary10Percent1Minutes'