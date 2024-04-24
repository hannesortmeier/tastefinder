# Read project version from Maven project
PROJECT_VERSION := $(shell mvn -q -Dexec.executable=echo -Dexec.args='$${project.version}' --non-recursive exec:exec)

# Terraform commands
init:
	cd terraform/restaurantpicker-dev && terraform init

plan:
	cd terraform/restaurantpicker-dev && terraform plan -var="project_version=$(PROJECT_VERSION)"

apply:
	cd terraform/restaurantpicker-dev && terraform apply -var="project_version=$(PROJECT_VERSION)" -auto-approve

# Other useful commands
validate:
	cd terraform/restaurantpicker-dev && terraform validate

fmt:
	cd terraform/restaurantpicker-dev && terraform fmt -recursive

clean:
	cd terraform/restaurantpicker-dev && rm -rf .terraform *.tfstate*

build-lambda:
	mvn package --projects lambda

.PHONY: init plan apply destroy validate fmt clean
