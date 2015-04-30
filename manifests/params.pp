# == Class: postgresql-replication::params
#
# This class defines default parameters of the main postgresql-replication class
#
#
# === Examples
#
# This class is not intended to be used directly.
# It may be imported or inherited by other classes
#
# === Authors
#
# Braiins Systems s.r.o.
#
# === Copyright
#
# Copyright 2014 Braiins Systems s.r.o.
#
class postgresql-replication::params {
  $version = '9.4',
  $contrib = false,
  $test_user = false,
  $encoding = 'UTF8',
  $listen_addresses = '*',
  $timezone = 'UTC',
  $allow_ip_range = '127.0.0.1/32'
}

