define profile::icinga2::ido::feature(
  Enum['mysql','pgsql']                  $db_type,
  Hash                                   $config = {},
) {

  assert_private()

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

class profile::icinga2::ido(
  String                                 $db_pass,
  Stdlib::Host                           $icinga_host = 'localhost',
  Enum['mysql','pgsql']                  $db_type     = 'mysql',
  String                                 $db_host     = 'localhost',
  Optional[Stdlib::Port::Unprivileged]   $db_port     = undef,
  String                                 $db_name     = 'icinga2',
  String                                 $db_user     = 'icinga2',
) {

  if $icinga_host =~ /^(localhost|::|127\.)/ {
    $_db_host = 'localhost'

    profile::icinga2::ido::feature { $icinga_host:
      db_type => $db_type,
      db_host => $icinga_host,
      db_name => $db_name,
      db_user => $db_user,
      db_pass => $db_pass,
      require => Mysql::Db[$db_name],
    }
  } else {
    $_db_host = $instance

    @@profile::icinga2::ido::feature { $icinga_host:
      db_type => $db_type,
      db_host => $db_host,
      db_port => $db_port,
      db_name => $db_name,
      db_user => $db_user,
      db_pass => $db_pass,
    }
  }

  mysql::db { $db_name:
    host     => $_db_host,
    user     => $db_user,
    password => $db_pass,
    grant    => ['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'DROP', 'CREATE VIEW', 'CREATE', 'ALTER', 'INDEX', 'EXECUTE'],
  }
}
