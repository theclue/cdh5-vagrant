#!/bin/bash
################## install oracle jdk1.7   ####################
yum install -y wget
sed -i 's/exclude=kernel/#exclude=kernel/g' /etc/yum.conf

yum update -y

wget -q --no-check-certificate --no-cookies - --header "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u60-b27/jdk-8u60-linux-x64.rpm" -O /tmp/jdk-8u60-linux-x64.rpm
rpm -Uvh /tmp/jdk-8u60-linux-x64.rpm

# configure it on the system using the alternatives command. This is in order to tell the system what are the default commands for JAVA
alternatives --install /usr/bin/java java /usr/java/jdk1.8.0_60/jre/bin/java 20000
alternatives --install /usr/bin/jar jar /usr/java/jdk1.8.0_60/bin/jar 20000
alternatives --install /usr/bin/javac javac /usr/java/jdk1.8.0_60/bin/javac 20000
alternatives --install /usr/bin/javaws javaws /usr/java/jdk1.8.0_60/jre/bin/javaws 20000
alternatives --set java /usr/java/jdk1.8.0_60/jre/bin/java
alternatives --set javaws /usr/java/jdk1.8.0_60/jre/bin/javaws
alternatives --set javac /usr/java/jdk1.8.0_60/bin/javac
alternatives --set jar /usr/java/jdk1.8.0_60/bin/jar

# list version
ls -lA /etc/alternatives/ | grep java
java -version
javac -version

echo '' >> /etc/profile
echo '# set JAVAHOME' >> /etc/profile
echo 'export JAVA_HOME=/usr/java/jdk1.8.0_60' >> /etc/profile
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /etc/profile
source /etc/profile

rm -f /tmp/jdk-8u60-linux-x64.rpm

################## add cdh yum repository   ####################
cd /etc/yum.repos.d/
wget http://archive.cloudera.com/cdh5/redhat/6/x86_64/cdh/cloudera-cdh5.repo
wget http://archive.cloudera.com/gplextras5/redhat/6/x86_64/gplextras/cloudera-gplextras5.repo
rpm --import http://archive.cloudera.com/cdh5/redhat/6/x86_64/cdh/RPM-GPG-KEY-cloudera
