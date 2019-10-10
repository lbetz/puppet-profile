class profile::icinga2::web::director(
  String                                 $db_pass,
  String                                 $api_user,
  String                                 $api_pass,
  Stdlib::Host                           $api_endpoint = $::fqdn,
  String                                 $db_user      = 'director',
  String                                 $db_name      = 'director',
  Stdlib::Host                           $db_host      = '127.0.0.1',
  Optional[Stdlib::Port::Unprivileged]   $db_port      = undef,  
) {

  include ::icingaweb2::module::ipl
  include ::icingaweb2::module::incubator
  include ::icingaweb2::module::reactbundle

  mysql::db { 'director':
    user      => $db_user,
    password  => $db_pass,
    host      => $db_host,
    charset   => 'utf8',
    grant     => [ 'ALL' ]
  }

  class {'icingaweb2::module::director':
    db_host       => $db_host,
    db_name       => $db_name,
    db_username   => $db_user,
    db_password   => $db_pass,
    import_schema => true,
    kickstart     => true,
    endpoint      => $api_endpoint,
    api_username  => $api_user,
    api_password  => $api_pass,
  }

}
