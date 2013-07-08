class team_dashboard {

  if ! defined(Package['build-essential'])      
  { package { 'build-essential':
    ensure => present } 
  }

  package {  ['git', 'libmysqlclient-dev', ]:
    ensure  => installed,
  }

  vcsrepo { "/vagrant/team_dashboard":
    ensure   => latest,
    owner    => vagrant,
    group    => vagrant,
    provider => git,
    require  => [ Package["git"] ],
    source   => "https://github.com/paulhamby/team_dashboard",
    revision => 'master',
  }

  file { "/vagrant/team_dashboard/config/database.yml":
    owner   => root,
    group   => root,
    source  => '/vagrant/puppet/modules/team_dashboard/files/database.yml',
    require => [ Vcsrepo['/vagrant/team_dashboard'] ],
  }

  exec { 'install-team_dashboard':
    path => '/usr/bin:/usr/sbin:/bin:/usr/local/rvm/bin',
    command => "bash -c 'source /usr/local/rvm/scripts/rvm && cd /vagrant/team_dashboard && bundle install && rake db:create && rake db:migrate && touch /vagrant/team_dashboard_installed'",
    creates => '/vagrant/team_dashboard_installed',
    require => [ File['/vagrant/team_dashboard/config/database.yml'] ],
  }

  file { "/etc/unicorn":
    ensure => directory,
    owner  => root,
    group  => root,
    require => [ Vcsrepo['/vagrant/team_dashboard'] ],
  }

  file { "/etc/unicorn/team_dashboard.conf":
    owner  => root,
    group  => root,
    source => '/vagrant/puppet/modules/team_dashboard/files/team_dashboard.conf',
    require => [ File['/etc/unicorn'] ],
  }

  file { "/etc/init.d/unicorn":
    owner   => root,
    group   => root,
    mode    => 755,
    source  => '/vagrant/puppet/modules/team_dashboard/files/unicorn.init',
    require => [ File['/etc/unicorn'] ],
  }

  service { "unicorn":
    name       => "unicorn",
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => [ File["/etc/init.d/unicorn"], Exec["install-team_dashboard"], ],
  }

}
