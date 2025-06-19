.PHONY: tf-plan yke-start yke-destroy init-argocd clean

tf-plan:
	terraform -chdir=./terraform plan -var="ssh_public_key=$(SSH_PUBLIC_KEY)"

yke-start:
	SSH_PUBLIC_KEY="$(SSH_PUBLIC_KEY)" bash setup.sh

yke-destroy: clean
	cd terraform && terraform destroy -auto-approve -var="ssh_public_key=$(SSH_PUBLIC_KEY)"

clean:
	@if [ -f admin.conf ]; then \
		rm admin.conf; \
		echo "Removed admin.conf"; \
	fi
	@if [ -f command.txt ]; then \
		rm command.txt; \
		echo "Removed command.txt"; \
	fi
