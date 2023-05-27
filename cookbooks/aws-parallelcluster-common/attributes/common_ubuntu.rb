# Ubuntu common attributes shared between multiple cookbooks

return unless platform?('ubuntu')

# Modulefile Directory
default['cluster']['modulefile_dir'] = "/usr/share/modules/modulefiles"

# Nvidia Repository for fabricmanager and datacenter-gpu-manager
default['cluster']['nvidia']['cuda']['repository_uri'] = "https://developer.download.nvidia._domain_/compute/cuda/repos/#{node['cluster']['base_os']}/#{arm_instance? ? 'sbsa' : 'x86_64'}"
