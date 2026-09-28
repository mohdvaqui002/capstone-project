output "servers" {
  description = "Addresses for SSH and subsequent Ansible configuration."
  value = {
    for name, server in aws_instance.server : name => {
      instance_id = server.id
      public_ip   = server.public_ip
      private_ip  = server.private_ip
      ssh_user    = "ubuntu"
    }
  }
}

output "jenkins_url" {
  description = "Available only after Jenkins is installed and configured."
  value       = "http://${aws_instance.server["jenkins"].public_ip}:8080"
}

output "website_urls" {
  description = "Available after Kubernetes, the application and NodePort 30008 are configured."
  value       = [for name in ["worker-1", "worker-2"] : "http://${aws_instance.server[name].public_ip}:30008"]
}

output "vpc_id" {
  value = aws_vpc.lab.id
}
