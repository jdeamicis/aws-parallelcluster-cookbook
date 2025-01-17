# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

control 'ephemeral_drives_service_running' do
  title 'Check ephemeral drives service is running'

  only_if { !os_properties.virtualized? }

  describe service('setup-ephemeral') do
    it { should be_installed }
    it { should be_enabled }
  end
end

control 'ephemeral_drives_configured' do
  title 'Ephemeral drives script is executed and we are able to write on them'

  only_if { !os_properties.virtualized? }

  # This value is set by cfnconfig_mock.rb
  describe directory('/scratch') do
    it { should exist }
    it { should be_writable }
    it { should be_mounted }
  end
end

control 'ephemeral_drives_with_name_clashing_not_mounted' do
  title 'Check ephemeral drives are not mounted when there is name clashing with reserved names'

  only_if { !os_properties.virtualized? }

  describe service('setup-ephemeral') do
    it { should be_installed }
    it { should_not be_enabled }
    it { should_not be_running }
  end

  describe bash('systemctl show setup-ephemeral.service -p ActiveState | grep "=inactive"') do
    its(:exit_status) { should eq 0 }
  end

  describe bash('systemctl show setup-ephemeral.service -p UnitFileState | grep "=disabled"') do
    its(:exit_status) { should eq 0 }
  end
end

control 'ephemeral_service_after_network_config' do
  title 'Check setup-ephemeral service to have the correct After statement'
  network_target = os_properties.redhat? ? /^After=network-online.target/ : /^After=network.target$/
  describe file('/etc/systemd/system/setup-ephemeral.service') do
    it { should exist }
    its('content') { should match network_target }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end
end
