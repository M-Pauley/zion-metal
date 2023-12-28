#! /usr/bin/env bash
########################################################################
# 
# Script will install QEMU/KVM/Libvirt/Virsh. After installation, the
# host computer can (and should) be added as a VM Host in MaaS.
# This script assumes CPU supports KVM virtualization and either
# VT-x(vmx) for Intel or AMD-V (svm) for AMD processors is enabled.
# I don't feel like figuring out how to script a check for it.
#
#    Script was based on this guide: 
#     https://www.linuxtechi.com/how-to-install-kvm-on-ubuntu-22-04/
#
########################################################################
#
while true; do
    read -rp "Install Virt-Manager for desktop environment VM Management?" yn
        case $yn in
            [yY] ) sudo apt install -y qemu-kvm virt-manager libvirt-daemon-system virtinst libvirt-clients bridge-utils;;
            [nN] ) sudo apt install -y qemu-kvm libvirt-daemon-system virtinst libvirt-clients bridge-utils;;
            * ) echo "Invalid";;
        esac
    done
sudo systemctl enable --now libvirtd
sudo systemctl start libvirtd
echo "Adding current user to kvm/libvirt group..."
sudo usermod -aG kvm "$USER"
sudo usermod -aG libvirt "$USER"
printf "Installation complete.\n
KVM needs manual creation of a Network Bridge to be accessed remotely.\n
See bridge configuration example in ./configs/01-netcfg.yaml\n
and check ./configs/README.yaml for guidance.\n
Manually add host to MaaS VM Management in the MaaS web GUI.\n"