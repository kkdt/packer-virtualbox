# https://access.redhat.com/downloads/content/479/ver=/rhel---8/8.5/x86_64/product-software
vm_guest_os_version = "8.5"
iso_path = "config/iso"
iso_file = "rhel-8.5-x86_64-dvd.iso"
iso_checksum_type = "sha256"
iso_checksum_value = "1f78e705cd1d8897a05afa060f77d81ed81ac141c2465d4763c0382aa96cadd0"

# Set to true to have DVD contents install as a local YUM repo
build_with_dvd_contents = false

# build version added to the .box filename
build_version = 1.0.0
