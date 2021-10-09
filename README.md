### This Module Terraform deploy an APP in AWS ECS Fargate:

* Create ECS Task Definition
* Create ECS Service Fargate
* Create Application Load Balance
* Create Target Group

## Usage
##### Credential for AWS
Create .env file to AWS credentials with access key and secret key.
```shell
# AWS environment
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
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
  source                 = "git@github.com:EzzioMoreira/modulo-awsecs-fargate.git?ref=v1.3"
  containers_definitions = data.template_file.containers_definitions_json.rendered
  environment            = "development"
  app_name               = "website"
  app_port               = "80"
  fargate_version        = "1.4.0"
}

data "template_file" "containers_definitions_json" {
  template = file("./containers_definitions.json")

  vars = {
    APP_VERSION = var.APP_VERSION
    APP_IMAGE   = var.APP_IMAGE
  }
}

variable "APP_VERSION" {
    default = "latest"
}

variable "APP_IMAGE" {
  default = "website"
}

```
#### Container Definition
create file named containers_definitions_json with the following content.
- your ECR address: 520044189785.dkr.ecr.us-east-2.amazonaws.com
- "name": call the variable:  "${APP_IMAGE}"
- calls the variables: ${APP_IMAGE}: ${APP_VERSION} "
```json
[
  {
    "cpu": 256,
    "image": "520044189785.dkr.ecr.us-east-2.amazonaws.com/${APP_IMAGE}:${APP_VERSION}",
    "memory": 1024,
    "name": "${APP_IMAGE}",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ]
  }
]
```

## Terraform inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| aws\_region | The AWS region to create things in. | string | `"us-east-2"` | no |
| fargate\_version | The fargate version used to deploy. inside ECS cluster. | string | `"1.3.0"` | no |
| fargate\_cpu | The maximum of CPU that the task can use. | string | 1024 | no |
| fargate\_memory | The maximum of memory that the task can use. | string | `"2048"` | no |
| app\_name | Name of your application. | string | `"empty"` | yes |
| app\_port | The port used for communication between the application load balancer and container. | number | `"80"` | no |
| app\_count | Number of tasks to be deployed to the application. | number | `"1"` | no |
| environment | The environment name to app.. | string | `"development"` | no |
| containers\_definitions | The json file with the container definition task. | file | `"containers_definitions.json"` | yes |


## The visual representation
```shell
# run the command for terraform shell
make terraform-sh

# and then install apk graphviz
apk -U add graphviz

# Command is used to generate a visual representation
terraform graph | dot -Tsvg > graph.svg
```

## To be
- We need the log configuration with AWS CloudWatch.
- Output: The dns_name the application load balancer.