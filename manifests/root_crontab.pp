# == Type: root_crontab
#
# Create a cron script /etc/cron.d/$title that runs as root.
#
# === Parameters
# [*ensure*]
#   Whether to create the cron.d file
#   Default: absent
#
# [*command*]
#   Command to be run by cron.
#   Default: ''
#
# [*environment*]
#   An array of environment variables to apply to the created cronjobs.
#   Default: []
#
# [*month*]
#   Month of year at which to run the cron job.
#   Default: '*'
#
# [*monthday*]
#   Day of month at which to run the cron job.
#   Default: '*'
#
# [*weekday*]
#   Day of week at which to run the cron job.
#   Default: '*'
#
# [*hour*]
#   Hour of the day at which to run the cron job.
#   Default: '0-5'
#
# [*minute*]
#   Minute of the hour at which to run the cron job.
#   Default: '*/5'
#
define unattended_reboot::root_crontab (
  $ensure = absent,
  $month = '*',
  $monthday = '*',
  $weekday = '*',
  $hour = '0-7',
  $minute = '*/5',
  $command = '',
  $environment = [],
) {
  $full_path = "/etc/cron.d/${title}"
  if ($ensure == present or $ensure == file) {
    validate_array($environment)

    file { $full_path:
      ensure  => file,
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
      content => template('unattended_reboot/crontab.erb'),
    }
  } else {
    file { $full_path:
      ensure => absent,
    }
  }
}
