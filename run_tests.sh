#!/bin/bash
set -x
set -e
./destroy_vms.sh
[[ -z "$SHUTIT" ]] && SHUTIT="$1/shutit"
[[ ! -a "$SHUTIT" ]] || [[ -z "$SHUTIT" ]] && SHUTIT="$(which shutit)"
if [[ ! -a "$SHUTIT" ]]
then
	echo "Must have shutit on path, eg export PATH=$PATH:/path/to/shutit_dir"
	exit 1
fi

if [[ $COOKBOOK_BRANCH != '' ]]
then
	cookbook_branch="${COOKBOOK_BRANCH}"
else
	cookbook_branch="master"
fi

if [[ $OSE_VERSIONS = '' ]]
then
	OSE_VERSIONS='1.3 1.4 1.5'
fi

# 4.0.0 is required by selinux_policy, latest yum is now 5.0.0
chef_yum_cookbook_version="4.0.0"
chef_iptables_cookbook_version="latest"
chef_selinux_policy_cookbook_version="latest"
chef_compat_resource_cookbook_version="latest"
inject_compat_resource="false"

if [[ ${QUICK:-0} = '1' ]]
then
	echo 'LOG: RUNNING QUICK MODE'
	$SHUTIT build \
		-l info \
		--echo -d bash \
		-m shutit-library/vagrant:shutit-library/virtualbox \
		-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster test_config_dir                       test_single_master_embedded_etcd \
		-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster ose_version                           1.4.1-1.el7 \
		-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster ose_major_version                     1.4 \
		-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster cookbook_branch                       ${cookbook_branch} \
		-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster chef_yum_cookbook_version             ${chef_yum_cookbook_version} \
		-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster chef_iptables_cookbook_version        ${chef_iptables_cookbook_version} \
		-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster chef_selinux_policy_cookbook_version  ${chef_selinux_policy_cookbook_version} \
		-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster chef_compat_resource_cookbook_version ${chef_compat_resource_cookbook_version} \
		-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster chef_version                          12.16.42-1 \
		-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster inject_compat_resource                ${inject_compat_resource} \
		"$@"
	./destroy_vms.sh
else
	for ose_major_version in ${OSE_VERSIONS}
	do
		for test_dir in test_multi_node_separate_etcd
		do
			# see http://mirror.centos.org/centos/7/paas/x86_64/openshift-origin/
			if [[ $ose_major_version == '1.5' ]]
			then
			        ose_version="1.5.0-1.el7"
			elif [[ $ose_major_version == '1.4' ]]
			then
			        ose_version="1.4.1-1.el7"
			elif [[ $ose_major_version == '1.3' ]]
			then
			        ose_version="1.3.3-1.el7"
			fi
	
			echo "LOG: RUNNING test_dir:${test_dir} ose_version:${ose_version} ose_major_version:${ose_major_version} cookbook_branch:${cookbook_branch}"
			$SHUTIT build \
				-l info \
				--echo -d bash \
				-m shutit-library/vagrant:shutit-library/virtualbox \
				-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster test_config_dir                       ${test_dir} \
				-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster ose_version                           ${ose_version} \
				-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster ose_major_version                     ${ose_major_version} \
				-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster cookbook_branch                       ${cookbook_branch} \
				-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster chef_yum_cookbook_version             ${chef_yum_cookbook_version} \
				-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster chef_iptables_cookbook_version        ${chef_iptables_cookbook_version} \
				-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster chef_selinux_policy_cookbook_version  ${chef_selinux_policy_cookbook_version} \
				-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster chef_compat_resource_cookbook_version ${chef_compat_resource_cookbook_version} \
				-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster chef_version                          12.16.42-1 \
				-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster inject_compat_resource                ${inject_compat_resource} \
				"$@"
			./destroy_vms.sh
		done
	done
fi

## $WORK-specific
#$SHUTIT build \
#	--echo -d bash \
#	-l info \
#	-m shutit-library/vagrant:shutit-library/virtualbox \
#	-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster test_config_dir                       test_multi_node_separate_etcd \
#	-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster ose_version                           1.2.1-1.el7 \
#	-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster ose_major_version                     1.2 \
#	-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster cookbook_branch                       master \
#	-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster chef_yum_cookbook_version             3.6.1 \
#	-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster chef_iptables_cookbook_version        1.0.0 \
#	-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster chef_selinux_policy_cookbook_version  0.7.2 \
#	-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster chef_compat_resource_cookbook_version latest \
#	-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster chef_version                          12.4.1-1 \
#	-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster inject_compat_resource                true \
#    "$@"
#./destroy_vms.sh
