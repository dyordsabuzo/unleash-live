SCRIPT_DIR=$(dirname "$0")
cd $SCRIPT_DIR/../../infra/auth
TF_WORKSPACE=prod
terraform init -upgrade

# cognito / auth parameters
COGNITO_USER_POOL_ARN=$(terraform output -raw user_pool_arn)
COGNITO_USER_POOL=$(terraform output -raw user_pool_id)
COGNITO_CLIENT_ID=$(terraform output -raw user_pool_client_id)
COGNITO_REGION=$(terraform output -raw cognito_region)

TEST_USER_EMAIL=$(aws ssm get-parameter \
    --name /cognito/testuser/EMAIL --region $COGNITO_REGION \
    --query "Parameter.Value" --with-decryption --output text)

TEST_USER_PASSWORD=$(aws ssm get-parameter \
    --name /cognito/testuser/PASSWORD --region $COGNITO_REGION \
    --query "Parameter.Value" --with-decryption --output text)

export TOKEN=$(aws cognito-idp admin-initiate-auth \
  --user-pool-id $COGNITO_USER_POOL --client-id $COGNITO_CLIENT_ID \
  --auth-flow ADMIN_NO_SRP_AUTH \
  --auth-parameters USERNAME=$TEST_USER_EMAIL,PASSWORD=$TEST_USER_PASSWORD \
  --region $COGNITO_REGION \
  --query "AuthenticationResult.IdToken" --output text)

cd ../compute
TF_WORKSPACE=prod-us
terraform init -upgrade

export BASE_URL=$(terraform output -raw apigw_invoke_url)
export REQUEST_REGION=$(terraform output -raw region)

cd ../../test/k6
k6 run testing.js
