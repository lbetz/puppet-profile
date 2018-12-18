class profile::icinga2::api(
  Stdlib::Host     $ca_host,
) {

  if $ca_host =~ /localhost/ {
    include ::icinga2::pki::ca

    class { '::icinga2::feature::api':
      pki             => 'none',
      accept_commands => true,
    }
  } else {
    fail('ca_host on remote host is not implemented')
  }

}
