# RHEL 6

text
cdrom
lang en_US.UTF-8
keyboard us
timezone Etc/GMT --isUtc
xconfig --startxonboot
firewall --disabled
selinux --disabled
firstboot --disable
bootloader --location=mbr
ignoredisk --only-use=sda
zerombr
clearpart --linux --initlabel
${vm_reboot_halt_shutdown_command}

# network

network --onboot yes bootproto=dhcp %{ if vm_hostname != "" && vm_hostname != "localhost" ~} --hostname ${vm_hostname} %{ endif ~}

# users

rootpw --iscrypted ${root_password_encrypted}

%{ if build_username != "" && build_username != "root" ~}
user --groups=wheel --iscrypted --name=${build_username} --password=${build_password_encrypted}
%{ endif ~}

# disk partitions

part /boot --fstype=${vm_disk_partitions.boot.fstype} --size=${vm_disk_partitions.boot.size} --fsoptions="${vm_disk_partitions.boot.fsoptions}" --label=${vm_disk_partitions.boot.label}

part ${vm_disk_partitions.pv.label} --grow --size=${vm_disk_partitions.pv.size}

volgroup ${vm_volgroup.name} --pesize=${vm_volgroup.pesize} ${vm_volgroup.partition_name}

logvol ${vm_logical_volumes.root.mount} --fstype=${vm_logical_volumes.root.fstype} --name=${vm_logical_volumes.root.name} --vgname=${vm_volgroup.name} --size=${vm_logical_volumes.root.size} %{ if vm_logical_volumes.root.grow ~} --grow %{ endif ~} %{ if vm_logical_volumes.root.fsoptions != "" ~} --fsoptions="${vm_logical_volumes.root.fsoptions}" %{ endif ~}

logvol ${vm_logical_volumes.home.mount} --fstype=${vm_logical_volumes.home.fstype} --name=${vm_logical_volumes.home.name} --vgname=${vm_volgroup.name} --size=${vm_logical_volumes.home.size} %{ if vm_logical_volumes.home.grow ~} --grow %{ endif ~} %{ if vm_logical_volumes.home.fsoptions != "" ~} --fsoptions="${vm_logical_volumes.home.fsoptions}" %{ endif ~}

logvol ${vm_logical_volumes.tmp.mount} --fstype=${vm_logical_volumes.tmp.fstype} --name=${vm_logical_volumes.tmp.name} --vgname=${vm_volgroup.name} --size=${vm_logical_volumes.tmp.size} %{ if vm_logical_volumes.tmp.grow ~} --grow %{ endif ~} %{ if vm_logical_volumes.tmp.fsoptions != "" ~} --fsoptions="${vm_logical_volumes.tmp.fsoptions}" %{ endif ~}

logvol ${vm_logical_volumes.var.mount} --fstype=${vm_logical_volumes.var.fstype} --name=${vm_logical_volumes.var.name} --vgname=${vm_volgroup.name} --size=${vm_logical_volumes.var.size} %{ if vm_logical_volumes.var.grow ~} --grow %{ endif ~} %{ if vm_logical_volumes.var.fsoptions != "" ~} --fsoptions="${vm_logical_volumes.var.fsoptions}" %{ endif ~}

logvol swap --name=swap --vgname=${vm_volgroup.name} --size=${vm_swap_size}

# packages

%packages --instLangs=en_US.utf8 --excludedocs

%{ for common_package in os_packages ~}
${common_package}
%{ endfor ~}

%{ for package in vm_packages ~}
${package}
%{ endfor ~}

%end

# Section: post

%post --log=/var/log/kickstart-post.log
echo "Updating /etc/ssh/sshd_config to allow root login"
sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/id:5:initdefault:/id:3:initdefault:/g' /etc/inittab

%{ if build_username != "" && build_username != "root" ~}
echo "Installing sudoers"
echo "${build_username} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/${build_username}
%{ endif ~}

sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers
%end

# Section: post/nochroot

%post --nochroot --log=/mnt/sysimage/root/kickstart.log
/usr/bin/cp /tmp/kickstart-*.log /mnt/sysimage/root/.

echo "Finding the DVD media.repo"
find / -type f -name "media.repo"
echo "done."
echo ""

%{ if build_with_dvd_contents ~}
mkdir -p /mnt/sysimage/repos

media_repo=$(find / -type f -name "media.repo")
if [ ! -z  "$media_repo" ]; then
  ls -lart $(dirname $media_repo)
  echo ""
  echo "Installing DVD contents"
  cp -a $(dirname $media_repo) /mnt/sysimage/repos/dvd
  cp -a $media_repo /mnt/sysimage/etc/yum.repos.d/dvd.repo
  chmod o+w /mnt/sysimage/etc/yum.repos.d/dvd.repo
  echo "enabled=1" >> /mnt/sysimage/etc/yum.repos.d/dvd.repo
  echo "baseurl=file:///repos/dvd" >> /mnt/sysimage/etc/yum.repos.d/dvd.repo
  echo "gpgkey=file:///repos/dvd/RPM-GPG-KEY-redhat-release" >> /mnt/sysimage/etc/yum.repos.d/dvd.repo
  echo "done."
  echo ""
else
  echo "Cannot find media.repo"
fi
%{ endif ~}

%end

# Section: pre

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
