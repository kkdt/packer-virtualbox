# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Red Hat Enterprise Linux Server 8

### Installs from the first attached CD-ROM/DVD on the system.
cdrom

### Performs the kickstart installation in text mode. 
### By default, kickstart installations are performed in graphical mode.
text

### Accepts the End User License Agreement.
eula --agreed

### Sets the language to use during installation and the default language to use on the installed system.
lang ${vm_guest_os_language}

### Sets the default keyboard type for the system.
keyboard ${vm_guest_os_keyboard}

### Configure network information for target system and activate network devices in the installer environment (optional)
### --onboot	  enable device at a boot time
### --device	  device to be activated and / or configured with the network command
### --bootproto	  method to obtain networking configuration for device (default dhcp)
### --noipv6	  disable IPv6 on this device
###
### network  --bootproto=static --ip=172.16.11.200 --netmask=255.255.255.0 --gateway=172.16.11.200 --nameserver=172.16.11.4 --hostname centos-linux-8
network --bootproto=dhcp

### Lock the root account.
rootpw --iscrypted ${root_password_encrypted}

%{ if build_username != "" && build_username != "root" ~}
user --groups=wheel --iscrypted --name=${build_username} --password=${build_password_encrypted}
%{ endif ~}


### Configure firewall settings for the system.
### --enabled	reject incoming connections that are not in response to outbound requests
### --ssh		allow sshd service through the firewall
firewall --disabled

### Sets up the authentication options for the system.
### The SSDD profile sets sha512 to hash passwords. Passwords are shadowed by default
### See the manual page for authselect-profile for a complete list of possible options.
authselect select sssd

### Sets the state of SELinux on the installed system.
selinux --disabled

### Sets the system time zone.
timezone ${vm_guest_os_timezone}

### Sets how the boot loader should be installed.
bootloader --location=mbr

### Initialize any invalid partition tables found on disks.
ignoredisk --only-use=sda
zerombr

### Removes partitions from the system, prior to creation of new partitions. 
### By default, no partitions are removed.
### --linux	erases all Linux partitions.
### --initlabel Initializes a disk (or disks) by creating a default disk label for all disks in their respective architecture.
clearpart --linux --initlabel

# Create primary system partitions (required for installs)
part /boot --fstype=${vm_disk_partitions.boot.fstype} --size=${vm_disk_partitions.boot.size} --fsoptions="${vm_disk_partitions.boot.fsoptions}" --label=${vm_disk_partitions.boot.label}
part ${vm_disk_partitions.pv.label} --grow --size=${vm_disk_partitions.pv.size}

# Create a Logical Volume Management (LVM) group (optional)
volgroup ${vm_volgroup.name} --pesize=${vm_volgroup.pesize} ${vm_volgroup.partition_name}

# Create particular logical volumes (optional)
logvol ${vm_logical_volumes.root.mount} --fstype=${vm_logical_volumes.root.fstype} --name=${vm_logical_volumes.root.name} --vgname=${vm_volgroup.name} --size=${vm_logical_volumes.root.size} %{ if vm_logical_volumes.root.grow ~} --grow %{ endif ~} %{ if vm_logical_volumes.root.fsoptions != "" ~} --fsoptions="${vm_logical_volumes.root.fsoptions}" %{ endif ~}

# Ensure /home Located On Separate Partition
logvol ${vm_logical_volumes.home.mount} --fstype=${vm_logical_volumes.home.fstype} --name=${vm_logical_volumes.home.name} --vgname=${vm_volgroup.name} --size=${vm_logical_volumes.home.size} %{ if vm_logical_volumes.home.grow ~} --grow %{ endif ~} %{ if vm_logical_volumes.home.fsoptions != "" ~} --fsoptions="${vm_logical_volumes.home.fsoptions}" %{ endif ~}

# Ensure /tmp Located On Separate Partition
logvol ${vm_logical_volumes.tmp.mount} --fstype=${vm_logical_volumes.tmp.fstype} --name=${vm_logical_volumes.tmp.name} --vgname=${vm_volgroup.name} --size=${vm_logical_volumes.tmp.size} %{ if vm_logical_volumes.tmp.grow ~} --grow %{ endif ~} %{ if vm_logical_volumes.tmp.fsoptions != "" ~} --fsoptions="${vm_logical_volumes.tmp.fsoptions}" %{ endif ~}

# Ensure /var Located On Separate Partition
logvol ${vm_logical_volumes.var.mount} --fstype=${vm_logical_volumes.var.fstype} --name=${vm_logical_volumes.var.name} --vgname=${vm_volgroup.name} --size=${vm_logical_volumes.var.size} %{ if vm_logical_volumes.var.grow ~} --grow %{ endif ~} %{ if vm_logical_volumes.var.fsoptions != "" ~} --fsoptions="${vm_logical_volumes.var.fsoptions}" %{ endif ~}

# swap volumn group
logvol swap --name=swap --vgname=${vm_volgroup.name} --size=${vm_swap_size}

### Packages selection.
%packages --ignoremissing --excludedocs

%{ for common_package in os_packages ~}
${common_package}
%{ endfor ~}

%{ for package in vm_packages ~}
${package}
%{ endfor ~}

# Get group identifier: yum grouplist -v
# https://access.redhat.com/solutions/5238 - Red Hat 8 only has "recommended" desktop environment

%{ if vm_desktop_environment == "recommended" || vm_desktop_environment == "minimal" ~}
# Server with GUI
@graphical-server-environment
# Graphical Administration Tools
@graphical-admin-tools
%{ endif ~}

%end

### Post-installation commands.
%post --log=/root/kickstart-post.log
echo "Updating /etc/ssh/sshd_config to allow root login"
sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config

%{ if build_username != "" && build_username != "root" ~}
echo "${build_username} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/${build_username}
%{ endif ~}
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

%{ if vm_desktop_environment == "recommended" || vm_desktop_environment == "minimal" ~}
echo "Set the system to boot directly into the GUI"
systemctl set-default graphical.target
%{ endif ~}
%end

### Reboot after the installation is complete.
### --eject attempt to eject the media before rebooting.
${vm_reboot_halt_shutdown_command}

%post --nochroot --log=/mnt/sysimage/root/kickstart.log
/usr/bin/cp /tmp/kickstart-*.log /mnt/sysimage/root/.

echo "Finding the DVD media.repo"
find / -type f -name "media.repo"
echo "done."
echo ""

%{ if build_with_dvd_contents ~}
mkdir -p /mnt/sysimage/repos/dvd

media_repo=$(find / -type f -name "media.repo")
if [ ! -z  "$media_repo" ]; then
  ls -lart $(dirname $media_repo)
  echo ""
  echo "Installing DVD contents"
  cp -a /run/install/repo/.treeinfo /mnt/sysimage/repos/dvd/.
  cp -a /run/install/repo/RPM-GPG-* /mnt/sysimage/repos/dvd/.
  cp -a /run/install/repo/BaseOS /mnt/sysimage/repos/dvd/.
  cp -a /run/install/repo/AppStream /mnt/sysimage/repos/dvd/.
  echo "done."
  echo ""
  echo "Installing repo files"
  echo "[BaseOS]" >> /mnt/sysimage/etc/yum.repos.d/dvd.repo
  echo "name=RHEL Local - BaseOS" >> /mnt/sysimage/etc/yum.repos.d/dvd.repo
  echo "mediaid=None" >> /mnt/sysimage/etc/yum.repos.d/dvd.repo
  echo "metadata_expire=-1" >> /mnt/sysimage/etc/yum.repos.d/dvd.repo
  echo "gpgcheck=1" >> /mnt/sysimage/etc/yum.repos.d/dvd.repo
  echo "cost=500" >> /mnt/sysimage/etc/yum.repos.d/dvd.repo
  echo "enabled=1" >> /mnt/sysimage/etc/yum.repos.d/dvd.repo
  echo "baseurl=file:///repos/dvd/BaseOS" >> /mnt/sysimage/etc/yum.repos.d/dvd.repo
  echo "gpgkey=file:///repos/dvd/RPM-GPG-KEY-redhat-release" >> /mnt/sysimage/etc/yum.repos.d/dvd.repo
  echo "" >> /mnt/sysimage/etc/yum.repos.d/dvd.repo
  echo "[AppStream]" >> /mnt/sysimage/etc/yum.repos.d/dvd.repo
  echo "name=RHEL Local - AppStream" >> /mnt/sysimage/etc/yum.repos.d/dvd.repo
  echo "mediaid=None" >> /mnt/sysimage/etc/yum.repos.d/dvd.repo
  echo "metadata_expire=-1" >> /mnt/sysimage/etc/yum.repos.d/dvd.repo
  echo "gpgcheck=1" >> /mnt/sysimage/etc/yum.repos.d/dvd.repo
  echo "cost=500" >> /mnt/sysimage/etc/yum.repos.d/dvd.repo
  echo "enabled=1" >> /mnt/sysimage/etc/yum.repos.d/dvd.repo
  echo "baseurl=file:///repos/dvd/AppStream" >> /mnt/sysimage/etc/yum.repos.d/dvd.repo
  echo "gpgkey=file:///repos/dvd/RPM-GPG-KEY-redhat-release" >> /mnt/sysimage/etc/yum.repos.d/dvd.repo
  echo "done."
  echo ""
else
  echo "Cannot find media.repo"
fi
%{ endif ~}

%end

%pre --log=/tmp/kickstart-pre.log
echo "Current mounts"
df -h
echo "done."
echo ""

echo "Current filesytem /"
ls -lart /
echo "done."
echo ""

echo "Finding the DVD media.repo"
find / -type f -name "media.repo"
echo "done."
echo ""
%end