# == Class: postgresql_replication::replication_node
#
# Sets up a node of a replication HA cluster of PostgreSQL servers.
#
# Uses built-in Streming replication for low latency synchronization
# and file-based WAL shipping for higher durability. Files are shipped
# using passwordless key-based SCP.
#
# Limitations:
# - currently only 2 servers (master - slave) are supported
#
# === Parameters
#
#  $master              - boolean, is the node master?
#  $peer_name           - peer's (the 2nd in the couple) hostname or IP
#  $version             - PostgreSQL version - taken from parent class by default
#  $user_seckey         - PostgreSQL superuser's SSH secret key
#  $peeruser_pubkey     - peer PostgreSQL superuser's SSH pub key
#  $host_seckey         - peers SSH secret hostkey
#  $peerhost_pubkey     - peers SSH pub hostkey
#  $superuser           - username of the superuser, 'postgres' by default
#
# === Examples
#
#  class { 'postgresql_replication::replication_node':
#    master    => true,
#    peer_name => '10.0.0.2',
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
class postgresql_replication::replication_node(
  $master = $postgresql_replication::replication_node::params::master,
  $peer_name = $postgresql_replication::replication_node::params::peer_name,
  $version = $postgresql_replication::version,
  $peeruser_pubkey = $postgresql_replication::replication_node::params::peeruser_pubkey,
  $user_seckey = $postgresql_replication::replication_node::params::user_seckey,
  $peerhost_pubkey = $postgresql_replication::replication_node::params::peerhost_pubkey,
  $host_seckey = $postgresql_replication::replication_node::params::host_seckey,
  $superuser = $postgresql_replication::replication_node::params::superuser,
) inherits postgresql_replication::replication_node::params {

  # Replication user
  postgresql::server::role { 'replicator':
    replication   => true,
    login         => true,
  }
  # HBA entry for the peer and replication user
  # Note: address must be either a hostname or an IP-range. Single host IP address
  # (without mask or CIDR) is not accepted, therefore this regexp-matching is present.
  # "\D" is a non-digit character, which, when present, determinines a hostname.
  postgresql::server::pg_hba_rule { 'allow slaves to connect':
    description => "Open up postgresql for access from hot stand-by server",
    type        => 'hostssl',
    database    => 'replication',
    user        => 'replicator',
    address     => $peer_name ? {
      /^(\D+)$/ => $peer_name,
      default   => "${peer_name}/32",
    },
    auth_method => 'trust',
  }
  # postgresql.conf replication setup
  postgresql::server::config_entry { 'wal_level':
    value => 'hot_standby',
  }
  postgresql::server::config_entry { 'max_wal_senders':
    value => '3',
  }
  postgresql::server::config_entry { 'checkpoint_segments':
    value => '16',
  }
  postgresql::server::config_entry { 'wal_keep_segments':
    value => '8',
  }

  $superuser_home = '/var/lib/postgresql'

  # archive_command is set on both peers and enabled/disabled later
  # using just archive_mode switch
  # Note: according to the documentation: The archive command should generally
  # be designed to refuse to overwrite any pre-existing archive file.
  # Our installation recycles the archive filenames and therefore we have to
  # overwrite the archive files on slave.
  postgresql::server::config_entry { 'archive_command':
    value => "scp %p ${peer_name}:${superuser_home}/${version}/main/pg_xlog/%f",
  } ->

  # slave bootstrapping script:
  file { "/usr/local/bin/pg_create_clean_replica.sh":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0750',
    content => template('postgresql_replication/replication_node/create_clean_replica.sh.erb')
  } ->

  # exchange the SSH keys and make trust
  file { "${superuser_home}/.ssh":
    ensure => directory,
    owner  => $superuser,
    group  => $superuser,
    mode   => '0700',
  } ->
  file { "${superuser_home}/.ssh/id_rsa":
    ensure  => present,
    owner   => $superuser,
    group   => $superuser,
    mode    => '0600',
    content => $user_seckey,
  } ->
  ssh_authorized_key {$superuser:
    ensure => present,
    user   => $superuser,
    name   => $peeruser_pubkey['name'],
    type   => $peeruser_pubkey['type'],
    key    => $peeruser_pubkey['key'],
  }

  # exchange host keys and make trust
  file { '/etc/ssh/ssh_host_ecdsa_key':
    ensure => present,
    owner  => root,
    group  => root,
    mode   => '0600',
    content => $host_seckey,
  }
  sshkey { $peer_name:
    target       => '/etc/ssh/ssh_known_hosts',
    ensure       => present,
    host_aliases => regsubst($peer_name, '\..+$', ''), # remove the domain name
    key          => $peerhost_pubkey['key'],
    type         => $peerhost_pubkey['type'],
  }

  # Slave is configured the same way as master (for the failover switch)
  # The differences are:
  #     * enabled hot_standby
  #     * disabled archive_mode (disables execution of configured archive_command)
  #     * presence of the recovery.conf
  #       (this is being created by the slave bootstrapping script)
  postgresql::server::config_entry { 'hot_standby':
    value => $master ? { true => 'off', false => 'on' }
  }
  postgresql::server::config_entry { 'archive_mode':
    value => $master ? { true => 'on', false => 'off' }
  }
}
