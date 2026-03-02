import json
import logging
import os
import time
import uuid

import boto3  # type: ignore
from botocore.exceptions import BotoCoreError, ClientError  # type: ignore

logger = logging.getLogger()
loglevel_env = os.environ.get("LOGLEVEL", "DEBUG")
logger.setLevel(getattr(logging, loglevel_env.upper(), logging.DEBUG))
generic_exception_message = "Internal server error"

_AWS_REGION = os.environ.get("AWS_REGION")

# Required env vars (set these on the Lambda configuration)
ECS_CLUSTER = os.environ.get("ECS_CLUSTER")
ECS_TASK_DEFINITION = os.environ.get("ECS_TASK_DEFINITION")

ECS_SUBNETS = os.environ.get("ECS_SUBNETS")
ECS_SECURITY_GROUPS = os.environ.get("ECS_SECURITY_GROUPS")
ECS_LAUNCH_TYPE = os.environ.get("ECS_LAUNCH_TYPE", "FARGATE")
ECS_PLATFORM_VERSION = os.environ.get("ECS_PLATFORM_VERSION", "LATEST")
ECS_ASSIGN_PUBLIC_IP = os.environ.get("ECS_ASSIGN_PUBLIC_IP", "ENABLED")

ECS_TASK_POLLING = os.environ.get("ECS_TASK_POLLING", "false").lower() in (
    "1",
    "true",
    "yes",
    "on",
)
ECS_WAIT_TIMEOUT_SECONDS = int(os.environ.get("ECS_WAIT_TIMEOUT_SECONDS", "300"))
ECS_POLL_INTERVAL_SECONDS = int(os.environ.get("ECS_POLL_INTERVAL_SECONDS", "5"))

ecs_client = (
    boto3.client("ecs", region_name=_AWS_REGION) if _AWS_REGION else boto3.client("ecs")
)


def _parse_csv(value):
    if not value:
        return []
    return [v.strip() for v in value.split(",") if v.strip()]


def poll_task(task_arn):
    start_time = time.time()
    while True:
        try:
            desc = ecs_client.describe_tasks(cluster=ECS_CLUSTER, tasks=[task_arn])
            task_list = desc.get("tasks", [])
            if task_list:
                task_desc = task_list[0]
                last_status = task_desc.get("lastStatus")
                logger.debug(f"Task {task_arn} status: {last_status}")
                if last_status == "STOPPED":
                    stopped_reason = task_desc.get("stoppedReason")
                    containers = task_desc.get("containers", [])
                    container_results = [
                        {
                            "name": c.get("name"),
                            "exitCode": c.get("exitCode"),
                            "reason": c.get("reason"),
                        }
                        for c in containers
                    ]
                    # Consider the task successful if all containers have exitCode 0 or exitCode is None
                    success = all(
                        (c.get("exitCode") is None or c.get("exitCode") == 0)
                        for c in containers
                    )
                    response_body = {
                        "message": "ECS task completed",
                        "taskArn": task_arn,
                        "lastStatus": last_status,
                        "stoppedReason": stopped_reason,
                        "containers": container_results,
                    }
                    logger.info(json.dumps(response_body))

                    if success:
                        return {
                            "statusCode": 200,
                            "headers": {"Content-Type": "application/json"},
                            "body": json.dumps(
                                {
                                    "message": "Lambda Dispatch completed successfully!",
                                    "region": _AWS_REGION,
                                }
                            ),
                        }
                    elif not success:
                        return {
                            "statusCode": 500,
                            "headers": {"Content-Type": "application/json"},
                            "body": json.dumps(
                                {
                                    "error": generic_exception_message,
                                    "region": _AWS_REGION,
                                }
                            ),
                        }
            else:
                logger.warning(f"No task description returned for {task_arn}")
        except (BotoCoreError, ClientError) as desc_err:
            logger.exception(f"Error describing ECS task {task_arn}: {str(desc_err)}")

        # continue to retry until timeout
        if time.time() - start_time >= ECS_WAIT_TIMEOUT_SECONDS:
            logger.error(
                f"Timeout waiting for ECS task {task_arn} to stop after {ECS_WAIT_TIMEOUT_SECONDS}s"
            )
            return {
                "statusCode": 504,
                "body": json.dumps({"error": generic_exception_message}),
            }
        time.sleep(ECS_POLL_INTERVAL_SECONDS)


def handler(event, context):
    logger.debug(f"Event received: {json.dumps(event)}")

    # Validate required configuration
    if not ECS_CLUSTER or not ECS_TASK_DEFINITION:
        msg = "ECS_CLUSTER and ECS_TASK_DEFINITION environment variables must be set"
        logger.error(msg)
        return {
            "statusCode": 500,
            "body": json.dumps({"error": generic_exception_message}),
        }

    subnets = _parse_csv(ECS_SUBNETS)
    security_groups = _parse_csv(ECS_SECURITY_GROUPS)

    network_configuration = {
        "awsvpcConfiguration": {
            "subnets": subnets,
            "assignPublicIp": ECS_ASSIGN_PUBLIC_IP,
            "securityGroups": security_groups,
        }
    }

    started_by = f"lambda-dispatcher-{uuid.uuid4()}"

    run_task_kwargs = {
        "cluster": ECS_CLUSTER,
        "taskDefinition": ECS_TASK_DEFINITION,
        "launchType": ECS_LAUNCH_TYPE,
        "platformVersion": ECS_PLATFORM_VERSION,
        "networkConfiguration": network_configuration,
        "startedBy": started_by,
        "count": 1,
    }

    try:
        logger.info(
            f"Running ECS task: cluster={ECS_CLUSTER}, taskDef={ECS_TASK_DEFINITION}, startedBy={started_by}"
        )
        resp = ecs_client.run_task(**run_task_kwargs)
        logger.debug(f"ECS run_task response: {json.dumps(resp, default=str)}")

        failures = resp.get("failures")
        if failures:
            logger.error(f"ECS run_task failures: {failures}")
            return {
                "statusCode": 500,
                "body": json.dumps({"error": generic_exception_message}),
            }

        tasks = resp.get("tasks")
        task_arn = tasks[0].get("taskArn") if tasks else None

        if task_arn:
            logger.info(f"ECS task polling {ECS_TASK_POLLING}")
            if ECS_TASK_POLLING:
                # Wait for the task to complete and return the poll result (which is an HTTP-style dict).
                poll_task(task_arn)
            else:
                logger.info(f"ECS task has been started {task_arn}")
                return {
                    "statusCode": 200,
                    "headers": {"Content-Type": "application/json"},
                    "body": json.dumps(
                        {
                            "message": "Lambda Dispatch has started ECS task!",
                            "region": _AWS_REGION,
                        }
                    ),
                }

    except (BotoCoreError, ClientError) as e:
        logger.exception(f"Error running ECS task: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": generic_exception_message}),
        }
