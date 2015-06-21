
define iptables::tcp_allow (
  $port = undef,
  $ports = undef,
) {

  if $port == undef and $ports == undef {
    fail('You must pass port or ports to iptables::tcp_allow')
  }

  $pub = pick($port, $ports)
  $public_tcp_ports = flatten([$pub])

  concat::fragment { "iptables-4-tcp-${name}":
    target  => "${::iptables::params::rules_dir}/rules",
    content => template('iptables/rules4_tcp.erb'),
    order   => '110'
  }

  concat::fragment { "iptables-6-tcp-${name}":
    target  => $::iptables::params::ipv6_rules,
    content => template('iptables/rules6_tcp.erb'),
    order   => '110'
  }

}
