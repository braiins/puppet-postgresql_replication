# == Class: postgresql-replication
#
# Basic setup of PostgreSQL server as a prerequisite for replication.
# Uses puppetlabs/postgresql module to install the software and to set
# the most important options.
# If more advanced settings are needed, do not declare this class and use the
# puppetlabs/postgresql module directly.
#
# - installs the postgresql server of a given version, defaults to 9.4
# - sets timezone and internal character encoding
# - makes the server accepting incomming TCP connections from a given IP range
# - installs additional contrib stuff
# - creates a test role - the first role aware of remote login
#
# === Parameters
#
#   Described above.
#
# === Examples
#
#  class { 'postgresql-replication':
#    allow_ip_range => '10.0.0.0/24',
#    contrib        => true,
#  }
#
# === Authors
#
# Braiins Systems s.r.o.
#
# === Copyright
#
# Copyright 2015 Braiins Systems s.r.o.
#
class postgresql-replication(
  $version = $postgresql-replication::params::version,
  $contrib = $postgresql-replication::params::contrib,
  $test_user = $postgresql-replication::params::test_user,
  $encoding = $postgresql-replication::params::encoding,
  $listen_addresses = $postgresql-replication::params::listen_addresses,
  $timezone = $postgresql-replication::params::timezone,
  $allow_ip_range = $postgresql-replication::params::allow_ip_range
) inherits postgresql-replication::params {

  class { 'postgresql::globals':
    encoding            => $encoding,
    manage_package_repo => true,
    version             => $version,
  } ->
  class { 'postgresql::server':
    listen_addresses    => $listen_addresses,
  }
  postgresql::server::config_entry { 'log_timezone':
    value => $timezone,
  }
  postgresql::server::config_entry { 'timezone':
    value => $timezone,
  }
  postgresql::server::pg_hba_rule { 'allow connections from a network':
    description => "Open up postgresql for access from a network",
    type        => 'host',
    database    => 'all',
    user        => 'all',
    address     => $allow_ip_range,
    auth_method => 'md5',
  }

  # optionally create a test user
  if ($test_user) {
    postgresql::server::role { "test_user":
      password_hash => postgresql_password('test_user', 'topsecret'),
    }
  }

  # optionally install additional useful postgreSQL modules
  if ($contrib) {
    class { 'postgresql::server::contrib':
    }
  }
}
