#!/bin/bash

# This script assumes that the Kubernetes cluster is already running and that it is configured to use OpenID Connect for authentication with the right client ID provided.
# This is also just a toy example due to the self-signed certificate with a certficate authority that we have created.
# In a production environment, you would opt for a solution like cert-manager to create the certificate for you from a trusted CA like letsencrypt.
# The repo for the helm chart in dex actually walks you through an example of how to do this.

# Check for required environment variables
if [ -z "$OAUTH2_CLIENT_ID" ]; then
    echo "Error: OAUTH2_CLIENT_ID environment variable is not set"
    exit 1
fi

if [ -z "$OAUTH2_CLIENT_SECRET" ]; then
    echo "Error: OAUTH2_CLIENT_SECRET environment variable is not set"
    exit 1
fi

echo "Using OAUTH2_CLIENT_ID: $OAUTH2_CLIENT_ID"

# Create SSL certificates for Dex
mkdir -p ssl

cat << EOF > ssl/req.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = dex.example.com
EOF

openssl genrsa -out ssl/ca-key.pem 2048
openssl req -x509 -new -nodes -key ssl/ca-key.pem -days 10 -out ssl/ca.pem -subj "/CN=kube-ca"

openssl genrsa -out ssl/key.pem 2048
openssl req -new -key ssl/key.pem -out ssl/csr.pem -subj "/CN=kube-ca" -config ssl/req.cnf
openssl x509 -req -in ssl/csr.pem -CA ssl/ca.pem -CAkey ssl/ca-key.pem -CAcreateserial -out ssl/cert.pem -days 10 -extensions v3_req -extfile ssl/req.cnf

# Create the namespace for Dex (if it doesn't exist)
if ! kubectl get namespace dex >/dev/null 2>&1; then
    echo "Creating dex namespace..."
    kubectl create namespace dex
else
    echo "Namespace dex already exists, skipping creation"
fi

# Create the TLS sercrets in the Kubernetes cluster
kubectl create --namespace dex secret generic tls --from-file=ssl/ca.pem --from-file=ssl/cert.pem --from-file=ssl/key.pem

# Create secret for the Oauth2 client
kubectl create --namespace dex secret generic oauth2-client --from-literal=client-id="$OAUTH2_CLIENT_ID" --from-literal=client-secret="$OAUTH2_CLIENT_SECRET"
