packer {
  required_version = ">= 1.8.0"
  required_plugins {
    virtualbox = {
      version = ">= 1.0.4"
      source = "github.com/hashicorp/virtualbox"
    }
  }
}

locals {
  vm_id = var.server_name == "" ? "${var.vm_guest_os_name}${var.vm_guest_os_version}" : "${var.server_name}"
  build_by = "Built by: ${var.build_script_username} with Packer ${packer.version}"
  build_date = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
  ssh_username = var.build_username == "" ? "root" : var.build_username
  ssh_password = var.build_username == "" ? var.root_password : var.build_password
  ansible_roles_path = pathexpand("${path.cwd}/.ansible-galaxy/roles")
  ansible_collections_path = pathexpand("${path.cwd}/.ansible-galaxy/collections")
  description = "Built on: ${local.build_date}\n${local.build_by}\nServer: ${var.server_name}\nISO: ${var.iso_file}\nGit Branch: ${var.git_branch} (${var.git_commit})\nGit URL: ${var.git_remote_url}\nBuilder: ${var.builder_info}"
  data_source_content = {
    "/ks.cfg" = templatefile("${abspath(path.root)}/data/ks.pkrtpl.hcl", {
      root_password_encrypted = var.root_password_encrypted,
      build_username = var.build_username,
      build_password_encrypted = var.build_password_encrypted,
      vm_guest_os_language = var.vm_guest_os_language,
      vm_guest_os_keyboard = var.vm_guest_os_keyboard,
      vm_guest_os_timezone = var.vm_guest_os_timezone,
      os_packages = var.os_packages,
      vm_packages = var.vm_packages,
      vm_modules = var.vm_modules,
      vm_reboot_halt_shutdown_command = var.vm_reboot_halt_shutdown_command,
      vm_disk_partitions = var.vm_disk_partitions,
      vm_volgroup = var.vm_volgroup,
      vm_swap_size = var.vm_swap_size,
      vm_logical_volumes = var.vm_logical_volumes,
      vm_hostname = var.vm_hostname,
      build_with_dvd_contents = var.build_with_dvd_contents,
      vm_desktop_environment = var.vm_desktop_environment
    })
  }
  build_info_content = templatefile("${abspath(path.cwd)}/builds/info.pkrtpl.json", {
    builder_info = var.builder_info
    vm_id = local.vm_id
    build_version = var.build_version
    build_by = "${var.build_script_username} with Packer ${packer.version}"
    build_date = local.build_date
    config_id = var.config_id
    vm_disk_size = var.vm_disk_size
    vm_guest_os_family = var.vm_guest_os_family
    vm_guest_os_name = var.vm_guest_os_name
    vm_guest_os_version = var.vm_guest_os_version
    iso_file = var.iso_file
    iso_checksum_value = var.iso_checksum_value
    git_branch = var.git_branch,
    git_commit = var.git_commit,
    git_remote_url = var.git_remote_url
  })
}

source "virtualbox-iso" "linux-rhel" {
  vm_name = "${local.vm_id}"
  http_content = local.data_source_content
  boot_wait = var.vm_boot_wait
  boot_command = [
    "<wait><tab><wait>",
    "<end><spacebar><wait>",
    "text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg",
    "<wait><enter>"
  ]
  headless = var.virtualbox_headless

  # Execute: `VBoxManage list ostypes` to view types
  guest_os_type = var.virtualbox_guest_os_type
  disk_size = var.vm_disk_size
  hard_drive_interface = var.virtualbox_hard_drive_interface

  iso_url = "${var.iso_path}/${var.iso_file}"
  iso_checksum = "${var.iso_checksum_type}:${var.iso_checksum_value}"

  shutdown_command = "echo '${var.build_password}' | sudo -S -E shutdown -P now"
  shutdown_timeout = var.common_shutdown_timeout

  ssh_username = local.ssh_username
  ssh_password = local.ssh_password
  ssh_port = var.communicator_port
  ssh_timeout = var.communicator_timeout

  # https://docs.oracle.com/en/virtualization/virtualbox/6.0/user/vboxmanage-modifyvm.html
  vboxmanage = [
    ["modifyvm", "{{ .Name }}", "--memory", "${var.vm_mem_size}"],
    ["modifyvm", "{{ .Name }}", "--cpus", "${var.vm_cpu_cores}"],
    ["modifyvm", "{{ .Name }}", "--clipboard-mode", "${var.virtualbox_clipboard_mode}"],
    ["modifyvm", "{{ .Name }}", "--audio", "${var.virtualbox_audio_mode}"],
    ["modifyvm", "{{ .Name }}", "--vrde", "${var.virtualbox_vrde_mode}"],
    ["modifyvm", "{{ .Name }}", "--vram", "${var.virtualbox_vram_mode}"],
    ["modifyvm", "{{ .Name }}", "--graphicscontroller", "${var.virtualbox_graphics_controller_mode}"],
    
    # https://github.com/hashicorp/packer/issues/12118
    ["modifyvm", "{{.Name}}", "--nat-localhostreachable1", "on"],
  ]

  skip_export = var.virtualbox_skip_export
  format = var.virtualbox_format

  # https://docs.oracle.com/en/virtualization/virtualbox/6.0/user/vboxmanage-import.html (vsys option)
  export_opts = [
    "--manifest",
    "${var.virtualbox_export_ovf_mode}",
    "--vsys", "0",
    "--description", "${local.description}\nOVF Format: ${var.virtualbox_export_ovf_mode}\nVersion: ${var.build_version}",
    "--version", "${var.build_version}"
  ]
  output_directory = "${var.build_script_output_directory}/virtualbox/${local.vm_id}"
  keep_registered = var.virtualbox_keep_registered

  guest_additions_path = var.virtualbox_guest_additions_path
  guest_additions_mode = var.virtualbox_guest_additions_mode
}

source "file" "linux-rhel-build-info" {
  content =  local.build_info_content
  target =  "${abspath(path.cwd)}/dist/info.json"
}

build {
  sources = ["source.file.linux-rhel-build-info", "source.virtualbox-iso.linux-rhel"]

  provisioner "ansible" {
    only = ["virtualbox-iso.linux-rhel"]
    except = []
    roles_path = "${local.ansible_roles_path}"
    collections_path = "${local.ansible_collections_path}"
    galaxy_force_install = true
    galaxy_file = "${var.ansible_requirements_yml}"
    playbook_file = "${var.ansible_playbook}"
    user = "${local.ssh_username}"
    ansible_env_vars = [
      "ANSIBLE_HOST_KEY_CHECKING=false",
      "ANSIBLE_SSH_ARGS='${var.ansible_ssh_args}'",
      "ANSIBLE_LOG_PATH=ansible-${local.vm_id}.log",
      "ANSIBLE_STDOUT_CALLBACK=yaml",
      "ANSIBLE_ROLES_PATH=${path.cwd}/ansible/roles:${local.ansible_roles_path}",
      "ANSIBLE_COLLECTIONS_PATH=${local.ansible_collections_path}"
    ]
    extra_arguments = [
      "-v",
      "--extra-vars", "rhsm_username=${var.rhsm_username}",
      "--extra-vars", "rhsm_password=${var.rhsm_password}",
      "--extra-vars", "ansible_scp_extra_args='${var.ansible_scp_extra_args}'",
      "--extra-vars", "ansible_ssh_transfer_method=${var.ansible_ssh_transfer_method}"
    ]
  }

  post-processors {
    post-processor "vagrant" {
      only = ["virtualbox-iso.linux-rhel"]
      provider_override = "virtualbox"
      keep_input_artifact = var.virtualbox_keep_input_artifact
      include = [
        "${abspath(path.cwd)}/dist/info.json"
      ]
      output = "${var.build_script_output_directory}/vagrant/${local.vm_id}-virtualbox-${var.build_version}.box"
    }
  }

}

