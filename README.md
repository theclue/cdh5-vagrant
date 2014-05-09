Vagrant provisioning script for Cloudera Hadoop Distribution 5
==============================================================

This script provides a complete automatic way to install Cloudera Hadoop in fully distributed node **without** user intervention. I decided to build it since the totality of Vagrant scripts for Hadoop I found on the Internet stop themselves after the installation of Cloudera Manager, which in turn is used to manually install the cluster.

This script won't use Cloudera Manager, but automates the manual installation and tuning on each node of the cluster. At ``vagrant up`` the cluster is provisioned and made ready-to-use in few minutes without a single click from the user!

Cluster features
----------------
The provisioned cluster has the following features:

* Full CDH Yarn cluster that also includes HBase (with Thrift), Oozie and Hue
* Each node has an automatically mounted virtual hard disk of configurable size for HDFS storage. This because vagrant boxes are defaulted with 8Gb boot hard disk, which is too small for real-use datanode storage.
* One **master** node which is publicy available through the LAN using DHCP. This node acts as Resource Manager, too.
* A configurable number of **slave** datanodes with share a private network with the master. For better isolation, these nodes are not available on the LAN
* Metadata is stored on a MySql instance running on the master node. This is true for every Cloudera service that may need to store data on a RDBMS (Hive, Hue, Oozie). Users and databases are create automatically (you can find credentials on the master node provisioning shell script, if you need them).
* For better management, Cloudera Services that have a Web UI are fully accessible trough the LAN, but you need to shell on the master node - which also acts as client - to launch YARN jobs. Or you can use Hue, if you prefer.
* Oracle JDK 1.7 is automatically downloaded and installed and replaces the weird (and sadly unsupported) OpenJDK library.
* As usual for vagrant boxes, SSH ports for each node are forwarded to host machine starting from port 2222. Please refer to the official vagrant documentation if you need further information.

Services included in the cluster
--------------------------------
The following services are included in the cluster on the master or the slave nodes (or both, eventually). Some of them have a WebUI interface. Please note that not every service is configured to automatically start at boot time.

* ZooKeeper (master)
* NodeManager (master, slave) - ``http://PUBLIC_IP:8042``
* ResourceManager (master)    - ``http://PUBLIC_IP:8088``
* JobHistory (master)         - ``http://PUBLIC_IP:19888``
* Namenode (master)           - ``http://PUBLIC_IP:50070``
* Datanode (master, slave)    - ``http://PUBLIC_IP:50075``
* HBase (master)              - ``http://PUBLIC_IP:60010``
* HBase Region Server (slave)
* WebHDFS (master)            - ``http://PUBLIC_IP:50070``
* Oozie (master)              - ``http://PUBLIC_IP:11000``
* WebHCat (master)            - ``http://PUBLIC_IP:50111``
* Hue (master)                - ``http://PUBLIC_IP:8888``

To get the ``PUBLIC_IP`` log in on the master node via SSH and issue the following command:

  ``ifconfig eth1 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'``
  
Don't forget that only the master node has a ``PUBLIC_IP``!
  
Configure and boot up the cluster
---------------------------------
Before booting up the cluster, you need to configure a few parameters in the Vagrantfile. You probably need to set at least:

* The number of datanodes to create. They will have a hostname in the form of cdh-node[1...N]
* RAM for the master node
* RAM for each slave node
* The size in GB for the secondary virtual hard disk, used for HDFS storage

Then, you simply need to ``vagrant up`` the cluster.
  
Supported providers
-------------------
This script supports only Virtualbox, at the moment. Support for AWS is currently in development.


Is this provisioner prodution-ready?
------------------------------------
It's intended to be and it would be. Right now, however, it misses some important features that it's better to add before going in a production environment:
:
* Better authentication mechanism
* Metadata redundancy
* A NFS for HDFS redundancy
* ZooKeeper redundancy
* Secondary NameNode
* Move the ResourceManager to a dedicated node

Some of the above points are out of scope; the others will be added sooner or later.
