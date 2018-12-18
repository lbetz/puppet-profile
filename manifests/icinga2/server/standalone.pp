class profile::icinga2::server::standalone {

  $ticket_salt = lookup('profile::icinga2::ticket_salt')

  class { '::profile::icinga2':
    confd     => true,
    constants => { 'TicketSalt' => $ticket_salt } 
  }  
  
  class { '::profile::icinga2::api':
    ca_host => 'localhost',
  }

  include ::profile::icinga2::ido
  
  class { '::profile::icinga2::web':
    ido_db_type  => $::profile::icinga2::ido::db_type,
    ido_db_host  => $::profile::icinga2::ido::db_host,
    ido_db_port  => $::profile::icinga2::ido::db_port,
    ido_db_name  => $::profile::icinga2::ido::db_dbame,
    ido_db_user  => $::profile::icinga2::ido::db_user,
    ido_db_pass  => $::profile::icinga2::ido::db_pass,
  }

}
