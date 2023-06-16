# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: install_slurm
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

slurm_version = node['cluster']['slurm']['version']
slurm_commit = node['cluster']['slurm']['commit']
slurm_tar_name = if slurm_commit.empty?
                   "slurm-#{slurm_version}"
                 else
                   "#{slurm_commit}"
                 end

# Clean already existing Slurm installation
bash 'make install' do
  not_if { redhat_ubi? }
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-SLURM
    set -e

    # python3 is required to build slurm >= 20.02
    source #{cookbook_virtualenv_path}/bin/activate
    cd slurm-#{slurm_tar_name}
    make uninstall
    make clean
  SLURM
end

# Install Slurm
include_recipe 'aws-parallelcluster-slurm::build_slurm'
