### This Module Terraform deploy an APP in AWS ECS Fargate:

* Create ECS Task Definition
* Create ECS Service Fargate
* Create Application Load Balance
* Create Target Group

#### Requisites for running this project:
- Docker
- Docker-compose
- Make
- AWS CLI version 2

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
    default   = "bead89c"
    describle = "Get the value of variable GIT_COMMIT in Makefile."
}

variable "APP_IMAGE" {
  default   = "website"
  describle = "Get the value of variable APP_IMAGE in Makefile"
}

variable "AWS_ACCOUNT" {
  default   = "520044189785"
  describle = "Get the value of variable AWS_ACCOUNT in Makefile"
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
    "image": "${AWS_ACCOUNT}.dkr.ecr.us-east-2.amazonaws.com/${APP_IMAGE}:${APP_VERSION}",
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

#### Terraform inputs

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


#### The visual representation
```shell
# run the command for terraform shell
make terraform-sh

# and then install apk graphviz
apk -U add graphviz

# Command is used to generate a visual representation
terraform graph | dot -Tsvg > graph.svg
```
#### For help, run the following commands: ```make help```:
##### Print:

```make
make help:         ## Run make help.
docker-run-local:  ## Run the container on the local machine.
docker-stop-local: ## Destroy the container on the local machine.
ecr-build:         ## ECR-step:1 Build your Docker image.
ecr-login:         ## ECR-step:2 Retrieve an authentication token and authenticate your Docker client to your registry.
ecr-tag:           ## ECR-step:3 Tag your image so you can push the image to this repository.
ecr-push:          ## ECR-step:4 Push this image to your newly created AWS repository.
terraform-fmt:     ## Command is used to rewrite Terraform configuration files to a canonical format and style.
terraform-init:    ## Run terraform init to download all necessary plugins
terraform-plan:    ## Exec a terraform plan and puts it on a file called plano
terraform-apply:   ## Uses plano to apply the changes on AWS.
terraform-destroy: ## Destroy all resources created by the terraform file in this repo.
terraform-sh:      ## Exec Terraform CLI.
```

#### To be
- We need the log configuration with AWS CloudWatch.
- Output: The dns_name the application load balancer.
