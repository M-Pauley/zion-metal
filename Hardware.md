## Part 2: The Hardware.
:desktop_computer:
1. Nodes.
   - 1x - Dell R710
   - 4x - Dell M520 (VRTX Chassis)
  
2. Storage.
   - Dell VRTX 25x2.5" Direct Attached Storage.
     - 20x - 1.2TB HDD 
       - 4x RAID5 Virtual Disks.
       - 1x Virtual Disk per M520
       - Distributed object storage.
   - Dell MD3220i SAN Storage
     - 5x 1.5TB
       - Single RAID5 Virtual Disk
       - Small-scale NAS storage.
   - Dell MD1200 (Attached to MD3220i)
     - 9x 6TB (RAID6)
     - Bulk media file storage.
  
3. Network.
   - UniFi Dream Machine Pro SE
   - UniFi 48 port PoE Switch
     - 2x 2-port LAGG Groups for R710.
     - 1x 8-port LAGG Group for VRTX R2401 - 1GB switch module.
     - 5x 1-port MD3220i Connections with DHCP enabled.
     - 3x 1-port iDRAC Management connections.