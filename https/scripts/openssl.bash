#!/bin/bash

# The below command will print the certificate in a human-readable format.
# It will include details about the issuer, subject, serial number, validity period, and more.
openssl x509 -in </path/to/certificate> -noout -text

