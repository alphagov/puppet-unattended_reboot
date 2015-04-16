# Unattended reboot

[Puppet][] module to coordinate unattended reboots for Ubuntu servers.

Used to reboot servers one-by-one during a specified window to allow security
updates to take effect, e.g. kernel or libssl upgrades.

Relies on [update-notifier-common][] to determine if a reboot is necessary.

You can specify a directory containing scripts that determine if it's safe to
invoke a reboot, e.g. query your monitoring service, by setting the
`check_scripts_directory` parameter.

You can also specify a directory of scripts to execute before the reboot
occurs, e.g. remove the node from a load balancer pool, by setting the
`pre_reboot_scripts_directory` parameter.

[Puppet]: http://docs.puppetlabs.com/puppet/
[GOV.UK]: https://www.gov.uk/
[update-notifier-common]: http://packages.ubuntu.com/search?keywords=update-notifier-common

## Requirements

Needs [etcd][] for the mutual exclusion lock.You can find the source for our
`etcd` Ubuntu package in our
[alphagov/packager](https://github.com/alphagov/packager/tree/master/pkg/etcd)
repository.


Uses [locksmithctl][] to add/remove the lock. You can find the source for our
`locksmithctl` Ubuntu package in our
[alphagov/packager](https://github.com/alphagov/packager/tree/master/pkg/locksmithctl)
repository.

[etcd]: https://coreos.com/docs/cluster-management/setup/cluster-architectures/
[locksmithctl]: https://github.com/coreos/locksmith/tree/master/locksmithctl

## License

See [LICENSE](LICENSE) file.
