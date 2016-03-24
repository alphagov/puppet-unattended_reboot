require_relative '../spec_helper'

describe 'unattended_reboot', :type => :class do
  let(:facts) {{
    :fqdn => 'foo.example.com',
  }}
  let(:default_params) {{
    :enabled => true,
  }}

  describe "enabled" do
    let(:params) { default_params.merge({
      :etcd_endpoints => ['http://etcd-1.foo:4001', 'http://etcd-2.foo:4001'],
    }) }

    it { should contain_file('/etc/init/post-reboot-unlock.conf').with_ensure('present') }
    it { should contain_file('/usr/local/bin/unattended-reboot').with_ensure('present') }

    it { should contain_cron('unattended-reboot').with_ensure('present') }

    it "passes all endpoints to locksmithctl" do
      should contain_file('/usr/local/bin/unattended-reboot').with_content(/locksmithctl -endpoint='http:\/\/etcd-1\.foo:4001,http:\/\/etcd-2\.foo:4001' lock/)
    end

    it "uses the correct FQDN when obtaining the reboot mutex" do
      should contain_file('/usr/local/bin/unattended-reboot').with_content(/locksmithctl.*lock 'foo\.example\.com'/)
    end

    it "includes all etcd endpoints when unlocking after a reboot" do
      should contain_file('/etc/init/post-reboot-unlock.conf').with_content(/locksmithctl -endpoint='http:\/\/etcd-1\.foo:4001,http:\/\/etcd-2\.foo:4001' unlock/)
    end

    context "manage_package is true" do
      let(:params) { default_params.merge({
        :manage_package => true,
      })}

      it { should contain_package('locksmithctl').with_ensure('latest') }
    end

    context "manage_package is false" do
      let(:params) { default_params.merge({
        :manage_package => false,
      })}

      it { should_not contain_package('locksmithctl') }
    end

    context "run_unattended_upgrade is true" do
      let(:params) { default_params.merge({
        :run_unattended_upgrade => true,
      })}

      it { should contain_cron('unattended-upgrade').with_ensure('present') }
    end

    context "run_unattended_upgrade is false" do
      let(:params) { default_params.merge({
        :run_unattended_upgrade => false,
      })}

      it { should contain_cron('unattended-upgrade').with_ensure('absent') }
    end

    context "empty array passed to etcd_endpoints" do
      let(:params) { default_params.merge({
        :etcd_endpoints => [],
      })}

      it { should raise_error(Puppet::Error, /Must pass non-empty array/) }
    end

    context "check_scripts_directory set" do
      let(:params) { default_params.merge({
        :check_scripts_directory => '/path',
      })}

      it { should contain_file('/usr/local/bin/unattended-reboot').with_content(/^\/bin\/run-parts --regex '.*' --exit-on-error \/path$/) }
    end

    context "check_scripts_directory not set" do
      it { should_not raise_error }
      it { should contain_file('/usr/local/bin/unattended-reboot').without_content(/^\/bin\/run-parts --regex '.*' --exit-on-error\s*$/) }
    end

    context "check_scripts_directory set to non-absolute path" do
      let(:params) { default_params.merge({
        :check_scripts_directory => 'relative',
      })}

      it { should raise_error(Puppet::Error) }
    end

    context "pre_reboot_scripts_directory set" do
      let(:params) { default_params.merge({
        :pre_reboot_scripts_directory => '/path',
      })}

      it { should contain_file('/usr/local/bin/unattended-reboot').with_content(/^\/bin\/run-parts --regex '.*' --exit-on-error \/path$/) }
    end

    context "pre_reboot_scripts_directory not set" do
      it { should_not raise_error }
      it { should contain_file('/usr/local/bin/unattended-reboot').without_content(/^\/bin\/run-parts --regex '.*' --exit-on-error\s*$/) }
    end

    context "pre_reboot_scripts_directory set to non-absolute path" do
      let(:params) { default_params.merge({
        :pre_reboot_scripts_directory => 'relative',
      })}

      it { should raise_error(Puppet::Error) }
    end
  end

  describe "disabled" do
    let(:params) {{
      :enabled => false,
    }}

    it { should contain_file('/etc/init/post-reboot-unlock.conf').with_ensure('absent') }
    it { should contain_file('/usr/local/bin/unattended-reboot').with_ensure('absent') }

    it { should contain_cron('unattended-reboot').with_ensure('absent') }
    it { should contain_cron('unattended-upgrade').with_ensure('absent') }

    context "disabled and empty array passed to etcd_endpoints" do
      let(:params) {{
        :enabled => false,
        :etcd_endpoints => [],
      }}

      it { should_not raise_error }
    end
  end
end
