# OpenStack IPTables Module

This module installs and configures IPTables

Works on RedHat and Debian systems.

It has, for now, hardcoded openstack-infra addresses.

The typical entry point to this module is through the openstack_project::server class

class { 'openstack_project::server':
  sysadmins => ['derp'],
  iptables_public_tcp_ports => [4444, 2121],
}


It is also possible to 'side load' iptables rules. The defined types below apply both ipv4 and ipv6 rules. These defines can be applied multiple times.

iptables::tcp_allow { 'allow port 80 conns':
  port => 80,
}

iptables::tcp_allow { 'allow port 90 and 100 conns':
  ports => [90, 100],
}

iptables::udp_allow { 'allow port 80 conns':
  port => 80,
}

iptables::udp_allow { 'allow port 90 and 100 conns':
  ports => [90, 100],
}

iptables::rules { 'Allow statsd':
  rules4 => ['-m udp -p udp -s 127.0.0.1 --dport 8125 -j ACCEPT'],
  rules6 => ['-m udp -p udp -s ::1 --dport 8125 -j ACCEPT'],
}
