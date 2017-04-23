machines = {}
machines.update({'master1':{'fqdn':'master1.vagrant.test','is_node':True,'region':'infra'}})
machines.update({'master2':{'fqdn':'master2.vagrant.test','is_node':True,'region':'infra'}})
machines.update({'etcd1':{'fqdn':'etcd1.vagrant.test','is_node':False}})
machines.update({'etcd2':{'fqdn':'etcd2.vagrant.test','is_node':False}})
machines.update({'etcd3':{'fqdn':'etcd3.vagrant.test','is_node':False}})
machines.update({'node1':{'fqdn':'node1.vagrant.test','is_node':True,'region':'user'}})
machines.update({'node2':{'fqdn':'node2.vagrant.test','is_node':True,'region':'user'}})
