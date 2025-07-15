# Affinity and Anti-affinity

With `nodeAffinity`/`nodeAntiAffinity`, the `requiredDuringSchedulingIgnoredDuringExecution` key functions like a `nodeSelector`. You can specify keys and values that might exist on node(s), and the scheduler will only schedule the pod on the node that has these keys and values. For `preferredDuringSchedulingIgnoredDuringExecution` the scheduler will do its best effort to schedule on the node that has the keys and values you specify.

For `podAffinity`/`podAntiAffinity` you specify a `topologyKey` which is used to denote the domain of nodes the scheduler will look at. You also give it a set of keys/values that pods might have that could already be scheduled onto the nodes. The scheduler will then schedule pods on the node (according to `required**` or `preferred**`) if pods already exists or do not exist on the node(s) already and if they possess the keys/values you specified.

# Taints and Tolerations
Taints and toerlations are used for repelling pods to be scheduled onto certain nodes.

Example: if a node has a taint "yoofi=quansah:NoSchedule", no pods will be able to be scheduled onto this node until it has a matching toleration. However, the pod can schedule on other nodes that do not have the taint.

The `kubelet` can place taints on nodes based on resource availability. If the node is running low on disk space, or has memory pressure, it can place necessary taints on the node so that pods will not be able to schedule onto those nodes.
