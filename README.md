Vagrant provisioning script for Cloudera Hadoop Distribution 5
==============================================================

This script provide a complete automatic way to install Cloudera Hadoop in fully distributed node **without** user intervention. I decided to build it since the totality of Vagrand scripts for Hadoop I found on the Internet stop after the installation of Cloudera Manager, which in turn is used to install the cluster.

This script won't use Cloudera Manager, but uses the manual installation and tuning on each node of the cluster. At *vagrant up* the cluster is provisioned and made ready-to-use!

Cluster features
----------------
The provisioned cluster has the following features:

* Full CDH Yarn class that also includes HBase (with Thrift), Oozie and Hue
* Each node has an automatically mounted virtual hard disk of configurable size for HDFS storage. This because vagrant boxes are defaulted with 8Gb boot hard disk, which is too small for real-use datanode storage. The secondary storage file is in the root of the vagrant box
* One **master** node which is publicy available through the LAN using DHCP and a secondary network interface. This node acts as Resource Manager, too
* A configurable number of **slave** nodes with a shared private network which includes the master. For better isolation, these nodes are not available on the LAN
* Metadata is stored on a MySql instance running on the master node. This is true for every Cloudera service that may need to store data on a RDBMS (Hive, Hue, Oozie). Users and databases are create automatically, so no user intervention is necessary (you can find credentials on the master node provisioning shell script, if you need).
* For better management, Cloudera Services that have a Web UI are fully accessible trough the LAN, but you need to shell on the master node - which also acts as a client - to launch YARN jobs. Ora you can use Hue, if you prefer.
* Oracle JDK 1.7 is automatically installed and replaces the weird (and sadly unsupported) OpenJDK library.
* As usual for vagrant boxes, SSH for each node is forwarded to host machine starting from port 2222. Please refer to official vagrant documentation if you need further information.

Services included in the cluster
--------------------------------
The following services are included in the cluster on the master or the slave nodes (or both, eventually). Some of them have a WebUI interface. Please note that not every service is configured to automatically start at boot time.

* ZooKeeper (master)
* NodeManager (master, slave) - http://PUBLIC_IP:8042
* ResourceManager (master)    - http://PUBLIC_IP:8088
* JobHistory (master)         - http://PUBLIC_IP:19888
* Namenode (master)           - http://PUBLIC_IP:50070
* Datanode (master, slave)    - http://PUBLIC_IP:50075
* HBase (master)              - http://PUBLIC_IP:60010
* HBase Region Server (slave)
* WebHDFS (master)            - http://PUBLIC_IP:50070
* Oozie (master)              - http://PUBLIC_IP:11000
* WebHCat (master)            - http://PUBLIC_IP:50111
* Hue (master)                - http://PUBLIC_IP:8888

To get the PUBLIC_IP log in on the master node via SSH and issue the following command:

  ifconfig eth1 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'
  
Configure and boot up the cluster
---------------------------------
Before booting up the cluster, you need to configure a few parameters in the Vagrantfile. You probably need to set at least:
* The number of datanodes to create. They will have a hostname in the form of cdh-node[1...N]
* RAM for the master node
* RAM for the namenode
* The size in GB for the secondary virtual hard disk, using for HDFS storage

Then, you simply need to vagrant up the cluster using the usual command:
  vagrant up
  
Supported providers
-------------------
This script supports only Virtualbox, at the moment. Support for AWS is currently in development.

Is this provisioner prodution-ready?
-------------------------------
It's intended to be and it would be. Right now, however, it misses some important features that it's better to add before going in a production environment:
:
* Better authentication mechanism
* Metadata redundancy
* A NFS for HDFS redundancy
* ZooKeeper redundancy
* Secondary NameNode
* Move the ResourceManager to a dedicated node

Not all these points are in-scope for the provisioner; others will be added sooner or later.
