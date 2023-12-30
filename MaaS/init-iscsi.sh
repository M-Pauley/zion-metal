#! /usr/bin/env bash
########################################################################
# 
# Setup iSCSI initiator and Multipath.
#
#
########################################################################
GATHER_INFO() {
    echo "Getting iSCSI information..."
    sudo cat /etc/iscsi/initiatorname.iscsi | grep -i "=" | cut -d '=' -f 2
}