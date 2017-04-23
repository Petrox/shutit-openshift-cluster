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

# 4.0.0 is required by selinux_policy, latest yum is now 5.0.0
chef_yum_cookbook_version="4.0.0"
chef_iptables_cookbook_version="latest"
chef_selinux_policy_cookbook_version="latest"
chef_compat_resource_cookbook_version="latest"
inject_compat_resource="false"

$SHUTIT build \
	-l debug \
	--echo -d bash \
	-m shutit-library/vagrant:shutit-library/virtualbox \
	-s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster test_config_dir                       multi_node_basic \
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
