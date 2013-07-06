#!/usr/bin/env bash

MYSQL_PASSWORD="password"

apt-get update
sudo apt-get -y install debconf-utils
  echo "mysql-server-5.5 mysql-server/root_password password $MYSQL_PASSWORD" | debconf-set-selections
  echo "mysql-server-5.5 mysql-server/root_password_again password $MYSQL_PASSWORD" | debconf-set-selections
  apt-get install -y mysql-server curl git libxml2-dev libxslt-dev libmysqlclient-dev build-essential
#sign your soul away to rvm.io...
curl -L https://get.rvm.io | bash -s stable --ruby=1.9.3-p429
source /usr/local/rvm/scripts/rvm

cd /vagrant
git clone https://github.com/paulhamby/team_dashboard
cd team_dashboard
gem install bundler
bundle install
cp config/database.example.yml config/database.yml
sed -i "s/password:/password: $MYSQL_PASSWORD/" config/database.yml
rake db:create && rake db:migrate

chown -R vagrant:vagrant /vagrant/team_dashboard

mkdir /etc/unicorn
cat > "/etc/unicorn/team_dashboard.conf" << 'EOF'
RAILS_USER=vagrant
RAILS_ENV=development
RAILS_DIR=/vagrant/team_dashboard
UNICORN_CONFIG=$RAILS_DIR/config/unicorn.rb
UNICORN_PID=$RAILS_DIR/tmp/pids/unicorn.pid
EOF

cat > "/etc/init.d/unicorn" << 'EOF'
#!/bin/bash
### BEGIN INIT INFO
# Provides:          unicorn
# Required-Start:    $local_fs $remote_fs
# Required-Stop:     $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: unicorn
# Description:       Rails http server
### END INIT INFO

CONFIGPATH=/etc/unicorn
CONFIG_VARS='RAILS_USER RAILS_ENV RAILS_DIR UNICORN_CONFIG UNICORN_PID'

check_pidfile() {
    PIDFILE=$1
    PID=0
    if [[ -f "$PIDFILE" ]]; then
        PID_IN_FILE=`cat $PIDFILE`
        [[ -f "/proc/$PID_IN_FILE/cmdline" ]] && [[ "`grep -c '^unicorn' /proc/$PID_IN_FILE/cmdline`" = "1" ]] && PID=$PID_IN_FILE
    fi
    echo $PID
}

[[ -d "$CONFIGPATH" ]] || { echo "Cannot find $CONFIGPATH"; exit 3; };

if [[ -n "$2" ]]; then
    ACTION=$2
    SITES=$1
else
    ACTION=$1
    SITES=`cd $CONFIGPATH && ls *conf | sed -e 's%.conf$%%'`
fi

for SITE in $SITES; do
    unset $CONFIG_VARS
    . $CONFIGPATH/$SITE.conf
    for CONFIG_VAR in $CONFIG_VARS; do
        [[ -n "${!CONFIG_VAR}" ]] || { echo "Variable $CONFIG_VAR is not set in $CONFIGPATH/$SITE.conf"; exit 3; }
    done
done

case "$ACTION" in
    start)
        for SITE in $SITES; do
            unset $CONFIG_VARS
            . $CONFIGPATH/$SITE.conf
            PID=`check_pidfile $UNICORN_PID`
            if [[ "$PID" = "0" ]]; then
                echo -n "Starting $SITE ..."
                CMD="export rvm_trust_rvmrcs_flag=1; cd $RAILS_DIR && bundle exec unicorn -c $UNICORN_CONFIG -E $RAILS_ENV -D"
                if [ "$RAILS_USER" != "`whoami`" ]; then
                    su - $RAILS_USER -c "$CMD"
                else
                    bash -l -c "$CMD"
                fi
            else
                echo "$SITE is already running (PID $PID)"
            fi
        done
        ;;

    stop)
        for SITE in $SITES; do
            unset $CONFIG_VARS
            . $CONFIGPATH/$SITE.conf
            echo -n "Stopping $SITE ..."
            PID=`check_pidfile $UNICORN_PID`
            if [[ "$PID" != "0" ]]; then
                COUNT=0
                while [ $COUNT -lt 10 -a "`check_pidfile $UNICORN_PID`" != "0" ]; do
                    kill $PID
                    sleep 1
                done
                [[ $COUNT -eq 10 ]] && kill -9 $PID
                echo "done"
            else
                echo "$SITE is not running"
            fi
        done
        ;;

    status)
        EXIT_CODE=0
        for SITE in $SITES; do
            unset $CONFIG_VARS
            . $CONFIGPATH/$SITE.conf
            PID=`check_pidfile $UNICORN_PID`
            echo -n "$SITE: "
            if [[ "$PID" != "0" ]]; then
                echo "running (PID $PID)"
            else
                echo "not running"
                EXIT_CODE=3
            fi
        done
        exit $EXIT_CODE
        ;;

    reload)
        EXIT_CODE=0
        for SITE in $SITES; do
            unset $CONFIG_VARS
            . $CONFIGPATH/$SITE.conf
            echo -n "Reloading $SITE ... "
            PID=`check_pidfile $UNICORN_PID`
            if [[ "$PID" != "0" ]]; then
                kill -USR2 $PID
		if [[ "$?" = "0" ]]; then
                    echo "done"
                else
                    echo "failed"
                    EXIT_CODE=3
                fi
            else
                echo "not running! Will start instead"
                $0 $SITE start
            fi
        done
        exit $EXIT_CODE
        ;;

    restart)
        for SITE in $SITES; do
            $0 $SITE stop
            sleep 2
            $0 $SITE start
        done
        ;;

    *)
        echo "Usage: $0 [`echo $SITES | sed -e 's# #|#g'`] {start|stop|restart|status|reload}"
        exit 3
esac

EOF

chmod 755 /etc/init.d/unicorn

/etc/init.d/unicorn start

echo "Team_dashboard should be available at http://127.0.0.1:4567"
