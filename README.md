# Bare-Metal deployment of the Zion Cluster.

☁️ Zion-Cluster is a Homelab multi-node server. ☁️

---
## Part 1: Goals and Concepts (High-level)
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
## Part 2: Hardware Overview.
:desktop_computer:
Check out details of the Hardware [here](Hardware.md).

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
## Part 3: OS and Infrastructure.
:penguin:

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
## Part 4: The Software
:floppy_disk:

