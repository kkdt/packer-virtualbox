vm_cpu_cores = 1
# Amount of RAM in MB
vm_mem_size = 2048
# The size of the disk in MB
vm_disk_size = 40960
# Swap size in MB
vm_swap_size = 2048

os_packages = [
  "@core",
  "kernel",
  "kernel-headers",
  "kernel-devel",
  "-iwl*firmware"
]

build_key = ""
vm_boot_wait = "10s"
communicator_port = 22
communicator_timeout = "30m"
common_shutdown_timeout = "1h30m"
vm_guest_os_language = "en_US.UTF-8"
vm_guest_os_keyboard = "--vckeymap=us --xlayouts='us'"
vm_guest_os_timezone = "UTC"
vm_guest_os_family = "linux"
vm_guest_os_name = "rhel"
vm_reboot_halt_shutdown_command="reboot --eject"

vm_disk_partitions = {
  boot = {
    label = "boot",
    fstype = "ext4",
    size = 512,
    fsoptions = "nodev,nosuid,noexec"
  },
  pv = {
    label = "pv.01",
    size = 1
  }
}

vm_volgroup = {
  name = "VolGroup",
  pesize = 4096,
  # must match 'pv' attribute above
  partition_name = "pv.01"
}

# All logical volumes on the VM
vm_logical_volumes = {
  root = {
    mount = "/",
    name = "root",
    fstype = "ext4",
    size = 10240,
    grow = true,
    fsoptions = ""
  },
  home = {
    mount = "/home",
    name = "home",
    fstype = "ext4",
    size = 1024,
    grow = false,
    fsoptions = "nodev"
  },
  tmp = {
    mount = "/tmp",
    name = "tmp",
    fstype = "ext4",
    size = 1024,
    grow = false,
    fsoptions = "nodev,nosuid"
  },
  var = {
    mount = "/var",
    name = "var",
    fstype = "ext4",
    size = 3072,
    grow = false,
    fsoptions = "nodev"
  }
}