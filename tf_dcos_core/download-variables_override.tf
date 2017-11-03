variable "dcos_download_path" {
  type = "map"


  default = {
   "1.7"      = "https://s3.amazonaws.com/downloads.mesosphere.io/dcos/testing/CM.7/dcos_generate_config.ee.sh"
   "1.7.1"      = "https://s3.amazonaws.com/downloads.mesosphere.io/dcos/testing/CM.7.1/dcos_generate_config.ee.sh"
   "1.7.2"      = "https://s3.amazonaws.com/downloads.mesosphere.io/dcos/testing/CM.7.2/dcos_generate_config.ee.sh"
   "1.7.3"      = "https://s3.amazonaws.com/downloads.mesosphere.io/dcos/testing/CM.7.3/dcos_generate_config.ee.sh"
   "1.7.4"      = "https://s3.amazonaws.com/downloads.mesosphere.io/dcos/testing/CM.7.4/dcos_generate_config.ee.sh"
   "1.8"        = "https://downloads.mesosphere.com/dcos-enterprise/testing/1.8/dcos_generate_config.ee.sh"
   "1.8.1"      = "https://downloads.mesosphere.com/dcos-enterprise/testing/1.8.1/dcos_generate_config.ee.sh"
   "1.8.2"      = "https://downloads.mesosphere.com/dcos-enterprise/testing/1.8.2/dcos_generate_config.ee.sh"
   "1.8.3"      = "https://downloads.mesosphere.com/dcos-enterprise/testing/1.8.3/dcos_generate_config.ee.sh"
   "1.8.4"      = "https://downloads.mesosphere.com/dcos-enterprise/stable/commit/5bf8127b7e5d24cb24e52c6b1fc1b7190397028c/dcos_generate_config.ee.sh"
   "1.8.5"      = "https://downloads.mesosphere.com/dcos-enterprise/stable/commit/722fcc50c4ac556a9484836bf8a3bb4add4bf14d/dcos_generate_config.ee.sh"
   "1.8.6"      = "https://downloads.mesosphere.com/dcos-enterprise/stable/commit/f98ac7040d67cacdafed71642eb6bc1b663a238e/dcos_generate_config.ee.sh"
   "1.8.7"      = "https://downloads.mesosphere.io/dcos-enterprise/stable/commit/3081d761d0ff1c64a48c71bb4c1fef7c72ffe52d/dcos_generate_config.ee.sh"
   "1.8.8"      = "https://downloads.mesosphere.io/dcos-enterprise/stable/commit/84c7427fd3c0078ac10786765c9c25b60adefd61/dcos_generate_config.ee.sh"
   "1.8.9"      = "https://downloads.mesosphere.com/dcos-enterprise/stable/1.8.9/dcos_generate_config.ee.sh"
   "1.9.0-rc1"  = "https://downloads.mesosphere.com/dcos-enterprise/testing/1.9.0-rc1/dcos_generate_config.ee.sh"
   "1.9.0-rc2"  = "https://downloads.mesosphere.com/dcos-enterprise/testing/1.9.0-rc2/dcos_generate_config.ee.sh"
   "1.9.0-rc3"  = "https://downloads.mesosphere.com/dcos-enterprise/testing/1.9.0-rc3/dcos_generate_config.ee.sh"
   "1.9.0-rc4"  = "https://downloads.mesosphere.com/dcos-enterprise/testing/1.9.0-rc4/dcos_generate_config.ee.sh"
   "1.9.0"      = "https://downloads.mesosphere.io/dcos-enterprise/stable/commit/9698bd296ded3f70f52346f2284c3c69f50f7fd0/dcos_generate_config.ee.sh"
   "1.9.1"      = "https://downloads.mesosphere.com/dcos-enterprise/stable/1.9.1/dcos_generate_config.ee.sh"
   "1.9.2"      = "https://downloads.mesosphere.com/dcos-enterprise/stable/1.9.2/dcos_generate_config.ee.sh"
   "1.9.3"      = "https://downloads.mesosphere.com/dcos-enterprise/stable/1.9.3/dcos_generate_config.ee.sh"
   "1.9.4"      = "https://downloads.mesosphere.com/dcos-enterprise/stable/1.9.4/dcos_generate_config.ee.sh"
   "1.9.5"      = "https://downloads.mesosphere.com/dcos-enterprise/stable/1.9.5/dcos_generate_config.ee.sh"
   "1.10.0"     = "https://downloads.mesosphere.com/dcos-enterprise/stable/1.10.0/dcos_generate_config.ee.sh"
   "1.10.1"     = "https://downloads.mesosphere.com/dcos-enterprise/stable/1.10.1/dcos_generate_config.ee.sh"
  }
}
