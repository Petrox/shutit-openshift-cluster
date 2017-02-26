#!/bin/bash
set -x
bash ./destroy_vms.sh
[[ -z "$SHUTIT" ]] && SHUTIT="$1/shutit"
[[ ! -a "$SHUTIT" ]] || [[ -z "$SHUTIT" ]] && SHUTIT="$(which shutit)"
if [[ ! -a "$SHUTIT" ]]
then
	echo "Must have shutit on path, eg export PATH=$PATH:/path/to/shutit_dir"
	exit 1
fi
$SHUTIT build --echo -s tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster test_config_dir multi_node_basic -d bash -m shutit-library/vagrant -s shutit-library.virtualization.virtualization.virtualization virt_method libvirt "$@"
if [[ $? != 0 ]]
then
	exit 1
fi
