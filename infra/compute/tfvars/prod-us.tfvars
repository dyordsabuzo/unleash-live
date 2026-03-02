region                = "us-east-1"
environment           = "prod-us"
cognito_user_pool_arn = "arn:aws:cognito-idp:us-east-1:231585964142:userpool/us-east-1_fV92ey3vF"
dynamodb_table_name   = "GreetingLogs"

# TODO: Replace this with the actual SNS topic from Unleash
sns_topic_arn = "arn:aws:sns:us-east-1:231585964142:my-sns-topic"
