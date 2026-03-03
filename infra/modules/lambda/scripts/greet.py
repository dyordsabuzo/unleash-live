import datetime
import json
import logging
import os
import uuid

import boto3  # type: ignore
from botocore.exceptions import BotoCoreError, ClientError  # type: ignore

# Configure logger using LOGLEVEL env var (defaults to DEBUG)
logger = logging.getLogger()
loglevel_env = os.environ.get("LOGLEVEL", "DEBUG")
logger.setLevel(getattr(logging, loglevel_env.upper(), logging.DEBUG))

# Region and AWS clients/resources will use the Lambda execution role (no credentials in code)
_AWS_REGION = os.environ.get("AWS_REGION")


def publish_to_sns(payload):
    sns_topic_arn = os.environ.get(
        "SNS_TOPIC_ARN"
    )  # no default; if unset we'll skip SNS publish

    if sns_topic_arn:
        try:
            message = json.dumps(payload)
            logger.debug(f"Publishing message to SNS topic {sns_topic_arn}: {message}")
            sns_client = (
                boto3.client("sns", region_name=_AWS_REGION)
                if _AWS_REGION
                else boto3.client("sns")
            )
            resp = sns_client.publish(
                TopicArn=sns_topic_arn,
                Message=message,
                Subject="Greeting",
            )

            # Log and return the publish response so caller can verify MessageId
            message_id = resp.get("MessageId") if isinstance(resp, dict) else None
            if message_id:
                logger.info(
                    f"Successfully published greeting payload to SNS topic {sns_topic_arn}, MessageId={message_id}"
                )
            else:
                logger.warning(f"Published to SNS but no MessageId returned: {resp}")

            return resp
        except (BotoCoreError, ClientError) as sns_err:
            logger.exception(
                f"Failed to publish to SNS topic {sns_topic_arn}: {str(sns_err)}"
            )
            raise
    else:
        logger.error("SNS_TOPIC_ARN not set")
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(
                {
                    "message": "Internal Server Error",
                    "region": _AWS_REGION,
                }
            ),
        }


def write_to_dynamodb(payload):
    table_name = os.environ.get("DYNAMODB_TABLE_NAME", "GreetingLogs")
    try:
        dynamodb_client = (
            boto3.resource("dynamodb", region_name=_AWS_REGION)
            if _AWS_REGION
            else boto3.resource("dynamodb")
        )
        table = dynamodb_client.Table(table_name)
        item = {
            "id": str(uuid.uuid4()),
            "email": payload.get("email"),
            "repo": payload.get("repo"),
            "source": payload.get("source"),
            "region": payload.get("region"),
            "created_at": datetime.datetime.utcnow().isoformat() + "Z",
        }
        logger.debug(f"Putting item into DynamoDB table {table_name}: {item}")
        table.put_item(Item=item)
        logger.info(
            f"Successfully wrote greeting log with id={item['id']} to {table_name}"
        )
    except (BotoCoreError, ClientError) as ddb_err:
        # Log but continue or decide to fail - here we fail the invocation because persisting the log is important
        logger.exception(
            f"Failed to write to DynamoDB table {table_name}: {str(ddb_err)}"
        )
        raise


def handler(event, context):
    logger.debug(f"Event received: {json.dumps(event)}")

    payload = {
        "email": os.environ.get("UNLEASH_CANDIDATE_EMAIL"),
        "source": "Lambda",
        "region": _AWS_REGION,
        "repo": os.environ.get("UNLEASH_CANDIDATE_REPO"),
    }

    logger.debug(f"Payload: {payload}")
    try:
        # 1) Write a record to DynamoDB table `GreetingLogs` (or the table specified in DDB_TABLE_NAME)
        write_to_dynamodb(payload)

        # 2) Publish a JSON payload to SNS topic if configured and capture response
        sns_resp = publish_to_sns(payload)

        # Prepare response body including SNS MessageId when available for verification
        response_body = {
            "message": "Lambda Greet completed successfully!",
            "region": _AWS_REGION,
        }
        if sns_resp and isinstance(sns_resp, dict):
            message_id = sns_resp.get("MessageId")
            if message_id:
                response_body["sns_message_id"] = message_id

        # Return response code 200 with region and optional sns_message_id
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(response_body),
        }
    except Exception as e:
        logger.error(f"Error in handler: {str(e)}")
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(
                {
                    "message": "Internal Server Error",
                    "region": _AWS_REGION,
                }
            ),
        }
