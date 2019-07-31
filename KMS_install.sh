#!/usr/bin/env bash

clear
# Define text colores
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
distro="redhat"

# print function
function print {
  ScreenWidth=`tput cols`
  Arg=$@
  ArgSize=${#Arg}
  let "Rem = $ScreenWidth - $ArgSize - 1"
  printf "\n" ; printf "$Arg " ; printf '*%.0s' $(seq 1 $Rem) ; printf "\n" 
}

# install function - redhat,debian,slackware,opensuse and Arch are supported
function install {
  if dnf -y    	    install $1 &>/dev/null || 
     yum -y    	    install $1 &>/dev/null || 
     apt -y    	    install $1 &>/dev/null || 
     slackpkg  	    install $1 &>/dev/null || 
     zypper -y 	    install $1 &>/dev/null ||
     pacman -S --noconfirm  $1 &>/dev/null
  then
    echo -e "${GREEN}OK${NC}"
  else 
    echo "${RED}this is unsupported linux ditribution${NC}"
    exit 1 
  fi
}

# apt wait function
apt_wait () {
  while fuser /var/lib/dpkg/lock >/dev/null 2>&1 ; do
    sleep 1
  done
  while fuser /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
    sleep 1
  done
  if [ -f /var/log/unattended-upgrades/unattended-upgrades.log ]; then
    while fuser /var/log/unattended-upgrades/unattended-upgrades.log >/dev/null 2>&1 ; do
      sleep 1
    done
  fi
}

# Testing if root user
print "Testing if root user"
if [[ $EUID -ne 0 ]]
then
  echo -e "${RED}This script must be run as root${NC}" 
  exit 1
else
  echo -e "${GREEN}OK${NC}"
fi

# Testing Internet Connection

print "Testing Internet Connection"
if ! ping  -c 4 8.8.8.8 &>/dev/null
then 
  echo -e "${RED}please insure that your machine is connected to internet${NC}" && exit 1
else
  echo -e "${GREEN}OK${NC}"
fi

# Add required repos
print "Add required repos"
if [ "$distro" == "redhat" ]
then 
  yum -q -y install epel-release &>/dev/null || ( echo "${RED}failed to add repo${NC}" && exit 1 )
elif [ "$distro" == "debian" ]
then
  apt_wait
  apt-get install -y software-properties-common &>/dev/null && apt-add-repository ppa:ansible/ansible && apt-get update 1>/dev/null ||  ( echo "${RED}failed to add repo${NC}" && exit 1 )
fi
echo -e "${GREEN}OK${NC}"

# Installing GIT
print "Installing GIT"
install git

# Installing Ansible
print "Installing Ansible"
install ansible 

# Clone KMS_install Repo
print "Clone KMS_install Repo"
if [ ! -d /tmp/KMS_install ] || [false]
then
  git clone --branch docker --depth 1 https://github.com/amyounis/KMS_install.git /tmp/KMS_install && cd /tmp/KMS_install && echo -e "${GREEN}OK${NC}"
else
  cd /tmp/KMS_install && echo -e "${GREEN}OK${NC}"
fi

# Play Ansible Playbook
print "Play Ansible Playbook"
ansible-playbook site.yml -i hosts
