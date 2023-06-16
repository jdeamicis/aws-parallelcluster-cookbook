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

# TODO: this should ideally be part of a resource and these variables should be passed as parameters
#  to the resource actions.

slurm_install_dir = node['cluster']['slurm']['install_dir']

slurm_version = node['cluster']['slurm']['version']
slurm_commit = node['cluster']['slurm']['commit']
slurm_tar_name = if slurm_commit.empty?
                   "slurm-#{slurm_version}"
                 else
                   "#{slurm_commit}"
                 end
slurm_tarball = "#{node['cluster']['sources_dir']}/#{slurm_tar_name}.tar.gz"

# Install Slurm
bash 'make install' do
  not_if { redhat_ubi? }
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-SLURM
    set -e

    # python3 is required to build slurm >= 20.02
    source #{cookbook_virtualenv_path}/bin/activate

    tar xf #{slurm_tarball}
    cd slurm-#{slurm_tar_name}

    # Apply possible Slurm patches
    shopt -s nullglob  # with this an empty slurm_patches directory does not trigger the loop
    for patch in #{node['cluster']['sources_dir']}/slurm_patches/*.diff; do
      echo "Applying patch ${patch}..."
      patch --ignore-whitespace -p1 < ${patch}
      echo "...DONE."
    done
    shopt -u nullglob

    # Configure Slurm
    ./configure --prefix=#{slurm_install_dir} --with-pmix=/opt/pmix --with-jwt=/opt/libjwt --enable-slurmrestd

    # Build Slurm
    CORES=$(grep processor /proc/cpuinfo | wc -l)
    make -j $CORES
    make install
    make install-contrib

    deactivate
  SLURM
  # TODO: Fix, so it works for upgrade
  creates "#{slurm_install_dir}/bin/srun"
end
