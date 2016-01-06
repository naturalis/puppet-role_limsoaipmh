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
# @example
#    class { 'limsoaipmh':
#      servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#    }
#
# Authors
# -------
#
# Author Name <author@domain.com>
#
# Copyright
# ---------
#
# Copyright 2016 Your name here, unless otherwise noted.
#
class limsoaipmh {

  class { '::java':  }

  class { 'wildfly':
    version          => '8.2.1',
    install_source   => 'http://download.jboss.org/wildfly/8.2.1.Final/wildfly-8.2.1.Final.tar.gz',
    #group            => 'wildfly',
    #user             => 'wildfly',
    #dirname          => '/opt/wildfly',
    java_home        => '/usr/lib/jvm/java-1.7.0-openjdk-amd64',
    java_xmx         => '1024m',
    java_xms         => '256m',
    java_maxpermsize => '512m',
    mgmt_bind        => '127.0.0.1',
    users_mgmt       => {
      'wildfly' => {
        password => 'wildfly'
        }
      },
    require => Class['::java']
  }

  # exec {'create nba conf dir':
  #   command => '/opt/wildfly/bin/jboss-cli.sh -c command="/system-property=nl.naturalis.nda.conf.dir:add(value=/etc/nba)"',
  #   unless  => '/opt/wildfly/bin/jboss-cli.sh -c command="ls system-property" | /bin/grep nl.naturalis.nda.conf.dir',
  #   require => Class['wildfly'],
  # }
  #
  # exec {'create nba logger':
  #   cwd     => '/opt/wildfly/bin',
  #   command => '/opt/wildfly/bin/jboss-cli.sh -c command="/subsystem=logging/logger=nl.naturalis.nda:add(level=DEBUG)"',
  #   unless  => '/opt/wildfly/bin/jboss-cli.sh -c command="ls subsystem=logging/logger" | /bin/grep nl.naturalis.nda',
  #   require => Class['wildfly'],
  # }


}
