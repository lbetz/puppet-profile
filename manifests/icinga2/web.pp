class profile::icinga2::web(
  String                                 $db_pass,
  String                                 $api_pass,
  String                                 $ido_db_pass,
  Enum['mysql', 'pgsql']                 $ido_db_type  = 'mysql',
  Stdlib::Host                           $ido_db_host  = '127.0.0.1',
  Optional[Stdlib::Port::Unprivileged]   $ido_db_port  = undef,
  String                                 $ido_db_name  = 'icinga2',
  String                                 $ido_db_user  = 'icinga2',
  String                                 $api_user     = 'icingaweb2',
  Enum['apache', 'nginx']                $server_type  = 'apache',
  Enum['mysql', 'pgsql']                 $db_type      = 'mysql',
  Stdlib::Host                           $db_host      = '127.0.0.1',
  Optional[Stdlib::Port::Unprivileged]   $db_port      = undef,
  String                                 $db_name      = 'icingaweb2',
  String                                 $db_user      = 'icingaweb2',
) {

  unless $ido_db_port {
    $_ido_db_port = $ido_db_type ? {
      'pgsql' => 5432,
      default => 3306,
    }
  } else {
    $_ido_db_port = $ido_db_port
  }

  unless $db_port {
    $_db_port = $db_type ? {
      'pgsql' => 5432,
      default => 3306,
    }
  } else {
    $_db_port = $db_port
  }

  case $::osfamily {
    'redhat': {
      require ::profile::repo::icinga
      require ::profile::repo::scl

      $php_globals    = {
        php_version => 'rh-php71',
        rhscl_mode  => 'rhscl',
      }
      $php_extensions = {
        mbstring => {},
        json     => {},
        ldap     => {},
        gd       => {},
        xml      => {},
        intl     => {},
        mysqlnd  => {},
        pgsql    => {},
      }
    } # RedHat

    'debian': {
      require ::profile::repo::icinga

      $php_globals    = {}
      $php_extensions = {
        mbstring => {},
        json     => {},
        ldap     => {},
        gd       => {},
        xml      => {},
        intl     => {},
        mysql    => {},
        pgsql    => {},
      }
    } # Debian

    default: {
      fail("'Your operatingsystem ${::operatingsystem} is not supported.'")
    }
  }

  #
  # PHP
  #
  class { '::php::globals':
    * => $php_globals,
  }

  class { '::php':
    ensure        => installed,
    manage_repos  => false,
    apache_config => false,
    fpm           => true,
    extensions    => $php_extensions,
    dev           => false,
    composer      => false,
    pear          => false,
    phpunit       => false,
    require       => Class['::php::globals'],
  }

  if $server_type == 'nginx' {
    #
    # Nginx
    #
    $manage_package = true

    Class['nginx']
      -> Class['icingaweb2']

    class { '::nginx':
      manage_repo  => false,
      server_purge => true,
      confd_purge  => true,
    }

    $web_conf_user = $::nginx::daemon_user

    nginx::resource::server { 'icingaweb2':
      server_name          => [ 'localhost' ],
      ssl                  => false,
      index_files          => [],
      use_default_location => false,
    }

    nginx::resource::location { 'icingaweb2':
      location       => '~ ^/icingaweb2(.+)?',
      location_alias => '/usr/share/icingaweb2/public',
      try_files      => ['$1', '$uri', '$uri/', '/icingaweb2/index.php$is_args$args'],
      index_files    => ['index.php'],
      server         => 'icingaweb2',
      ssl            => false,
    }
    
    nginx::resource::location { 'icingaweb2_index':
      location       => '~ ^/icingaweb2/index\.php(.*)$',
      server         => 'icingaweb2',
      ssl            => false,
      index_files    => [],
      fastcgi        => '127.0.0.1:9000',
      fastcgi_index  => 'index.php',
      fastcgi_param  => {
        'SCRIPT_FILENAME'         => '/usr/share/icingaweb2/public/index.php',
        'ICINGAWEB_CONFIGDIR' => '/etc/icingaweb2',
        'REMOTE_USER'         => '$remote_user',
      },
    }
  } else {
    #
    # Apache
    #
    $manage_package = false

    Package['icingaweb2']
      -> Class['apache']

    package { 'icingaweb2':
      ensure => installed,
    }

    class { '::apache':
      default_mods  => false,
      default_vhost => false,
      mpm_module    => 'worker',
    }

    apache::listen { '80': }
  
    $web_conf_user = $::apache::user

    include ::apache::mod::alias
    include ::apache::mod::status
    include ::apache::mod::dir
    include ::apache::mod::env
    include ::apache::mod::rewrite
    include ::apache::mod::proxy
    include ::apache::mod::proxy_fcgi
  
    apache::custom_config { 'icingaweb2':
      ensure        => present,
      source        => 'puppet:///modules/icingaweb2/examples/apache2/for-mod_proxy_fcgi.conf',
      verify_config => false,
      priority      => false,
    }
  }

  #
  # Icinga Web 2
  #
  if $db_host in [ '127.0.0.1', '::1' ] {
    if $db_type == 'pgsql' {
      fail("'pgsql for icingaweb2 is currently not supported'")
    } else {
      include ::mysql::server
  
      mysql::db { $db_name:
        host     => $db_host,
        user     => $db_user,
        password => $db_pass,
        grant    => ['ALL'],
        before   => Class['icingaweb2'],
      }
    }
  }  

  class { 'icingaweb2':
    db_type        => $db_type,
    db_host        => $db_host,
    db_port        => $_db_port,
    db_name        => $db_name,
    db_username    => $db_user,
    db_password    => $db_pass,
    import_schema  => true,
    config_backend => 'db',
    conf_user      => $web_conf_user,
    manage_package => $manage_package,
  }

  ::icinga2::object::apiuser { $api_user:
    ensure      => present,
    password    => $api_pass,
    permissions => [ 'status/query', 'actions/*', 'objects/modify/*', 'objects/query/*' ],
    target      => '/etc/icinga2/conf.d/api-users.conf',
  }

  class { '::icingaweb2::module::monitoring':
    ido_type          => $ido_db_type,
    ido_host          => $ido_db_host,
    ido_port          => $_ido_db_port,
    ido_db_name       => $ido_db_name,
    ido_db_username   => $ido_db_user,
    ido_db_password   => $ido_db_pass,
    commandtransports => {
      'icinga2' => {
        transport => 'api',
        username  => $api_user,
        password  => $api_pass,
      }
    }
  }

}
