
define iptables::hosts_allow (
  $port = undef,
  $ports = undef,
) {

  if $port == undef and $ports == undef {
    fail("You must pass port or ports to iptables::hosts_allow")
  }

  $pub = pick($port, $ports)
  $public_hosts_ports = flatten([$pub])

  concat::fragment { "iptables-4-hosts-${name}":
    target  => "${::iptables::params::rules_dir}/rules",
    content => template('iptables/rules4_hosts.erb'),
    order   => '110'
  }

  concat::fragment { "iptables-6-hosts-${name}":
    target  => $::iptables::params::ipv6_rules,
    content => template('iptables/rules6_hosts.erb'),
    order   => '110'
  }

}
