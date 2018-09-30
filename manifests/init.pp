# == Class: unattended_reboot
#
# Coordinates unattended reboots of nodes across an environment,
# using a distributed mutex in etcd.
#
# === Parameters
#
# [*check_scripts_directory*]
#   Directory of scripts to verify if it's safe to reboot. A non-zero exit code
#   from one of these scripts will prevent a reboot.
#
#   Default: ''
#
# [*cron_env_vars*]
#   An array of environment variables to apply to the created cronjobs.
#   Default: []
#
# [*cron_month*]
#   Month of year at which to run unatteded-reboot command.
#   Default: '*'
#
# [*cron_monthday*]
#   Day of month at which to run unatteded-reboot command.
#   Default: '*'
#
# [*cron_weekday*]
#   Day of week at which to run unatteded-reboot command.
#   Default: '*'
#
# [*cron_hour*]
#   Hour of the day at which to run unatteded-reboot command.
#   Default: '0-5'
#
# [*cron_minute*]
#   Minute of the hour at which to run unatteded-reboot command.
#   Default: '*/5'
#
# [*enabled*]
#   Whether to enable unattended reboots.
#   Default: false
#
# [*cron_enabled*]
#   Whether to enable the unattended reboot cronjob, if `enabled` is
#   true.
#   Default: true
#
# [*etcd_endpoints*]
#   An array of etcd client endpoints.
#
#   Example: [ 'http://etcd-1.foo:2379', 'http://etcd-2.foo:2379',
#   'http://etcd-3.foo:2379' ]
#
#   Mandatory if enabled is set to `true`; defaults to [
#   'http://localhost:2379', 'http://localhost:4001' ]
#
#   Note: 2379 is IANA-assigned etcd client port, 4001 is the legacy etcd
#   client port; we try both.
#
# [*manage_package*]
#   Whether this module should manage installation/removal of the
#   'locksmithctl' package.
#
#   Default: true
#
# [*pre_reboot_scripts_directory*]
#   Directory of scripts to run before rebooting a machine to ensure that it
#   reboots gracefully (e.g. take the node out of a cluster). A non-zero exit
#   code will abort the reboot.
#
#   Default: ''
#
# [*run_unattended_upgrade*]
#   If true, 'unattended-upgrade' will be run within the reboot window defined
#   by the 'cron_*' parameters to maximise the chance that a package will be
#   upgraded and trigger a reboot.
#   Default: false
#
class unattended_reboot (
  $check_scripts_directory = '',
  $cron_env_vars = [],
  $cron_month = '*',
  $cron_monthday = '*',
  $cron_weekday = '*',
  $cron_hour = '0-7',
  $cron_minute = '*/5',
  $enabled = false,
  $etcd_endpoints = [ 'http://localhost:2379', 'http://localhost:4001' ],
  $manage_package = true,
  $pre_reboot_scripts_directory = '',
  $run_unattended_upgrade = false,
) {

  if $check_scripts_directory != '' {
    validate_absolute_path($check_scripts_directory)
  }
  if $pre_reboot_scripts_directory != '' {
    validate_absolute_path($pre_reboot_scripts_directory)
  }

  validate_array($cron_env_vars)
  validate_array($etcd_endpoints)
  validate_bool($enabled)
  validate_bool($manage_package)
  validate_bool($run_unattended_upgrade)

  if ($enabled) {
    if $cron_enabled {
      $cron_ensure = present
    } else {
      $cron_ensure = absent
    }
    $file_ensure = present
    $pkg_ensure = latest
    $supporting_packages = present

    if $run_unattended_upgrade {
      $unattended_upgrade_cron_ensure = present
    } else {
      $unattended_upgrade_cron_ensure = absent
    }

    if empty($etcd_endpoints) {
      fail('Must pass non-empty array to unattended_reboot::etcd_endpoints')
    }
  } else {
    $cron_ensure = absent
    $file_ensure = absent
    $pkg_ensure  = purged
    $unattended_upgrade_cron_ensure = absent
    $supporting_packages = absent
  }

  ensure_packages(['update-notifier-common', 'unattended-upgrades'], { ensure => $supporting_packages })

  # Upstart script to release reboot lock on boot
  file { '/etc/init/post-reboot-unlock.conf':
    ensure  => $file_ensure,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('unattended_reboot/post-reboot-unlock.erb'),
  }

  if $manage_package {
    package { 'locksmithctl':
      ensure => $pkg_ensure,
      before => File['/etc/init/post-reboot-unlock.conf'],
    }

    File['/usr/local/bin/unattended-reboot'] {
      require => Package['locksmithctl'],
    }
  }

  file { '/usr/local/bin/unattended-reboot':
    ensure  => $file_ensure,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => template('unattended_reboot/unattended-reboot.erb'),
  # Check if a reboot is required and attempt to grab the reboot mutex.
  } -> unattended_reboot::root_crontab { 'unattended-reboot':
    ensure      => $cron_ensure,
    month       => $cron_month,
    monthday    => $cron_monthday,
    weekday     => $cron_weekday,
    hour        => $cron_hour,
    minute      => $cron_minute,
    require     => Package['update-notifier-common'],
    environment => $cron_env_vars,
    command     => '/usr/local/bin/unattended-reboot',
  }

  # Run unattended upgrade to maximise the chance that an upgraded package is
  # installed within the reboot window
  unattended_reboot::root_crontab { 'unattended-upgrade':
    ensure      => $unattended_upgrade_cron_ensure,
    month       => $cron_month,
    monthday    => $cron_monthday,
    weekday     => $cron_weekday,
    hour        => $cron_hour,
    minute      => fqdn_rand(59),
    require     => Package['unattended-upgrades'],
    environment => $cron_env_vars,
    command     => '/usr/bin/unattended-upgrade',
  }
}
