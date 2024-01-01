# Appendix B: Networking

## UniFi DDNS  
  
On the Master Node (preferrably SSH, unless you setup a Desktop Environment), we are going to clone [this unifi-ddns repo](https://github.com/workerforce/unifi-ddns) and follow its instructions (summarized here) to create a a CloudFlare worker for the UniFi UDM Pro controller to send changes to our public IP address to update our DNS domain.  

    - Install Node.js  
```
sudo apt-get update && sudo apt-get install -y ca-certificates curl gnupg
sudo mkdir -p /etc/apt/keyrings  
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=21  
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt-get update  
sudo apt-get install nodejs -y
```  
    - Install wrangler & deploy. 
Login to your CloudFlare Account.
```
git clone `https://github.com/workerforce/unifi-ddns.git
cd ./unifi-ddns
npm install wrangler --save-dev
npx wrangler deploy
```  
You'll get a warning while attempting to login. Copy the link and paste it into a browser tab. Allow access to the worker.  
  
    - Create an API token so the Worker can update your DNS records. In the permissions select Zone : DNS : Edit. Include a target zone in the Zone Resources. Copy the API Key.
    
    - Setup DYNDNS on UniFi
        - Login to UniFi Network Application.
        - Settings (gear icon) > Internet > WAN > Select the applicable WAN Interface.
        - Create New Dynamic DNS
            - Service: dyndns
            - Hostname: A record to update. (sub.domain.com)
            - Username: Domain holding the A record. (domain.com)
            - Password: API Key  copied earlier.
            - Server: CloudFlare Worker route. (e.g. unifi-cloudflare-ddns.yournamehere.workers.dev)
    - Setup the routing yourdomain.name to k8s cluster ingress proxy.