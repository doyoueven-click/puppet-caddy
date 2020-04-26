require 'spec_helper'

describe 'caddy' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      context 'with defaults for all parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('caddy') }
        it { is_expected.to contain_class('caddy::params') }
        it { is_expected.to contain_class('caddy::package').that_comes_before('Class[caddy::config]') }
        it { is_expected.to contain_class('caddy::config').that_notifies('Class[caddy::service]') }
        it { is_expected.to contain_class('caddy::service') }
        it do
          is_expected.to contain_group('caddy').with(
            'ensure' => 'present',
            'system' => 'true'
          )
        end
        it do
          is_expected.to contain_user('caddy').with(
            'ensure'     => 'present',
            'shell'      => '/sbin/nologin',
            'gid'        => 'caddy',
            'system'     => 'true',
            'home'       => '/etc/ssl/caddy',
            'managehome' => 'true'
          )
        end

        it do
          is_expected.to contain_archive('/tmp/caddy_linux_amd64_custom.tar.gz').with(
            'ensure'       => 'present',
            'extract'      => 'true',
            'extract_path' => '/usr/local/bin',
            'source'       => 'https://caddyserver.com/download/linux/amd64?plugins=http.filter,http.git,http.ipfilter&license=personal&telemetry=off',
            'user'         => 'root',
            'group'        => 'root',
            'creates'      => '/usr/local/bin/caddy',
            'cleanup'      => 'true',
            'notify'       => 'File_capability[/usr/local/bin/caddy]'
          )
        end
        it do
          is_expected.to contain_file_capability('/usr/local/bin/caddy').with(
            'ensure'     => 'present',
            'capability' => 'cap_net_bind_service=ep',
            'require'    => 'Archive[/tmp/caddy_linux_amd64_custom.tar.gz]'
          )
        end

        it do
          is_expected.to contain_file('/etc/ssl/caddy/.caddy').with(
            'ensure'  => 'directory',
            'owner'   => 'caddy',
            'group'   => 'caddy',
            'mode'    => '0755'
          )
        end
        it do
          is_expected.to contain_file('/var/log/caddy').with(
            'ensure'  => 'directory',
            'owner'   => 'caddy',
            'group'   => 'caddy',
            'mode'    => '0755'
          )
        end
        it do
          is_expected.to contain_file('/etc/caddy').with(
            'ensure'  => 'directory',
            'owner'   => 'root',
            'group'   => 'root',
            'mode'    => '0755'
          )
        end
        it do
          is_expected.to contain_file('/etc/caddy/Caddyfile').with(
            'ensure'  => 'file',
            'owner'   => 'caddy',
            'group'   => 'caddy',
            'mode'    => '0444',
            'source'  => 'puppet:///modules/caddy/etc/caddy/Caddyfile',
            'require' => 'File[/etc/caddy]'
          )
        end
        it do
          is_expected.to contain_file('/etc/caddy/config').with(
            'ensure'  => 'directory',
            'purge'   => 'true',
            'recurse' => 'true',
            'owner'   => 'caddy',
            'group'   => 'caddy',
            'mode'    => '0755'
          )
        end

        case facts[:os]['release']['major']
        when '7'
          it do
            is_expected.to contain_file('/etc/systemd/system/caddy.service').with(
              'ensure'  => 'file',
              'owner'   => 'root',
              'group'   => 'root',
              'mode'    => '0744',
              'content' => %r{User=caddy},
              'notify'  => 'Exec[systemctl-daemon-reload]'
            )
          end
          it do
            is_expected.to contain_exec('systemctl-daemon-reload').with(
              'refreshonly' => 'true',
              'path'        => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
              'command'     => 'systemctl daemon-reload'
            )
          end
        when '6'
          it do
            is_expected.to contain_file('/etc/init.d/caddy').with(
              'ensure'  => 'file',
              'owner'   => 'root',
              'group'   => 'root',
              'mode'    => '0744',
              'content' => %r{DAEMONUSER=caddy}
            )
          end
        end
        it do
          is_expected.to contain_service('caddy').with(
            'ensure' => 'running',
            'enable' => 'true'
          )
        end
      end
    end
  end
end
