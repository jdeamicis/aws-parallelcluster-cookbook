# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: config_health_check
#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

directory "#{node['cluster']['slurm']['install_dir']}/etc/scripts/prolog.d" do
  user 'root'
  group 'root'
  mode '0755'
  recursive true
end

directory "#{node['cluster']['slurm']['install_dir']}/etc/pcluster/.slurm_plugin/scripts/prolog.d" do
  user 'root'
  group 'root'
  mode '0755'
  recursive true
end

directory "#{node['cluster']['slurm']['install_dir']}/etc/scripts/epilog.d" do
  user 'root'
  group 'root'
  mode '0755'
end

directory "#{node['cluster']['slurm']['install_dir']}/etc/pcluster/.slurm_plugin/scripts/epilog.d" do
  user 'root'
  group 'root'
  mode '0755'
end

cookbook_file "#{node['cluster']['slurm']['install_dir']}/etc/pcluster/.slurm_plugin/scripts/health_check_manager.py" do
  source 'config_slurm/scripts/health_check_manager.py'
  owner 'root'
  group 'root'
  mode '0755'
end

directory "#{node['cluster']['slurm']['install_dir']}/etc/pcluster/.slurm_plugin/scripts/logging" do
  user 'root'
  group 'root'
  mode '0755'
end

cookbook_file "#{node['cluster']['slurm']['install_dir']}/etc/pcluster/.slurm_plugin/scripts/logging/health_check_manager_logging.conf" do
  source 'config_slurm/scripts/logging/health_check_manager_logging.conf'
  owner 'root'
  group 'root'
  mode '0644'
end

directory "#{node['cluster']['slurm']['install_dir']}/etc/pcluster/.slurm_plugin/scripts/conf" do
  user 'root'
  group 'root'
  mode '0755'
end

template "#{node['cluster']['slurm']['install_dir']}/etc/pcluster/.slurm_plugin/scripts/conf/health_check_manager.conf" do
  source 'slurm/head_node/health_check/health_check_manager.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

directory "#{node['cluster']['slurm']['install_dir']}/etc/pcluster/.slurm_plugin/scripts/health_checks" do
  user 'root'
  group 'root'
  mode '0755'
end

cookbook_file "#{node['cluster']['slurm']['install_dir']}/etc/pcluster/.slurm_plugin/scripts/health_checks/gpu_health_check.sh" do
  source 'config_slurm/scripts/health_checks/gpu_health_check.sh'
  owner 'root'
  group 'root'
  mode '0755'
end

template "#{node['cluster']['slurm']['install_dir']}/etc/pcluster/.slurm_plugin/scripts/prolog.d/90_pcluster_health_check_manager" do
  source 'slurm/head_node/health_check/90_pcluster_health_check_manager.erb'
  owner 'root'
  group 'root'
  mode '0755'
end

link "#{node['cluster']['slurm']['install_dir']}/etc/scripts/prolog.d/90_pcluster_health_check_manager" do
  to "#{node['cluster']['slurm']['install_dir']}/etc/pcluster/.slurm_plugin/scripts/prolog.d/90_pcluster_health_check_manager"
end

cookbook_file "#{node['cluster']['slurm']['install_dir']}/etc/pcluster/.slurm_plugin/scripts/epilog.d/90_pcluster_noop" do
  source 'config_slurm/scripts/epilog.d/90_pcluster_noop'
  owner 'root'
  group 'root'
  mode '0755'
end

link "#{node['cluster']['slurm']['install_dir']}/etc/scripts/epilog.d/90_pcluster_noop" do
  to "#{node['cluster']['slurm']['install_dir']}/etc/pcluster/.slurm_plugin/scripts/epilog.d/90_pcluster_noop"
end
