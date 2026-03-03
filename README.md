# Unleash Live — Infrastructure and Test Project

This repository contains Terraform infrastructure, Lambda functions, ECS task definitions, API Gateway wiring, continuous deployment workflows, and k6 performance tests for the "Unleash Live" demo application.

This README summarizes the project layout, how to run the Terraform modules locally and in CI, how GitHub Actions are wired, and how to run the k6 tests that exercise the deployed API.

---

## Table of contents

- Project overview
- Repo layout
- Prerequisites
- Terraform: local usage
- Terraform: workspace-based workflow
- Modules and what they contain
- GitHub Actions CI usage
- k6 API tests
- Lambda & ECS notes
- Security and secrets
- Troubleshooting
- Contributing

---

## Project overview

- `infra/` — top-level Terraform workspaces split into environment-focused stacks:
  - `infra/auth` — Cognito + related auth infrastructure
  - `infra/compute` — ECS, Lambdas, API Gateway wiring, and compute resources
- `infra/modules/` — reusable Terraform modules used by the stacks:
  - `apigw`, `cognito`, `ecs`, `lambda` etc.
- `test/k6` — k6 load test scripts for the API.
- `.github/workflows` — GitHub Actions workflows for planning/deploying Terraform and performing tests.

This repo uses a reusable Terraform workflow so `auth` and `compute` can be deployed separately and in sequence.

---

## Repo layout (high-level)

- unleash-live/
  - infra/
    - auth/
      - main.tf
      - variables.tf
      - outputs.tf
      - tfvars/
        - prod.tfvars
    - compute/
      - main.tf
      - variables.tf
      - outputs.tf
      - tfvars/
        - prod-us.tfvars
        - prod-eu.tfvars
    - modules/
      - apigw/
      - cognito/
      - ecs/
      - lambda/
        - scripts/
          - dispatch.py
          - greet.py
  - test/
    - k6/
      - testing.js
      - testing.sh
  - .github/
    - workflows/
      - deploy-infra.yml        # caller workflow (auth -> compute -> api tests)
      - terraform-deploy.yml    # reusable terraform workflow called by above

---

## Prerequisites

Install on your local workstation to run Terraform and tests (all installed using ASDF):

- Terraform (recommended version declared in workflows: `1.5.x` — use the version pinned in workflows).
- AWS CLI v2 (for local credential verification).
- k6 (for running performance tests locally).
- jq (helpful for parsing JSON outputs).
- An AWS account and credentials with sufficient permissions for the resources in the stacks.


---

## Terraform: local usage

Each stack has its own Terraform root: `infra/auth` and `infra/compute`.

Typical flow (example for `infra/auth`):

1. Change into the stack directory:
```/dev/null/commands.md#L1-6
cd infra/auth
```

2. Initialize:
```/dev/null/commands.md#L7-11
terraform init -upgrade -input=false
```

3. Select or create a workspace (this repository uses workspace-per-environment by default — the CI sets `TF_WORKSPACE`):
```/dev/null/commands.md#L12-18
# Choose a workspace name like "prod", "prod-us" or "prod-eu"
export TF_WORKSPACE=prod
terraform workspace select "${TF_WORKSPACE}" || terraform workspace new "${TF_WORKSPACE}"
```

4. Plan using an environment-specific tfvars:
```/dev/null/commands.md#L19-24
terraform plan -var-file=tfvars/$TF_WORKSPACE.tfvars -no-color -out=tfplan -input=false
```

5. Apply (if desired):
```/dev/null/commands.md#L25-28
terraform apply tfplan
```

Notes:
- The GitHub Actions reusable workflow does the same but is parameterized for multiple environments via `envs` or `environment` inputs.
- For `compute` stack, choose the appropriate tfvars file under `infra/compute/tfvars/` (e.g., `prod-us.tfvars` or `prod-eu.tfvars`).
- Multi region deployment is enabled by using matrix in github actions that map to the appropriate tfvars to use (i.e. `prod-us.tfvars` for prod-us and `prod-eu.tfvars` for prod-eu)

---

## Terraform: workspace-based workflow

This repo configures Terraform runs to use workspaces (CI sets `TF_WORKSPACE` per matrix env). The reusable workflow sets `TF_WORKSPACE` to the matrix environment name, selects or creates that workspace before running plan/apply, and names plan outputs using that environment.

If you want to mimic CI locally:
```/dev/null/commands.md#L29-34
# Example for prod-us:
export TF_WORKSPACE=prod-us
cd infra/compute
terraform init
terraform workspace select "${TF_WORKSPACE}" || terraform workspace new "${TF_WORKSPACE}"
terraform plan -var-file=tfvars/$TF_WORKSPACE.tfvars -out=tfplan -input=false
```

---

## Modules and contents

- `infra/modules/apigw` — API Gateway resources (rest api, resources, methods, integrations).
  - See `infra/modules/apigw/main.tf`.
- `infra/modules/cognito` — Cognito User Pool and client config.
- `infra/modules/ecs` — ECS cluster, security group and task definition module.
- `infra/modules/lambda` — Lambda functions and supporting resources (DynamoDB table, SNS topic, IAM role).
  - Lambda handler scripts live in `infra/modules/lambda/scripts/`.

The lambda scripts include:
- `dispatch.py` — dispatches/runs a standalone Fargate task via ECS (supports waiting for completion).
  - currently set run ecs task without polling for ecs task result. This is due to the amount of time it takes for the ecs task to provision, run and finish the task.
  - opportunities: async strategy via callback
- `greet.py` — greets and publishes to SNS and writes a DynamoDB record (uses the Lambda execution role; no credentials embedded).

---

## GitHub Actions: CI/CD

Two main workflows:

- `.github/workflows/terraform-deploy.yml` — a reusable workflow that runs Terraform for a given `directory` and an `envs` matrix. It:
  - Initializes Terraform, optionally runs tfsec, selects/creates Terraform workspace, plans per environment, and optionally applies when `apply` is true.

- `.github/workflows/deploy-infra.yml` — the caller workflow that:
  - Calls the reusable workflow for the `auth` stack (typically run for a single env).
  - Calls the reusable workflow for the `compute` stack (depends on `auth`).
  - Runs `api-test` job (k6 tests) after deployment.

Required secrets for the workflows:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- Optional: `AWS_SESSION_TOKEN`
- `AWS_REGION`


---

## k6 API tests

k6 tests are under `test/k6/`.

- Main test script: `test/k6/testing.js`.
  - Reads env vars:
    - `BASE_URL` — target API base URL (required)
    - `API_TOKEN` — optional Bearer token for auth
    - `REQUEST_REGION` — region to assert (e.g., `us-east-1`)
  - The script logs each response and checks:
    - HTTP 200
    - latency thresholds
    - payload `region` matches `REQUEST_REGION` (when set)

- Wrapper script: `test/k6/testing.sh`

Run locally:
```/dev/null/commands.md#L35-40
# Example:
./test/k6/testing.sh
```

Notes:
- The CI `api-test` job installs AWS CLI and runs the k6 action. You can adjust the test scenarios (VUs, duration, or RPS) inside `test/k6/testing.js`.
- The repo includes `test/k6/testing.sh` as a helper for local runs (inspect it for convenience).

---

## Lambda & ECS developer notes

- Lambda code is stored in `infra/modules/lambda/scripts/`.
  - Use the Lambda execution role to allow boto3 calls without embedding credentials (`aws_iam_role` configuration in Terraform).
  - Ensure IAM role has appropriate permissions:
    - For DynamoDB: `dynamodb:PutItem` to the target table
    - For SNS: `sns:Publish` to the topic (ARN passed in env)
    - For ECS calls: `ecs:RunTask`, `ecs:DescribeTasks`, and `iam:PassRole` for task role passing (scoped in the module)
- Dispatcher Lambda (`dispatch.py`) runs an ECS Fargate task and optionally waits for it to enter `STOPPED` state. The wait timeout and polling interval are configurable by env vars:
  - `ECS_WAIT_TIMEOUT_SECONDS` (default `300`)
  - `ECS_POLL_INTERVAL_SECONDS` (default `5`)
  - `ECS_TASK_POLLING` (default `false`)
- If your Lambda waits for ECS task completion, ensure the Lambda `timeout` and APIGW `timeout` in Terraform is set longer than the wait timeout.

---

## Security and secrets

- Do not store credentials in code. Use environment variables and IAM roles.
- Store AWS credentials in GitHub Secrets:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_SESSION_TOKEN` (if using temporary credentials)
  - `AWS_REGION`
- Terraform remote state: ensure your backend is secured and locked (the repo uses backend config under each `infra/*/backend.tf`).
- The reusable workflow exposes Terraform outputs as base64 JSON. Do not return sensitive outputs in this mechanism.
