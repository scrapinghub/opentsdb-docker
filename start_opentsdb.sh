#!/bin/bash
echo "Sleeping for 30 seconds to give HBase time to warm up"
sleep 30 

if [ ! -e /opt/opentsdb_tables_created.txt ]; then
	echo "creating tsdb tables"
	bash /opt/start/create_tsdb_tables.sh
	echo "created tsdb tables"
fi

echo "starting opentsdb"
/opt/opentsdb/build/tsdb tsd --port=4242 --staticroot=/opt/opentsdb/build/staticroot --cachedir=/tmp --auto-metric
