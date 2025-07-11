[control_plane]
control-plane-0 ansible_host=${control_plane_ip} ansible_user=${ssh_user}

[worker_nodes]
%{ for idx, ip in worker_ips ~}
worker-${idx} ansible_host=${ip} ansible_user=${ssh_user}
%{ endfor ~}

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'