#!/bin/bash -x
##############################################################
# --- Start MAAS 1.0 script metadata ---
# name: 01-dell-01-openmanage-repos
# title: Dell iSM install for PowerEdge Servers with iDRAC. 
# description: Dell iSM and iSM-OSC download and install.
# script_type: commissioning
# tags: Run
# for_hardware: system_vendor: Dell, Inc.
# may_reboot: True
# recommission: True
# --- End MAAS 1.0 script metadata ---
##############################################################

# Set variables to make script updates easier.
oscfile=dcism-osc_7.3.0.0_amd64.deb
ismfile=dcism_5.3.0.0-3289.ubuntu22_amd64.deb
majversion=5300
ubuntuname=jammy


echo "Installing Dell OS Collector package and iSM v3.5.0..."
    wget "https://linux.dell.com/repo/community/openmanage/iSM/$majversion/$ubuntuname/pool/main/d/dcism-osc/$oscfile"
    sudo dpkg -i $oscfile
    wget "https://linux.dell.com/repo/community/openmanage/iSM/$majversion/$ubuntuname/pool/main/d/dcism/$ismfile"
    sudo dpkg -i $ismfile
echo "Installation complete! Cleaning up..."
    rm -fv $oscfile
    rm -fv $ismfile

## iDRAC Service Module and its dependancy should be installed and ready to manage this system.