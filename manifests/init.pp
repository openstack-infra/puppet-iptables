# Class: iptables
#
# http://projects.puppetlabs.com/projects/1/wiki/Module_Iptables_Patterns
#
# params:
#   rules4: A list of additional iptables v4 rules
#          eg: [ '-m udp -p udp -s 127.0.0.1 --dport 8125 -j ACCEPT' ]
#   rules6: A list of additional iptables v6 rules
#          eg: [ '-m udp -p udp -s ::1 --dport 8125 -j ACCEPT' ]
#   public_tcp_ports: List of integer TCP ports on which to allow all traffic
#   public_udp_ports: List of integer UDP ports on which to allow all traffic
#   allowed_hosts: An array of hashes in the form:
#      hostname => str
#      port => int
#      protocol => 'udp' or 'tcp'
#   All entries in allowed_hosts will be resolved to ip addresses and added as
#   additional ACCEPT rules
class iptables(
  $rules4           = [],
  $rules6           = [],
  $public_tcp_ports = [],
  $public_udp_ports = [],
  $snmp_v4hosts     = [],
  $snmp_v6hosts     = [],
  $allowed_hosts    = [],
) {

  include ::iptables::params

  # This is to work-around rhbz#1327786 ; the iptables-service package
  # incorrectly "provides" an old iptables version and confuses rpm,
  # making it uninstallable (this was apparently done as part of a
  # package-split).  Pre-installing the iptables instead of leaving it
  # up to the dependency resolver works-around this.
  # 2016-12-20 : fixed in iptables-1.6.0-3.fc26 so we can remove this
  # when we've moved past F25
  if $::operatingsystem == 'Fedora' {
    package { 'iptables-actual':
      ensure => present,
      name   => 'iptables',
      before => Package['iptables']
    }
  }

  package { 'iptables':
    ensure => present,
    name   => $::iptables::params::package_name,
  }

  if ($::in_chroot) {
    notify { 'iptables in chroot':
      message => 'Iptables not refreshed, running in chroot',
    }
    $notify_iptables = []
    $notify_ip6tables = []
  }
  else {
    # On centos 7 firewalld and iptables-service confuse each other and you
    # end up with no firewall rules at all. Disable firewalld so that
    # iptables-service can be in charge.
    if ($::osfamily == 'RedHat') {
      $notify_iptables = Service['iptables']
      $notify_ip6tables = Service['ip6tables']

      if ($::operatingsystemmajrelease >= '7') {
        exec { 'stop-firewalld-if-running':
          command => '/usr/bin/systemctl stop firewalld',
          onlyif  => '/usr/bin/pgrep firewalld',
        }
        package { 'firewalld':
          ensure  => absent,
          require => Exec['stop-firewalld-if-running'],
          before  => Package['iptables'],
        }
      }
    } else {
      $notify_iptables = Service['iptables']
      $notify_ip6tables = Service['iptables']
    }
  }

  service { 'iptables':
    name       => $::iptables::params::service_name,
    require    => Package['iptables'],
    hasstatus  => $::iptables::params::service_has_status,
    status     => $::iptables::params::service_status_cmd,
    hasrestart => $::iptables::params::service_has_restart,
    enable     => true,
    ensure     => running,
  }

  if ($::osfamily == 'RedHat') {
    # NOTE(pabelanger): Centos-7 has a dedicated service for ip6tables. Aside
    # from the different service name, we keep the same settings as iptables.
    service { 'ip6tables':
      name       => $::iptables::params::service6_name,
      require    => Package['iptables'],
      hasstatus  => $::iptables::params::service_has_status,
      status     => $::iptables::params::service_status_cmd,
      hasrestart => $::iptables::params::service_has_restart,
      enable     => true,
      ensure     => running,
      subscribe  => File["${::iptables::params::rules_dir}/rules"],
    }
  }

  file { $::iptables::params::rules_dir:
    ensure  => directory,
    require => Package['iptables'],
  }

  # This file is not required on Red Hat distros... but it
  # won't hurt to softlink to it either
  file { "${::iptables::params::rules_dir}/rules":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('iptables/rules.erb'),
    require => [
      Package['iptables'],
      File[$::iptables::params::rules_dir],
    ],
    # When this file is updated, make sure the rules get reloaded.
    notify  => $notify_iptables,
  }

  file { $::iptables::params::ipv4_rules:
    ensure  => link,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    target  => "${::iptables::params::rules_dir}/rules",
    require => File["${::iptables::params::rules_dir}/rules"],
    notify  => $notify_iptables,
  }

  file { $::iptables::params::ipv6_rules:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('iptables/rules.v6.erb'),
    require => [
      Package['iptables'],
      File[$::iptables::params::rules_dir],
    ],
    # When this file is updated, make sure the rules get reloaded.
    notify  => $notify_ip6tables,
    replace => true,
  }
}
