#!/bin/bash

# Look for A records of the domain example.com
dig example.com A

# Look for MX records of the domain example.com
dig example.com MX

# Reverse DNS lookup for the IP address 192.168.1.1
dig -x 192.168.1.1
