variable aws_region {
  type        = string
  default     = "us-east-1"
  description = "aws region"
}

variable osuser {
  default = "ubuntu"
  description = "default user name"
}

variable ssh_key_path {
  default = "~/.ssh/taxis.pem"
  description = "default privatekey"
}

variable key_name {
  type = string
  default = "taxis"
  description = "name of public key in aws"
}

variable testlist {
    type = list(string)
    default = [ "10.0.0.1",
                "10.0.0.2",
                "10.0.0.3",
                "10.0.0.4",
                "10.0.0.5",
                "10.0.0.6",
                "10.0.0.7",
    ]
}