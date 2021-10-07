### This Module Terraform deploy an APP in AWS ECS Fargate:

* Create ECS Task Definition
* Create ECS Service Fargate
* Create Application Load Balance
* Create Target Group
* Create Monitoring Log in AWS CloudWatch

## Usage
##### Credential for AWS
Create .env file to AWS credentials with access key and secret key.
```shell
# AWS environment
AWS_ACCESS_KEY_ID =
AWS_SECRET_ACCESS_KEY =
```
#### Create terrafile.tf file with content and set your configurations:
```terraform
provider "aws" {
  region  = "us-east-2"
  version = "= 3.0"
}
terraform {
  backend "s3" {
    bucket = "your-bucket-here"
    key    = "key-terraform-.tfstate"
    region = "us-east-2"
  }
} 

module "app-deploy" {
  source                 = "git@github.com:gomex/terraform-module-fargate-deploy.git?ref=v0.1"
  containers_definitions = data.template_file.containers_definitions_json.rendered
  environment            = "development"
  subdomain_name         = "app"
  app_name               = "app"
  app_port               = "80"
  cloudwatch_group_name  = "development-app"
  default_tags  = {
    Name        : "myapp",
    Team        : "IAC",
    Application : "App-Rapadura",
    Environment : "development",
    Terraform   : "Yes",
    Owner       : "Metal.Corp"
  }
}

data "template_file" "containers_definitions_json" {
  template = file("./containers_definitions.json")

  vars = {
    APP_VERSION = var.APP_VERSION
    APP_IMAGE   = var.APP_IMAGE
    ENVIRONMENT = "development"
    AWS_REGION  = var.aws_region
  }
}

variable "APP_VERSION" {
}

variable "APP_IMAGE" {
  default = "app"
}

variable "aws_region" {
  default = "us-east-1"
}
```
#### Container Definition
```json
[
  {
    "cpu": 1024,
    "image": "520044189785.dkr.ecr.us-east-2.amazonaws.com/website:${APP_VERSION}",
    "memory": 1024,
    "name": "myapp",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 3000,
        "hostPort": 3000
      }
    ],
    "environment": [
      {
        "name": "AWESOME_ENV_VAR",
        "value": "${AWESOME_ENV_VAR}"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "myapp-log",
        "awslogs-region": "us-east-2",
        "awslogs-stream-prefix": "myapp-log-${APP_VERSION}"
      }
    }
  }
]
```

## Terraform inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| aws\_region | The AWS region to create things in. | string | `"us-east-2"` | yes |
| az\_count | The number of Availability Zones that we will deploy into | string | `"2"` | no |
| environment | Name of environment to be created | string | n/a | yes |
| vpc\_cidr\_block | Range of IPv4 address for the VPC. | string | `"10.10.0.0/16"` | no |
| default\_tags | Default tags name. | map | `"Key: value"` | yes |

## Outputs

| Name | Description |
|------|-------------|
| ecs_cluster_name | ECS cluster name. |
| aws\_vpc\_id | The ID of AWS VPC created for the ECS cluster. ||