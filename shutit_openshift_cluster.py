import random
import inspect
import string
import os
import jinja2
import importlib
import logging

from shutit_module import ShutItModule

class shutit_openshift_cluster(ShutItModule):


	def build(self, shutit):
		# Extract password from 'secret' file (which git ignores).
		# TODO: check perms are only readable by user
		try:
			pw = file('secret').read().strip()
		except IOError:
			pw = ''
		if pw == '':
			shutit.log('''WARNING! IF THIS DOES NOT WORK YOU MAY NEED TO SET UP A 'secret' FILE IN THIS FOLDER!''',level=logging.CRITICAL)
		vagrant_image = shutit.cfg[self.module_id]['vagrant_image']
		vagrant_provider = shutit.cfg[self.module_id]['vagrant_provider']
		memory = shutit.cfg[self.module_id]['memory']
		gui = shutit.cfg[self.module_id]['gui']
		# Collect the - expect machines dict to be set up here
		test_config_module = importlib.import_module('tests.' + shutit.cfg[self.module_id]['test_config_dir'] + '.machines')
		self_dir = os.path.dirname(os.path.abspath(inspect.getsourcefile(lambda:0)))
		shutit.cfg[self.module_id]['vagrant_run_dir'] = self_dir + '/vagrant_run'
		run_dir = shutit.cfg[self.module_id]['vagrant_run_dir']
		module_name = 'shutit_openshift_cluster_' + ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(6))
		shutit.send('command rm -rf ' + run_dir + '/' + module_name + ' && command mkdir -p ' + run_dir + '/' + module_name + ' && command cd ' + run_dir + '/' + module_name)
		shutit.multisend('vagrant init ' + vagrant_image,{'assword':pw})
		template = jinja2.Template(file(self_dir + '/tests/' + shutit.cfg[self.module_id]['test_config_dir'] + '/Vagrantfile').read())
		shutit.send_file(run_dir + '/' + module_name + '/Vagrantfile',str(template.render(vagrant_image=vagrant_image,cfg=shutit.cfg[self.module_id])))
		for machine in test_config_module.machines.keys():
			shutit.multisend('vagrant up --provider ' + shutit.cfg['shutit-library.virtualization.virtualization.virtualization']['virt_method'] + ' ' + machine,{'assword for':pw},timeout=99999)
		###############################################################################
		# SET UP MACHINES AND START CLUSTER
		###############################################################################
		for machine in sorted(test_config_module.machines.keys()):
			ip = shutit.send_and_get_output('''vagrant ssh-config ''' + test_config_module.machines[machine]['fqdn'] + ''' 2> /dev/null | awk '/HostName/ {print $2}' ''')
			test_config_module.machines.get(machine).update({'ip':ip})
		for machine in test_config_module.machines.keys():
			shutit.login(command='vagrant ssh ' + machine)
			shutit.login(command='sudo su - ')
			shutit.install('git')
			# Allow logins via ssh between machines
			shutit.send('rpm -i https://packages.chef.io/stable/el/7/chef-' + shutit.cfg[self.module_id]['chef_version'] + '.el7.x86_64.rpm',note='install chef')
			shutit.send('mkdir -p /root/chef-solo-example /root/chef-solo-example/cookbooks /root/chef-solo-example/environments /root/chef-solo-example/logs',note='Create chef folders')
			shutit.send('cd /root/chef-solo-example/cookbooks')
			shutit.send('git clone -b ' + shutit.cfg[self.module_id]['cookbook_branch'] + ' https://github.com/IshentRas/cookbook-openshift3',note='Clone chef repo')
			if shutit.cfg[self.module_id]['inject_compat_resource']:                                                                                                                           
				shutit.send("""echo "depends 'compat_resource'" >> cookbook-openshift3/metadata.rb""") 
			# Filthy hack to 'override' the node['ipaddress'] value
			if shutit.cfg[self.module_id]['chef_iptables_cookbook_version'] == 'latest':
				shutit.send('curl -L https://supermarket.chef.io/cookbooks/iptables/download | tar -zxvf -',note='Get cookbook dependencies')
			else:
				shutit.send('curl -L https://supermarket.chef.io/cookbooks/iptables/versions/'+ shutit.cfg[self.module_id]['chef_iptables_cookbook_version'] + '/download | tar -zxvf -',note='Get cookbook dependencies')
			if shutit.cfg[self.module_id]['chef_yum_cookbook_version'] == 'latest':
				shutit.send('curl -L https://supermarket.chef.io/cookbooks/yum/download | tar -zxvf -',note='Get cookbook dependencies')
			else:
				shutit.send('curl -L https://supermarket.chef.io/cookbooks/yum/versions/'+ shutit.cfg[self.module_id]['chef_yum_cookbook_version'] + '/download | tar -zxvf -',note='Get cookbook dependencies')
			if shutit.cfg[self.module_id]['chef_selinux_policy_cookbook_version'] == 'latest':
				shutit.send('curl -L https://supermarket.chef.io/cookbooks/selinux_policy/download | tar -zxvf -',note='Get cookbook dependencies')
			else:
				shutit.send('curl -L https://supermarket.chef.io/cookbooks/selinux_policy/versions/'+ shutit.cfg[self.module_id]['chef_selinux_policy_cookbook_version'] + '/download | tar -zxvf -',note='Get cookbook dependencies')
			if shutit.cfg[self.module_id]['chef_compat_resource_cookbook_version'] == 'latest':
				shutit.send('curl -L https://supermarket.chef.io/cookbooks/compat_resource/download | tar -zxvf -',note='Get cookbook dependencies')
			else:
				shutit.send('curl -L https://supermarket.chef.io/cookbooks/compat_resource/versions/'+ shutit.cfg[self.module_id]['chef_compat_resource_cookbook_version'] + '/download | tar -zxvf -',note='Get cookbook dependencies')
			# Create solo.rb
			template = jinja2.Template(file(self_dir + '/tests/' + shutit.cfg[self.module_id]['test_config_dir'] + '/solo.rb').read())
			shutit.send_file('/root/chef-solo-example/solo.rb',str(template.render()),note='Create solo.rb file')
			# Create environment file
			template = jinja2.Template(file(self_dir + '/tests/' + shutit.cfg[self.module_id]['test_config_dir'] + '/environment.json').read())
			shutit.send_file('/root/chef-solo-example/environments/ocp-cluster-environment.json',str(template.render(test_config_module=test_config_module,cfg=shutit.cfg[self.module_id])),note='Create environment file')
			shutit.logout()
			shutit.logout()

		for machine in test_config_module.machines.keys():
			shutit.login(command='vagrant ssh ' + machine)
			shutit.login(command='sudo su - ')
                        shutit.send('nohup chef-solo --environment ocp-cluster-environment -o recipe[cookbook-openshift3] -c ~/chef-solo-example/solo.rb &',note='set up crontab on ' + machine)
			shutit.logout()
			shutit.logout()
	
		# CHECKS
		# 1) CHECK NODES COME UP	
		shutit.login(command='vagrant ssh master1')
		shutit.login(command='sudo su - ')
		shutit.send_until('oc get all || tail /root/nohup.out','.*kubernetes.*',cadence=20,note='Wait until oc get all returns OK')
		for machine in test_config_module.machines.keys():
			if test_config_module.machines[machine]['is_node']:
				shutit.send_until('oc get nodes',machine + '.* Ready.*',cadence=20,note='Wait until oc get all returns OK')
		shutit.logout()
		shutit.logout()
		shutit.pause_point('Deployment OK?')
		shutit.logout()
		shutit.logout()
		return True


	def get_config(self, shutit):
		shutit.get_config(self.module_id,'vagrant_image',default='centos/7')
		shutit.get_config(self.module_id,'vagrant_provider',default='libvirt')
		shutit.get_config(self.module_id,'gui',default='false')
		# Vagrantfile and environment files in here
		shutit.get_config(self.module_id,'test_config_dir',default='multi_node_basic')
		# To test different cookbook versions
		shutit.get_config(self.module_id,'chef_yum_cookbook_version',default='4.0.0')
		shutit.get_config(self.module_id,'chef_iptables_cookbook_version',default='latest')
		shutit.get_config(self.module_id,'chef_selinux_policy_cookbook_version',default='latest')
		shutit.get_config(self.module_id,'chef_compat_resource_cookbook_version',default='latest')
		shutit.get_config(self.module_id,'chef_version',default='12.16.42-1')
		shutit.get_config(self.module_id,'pw',default='')
		shutit.get_config(self.module_id,'ose_major_version',default='1.4')
		shutit.get_config(self.module_id,'cookbook_branch',default='master')
		shutit.get_config(self.module_id,'ose_version',default='1.4.1-1.el7')
		shutit.get_config(self.module_id,'openshift_docker_image_version',default='v1.4.1')
		shutit.get_config(self.module_id,'inject_compat_resource',default=False,boolean=True) 
		shutit.get_config(self.module_id,'memory',default='512')
		return True


def module():
	return shutit_openshift_cluster(
		'tk.shutit.shutit_openshift_cluster.shutit_openshift_cluster', 857091783.0001,
		description='',
		maintainer='',
		delivery_methods=['bash'],
		depends=['shutit.tk.setup','shutit-library.virtualization.virtualization.virtualization','tk.shutit.vagrant.vagrant.vagrant']
	)
