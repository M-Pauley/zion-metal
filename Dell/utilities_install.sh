#! /usr/bin/env bash
########################################################################
# 
#  This script installs Dell's OpenManage Server Administrator (OMSA)
# and iDRAC Service Module (iSM) for Dell PowerEdge Servers.
# OMSA will/has reached:
# END OF LIFE in 2024  
# END OF SUPPORT in 2027.
#
# Dell recommends management using iDRAC and iSM.
#
#    Script was based on this guide: 
#     https://linux.dell.com/repo/community/openmanage/
#
########################################################################
#
# Change these variables to update the proper package for your system
# according to the Dell Community Repository instructions.
#
# ********************************************
oscfile=dcism-osc_7.3.0.0_amd64.deb
ismfile=dcism_5.3.0.0-3289.ubuntu22_amd64.deb
majversion=5300
omsaversion=11010
ubuntuname=jammy
pgp_pubkeys=0x1285491434D8786F.asc
browser_ver="Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0"
dsu_location=FOLDER04882835M/1/
dsu_file=Systems-Management_Application_RT3W9_LN64_1.5.3_A00.BIN
# ********************************************
#
########################################################################
function install_omsa() {
    echo "Installing OMSA v11.0.1.0..."
    dellreposrc="http://linux.dell.com/repo/community/openmanage/'$omsaversion'/'$ubuntuname' '$ubuntuname'"
    sudo echo "deb $dellreposrc main" | sudo tee -a /etc/apt/sources.list.d/linux.dell.com.sources.list 
    sudo wget "https://linux.dell.com/repo/pgp_pubkeys/$pgp_pubkeys"
    sudo apt-key add $pgp_pubkeys
    sudo apt-get update
    sudo apt-get install -y srvadmin-all
    echo "$USER     *     Administrator" >> /opt/dell/srvadmin/etc/omarolemap 
    sudo service dsm_om_connsvc start
    sudo update-rc.d dsm_om_connsvc defaults
}

function remove_omsa() {
    select yn in "Yes" "No"; do
        case $yn in
            [yY]* ) echo "Purge config data?"; sudo apt-get --auto-remove purge srvadmin-all;;
            [nN]* ) echo "Just uninstall all packages."; sudo apt-get --auto-remove remove srvadmin-all;;
            * ) echo "Invalid"; remove_omsa;;
        esac
    done
}

function install_ism() {
    echo "Installing Dell OS Collector package and iSM v3.5.0..."
    wget "https://linux.dell.com/repo/community/openmanage/iSM/$majversion/$ubuntuname/pool/main/d/dcism-osc/$oscfile"
    dpkg -i $oscfile
    wget "https://linux.dell.com/repo/community/openmanage/iSM/$majversion/$ubuntuname/pool/main/d/dcism/$ismfile"
    dpkg -i $ismfile
    echo "Installation complete. Packages retained for installation on remaining Dell nodes."
}
function install_dsu() {
    wget --user-agent="$browser_ver" "https://dl.dell.com/$dsu_location/$dsu_file"
    chmod u+x ./$dsu_file
    sudo sh ./$dsu_file
    echo "Installation complete. Packages retained for installation on remaining Dell nodes."
}

echo "NOTICE: Dell OMSA has reached EOL in 2024. End of Support Life - 2027"

select opt in ["Install OMSA" "Install iSM" "Remove OMSA" "exit"]; do
    case $opt in
        "Install OMSA")
            install_omsa;;
        "Install iSM")
            install_ism;;
        "Install DSU")
            install_dsu;;
        "Remove OMSA")
            remove_omsa;;
        "exit")
            exit;;
    esac
done