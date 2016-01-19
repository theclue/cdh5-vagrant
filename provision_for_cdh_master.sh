#!/bin/bash
################## install mysql database for cloudera   ####################
#install mysql database for cloudera  BEFORE installing cloudera
#---------------------------------------------------------------
# ref http://www.cloudera.com/content/cloudera-content/cloudera-docs/CM4Ent/latest/Cloudera-Manager-Installation-Guide/cmig_install_mysql.html#cmig_topic_5_5
sudo yum install -y mysql-server
service mysqld start

yum install -y mysql-connector-java

mysqladmin -u root password p@ssw0rd

# add root remote access
mysql -u root -pp@ssw0rd -e "CREATE USER 'root'@'%' IDENTIFIED BY 'p@ssw0rd';"
mysql -u root -pp@ssw0rd -e "GRANT ALL ON *.* TO 'root'@'%';"


# Recommended Settings
sed -i 's/symbolic-links=0/#symbolic-links=0/g' /etc/my.cnf
echo '' >> /etc/my.cnf
echo '# Recommended Settings for cloudera [mysqld]' >> /etc/my.cnf
echo 'transaction-isolation=READ-COMMITTED' >> /etc/my.cnf
echo 'key_buffer              = 16M' >> /etc/my.cnf
echo 'key_buffer_size         = 32M' >> /etc/my.cnf
echo 'max_allowed_packet      = 16M' >> /etc/my.cnf
echo 'thread_stack            = 256K' >> /etc/my.cnf
echo 'thread_cache_size       = 64' >> /etc/my.cnf
echo 'query_cache_limit       = 8M' >> /etc/my.cnf
echo 'query_cache_size        = 64M' >> /etc/my.cnf
echo 'query_cache_type        = 1' >> /etc/my.cnf
echo '# Important: see Configuring the Databases and Setting max_connections' >> /etc/my.cnf
echo 'max_connections         = 550' >> /etc/my.cnf
echo '# log-bin should be on a disk with enough free space' >> /etc/my.cnf
echo 'log-bin=/var/lib/mysql/logs/binary/mysql_binary_log' >> /etc/my.cnf
echo '' >> /etc/my.cnf
echo '# For MySQL version 5.1.8 or later. Comment out binlog_format for older versions.' >> /etc/my.cnf
echo 'binlog_format           = mixed' >> /etc/my.cnf
echo '' >> /etc/my.cnf
echo 'read_buffer_size = 2M' >> /etc/my.cnf
echo 'read_rnd_buffer_size = 16M' >> /etc/my.cnf
echo 'sort_buffer_size = 8M' >> /etc/my.cnf
echo 'join_buffer_size = 8M' >> /etc/my.cnf
echo '' >> /etc/my.cnf
echo '# InnoDB settings' >> /etc/my.cnf
echo 'innodb_file_per_table = 1' >> /etc/my.cnf
echo 'innodb_flush_log_at_trx_commit  = 2' >> /etc/my.cnf
echo 'innodb_log_buffer_size          = 64M' >> /etc/my.cnf
echo 'innodb_buffer_pool_size         = 4G' >> /etc/my.cnf
echo 'innodb_thread_concurrency       = 8' >> /etc/my.cnf
echo 'innodb_flush_method             = O_DIRECT' >> /etc/my.cnf
echo 'innodb_log_file_size = 512M' >> /etc/my.cnf

# Move the old InnoDB log files to a backup location
mkdir /var/lib/mysql/bak_orignal_log_file
mv /var/lib/mysql/ib_logfile0 /var/lib/mysql/ib_logfile1 /var/lib/mysql/bak_orignal_log_file


#Creating the MySQL Databases for Cloudera Manager --------------------------
#Create a database for the Activity Monitor
mysql -u root -pp@ssw0rd -e "create database amon DEFAULT CHARACTER SET utf8;"
mysql -u root -pp@ssw0rd -e "grant all on amon.* TO 'amon'@'%' IDENTIFIED BY 'p@ssw0rd';"

#Create a database for the Service Monitor
mysql -u root -pp@ssw0rd -e "create database smon DEFAULT CHARACTER SET utf8;"
mysql -u root -pp@ssw0rd -e "grant all on smon.* TO 'smon'@'%' IDENTIFIED BY 'p@ssw0rd';"

#Create a database for the Report Manager
mysql -u root -pp@ssw0rd -e "create database rman DEFAULT CHARACTER SET utf8;"
mysql -u root -pp@ssw0rd -e "grant all on rman.* TO 'rman'@'%' IDENTIFIED BY 'p@ssw0rd';"

#Create a database for the Host Monitor.
mysql -u root -pp@ssw0rd -e "create database hmon DEFAULT CHARACTER SET utf8;"
mysql -u root -pp@ssw0rd -e "grant all on hmon.* TO 'hmon'@'%' IDENTIFIED BY 'p@ssw0rd';"

# to make sure mysql will start at boot
/sbin/chkconfig mysqld on
/sbin/chkconfig --list mysqld

################## install zookeeper server   ####################
# install zookeper as standalone server BEFORE installing cloudera
#-----------------------------------------------------------------
# ref http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_cdh5_install.html?scroll=topic_4_4_4_unique_1
yum clean all
yum install -y zookeeper zookeeper-server

mkdir -p /var/lib/zookeeper
chown -R zookeeper /var/lib/zookeeper/

service zookeeper-server init --myid=1
service zookeeper-server start

chkconfig zookeeper-server on

################## install cdh components   ####################
# master will act as namenode, resourcemanager and so on...
#-----------------------------------------------------------------
# ref http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_cdh5_install.html?scroll=topic_4_4_4_unique_1
yum clean all
yum install -y hadoop-yarn-resourcemanager hadoop-hdfs-namenode hadoop-hdfs-datanode hadoop-mapreduce-historyserver hadoop-yarn-proxyserver hadoop-lzo hadoop-yarn-nodemanager


################## setup configuration files   ##############
# create a custom configuration profile called 'conf.vagrant'
#------------------------------------------------------------
# ref http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_cdh5_install.html?scroll=topic_4_4_4_unique_1
cp -r /etc/hadoop/conf.empty /etc/hadoop/conf.vagrant

alternatives --verbose --install /etc/hadoop/conf hadoop-conf /etc/hadoop/conf.vagrant 50
alternatives --set hadoop-conf /etc/hadoop/conf.vagrant

####### hdfs configuration   #########
# configure and start hdfs on namenode
#-------------------------------------
# ref http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_hdfs_cluster_deploy.html?scroll=topic_11_2

# core-site configurations
sed -i '$d' /etc/hadoop/conf.vagrant/core-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '    <name>fs.defaultFS</name>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '    <value>hdfs://cdh-master:8020</value>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '    <name>io.compression.codecs</name>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '    <value>org.apache.hadoop.io.compress.DefaultCodec,org.apache.hadoop.io.compress.GzipCodec, org.apache.hadoop.io.compress.BZip2Codec,com.hadoop.compression.lzo.LzoCodec, com.hadoop.compression.lzo.LzopCodec,org.apache.hadoop.io.compress.SnappyCodec</value>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '    <name>hadoop.proxyuser.mapred.groups</name>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '    <value>*</value>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '    <name>hadoop.proxyuser.mapred.hosts</name>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '    <value>*</value>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '  <!-- Hue WebHDFS proxy user setting -->' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '   <name>hadoop.proxyuser.hue.hosts</name>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '   <value>*</value>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '    <name>hadoop.proxyuser.hue.groups</name>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '    <value>*</value>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '    <name>hadoop.proxyuser.httpfs.hosts</name>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '    <value>*</value>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '    <name>hadoop.proxyuser.httpfs.groups</name>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '    <value>*</value>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '    <name>hadoop.proxyuser.oozie.hosts</name>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '    <value>*</value>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '    <name>hadoop.proxyuser.oozie.groups</name>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '    <value>*</value>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/core-site.xml
echo '</configuration>' >> /etc/hadoop/conf.vagrant/core-site.xml

# hdfs-site configurations
sed -i '$d' /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '    <name>dfs.datanode.data.dir</name>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '    <value>file:///dfs/dn</value>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '    <name>dfs.permissions.superusergroup</name>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '    <value>hadoop</value>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '    <name>dfs.webhdfs.enabled</name>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '    <value>true</value>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '</configuration>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml

mkdir /dfs/nn /dfs/dn
chown -R hdfs:hdfs /dfs/nn/ /dfs/dn
chmod 700 /dfs/nn /dfs/dn
sed -i 's/dfs.name.dir/dfs.namenode.name.dir/g' /etc/hadoop/conf.vagrant/hdfs-site.xml
sed -i '/dfs.namenode.name.dir/{n; s/>.*\(<\/value>\)/>file:\/\/\/dfs\/nn\1/}' /etc/hadoop/conf.vagrant/hdfs-site.xml

# format namenode on /dfs/nn
sudo -u hdfs hdfs namenode -format

# start namenode and datanode
service hadoop-hdfs-namenode start
service hadoop-hdfs-datanode start

# create temp dir on hdfs
sudo -u hdfs hadoop fs -mkdir /tmp
sudo -u hdfs hadoop fs -chmod -R 1777 /tmp

# autostart namenode and datanode at boot
chkconfig hadoop-hdfs-namenode on
chkconfig hadoop-hdfs-datanode on

## yarn configuration   ##
# configure and start yarn
#-------------------------
# ref http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_hdfs_cluster_deploy.html?scroll=topic_11_2
sed -i '$d' /etc/hadoop/conf.vagrant/mapred-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/mapred-site.xml
echo '    <name>mapreduce.framework.name</name>' >> /etc/hadoop/conf.vagrant/mapred-site.xml
echo '    <value>yarn</value>' >> /etc/hadoop/conf.vagrant/mapred-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/mapred-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/mapred-site.xml
echo '    <name>mapreduce.jobhistory.address</name>' >> /etc/hadoop/conf.vagrant/mapred-site.xml
echo '    <value>cdh-master:10020</value>' >> /etc/hadoop/conf.vagrant/mapred-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/mapred-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/mapred-site.xml
echo '    <name>mapreduce.jobhistory.webapp.address</name>' >> /etc/hadoop/conf.vagrant/mapred-site.xml
echo '    <value>0.0.0.0:19888</value>' >> /etc/hadoop/conf.vagrant/mapred-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/mapred-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/mapred-site.xml
echo '    <name>yarn.app.mapreduce.am.staging-dir</name>' >> /etc/hadoop/conf.vagrant/mapred-site.xml
echo '    <value>/user</value>' >> /etc/hadoop/conf.vagrant/mapred-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/mapred-site.xml
echo '</configuration>' >> /etc/hadoop/conf.vagrant/mapred-site.xml

# yarn-site.xml
sed -i '/yarn.nodemanager.local-dirs/{n; s/>.*\(<\/value>\)/>file:\/\/\/dfs\/yarn\/local\/$\{user.name\}\1/}' /etc/hadoop/conf.vagrant/yarn-site.xml
sed -i '/yarn.nodemanager.log-dirs/{n; s/>.*\(<\/value>\)/>file:\/\/\/dfs\/yarn\/logs\/$\{user.name\}\1/}' /etc/hadoop/conf.vagrant/yarn-site.xml
sed -i '/yarn.nodemanager.remote-app-log-dir/{n; s/>.*\(<\/value>\)/>hdfs:\/\/cdh-master:8020\/var\/log\/hadoop-yarn\/apps\1/}' /etc/hadoop/conf.vagrant/yarn-site.xml

# TODO - where resourcemanager goes to another machine, fix the hostname
sed -i '$d' /etc/hadoop/conf.vagrant/yarn-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '    <name>yarn.resourcemanager.resource-tracker.address</name>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '    <value>cdh-master:8031</value>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '    <name>yarn.resourcemanager.address</name>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '    <value>cdh-master:8032</value>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '    <name>yarn.resourcemanager.scheduler.address</name>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '    <value>cdh-master:8030</value>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '    <name>yarn.resourcemanager.admin.address</name>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '    <value>cdh-master:8033</value>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '    <name>yarn.resourcemanager.webapp.address</name>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '    <value>0.0.0.0:8088</value>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '    <name>yarn.resourcemanager.hostname</name>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '    <value>cdh-master</value>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '</configuration>' >> /etc/hadoop/conf.vagrant/yarn-site.xml

# create needed directories on hdfs
sudo -u hdfs hadoop fs -mkdir -p /user/history
sudo -u hdfs hadoop fs -chmod -R 1777 /user/history
#sudo -u hdfs hadoop fs -chown mapred:hadoop /user/history
sudo -u hdfs hadoop fs -chown yarn:hadoop /user/history
sudo -u hdfs hadoop fs -mkdir -p /var/log/hadoop-yarn
sudo -u hdfs hadoop fs -chown yarn:mapred /var/log/hadoop-yarn

# start services
service hadoop-yarn-resourcemanager start
service hadoop-yarn-nodemanager start
service hadoop-mapreduce-historyserver start

# autostart resourcemanager, nodemanager and historyserver at boot
chkconfig hadoop-yarn-resourcemanager on
chkconfig hadoop-yarn-nodemanager on
chkconfig hadoop-mapreduce-historyserver on

# create home directories for yarn users
sudo -u hdfs hadoop fs -mkdir  /user/vagrant
sudo -u hdfs hadoop fs -chown vagrant /user/vagrant

########## hbase installation and configuration  ########
# configure and start hbase in fully distributed cluster
#--------------------------------------------------------
# ref http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_hbase_install.html
yum install -y hbase hbase-master hbase-rest hbase-thrift

cp -r /etc/hbase/conf.dist /etc/hbase/conf.vagrant

alternatives --verbose --install /etc/hbase/conf hbase-conf /etc/hbase/conf.vagrant 50
alternatives --set hbase-conf /etc/hbase/conf.vagrant

#hbase-site
sed -i '$d' /etc/hbase/conf.vagrant/hbase-site.xml
echo '  <property>' >> /etc/hbase/conf.vagrant/hbase-site.xml
echo '    <name>hbase.cluster.distributed</name>' >> /etc/hbase/conf.vagrant/hbase-site.xml
echo '    <value>true</value>' >> /etc/hbase/conf.vagrant/hbase-site.xml
echo '  </property>' >> /etc/hbase/conf.vagrant/hbase-site.xml
echo '  <property>' >> /etc/hbase/conf.vagrant/hbase-site.xml
echo '    <name>hbase.rootdir</name>' >> /etc/hbase/conf.vagrant/hbase-site.xml
echo '    <value>hdfs://cdh-master:8020/hbase</value>' >> /etc/hbase/conf.vagrant/hbase-site.xml
echo '  </property>' >> /etc/hbase/conf.vagrant/hbase-site.xml
echo '  <property>' >> /etc/hbase/conf.vagrant/hbase-site.xml
echo '    <name>hbase.zookeeper.quorum</name>' >> /etc/hbase/conf.vagrant/hbase-site.xml
echo '    <value>cdh-master</value>' >> /etc/hbase/conf.vagrant/hbase-site.xml
echo '  </property>' >> /etc/hbase/conf.vagrant/hbase-site.xml
echo '</configuration>' >> /etc/hbase/conf.vagrant/hbase-site.xml

# hbase needs more file handles
sed -i '$d' /etc/security/limits.conf
echo 'hdfs  -       nofile  32768' >> /etc/security/limits.conf
echo 'hbase -       nofile  32768' >>  /etc/security/limits.conf
echo '' >> /etc/security/limits.conf
echo '# End of file' >> /etc/security/limits.conf

# create hdfs directories
sudo -u hdfs hadoop fs -mkdir /hbase
sudo -u hdfs hadoop fs -chown hbase /hbase

# start hbase services
service hbase-master start
service hbase-thrift start
#service hbase-rest start

# autostart services
chkconfig hbase-master on
chkconfig hbase-thrift on

## hive installation and configuration   ##
# configure and start hive
#-----------------------------------------
# ref http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_hive_installation.html
yum install -y hive hive-metastore hive-server2 hive-hbase

cp -r /etc/hive/conf.dist /etc/hive/conf.vagrant

alternatives --verbose --install /etc/hive/conf hive-conf /etc/hive/conf.vagrant 50
alternatives --set hive-conf /etc/hive/conf.vagrant

#Create the Database for the Hive Metastore and Impala Catalog Daemon
mysql -u root -pp@ssw0rd -e "CREATE DATABASE metastore DEFAULT CHARACTER SET utf8;"
mysql -u root -pp@ssw0rd -e "CREATE USER 'hive'@'localhost' IDENTIFIED BY 'p@ssw0rd';"
mysql -u root -pp@ssw0rd -e "REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'hive'@'localhost';"
mysql -u root -pp@ssw0rd -e "GRANT SELECT,INSERT,UPDATE,DELETE,LOCK TABLES,EXECUTE ON metastore.* TO 'hive'@'localhost'; FLUSH PRIVILEGES;"

# show hive user privileges
mysql -u root -pp@ssw0rd -e "SHOW GRANTS FOR 'hive'@'localhost';"

# the installed mysql-connector-java is symbolically linked to /usr/lib/hive/lib/ directory.
# this is enought on CentOS 6
ln -s /usr/share/java/mysql-connector-java.jar /usr/lib/hive/lib/mysql-connector-java.jar

#hive-site
sed -i '/javax.jdo.option.ConnectionURL/{n; s/>.*\(<\/value>\)/>jdbc:mysql:\/\/localhost\/metastore\1/}' /etc/hive/conf.vagrant/hive-site.xml
sed -i '/javax.jdo.option.ConnectionDriverName/{n; s/>.*\(<\/value>\)/>com.mysql.jdbc.Driver\1/}' /etc/hive/conf.vagrant/hive-site.xml

sed -i '$d' /etc/hive/conf.vagrant/hive-site.xml
echo '' >> /etc/hive/conf.vagrant/hive-site.xml
echo '  <property>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '    <name>javax.jdo.option.ConnectionUserName</name>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '    <value>hive</value>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '  </property>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '' >> /etc/hive/conf.vagrant/hive-site.xml
echo '  <property>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '    <name>javax.jdo.option.ConnectionPassword</name>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '    <value>p@ssw0rd</value>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '  </property>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '' >> /etc/hive/conf.vagrant/hive-site.xml
echo '  <property>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '    <name>datanucleus.autoCreateSchema</name>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '    <value>false</value>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '  </property>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '' >> /etc/hive/conf.vagrant/hive-site.xml
echo '  <property>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '    <name>datanucleus.fixedDatastore</name>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '    <value>true</value>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '  </property>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '' >> /etc/hive/conf.vagrant/hive-site.xml
echo '  <property>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '    <name>datanucleus.autoStartMechanism</name>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '    <value>SchemaTable</value>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '  </property>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '' >> /etc/hive/conf.vagrant/hive-site.xml
echo '  <property>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '    <name>hive.metastore.uris</name>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '    <value>thrift://cdh-master:9083</value>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '    <description>IP address (or fully-qualified domain name) and port of the metastore host</description>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '  </property>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '' >> /etc/hive/conf.vagrant/hive-site.xml
echo '  <property>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '    <name>hive.support.concurrency</name>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '    <value>true</value>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '  </property>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '' >> /etc/hive/conf.vagrant/hive-site.xml
echo '  <property>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '    <name>hive.zookeeper.quorum</name>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '    <value>cdh-master</value>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '  </property>' >> /etc/hive/conf.vagrant/hive-site.xml
echo '</configuration>' >> /etc/hive/conf.vagrant/hive-site.xml

# init the schema using root user ('hive' user hasn't create table privilege)
/usr/lib/hive/bin/schematool -dbType mysql -initSchema -userName root - password p@ssw0rd

# show hive's user metastore tables
mysql -u hive -pp@ssw0rd -e "USE metastore; SHOW TABLES;"

# this is needed for YARN
echo 'export HADOOP_MAPRED_HOME=/usr/lib/hadoop-mapreduce' >> /etc/default/hive-server2

# start the metastore
service hive-metastore start

# create needed directories on hdfs
# create temp dir on hdfs
sudo -u hdfs hadoop fs -mkdir -p /user/hive/warehouse
sudo -u hdfs hadoop fs -chmod -R 1777 /user/hive/warehouse

# start hive server 2
service hive-server2 start

# confirm hive server 2 is correctly running
/usr/lib/hive/bin/beeline -u jdbc:hive2://localhost:10000 -n username -p password -d org.apache.hive.jdbc.HiveDriver -e "show tables;"

# autostart services
chkconfig hive-metastore  on
chkconfig hive-server2 on

## mahout installation  ##
# configure mahout library
#-------------------------
# ref http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_mahout_installation.html
yum install -y mahout

### pig installation  ###
# configure and test pig
#------------------------
# ref http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_pig_installation.html
yum install -y pig pig-udf-datafu

### oozie server installation  ###
# configure and start oozie server
#---------------------------------
# ref http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_oozie_about.html
yum install -y oozie

cp -r /etc/oozie/conf.dist /etc/oozie/conf.vagrant

alternatives --verbose --install /etc/oozie/conf oozie-conf /etc/oozie/conf.vagrant 50
alternatives --set oozie-conf /etc/oozie/conf.vagrant

# configure oozie to work with YARN and without SSL
alternatives --set oozie-tomcat-conf /etc/oozie/tomcat-conf.http

#Create a database for the Oozie server.
mysql -u root -pp@ssw0rd -e "create database oozie;"
mysql -u root -pp@ssw0rd -e "create user 'oozie'@'localhost' IDENTIFIED BY 'p@ssw0rd';"
mysql -u root -pp@ssw0rd -e "grant all privileges on oozie.* to 'oozie'@'localhost'; flush privileges"

# the installed mysql-connector-java is symbolically linked to /usr/lib/hive/lib/ directory.
# this is enought on CentOS 6
ln -s /usr/share/java/mysql-connector-java.jar /var/lib/oozie/mysql-connector-java.jar

#oozie-site
sed -i '$d' /etc/oozie/conf.vagrant/oozie-site.xml
echo '' >> /etc/oozie/conf.vagrant/oozie-site.xml
echo '  <property>' >> /etc/oozie/conf.vagrant/oozie-site.xml
echo '    <name>oozie.service.JPAService.jdbc.driver</name>' >> /etc/oozie/conf.vagrant/oozie-site.xml
echo '    <value>com.mysql.jdbc.Driver</value>' >> /etc/oozie/conf.vagrant/oozie-site.xml
echo '  </property>' >> /etc/oozie/conf.vagrant/oozie-site.xml
echo '' >> /etc/oozie/conf.vagrant/oozie-site.xml
echo '  <property>' >> /etc/oozie/conf.vagrant/oozie-site.xml
echo '    <name>oozie.service.JPAService.jdbc.url</name>' >> /etc/oozie/conf.vagrant/oozie-site.xml
echo '    <value>jdbc:mysql://localhost:3306/oozie</value>' >> /etc/oozie/conf.vagrant/oozie-site.xml
echo '  </property>' >> /etc/oozie/conf.vagrant/oozie-site.xml
echo '' >> /etc/oozie/conf.vagrant/oozie-site.xml
echo '  <property>' >> /etc/oozie/conf.vagrant/oozie-site.xml
echo '    <name>oozie.service.JPAService.jdbc.username</name>' >> /etc/oozie/conf.vagrant/oozie-site.xml
echo '    <value>oozie</value>' >> /etc/oozie/conf.vagrant/oozie-site.xml
echo '  </property>' >> /etc/oozie/conf.vagrant/oozie-site.xml
echo '' >> /etc/oozie/conf.vagrant/oozie-site.xml
echo '  <property>' >> /etc/oozie/conf.vagrant/oozie-site.xml
echo '    <name>oozie.service.JPAService.jdbc.password</name>' >> /etc/oozie/conf.vagrant/oozie-site.xml
echo '    <value>p@ssw0rd</value>' >> /etc/oozie/conf.vagrant/oozie-site.xml
echo '  </property>' >> /etc/oozie/conf.vagrant/oozie-site.xml
echo '</configuration>' >> /etc/oozie/conf.vagrant/oozie-site.xml

# create table schemas
sudo -u oozie /usr/lib/oozie/bin/ooziedb.sh create -run

# show oozie user's tables
mysql -u oozie -pp@ssw0rd -e "USE oozie; SHOW TABLES;"

# enable oozie web console
cd tmp/
wget -q http://archive.cloudera.com/gplextras/misc/ext-2.2.zip
unzip ext-2.2.zip -d /var/lib/oozie
rm -f ext-2.2.zip

# install oozie shared libs
sudo -u hdfs hadoop fs -mkdir -p /user/oozie/deployments
sudo -u hdfs hadoop fs -chown -R oozie:oozie /user/oozie
sudo oozie-setup sharelib create -fs  hdfs://cdh-master:8020 -locallib /usr/lib/oozie/oozie-sharelib-yarn.tar.gz

sed -i 's/export OOZIE_CONFIG=\/etc\/oozie\/conf/export OOZIE_CONFIG=\/etc\/oozie\/conf.vagrant/' /etc/oozie/conf.vagrant/oozie-env.sh

# start the service
service oozie start

# check if oozie is correctly running
oozie admin -oozie http://localhost:11000/oozie -status

# autostart at boot
chkconfig oozie on


### hcatalog installation and configuration   ###
# configure and start hcatalog and its web server
#------------------------------------------------
# ref http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_hcat_install.html
yum install -y hive-hcatalog hive-webhcat hive-webhcat-server

# workaroung waiting from fix by Cloudera
# ref http://grokbase.com/p/cloudera/cdh-user/1433ecjnmd/cdh5beta-webhcat-error
PYTHON_CMD=$(which python)
# TODO: remove hardcoded path to python executables in sed statements
sed -i "/templeton.python/{n; s/>.*\(<\/value>\)/>\/usr\/bin\/python\1/}"  /usr/lib/hive-hcatalog/etc/webhcat/webhcat-default.xml
sed -i "/templeton.hcat/{n; s/>.*\(<\/value>\)/>\/usr\/lib\/hive-hcatalog\/bin\/hcat.py\1/}"  /usr/lib/hive-hcatalog/etc/webhcat/webhcat-default.xml

# start the service
service hive-webhcat-server start

# autostart at boot
chkconfig hive-webhcat-server on

### flume agents installation  ###
# configure and start flume agents
#---------------------------------
# ref http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_flume_package_install.html
yum install -y flume-ng flume-ng-agent flume-ng-doc

cp -r /etc/flume-ng/conf.empty /etc/flume-ng/conf.vagrant

alternatives --verbose --install /etc/flume-ng/conf flume-ng-conf /etc/flume-ng/conf.vagrant 50
alternatives --set flume-ng-conf /etc/flume-ng/conf.vagrant

# copy the template file to effective configuration properties file; it must be edited then!
rm -f /etc/flume-ng/conf.vagrant/flume.conf
cp /etc/flume-ng/conf.vagrant/flume-conf.properties.template /etc/flume-ng/conf.vagrant/flume.conf

## hue installation and configuration   ##
# configure and start hue web server
#-----------------------------------------
# ref http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_hue_install.html?scroll=topic_15_3

# python is needed on CentOS; it should be already on place, but better safe than sorry
yum install -y hue

cp -r /etc/hue/conf.empty /etc/hue/conf.vagrant

alternatives --verbose --install /etc/hue/conf hue-conf /etc/hue/conf.vagrant 50
alternatives --set hue-conf /etc/hue/conf.vagrant

#Create a database for Hue.
mysql -u root -pp@ssw0rd -e "create database hue;"
mysql -u root -pp@ssw0rd -e "create user 'hue'@'localhost' IDENTIFIED BY 'p@ssw0rd';"
mysql -u root -pp@ssw0rd -e "grant all privileges on hue.* to 'hue'@'localhost'; flush privileges"

# get a copy from a fresh hue.ini
# since for some reason the one provided in conf.empty won't work properly
rm /etc/hue/conf.vagrant/hue.ini
cd /etc/hue/conf.vagrant
wget -q https://raw.githubusercontent.com/cloudera/hue/master/desktop/conf.dist/hue.ini

#hue.ini

# default
sed -i 's/secret_key=/secret_key=qpbdxoewsqlkhztybvfidtvwekftusgdlofbcfghaswuicmqp/' /etc/hue/conf.vagrant/hue.ini
sed -i 's/http_500_debug_mode=false/http_500_debug_mode=true/' /etc/hue/conf.vagrant/hue.ini

# database
sed -i 's/\[\[database\]\]/\[\[database\]\]\n    engine=mysql\n    host=localhost\n    port=3306\n    user=hue\n    password=p@ssw0rd\n    name=hue/' /etc/hue/conf.vagrant/hue.ini

# hadoop
sed -i 's/fs_defaultfs=hdfs:\/\/localhost:8020/fs_defaultfs=hdfs:\/\/cdh-master:8020/' /etc/hue/conf.vagrant/hue.ini
sed -i 's/## webhdfs_url=http:\/\/localhost:50070\/webhdfs\/v1/webhdfs_url=http:\/\/cdh-master:50070\/webhdfs\/v1/' /etc/hue/conf.vagrant/hue.ini

# yarn
sed -i 's/## resourcemanager_host=localhost/resourcemanager_host=cdh-master/' /etc/hue/conf.vagrant/hue.ini
sed -i 's/# history_server_api_url=http:\/\/localhost:19888/history_server_api_url=http:\/\/cdh-manager:19888/' /etc/hue/conf.vagrant/hue.ini
sed -i 's/## resourcemanager_api_url=http:\/\/localhost:8088/resourcemanager_api_url=http:\/\/cdh-master:8088/' /etc/hue/conf.vagrant/hue.ini
sed -i 's/## proxy_api_url=http:\/\/localhost:8088/proxy_api_url=http:\/\/cdh-master:8088/' /etc/hue/conf.vagrant/hue.ini


# pig
sed -i 's/## local_sample_dir=\/usr\/share\/hue\/apps\/pig\/examples/local_sample_dir=\/usr\/lib\/pig/' /etc/hue/conf.vagrant/hue.ini
# sed -i 's/## remote_data_dir=/user/hue/pig/examples/remote_data_dir=/user/hue/pig/examples/' /etc/hue/conf.vagrant/hue.ini

# oozie
sed -i 's/## oozie_url=http:\/\/localhost:11000\/oozie/oozie_url=http:\/\/cdh-master:11000\/oozie/' /etc/hue/conf.vagrant/hue.ini
sed -i 's/## remote_deployement_dir=\/user\/hue\/oozie\/deployments/remote_deployement_dir=\/user\/hue\/oozie\/deployments/' /etc/hue/conf.vagrant/hue.ini

# hive
sed -i 's/## hive_conf_dir=\/etc\/hive\/conf/hive_conf_dir=\/etc\/hive\/conf.vagrant/' /etc/hue/conf.vagrant/hue.ini
sed -i 's/## hive_server_host=<FQDN of Hive Server>/hive_server_host=cdh-master/' /etc/hue/conf.vagrant/hue.ini
sed -i 's/## hive_server_port=10000/hive_server_port=10000/' /etc/hue/conf.vagrant/hue.ini

# hbase
sed -i 's/## hbase_clusters=(Cluster|localhost:9090)/hbase_clusters=(Cluster|cdh-master:9090)/' /etc/hue/conf.vagrant/hue.ini

# zookeeper
sed -i 's/## host_ports=localhost:2181/host_ports=cdh-master:2181/' /etc/hue/conf.vagrant/hue.ini

#sed -i -e '/[[database]]/{n;N;N;d}' /etc/hue/conf.vagrant/hue.ini

# init the mysql database
/usr/lib/hue/build/env/bin/hue syncdb --noinput
/usr/lib/hue/build/env/bin/hue migrate

# start the service
service hue start

# autostart at boot
chkconfig hue on

############# print useful informations ################
# print a recap of useful informations about the cluster
#-------------------------------------------------------
# ref

PUBLIC_IP=$(/sbin/ifconfig eth1 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}')
echo "-----------------------------------------------------------------------------------------"
echo ""
echo "  Welcome to Cloudera Hadoop Distribution 5"
echo ""
echo "  This cluster was provisioned by Gabriele Baldassarre - http://gabrielebaldassarre.com"
echo ""
echo "  Master Node FQHN: $(hostname) Public IP: ($PUBLIC_IP)"
echo ""
echo "  Please use the provided WebUIs for inspecting the services executing on this machine:"
echo ""
echo "  NodeManager:    http://$PUBLIC_IP:8042"
echo "  ResourceManager http://$PUBLIC_IP:8088"
echo "  JobHistory      http://$PUBLIC_IP:19888"
echo "  Namenode:       http://$PUBLIC_IP:50070"
echo "  Datanode:       http://$PUBLIC_IP:50075"
echo "  HBase:          http://$PUBLIC_IP:60010"
echo "  WebHDFS:        http://$PUBLIC_IP:50070"
echo "  Oozie:          http://$PUBLIC_IP:11000"
echo "  WebHCat:        http://$PUBLIC_IP:50111"
echo "  Hue:            http://$PUBLIC_IP:8888"
echo ""
echo "-----------------------------------------------------------------------------------------"
echo ""
echo " Services must start in the following order (reverse order for stopping):"
echo ""
echo "  1. ZooKeeper        (*)"
echo "  2. HDFS             (*)"
echo "  3. ResourceManager  (*)"
echo "  4. NodeManager      (*)"
echo "  5. History Server   (*)"
echo "  6. HBase            (*)"
echo "  7. HBase Thrift     (*)"
echo "  8. Hive Metastore   (*)"
echo "  9. HiveServer2      (*)"
echo "  10. Oozie           (*)"
echo "  11. Flume"
echo "  11. WebHCat"
echo "  12. Hue             (*)"
echo ""
echo "  (*) configured to start at boot time"

