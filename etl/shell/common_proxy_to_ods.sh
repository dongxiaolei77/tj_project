#!/bin/bash
tasktime=`date "+%Y-%m-%d"`
export JAVA_HOME=/usr/java/jdk1.8.0_151
export CLASSPATH=$CLASSPATH:$JAVA_HOME/lib:$JAVA_HOME/jre/lib
export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH:$HOME/bin
# 指定调度日期
v_sdate="$1"
v_sdate1=$(date -d "${1}" +'%Y-%m-%d')
v_sdate2=$(date -d "${1} +1 day" +'%Y-%m-%d')
/app/apps/dwnd/data-integration/kitchen.sh -file=/app/apps/dwnd/etl/ods/common_proxy/job_common_proxy_to_dw.kjb -param:v_sdate=$v_sdate -param:v_sdate1=$v_sdate1 -param:v_sdate2=$v_sdate2 -level=Detailed -logfile=/app/apps/dwnd/etl/log/${tasktime}_job_common_proxy_to_dw.log
