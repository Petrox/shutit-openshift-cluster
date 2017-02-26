#!/bin/bash
if [[ $(command -v VBoxManage) != '' ]]
then
	while true
	do
		VBoxManage list runningvms | grep shutit_openshift_cluster | awk '{print $1}' | xargs -IXXX VBoxManage controlvm 'XXX' poweroff && VBoxManage list vms | grep shutit_openshift_cluster | awk '{print $1}'  | xargs -IXXX VBoxManage unregistervm 'XXX' --delete
		# The xargs removes whitespace
		if [[ $(VBoxManage list vms | grep shutit_openshift_cluster | wc -l | xargs) -eq '0' ]]
		then
			break
		else
			ps -ef | grep virtualbox | grep shutit_openshift_cluster | awk '{print $2}' | xargs kill
			sleep 10
		fi
	done
fi
if [[ $(command -v virsh) != '' ]]
then
	for machine in $(virsh -c qemu:///system list | grep shutit_openshift_cluster | awk '{print $2}')
 	do
        	virsh -c qemu:///system destroy $machine 
        	virsh -c qemu:///system undefine $machine --remove-all-storage --nvram
	done
	[ -d vagrant_run/*/ ] && (cd vagrant_run/*/ && vagrant destroy -f &> /dev/null) || true
fi
rm -rf vagrant_run/*
