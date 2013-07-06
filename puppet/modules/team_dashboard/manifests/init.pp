class team_dashboard {

  package { 'git':
    ensure => installed,
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

#cd team_dashboard
#bundle install
#cp config/database.example.yml config/database.yml
#rake db:create && rake db:migrate

  exec { 'install-team_dashboard':
    #path => '/usr/bin:/usr/sbin:/bin:/usr/local/rvm/bin/rvm',
    command => "bash -c 'cd /vagrant/team_dashboard && bundle install && rake db:create && rake db:migrate && touch /tmp/team_dashboard_installed'",
    creates => '/vagrant/team_dashboard_installed',
    require => [ Vcsrepo['/vagrant/team_dashboard'] ],
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
    source => 'puppet:///modules/team_dashboard/team_dashboard.conf',
    require => [ File['/etc/unicorn'] ],
  }

  file { "/etc/init.d/unicorn":
    owner   => root,
    group   => root,
    mode    => 755,
    source  => 'puppet:///modules/team_dashboard/unicorn.init',
    require => [ File['/etc/unicorn'] ],
  }
}
