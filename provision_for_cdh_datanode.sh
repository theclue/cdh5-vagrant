#!/bin/bash
################## install cdh components for datanodes   ####################
yum clean all
yum install -y hadoop-yarn-nodemanager hadoop-hdfs-datanode hadoop-mapreduce hadoop-lzo

################## setup configuration files   ##############
# create a custom configuration profile called 'conf.vagrant'
#------------------------------------------------------------
# ref http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_cdh5_install.html?scroll=topic_4_4_4_unique_1
cp -r /etc/hadoop/conf.empty /etc/hadoop/conf.vagrant

alternatives --verbose --install /etc/hadoop/conf hadoop-conf /etc/hadoop/conf.vagrant 50
alternatives --set hadoop-conf /etc/hadoop/conf.vagrant

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
echo '</configuration>' >> /etc/hadoop/conf.vagrant/core-site.xml

# hdfs-site configurations
sed -i '$d' /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '    <name>dfs.permissions.superusergroup</name>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '    <value>hadoop</value>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '    <name>dfs.webhdfs.enabled</name>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '    <value>true</value>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '    <name>dfs.datanode.max.xcievers</name>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '    <value>4096</value>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml
echo '</configuration>' >> /etc/hadoop/conf.vagrant/hdfs-site.xml

mkdir /dfs/dn
chown -R hdfs:hdfs /dfs/dn
chmod 700 /dfs/dn
sed -i 's/dfs.name.dir/dfs.datanode.data.dir/g' /etc/hadoop/conf.vagrant/hdfs-site.xml
sed -i '/dfs.datanode.data.dir/{n; s/>.*\(<\/value>\)/>file:\/\/\/dfs\/dn\1/}' /etc/hadoop/conf.vagrant/hdfs-site.xml

# start the datanode
service hadoop-hdfs-datanode start

# autostart the datanode at boot time
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
echo '    <value>cdh-master:19888</value>' >> /etc/hadoop/conf.vagrant/mapred-site.xml
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
echo '    <value>cdh-master:8088</value>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '  <property>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '    <name>yarn.resourcemanager.hostname</name>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '    <value>cdh-master</value>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '  </property>' >> /etc/hadoop/conf.vagrant/yarn-site.xml
echo '</configuration>' >> /etc/hadoop/conf.vagrant/yarn-site.xml

# create the local storage directories
mkdir -p /dfs/yarn/local/vagrant /dfs/yarn/logs/vagrant
chown -R yarn:yarn /dfs/yarn/local /dfs/yarn/logs

# start services
service hadoop-yarn-nodemanager start

# autostart nodemanager at boot
chkconfig hadoop-yarn-nodemanager on

##### hbase installation and configuration   ######
# configure and start hbase as regionserver cluster
#--------------------------------------------------
# ref http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_hbase_install.html
yum install -y hbase hbase-regionserver

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

# start services
service hbase-regionserver start

# autostart services
chkconfig hbase-regionserver on

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
