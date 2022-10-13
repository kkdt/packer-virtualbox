variable "rhsm_username" {
  type = string
  description = "Red Hat Subscription Manager username"
  default = ""
}

variable "rhsm_password" {
  type = string
  description = "Red Hat Subscription Manager password"
  default = ""
}

variable "vm_guest_os_language" {
  type = string
  description = "The guest operating system language."
  default = "en_US"
}

variable "vm_guest_os_keyboard" {
  type = string
  description = "The guest operating system keyboard input."
  default = "us"
}

variable "vm_guest_os_timezone" {
  type = string
  description = "The guest operating system timezone."
  default = "UTC"
}

variable "vm_guest_os_family" {
  type = string
  description = "The guest operating system family. Used for naming and VMware tools. (e.g. 'linux')"
}

variable "vm_guest_os_name" {
  type = string
  description = "The guest operating system name. Used for naming . (e.g. 'rhel')"
}

variable "vm_guest_os_version" {
  type = string
  description = "The guest operating system version. Used for naming. (e.g. '8')"
}

variable "vm_cpu_cores" {
  type = number
  description = "CPUs on the virtual machine"
  default = 1
}

variable "vm_mem_size" {
  type = number
  description = "The size for the virtual memory in MB. (e.g. '2048')"
  default = 2048
}

variable "vm_disk_size" {
  type = number
  description = "The size for the virtual disk in MB. (e.g. '40960')"
  default = 40960
}

variable "vm_swap_size" {
  type = number
  description = "The swap size in MB"
  default = 2048
}

variable "vm_hostname" {
  type = string
  description = "Fully-qualified hostname"
  default = "localhost"
}

variable "vm_disk_partitions" {
  type = object({
    boot = object({
      label = string,
      fstype = string,
      size = number,
      fsoptions = string
    }),
    pv = object({
      label = string,
      size = number
    })
  })
  description = "Disk partitions will be for boot and the primary volume"
}

variable "vm_volgroup" {
  type = object({
    name = string,
    pesize = number,
    partition_name = string
  })
  description = "The single volume group attributes on the server, i.e. VolGroup"
}

variable "vm_logical_volumes" {
  type = object({
    root = object({
      mount = string,
      name = string,
      fstype = string,
      size = number,
      grow = bool,
      fsoptions = string
    }),
    home = object({
      mount = string,
      name = string,
      fstype = string,
      size = number,
      grow = bool,
      fsoptions = string
    }),
    tmp = object({
      mount = string,
      name = string,
      fstype = string,
      size = number,
      grow = bool,
      fsoptions = string
    }),
    var = object({
      mount = string,
      name = string,
      fstype = string,
      size = number,
      grow = bool,
      fsoptions = string
    })
  })
  description = "List out all logical volumes and their attributes"
}

variable "iso_path" {
  type = string
  description = "The relative path"
  default = "config/iso"
}

variable "iso_file" {
  type = string
  description = "The file name of the ISO image used by the vendor. (e.g. 'rhel-<verssion>-x86_64-dvd.iso')"
}

variable "iso_checksum_type" {
  type = string
  description = "The checksum algorithm used by the vendor. (e.g. 'sha256')"
  default = "sha256"
}

variable "iso_checksum_value" {
  type = string
  description = "The checksum value provided by the vendor."
}

variable "vm_boot_wait" {
  type = string
  description = "The time to wait before boot."
}

variable "vm_reboot_halt_shutdown_command" {
  type = string
  description = "This value will be substituted in the kickstart to reboot, halt, or shutdown"
  default = "reboot --eject"
}

variable "common_shutdown_timeout" {
  type = string
  description = "Time to wait for guest operating system shutdown."
}

variable "root_password" {
  type = string
  description = "The root password"
  sensitive = true
}

variable "root_password_encrypted" {
  type = string
  description = "The root SHA-512 encrypted password"
  sensitive = true
}

variable "build_with_dvd_contents" {
  type = bool
  description = "Include the DVD contents with the server"
  default = false
}

variable "build_username" {
  type = string
  description = "The username to login to the guest operating system."
  sensitive = true
  default = ""
}

variable "build_password" {
  type = string
  description = "The password to login to the guest operating system."
  sensitive = true
  default = ""
}

variable "build_password_encrypted" {
  type  = string
  description = "The SHA-512 encrypted password to login to the guest operating system."
  sensitive   = true
  default = ""
}

variable "build_key" {
  type = string
  description = "The public key to login to the guest operating system."
  sensitive = true
}

variable "communicator_port" {
  type = string
  description = "The port for the communicator protocol."
}

variable "communicator_timeout" {
  type = string
  description = "The timeout for the communicator protocol."
}

variable "os_packages" {
  type = list(string)
  description = "Common OS packages to install"
}

variable "vm_packages" {
  type = list(string)
  description = "VM-specific OS packages"
  default = []
}

variable "build_script_username" {
  type = string
  description = "The user that kicked off the build"
  default = "packer"
}

variable "build_script_output_directory" {
  type = string
  description = "The provided full path to the output directory"
  default = "./dist"
}

variable "server_name" {
  type = string
  description = "The server name provided by the build"
  default = ""
}

variable "git_branch" {
  type = string
  description = "The current Git branch"
  default = ""
}

variable "git_commit" {
  type = string
  description = "The Git commit short hash"
  default = ""
}

variable "git_remote_url" {
  type = string
  description = "The Git remote URL"
  default = ""
}

variable "builder_info" {
  type = string
  description = "Additional information on the builder"
  default = "virtualbox-iso"
}

variable "build_version" {
  type = string
  description = "The build version"
  default = "1.0.0"
}

variable "virtualbox_headless" {
  type = bool
  description = "Show/hide the VirtualBox GUI on build"
  default = true
}

variable "virtualbox_audio_mode" {
  type = string
  description = "Customization using VirtualBox 'modifyvm' command"
  default = "none"
}

variable "virtualbox_vrde_mode" {
  type = string
  description = "Customization using VirtualBox 'modifyvm' command"
  default = "off"
}

variable "virtualbox_vram_mode" {
  type = number
  description = "Customization using VirtualBox 'modifyvm' command"
  default = 16
}

variable "virtualbox_graphics_controller_mode" {
  type = string
  description = "Customization using VirtualBox 'modifyvm' command"
  default = "vmsvga"
}

variable "virtualbox_clipboard_mode" {
  type = string
  description = "Customization using VirtualBox 'modifyvm' command"
  default = "bidirectional"
}

variable "virtualbox_skip_export" {
  type = bool
  description = "Skip exporting the VirtualBox disk/ovf contents"
  default = false
}

variable "virtualbox_format" {
  type = string
  description = "Output format"
  default = "ovf"
}

variable "virtualbox_guest_os_type" {
  type = string
  description = "VirtualBox guest OS type"
  default = "RedHat_64"
}

variable "virtualbox_guest_additions_mode" {
  type = string
  description = "The method to put the Guest Additions ISO on the virtual machine"
  default = "upload"
}

variable "virtualbox_guest_additions_path" {
  type = string
  description = "The location of the Guest Additions ISO on the virtual machine"
  default = "/root/VBoxGuestAdditions.iso"
}

variable "virtualbox_keep_registered" {
  type = bool
  description = "Set this to true if you would like to keep the VM registered with virtualbox"
  default = false
}

variable "virtualbox_keep_input_artifact" {
  type = bool
  description = "Indicate whether or not to keep the input files that the vagrant post-processor uses"
  default = false
}

variable "virtualbox_export_ovf_mode" {
  type = string
  description = "Virtualization OVF format/mode: [--legacy09|--ovf09|--ovf10|--ovf20|--opc10]"
  default = "--ovf10"
}

variable "virtualbox_hard_drive_interface" {
  type = string
  description = "he type of controller that the primary hard drive is attached to: [ide|sata|scsi|pcie|virtio]"
  default = "ide"
}
