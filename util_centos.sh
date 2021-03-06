#!/bin/bash
################################################################
# requirement:
# --------------------------------------------------------------
#  - ansible 2.7.4
#  - vagrant 2.2.2
#    - vagrant-libvirt (0.0.45)
#    - vagrant-mutate (1.2.0)
#    - vagrant-proxyconf (1.5.2)
# ----libvirt------
#  - qemu(2.4.1), libvirt-bin(3.9.0)
#  - ruby 2.5.1
#  - ruby-libvirt 0.7.1
# ----virtualbox------
#  - virtualbox 5.2.22
################################################################
# test env:
# --------------------------------------------------------------
# host os : ubuntu14.04
# provider: libvirt
# image   : centos/7
# ansible : 2.0
################################################################


# manage virtualbox vm
##########################################
# VBoxManage list runningvms
# VBoxManage controlvm <uuid> poweroff
# VBoxManage unregistervm <uuid>

#magage libvirt vm
##########################################
# virsh list --all
# virsh undefine <vm_name>

################################################################
WORK_DIR=$(cd `dirname $0`; pwd)
TMP_DIR="../_tmp"
IMAGE_CACHE="../_image"

VAGRANT_VER="2.2.2"
VAGRANT_PKG="vagrant_${VAGRANT_VER}_x86_64.rpm"
VAGRANT_URL="https://releases.hashicorp.com/vagrant/${VAGRANT_VER}/${VAGRANT_PKG}"
VIRTUALBOX_PKG="VirtualBox-5.2-5.2.22_126460_el7-1.x86_64.rpm "
VIRTUALBOX_URL="http://download.virtualbox.org/virtualbox/5.2.22/${VIRTUALBOX_PKG}"

RUBY_VER=2.5.1
RUBY_LIBVIRT=0.7.1

##################################
##            provider           #
##################################
PROVIDER="libvirt"
#PROVIDER="virtualbox"


##################################
##            libvirt            #
##################################
LV_DISTROS="centos/7"
#LV_DISTROS="fedora/22-cloud-base"
#------------------------------------------------
LV_FEDORA22_NAME="libvirt/fedora/22-cloud-base"
LV_FEDORA22_URL="https://download.fedoraproject.org/pub/fedora/linux/releases/22/Cloud/x86_64/Images/Fedora-Cloud-Base-Vagrant-22-20150521.x86_64.vagrant-libvirt.box"
LV_FEDORA22_IMG="Fedora-Cloud-Base-Vagrant-22-20150521.x86_64.vagrant-libvirt.box"
#------------------------------------------------
LV_CENTOS7BOX_NAME="libvirt/centos/7"
LV_CENTOS7BOX_URL="https://vagrantcloud.com/centos/boxes/7/versions/1811.01/providers/libvirt.box"
LV_CENTOS7BOX_IMG="CentOS-7-x86_64-Vagrant-v1811_01.LibVirt.box"


##################################
##           virtualbox          #
##################################
VB_DISTROS="centos/7"
#VB_DISTROS="fedora/22-cloud-base"
#VB_DISTROS="ubuntu/trusty64"

#------------------------------------------------
VB_FEDORA22_NAME="virtualbox/fedora/22-cloud-base"
VB_FEDORA22_URL="https://download.fedoraproject.org/pub/fedora/linux/releases/22/Cloud/x86_64/Images/Fedora-Cloud-Base-Vagrant-22-20150521.x86_64.vagrant-virtualbox.box"
VB_FEDORA22_IMG="Fedora-Cloud-Base-Vagrant-22-20150521.x86_64.vagrant-virtualbox.box"
#------------------------------------------------
VB_UBUNTU1404BOX_NAME="virtualbox/ubuntu/trusty64"
VB_UBUNTU1404BOX_URL="https://atlas.hashicorp.com/ubuntu/boxes/trusty64/versions/20160122.0.0/providers/virtualbox.box"
VB_UBUNTU1404BOX_IMG="trusty-server-cloudimg-amd64-vagrant-disk1.box"
#------------------------------------------------
VB_CENTOS7BOX_NAME="virtualbox/centos/7"
VB_CENTOS7BOX_URL="https://atlas.hashicorp.com/centos/boxes/7/versions/1611.01/providers/virtualbox.box"
VB_CENTOS7BOX_IMG="CentOS-7-x86_64-Vagrant-1611_01.VirtualBox.box"


################################################################
function quit(){
  echo "$1"
  exit 1
}

function ensure_config_file(){
  if [ -s ${WORK_DIR}/roles/common/files/github/deploy.pem ];then
    echo "roles/common/files/github/deploy.pem is ready"
  else
    echo "please add a privte keypair in '${WORK_DIR}/roles/common/files/github/deploy.pem' which has permission to pull privte repo github.com/getdvm"
    exit 1
  fi

  if [ -s ${WORK_DIR}/roles/common/vars/main.yml ];then
    echo "roles/common/vars/main.yml is ready"
  else
    echo "please create file '${WORK_DIR}/roles/common/vars/main.yml', which container shadowsocks server ip"
    exit 1
  fi
}


function ensure_dependency(){

  echo "ensure dependency for provider: '${PROVIDER}'"

  echo "----------------------------------------"
  echo "[for common] ensure vagrant installed"
  which vagrant >/dev/null 2>&1
  if [ $? -ne 0 ];then
    NEED_INSTALL="true"
  else
    GET_VAGRANT_VER=$(vagrant --version | awk '{print $NF}')
    if [ "${GET_VAGRANT_VER}" != "${VAGRANT_VER}" ]; then
      NEED_INSTALL="true"
    fi
  fi
  if [ "${NEED_INSTALL}" == "true" ];then
    wget -c ${VAGRANT_URL} -O ${WORK_DIR}/${TMP_DIR}/${VAGRANT_PKG}
    sudo rpm -Uvh ${WORK_DIR}/${TMP_DIR}/${VAGRANT_PKG}
    which vagrant >/dev/null 2>&1
    if [ $? -ne 0 ];then
      quit "[for common] install vagrant failed"
    else
      echo "[for common] vagrant installed successfully"
    fi
  else
    vagrant --version
    echo "[for common] vagrant already installed"
  fi

  echo "----------------------------------------"
  echo "[for common] ensure vagrant plugin vagrant-proxyconf installed"
  vagrant plugin list | grep vagrant-proxyconf >/dev/null 2>&1
  if [ $? -ne 0 ];then
    vagrant plugin install vagrant-proxyconf --plugin-clean-sources --plugin-source http://mirrors.aliyun.com/rubygems/
  fi

  echo "----------------------------------------"
  echo "[for common] ensure ansible installed"
  ansible --version | grep "^ansible 2.7" >/dev/null 2>&1
  if [ $? -ne 0 ];then
    sudo yum install ansible
    ansible --version | grep "^ansible 2.7" >/dev/null 2>&1
    if [ $? -ne 0 ];then
      quit "install ansible failed"
    else
      echo "install ansible successfully"
    fi
  else
    echo "ansible already installed"
    ansible --version
  fi

  if [ ${PROVIDER} == "virtualbox" ];then
  # for virtualbox
    echo "-----------------------------"
    echo "[for virtualbox] ensure virtualbox5 installed"
    sudo yum install -y qt qt-x11
    sudo yum install -y kernel-devel-`uname -r` gcc
    wget -c ${VIRTUALBOX_URL} -O ${WORK_DIR}/${TMP_DIR}/${VIRTUALBOX_PKG}
    sudo rpm -Uvh ${WORK_DIR}/${TMP_DIR}/${VIRTUALBOX_PKG}
    # add current user to vboxusers
    sudo usermod -aG vboxusers $USER


  elif [ ${PROVIDER} == "libvirt" ];then
    echo "-----------------------------"
    echo "[for libvirt] ensure qemu installed"
    which qemu-system-x86_64 libvirtd >/dev/null 2>&1
    if [ $? -ne 0 ];then
      sudo yum install -y qemu libvirt  librbd1
    fi
    grep '^unix_sock_rw_perms = "0770"' /etc/libvirt/libvirtd.conf >/dev/null 2>&1
    if [ $? -eq 0 ];then
      sudo sed -i 's/unix_sock_rw_perms = "0770"/unix_sock_rw_perms = "0777"/' /etc/libvirt/libvirtd.conf
      sudo service libvirtd restart
    fi

    echo "----------------------------------------"
    if [ -s ~/.rvm/scripts/rvm ];then
      source ~/.rvm/scripts/rvm
    fi
    which rvm >/dev/null 2>&1
    if [ $? -ne 0 ];then
      echo "install rvm"
      sudo yum install -y ca-certificates
      sudo update-ca-trust
      sudo gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
      curl -kL get.rvm.io | sudo bash -s stable --ruby=$RUBY_VER
    else
      echo "[for libvirt] rvm was installed"
      rvm --version
    fi

    #patch: fix __rvm_cleanse_variables: function definition file not found
    echo "----------------------------------------"
    echo "patch for rvm and zsh"
    if [ -f $HOME/.zgen/zcompdump ]; then
      rm -rf $HOME/.zgen/zcompdump
    fi
    ls ~/.zcomp* >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      rm -rf $HOME/.zcomp*
    fi
    if [ -f $HOME/.zlogin ]; then
      rm -rf $HOME/.zlogin
    fi

    echo "----------------------------------------"
    echo "[for libvirt] ensure ruby ${RUBY_VER} installed"
    case $USER in
      root) if [ -s /etc/profile.d/rvm.sh ];then
              source /etc/profile.d/rvm.sh
            fi
            ;;
      *)    if [ -s ~/.rvm/scripts/rvm ];then
              source ~/.rvm/scripts/rvm
            fi
            ;;
    esac
    rvm reload
    rvm requirements run

    ruby --version | grep "ruby ${RUBY_VER}" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
      echo "[for libvirt] install ruby $RUBY_VER now"
      rvm install $RUBY_VER
      ruby --version | grep "ruby ${RUBY_VER}" >/dev/null 2>&1
      if [ $? -ne 0 ]; then
        quit "[for libvirt] failed to install ruby ${RUBY_VER}"
      fi
    else
      ruby --version
      echo "[for libvirt] ruby ${RUBY_VER} alreay installed"
    fi

    echo "[for libvirt] use ruby-china gem source"
    gem sources --add http://mirrors.aliyun.com/rubygems/ --remove https://rubygems.org/
    gem source -l

    echo "-----------------------------"
    echo "[for libvirt] ensure ruby-libvirt"
    gem list | grep "ruby-libvirt (${RUBY_LIBVIRT}" >/dev/null 2>&1
    if [ $? -ne 0 ];then
      gem list | grep "ruby-libvirt (${RUBY_LIBVIRT}" >/dev/null 2>&1
    fi
    if [ $? -ne 0 ];then
      sudo yum install -y libxslt-devel libxml2-devel libvirt-devel libguestfs-tools-c
      gem install --source=http://mirrors.aliyun.com/rubygems/ ruby-libvirt -v "${RUBY_LIBVIRT}"
      gem list | grep "ruby-libvirt (${RUBY_LIBVIRT}" >/dev/null 2>&1
      if [ $? -ne 0 ];then
        echo "[for libvirt] ruby-libvirt ${RUBY_LIBVIRT} installed failed"
      else
        echo "[for libvirt] ruby-libvirt ${RUBY_LIBVIRT} install successfully"
      fi
    else
      echo "[for libvirt] ruby-libvirt already installed"
    fi
    echo "-----------------------------"
    echo "[for libvirt] ensure vagrant plugin "
    for p in vagrant-libvirt vagrant-mutate vagrant-scp
    do
      echo "[for libvirt] ensure vagrant plugin : ${p} "
      vagrant plugin list | grep ${p} >/dev/null 2>&1
      if [ $? -ne 0 ];then
        vagrant plugin install ${p} --plugin-clean-sources --plugin-source http://mirrors.aliyun.com/rubygems/
      fi
    done
    vagrant plugin list

  else
    quit "unsupport provider '${PROVIDER}'"
  fi

# cat <<EOF
#
#   >FAQ 1: error "VirtualBox is complaining that the kernel module is not loaded"
#     sudo service vboxdrv setup
#
#   >FAQ 2: error "Stderr: VBoxManage: error: Could not find a controller named 'SATA Controller'"
#     cat ~/.vagrant.d/boxes/trusty/0/virtualbox/box.ovf | grep -i "storagecontroller name"
#     (REF: https://github.com/kusnier/vagrant-persistent-storage/issues/33)
#
# EOF
}

function prepare_image(){
  # centos/7 (libvirt/virtualbox) https://atlas.hashicorp.com/centos/boxes/7
  # ubuntu/trusty64 (virtualbox)  https://atlas.hashicorp.com/ubuntu/boxes/trusty64
  mkdir -p ${WORK_DIR}/${IMAGE_CACHE}
  case ${PROVIDER} in
    virtualbox)
      CUR_DISTROS=${VB_DISTROS}
      case "${CUR_DISTROS}" in
        "centos/7")
          CUR_IMAGE_NAME=${VB_CENTOS7BOX_NAME}
          CUR_IMAGE_URL=${VB_CENTOS7BOX_URL}
          CUR_IMAGE_IMG=${VB_CENTOS7BOX_IMG}
          ;;
        "fedora/22-cloud-base")
          CUR_IMAGE_NAME=${VB_FEDORA22_NAME}
          CUR_IMAGE_URL=${VB_FEDORA22_URL}
          CUR_IMAGE_IMG=${VB_FEDORA22_IMG}
          ;;
        "ubuntu/trusty64")
          CUR_IMAGE_NAME=${VB_UBUNTU1404BOX_NAME}
          CUR_IMAGE_URL=${VB_UBUNTU1404BOX_URL}
          CUR_IMAGE_IMG=${VB_UBUNTU1404BOX_IMG}
          ;;
        *) quit "unknown osdistro for provider(virtualbox)"
          ;;
      esac
      echo "update device name"
      ;;
    libvirt)
      CUR_DISTROS=${LV_DISTROS}
      case "${CUR_DISTROS}" in
        "centos/7")
          CUR_IMAGE_NAME=${LV_CENTOS7BOX_NAME}
          CUR_IMAGE_URL=${LV_CENTOS7BOX_URL}
          CUR_IMAGE_IMG=${LV_CENTOS7BOX_IMG}
          ;;
        "fedora/22-cloud-base")
          CUR_IMAGE_NAME=${LV_FEDORA22_NAME}
          CUR_IMAGE_URL=${LV_FEDORA22_URL}
          CUR_IMAGE_IMG=${LV_FEDORA22_IMG}
          ;;
        *) quit "unknown osdistro for provider(virtualbox)"
          ;;
      esac
      echo "update device name"
      ;;
    *)
      quit "unknown provider:${PROVIDER}"
      ;;
  esac

  echo "============================================"
  echo " current image info "
  echo "============================================"
  echo "CUR_IMAGE_NAME: ${CUR_IMAGE_NAME}"
  echo "CUR_IMAGE_URL : ${CUR_IMAGE_URL}"
  echo "CUR_IMAGE_IMG : ${CUR_IMAGE_IMG}"
  echo
  echo "========================================="
  echo "ensure box ${CUR_IMAGE_NAME}"
  vagrant box list | grep "${CUR_IMAGE_NAME}.*(${PROVIDER}," >/dev/null 2>&1
  if [ $? -ne 0 ];then
    echo "download and add box ${CUR_IMAGE_NAME} (${PROVIDER})"
    wget -c ${CUR_IMAGE_URL} -O ${WORK_DIR}/${IMAGE_CACHE}/${CUR_IMAGE_IMG}
    if [ -s ${WORK_DIR}/${IMAGE_CACHE}/${CUR_IMAGE_IMG} ];then
      vagrant box add --name "${CUR_IMAGE_NAME}" ${WORK_DIR}/${IMAGE_CACHE}/${CUR_IMAGE_IMG}
    fi
  else
    echo "box '${CUR_IMAGE_NAME}' already exist,skip"
  fi
  echo "============================="
  echo "list all box:"
  echo "-----------------------------"
  vagrant box list
  echo "============================="
}

function prepare_kubernetes_server() {
  KUBERNETES_VER="1.13.0"
  kubernetes_release="kubernetes-server-linux-amd64-${KUBERNETES_VER}.tar.gz"
  # Download Kubernetes
  if [[ ! -f "$kubernetes_release" ]]; then
      export http_proxy=http://192.168.122.1:8118
      export https_proxy=http://192.168.122.1:8118
      wget -c https://dl.k8s.io/v$KUBERNETES_VER/kubernetes-server-linux-amd64.tar.gz -O kubernetes-server-linux-amd64-${KUBERNETES_VER}.tar.gz
      unset http_proxy
      unset https_proxy
  fi
}

function vagrant_up(){

cat <<EOF

==========================================
Ansible        : $(ansible --version | head -n1 | grep -o "[0-9]\.[0-9]\.[0-9]\.[0-9]")
------------------------------------------
Ruby           : $(ruby --version | grep -o "[0-9]\.[0-9]\.[0-9]")
Germ           : $(gem list | grep ruby-libvirt)
------------------------------------------
Vagrant        : $(vagrant --version | grep -o "[0-9]\.[0-9]\.[0-9]")
Vagrant plugins: $(vagrant plugin list|grep vagrant-libvirt)
------------------------------------------
VirtualBox     : $(vboxmanage --version | grep -o "[0-9]\.[0-9]\.[0-9]")
------------------------------------------
Libvirt        : $(libvirtd --version | grep -o "[0-9]\.[0-9]\.[0-9]")
Qemu           : $(qemu-system-x86_64 --version | grep -o "[0-9]\.[0-9]")
==========================================

EOF

echo "sleep 3 seconds, then continue..."
sleep 3

  case "${PROVIDER}" in
    libvirt)
      sudo service vboxdrv stop
      sudo service libvirtd restart
      ;;
    virtualbox)
      sudo service libvirtd stop
      sudo service vboxdrv restart
      ;;
  esac

  VAGRANT_LOG=info vagrant up --provision --provider=${PROVIDER}
}

function destroy_all(){
  vagrant destroy
  rm .vagrant -rf && rm *.vdi -rf
  case "${PROVIDER}" in
    libvirt)
      virsh list --all| grep -v Name | awk '{print $2}' | grep imaged_default | xargs -I vm_name virsh destroy vm_name
      virsh list --all| grep -v Name | awk '{print $2}' | grep imaged_default | xargs -I vm_name virsh undefine vm_name
      ;;
    virtualbox)
      VBoxManage list runningvms | awk '{print $2;}' | grep imaged_default | xargs -I vmid VBoxManage controlvm vmid poweroff
      VBoxManage list vms | awk '{print $2;}' | grep imaged_default |xargs -I vmid VBoxManage unregistervm vmid --delete
      ;;
    *)
      quit "unknown provider(${PROVIDER})"
  esac
}

function show_usage(){
  cat <<EOF
  usage: ./util_centos.sh <command>
  <command>:
    run              # 'vagrant up --provision --provider=${PROVIDER}'
    suspend          # 'virsh suspend node<n>'
    resume           # 'virsh resume node<n>'
    halt             # 'vagrant halt'
    destroy          # 'vagrant destroy'
    list             # show VM list via 'sudo vagrant list'
    status           # show VM status via 'vagrant status'
    ssh              # enter VM via 'vagrant ssh default'
    console          # enter VM via 'sudo virsh console node<n>'
EOF
}

## main #################################################
cd ${WORK_DIR}
mkdir -p ${WORK_DIR}/${IMAGE_CACHE} ${WORK_DIR}/${TMP_DIR}
case "$1" in
  run)
    # ensure_config_file
    ensure_dependency
    prepare_image
    prepare_kubernetes_server
    vagrant_up
    ;;
  list)
    sudo virsh list | awk 'NR==1 || /kubernetes-vagrant-centos-cluster_node/'
    ;;
  status)
    vagrant status
    ;;
  halt)
    vagrant halt
    ;;
  suspend)
    if [ "$2" == "" ]; then
      quit "please specify node name, run './util_centos.sh status' to get node name list"
    fi
    sudo virsh suspend kubernetes-vagrant-centos-cluster_$2
    ;;
  resume)
    if [ "$2" == "" ]; then
      quit "please specify node name, run './util_centos.sh status' to get node name list"
    fi
    sudo virsh resume kubernetes-vagrant-centos-cluster_$2
    ;;
  destroy)
    destroy_all
    ;;
  ssh)
    if [ "$2" == "" ]; then
      quit "please specify node name, run './util_centos.sh status' to get node name list"
    fi
    vagrant ssh $2
    ;;
  console)
    if [ "$2" == "" ]; then
      quit "please specify node name, run './util_centos.sh status' to get node name list"
    fi
    sudo virsh console kubernetes-vagrant-centos-cluster_$2
    ;;
  *)
    show_usage
    ;;
esac
