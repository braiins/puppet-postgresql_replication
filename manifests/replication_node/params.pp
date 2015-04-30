# == Class: postgresql-replication::replication_node::params
#
# This class defines default parameters of the replication_node class
#
#
# === Examples
#
# This class is not intended to be used directly. It may be imported
# or inherited by other classes
#
# === Authors
#
# Braiins Systems s.r.o.
#
# === Copyright
#
# Copyright 2015 Braiins Systems s.r.o.
#
class postgresql-replication::replication_node::params {
  $superuser = 'postgres',
  $master = false,
  $peer_name = undef,
  $version = '9.4',
  $replication_pubkey = undef,
  $replication_seckey = undef,
  $host_seckey = undef,
  $peerhost_pubkey = undef
}
