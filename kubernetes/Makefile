# AWS Infrastructure Management Makefile

# Directories
AWS_TERRAFORM_DIR = self-hosted/cloud/aws/terraform
SCRIPTS_DIR = self-hosted/cloud/aws/scripts

# Default target
.PHONY: help
help:
	@echo "Available AWS targets:"
	@echo "  aws-terraform-plan     - Run terraform plan in AWS terraform directory"
	@echo "  aws-terraform-apply    - Run terraform apply in AWS terraform directory"
	@echo "  aws-terraform-destroy  - Run terraform destroy in AWS terraform directory"
	@echo "  aws-terraform-init     - Initialize terraform in AWS terraform directory"
	@echo "  aws-ansible-setup      - Run the AWS Ansible setup script"
	@echo "  aws-kubeadm-init       - Run the AWS kubeadm initialization script"
	@echo "  aws-clean              - Clean up generated files"

# Terraform targets
.PHONY: aws-terraform-init
aws-terraform-init:
	@echo "Initializing Terraform..."
	cd $(AWS_TERRAFORM_DIR) && terraform init

.PHONY: aws-terraform-plan
aws-terraform-plan:
	@echo "Running Terraform plan..."
	@if [ ! -f ~/.ssh/id_rsa.pub ]; then echo "Error: SSH public key not found at ~/.ssh/id_rsa.pub"; exit 1; fi
	cd $(AWS_TERRAFORM_DIR) && terraform plan -var="ssh_public_key=$$(cat ~/.ssh/id_rsa.pub)" -out=PLAN

.PHONY: aws-terraform-apply
aws-terraform-apply:
	@echo "Running Terraform apply..."
	@if [ ! -f $(AWS_TERRAFORM_DIR)/PLAN ]; then echo "Error: PLAN file not found. Run 'make aws-terraform-plan' first."; exit 1; fi
	cd $(AWS_TERRAFORM_DIR) && terraform apply PLAN

.PHONY: aws-terraform-destroy
aws-terraform-destroy:
	@echo "Running Terraform destroy..."
	@if [ ! -f ~/.ssh/id_rsa.pub ]; then echo "Error: SSH public key not found at ~/.ssh/id_rsa.pub"; exit 1; fi
	cd $(AWS_TERRAFORM_DIR) && terraform destroy -var="ssh_public_key=$$(cat ~/.ssh/id_rsa.pub)"

# AWS Scripts targets
.PHONY: aws-ansible-setup
aws-ansible-setup:
	@echo "Running AWS Ansible setup..."
	cd $(SCRIPTS_DIR) && ./aws_ansible.sh

.PHONY: aws-kubeadm-init
aws-kubeadm-init:
	@echo "Running AWS kubeadm initialization..."
	cd $(SCRIPTS_DIR) && ./kubeadm_init.sh

# Utility targets
.PHONY: aws-clean
aws-clean:
	@echo "Cleaning up generated files..."
	rm -f $(SCRIPTS_DIR)/kubeconfig
	rm -f $(AWS_TERRAFORM_DIR)/terraform.tfstate.backup
	rm -f $(AWS_TERRAFORM_DIR)/PLAN

# Combined workflow targets
.PHONY: aws-deploy
aws-deploy: aws-terraform-apply aws-ansible-setup aws-kubeadm-init
	@echo "Complete AWS deployment finished!"

.PHONY: aws-setup
aws-setup: aws-terraform-init aws-terraform-plan
	@echo "AWS setup complete - ready for terraform apply" 