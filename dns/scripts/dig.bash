#!/bin/bash

# Look for A records of a particular domain
dig <domain_name> A

# Look for MX records of a particular domain
dig <domain_name> MX

# Reverse DNS lookup
dig -x <ip_address>
