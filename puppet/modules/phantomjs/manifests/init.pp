class phantomjs($version = "1.9.1" ) {

    package { ["fontconfig", ]:
      ensure => installed,
    }

    if $::architecture == "amd64" or $::architecture == "x86_64" {
        $platid = "x86_64"
    } else {
        $platid = "i686"
    }

    $filename = "phantomjs-${version}-linux-${platid}.tar.bz2"
    $phantom_src_path = "/usr/local/src/phantomjs-${version}/"
    $phantom_bin_path = "/opt/phantomjs"

    file { $phantom_src_path : ensure => directory }

    exec { "download-${filename}" : 
        path => '/usr/bin:/usr/sbin:/bin',
        command => "wget https://phantomjs.googlecode.com/files/${filename} -O ${filename}",
        cwd => $phantom_src_path,
        creates => "${phantom_src_path}${filename}",
        require => File[$phantom_src_path]
    }
    
    exec { "extract-${filename}" :
        path => '/usr/bin:/usr/sbin:/bin',
        command     => "tar xvfj ${filename} -C /opt/; mv /opt/phantomjs-${version}-linux-${platid} $phantom_bin_path",
        creates     => "/opt/phantomjs/",
        cwd         => $phantom_src_path,
        require     => Exec["download-${filename}"],
    }

    file { "/usr/local/bin/phantomjs" :
        target => "${phantom_bin_path}/bin/phantomjs",
        ensure => link,
        require     => Exec["extract-${filename}"],
    }
    
    file { "/usr/bin/phantomjs" :
        target => "${phantom_bin_path}/bin/phantomjs",
        ensure => link,
        require     => Exec["extract-${filename}"],
    }
    
    exec { "nuke-old-version-on-upgrade" :
        path => '/usr/bin:/usr/sbin:/bin',
        command => "rm -Rf /opt/phantomjs /usr/local/bin/phantomjs",
        unless => "test -f /usr/local/bin/phantomjs && /usr/local/bin/phantomjs --version | grep ${version}",
        before => Exec["download-${filename}"]
    }

}
