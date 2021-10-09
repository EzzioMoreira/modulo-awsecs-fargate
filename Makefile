# Import end.aws as environment variable
cnf ?= .env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

# Get the latest tag
TAG=$(shell git describe --tags --abbrev=0)
GIT_COMMIT=$(shell git log -1 --format=%h)
AWS_ACCOUNT=520044189785
APP_NAME=website
AWS_REGIO=us-east-2
TERRAFORM_VERSION=0.13.0

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

docker-run-local: ## Run the container on the local machine.
	docker-compose -f ./app/docker-compose.yml up -d

docker-stop-local: ## Destroy the container on the local machine.
	docker-compose -f ./app/docker-compose.yml rm -sf

ecr-build: ## ECR-step:1 Build your Docker image.
	docker build -t ${APP_NAME}:${GIT_COMMIT} ./app/.

ecr-login: ## ECR-step:2 Retrieve an authentication token and authenticate your Docker client to your registry.
	export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
	export AWS_ACCESS_KEY_ID=${AWS_SECRET_ACCESS_KEY}
	aws ecr get-login-password --region ${AWS_REGIO} | docker login --username AWS --password-stdin ${AWS_ACCOUNT}.dkr.ecr.us-east-2.amazonaws.com

ecr-tag: ecr-login ecr-build ## ECR-step:3 Tag your image so you can push the image to this repository.
	docker tag  ${APP_NAME}:${GIT_COMMIT} ${AWS_ACCOUNT}.dkr.ecr.us-east-2.amazonaws.com/${APP_NAME}:${GIT_COMMIT}

ecr-push: ## ECR-step:4 Push this image to your newly created AWS repository.
	docker push ${AWS_ACCOUNT}.dkr.ecr.us-east-2.amazonaws.com/${APP_NAME}:${GIT_COMMIT}

terraform-fmt: ## Command is used to rewrite Terraform configuration files to a canonical format and style.
	docker run --rm -v $$PWD:/app -v $$HOME/.ssh/:/root/.ssh/ -w /app/ -e AWS_ACCESS_KEY_ID=$$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$$AWS_SECRET_ACCESS_KEY -e TF_VAR_APP_VERSION=$(GIT_COMMIT) hashicorp/terraform:$(TERRAFORM_VERSION) fmt

terraform-init: ## Run terraform init to download all necessary plugins.
	docker run --rm -v $$PWD:/app -v $$HOME/.ssh/:/root/.ssh/ -w /app/ -e AWS_ACCESS_KEY_ID=$$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$$AWS_SECRET_ACCESS_KEY -e TF_VAR_APP_VERSION=$(GIT_COMMIT) hashicorp/terraform:$(TERRAFORM_VERSION) init -upgrade=true

terraform-plan: ## Exec a terraform plan and puts it on a file called plano.
	docker run --rm -v $$PWD:/app -v $$HOME/.ssh/:/root/.ssh/ -w /app/ -e AWS_ACCESS_KEY_ID=$$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$$AWS_SECRET_ACCESS_KEY -e TF_VAR_APP_VERSION=$(GIT_COMMIT) hashicorp/terraform:$(TERRAFORM_VERSION) plan -out=plano

terraform-apply: ## Uses plano to apply the changes on AWS.
	docker run --rm -v $$PWD:/app -v $$HOME/.ssh/:/root/.ssh/ -w /app/ -e AWS_ACCESS_KEY_ID=$$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$$AWS_SECRET_ACCESS_KEY -e TF_VAR_APP_VERSION=$(GIT_COMMIT) hashicorp/terraform:$(TERRAFORM_VERSION) apply -auto-approve

terraform-destroy: ## Destroy all resources created by the terraform file in this repo.
	docker run --rm -v $$PWD:/app -v $$HOME/.ssh/:/root/.ssh/ -w /app/ -e AWS_ACCESS_KEY_ID=$$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$$AWS_SECRET_ACCESS_KEY -e TF_VAR_APP_VERSION=$(GIT_COMMIT) hashicorp/terraform:$(TERRAFORM_VERSION) destroy -auto-approve

terraform-sh: ## Exec Terraform CLI.
	docker run -it --rm -v $$PWD:/app -v $$HOME/.ssh/:/root/.ssh/ -w /app/ -e AWS_ACCESS_KEY_ID=$$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$$AWS_SECRET_ACCESS_KEY -e TF_VAR_APP_VERSION=$(GIT_COMMIT) --entrypoint "" hashicorp/terraform:$(TERRAFORM_VERSION) sh
