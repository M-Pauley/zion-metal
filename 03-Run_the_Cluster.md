# Create the Cluster
---

### Description:  
This section will create a starting MicroK8s cluster on our MaaS-controlled nodes to build on.  
Tasks for the Cluster:
- Install Microk8s.
- Add Nodes.
- Enable addons.
- Confirm and verify basic cluster operation.
- Create services for components that are not available as addons.
- Modify any service configurations as needed.
- Finalize the starting cluster operation.
- Install and configure GitOps CD system.
- 🎸🐓 Rock out! 🐓🎸


Nodes can also serve as KVM hosts and should be added in MaaS if you will need any VMs.

---

## Install Microk8s.
*clever line and emoji go here*

I somehow remember the [official docs](https://microk8s.io/docs/getting-started) and [tutorials](https://ubuntu.com/tutorials/install-a-local-kubernetes-with-microk8s#2-deploying-microk8s) for Microk8s to be written better, or at least easier to follow. Anyway, I took the best of both and simplified it for our purposes here.
  
`sudo snap install microk8s --classic`
or to install a specific version/release:
`sudo snap install microk8s --classic --channel=1.29/stable`

You probably won't have to, but this is something to keep in mind if you are or want to run a firewall.
> *Note:* You may need to configure your firewall to allow pod-to-pod and pod-to-internet communication:
> `sudo ufw status`
> `sudo ufw allow in on cni0 && sudo ufw allow out on cni0`
> `sudo ufw default allow routed`
  
Join the group to have permission to run microk8s.
(substitute $USER with your username if you'd like.)  
`sudo usermod -a -G microk8s $USER`  
`sudo chown -f -R $USER ~/.kube`  
  
- Either logout/login or `su - $USER` for the group change to take effect.
- Check if microk8s is running with `microk8s status`. You should see something like this:
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
>  disabled:
>    cert-manager         # (core) Cloud native certificate management
>    cis-hardening        # (core) Apply CIS K8s hardening
>    community            # (core) The community addons repository
>    dashboard            # (core) The Kubernetes dashboard
>    gpu                  # (core) Automatic enablement of Nvidia CUDA
>    host-access          # (core) Allow Pods connecting to Host services smoothly
>    hostpath-storage     # (core) Storage class; allocates storage from host directory
>    ingress              # (core) Ingress controller for external access
>    kube-ovn             # (core) An advanced network fabric for Kubernetes
>    mayastor             # (core) OpenEBS MayaStor
>    metallb              # (core) Loadbalancer for your Kubernetes cluster
>    metrics-server       # (core) K8s Metrics Server for API access to service metrics
>    minio                # (core) MinIO object storage
>    observability        # (core) A lightweight observability stack for logs, traces and metrics
>    prometheus           # (core) Prometheus operator for monitoring and logging
>    rbac                 # (core) Role-Based Access Control for authorisation
>    registry             # (core) Private image registry exposed on localhost:32000
>    rook-ceph            # (core) Distributed Ceph storage using Rook
>    storage              # (core) Alias to hostpath-storage add-on, deprecated  

- if everything looks good, you can check Kubernetes `microk8s kubectl get nodes` and `microk8s kubectl get all -A`

Pretty basic stuff, but it's up and running. HA-cluster is installed by default, but it won't be highly-available until we add more nodes; we will also see both datastore values change. That gives us a perfect segue to...

## Add more nodes.
Eat more chik'n

## Addons and stuff.
*another clever line and emoji go here*

1) cert-manager
   `microk8s enable cert-manager`
   Create a file to copy just your plain-text CloudFlare API Token. (~/Documents/CloudFlare.token)
   `sed -i -e "s/<API_Token>/$(base64 -w0 ~/Documents/CloudFlare.token)/g" cloudflare-api-token-secret.yaml`
   and to be fancy,
   `sed -i -e "s/<your_email_address>/literally-put-your@email.here/g" cloudflare-api-token-{issuer,clusterissuer}.yaml`
   Apply these to the cluster. Apply either issuer or clusterissuer depending on your needs. Learn the difference in the [docs](https://cert-manager.io/docs/concepts/issuer/) or a better/different explanation [here](https://platform.jetstack.io/documentation/academy/jss02/chapter1)
   ```
   microk8s kubectl apply -f cloudflare-api-token-secret.yaml
   microk8s kubectl apply -f cloudflare-api-token-clusterissuer.yaml
   microk8s kubectl apply -f cloudflare-api-token-issuer.yaml
   ```  
   Check on the status of your certificate attempt.
   `microk8s kubectl describe clusterissuers.cert-manager.io letsencrypt-issuer`
   or
   `microk8s kubectl describe issuers.cert-manager.io letsencrypt-issuer`  
   Look at the last couple lines in status for:
    > Status:
    >  Acme:
    >    Last Registered Email:  what-you-put-your@email.as
    >    Uri:                    https://acme-staging-v02.api.letsencrypt.org/acme/acct/9-digit-number
    >  Conditions:
    >    Last Transition Time:  Date-and-time-stamp
    >    Message:               The ACME account was registered with the ACME server
    >    Observed Generation:   1
    >    Reason:                ACMEAccountRegistered
    >    Status:                True
    >    Type:                  Ready
    > Events:                    <none>  
    Notice the URI is staging. Let's verify our TLS key exists and fix that.
    `microk8s kubectl describe -n cert-manager secrets letsencrypt-issuer-account-key`
    Now we should see an output like this with the tls.key containing some bytes:
    > Name:         letsencrypt-issuer-account-key
    > Namespace:    cert-manager
    > Labels:       <none>
    > Annotations:  <none>
    >
    > Type:  Opaque
    >
    > Data
    > ====
    > tls.key:  1675 bytes
    Change you cloudflare-api-token-(cluster)issuer.yaml to the production server by removing the # and placing a # at the start of the staging server line and re-run `microk8s kubectl apply -f` on the file you just edited. Re-check that everything was created ok and grab a beer. 🍻
2) metal-lb
   `microk8s enable metallb:<IP_Start-IP_End>`
3) hostpath-storage
   `microk8s enable hostpath-storage`
4) community
   `microk8s enable community`
5) traefik
   `microk8s enable traefik`