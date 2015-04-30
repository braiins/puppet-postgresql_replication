# postgresql_replication

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with postgresql_replication](#setup)
    * [What postgresql_replication affects](#what-postgresql_replication-affects)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module configures PostgreSQL server with replication capability and enables
the replication on two server nodes in master-slave mode.
It has been tested with puppet 3.7.x on Debian systems.

## Module Description

This module uses the puppetlabs/postgresql module to manipulate the settings.
It consist of two components:

* install and simply configure the base PostgreSQL server
* set the replication between two given nodes

Each of the components can be omitted, but the first one, when omitted, must
be replaced by alternative basic server setup.

It uses the PostgreSQL's Log-Shipping mechanism in two ways simultaneously:

* Streaming replication for low latency sync
* supported by the file-based WAL records exchange through passwordless key-based SCP filetransfer

## Setup

### What postgresql_replication affects

* the module deploys a new PostgreSQL server instance
* it sets the server ready to accept TCP connections from a range of IP addresses
* it enables the replication capability: master on one node, slave on the other
* the configuration of master and slave is as close as possible to ease the HA failover switch


## Usage


## Reference

Classes:

## Limitations

Currently only two nodes: one master and one slave are supported.

## Development

Patches and improvements are welcome as pull requests for the central project github repository.

