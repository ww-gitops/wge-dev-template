provider "aws" {
  region = var.region

  default_tags {
    tags = merge({
      source  = "Terraform Managed"
      resource = var.resource_name
    }, var.tags, local.tags)
  }
}

provider "gitlab" {
  base_url = "${var.gitlab_url}/api/v4"
  token    = var.gitlab_token
}

data "gitlab_group" "owner" {
  full_path = var.gitlab_owner
}

data "gitlab_project" "main" {
  path_with_namespace = "${data.gitlab_group.owner.path}/${var.repository_name}"
}

locals {
  gitlab_repository = data.gitlab_project.main

  target_path         = "clusters/${var.template_namespace}/${var.resource_name}/edge-nodes/${local.edge_node_name}"
  gitlab_hostname     = replace(var.gitlab_url, "/(https?://)/", "")
  edge_node_name      = format("%s-%s", var.resource_name, var.name)
  tags = {
    "Name" = local.edge_node_name
  }
  public_subnet_id   = flatten([split(",", var.public_subnets_string), split(",", var.public_subnets_string)])[0]
  private_subnet_id  = flatten([split(",", var.private_subnets_string), split(",", var.private_subnets_string)])[0]
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "edge_instance_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "edge_instance_role" {
  assume_role_policy = data.aws_iam_policy_document.edge_instance_assume_role.json
  name               = local.edge_node_name

}

resource "aws_iam_role_policy_attachment" "edge_instance_policy_attachment" {
  role       = aws_iam_role.edge_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "profile" {
  name = local.edge_node_name
  role = aws_iam_role.edge_instance_role.name
}

resource "aws_security_group" "instance" {
  name        = local.edge_node_name
  description = "Allow ssh and k8s inbound traffic"
  vpc_id      = var.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group_rule" "k8s" {
  description      = "k8s from client"
  from_port        = 6443
  to_port          = 6443
  protocol         = "tcp"
  cidr_blocks      = [var.source_cidr]
  security_group_id = aws_security_group.instance.id
  type = "ingress"
}

resource "aws_security_group_rule" "k8s-internal" {
  description      = "k8s on public ip from instance"
  from_port        = 0
  to_port          = 0
  protocol         = "tcp"
  source_security_group_id = aws_security_group.instance.id
  security_group_id = aws_security_group.instance.id
  type = "ingress"
}

resource "aws_security_group_rule" "http" {
  description      = "http from client"
  from_port        = 80
  to_port          = 80
  protocol         = "tcp"
  cidr_blocks      = [var.source_cidr]
  security_group_id = aws_security_group.instance.id
  type = "ingress"
}

resource "aws_security_group_rule" "https" {
  description      = "https from client"
  from_port        = 443
  to_port          = 443
  protocol         = "tcp"
  cidr_blocks      = [var.source_cidr]
  security_group_id = aws_security_group.instance.id
  type = "ingress"
}

resource "aws_security_group_rule" "ssh" {
  description      = "ssh from client"
  from_port        = 22
  to_port          = 22
  protocol         = "tcp"
  cidr_blocks      = [var.source_cidr]
  security_group_id = aws_security_group.instance.id
  type = "ingress"
}

resource "aws_network_interface" "edge_node" {
    subnet_id        = local.public_subnet_id
    security_groups = [aws_security_group.instance.id]
}

resource "aws_eip" "edge_node" {
  network_interface         = aws_network_interface.edge_node.id
}

#
# route53 routing
#
data "aws_route53_zone" "main" {
  name = var.route53_main_domain
}

resource "aws_route53_zone" "sub" {
  name          = "${var.name}-${var.resource_name}.${var.route53_main_domain}"
  force_destroy = true
}

resource "aws_route53_record" "sub_ns" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = aws_route53_zone.sub.name
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.sub.name_servers
}

resource "aws_route53_record" "edge_node_record" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = aws_route53_zone.sub.name
  type    = "A"
  ttl     = "300"
  records = [aws_eip.edge_node.public_ip]
}

resource "local_file" "cloud_init" {
    content  = <<-EOT
    #!/usr/bin/env bash

    set -x

    export PATH=$PATH:/usr/local/bin

    amazon-linux-extras install epel -y

    echo "Updating system packages & installing required utilities"
    yum-config-manager --enable epel
    yum update -y
    yum install -y jq curl unzip git tc yum-utils
    curl $curl_proxy_opt "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm" -o "session-manager-plugin.rpm"
    sudo yum install -y session-manager-plugin.rpm
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
    sudo yum -y install vault

    curl -s https://fluxcd.io/install.sh | sudo bash

    echo "#!/usr/bin/env bash" > /usr/local/bin/install-awscli.sh
    echo "TMPDIR=$(mktemp -d)" >> /usr/local/bin/install-awscli.sh
    echo "pushd $TMPDIR" >> /usr/local/bin/install-awscli.sh
    echo 'curl $curl_proxy_opt "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"' >> /usr/local/bin/install-awscli.sh
    echo "unzip -q awscliv2.zip >/dev/null" >> /usr/local/bin/install-awscli.sh
    echo "./aws/install >/dev/null" >> /usr/local/bin/install-awscli.sh
    echo "popd" >> /usr/local/bin/install-awscli.sh
    chmod 755 /usr/local/bin/install-awscli.sh
    /usr/local/bin/install-awscli.sh

    export AWS_REGION=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
    
    TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
    curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/iam/security-credentials/${aws_iam_role.edge_instance_role.name}
    export AWS_ACCESS_KEY_ID=$(echo $iam | jq -r '."AccessKeyId"')
    export AWS_SECRET_ACCESS_KEY=$(echo $iam | jq -r '."SecretAccessKey"')
    export AWS_SESSION_TOKEN=$(echo $iam | jq -r '."Token"')

    echo "Installing SSM Agent"
    yum install -y https://s3.$AWS_REGION.amazonaws.com/amazon-ssm-$AWS_REGION/latest/linux_amd64/amazon-ssm-agent.rpm
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    systemctl status amazon-ssm-agent

    sudo swapoff -a
    sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

    cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
    overlay
    br_netfilter
    EOF

    sudo modprobe overlay
    sudo modprobe br_netfilter

    # sysctl params required by setup, params persist across reboots
    cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-iptables  = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    net.ipv4.ip_forward                 = 1
    EOF

    # Apply sysctl params without reboot
    sudo sysctl --system

    # Install containerd
    sudo yum install -y containerd

    # Generate and save containerd configuration file to its standard location
    sudo containerd config default | sudo tee /etc/containerd/config.toml

    # Restart containerd to ensure new configuration file usage:
    sudo systemctl restart containerd

    # Verify containerd is running.
    sudo systemctl status containerd

    cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
    [kubernetes]
    name=Kubernetes
    baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
    enabled=1
    gpgcheck=1
    gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
    exclude=kubelet kubeadm kubectl
    EOF

    # Set SELinux in permissive mode (effectively disabling it)
    sudo setenforce 0
    sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

    sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

    sudo systemctl enable --now kubelet

    sudo kubeadm init --pod-network-cidr 192.168.0.0/16 --apiserver-cert-extra-sans ${aws_route53_zone.sub.name},${aws_eip.edge_node.public_ip} 

    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    export KUBECONFIG=/etc/kubernetes/admin.conf

    kubectl taint nodes --all node-role.kubernetes.io/control-plane-

    # Install the Tigera Calico operator and custom resource definitions.
    kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml

    # Install Calico by creating the necessary custom resource. 
    kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/custom-resources.yaml

    # Test Control Plane node. Expected to be in Ready state this time
    kubectl get nodes

    cat $KUBECONFIG | sed s%https://.*:6443%https://${aws_eip.edge_node.public_ip}:6443%g > /tmp/kubeconfig

    export GITLAB_TOKEN=${var.gitlab_token}
    flux bootstrap gitlab --owner=${var.gitlab_owner} --repository=${var.repository_name} --branch=${var.branch} --token-auth \
      --path=${local.target_path}/flux

    # Output kubeconfig to vault
    cluster_name="${local.edge_node_name}"
    domain_suffix="$(kubectl get cm -n flux-system tf-output-values -o json | jq -r '.data.hostname')"
    export VAULT_ADDR="${var.vault_url}"
    export VAULT_TOKEN="$(aws secretsmanager get-secret-value --secret-id vault-leaf-token --query SecretString --output text)"
    vault kv put -mount=leaf-cluster-secrets leaf-clusters/${local.edge_node_name}-admin-kubeconfig value.yaml="$(cat /tmp/kubeconfig)"

    EOT
    filename = "/tmp/cloud-init.sh"
}

# Create secret for kubeconfig in management cluster

resource "gitlab_repository_file" "kubeconfig_secret" {
  project        = local.gitlab_repository.id
  branch         = var.branch
  file_path      = "clusters/management/secrets/leaf-clusters/${var.resource_name}-${var.name}-admin-kubeconfig.yaml"
  author_email   = var.git_commit_email
  author_name    = var.git_commit_author
  commit_message = "clusters/management/secrets/leaf-clusters/${var.resource_name}-${var.name}-admin-kubeconfig.yaml"
  content = base64encode(<<-EOF
    #
    # DO NOT EDIT - This file is managed by Terraform
    #
    ---
    apiVersion: external-secrets.io/v1beta1
    kind: ExternalSecret
    metadata:
      name: ${local.edge_node_name}-admin-kubeconfig
      namespace: default
    spec:
      refreshInterval: 5m
      secretStoreRef:
        kind: SecretStore
        name: vault-leaf-secrets
      target:
        name: ${local.edge_node_name}-admin-kubeconfig
        creationPolicy: Owner
      dataFrom:
        - extract:
            key: leaf-clusters/${local.edge_node_name}-admin-kubeconfig
  EOF
  )
}

resource "tls_private_key" "rsa_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = format("%s-%s", var.resource_name, var.name)
  public_key = tls_private_key.rsa_key.public_key_openssh
}

resource "aws_instance" "edge_node" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  user_data_base64 = base64encode(local_file.cloud_init.content)
  user_data_replace_on_change = true
  iam_instance_profile = aws_iam_instance_profile.profile.id
  key_name = aws_key_pair.ec2_key_pair.key_name

  network_interface {
      device_index            = 0
      network_interface_id    = aws_network_interface.edge_node.id
  }

  root_block_device {
    volume_size = 25
    volume_type = "gp2"
    delete_on_termination = true
  }
}
