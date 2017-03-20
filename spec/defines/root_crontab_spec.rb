require_relative '../spec_helper'

describe 'unattended_reboot::root_crontab', :type => :define do
  let(:title) { 'crontest' }
    let(:default_params) {{
      :ensure => 'present',
      :command => 'testCmd',
    }}

  context 'present' do
    let(:params) { default_params }
    it { should contain_file('/etc/cron.d/crontest').with_ensure('file') }
    it { should contain_file('/etc/cron.d/crontest').with_content(/\*\/5 0-7 \* \* \* root testCmd/) }

    context 'environment variables set' do
      let(:params) { default_params.merge({ :environment => ['ONE=1', 'TWO=2'], }) }
      it { should contain_file('/etc/cron.d/crontest').with_content(/ONE=1\nTWO=2\n\*\/5 0-7 \* \* \* root testCmd/m) }
    end
  end

  context 'file' do
    let(:params) { default_params.merge({ :ensure => 'file', }) }
    it { should contain_file('/etc/cron.d/crontest').with_ensure('file') }
    it { should contain_file('/etc/cron.d/crontest').with_content(/\*\/5 0-7 \* \* \* root testCmd/) }
  end

  context 'defaults' do
    let(:params) { {} }
    it { should contain_file('/etc/cron.d/crontest').with_ensure('absent') }
  end

  context 'absent' do
    let(:params) { default_params.merge({ :ensure => 'absent', }) }

    it { should contain_file('/etc/cron.d/crontest').with_ensure('absent') }
  end
end
