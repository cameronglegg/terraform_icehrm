terraform {
  required_providers {
    linode = {
        source = "linode/linode"
    }
  }
}

# variables
variable "token" {}
variable "root_pass" {}

# proivder
provider "linode" {
    token = var.token
    api_version = "v4beta"
}

#Deploy Linode Server
resource "linode_instance" "icehrm" {
  label = "icehrm_terraform"
  image = "linode/debian9"
  region = "ca-central"
  type = "g6-standard-1"
  root_pass = var.root_pass

# These provisioners are only called on init setup. You need to destroy before they are called.
  # provisioner/webserverscript
  provisioner "file" {
    source = "setup_script.sh"
    destination = "/tmp/setup_script.sh"
    connection {
      type = "ssh"
      host = self.ip_address
      user = "root"
      password = var.root_pass
    }
  }

  #provisioner/remote exectution session to run the script
  provisioner "remote-exec" {
    inline = [
      # Adding executable permissions
      "chmod +x /tmp/setup_script.sh",
      # calling the script
      "/tmp/setup_script.sh",
      # testing showed this worked
      "sleep 1"
    ]
    # This block also needs a connection defined
    connection {
      type = "ssh"
      host = self.ip_address
      user = "root"
      password = var.root_pass
    }
  }
}

# domain
resource "linode_domain" "cam_example_domain" {
  domain = "camglegg.xyz"
  soa_email = "cameron@stirlingwoodworks.com"
  type = "master"
}

# domain record
resource "linode_domain_record" "example_domain_record" {
  domain_id = linode_domain.cam_example_domain.id
  name = "camglegg.xyz"
  record_type = "A"
  target = linode_instance.icehrm.ip_address
  ttl_sec = 300
}

# firewall
resource "linode_firewall" "icehrm_firewall" {
  label = "icehrm_firewall_label"

  inbound {
    label = "allow-http"
    action = "ACCEPT"
    protocol = "TCP"
    ports = "80"
    ipv4 = ["0.0.0.0/0"]
    ipv6 = ["ff00::/8"]
  }
  inbound_policy = "DROP"

  outbound_policy = "ACCEPT"

  linodes = [linode_instance.icehrm.id]
}