1. Before running this script please ensure you've zookeeper gem installed on your machine.

To install the gem issue command - gem install zookeeper

2. Ensure thay you've replaced QUORUM with a value like "zk1.domain:2181,zk2.domain:8181,zk3.domain:8181" and EXPECTED_NODES with array containing hostnames of solr nodes in  your cluster, like ["solr1.domain","solr2.domain,"solr3.domain"]
