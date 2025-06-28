## Kubernetes network model

Pods all have a unique IP Address across the whole cluster, and they should be able to communicate with each other via IP whether they are on the same node or they exist on different nodes. Services are allocated a singular IP address and route to their backend pods which can change often. Kubernetes uses the EndpointSlice object to provide information about pods backing a service.

The pod network is an implementation usually handled by providers such as Calico, Flannel, etc. This provides functionality for Pods to communicate with each other throughout the cluster.

[CoreDNS](https://github.com/coredns/coredns) provides a DNS service for the cluster. It provides a way for pods to talk to services via DNS names, and pods to talk to other pods via DNS names as well. You can configure CoreDNS with a `Corefile`. This specifies exactly how your DNS queries should be answered. There are ways to configure CoreDNS to forward DNS queries to upstream DNS servers such as `8.8.8.8`, which is Google, and forward the rest to some other configuration.

The example Corefile:

```
example.org {
    forward . 8.8.8.8
    log
}

. {
    forward . /etc/resolv.conf
    log
}
```

will forward queries for `example.org` to Google Public DNS, and the rest of the queries to `resolv.conf`. CoreDNS basically contacts the Kubernetes API server for the various IPs for pods and services, and caches that information for subsequent requests to reduce load on the Kubernetes API server.

Every pod created in the Kubernetes cluster will get an `/etc/resolv.conf` that will forward DNS queries to a specific upstream server. The upstream server is a Virtual IP, which is intercepted by the Kernel via iptable rules and routed to the CoreDNS backend to retrieve answers for the DNS query.

Playing around with `dig` you can specify the host of your DNS server for answers like so:

```
dns @{HOST} -p {PORT} example.com
```

This will query the host at the specified port for answers on example.com.

In order for a pod to get DNS answers for their DNS queries it follows this journey:

```
Pod on Node A → iptables (rewrites VIP to real pod IP) → Cluster Network → CoreDNS Pod on Node B
```

The `Cluster Network` is pluggable via flannel, or calico.
