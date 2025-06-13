# Network Monitoring and Utilities

All things network related - monitoring tools, diagnostic scripts, and network analysis utilities.

## Installing Network Monitoring Tools

### Installing iftop on Ubuntu

```bash
# Update package list
sudo apt update

# Install iftop
sudo apt install iftop -y

# Verify installation
iftop --version
```

## Network Activity Monitoring with iftop

### Basic Usage

```bash
# Monitor all network interfaces
sudo iftop

# Monitor specific interface (e.g., eth0)
sudo iftop -i eth0

# Display port numbers instead of service names
sudo iftop -P

# Display bandwidth in bytes instead of bits
sudo iftop -B

# Don't resolve hostnames (faster startup)
sudo iftop -n

# Show cumulative totals instead of averages
sudo iftop -t
```

### Advanced Usage

```bash
# Monitor only TCP traffic
sudo iftop -f "tcp"

# Monitor traffic to/from specific host
sudo iftop -f "host 192.168.1.100"

# Monitor specific port traffic
sudo iftop -f "port 80"

# Monitor and log to file for 60 seconds
sudo iftop -t -s 60 > network_usage.txt
```

### Reading iftop Output

The iftop interface shows:

- **Left column**: Source hosts/IPs
- **Right column**: Destination hosts/IPs
- **Middle arrows**: Direction of traffic flow
- **Three columns on right**: Traffic rates (2s, 10s, 40s averages)
- **Bottom stats**: TX (transmitted), RX (received), TOTAL

### Network Saturation Indicators

Watch for these signs that your network interface is saturated:

#### Bandwidth Utilization

- **TX/RX approaching interface limit**: If you see consistent traffic near your interface capacity (e.g., 950+ Mbps on gigabit)
- **Sustained high usage**: Traffic consistently above 80% of interface capacity for extended periods

#### Performance Indicators

- **High packet loss**: Use `ping` alongside iftop to check for dropped packets
- **Increased latency**: Network responses become noticeably slower
- **Buffer bloat**: Large queues building up, causing delays even when bandwidth available

#### iftop-specific Warning Signs

```bash
# Signs of saturation in iftop:
# 1. Multiple connections showing high sustained rates
# 2. Total TX + RX approaching physical interface limits
# 3. Many connections to the same destination (potential bottleneck)
# 4. Unusually high traffic from unexpected sources
```

#### Checking Interface Capacity

```bash
# Check interface speed and statistics
ethtool eth0

# Monitor interface errors and drops
cat /proc/net/dev

# Check current interface utilization
cat /sys/class/net/eth0/statistics/tx_bytes
cat /sys/class/net/eth0/statistics/rx_bytes
```

### Troubleshooting High Network Usage

1. **Identify top talkers**: Look for hosts with consistently high traffic
2. **Check for unexpected traffic**: Monitor for unusual destinations or protocols
3. **Verify legitimate usage**: Ensure high traffic corresponds to expected applications
4. **Consider traffic shaping**: Implement QoS if certain applications are consuming excessive bandwidth

## DNS Resolution with dig

The `dig` (Domain Information Groper) command is a powerful DNS lookup tool for troubleshooting DNS issues and querying DNS records.

### Basic dig Usage

```bash
# Basic A record lookup
dig example.com

# Query specific record type
dig example.com A
dig example.com AAAA
dig example.com MX
dig example.com NS
dig example.com TXT
dig example.com CNAME

# Reverse DNS lookup
dig -x 8.8.8.8
dig -x 192.168.1.1

# Query specific DNS server
dig @8.8.8.8 example.com
dig @1.1.1.1 example.com A
```

### Advanced dig Options

```bash
# Short output (just the answer)
dig +short example.com
dig +short example.com MX

# Trace the full DNS resolution path
dig +trace example.com

# Query all record types
dig example.com ANY

# Disable recursion (query authoritative servers only)
dig +norecurse example.com

# Show query time and server used
dig +stats example.com

# Query multiple domains
dig example.com google.com
```

### Common DNS Record Types

```bash
# A Record - IPv4 address
dig example.com A

# AAAA Record - IPv6 address
dig example.com AAAA

# MX Record - Mail exchange servers
dig example.com MX

# NS Record - Name servers
dig example.com NS

# TXT Record - Text records (SPF, DKIM, etc.)
dig example.com TXT

# CNAME Record - Canonical name (aliases)
dig www.example.com CNAME

# SOA Record - Start of Authority
dig example.com SOA

# PTR Record - Reverse DNS
dig -x 192.168.1.1
```

### What to Watch Out For

#### DNS Resolution Issues

```bash
# Check for DNS propagation issues
dig example.com @8.8.8.8     # Google DNS
dig example.com @1.1.1.1     # Cloudflare DNS
dig example.com @208.67.222.222  # OpenDNS

# Different results may indicate propagation delays
```

#### Common Warning Signs

1. **NXDOMAIN Status**: Domain doesn't exist
2. **SERVFAIL Status**: DNS server error
3. **High Query Times**: Network or DNS server issues (> 1000ms)
4. **Missing Records**: Expected record types not found

#### TTL (Time To Live) Considerations

```bash
# Low TTL values (< 300) may indicate:
# - Recent DNS changes
# - Load balancing/failover setup
# - Frequent IP changes

# High TTL values (> 86400) may indicate:
# - Stable infrastructure
# - Potential delays in DNS updates
```

#### Security Considerations

```bash
# Check for suspicious DNS responses
dig +trace example.com | grep -E "(NXDOMAIN|SERVFAIL|timeout)"

# Verify DNSSEC if enabled
dig +dnssec example.com

# Check for DNS hijacking by comparing multiple resolvers
dig @8.8.8.8 suspicious-domain.com
dig @1.1.1.1 suspicious-domain.com
dig @208.67.222.222 suspicious-domain.com
```

#### Troubleshooting DNS Issues

1. **Compare multiple DNS servers**: Ensure consistent responses
2. **Check TTL values**: Low TTL might indicate recent changes
3. **Use +trace**: Follow the complete DNS resolution path
4. **Test reverse DNS**: Verify PTR records match forward lookup
5. **Monitor query times**: Slow responses may indicate network issues
