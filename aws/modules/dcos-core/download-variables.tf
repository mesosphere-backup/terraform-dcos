variable "dcos_download_path" {
  type = "map"

  default = {
   "1.7-open"   = "https://downloads.dcos.io/dcos/EarlyAccess/commit/14509fe1e7899f439527fb39867194c7a425c771/dcos_generate_config.sh"
   "1.8.0"      = "https://downloads.dcos.io/dcos/EarlyAccess/commit/586c0496863000322c016c631e463248d863690d/dcos_generate_config.sh"
   "1.8.1"      = "https://downloads.dcos.io/dcos/EarlyAccess/commit/c1915a9f9f02caf7e34022eaea04f15ff853bd0e/dcos_generate_config.sh"
   "1.8.2"      = "https://downloads.dcos.io/dcos/EarlyAccess/commit/4cfc235259a2375c558f2e1bab3564419110459e/dcos_generate_config.sh"
   "1.8.3"      = "https://downloads.dcos.io/dcos/EarlyAccess/commit/636f8b72288e82ad3b0065928e0b492af4c7cf66/dcos_generate_config.sh"
   "1.8.4"      = "https://downloads.dcos.io/dcos/stable/commit/e64024af95b62c632c90b9063ed06296fcf38ea5/dcos_generate_config.sh"
   "1.8.5"      = "https://downloads.dcos.io/dcos/stable/commit/e665123df0dbb19adacaefe47d16a3de144d5733/dcos_generate_config.sh"
   "1.8.6"      = "https://downloads.dcos.io/dcos/stable/commit/cfccfbf84bbba30e695ae4887b65db44ff216b1d/dcos_generate_config.sh"
   "1.8.7"      = "https://downloads.dcos.io/dcos/stable/commit/1b43ff7a0b9124db9439299b789f2e2dc3cc086c/dcos_generate_config.sh"
   "1.8.8"      = "https://downloads.dcos.io/dcos/stable/dcos_generate_config.sh"
   "1.9.0-rc1"  = "https://downloads.dcos.io/dcos/EarlyAccess/commit/26d16366a29aba258541a8653b00522c4c1c21fc/dcos_generate_config.sh"
   "1.9.0-rc2"  = "https://downloads.dcos.io/dcos/EarlyAccess/commit/7f1ce42734aa54053291f403d71e3cb378bd13f3/dcos_generate_config.sh"
   "1.9.0-rc3"  = "https://downloads.dcos.io/dcos/EarlyAccess/commit/e5b5e6e336763ba9c8ed2d8266c798873e501cb2/dcos_generate_config.sh"
   "1.9.0-rc4"  = "https://downloads.dcos.io/dcos/EarlyAccess/commit/10b4b02efc86e0e6d7f19d3734c766f5580d04d4/dcos_generate_config.sh"
   "1.9.0"      = "https://downloads.dcos.io/dcos/stable/commit/0ce03387884523f02624d3fb56c7fbe2e06e181b/dcos_generate_config.sh"
  }
}
