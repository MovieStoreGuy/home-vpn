variable "do-token" {
    description = "Access token for Digital Ocean"
}

variable "domain" {
    description = "Define the domain (URL) of where to configure the droplet"
}

variable "ssh_key_name" {
    description = "Fingerprint IDs in the list of an array"
}

variable "tags" {
    default = []
    description = "Define what tags should be applied to the service"
}
