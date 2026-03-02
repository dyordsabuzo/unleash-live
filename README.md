


# Assumptions

### TF State management

# Adjustments i have done

### request for quota increase on API GW timeout


# Questions

### processing time

handling it using callback

### The use of dynamodb

Is this necessary?  If the intention is to capture log entries for when the lambda function is invoked, wouldn't dynamodb be redudant since the lambda function already has access to the log stream?


``` bash
cd infra/auth

export TF_WORKSPACE=prod
terraform init -upgrade
terraform plan -var-file=tfvars/$TF_WORKSPACE.tfvars -out tfplan
terraform apply tfplan

# cognito / auth parameters
COGNITO_USER_POOL_ARN=$(terraform output -raw user_pool_arn)
COGNITO_USER_POOL=$(terraform output -raw user_pool_id)
COGNITO_CLIENT_ID=$(terraform output -raw user_pool_client_id)
COGNITO_REGION=$(terraform output -raw cognito_region)

# test user
TEST_USER_EMAIL=$(aws ssm get-parameter \
    --name /cognito/testuser/EMAIL --region $COGNITO_REGION \
    --query "Parameter.Value" --with-decryption --output text)
    
TEST_USER_PASSWORD=$(aws ssm get-parameter \
    --name /cognito/testuser/PASSWORD --region $COGNITO_REGION \
    --query "Parameter.Value" --with-decryption --output text)

cd infra/compute
export TF_WORKSPACE=prod-us
terraform init -upgrade
terraform plan -var-file=tfvars/$TF_WORKSPACE.tfvars \
    -var "cognito_user_pool_arn=$COGNITO_USER_POOL_ARN" \
    -out tfplan
terraform apply tfplan

APIGW_INVOKE_URL=$(terraform output -raw apigw_invoke_url)

# cognito IdToken
COGNITO_TOKEN=$(aws cognito-idp admin-initiate-auth \
  --user-pool-id $COGNITO_USER_POOL --client-id $COGNITO_CLIENT_ID \
  --auth-flow ADMIN_NO_SRP_AUTH \
  --auth-parameters USERNAME=$TEST_USER_EMAIL,PASSWORD=$TEST_USER_PASSWORD \
  --region $COGNITO_REGION \
  --query "AuthenticationResult.IdToken" --output text)
  
# api test - greeter
http GET $APIGW_INVOKE_URL/greet Authorization:"Bearer $COGNITO_TOKEN"

# api test - dispatcher
http POST $APIGW_INVOKE_URL/dispatch Authorization:"Bearer $COGNITO_TOKEN"

``




### deployment permission

permission to ssm parameter record /cognito/testuser/PASSWORD
