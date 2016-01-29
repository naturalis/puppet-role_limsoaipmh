# Class: limsoaipmh
# ===========================
#
# Full description of class limsoaipmh here.
#
# Parameters
# ----------
#
# Document parameters here.
#
# * `sample parameter`
# Explanation of what this parameter affects and what it defaults to.
# e.g. "Specify one or more upstream ntp servers as an array."
#
# Variables
# ----------
#
# Here you should define a list of variables that this module would require.
#
# * `sample variable`
#  Explanation of how this variable affects the function of this class and if
#  it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#  External Node Classifier as a comma separated list of hostnames." (Note,
#  global variables should be avoided in favor of class parameters as
#  of Puppet 2.6.)
#
# Examples
# --------
#
# @exampleo
#    class { 'limsoaipmh':
#      servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#    }
#
# Authors
# -------
#
# Author Name <author@domain.com>
#
# Copyrightdf
# ---------
#sd
# Copyright 2016 Your name here, unless odftherwise noted.
#
class role_limsoaipmh (
  $private_key,
  $certificate,
  ) {

  class { '::java':  }

  class { '::wildfly':
    version          => '8.2.1',
    install_source   => 'http://download.jboss.org/wildfly/8.2.1.Final/wildfly-8.2.1.Final.tar.gz',
    #group            => 'wildfly',
    #user             => 'wildfly',
    #dirname          => '/opt/wildfly',
    java_home        => '/usr/lib/jvm/java-1.7.0-openjdk-amd64',
    java_xmx         => '1024m',
    java_xms         => '256m',
    java_maxpermsize => '512m',
    public_bind      => '127.0.0.1'
    mgmt_bind        => '127.0.0.1',
    users_mgmt       => {
      'wildfly' => {
        password => 'wildfly'
        }
      },
    require          => Class['::java']
  }

  exec {'create nba conf dir':
    command => '/opt/wildfly/bin/jboss-cli.sh -c command="/system-property=nl.naturalis.oaipmh.conf.dir:add(value=/etc/limsoaipmh)"',
    unless  => '/opt/wildfly/bin/jboss-cli.sh -c command="ls system-property" | /bin/grep nl.naturalis.oaipmh.conf.dir',
    require => Class['::wildfly'],
  }

  file {'/etc/limsoaipmh':
    ensure => directory,
    before => Class['::wildfly'],
  }

  exec {'create lims logger':
    cwd     => '/opt/wildfly/bin',
    command => '/opt/wildfly/bin/jboss-cli.sh -c command="/subsystem=logging/logger=nl.naturalis.lims2.oaipmh:add(level=DEBUG)"',
    unless  => '/opt/wildfly/bin/jboss-cli.sh -c command="ls subsystem=logging/logger" | /bin/grep nl.naturalis.lims2.oaipmh',
    require => Class['::wildfly'],
  }


  file { '/etc/ssl/lims_key.pem' :
    ensure  => present,
    content => $private_key,
    mode    => '0644',
  }

  file { '/etc/ssl/lims_cert.pem' :
    ensure  => present,
    content => $certificate,
    mode    => '0644',
  }

  nginx::resource::upstream { 'limsoaipmh_naturalis_nl':
    members => ['localhost:8080'],
  }

  nginx::resource::vhost { 'limsoaipmf.naturalis.nl':
    proxy       => 'http://limsoaipmh_naturalis_nl',
    ssl         => true,
    listen_port => 443,
    ssl_cert    => '/etc/ssl/lims_cert.pem',
    ssl_key     => '/etc/ssl/lims_key.pem',
  }

}
