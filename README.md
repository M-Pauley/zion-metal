# Bare-Metal deployment of the Zion Cluster.

☁️ Zion-Cluster is a Homelab multi-node server. ☁️  
Buzzwords include, but are not limited to: hyperconverged infrastructure, automation, on-prem cloud, Kubernetes, etc.  

### Quick Links
- [Build a Master Node](01-Master_Node.md)
- [Add the Worker Nodes](02-Worker_Nodes.md)
- [Release the Hounds](03-Run_the_Cluster.md)

---
## Part 1  
### Goals and Concepts: A High-level overview.
1. Hardware
   - Use hardware that is easily obtained from the usual ~~scumbags~~ sources. (Ebay, Maraketplace, etc.)
   - Hardware is what I already have. Most is retired/recycled enterprise gear.
   - Integration with networking and software sould be a learning experience, not a significant emotional one.
  
2. Infrastructure
   - Elasticity; capable of single-node, scalable to multiple.
   - Remote management and OS deployments.
   - Follow best practices according to hardware capabilities and limitations.
  
3. Storage
   - Stay within capabilities and recommendations of available hardware.
   - Shared/distributed object storage.
   - Networked bulk (block) storage.
  
4. Cloud Management
   - Centeralized cloud management system dashboard.
   - GitOps CDI implementation.

---
## Part 2  
### Hardware Overview.
🖥️ Check out details of the Hardware [here](X-a_Hardware.md).

1. Nodes.
   - 1x - Dell R710
   - 1x - Dell VRTX Chassis
     - 4x - Dell M520
  
2. Storage.
   - Dell VRTX 25x2.5" Direct Attached Storage
   - Dell MD3220i SAN Storage
   - Dell MD1200 (Attached to MD3220i)
  
3. Network.
   - UniFi Dream Machine Pro SE
   - UniFi 48-port PoE Switch

---
## Part 3  
### OS and Infrastructure.
🐧 The Base to build on.

Operating system: Ubuntu Server 22.04LTS  
Reasons for: Community support. Well-documented. My familiarity level.  

| Alternative OS Option | Reason I'm not using it.                       |
| --------------------- | ---------------------------------------------- |
| Windows Server (all)  | :fu: No. (also $$$:dollar:$$$)                 |
| Proxmox               | ZFS filesystem interaction with HW RAID.       |
| ESXi (free)           | 60-day license renewal.                        |
| Harvester             | Difficult to customize OS and iSCSI initiator. |
| RHEL-based            | Remote OS Lifecycle management options.        |
| Debian-based          | Remote OS Lifecycle management options.        |

OS Lifecycle Management: Canonical MaaS  
Reasons for: Easy to setup and configure. Ability to customize hardware/storage easily.  
Complaint: :fu: No support for standard ISO other than Ubuntu or CentOS.  

| Alternative Option    | Reason I'm not using it.                                     |
| --------------------- | ------------------------------------------------------------ |
| Foreman               | Possible extra hardware required.  Advanced config possible. |
| Terraform             | Extra hardware required.  Steep learning curve.              |
| iPXE (custom build)   | Extra hardware required.  Need OS configuration solution.    |
| Harvester             | No central deployment.  OS customization and iSCSI initiator.|
| Ironic                | High amount of configuration.  Steep learning curve.         |  

Note: The Foreman was a very close second and could probably automate 90% or more of everything. :muscle:

---
## Part 4  
### The Software
💾 What makes the world go round?

Containerization: MicroK8s
Reasons for: Quick and easy to setup. Addons for most basic features we want.
- Alternatives: K3s, (Charmed) Kubernetes

Virtualization: KVM/Virsh
Reasons for: Integration with MaaS.
- Alternatives: MicroStack, (Charmed) Openstack 

Notes:
- Software will be installed according to the current Getting Started guides and tutorials from the official documentation.  
- Installation will be mostly, if not completely, scripted in bash or using go-task.  
- Most of this software will be running as [snaps](https://docs.snapcraft.io/installing-snapd).
- Aside from my hardware-specific dependencies, I want to minimize the amount of additional required software.

---
## Part 5  
### The Cluster
🍇 The fruit of our loom.

"Deploy a Kubernetes cluster backed by Flux" following principles and practices from [onedr0p](https://github.com/onedr0p/flux-cluster-template)  
  
Baisically, we are going to 🍒cherry pick from [our template copy](https://github.com/zion-cluster/) of onedr0p's.  
Why not just follow the template guide? I want to play with OS lifecycle and automation software to manage my bare-metal systems. There are some requirements that my systems have that are slightly unique and I want to incorporate into the base OS (e.g. Dell utilities and iSCSI). I also want to make getting the cluster up and running quick, easy, and repeatable. I have procrastinated long enough and just want to get it done, and if I have to do it again, I want to hit the easy button and let it go.  

---
# Operation
- [Build a Master Node](01-Master_Node.md)
- [Add the Worker Nodes](02-Worker_Nodes.md)
- [Release the Hounds](03-Run_the_Cluster.md)