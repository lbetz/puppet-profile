class profile::icinga2(
  Enum['running', 'stopped']     $ensure          = 'running',
  Boolean                        $enable          = true,
  Variant[Boolean, String]       $confd           = false,
  Optional[Hash]                 $constants       = undef,
  Optional[String]               $ticket_salt     = undef,
  Optional[String]               $pub_rsa_key     = undef,
  Optional[String]               $private_rsa_key = undef,
) {

  assert_private()

  case $::kernel {
    'linux': {
      require ::profile::repo::icinga

      $manage_package = false
      $manage_repo    = false

      case $::osfamily {
        'redhat': {
          unless $::operatingsystem in [ 'redhat', 'centos' ] and $::operatingsystemmajrelease in [ '7' ] {
            fail("'Your operatingssystem ${::operatingsystem} in release ${::operatingsystemmajrelease} is not supported'")
          }

          require ::profile::repo::epel
    
          $icinga_user    = 'icinga'
          $icinga_group   = 'icinga'
          $icinga_home    = '/var/spool/icinga2'
     
          package { [ 'nagios-plugins-all', 'icinga2' ]:
            ensure => installed,
            before => User['icinga'],
          }

          user { 'icinga':
            ensure => present,
            shell  => '/bin/bash',
            groups => [ 'nagios' ],
            before => Class['icinga2'],
          }
        } # RedHat
    
        'debian': {
          unless $::operatingsystem in [ 'debian', 'ubuntu' ] and $::os['distro']['codename'] in [ 'stretch', 'bionic' ] {
            fail("'Your operatingssystem ${::operatingsystem} in release ${::operatingsystemmajrelease} is not supported'")
          }
    
          $icinga_user    = 'nagios'
          $icinga_group   = 'nagios'
          $icinga_home    = '/var/lib/nagios'

          package { ['monitoring-plugins', 'icinga2']:
            ensure => installed,
            before => User['nagios'],
          }

          user { 'nagios':
            ensure => present,
            shell  => '/bin/bash',
            before => Class['icinga2'],
          }
        } # Debian

        default: {
          fail("'Your operatingssystem ${::operatingsystem} in release ${::operatingsystemmajrelease} is not supported'")
        }
      }

      if $pub_rsa_key {
        ssh_authorized_key { "${icinga_user}@server.localdomain":
          ensure  => present,
          user    => $icinga_user,
          key     => $pub_rsa_key,
          type    => 'ssh-rsa',
        }
      } # pubkey

      if $private_rsa_key {
        file { 
          default:
            ensure => file,
            owner  => $icinga_user,
            group  => $icinga_group;
          "${icinga_home}/.ssh":
            ensure => directory,
            mode   => '0700';
          "${icinga_home}/.ssh/id_rsa":
            mode    => '0600',
            content => $private_rsa_key;
          "${icinga_home}/.ssh/config":
            content => "Host *\n  StrictHostKeyChecking no\n";
        }
      } # privkey
    } # Linux
    
    'windows': {
      $manage_package = true
      $manage_repo    = false
    }

    default: {
      fail("'Your operatingssystem ${::operatingsystem} in release ${::operatingsystemmajrelease} is not supported'")
    }
  }

  class { 'icinga2':
    ensure         => $ensure,
    enable         => $enable,
    constants      => $constants,
    confd          => $confd,
    manage_package => $manage_package,
    manage_repo    => $manage_repo,
  }

}
