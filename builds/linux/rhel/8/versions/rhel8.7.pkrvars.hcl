# https://access.redhat.com/downloads/content/479/ver=/rhel---8/8.7/x86_64/product-software
vm_guest_os_version = "8.7"
iso_path = "config/iso"
iso_file = "rhel-8.7-x86_64-dvd.iso"
iso_checksum_type = "sha256"
iso_checksum_value = "a6a7418a75d721cc696d3cbdd648b5248808e7fef0f8742f518e43b46fa08139"

# Set to true to have DVD contents install as a local YUM repo
build_with_dvd_contents = false

# build version added to the .box filename
build_version = "1.0.0"
