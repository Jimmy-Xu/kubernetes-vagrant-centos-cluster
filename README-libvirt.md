README for libvirt
===========================

<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Disable DHCP for libvirt network](#disable-dhcp-for-libvirt-network)
- [Update kubernetes certificate](#update-kubernetes-certificate)
	- [genreate new certificate](#genreate-new-certificate)
	- [copy certificate files from host to guest](#copy-certificate-files-from-host-to-guest)
- [Deploy node again](#deploy-node-again)
- [Usage](#usage)
	- [Manage vm node](#manage-vm-node)
	- [Use Kubernetes](#use-kubernetes)
	- [Use dashboard](#use-dashboard)
- [re-install dashboard](#re-install-dashboard)

<!-- /TOC -->

# Disable DHCP for libvirt network

> to specify static ip in Vagrantfile

```
$ sudo virsh net-list
 Name                 State      Autostart     Persistent
----------------------------------------------------------
 default              active     yes           yes
 vagrant-libvirt      active     no            yes

 $ sudo virsh net-dumpxml default
 <network connections='3'>
   <name>default</name>
   <uuid>5f1a6e41-a0d2-4d02-801a-c2ce04acab91</uuid>
   <forward mode='nat'>
     <nat>
       <port start='1024' end='65535'/>
     </nat>
   </forward>
   <bridge name='virbr0' stp='on' delay='0'/>
   <mac address='52:54:00:65:a7:c4'/>
   <ip address='192.168.122.1' netmask='255.255.255.0'>
     <dhcp>
       <range start='192.168.122.2' end='192.168.122.254'/>
     </dhcp>
   </ip>
 </network>

//edit net default, remove dhcp node
$ sudo net-edit default

//recreate net default
$ sudo net-destroy default
$ sudo net-start default
```


# Update kubernetes certificate

## genreate new certificate
```
//install cfssl
$ go get -u github.com/cloudflare/cfssl/cmd/cfssl

//update hosts in kubernetes-csr.json if node ip changed

//genereate certificate for kubernetes
$ cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes

$ ll kubernetes*
-rw-r--r--  1 xjimmy  staff   575B 12 17 13:53 kubernetes-csr.json
-rw-r--r--  1 xjimmy  staff   1.6K 12 17 14:07 kubernetes-key.pem
-rw-r--r--  1 xjimmy  staff   1.2K 12 17 14:07 kubernetes.csr
-rw-r--r--  1 xjimmy  staff   1.6K 12 17 14:07 kubernetes.pem
```

## copy certificate files from host to guest
```
$ vagrant ssh-config | grep -E "(HostName|IdentityFile)"
  HostName 192.168.121.36
  IdentityFile /home/xjimmy/gopath/src/github.com/jimmy-xu/kubernetes-vagrant-centos-cluster/.vagrant/machines/node1/libvirt/private_key
  HostName 192.168.121.105
  IdentityFile /home/xjimmy/gopath/src/github.com/jimmy-xu/kubernetes-vagrant-centos-cluster/.vagrant/machines/node2/libvirt/private_key
  HostName 192.168.121.39
  IdentityFile /home/xjimmy/gopath/src/github.com/jimmy-xu/kubernetes-vagrant-centos-cluster/.vagrant/machines/node3/libvirt/private_key

$ scp -i .vagrant/machines/node1/libvirt/private_key pki/* vagrant@192.168.121.36:/vagrant/pki/
$ scp -i .vagrant/machines/node2/libvirt/private_key pki/* vagrant@192.168.121.105:/vagrant/pki/
$ scp -i .vagrant/machines/node3/libvirt/private_key pki/* vagrant@192.168.121.39:/vagrant/pki/
```

# Deploy node again

```
$ ./util_centos.sh destroy
$ ./util_centos.sh run
```

# Usage

## Manage vm node

```
//vagrant status
$ ./util_centos.sh status
Current machine states:
node1                     running (libvirt)
node2                     running (libvirt)
node3                     running (libvirt)

//virsh list
$ ./util_centos.sh list
 Id    Name                           State
 1     kubernetes-vagrant-centos-cluster_node1 running
 2     kubernetes-vagrant-centos-cluster_node3 running
 3     kubernetes-vagrant-centos-cluster_node2 running

//suspend
$ for i in 1 2 3
do
./util_centos.sh suspend node$i
done

$ ./util_centos.sh status
Current machine states:
node1                     paused (libvirt)
node2                     paused (libvirt)
node3                     paused (libvirt)

//resume
$ for i in 1 2 3
do
./util_centos.sh resume node$i
done

$ ./util_centos.sh status
Current machine states:
node1                     running (libvirt)
node2                     running (libvirt)
node3                     running (libvirt)
```

## Use Kubernetes

```
$ ./util_centos.sh ssh node1
Last login: Mon Dec 17 22:48:01 2018 from 192.168.121.1
[vagrant@node1 ~]$ sudo kubectl get nodes
NAME    STATUS   ROLES    AGE   VERSION
node1   Ready    <none>   68m   v1.13.0
node2   Ready    <none>   68m   v1.13.0
node3   Ready    <none>   68m   v1.13.0

[vagrant@node1 ~]$ sudo -s
[root@node1 vagrant]# kubectl get all --all-namespaces
NAMESPACE     NAME                                        READY   STATUS    RESTARTS   AGE
kube-system   pod/coredns-f5cf6c6fd-8cznm                 1/1     Running   0          6m42s
kube-system   pod/coredns-f5cf6c6fd-fr7pk                 1/1     Running   0          6m42s
kube-system   pod/kubernetes-dashboard-6cbfcb69b8-tkkkq   1/1     Running   0          6m40s
kube-system   pod/traefik-ingress-controller-hfp9s        1/1     Running   0          6m38s

NAMESPACE     NAME                              TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)           AGE
default       service/kubernetes                ClusterIP   10.254.0.1       <none>        443/TCP           66m
kube-system   service/kube-dns                  ClusterIP   10.254.0.2       <none>        53/UDP,53/TCP     6m42s
kube-system   service/kubernetes-dashboard      ClusterIP   10.254.255.130   <none>        8443/TCP          6m40s
kube-system   service/traefik-ingress-service   ClusterIP   10.254.172.149   <none>        80/TCP,8080/TCP   6m38s

NAMESPACE     NAME                                        DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                  AGE
kube-system   daemonset.apps/traefik-ingress-controller   1         1         1       1            1           kubernetes.io/hostname=node2   6m38s

NAMESPACE     NAME                                   READY   UP-TO-DATE   AVAILABLE   AGE
kube-system   deployment.apps/coredns                2/2     2            2           6m42s
kube-system   deployment.apps/kubernetes-dashboard   1/1     1            1           6m40s

NAMESPACE     NAME                                              DESIRED   CURRENT   READY   AGE
kube-system   replicaset.apps/coredns-f5cf6c6fd                 2         2         2       6m42s
kube-system   replicaset.apps/kubernetes-dashboard-6cbfcb69b8   1         1         1       6m40s
```

##  Use dashboard

```
//create cert for dashboard
$ vagrant ssh node1
$ sudo -i
$ cd /vagrant/addon/dashboard/
$ mkdir certs
$ openssl req -nodes -newkey rsa:2048 -keyout certs/dashboard.key -out certs/dashboard.csr -subj "/C=/ST=/L=/O=/OU=/CN=kubernetes-dashboard"
$ openssl x509 -req -sha256 -days 365 -in certs/dashboard.csr -signkey certs/dashboard.key -out certs/dashboard.crt
$ kubectl delete secret kubernetes-dashboard-certs -n kube-system
$ kubectl create secret generic kubernetes-dashboard-certs --from-file=certs -n kube-system

#re-install dashboard
$ kubectl delete pods $(kubectl get pods -n kube-system|grep kubernetes-dashboard|awk '{print $1}') -n kube-system

//get token
$ kubectl describe secret/$(kubectl get secret -nkube-system |grep admin|awk '{print $1}') -nkube-system
or
$ kubectl -n kube-system get secret $(kubectl get secret -nkube-system |grep admin|awk '{print $1}') -o jsonpath={.data.token}|base64 -d

//get ip of dashboard
$ kubectl get services -n kube-system kubernetes-dashboard
NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
kubernetes-dashboard   ClusterIP   10.254.160.11   <none>        8443/TCP   9h

//open dashboard in web browser, paste the token
https://10.254.160.11:8443
```

# FAQ

## upgrae kubernetes

```
$ rm -rf kubernetes-server-linux-amd64.tar.gz
$ ./util_centos.sh run
```
