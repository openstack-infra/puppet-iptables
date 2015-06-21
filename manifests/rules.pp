
define iptables::hosts_allow (
  $rules4 = undef,
  $rules6 = undef,
) {

  if $rules4 == undef and $rules6 == undef {
    fail("You must pass rules4 or rules6 to iptables::rules")
  }

  if $rules4 != undef {

    concat::fragment { "iptables-4-hosts-${name}":
      target  => "${::iptables::params::rules_dir}/rules",
      content => template('iptables/rules4_hosts.erb'),
      order   => '110'
    }
  }

  if $rules6 != undef {
    concat::fragment { "iptables-6-hosts-${name}":
      target  => $::iptables::params::ipv6_rules,
      content => template('iptables/rules6_hosts.erb'),
      order   => '110'
    }
  }

}
