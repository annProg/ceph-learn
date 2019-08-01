class ceph (
	$package = vim

	package { $package:
		ensure => present,
	}
)