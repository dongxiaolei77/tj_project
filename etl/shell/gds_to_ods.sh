#!/bin/bash
tasktime=`date "+%Y-%m-%d"`
export JAVA_HOME=/usr/java/jdk1.8.0_151
export CLASSPATH=$CLASSPATH:$JAVA_HOME/lib:$JAVA_HOME/jre/lib
export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH:$HOME/bin
# 指定调度日期
v_sdate="$1"
/app/apps/dwnd/data-integration/kitchen.sh -file=/app/apps/dwnd/etl/ods/gds/job_gds_ngd_to_dw.kjb -param:v_sdate=$v_sdate -level=Detailed -logfile=/app/apps/dwnd/etl/log/${tasktime}_job_gds_ngd_to_dw.log
