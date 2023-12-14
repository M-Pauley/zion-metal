Guide and example configs.  
  
## Contents

[MaaS cloud-init](#maas-cloud-init)  
[MaaS commissioning scripts](#maas-commissioning-scripts)  
[KVM bridge](#kvm-bridge)  

---

### MaaS cloud-init

---

### MaaS Commissioning Scripts

---

### KVM Bridge and Netplan.

To create a network bridge, create or modify */etc/netplan/01-netcfg.yaml* using [this example](./01-netcfg.yaml).  
Save the file and run `sudo netplan generate` to check for errors. If everything is good, then run `sudo netplan apply` to create KVM's brige network.

---