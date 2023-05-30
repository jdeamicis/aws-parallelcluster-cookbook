# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: install
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# ----------------------------------------------------------------------------------------------------------------------
# INSTALL VARIOUS DEPENDENCIES OF SLURM (INCLUDING MUNGE)

# Create directory for various sources
Chef::Log.info("Directory to be created: #{node['cluster']['sources_dir']}")
directory "#{node['cluster']['sources_dir']}" do
  user 'root'
  group 'root'
  mode '0755'
  recursive true
end

include_recipe 'aws-parallelcluster-slurm::install_jwt'
include_recipe 'aws-parallelcluster-slurm::install_pmix'
munge 'Install munge' do
  action :setup
end
slurm_dependencies 'Install slurm dependencies'

# ----------------------------------------------------------------------------------------------------------------------
# CONFIGURE SLURM USER AND GROUP

slurm_user = node['cluster']['slurm']['user']
slurm_user_id = node['cluster']['slurm']['user_id']
slurm_group = node['cluster']['slurm']['group']
slurm_group_id = node['cluster']['slurm']['group_id']

## Setup slurm group
group slurm_group do
  comment 'slurm group'
  gid slurm_group_id
  system true
end

## Setup slurm user
user slurm_user do
  comment 'slurm user'
  uid slurm_user_id
  gid slurm_group_id
  # home is mounted from the head node
  manage_home ['HeadNode', nil].include?(node['cluster']['node_type'])
  home "/home/#{slurm_user}"
  system true
  shell '/bin/bash'
end

# ----------------------------------------------------------------------------------------------------------------------
# MOUNT SLURM INSTALLATION AND CONFIG DIRECTORY FROM REMOTE HEAD NODE

# Create directory for mounting
Chef::Log.info("Directory to be created: #{node['cluster']['slurm']['install_dir']}")
directory "#{node['cluster']['slurm']['install_dir']}" do
  user 'root'
  group 'root'
  mode '0755'
  recursive true
end

# Mount /opt/slurm over NFS
# Computemgtd config is under /opt/slurm/etc/pcluster; all compute nodes share a config
mount "#{node['cluster']['slurm']['install_dir']}" do
  device(lazy { "#{node['cluster']['head_node_private_ip']}:#{node['cluster']['slurm']['install_dir']}" })
  fstype "nfs"
  options node['cluster']['nfs']['hard_mount_options']
  action %i(mount enable)
  retries 10
  retry_delay 6
end

# ----------------------------------------------------------------------------------------------------------------------
# CONFIGURE MUNGE WITH MUNGE KEY FROM HEAD NODE

# Temporary rewriting of this helper function with custom munge key path
## TODO: here I moved the munge key under /opt/slurm/etc although it normally sits in the default user's home.
## We have to generalize this.
bash 'get_munge_key' do
  user 'root'
  group 'root'
  code <<-COMPUTE_MUNGE_KEY
      set -e
      # Copy munge key from shared dir
      cp #{node['cluster']['slurm']['install_dir']}/etc/.munge/.munge.key /etc/munge/munge.key
      # Set ownership on the key
      chown #{node['cluster']['munge']['user']}:#{node['cluster']['munge']['group']} /etc/munge/munge.key
      # Enforce correct permission on the key
      chmod 0600 /etc/munge/munge.key
  COMPUTE_MUNGE_KEY
end
enable_munge_service

# ----------------------------------------------------------------------------------------------------------------------
# CONFIGURE SLURMD

# TODO: generalize this -- I don't know yet how
slurm_nodename = node['cluster']['slurm']['slurm_nodename']

# Create directory configured as SlurmdSpoolDir
directory '/var/spool/slurmd' do
  user node['cluster']['slurm']['user']
  group node['cluster']['slurm']['group']
  mode '0700'
end

include_recipe 'aws-parallelcluster-slurm::config_slurmd_systemd_service'

if node['cluster']['enable_nss_slurm'] == 'true'
  nsswitch_path = '/etc/nsswitch.conf'
  bash 'Add Slurm to nsswitch.conf' do
    code <<-NSSWITCH
      sed -i 's/^passwd: */&slurm /' #{nsswitch_path}
      sed -i 's/^group: */&slurm /' #{nsswitch_path}
    NSSWITCH
  end

  file '/etc/nss_slurm.conf' do
    content("NodeName=#{slurm_nodename}")
    mode '0644'
    owner 'root'
    group 'root'
  end
end

directory '/etc/sysconfig' do
  user 'root'
  group 'root'
  mode '0644'
end

ruby_block 'get_compute_nodename' do
  block do
    node.run_state['slurm_compute_nodename'] = slurm_nodename
  end
end

template "/etc/sysconfig/slurmd" do
  source 'compute_node_finalize/slurm/slurm.sysconfig.erb'
  user 'root'
  group 'root'
  mode '0644'
end
