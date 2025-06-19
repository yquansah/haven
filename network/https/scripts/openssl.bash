#!/bin/bash

# This is openssl version 3.3.2

# The below command will print the certificate () in a human-readable format.
# It will include details about the issuer, subject, serial number, validity period, and more.
openssl x509 -in tls.crt -noout -text

# Generate a private key for the certificate authority
# This is used to sign the certificate
openssl genrsa -out server.key 2048

# Generate a certificate signing request (CSR) for the server certificate
# This is used to request a certificate from the certificate authority
# This certficate is only valid for the domain "example.com"
openssl req -new -key server.key -out request.csr \
-subj "/C=US/ST=California/L=City/O=Hyperbolic/OU=Unit/CN=example.com"

# Generate a self-signed certificate for the server
openssl x509 -req -in request.csr -signkey server.key -out server.crt -days 365
