# Define iptables::udp_allow
# Allow a udp port to listen on v4 and v6
define iptables::udp_allow (
  $port = undef,
  $ports = undef,
) {

  if $port == undef and $ports == undef {
    fail('You must pass port or ports to iptables::udp_allow')
  }

  $pub = pick($port, $ports)
  $public_udp_ports = flatten([$pub])

  concat::fragment { "iptables-4-udp-${name}":
    target  => "${::iptables::params::rules_dir}/rules",
    content => template('iptables/rules4_udp.erb'),
    order   => '110'
  }

  concat::fragment { "iptables-6-udp-${name}":
    target  => $::iptables::params::ipv6_rules,
    content => template('iptables/rules6_udp.erb'),
    order   => '110'
  }

}
