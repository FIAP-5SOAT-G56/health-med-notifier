#!/bin/bash

tf-init:
	terraform -chdir=terraform init

tf-plan:
	terraform -chdir=terraform plan

tf-apply:
	terraform -chdir=terraform apply -auto-approve

tf-destroy:
	terraform -chdir=terraform destroy -auto-approve