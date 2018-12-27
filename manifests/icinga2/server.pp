class profile::icinga2::server {

  include ::profile::icinga2

  Profile::Icinga2::Ido::Feature <<| title == $::ipaddress_eth1 |>>
}
