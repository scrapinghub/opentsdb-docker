FROM ubuntu
RUN if [ ! $(grep universe /etc/apt/sources.list) ]; \
    then sed 's/main$/main universe/' -i /etc/apt/sources.list && apt-get update; fi
RUN DEBIAN_FRONTEND=noninteractive apt-get -y update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl build-essential git-core python python-dev \
    openjdk-7-jdk supervisor automake gnuplot unzip
RUN mkdir -p /opt/start/

#Install HBase and scripts
RUN mkdir -p /data/hbase
RUN mkdir -p /root/.profile.d
WORKDIR /opt
ADD http://apache.org/dist/hbase/1.1.2/hbase-1.1.2-bin.tar.gz /opt/downloads/
RUN tar xzvf /opt/downloads/hbase-*gz && rm /opt/downloads/hbase-*gz
RUN ["/bin/bash","-c","mv hbase-* /opt/hbase"]
ADD start_hbase.sh /opt/start/
ADD hbase-site.xml /opt/hbase/conf/
EXPOSE 60000
EXPOSE 60010
EXPOSE 60030

#Install OpenTSDB and scripts
RUN git clone -b next --single-branch git://github.com/OpenTSDB/opentsdb.git /opt/opentsdb
RUN cd /opt/opentsdb && bash ./build.sh
ADD start_opentsdb.sh /opt/start/
ADD create_tsdb_tables.sh /opt/start/
EXPOSE 4242

#Install Supervisord
RUN mkdir -p /var/log/supervisor
ADD supervisor-hbase.conf /etc/supervisor/conf.d/hbase.conf
ADD supervisor-system.conf /etc/supervisor/conf.d/system.conf
ADD supervisor-tsdb.conf /etc/supervisor/conf.d/tsdb.conf

VOLUME ["/data/hbase"]

CMD ["/usr/bin/supervisord"]
