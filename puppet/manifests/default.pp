Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

class system-update {

  exec { 'apt-get update':
    command => 'apt-get update',
  }

}

class rvm-install {

  include rvm

  rvm_system_ruby {
    'ruby-1.9.3-p429':
      ensure => 'present',
      default_use => true;
  }
}

include system-update
include mysql
include rvm-install
