#!/usr/bin/env bash

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

function help() {
  echo "build.sh [options]"
  echo "  --secrets          An externalized HCL variable file containing plain-text secrets"
  echo "  --os               OS identifier"
  echo "  --configs          (optional) Path to directory containing configurations"
  echo "  --output-directory (optional) Full path to the output directory, default ./dist"
  echo "  --details          (optional) Include additional metadata for the box image"
}

set -e

__directory="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"
__ansible_requirements_yml=${__directory}/ansible/requirements.yml
__ansible_playbook=${__directory}/ansible/default.yml
__include_details=""
__input_path=""
__input_os=""
__output_directory="${__directory}/dist"
__configs=""
__builder_info=""
__secrets=""
__var_files=""
__var_files_overrides="
build.pkrvars.hcl
vm.pkrvars.hcl
virtualbox.pkrvars.hcl
"

while [ "$1" != "" ]; do
  case "$1" in
  --secrets)
    shift
    __secrets="${1}"
    ;;

  --os)
    shift
    case "$1" in
    rhel8.5)
      __input_path="${__directory}/builds/linux/rhel/8/"
      __input_os="$1"
      __var_files="-var-file=${__input_path}/versions/rhel8.5.pkrvars.hcl"
      ;;
    rhel8.6)
      __input_path="${__directory}/builds/linux/rhel/8/"
      __input_os="$1"
      __var_files="-var-file=${__input_path}/versions/rhel8.6.pkrvars.hcl"
      ;;
    rhel8.7)
      __input_path="${__directory}/builds/linux/rhel/8/"
      __input_os="$1"
      __var_files="-var-file=${__input_path}/versions/rhel8.7.pkrvars.hcl"
      ;;
    rhel6.7)
      __input_path="${__directory}/builds/linux/rhel/6/"
      __input_os="$1"
      __var_files="-var-file=${__input_path}/versions/rhel6.7.pkrvars.hcl"
      ;;
    rhel6.9)
      __input_path="${__directory}/builds/linux/rhel/6/"
      __input_os="$1"
      __var_files="-var-file=${__input_path}/versions/rhel6.9.pkrvars.hcl"
      ;;
    *)
      echo "Invalid OS: $1"
      exit 1
      ;;
    esac
    ;;

  --details)
    __include_details="true"
    ;;

  --output-directory)
    shift
    if [ -e "$1" ]; then
      __output_directory="${1}"
    else
      echo "Error: Invalid output directory $1"
      exit 1
    fi
    ;;

  --configs)
    shift
    if [ ! -d "${__configs}" ]; then
      __configs="${1}"
    else
      echo "Error: Invalid configuration directory $1"
      exit 1
    fi
    ;;

  h|-h|--h|help|-help|--help)
    help
    exit 0
    ;;

  *)
    echo "Error: Invalid argument $1"
    help
    exit 1
    ;;
  esac
  shift
done

if [ -z "${__input_path}" -o -z "${__input_os}" ]; then
  echo "Please specify a supported guest operating system"
  exit 1
fi

if [ -z "${__secrets}" -o ! -f "${__secrets}" ]; then
  echo "Invalid secrets HCL file: ${__secrets}"
  echo "Please provide a valid file and re-run script"
  exit 1
fi

__git_branch=""
__git_commit=""
__git_remote_url=""

if [ ! -z "${__include_details}" ]; then
  set +e
  which git > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    if [ "$(git rev-parse --is-inside-work-tree)" == "true" ]; then
      __git_branch="$(git branch --show-current)"
      __git_commit="$(git log -1 --pretty=format:%h)"
      __git_remote_name="$(git config branch.${__git_branch}.remote)"

      # check if there are modified files
      git diff-index --quiet HEAD
      if [ $? -ne 0 ]; then
        __git_branch="${__git_branch}(*)"
      fi

      # check if there are untracked files
      __untracked=$(git ls-files . --exclude-standard --others)
      if [ ! -z "${__untracked}" ]; then
        __git_branch="${__git_branch}(+)"
      fi

      # determine remote Git URL
      if [ ! -z "${__git_remote_name}" ]; then
        __git_remote_url=$(git config remote.${__git_remote_name}.url)
      else
        __git_remote_url=""
      fi
    fi
  fi
  set -e
fi

# always include Vagrant and VirtualBox information

set +e
__vagrant_version=""
which vagrant > /dev/null 2>&1
if [ $? -eq 0 ]; then
  __vagrant_version=$(vagrant --version)
fi
set -e

set +e
__vbox_version=""
which VBoxManage > /dev/null 2>&1
if [ $? -eq 0 ]; then
  __vbox_version=$(VBoxManage --version)
fi
set -e

if [ -z "${__vagrant_version}" -o -z "${__vbox_version}" ]; then
  echo "ERROR: Vagrant and VirtualBox are required"
  echo "   VirtualBox found: ${__vbox_version}"
  echo "   Vagrant found: ${__vagrant_version}"
  exit 1
fi

__builder_info="VirtualBox ${__vbox_version}, ${__vagrant_version}"

echo "================================"
echo "packer-virtualbox"
echo "================================"
echo ""

echo "Packer workspace: ${__input_path}"
echo "VirtualBox/Vagrant details: ${__builder_info}"
echo "Build output directory: ${__output_directory}"
echo "Build user: ${USER}"
echo "OS type: ${__input_os}"
if [ ! -z "${__include_details}" ]; then
  echo "Git Info"
  echo "  - Branch: ${__git_branch}"
  echo "  - Commit: ${__git_commit}"
  echo "  - Remote URL: ${__git_remote_url}"
fi
echo -e "\nContinue? (y/n)"
read -r REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  exit 1
fi

# include sensitive file

__var_files="-var-file=${__secrets} ${__var_files}"

# external configurations

if [ ! -z "${__configs}" ]; then
  for override in ${__var_files_overrides}; do
    if [ -f "${__configs}/${override}" ]; then
      __var_files="${__var_files} -var-file=${__configs}/${override}"
      echo "Config: ${__configs}/${override}"
    fi
  done

  if [ -f "${__configs}/requirements.yml" ]; then
    __ansible_requirements_yml="${__configs}/requirements.yml"
    echo "Ansible: ${__ansible_requirements_yml}"
  fi

  if [ -f "${__configs}/default.yml" ]; then
    __ansible_playbook="${__configs}/default.yml"
    echo "Ansible: ${__ansible_playbook}"
  fi
fi

echo ""
echo "Initializing HashiCorp Packer and required plugins..."
packer init "${__input_path}"

echo "Building...."

packer build -force \
  -var "build_script_username=${USER}" \
  -var "builder_info=${__builder_info}" \
  -var "build_script_output_directory=${__output_directory}" \
  -var "git_branch=${__git_branch}" \
  -var "git_commit=${__git_commit}" \
  -var "git_remote_url=${__git_remote_url}" \
  -var "ansible_playbook=${__ansible_playbook}" \
  -var "ansible_requirements_yml=${__ansible_requirements_yml}" \
  ${__var_files} \
  "${__input_path}"

echo "Done."