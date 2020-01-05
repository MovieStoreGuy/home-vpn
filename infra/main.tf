module "home-vpn-infra" {
  source = "./modules/do-vpn"

  domain       = var.domain-name
  do-token     = var.digital-ocean-token
  ssh_key_name = var.ssh-key-name
}
