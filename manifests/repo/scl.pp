class profile::repo::scl {

  case $::operatingsystem {
    'centos': {
      package { 'centos-release-scl':
        ensure => installed,
      }
    } # CentOS

    default: {
      fail("'Your plattform ${::operatingsystem} is not supported.'")
    }
  } # case

}

