data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_key_pair" "existing" {
  key_name = var.key_name
}

locals {
  servers = {
    jenkins       = "jenkins"
    control-plane = "control-plane"
    worker-1      = "worker"
    worker-2      = "worker"
  }
  admin_ports = {
    ssh        = { group = "ssh", port = 22 }
    jenkins    = { group = "jenkins", port = 8080 }
    kubernetes = { group = "control-plane", port = 6443 }
    website    = { group = "worker", port = 30008 }
  }
}

resource "aws_vpc" "lab" {
  cidr_block           = "10.42.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project_name}-vpc" }
}

resource "aws_subnet" "lab" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.42.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project_name}-public" }
}

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "${var.project_name}-igw" }
}

resource "aws_route_table" "lab" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "${var.project_name}-public" }
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.lab.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.lab.id
}

resource "aws_route_table_association" "lab" {
  subnet_id      = aws_subnet.lab.id
  route_table_id = aws_route_table.lab.id
}

resource "aws_security_group" "role" {
  for_each    = toset(["ssh", "jenkins", "control-plane", "worker", "cluster"])
  name_prefix = "${var.project_name}-${each.key}-"
  description = "Capstone ${each.key} traffic"
  vpc_id      = aws_vpc.lab.id
  tags        = { Name = "${var.project_name}-${each.key}" }
}

resource "aws_vpc_security_group_ingress_rule" "admin" {
  for_each          = local.admin_ports
  security_group_id = aws_security_group.role[each.value.group].id
  cidr_ipv4         = var.admin_cidr
  ip_protocol       = "tcp"
  from_port         = each.value.port
  to_port           = each.value.port
  description       = "Administrator ${each.key} access"
}

# The three Kubernetes nodes trust one another for kubeadm, kubelet and CNI traffic.
# This rule excludes Jenkins and external hosts.
resource "aws_vpc_security_group_ingress_rule" "cluster_internal" {
  security_group_id            = aws_security_group.role["cluster"].id
  referenced_security_group_id = aws_security_group.role["cluster"].id
  ip_protocol                  = "-1"
  description                  = "Internal Kubernetes node communication"
}

resource "aws_vpc_security_group_ingress_rule" "ansible" {
  security_group_id            = aws_security_group.role["cluster"].id
  referenced_security_group_id = aws_security_group.role["jenkins"].id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  description                  = "Ansible from Jenkins controller"
}

resource "aws_vpc_security_group_ingress_rule" "jenkins_api" {
  security_group_id            = aws_security_group.role["control-plane"].id
  referenced_security_group_id = aws_security_group.role["jenkins"].id
  ip_protocol                  = "tcp"
  from_port                    = 6443
  to_port                      = 6443
  description                  = "Jenkins Kubernetes deployments"
}

resource "aws_vpc_security_group_egress_rule" "outbound" {
  security_group_id = aws_security_group.role["ssh"].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Package downloads and container registry access"
}

resource "aws_instance" "server" {
  for_each      = local.servers
  ami           = coalesce(var.ami_id, data.aws_ami.ubuntu.id)
  instance_type = var.instance_type
  subnet_id     = aws_subnet.lab.id
  key_name      = data.aws_key_pair.existing.key_name
  vpc_security_group_ids = concat(
    [aws_security_group.role["ssh"].id, aws_security_group.role[each.value].id],
    each.key == "jenkins" ? [] : [aws_security_group.role["cluster"].id]
  )
  associate_public_ip_address = true
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
  }
  tags = {
    Name = "${var.project_name}-${each.key}"
    Role = each.value
  }
  depends_on = [aws_route.internet, aws_route_table_association.lab]
}
