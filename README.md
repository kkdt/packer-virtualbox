# HashiCorp Packer, Oracle VirtualBox, and Vagrant Build Virtual Machine Images

> All credits go to the VMware Open Source team for providing the foundation for infrastructure-as-code to automate the creation of virtual machine images in [packer-examples-for-vsphere][packer-examples-for-vsphere].
> This project will no longer receive updates from the parent fork past commit [1472998](https://github.com/kkdt/packer-virtualbox/commit/147299898a844cdd9e64b93a05591ba5f427badc).

## Table of Contents

1. [Introduction](#Introduction)
1. [Requirements](#Requirements)
1. [Configuration](#Configuration)
1. [Build](#Build)
1. [Troubleshoot](#Troubleshoot)
1. [Credits](#Credits)

## Introduction

This repository provides infrastructure-as-code to automate the creation of virtual machine images and their guest operating
systems on [Oracle VirtualBox][oracle-virtualbox] using [HashiCorp Packer][packer] and the [Packer Plugin for VirtualBox][packer-plugin-virtualbox-docs]
(`virtualbox-iso`).

By default, the machine image artifacts are created by the [Packer Vagrant Post-Processor][packer-vagrant-post-processor]
and stored on the local file system at a configurable location. If items of the same name exists in the target location,
then Packer will replace the existing item.

The following builds are supported under this project:

### Linux Distributions

* Red Hat Enterprise Linux 6 Server
* Red Hat Enterprise Linux 8 Server

  > **Note**
  >
  > Other distributions will be added as needed.

## Requirements

**Host Operating Systems**:

* Ubuntu Server 22.04 LTS and 20.04 LTS
* macOS Ventura (Intel)

    > **Note**
    >
    > Operating systems and versions tested with the project.
    >
    > Click on the operating system name to display the installation steps.

    * <details>
        <summary>macOS</summary>

        ```shell
        pip3 install pip-search

        pip3 list
        ```

      </details>

**Packer**:

* HashiCorp [Packer][packer-install] 1.8.0 or higher.

  > **Note**
  >
  > Click on the operating system name to display the installation steps.
  >
  > macOS is locked to Packer 1.8.3 below.

  * <details>
      <summary>Ubuntu</summary>

      ```shell
      sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl

      curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

      sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

      sudo apt-get update && sudo apt-get install packer
      ```

    </details>

  * <details>
      <summary>macOS</summary>

      ```shell
      curl -O https://releases.hashicorp.com/packer/1.8.3/packer_1.8.3_darwin_amd64.zip

      sudo unzip packer_1.8.3_darwin_amd64.zip -d /usr/local/bin
      ```

    </details>

* HashiCorp [Packer Plugin for VirtualBox][packer-plugin-virtualbox]  (`virtualbox-iso`) 1.0.4 or higher.

**Additional Software Packages**:

The following software packages must be installed on the operating system running Packer.

> **Note**
>
> Click on the operating system name to display the installation steps.

* [Ansible][ansible-docs] 2.9 or higher.
  * <details>
      <summary>Ubuntu</summary>

      ```shell
      apt-get install ansible
      ```

    </details>

  * <details>
      <summary>macOS</summary>

      ```shell
      pip3 install --user ansible-core==2.12.9

      pip3 install --user ansible==5.10.0      

      pip3 list
      ```

    </details>

* A command-line .iso creator. Packer will use one of the following:
  * <details>
      <summary>Ubuntu</summary>

      ```shell
      apt-get install xorriso
      ```

    </details>

  * <details>
      <summary>macOS</summary>

      hdiutil (native)

    </details>

* Coreutils
  * <details>
      <summary>macOS</summary>

      ```shell
      brew install coreutils
      ```

    </details>

## Configuration

### Quickstart

Use the default configurations to build a Red Hat Vagrant/VirtualBox image.

1. Create local directories
   - Execute: `mkdir -p config/iso`
1. Download ISO file(s) from the vendor and move to `config/iso`
   - e.g. [Red Hat 6][download-linux-redhat-server-6]
1. Copy the provided [secrets.pkrvars.hcl.example](builds/secrets.pkrvars.hcl.example) to `config/secrets.pkrvars.hcl`

> **Note**
>
> The entire 'config' directory will be ignored by Git.
>
> The secrets.pkrvars.hcl file will create systems with a root password of `helloworld`.
>
> You will need to provide your Red Hat subscription in secrets.pkrvars.hcl if you want to build the latest Red Hat 6 and 8 systems.

### Variables Files

Packer HCL variable files make up the characteristics of each virtual machine. All supported guest operating systems will
provide an `*.auto.pkrvars.hcl` file that Packer automatically loads for each build without having the user provide their
own build values. The automatic build values establish the "default" virtual machine state for each build - OS packages,
disk partitions, etc. of the final Vagrant virtual machine box image.

This project will read variables from the files below. These files provide logical grouping for build variables rather
than having all variables in a single HCL file.

1. build.pkrvars.hcl - Build settings
1. vm.pkrvars.hcl - Virtual machine settings
1. virtualbox.pkrvars.hcl - VirtualBox settings
1. requirements.yml - The Ansible Galaxy requirements file containing `collections` and `roles` attributes
1. default.yml - The Ansible playbook to use in the build

Using [Packer HCL Variables][packer-variables] hierarchy, the user can override Packer variables using configuration
overrides - logically grouped Packer HCL files to build a version-controlled virtual machine. Pass in the `--configs`
option followed by the full path to the directory containing one or more of the HCL configuration files listed above.

## Build

Start a build by running the build script (`./build.sh`) where you must provide the option `--os <os>` to build a supported
virtual machine system.

> **Note**
>
> Click on builds below for the full command.

* <details>
    <summary>Red Hat 6.7</summary>

    ```shell
    ./build.sh --secrets config/secrets.pkrvars.hcl --os rhel6.7
    ```
  </details>

* <details>
    <summary>Red Hat 6.9</summary>

    ```shell
    ./build.sh --secrets config/secrets.pkrvars.hcl --os rhel6.9
    ```
  </details>

* <details>
    <summary>Red Hat 8.5</summary>

    ```shell
    ./build.sh --secrets config/secrets.pkrvars.hcl --os rhel8.5
    ```
  </details>

* <details>
    <summary>Red Hat 8.6</summary>

    ```shell
    ./build.sh --secrets config/secrets.pkrvars.hcl --os rhel8.6
    ```
  </details>


* <details>
    <summary>Red Hat 8.7</summary>

    ```shell
    ./build.sh --secrets config/secrets.pkrvars.hcl --os rhel8.7
    ```
  </details>

* <details>
    <summary>Red Hat 8.9</summary>

    ```shell
    ./build.sh --secrets config/secrets.pkrvars.hcl --os rhel8.9
    ```
  </details>

* <details>
    <summary>Red Hat 6.7 (external configs)</summary>

    ```shell
    ./build.sh --secrets config/secrets.pkrvars.hcl --os rhel6.7 --configs $HOME/servers/apache-server
    ```
  </details>

## Troubleshoot

* Read [Debugging Packer Builds][packer-debug].
* For macOS hosts, after an operating system upgrade, go to System Settings > Privacy and Security
  <details>
    <summary>Privacy and Security</summary>

    1. Enable the Oracle extensions
    1. Go to Profiles > Ensure Oracle VirtualBox VM is listed
    1. Restart laptop
    1. Worst case scenario - reinstall VirtualBox and VirtualBox Extension Pack

  </details>

## Credits

* VMware Open Source Team [packer-examples-for-vsphere][packer-examples-for-vsphere]

[//]: Links

[ansible-docs]: https://docs.ansible.com
[download-linux-almalinux-server-8]: https://mirrors.almalinux.org/isos/x86_64/8.6.html
[download-linux-almalinux-server-9]: https://mirrors.almalinux.org/isos/x86_64/9.0.html
[download-linux-centos-server-7]: http://isoredirect.centos.org/centos/7/isos/x86_64/
[download-linux-centos-stream-9]: http://mirror.stream.centos.org/9-stream/BaseOS/x86_64/iso/
[download-linux-centos-stream-8]: http://isoredirect.centos.org/centos/8-stream/isos/x86_64/
[download-linux-debian-11]: https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/
[download-linux-photon-server-4]: https://packages.vmware.com/photon/4.0/
[download-linux-redhat-server-6]: https://access.redhat.com/downloads/content/69/ver=/rhel---6/6.7/x86_64/product-software
[download-linux-redhat-server-7]: https://access.redhat.com/downloads/content/69/ver=/rhel---7/7.9/x86_64/product-software
[download-linux-redhat-server-8]: https://access.redhat.com/downloads/content/479/ver=/rhel---8/8.6/x86_64/product-software
[download-linux-redhat-server-9]: https://access.redhat.com/downloads/content/479/ver=/rhel---9/9.0/x86_64/product-software
[download-linux-rocky-server-9]: https://download.rockylinux.org/pub/rocky/9/isos/x86_64/
[download-linux-rocky-server-8]: https://download.rockylinux.org/pub/rocky/8/isos/x86_64/
[download-suse-linux-enterprise-15]: https://www.suse.com/download/sles/#
[download-linux-ubuntu-server-18-04-lts]: http://cdimage.ubuntu.com/ubuntu/releases/18.04.5/release/
[download-linux-ubuntu-server-20-04-lts]: https://releases.ubuntu.com/20.04/
[download-linux-ubuntu-server-22-04-lts]: https://releases.ubuntu.com/22.04/
[hcp-packer-docs]: https://cloud.hashicorp.com/docs/packer
[hcp-packer-intro]: https://www.youtube.com/watch?v=r0I4TTO957w
[oracle-virtualbox]: https://www.virtualbox.org/
[packer]: https://www.packer.io
[packer-debug]: https://www.packer.io/docs/debugging
[packer-examples-for-vsphere]: https://github.com/vmware-samples/packer-examples-for-vsphere
[packer-install]: https://www.packer.io/intro/getting-started/install.html
[packer-plugin-virtualbox]: https://github.com/hashicorp/packer-plugin-virtualbox
[packer-plugin-virtualbox-docs]: https://www.packer.io/plugins/builders/virtualbox/iso
[packer-plugin-windows-update]: https://github.com/rgl/packer-plugin-windows-update
[packer-vagrant-post-processor]: https://www.packer.io/plugins/post-processors/vagrant/vagrant
[packer-variables]: https://www.packer.io/docs/templates/hcl_templates/variables
[redhat-kickstart]: https://access.redhat.com/labs/kickstartconfig/
[suse-autoyast]: https://documentation.suse.com/sles/15-SP3/single-html/SLES-autoyast/index.html#CreateProfile-CMS
