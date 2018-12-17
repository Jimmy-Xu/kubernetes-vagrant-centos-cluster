README for libvirt
===========================

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

# Enter node

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

$ ./util_centos.sh ssh node1
Last login: Mon Dec 17 22:48:01 2018 from 192.168.121.1
[vagrant@node1 ~]$ sudo kubectl get nodes
NAME      STATUS    ROLES     AGE       VERSION
node1     Ready     <none>    29m       v1.11.0
node2     Ready     <none>    29m       v1.11.0
node3     Ready     <none>    29m       v1.11.0
```
