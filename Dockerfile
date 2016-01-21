FROM ubuntu
RUN if [ ! $(grep universe /etc/apt/sources.list) ]; \
    then sed 's/main$/main universe/' -i /etc/apt/sources.list; fi
RUN apt-get update -qq && \
    apt-get install -qy curl build-essential git-core python python-dev \
                        openjdk-7-jdk supervisor automake gnuplot unzip wget
RUN mkdir -p /opt/start/ /opt/downloads

#Install HBase and scripts
RUN mkdir -p /data/hbase
RUN mkdir -p /root/.profile.d
WORKDIR /opt

RUN cd /opt/downloads && \
	wget http://apache.org/dist/hbase/1.1.2/hbase-1.1.2-bin.tar.gz && \
    tar xzvf /opt/downloads/hbase-*gz && rm /opt/downloads/hbase-*gz && \
    mv hbase-* /opt/hbase
ADD start_hbase.sh /opt/start/
ADD hbase-site.xml /opt/hbase/conf/
EXPOSE 60000
EXPOSE 60010
EXPOSE 60030

#Install OpenTSDB and scripts
RUN git clone -b next --single-branch git://github.com/OpenTSDB/opentsdb.git /opt/opentsdb
# Increase UIDS width
RUN sed -i -e 's/METRICS_WIDTH = [0-9]\+;/METRICS_WIDTH = 5;/g' /opt/opentsdb/src/core/TSDB.java
RUN sed -i -e 's/TAG_NAME_WIDTH = [0-9]\+;/TAG_NAME_WIDTH = 4;/g' /opt/opentsdb/src/core/TSDB.java
RUN sed -i -e 's/TAG_VALUE_WIDTH = [0-9]\+;/TAG_VALUE_WIDTH = 4;/g' /opt/opentsdb/src/core/TSDB.java
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
