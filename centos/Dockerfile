FROM centos:7.3.1611
RUN curl -O http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-10.noarch.rpm
RUN rpm -ivh epel-release-7-10.noarch.rpm
RUN rm -fr /var/cache/yum/* && yum clean all 
RUN yum install -y rpm-build scons git python-lxml wget gcc patch make unzip flex bison gcc-c++ openssl-devel autoconf automake vim python-devel python-setuptools protobuf protobuf-devel protobuf-compiler net-snmp-python bzip2 boost-devel tbb-devel  libcurl-devel libxml2-devel zlib-devel cppunit-devel cyrus-sasl-devel cyrus-sasl-lib openssl-devel  cyrus-sasl python-sphinx.noarch kernel-devel libpcap-devel libpcap libnl-devel libnl3-devel wget libtool openssl cmake python-fixtures
RUN wget http://sourceforge.net/projects/libipfix/files/libipfix/libipfix_110209.tgz
RUN wget http://downloads.datastax.com/cpp-driver/centos/7/dependencies/libuv/v1.8.0/libuv-1.8.0-1.el7.centos.x86_64.rpm
RUN wget http://downloads.datastax.com/cpp-driver/centos/7/dependencies/libuv/v1.8.0/libuv-devel-1.8.0-1.el7.centos.x86_64.rpm
RUN wget http://downloads.datastax.com/cpp-driver/centos/7/cassandra/v2.4.2/cassandra-cpp-driver-2.4.2-1.el7.centos.x86_64.rpm
RUN wget http://downloads.datastax.com/cpp-driver/centos/7/cassandra/v2.4.2/cassandra-cpp-driver-devel-2.4.2-1.el7.centos.x86_64.rpm
RUN rpm -i libuv-devel-1.8.0-1.el7.centos.x86_64.rpm libuv-1.8.0-1.el7.centos.x86_64.rpm cassandra-cpp-driver-devel-2.4.2-1.el7.centos.x86_64.rpm cassandra-cpp-driver-2.4.2-1.el7.centos.x86_64.rpm
RUN git clone https://github.com/edenhill/librdkafka/
RUN tar zxvf libipfix_110209.tgz
RUN cd /libipfix_110209 && ./configure && make && make install
RUN cd /librdkafka/ && ./configure && make && make install
RUN cd 
RUN git clone https://github.com/michaelhenkel/zookeeper-el7-rpm
RUN mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
RUN cd zookeeper-el7-rpm \
      wget http://apache.cs.uu.nl/zookeeper/zookeeper-3.4.8/zookeeper-3.4.8.tar.gz \
      cp -r * ~/rpmbuild/SOURCES/ \
      rpmbuild -ba zookeeper.spec \
      rpm -i ~/rpmbuild/RPMS/x86_64/libzookeeper-3.4.8-1.x86_64.rpm ~/rpmbuild/RPMS/x86_64/libzookeeper-devel-3.4.8-1.x86_64.rpm ~/rpmbuild/RPMS/x86_64/python-zookeeper-3.4.8-1.x86_64.rpm
RUN wget --no-check-certificate -O /usr/bin/repo https://storage.googleapis.com/git-repo-downloads/repo
RUN chmod +x /usr/bin/repo
COPY entrypoint-centos.sh /
ENTRYPOINT ["/entrypoint-centos.sh"]
