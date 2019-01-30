FROM ubuntu:14.04

MAINTAINER Jeroen Twilt <jt@staedion.nl>

RUN apt-get update \
    && apt-get -y install git wget \
    && ZENOSSHOME="/home/zenoss" \
    && DOWNDIR="/tmp" \
    && ZVER="425" \
    && ZVERb="4.2.5" \
    && ZVERc="2108" \
    && DVER="03c" \
    && echo $(grep $(hostname) /etc/hosts | cut -f1) zenoss4-core >> /etc/hosts && hostname zenoss4-core && echo "zenoss4-core" > /etc/hostname \
    && export ZENHOME=/usr/local/zenoss \
    && export PYTHONPATH=/usr/local/zenoss/lib/python \
    && export PATH=/usr/local/zenoss/bin:$PATH \
    && export INSTANCE_HOME=$ZENHOME \
    && useradd -m -U -s /bin/bash zenoss \
    && mkdir $ZENOSSHOME/zenoss$ZVER-srpm_install \
    && mkdir $ZENHOME && chown -cR zenoss:zenoss $ZENHOME \
    && apt-get -y install software-properties-common python-software-properties libpangocairo-1.0-0 libx11-xcb1 libxcomposite1 libxcursor1 libxdamage1 libxi6 libxtst6 libnss3 libcups2 libxss1 libxrandr2 libgconf2-4 libasound2 libatk1.0-0 libgtk-3-0 libxslt-dev snmp build-essential rrdtool libmysqlclient-dev nagios-plugins erlang subversion autoconf swig unzip zip g++ libssl-dev maven libmaven-compiler-plugin-java build-essential \
    && echo | add-apt-repository ppa:webupd8team/java && sleep 1 && apt-get update \
    && echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections \
    && apt-get -y install libxml2-dev libxslt1-dev libldap2-dev libsasl2-dev oracle-java8-installer python-twisted python-gnutls python-twisted-web python-samba libsnmp-base snmp-mibs-downloader bc rpm2cpio memcached libncurses5 libncurses5-dev libreadline6-dev libreadline6 librrd-dev python-setuptools python-dev erlang-nox redis-server \
    && apt-get -f install \
    && /etc/init.d/memcached start && sleep 2 \
    && /etc/init.d/redis-server start && sleep 2 \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install mysql-server mysql-client mysql-common \
    && apt-get -f install \
    && wget -N https://sourceforge.net/projects/zenossforubuntu/files/zenoss-core-425-2108_03c_amd64.deb -P $DOWNDIR/ \
    && dpkg -i $DOWNDIR/zenoss-core-425-2108_03c_amd64.deb \
    && chown -R zenoss:zenoss $ZENHOME && chown -R zenoss:zenoss $ZENOSSHOME \
    && /etc/init.d/mysql start && sleep 2 \
    && MYSQLUSER="root" \
    && mysql -u$MYSQLUSER -e "create database zenoss_zep" \
    && mysql -u$MYSQLUSER -e "create database zodb" \
    && mysql -u$MYSQLUSER -e "create database zodb_session" \
    && echo && echo "...The 1305 MySQL import error below is safe to ignore" \
    && mysql -u$MYSQLUSER zenoss_zep < $ZENOSSHOME/zenoss_zep.sql
    
RUN ZENOSSHOME="/home/zenoss" \
    && DOWNDIR="/tmp" \
    && ZVER="425" \
    && ZVERb="4.2.5" \
    && ZVERc="2108" \
    && DVER="03c" \
    && export ZENHOME=/usr/local/zenoss \
    && export PYTHONPATH=/usr/local/zenoss/lib/python \
    && export PATH=/usr/local/zenoss/bin:$PATH \
    && export INSTANCE_HOME=$ZENHOME \
    && MYSQLUSER="root" \
    && mysql -u$MYSQLUSER zodb < $ZENOSSHOME/zodb.sql \
    && mysql -u$MYSQLUSER zodb_session < $ZENOSSHOME/zodb_session.sql \
    && mysql -u$MYSQLUSER -e "CREATE USER 'zenoss'@'localhost' IDENTIFIED BY  'zenoss';" \
    && mysql -u$MYSQLUSER -e "GRANT REPLICATION SLAVE ON *.* TO 'zenoss'@'localhost' IDENTIFIED BY PASSWORD '*3715D7F2B0C1D26D72357829DF94B81731174B8C';" \
    && mysql -u$MYSQLUSER -e "GRANT ALL PRIVILEGES ON zodb.* TO 'zenoss'@'localhost';" \
    && mysql -u$MYSQLUSER -e "GRANT ALL PRIVILEGES ON zenoss_zep.* TO 'zenoss'@'localhost';" \
    && mysql -u$MYSQLUSER -e "GRANT ALL PRIVILEGES ON zodb_session.* TO 'zenoss'@'localhost';" \
    && mysql -u$MYSQLUSER -e "GRANT SELECT ON mysql.proc TO 'zenoss'@'localhost';" \
    && mysql -u$MYSQLUSER -e "CREATE USER 'zenoss'@'%' IDENTIFIED BY  'zenoss';" \
    && mysql -u$MYSQLUSER -e "GRANT REPLICATION SLAVE ON *.* TO 'zenoss'@'%' IDENTIFIED BY PASSWORD '*3715D7F2B0C1D26D72357829DF94B81731174B8C';" \
    && mysql -u$MYSQLUSER -e "GRANT ALL PRIVILEGES ON zodb.* TO 'zenoss'@'%';" \
    && mysql -u$MYSQLUSER -e "GRANT ALL PRIVILEGES ON zenoss_zep.* TO 'zenoss'@'%';" \
    && mysql -u$MYSQLUSER -e "GRANT ALL PRIVILEGES ON zodb_session.* TO 'zenoss'@'%';" \
    && mysql -u$MYSQLUSER -e "GRANT SELECT ON mysql.proc TO 'zenoss'@'%';" \
    && wget -N http://www.rabbitmq.com/releases/rabbitmq-server/v3.3.0/rabbitmq-server_3.3.0-1_all.deb -P $DOWNDIR/ \
    && dpkg -i $DOWNDIR/rabbitmq-server_3.3.0-1_all.deb \
    && chown -R zenoss:zenoss $ZENHOME && echo \
    && /etc/init.d/rabbitmq-server start && sleep 2\
    && rabbitmqctl add_user zenoss zenoss \
    && rabbitmqctl add_vhost /zenoss \
    && rabbitmqctl set_permissions -p /zenoss zenoss '.*' '.*' '.*' && echo \
    && cd /usr/local/zenoss/lib/python/pynetsnmp \
    && mv netsnmp.py netsnmp.py.orig \
    && wget https://raw.github.com/hydruid/zenoss/master/core-autodeploy/4.2.5/misc/netsnmp.py \
    && chown zenoss:zenoss netsnmp.py \
    && echo && ln -s /usr/local/zenoss /opt \
    && apt-get install libssl1.0.0 libssl-dev -y \
    && ln -s /lib/x86_64-linux-gnu/libssl.so.1.0.0 /usr/lib/libssl.so.10 \
    && ln -s /lib/x86_64-linux-gnu/libcrypto.so.1.0.0 /usr/lib/libcrypto.so.10 \
    && ln -s /usr/local/zenoss/zenup /opt \
    && chmod +x /usr/local/zenoss/zenup/bin/zenup \
    && echo 'watchdog True' >> $ZENHOME/etc/zenwinperf.conf \
    && touch $ZENHOME/var/Data.fs && echo \
    && wget --no-check-certificate -N https://raw.githubusercontent.com/JeroTwi/zenoss/master/core-autodeploy/$ZVERb/misc/zenoss -P $DOWNDIR/ \
    && cp $DOWNDIR/zenoss /etc/init.d/zenoss \
    && chmod 755 /etc/init.d/zenoss \
    && update-rc.d zenoss defaults && sleep 2 \
    && echo && touch /etc/insserv/overrides/zenoss \
    && echo "### BEGIN INIT INFO
    # Provides: zenoss-stack
    # Required-Start: $local_fs $network $remote_fs
    # Required-Stop: $local_fs $network $remote_fs
    # Should-Start: $all
    # Should-Stop: $all
    # Default-Start: 2 3 4 5
    # Default-Stop: 0 1 6
    # Short-Description: Start/stop Zenoss-stack
    # Description: Start/stop Zenoss-stack
    ### END INIT INFO" > /etc/insserv/overrides/zenoss \
    && echo && chown -c root:zenoss /usr/local/zenoss/bin/pyraw \
    && chown -c root:zenoss /usr/local/zenoss/bin/zensocket \
    && chown -c root:zenoss /usr/local/zenoss/bin/nmap \
    && chmod -c 04750 /usr/local/zenoss/bin/pyraw \
    && chmod -c 04750 /usr/local/zenoss/bin/zensocket \
    && chmod -c 04750 /usr/local/zenoss/bin/nmap && echo \
    && wget --no-check-certificate -N https://raw.githubusercontent.com/stdnwbeheer/zenoss4.2.5/master/secure_zenoss_ubuntu.sh -P $ZENHOME/bin \
    && chown -c zenoss:zenoss $ZENHOME/bin/secure_zenoss_ubuntu.sh && chmod -c 0700 $ZENHOME/bin/secure_zenoss_ubuntu.sh \
    && sed -i 's/mibs/#mibs/g' /etc/snmp/snmp.conf \
	&& wget --no-check-certificate -N https://raw.githubusercontent.com/stdnwbeheer/zenoss4.2.5/master/docker-entrypoint.sh -P / \
	&& chown root:root /docker-entrypoint.sh && chmod +x /docker-entrypoint.sh \
    && mysqladmin -u root password 'zenoss' \
	&& zenglobalconf -u zodb-admin-password="zenoss" \
	&& zenglobalconf -u zep-admin-password="zenoss" \
    && su -l -c "$ZENHOME/bin/secure_zenoss_ubuntu.sh" zenoss \
	&& /etc/init.d/mysql stop && sleep 2 \
	&& /etc/init.d/rabbitmq-server stop && sleep 2 \
	&& /etc/init.d/memcached stop && sleep 2 \
	&& /etc/init.d/redis-server stop && sleep 2 \
    && rm -R $DOWNDIR/* \
    && apt-get -y autoremove \
    && apt-get -y autoclean \
    && apt-get -y clean

EXPOSE 8080

ENTRYPOINT ["/docker-entrypoint.sh"]
