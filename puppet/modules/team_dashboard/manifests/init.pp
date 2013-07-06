class team_dashboard {

  package { 'git':
    ensure => installed,
  }

  vcsrepo { "/vagrant/team_dashboard/team_dashboard":
    ensure   => latest,
    owner    => vagrant,
    group    => vagrant,
    provider => git,
    require  => [ Package["git"] ],
    source   => "https://github.com/paulhamby/team_dashboard",
    revision => 'master',
  }
}
