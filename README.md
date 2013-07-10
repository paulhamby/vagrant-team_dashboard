#Vagrant files for team_dashboard  

###Prerequisites:  

Install virtualbox (https://www.virtualbox.org).  
Install vagrant (http://www.vagrantup.com).  
Install git (For Windows install git with ssh from http://git-scm.com/downloads).  


    git clone https://github.com/paulhamby/vagrant-team_dashboard.git  
    mkdir team_dashboard  
    cp -a vagrant-team_dashboard/* team_dashboard  
    cd team_dashboard  
    vagrant up  

##Puppet Components
MySQL installed with https://github.com/example42/puppet-mysql  
RVM installed with https://github.com/blt04/puppet-rvm  
VCSRepo installed with https://github.com/puppetlabs/puppetlabs-vcsrepo  
PhantomJS installed with https://github.com/brhelwig/puppet-phantomjs
