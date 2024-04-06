# Build the Master Node
---

### Description:  
The master node is intended to be a combination workstation, control node, and worker node.  
Tasks for this node will be
- Install the required tools and utilities.
- Setup storage components to be consumed by k8s.
- Initalize MaaS controller.
- Commission, configure, and deploy the other nodes. 

This node will also serve to verify our initial cluster and troubleshoot any problems.  

---

## Part 1:  

🧰 A large tool requires a bigger box. 🧰  

### A Fresh Start

Get started by installing Ubuntu Server v22.04 on the workstation. I'll call mine ZionNode00 since it will eventually be a control and worker node. If you haven't installed an OS a hundred times in your life, use the 🔎googler🔍 and find an install guide or use [this one](https://ubuntu.com/download/server) and find everything you need.  

> TIP: It would be a good idea to create your Github account and SSH keys so they can be imported during installation.  

As is in good practice, run `sudo apt update` followed by `sudo apt -y upgrade`. We should probably install git first `sudo apt install -y git`, and then clone the repo `git clone https://github.com/YourUserName/MyRepo-metal/` and `cd ./MyRepo-metal`.  
  
#### Dell Utils  

If you are running old, reclaimed Dell PowerEdge servers, I highly recommend installing any firmware updates and Dell utilities for your system.

> Important Note:
>
> End of Life of Open Manage Server Administrator
>
> OpenManage Server Administrator (OMSA) will reach its End of Life status during 2024. However, OMSA will be supported until End of Support Life 
> until  2027. Dell Technologies recommends managing your PowerEdge servers by using a combination of the following Systems Management tools:
>
>    Integrated Dell Remote Access Controller (iDRAC), and
>    iDRAC Service Module (iSM) 

Well, 💩 can't support it forever. If you want to install OMSA use v11.0.1.0 and/or iSM v5.3.0.0 my scripts and guide can be found [here](./Dell/README.md) under the Dell folder.  
  
#### Other Tools  
  
🛠️ Now would be a good time to install any other tools you may want; It's your workstation after all.  
To-Do (maybe):
    - [ ] Determine required addons and CLI utilities.
    - [ ] Create Go-task tasks.
    - [X] Setup networking. 
      - I did this after installing MaaS. So, lessons learned:
      - MaaS does not want to change IP addresses. Needed to remove (purge), re-initialize, re-setup PSQL and MaaS. (Total PITA)
        - Create bond(s) if not done during Ubuntu installation.
        - Setup static IP or static DHCP lease for the main incoming interface.
        - Setup static IP for the interface MaaS will be providing DHCP on.
        - Configure UniFi router PXE-VLAN to relay DHCP to the static MaaS IP.
        - Configure any additional VLANs (like storage or lxdbr).
    - [X] Figure out your storage setup.

---

## Part 2:

🚚 Put your junk in the trunk. 🚚

### Setup Local Storage

My total storage capacity on the R710 is 8x 500Gb in a RAID5, which was configured at Ubuntu installation for LVM with a 500GB VD for the OS and a 2.27TB VD for data. Eventually the data VD will be used in Longhorn for cluster storage.

### Setup iSCSI and multipath storage
  
I'm running a Dell MD3220i SAN/iSCSI device. If you are running iSCSI, now would be a good time to get these things sorted out. I used [this](https://https://linux.dell.com/files/whitepapers/iSCSI_Multipathing_in_Ubuntu_Server_1404_LTS.pdf) as a guide.  
  
🖤👑👹 It's ~~an~~ older code, sir, but it checks out. 🖤👑👹

A guide to the iSCSI setup process I did is [here](X-c_iSCSI.md). I setup the MD3220i using Dell's PowerVault Modular Disk Storage Manager (MDSM). 

---
  
## Part 3:
  
👯🔗 Yes, Master. 🔗👯  

This part is a choose-your-own-adventure story. First, you could setup [basic Microk8s services](./01-Master_Node.md#basics) as a foundation for the cluster or setup and configure the cluster nodes in [MaaS](./01-Master_Node.md#maas---🤘-metal-🤘-as-a-service).  

The route I'm choosing is to configure Microk8s services, add my nodes to MaaS, then use deployments to populate the cluster.  

### MicroK8s: Part 1
#### Basics  

Let's make this (somewhat) easy. The configs/Microk8s folder contains a yaml file to edit and put in place before we install Microk8s that will pre-configure our basic environment. Feel free to check out all the options available with examples [here](https://microk8s.io/docs/add-launch-config). 

```
sudo mkdir -p /var/snap/microk8s/common/
sudo cp microk8s-config.yaml /var/snap/microk8s/common/.microk8s.yaml
```

Then run `sudo snap install microk8s --classic` to install.
Another option is to apply the configuration file after installing the microk8s snap with `sudo snap set microk8s config="$(cat microk8s-config.yaml)"`

My config file will enable the most basic features that don't require any additional configuration. Also, I want to manually set a randomly-generated, hex-based, 32-character, persistent cluster token rather than having the system generate one to join each node so it can be sent out in the config file to the other nodes to join the cluster.  

If you mess up (like the 1,000's of times I did): `sudo snap remove microk8s` and `sudo snap forget #`, where # is the snapshot created on remove.

You probably won't have to, but this is something to keep in mind if you are or want to run a firewall.
> *Note:* You may need to configure your firewall to allow pod-to-pod and pod-to-internet communication:  
> `sudo ufw status`  
> `sudo ufw allow in on cni0 && sudo ufw allow out on cni0`  
> `sudo ufw default allow routed`  

Add yourself to the proper group `sudo usermod -a -G microk8s $USER` and either logout/login or `su - $USER` to apply the change. Then create `sudo mkdir -p ~/.kube` and set the proper permissions `sudo chown -f -R $USER ~/.kube`.

#### HA Cluster using other networking services.

I'll be honest, I don't know much about the K8s networking backend and will be sticking with Calico (MicroK8s' default). What's the difference between Callico, Cillium, KubeOVN, or WeaveNet? I'm not the person to tell you which to use, how, or why. There is, however, a guide for the KubeOVN HA setup [here](https://microk8s.io/docs/addon-kube-ovn). KubeOVN looks to have more advanced features at the cost of performance and resource consumption.  

#### Part 1: Complete

At this point, you should be able to run `microk8s status` and see a working Kubernetes service. 

>microk8s is running  
>high-availability: no  
>  datastore master nodes: 127.0.0.1:19001  
>  datastore standby nodes: none  
>addons:  
>  enabled:  
>    dns                  # (core) CoreDNS  
>    ha-cluster           # (core) Configure high availability on the current node  
>    helm                 # (core) Helm - the package manager for Kubernetes  
>    helm3                # (core) Helm 3 - the package manager for Kubernetes  

There isn't much here, but that will change in time. It would also be a good time to add any aliases to either .bashrc or .bash_aliases. I have `alias kubectl='microk8s kubectl'` to eliminate using `microk8s kubectl` and `alias k8s-getall='kubectl get all --all-namespaces'` which should show you:

>NAMESPACE     NAME                                         READY   STATUS    RESTARTS   AGE  
>kube-system   pod/calico-kube-controllers-77bd7c5b-x68rc   1/1     Running   0          71m  
>kube-system   pod/calico-node-4ldbn                        1/1     Running   0          71m  
>kube-system   pod/coredns-864597b5fd-7jzp6                 1/1     Running   0          71m  
>  
>NAMESPACE     NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                  AGE  
>default       service/kubernetes   ClusterIP   10.152.183.1    <none>        443/TCP                  72m  
>kube-system   service/kube-dns     ClusterIP   10.152.183.10   <none>        53/UDP,53/TCP,9153/TCP   71m  
>  
>NAMESPACE     NAME                         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE  
>kube-system   daemonset.apps/calico-node   1         1         1       1            1           kubernetes.io/os=linux   71m  
>  
>NAMESPACE     NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE  
>kube-system   deployment.apps/calico-kube-controllers   1/1     1            1           71m  
>kube-system   deployment.apps/coredns                   1/1     1            1           71m  
>  
>NAMESPACE     NAME                                               DESIRED   CURRENT   READY   AGE  
>kube-system   replicaset.apps/calico-kube-controllers-77bd7c5b   1         1         1       71m  
>kube-system   replicaset.apps/coredns-864597b5fd                 1         1         1       71m  

I also installed the kubectl snap package `sudo snap install kubectl --classic` and [kubecolor](https://github.com/kubecolor/kubecolor).

If you want to continue spinning up K8s, you can go [here](./01-Master_Node.md#microk8s-part-2).
Or if you would rather get more nodes added to the cluster, [continue on](./01-Master_Node.md#maas---🤘-metal-🤘-as-a-service)!

### MaaS - 🤘 Metal 🤘 as a Service 
#### Install

Now we should have the MaaS directory we can `cd ./MaaS` followed by `./maas_install.sh`. Check out the [MaaS/README.md](./README.md) to see a breakdown of what the script is doing. You could also follow [this guide](https://maas.io/docs/fresh-installation-of-maas) to manually install MaaS.  
Access your MaaS server at *http://${API_HOST}:5240/MAAS*, where *${API_HOST}* is what you entered during MaaS installation. The script should have created a logfile in the current directory if you need it (NOTE: Any sensitive data that may be in the log is in plaintext.).  
Follow the initial MaaS setup prompts and you will eventually be met with the MaaS dashboard.  
  
If you want to setup your nodes for double-duty, now would be a good time to install *virsh* or *LXD* and add the host as a MaaS VM host.
  
#### Setup

Configure host's network, setup host as a DHCP Server on a management network that has access to the Node BMC's. Setup a non-root user on the remote node's iDRAC and give it at least operator properties that can control server power. Also, don't forget to enable Redfish or remote IPMI.

Create cloud-init and add any MaaS commissioning scripts.

#### Commission and Deploy Nodes
Work in-progress.

### MicroK8s: Part 2
Work in-progress.