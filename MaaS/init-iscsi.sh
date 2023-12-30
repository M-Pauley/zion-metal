#! /usr/bin/env bash
########################################################################
# 
# Setup iSCSI initiator and Multipath.
#
#
########################################################################
echo "Getting iSCSI information..."
CHAPNAME=$(sudo cat /etc/iscsi/initiatorname.iscsi | grep -i "=" | cut -d '=' -f 2)
read -srp "Enter iSCSI Target CHAP password: " CHAPPASSWD
echo "Enter iSCSI Network Interface Name"
read -rp "Enter multiple interfaces seperated by a space:" -a IFACENAME
echo "Enter Friendly Network Interface Name"
echo "If setting multiple interfaces, make sure to set a friendly name for each interface."
read -rp "Enter multiple interfaces seperated by a space: " -a IFACENAME2
read -rp "Enter Main iSCSI Target IP: " TGTIPADDR

sed -i "s/node.startup = manual/# node.startup = manual/" iscsid.conf
sed -i "s/# node.startup = automatic/node.startup = automatic/" iscsid.conf
sed -i "s/# node.session.auth.authmethod = CHAP/node.session.auth.authmethod = CHAP/" iscsid.conf
sed -i "s/# node.session.auth.username = <chap-user>/node.session.auth.username = $CHAPNAME/" iscsid.conf
sed -i "s/# node.session.auth.password = <chap-password>/node.session.auth.password = $CHAPPASSWD/" iscsid.conf
sed -i "s/# discovery.node.session.auth.authmethod = CHAP/discovery.node.session.auth.authmethod = CHAP/" iscsid.conf
sed -i "s/# discovery.node.session.auth.username = <chap-user>/discovery.node.session.auth.username = $CHAPNAME/" iscsid.conf
sed -i "s/# discovery.node.session.auth.password = <chap-password>/discovery.node.session.auth.password = $CHAPPASSWD/" iscsid.conf

for int in ${!IFACENAME[*]}; do
    echo "Adding system interface $int to iSCSI interface list..."
    sudo iscsiadm -m iface -I "${IFACENAME[$int]}" -o new
    echo "Adding iSCSI friendly interface name ${IFACENAME[$int]} to interface ${IFACENAME2[$int]}..."
    sudo iscsiadm -m iface -I "${IFACENAME[$int]}" --op=update -n iface.net_ifacename -v "${IFACENAME2[$int]}"
done

TGTIQN=$(sudo iscsiadm -m discovery -t st -p "$TGTIPADDR" | awk -F ' ' '{print $2}' | head -1 )
sudo iscsiadm -m node -T "$TGTIQN" --login