# This Module Terraform deploy an APP in AWS ECS Fargate:

### What will be created:
* Create ECS Service Fargate
* Create ECS Task Definition
* Create Task
* Create Application Load Balance
* Create Target Group

### Requisites for running this project:
- Docker
- Docker-compose
- Make
- AWS CLI version 2

### How do you use:
### Credential for AWS:
Create `.env` file to AWS credentials with access key and secret key.
```shell
# AWS environment
AWS_ACCESS_KEY_ID=your-access-key-here
AWS_SECRET_ACCESS_KEY=your-secret-key-here
```

### 2.2: Configure your variables in `Makefile` file.
- `AWS_ACCOUNT`=you_account-id
- `APP_IMAGE`=application_name
- `AWS_REGIO`=you_aws_region

### Create `terrafile.tf` file with content and set your configurations. If you prefer, change the environment variable name.
```terraform
provider "aws" {
  region  = "us-east-2"
  version = "= 3.0"
}

terraform {
  backend "s3" {
    bucket = "your-bucket-here"
    key    = "path/keyname-terraform-.tfstate"
    region = "us-east-2"
  }
} 

module "app-deploy" {
  source                 = "git@github.com:EzzioMoreira/modulo-awsecs-fargate.git?ref=v1.4"
  containers_definitions = data.template_file.containers_definitions_json.rendered
  environment            = "your-environment"
  app_name               = "your-app-name"
  app_count              = "2"
  app_port               = "80"
  fargate_version        = "1.4.0"
  cloudwatch_group_name  = "your-app-name"
}

output "load_balancer_dns_name" {
  value = "http://${module.app-deploy.loadbalance_dns_name}"
}

data "template_file" "containers_definitions_json" {
  template = file("./containers_definitions.json")

  vars = {
    APP_VERSION = var.APP_VERSION
    APP_IMAGE   = var.APP_IMAGE
    AWS_ACCOUNT = var.AWS_ACCOUNT
  }
}

variable "APP_VERSION" {
  default   = "latest"
  description = "Get the value of variable GIT_COMMIT in Makefile."
}

variable "APP_IMAGE" {
  default   = "you-image-name"
  description = "Get the value of variable APP_IMAGE in Makefile"
}

variable "AWS_ACCOUNT" {
  default   = "your-account-id"
  description = "Get the value of variable AWS_ACCOUNT in Makefile"
}

```
### Container Definition:
Create file named containers_definitions_json with the following content.
- your ECR address:           "520044189785.dkr.ecr.us-east-2.amazonaws.com"
- "name": call the variable:  "${APP_IMAGE}"
- calls the variables:        "${APP_IMAGE}: ${APP_VERSION}"
```json
[
  {
    "cpu": 256,
    "image": "${AWS_ACCOUNT}.dkr.ecr.us-east-2.amazonaws.com/${APP_IMAGE}:${APP_VERSION}",
    "memory": 256,
    "name": "${APP_IMAGE}",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
          "awslogs-group": "${APP_IMAGE}",
          "awslogs-region": "us-east-2",
          "awslogs-stream-prefix": "${APP_IMAGE}-${APP_VERSION}"
      }
    }
  }
]
```

### Terraform inputs:

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| aws\_region | The AWS region to create things in. | string | `"us-east-2"` | no |
| fargate\_version | The fargate version used to deploy. inside ECS cluster. | string | `"1.3.0"` | no |
| fargate\_cpu | The maximum of CPU that the task can use. | string | 1024 | no |
| fargate\_memory | The maximum of memory that the task can use. | string | `"2048"` | no |
| app\_name | Name of your application. | string | `"empty"` | yes |
| app\_port | The port used for communication between the application load balancer and container. | number | `"80"` | no |
| app\_count | Number of tasks to be deployed to the application. | number | `"1"` | no |
| environment | The environment name to app. | string | `"development"` | no |
| cloudwatch\_group_name | CloudWatch group name where to send the logs. | string | `"empty"`| yes | 
| containers\_definitions | The json file with the container definition task. | file | `"containers_definitions.json"` | yes ||

### Terraform Output:

| Name | Description |
|:------:|:-------------:|
| load\_balancer\_dns\_name | Application load balancer DNS name.  ||

### The visual representation:
```shell
# run the command for terraform shell
make terraform-sh

# and then install apk graphviz
apk -U add graphviz

# Command is used to generate a visual representation
terraform graph | dot -Tsvg > graph.svg
```
### For help, run the following commands: `make help`:
#### Print:

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
