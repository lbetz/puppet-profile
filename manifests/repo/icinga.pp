class profile::repo::icinga {

  case $::osfamily {

    'redhat': {
      yumrepo { 'ICINGA-release':
        descr => 'ICINGA (stable release for epel)',
        baseurl => 'http://packages.icinga.org/epel/$releasever/release/',
        failovermethod => 'priority',
        enabled => '1',
        gpgcheck => '1',
        gpgkey => 'http://packages.icinga.org/icinga.key',
      }
    } # RedHat

    'debian': {
      Apt::Source['icinga-stable-release']
        -> Class['Apt::Update']
        -> Package <| tag == 'icinga2' |>
      case $::operatingsystem {
        'debian': {
          include ::apt
          apt::source { 'icinga-stable-release':
            location => 'http://packages.icinga.com/debian',
            release  => "icinga-${::lsbdistcodename}",
            repos    => 'main',
            key      => {
              id     => 'F51A91A5EE001AA5D77D53C4C6E319C334410682',
              source => 'http://packages.icinga.com/icinga.key',
            },
          }
        }
        'ubuntu': {
          include ::apt
          apt::source { 'icinga-stable-release':
            location => 'http://packages.icinga.com/ubuntu',
            release  => "icinga-${::lsbdistcodename}",
            repos    => 'main',
            key      => {
              id     => 'F51A91A5EE001AA5D77D53C4C6E319C334410682',
              source => 'http://packages.icinga.com/icinga.key',
            };
          }
        }
        default: {
          fail('Your plattform is not supported to manage a repository.')
        }
      }
      contain ::apt::update
    } # Debian

    default: {
      fail("'Your operatingsystem ${::operatingsystem} is not supported.'")
    }

   } # case

}
