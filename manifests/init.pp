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

  $checkout = 'master',

  $geneious_db_pass,
  $geneious_db_host = '127.0.0.1',
  $geneious_database = 'geneious',
  $geneious_db_user = 'geneious',

  $specimens_pagesize = 20,
  $dna_plates_pagesize = 20,
  $dna_pagesize = 20,

  $auto_deploy = true,
  $wildfly_pass = 'wildfly'
  ) {

  package { ['git','ant']:
    ensure => present,
  }


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
    public_bind      => '127.0.0.1',
    mgmt_bind        => '127.0.0.1',
    users_mgmt       => {
      'wildfly' => {
        password => $wildfly_pass
        }
      },
    require          => Class['::java']
  }

  exec {'create oaipmh conf dir':
    command => '/opt/wildfly/bin/jboss-cli.sh -c command="/system-property=nl.naturalis.oaipmh.conf.dir:add(value=/etc/limsoaipmh)"',
    unless  => '/opt/wildfly/bin/jboss-cli.sh -c command="ls system-property" | /bin/grep nl.naturalis.oaipmh.conf.dir',
    require => Class['::wildfly'],
  }

  exec {'create log4j conf file':
    command => '/opt/wildfly/bin/jboss-cli.sh -c command="/system-property=log4j.configurationFile:add(value=/etc/limsoaipmh/log4j2.xml)"',
    unless  => '/opt/wildfly/bin/jboss-cli.sh -c command="ls system-property" | /bin/grep log4j.configurationFile',
    require => Class['::wildfly'],
  }

  file {'/etc/limsoaipmh':
    ensure => directory,
    before => Class['::wildfly'],
  }

  file {'/etc/limsoaipmh/oaipmh.properties':
    ensure  => present,
    content => template('role_limsoaipmh/oaipmh.properties.erb'),
    before  => Class['::wildfly'],
    require => File['/etc/limsoaipmh'],
    notify  => Service['wildfly'],
  }

  file {'/etc/limsoaipmh/oai-repo.geneious.properties':
    ensure  => present,
    content => template('role_limsoaipmh/oai-repo.geneious.properties.erb'),
    before  => Class['::wildfly'],
    require => File['/etc/limsoaipmh'],
    notify  => Service['wildfly'],
  }

  file {'/etc/limsoaipmh/log4j2.xml':
    ensure  => present,
    content => template('role_limsoaipmh/log4j2.xml.erb'),
    before  => Class['::wildfly'],
    require => File['/etc/limsoaipmh'],
    notify  => Service['wildfly'],
  }

  # exec {'create lims logger':
  #   cwd     => '/opt/wildfly/bin',
  #   command => '/opt/wildfly/bin/jboss-cli.sh -c command="/subsystem=logging/logger=nl.naturalis.lims2.oaipmh:add(level=DEBUG)"',
  #   unless  => '/opt/wildfly/bin/jboss-cli.sh -c command="ls subsystem=logging/logger" | /bin/grep nl.naturalis.lims2.oaipmh',
  #   require => Class['::wildfly'],
  # }

  # file { '/opt/wildfly/standalone/deployments/oaipmh.war':
  #   ensure  => present,
  #   source  => 'puppet:///modules/role_limsoaipmh/oaipmh.war',
  #   owner   => 'wildfly',
  #   group   => 'wildfly',
  #   require => [Class['wildfly'],
  #     Exec['create oaipmh conf dir'],
  #     Exec['create log4j conf file'],
  #     File['/etc/limsoaipmh/oaipmh.properties'],
  #     File['/etc/limsoaipmh/oai-repo.geneious.properties'],
  #     File['/etc/limsoaipmh/log4j2.xml']],
  #   notify  => Service['wildfly']
  # }

  vcsrepo { '/opt/nl.naturalis.oaipmh':
    ensure   => present,
    force    => true,
    provider => git,
    source   => 'https://github.com/naturalis/nl.naturalis.oaipmh',
    revision => $checkout,
    require  => Package['git'],
  }

  file {'/opt/nl.naturalis.oaipmh/nl.naturalis.oaipmh.build/build.properties':
    ensure  => present,
    content => 'war.install.dir=/opt/wildfly/standalone/deployments',
    require => Vcsrepo['/opt/nl.naturalis.oaipmh'],
  }

  exec {'make WAR ':
    cwd         => '/opt/nl.naturalis.oaipmh/nl.naturalis.oaipmh.build',
    command     => '/usr/bin/ant install',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/nl.naturalis.oaipmh'],
    require     => [Class['wildfly'],
      Package['ant'],
      Exec['create oaipmh conf dir'],
      Exec['create log4j conf file'],
      File['/etc/limsoaipmh/oaipmh.properties'],
      File['/etc/limsoaipmh/oai-repo.geneious.properties'],
      File['/etc/limsoaipmh/log4j2.xml'],
      File['/opt/nl.naturalis.oaipmh/nl.naturalis.oaipmh.build/build.properties']],
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

  include ::nginx

  ::nginx::resource::upstream { 'limsoaipmh_naturalis_nl':
    members => ['localhost:8080'],
  }

  ::nginx::resource::vhost { 'limsoaipmh.naturalis.nl':
    proxy       => 'http://limsoaipmh_naturalis_nl',
    ssl         => true,
    listen_port => 443,
    ssl_cert    => '/etc/ssl/lims_cert.pem',
    ssl_key     => '/etc/ssl/lims_key.pem',
    require     => [
      File['/etc/ssl/lims_key.pem'],
      File['/etc/ssl/lims_cert.pem']
    ],
  }

}
