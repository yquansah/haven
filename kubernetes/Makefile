# AWS and GCP Infrastructure Management Makefile

# Directories
AWS_TERRAFORM_DIR = self-hosted/cloud/aws/terraform
AWS_SCRIPTS_DIR = self-hosted/cloud/aws/scripts
GCP_TERRAFORM_DIR = self-hosted/cloud/gcp/terraform
GCP_SCRIPTS_DIR = self-hosted/cloud/gcp/scripts

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
	@echo "  aws-deploy             - Complete AWS deployment workflow"
	@echo "  aws-setup              - AWS setup workflow (init + plan)"
	@echo ""
	@echo "Available GCP targets:"
	@echo "  gcp-terraform-plan     - Run terraform plan in GCP terraform directory"
	@echo "  gcp-terraform-apply    - Run terraform apply in GCP terraform directory"
	@echo "  gcp-terraform-destroy  - Run terraform destroy in GCP terraform directory"
	@echo "  gcp-terraform-init     - Initialize terraform in GCP terraform directory"
	@echo "  gcp-ansible-setup      - Run the GCP Ansible setup script"
	@echo "  gcp-kubeadm-init       - Run the GCP kubeadm initialization script"
	@echo "  gcp-clean              - Clean up generated files"
	@echo "  gcp-deploy             - Complete GCP deployment workflow"
	@echo "  gcp-setup              - GCP setup workflow (init + plan)"

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

# GCP Terraform targets
.PHONY: gcp-terraform-init
gcp-terraform-init:
	@echo "Initializing GCP Terraform..."
	cd $(GCP_TERRAFORM_DIR) && terraform init

.PHONY: gcp-terraform-plan
gcp-terraform-plan:
	@echo "Running GCP Terraform plan..."
	@if [ ! -f ~/.ssh/id_rsa.pub ]; then echo "Error: SSH public key not found at ~/.ssh/id_rsa.pub"; exit 1; fi
	cd $(GCP_TERRAFORM_DIR) && terraform plan -var="gce_ssh_pub_key_file=~/.ssh/id_rsa.pub" -out=PLAN

.PHONY: gcp-terraform-apply
gcp-terraform-apply:
	@echo "Running GCP Terraform apply..."
	@if [ ! -f $(GCP_TERRAFORM_DIR)/PLAN ]; then echo "Error: PLAN file not found. Run 'make gcp-terraform-plan' first."; exit 1; fi
	cd $(GCP_TERRAFORM_DIR) && terraform apply PLAN

.PHONY: gcp-terraform-destroy
gcp-terraform-destroy:
	@echo "Running GCP Terraform destroy..."
	@if [ ! -f ~/.ssh/id_rsa.pub ]; then echo "Error: SSH public key not found at ~/.ssh/id_rsa.pub"; exit 1; fi
	cd $(GCP_TERRAFORM_DIR) && terraform destroy -var="gce_ssh_pub_key_file=~/.ssh/id_rsa.pub"

# AWS Scripts targets
.PHONY: aws-ansible-setup
aws-ansible-setup:
	@echo "Running AWS Ansible setup..."
	cd $(AWS_SCRIPTS_DIR) && ./aws_ansible.sh

.PHONY: aws-kubeadm-init
aws-kubeadm-init:
	@echo "Running AWS kubeadm initialization..."
	cd $(AWS_SCRIPTS_DIR) && ./kubeadm_init.sh

# GCP Scripts targets
.PHONY: gcp-ansible-setup
gcp-ansible-setup:
	@echo "Running GCP Ansible setup..."
	cd $(GCP_SCRIPTS_DIR) && ./gcp_ansible.sh

.PHONY: gcp-kubeadm-init
gcp-kubeadm-init:
	@echo "Running GCP kubeadm initialization..."
	cd $(GCP_SCRIPTS_DIR) && ./kubeadm_init.sh

# Utility targets
.PHONY: aws-clean
aws-clean:
	@echo "Cleaning up generated files..."
	rm -f $(AWS_SCRIPTS_DIR)/kubeconfig
	rm -f $(AWS_TERRAFORM_DIR)/terraform.tfstate.backup
	rm -f $(AWS_TERRAFORM_DIR)/PLAN

.PHONY: gcp-clean
gcp-clean:
	@echo "Cleaning up generated files..."
	rm -f $(GCP_SCRIPTS_DIR)/kubeconfig
	rm -f $(GCP_TERRAFORM_DIR)/terraform.tfstate.backup
	rm -f $(GCP_TERRAFORM_DIR)/PLAN

# Combined workflow targets
.PHONY: aws-deploy
aws-deploy: aws-terraform-apply aws-ansible-setup aws-kubeadm-init
	@echo "Complete AWS deployment finished!"

.PHONY: aws-setup
aws-setup: aws-terraform-init aws-terraform-plan
	@echo "AWS setup complete - ready for terraform apply"

.PHONY: gcp-deploy
gcp-deploy: gcp-terraform-apply gcp-ansible-setup gcp-kubeadm-init
	@echo "Complete GCP deployment finished!"

.PHONY: gcp-setup
gcp-setup: gcp-terraform-init gcp-terraform-plan
	@echo "GCP setup complete - ready for terraform apply" 