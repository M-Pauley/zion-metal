## Master Node iSCSI and Multipath setup.  
  
After configuring the Virtual Disks, iSCSI LUNs, host ports, CHAP Authentication  
`sudo cat /etc/iscsi/initiatorname.iscsi | grep -i "=" | cut -d '=' -f 2` to obtain the iSCSI initiator name needed next.  
edit `/etc/iscsi/iscsid.conf`, then find, uncomment, and/or modify these lines:  
``` 
 node.startup = automatic 
 node.session.auth.authmethod = CHAP 
 node.session.auth.username = *< iscsi initiator name from earlier >* 
 node.session.auth.password = *< CHAP password set in the SAN >* 
 discovery.node.session.auth.authmethod = CHAP 
 discovery.node.session.auth.username = *< iscsi initiator name from earlier >* 
 discovery.node.session.auth.password = *< CHAP password set in the SAN >*  
```
Restart open-iscsi.  
`sudo systemctl restart iscsid.service`  
Create iSCSI interface(s) and add a name to each network port.  
`ip n | awk -d '{print $3}'` - get the name.  
`sudo iscsiadm -m iface -I storage.vlan.or.interface.name -o new` - make new interface  
`sudo iscsiadm -m iface -I storage.vlan.or.interface.name --op=update -n iface.net_ifacename -v storenet` -  logical name for it.  
Let's see if we got it right.
`sudo iscsiadm -m discovery -t st -p <iscsi ip address>` - Gives you the target ID (iqn. address).
`sudo iscsiadm -m node -T <targetID-iqn.> ---login` - Will login to the iSCSI device (where targetID is from previous command).  
  
About the only thing to do at this point is to check if the session is open with `sudo iscsiadm -m session -P 1`.

You'll have to go into MDSM and connect to the array. Under *Host Mappings > Unassociated Host Port Identifiers* and associate your new connection to a host group.
  
Restart open-iscsi service again and if the Gods are kind, it should be 100% connected.
  
Running `sudo multipath -ll` and `sudo multipath -v3` should now show a bunch of data, some of which should look familiar.
  
Tweak whatever iSCSI and Multipath settings you want or need. Format to your liking. Mount and add to */etc/fstab*.  
`sudo blkid` - to get the iSCSI device UUID.
append the drives to `/etc/fstab`. Use whichever options you need, but for my example:
```
UUID="417637cb-9c61-4b9e-8618-5b4f02662a6b"     /mnt/m          _netfs, rw, umask=777       0   0
UUID="d07ccc50-e35a-43d9-a566-b035380c223a"     /mnt/e          _netfs, rw, umask=666       0   0
```
**don’t forget to pass the *_netdev* option in fstab. This indicates a network file system which needs to be unmounted before the network services are stopped. Without this, the system will hang on reboot.**