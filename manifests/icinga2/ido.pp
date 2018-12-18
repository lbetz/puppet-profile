class profile::icinga2::ido(
  String                                 $db_pass,
  Enum['mysql','pgsql']                  $db_type = 'mysql',
  Stdlib::Host                           $db_host = '127.0.0.1',
  Optional[Stdlib::Port::Unprivileged]   $db_port = undef,
  String                                 $db_name = 'icinga2',
  String                                 $db_user = 'icinga2',
) {

  assert_private()

  require ::profile::icinga2

  if $db_host in [ '127.0.0.1', '::1' ] {
    if $db_type == 'pgsql' {
      include ::postgresql::server

      postgresql::server::db { $db_name:
        user     => $db_user,
        password => postgresql_password($db_user, $db_pass),
        before   => Class['icinga2::feature::idopgsql'],
      }
    } else {
      include ::mysql::server

      mysql::db { $db_name:
        host     => $db_host,
        user     => $db_user,
        password => $db_pass,
        grant    => ['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'DROP', 'CREATE VIEW', 'CREATE', 'ALTER', 'INDEX', 'EXECUTE'],
        before   => Class['icinga2::feature::idomysql'],
      }
    }
  }

  if $::kernel == 'linux' {
    if $::osfamily == 'debian' {
      ensure_resources('file', { '/etc/dbconfig-common' => { ensure => directory } })
      file { "/etc/dbconfig-common/icinga2-ido-${db_type}.conf":
        ensure  => file,
        content => "dbc_install='false'\ndbc_upgrade='false'\ndbc_remove='false'\n",
        mode    => '0600',
        before  => Package["icinga2-ido-${db_type}"],
      }
    } # Debian
    package { "icinga2-ido-${db_type}":
      ensure => installed,
      before => Class["icinga2::feature::ido${db_type}"],
    }
  } # Linux

  class { "::icinga2::feature::ido${db_type}":
    host          => $db_host,
    port          => $db_port,
    database      => $db_name,
    user          => $db_user,
    password      => $db_pass,
    import_schema => true,
  }

}
