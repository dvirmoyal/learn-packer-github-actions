packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu-lts" {
  region = "il-central-1"
  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
    }
    owners      = ["099720109477"]
    most_recent = true
  }
  instance_type  = "t3.micro"
  ssh_username   = "ubuntu"
  ssh_agent_auth = false

  ami_name    = "hashicups_{{timestamp}}"
  ami_regions = ["il-central-1"]
}

build {
  # HCP Packer settings
  hcp_packer_registry {
    bucket_name = "learn-packer-github-actions"
    description = <<EOT
This is an image for HashiCups.
    EOT

    bucket_labels = {
      "hashicorp-learn" = "learn-packer-github-actions",
    }
  }

  sources = [
    "source.amazon-ebs.ubuntu-lts",
  ]

  # systemd unit for HashiCups service
  provisioner "file" {
    source      = "hashicups.service"
    destination = "/tmp/hashicups.service"
  }

  # Set up HashiCups
  provisioner "shell" {
    scripts = [
      "setup-deps-hashicups.sh"
    ]
  }

  post-processor "manifest" {
    output     = "packer_manifest.json"
    strip_path = true
    custom_data = {
      version_fingerprint = packer.versionFingerprint
    }
  }
}
