# Link to documentation: https://www.terraform.io/docs/providers/do/index.html
# Link to repo: https://github.com/terraform-providers/terraform-provider-digitalocean
provider "digitalocean" {
  token = "${var.token}"

  version = "v1.12.0"
}

resource "digitalocean_ssh_key" "configuring_key" {
  name       = "${var.ssh_key_name}"
  public_key = file("~/.ssh/id_rsa.pub")
}


# Home VPN server configuration
resource "digitalocean_droplet" "home-vpn" {
  name   = "home-vpn-server"
  image  = "fedora-30-x64"
  region = "lon1"
  size   = "s-1vcpu-2gb" # Size definitions can be found here: https://developers.digitalocean.com/documentation/v2/#list-all-sizes

  private_networking = true # Allows this droplet to communicate with other droplets in the same region on the same account
  ssh_keys           = [digitalocean_ssh_key.configuring_key.fingerprint]
  tags               = "${concat(var.tags, "home-vpn")}"
}

# The firewall is the most important part as we need to allow anyone access it from the same network
# to work freely, anything outside the configured network should be heavily filtered 
resource "digitalocean_firewall" "home-vpn" {
  name = "Home VPN Firewall"

  droplet_ids = [
    digitalocean_droplet.home-vpn.id
  ]

  # Inbound rules for the home VPN server
  # Opens up connections for SSH from anywhere
  # Allows VPN clients and serving site content over 443
  inbound_rule {
    protocol         = "tcp" # Ensure that we can allow SSH
    port_range       = "22"
    source_addresses = ["0.0.0.0/0"] # Allow Any inbound connection try attemp ssh'ing in
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol         = "tcp" # Opens up the HTTPS port to allow for OpenVPN / static sites served over SSL
    port_range       = "443"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol         = "udp" # Opens up the required UDP port for VPN clients
    port_range       = "1194"
    source_addresses = ["0.0.0.0/0"]
  }

  # Allow local inbound / outbound connections on the configured network
  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["10.0.0.0/8"]
  }

  inbound_rule {
    protocol         = "udp"
    source_addresses = ["10.0.0.0/8"]
  }

  inbound_rule {
    protocol         = "tcp"
    source_addresses = ["10.0.0.0/8"]
  }

  outbound_rule {
    protocol               = "icmp"
    destinations_addresses = ["10.0.0.0/8"]
  }

  outbound_rule {
    protocol               = "udp"
    destinations_addresses = ["10.0.0.0/8"]
  }

  outbound_rule {
    protocol               = "tcp"
    destinations_addresses = ["10.0.0.0/8"]
  }
}
