Update certificate for kubernetes
===========================

# genreate new certificate
```
//install cfssl
$ go get -u github.com/cloudflare/cfssl/cmd/cfssl

//update hosts in kubernetes-csr.json

//genereate certificate for kubernetes
$ cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes

$ ll kubernetes*
-rw-r--r--  1 xjimmy  staff   575B 12 17 13:53 kubernetes-csr.json
-rw-r--r--  1 xjimmy  staff   1.6K 12 17 14:07 kubernetes-key.pem
-rw-r--r--  1 xjimmy  staff   1.2K 12 17 14:07 kubernetes.csr
-rw-r--r--  1 xjimmy  staff   1.6K 12 17 14:07 kubernetes.pem
```

# copy certificate files from host to guest
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

# deploy node again

```
$ ./util_centos.sh run
```
