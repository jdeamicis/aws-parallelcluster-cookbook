#
# Check if we are running in a virtualized environment
#
def docker?
  node['virtualization']['system'] == 'docker'
end

def redhat_ubi?
  docker? && platform?('redhat')
end