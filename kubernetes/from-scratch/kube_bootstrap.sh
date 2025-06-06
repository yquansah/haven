#!/bin/bash

# Configuration parameters
MAIN_DIRECTORY="${MAIN_DIRECTORY:-/tmp/kube}"
PKI_DIRECTORY="${PKI_DIRECTORY:-$MAIN_DIRECTORY/pki}"
KUBECONFIG_DIRECTORY="${KUBECONFIG_DIRECTORY:-$MAIN_DIRECTORY/configs}"
SERVER_NAME="${SERVER_NAME:-kube-apiserver.com}"
SERVER_PORT="${SERVER_PORT:-6443}"
CERT_DAYS="${CERT_DAYS:-365}"
CA_KEY_SIZE="${CA_KEY_SIZE:-2048}"
SERVICE_ACCOUNT_KEY_SIZE="${SERVICE_ACCOUNT_KEY_SIZE:-4096}"

# Certificate configurations
declare -A CERT_CONFIGS=(
  ["ca"]="key_size:${CA_KEY_SIZE} subject:/CN=${SERVER_NAME} extensions:subjectAltName=DNS:${SERVER_NAME}"
  ["server"]="key_size:${CA_KEY_SIZE} subject:/CN=${SERVER_NAME} extensions:subjectAltName=DNS:${SERVER_NAME}"
  ["kube-scheduler"]="key_size:${CA_KEY_SIZE} subject:/CN=${SERVER_NAME} extensions:subjectAltName=DNS:${SERVER_NAME}"
  ["service-accounts"]="key_size:${CA_KEY_SIZE} subject:/CN=${SERVER_NAME} extensions:subjectAltName=DNS:${SERVER_NAME}"
  ["kube-controller-manager"]="key_size:${CA_KEY_SIZE} subject:/CN=${SERVER_NAME} extensions:subjectAltName=DNS:${SERVER_NAME}"
)

# Kubeconfig configurations
declare -A KUBECONFIG_CONFIGS=(
  ["kubeconfig"]="cluster:local-apiserver user:admin cert:server"
  ["kube-scheduler.kubeconfig"]="cluster:local-apiserver user:system:kube-scheduler cert:kube-scheduler"
  ["kube-controller-manager.kubeconfig"]="cluster:local-apiserver user:system:kube-controller-manager cert:kube-controller-manager"
)

# Functions
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

generate_private_key() {
  local name="$1"
  local key_size="$2"
  local output_file="$3"

  log "Generating ${name} private key (${key_size} bits)"
  openssl genrsa -out "${output_file}" "${key_size}"
}

generate_certificate() {
  local name="$1"
  local key_file="$2"
  local cert_file="$3"
  local subject="$4"
  local extensions="$5"

  log "Generating ${name} certificate"
  openssl req -x509 -new -nodes \
    -key "${key_file}" \
    -subj "${subject}" \
    -days "${CERT_DAYS}" \
    -out "${cert_file}" \
    -addext "${extensions}"
}

generate_csr() {
  local name="$1"
  local key_file="$2"
  local csr_file="$3"
  local subject="$4"
  local extensions="$5"

  log "Generating ${name} certificate signing request"
  openssl req -new \
    -key "${key_file}" \
    -subj "${subject}" \
    -out "${csr_file}" \
    -addext "${extensions}"
}

sign_certificate() {
  local name="$1"
  local csr_file="$2"
  local cert_file="$3"
  local ca_cert="$4"
  local ca_key="$5"

  log "Signing ${name} certificate"
  openssl x509 -req \
    -in "${csr_file}" \
    -CA "${ca_cert}" \
    -CAkey "${ca_key}" \
    -CAcreateserial \
    -out "${cert_file}" \
    -days "${CERT_DAYS}" \
    -copy_extensions copy
}

setup_kubeconfig() {
  local config_file="${KUBECONFIG_DIRECTORY}/$1"
  local cluster_name="$2"
  local user_name="$3"
  local cert_prefix="$4"

  log "Setting up kubeconfig: ${config_file}"

  kubectl config set-cluster "${cluster_name}" \
    --certificate-authority="${PKI_DIRECTORY}/ca.crt" \
    --embed-certs=true \
    --server="https://${SERVER_NAME}:${SERVER_PORT}" \
    --kubeconfig="${config_file}"

  kubectl config set-credentials "${user_name}" \
    --client-certificate="${PKI_DIRECTORY}/${cert_prefix}.crt" \
    --client-key="${PKI_DIRECTORY}/${cert_prefix}.key" \
    --embed-certs=true \
    --kubeconfig="${config_file}"

  kubectl config set-context default \
    --cluster="${cluster_name}" \
    --user="${user_name}" \
    --kubeconfig="${config_file}"

  kubectl config use-context default \
    --kubeconfig="${config_file}"
}

create_scheduler_config() {
  local scheduler_config_file="${KUBECONFIG_DIRECTORY}/kube-scheduler-config.yaml"

  log "Creating kube-scheduler configuration: ${scheduler_config_file}"

  cat >"${scheduler_config_file}" <<EOF
apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: ${KUBECONFIG_DIRECTORY}/kube-scheduler.kubeconfig
leaderElection:
  leaderElect: true
EOF
}

# Main execution
main() {
  log "Starting certificate generation process"
  log "Main directory: ${MAIN_DIRECTORY}"
  log "Server name: ${SERVER_NAME}"

  # Clean up existing directory for fresh start
  if [[ "${MAIN_DIRECTORY}" == /tmp/kube* ]]; then
    log "Removing existing directory: ${MAIN_DIRECTORY}"
    rm -rf "${MAIN_DIRECTORY}"
  fi

  # Create main directory
  mkdir -p "${MAIN_DIRECTORY}"
  mkdir -p "${PKI_DIRECTORY}"

  # Generate service account key and certificate (special case)
  log "Generating service account key and certificate"
  generate_private_key "service-account" "${SERVICE_ACCOUNT_KEY_SIZE}" \
    "${PKI_DIRECTORY}/service-account-key.pem"

  openssl req -new -x509 -days "${CERT_DAYS}" \
    -key "${PKI_DIRECTORY}/service-account-key.pem" \
    -subj "/CN=${SERVER_NAME}" \
    -sha256 \
    -out "${PKI_DIRECTORY}/service-account.pem"

  # Generate CA certificate first (needed for signing others)
  local ca_config="${CERT_CONFIGS[ca]}"
  local ca_key_size=$(echo "$ca_config" | grep -o 'key_size:[0-9]*' | cut -d: -f2)
  local ca_subject=$(echo "$ca_config" | grep -o 'subject:[^[:space:]]*' | cut -d: -f2-)
  local ca_extensions=$(echo "$ca_config" | grep -o 'extensions:.*' | cut -d: -f2-)

  generate_private_key "CA" "${ca_key_size}" "${PKI_DIRECTORY}/ca.key"
  generate_certificate "CA" "${PKI_DIRECTORY}/ca.key" \
    "${PKI_DIRECTORY}/ca.crt" "${ca_subject}" "${ca_extensions}"

  # Generate other certificates that need to be signed by CA
  for cert_name in server kube-scheduler; do
    local config="${CERT_CONFIGS[$cert_name]}"
    local key_size=$(echo "$config" | grep -o 'key_size:[0-9]*' | cut -d: -f2)
    local subject=$(echo "$config" | grep -o 'subject:[^[:space:]]*' | cut -d: -f2-)
    local extensions=$(echo "$config" | grep -o 'extensions:.*' | cut -d: -f2-)

    generate_private_key "${cert_name}" "${key_size}" \
      "${PKI_DIRECTORY}/${cert_name}.key"

    generate_csr "${cert_name}" "${PKI_DIRECTORY}/${cert_name}.key" \
      "${PKI_DIRECTORY}/${cert_name}.csr" "${subject}" "${extensions}"

    sign_certificate "${cert_name}" "${PKI_DIRECTORY}/${cert_name}.csr" \
      "${PKI_DIRECTORY}/${cert_name}.crt" "${PKI_DIRECTORY}/ca.crt" \
      "${PKI_DIRECTORY}/ca.key"
  done

  # Add hostname to /etc/hosts (idempotent)
  log "Adding hostname to /etc/hosts"
  if ! grep -q "127.0.0.1 ${SERVER_NAME}" /etc/hosts; then
    echo "127.0.0.1 ${SERVER_NAME}" | sudo tee -a /etc/hosts
  fi

  # Generate kubeconfig files
  for config_file in "${!KUBECONFIG_CONFIGS[@]}"; do
    local config_data="${KUBECONFIG_CONFIGS[$config_file]}"
    local cluster_name=$(echo "$config_data" | grep -o 'cluster:[^[:space:]]*' | cut -d: -f2)
    local user_name=$(echo "$config_data" | grep -o 'user:[^[:space:]]*' | cut -d: -f2-)
    local cert_prefix=$(echo "$config_data" | grep -o 'cert:[^[:space:]]*' | cut -d: -f2)

    setup_kubeconfig "${config_file}" "${cluster_name}" "${user_name}" "${cert_prefix}"
  done

  # Create kube-scheduler configuration
  create_scheduler_config

  log "Certificate generation and kubeconfig setup completed successfully"
}

# Execute main function
main "$@"
