#!/bin/bash
terraform -chdir=./terraform apply -auto-approve -var="ssh_public_key=${SSH_PUBLIC_KEY}"

CONTROL_PLANE_HOSTNAME=$(aws ec2 describe-instances --filters "Name=tag:Component,Values=control-plane-node" --output text --query "Reservations[].Instances[].PublicIpAddress")
LOAD_BALANCER_HOST=$(aws elbv2 describe-load-balancers --output text --query "LoadBalancers[0].DNSName")
LOAD_BALANCER_PORT=6443

ssh ubuntu@"$CONTROL_PLANE_HOSTNAME" \
  "LOAD_BALANCER_HOST=$LOAD_BALANCER_HOST LOAD_BALANCER_PORT=$LOAD_BALANCER_PORT bash -s" <<"EOF"
  #!/bin/bash
  NODENAME=$(hostname -s)
  sudo kubeadm init --control-plane-endpoint="$LOAD_BALANCER_HOST:$LOAD_BALANCER_PORT" --apiserver-cert-extra-sans="$LOAD_BALANCER_HOST" --pod-network-cidr="192.168.0.0/16" --node-name "$NODENAME" --ignore-preflight-errors Swap
  sudo kubectl apply --kubeconfig=/etc/kubernetes/admin.conf -f https://docs.projectcalico.org/manifests/calico.yaml
  sudo kubectl set env --kubeconfig=/etc/kubernetes/admin.conf daemonset/calico-node -n kube-system IP_AUTODETECTION_METHOD=interface=ens5
  # curl -LO https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
  # sed -i '/net-conf.json:/,/Backend:/s/"Network": "10.244.0.0\/16"/"Network": "192.168.0.0\/16"/' kube-flannel.yml
  # sudo kubectl --kubeconfig /etc/kubernetes/admin.conf apply -f kube-flannel.yml
  sudo cp /etc/kubernetes/admin.conf admin.conf
  sudo chown ubuntu:ubuntu admin.conf
  sudo kubeadm token create --print-join-command > command.txt
EOF

scp -r ubuntu@"$CONTROL_PLANE_HOSTNAME":./* .

TOKEN=$(cat command.txt | awk -F'--token ' '{print $2}' | awk '{print $1}')
CA_CERT_HASH=$(cat command.txt | awk -F'--discovery-token-ca-cert-hash ' '{print $2}' | awk '{print $1}')

for hostname in $(aws ec2 describe-instances --filters "Name=tag:Component,Values=worker-node" --output text --query "Reservations[].Instances[].PublicIpAddress"); do
  ssh ubuntu@"$hostname" \
    "LOAD_BALANCER_HOST=$LOAD_BALANCER_HOST LOAD_BALANCER_PORT=$LOAD_BALANCER_PORT TOKEN=$TOKEN CA_CERT_HASH=$CA_CERT_HASH bash -s" <<"EOF"
    #!/bin/bash
    sudo kubeadm join "$LOAD_BALANCER_HOST:$LOAD_BALANCER_PORT" --token "$TOKEN" --discovery-token-ca-cert-hash "$CA_CERT_HASH"
EOF
done

rm command.txt
