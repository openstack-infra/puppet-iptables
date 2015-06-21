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
class iptables(
  $rules4 = [],
  $rules6 = [],
  $public_tcp_ports = [],
  $public_udp_ports = []
) {

  include iptables::params

  package { 'iptables':
    ensure => present,
    name   => $::iptables::params::package_name,
  }

  if ($::in_chroot) {
    notify { 'iptables in chroot':
      message => 'Iptables not refreshed, running in chroot',
    }
    $notify_iptables = []
  }
  else {
    service { 'iptables':
      name       => $::iptables::params::service_name,
      require    => Package['iptables'],
      hasstatus  => $::iptables::params::service_has_status,
      status     => $::iptables::params::service_status_cmd,
      hasrestart => $::iptables::params::service_has_restart,
      enable     => true,
    }
    $notify_iptables = Service['iptables']
  }

  file { $::iptables::params::rules_dir:
    ensure     => directory,
    require    => Package['iptables'],
  }

  # This file is not required on Red Hat distros... but it
  # won't hurt to softlink to it either
  # build it up with concat
  # 0xx Headers
  # 1xx TCP
  # 2xx UDP
  # 3xx HOSTS
  # 9xx Footers
  concat { "${::iptables::params::rules_dir}/rules":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    require => [
      Package['iptables'],
      File[$::iptables::params::rules_dir],
    ],
    # When this file is updated, make sure the rules get reloaded.
    notify  => $notify_iptables,
  }


  concat::fragment { 'iptables-4-header':
    target  => "${::iptables::params::rules_dir}/rules",
    content => template('iptables/rules4_header.erb'),
    order   => '01'
  }

  concat::fragment { 'iptables-4-tcp':
    target  => "${::iptables::params::rules_dir}/rules",
    content => template('iptables/rules4_tcp.erb'),
    order   => '100'
  }

  concat::fragment { 'iptables-4-udp':
    target  => "${::iptables::params::rules_dir}/rules",
    content => template('iptables/rules4_udp.erb'),
    order   => '200'
  }

  concat::fragment { 'iptables-4-raw':
    target  => "${::iptables::params::rules_dir}/rules",
    content => template('iptables/rules4_raw.erb'),
    order   => '300'
  }

  concat::fragment { 'iptables-4-footer':
    target  => "${::iptables::params::rules_dir}/rules",
    content => template('iptables/rules4_footer.erb'),
    order   => '999'
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

  # build it up with concat
  # 0xx Headers
  # 1xx TCP
  # 2xx UDP
  # 3xx HOSTS
  # 9xx Footers
  concat { $::iptables::params::ipv6_rules:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    require => [
      Package['iptables'],
      File[$::iptables::params::rules_dir],
    ],
    # When this file is updated, make sure the rules get reloaded.
    notify  => $notify_iptables,
  }

  concat::fragment { 'iptables-6-header':
    target  => $::iptables::params::ipv6_rules,
    content => template('iptables/rules6_header.erb'),
    order   => '01'
  }

  concat::fragment { 'iptables-6-tcp':
    target  => $::iptables::params::ipv6_rules,
    content => template('iptables/rules6_tcp.erb'),
    order   => '100'
  }

  concat::fragment { 'iptables-6-udp':
    target  => $::iptables::params::ipv6_rules,
    content => template('iptables/rules6_udp.erb'),
    order   => '200'
  }

  concat::fragment { 'iptables-6-raw':
    target  => $::iptables::params::ipv6_rules,
    content => template('iptables/rules6_raw.erb'),
    order   => '300'
  }

  concat::fragment { 'iptables-6-footer':
    target  => $::iptables::params::ipv6_rules,
    content => template('iptables/rules6_footer.erb'),
    order   => '999'
  }

}
