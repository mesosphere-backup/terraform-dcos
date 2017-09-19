# Deploy Open DC/OS using Terraform

The purpose of this tool is to automate most of the manual efforts of managing and maintaining distributed systems. This project has a few important goals in mind since the inception of the project.

Goal: Make a modular and reusable script to easily decouple DC/OS on various OS and cloud providers to easily install, upgrade and modify in-place.

The dcos-core module has all the DC/OS unique install and upgrade instructions. These instructions are taken from the mesosphere.io and dcos.io documentation and modified a bit to make it allowed to be automated and templated by terraform. The dcos-core module was written in bash to allow flexibility to run on any linux operating system. It also has templates in the scripts to leverage the power of terraform to manage your cluster with very few commands. 

If you want to use this in your own environment, feel free to fork this and customize it to your specifications. This will be built so everybody can take advantage of deploying and manage DC/OS clusters.

## Getting Started

### Install Terraform

If you're on a mac environment with homebrew installed, run this command.

```bash
brew install terraform
```

If you want to leverage the terraform installer, feel free to check out https://www.terraform.io/downloads.html.

## Cloud Providers 

You can find aws terraform instructions for the respective clouds below:

 - [AWS Terraform](./aws/README.md)
 - [Azure Terraform](./azure/README.md)

# Roadmaps

  - [X] Support for AWS
  - [X] Support for Azure
  - [ ] Support for GCP
