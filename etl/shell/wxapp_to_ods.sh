#!/bin/bash
tasktime=`date "+%Y-%m-%d"`
export JAVA_HOME=/usr/java/jdk1.8.0_151
export CLASSPATH=$CLASSPATH:$JAVA_HOME/lib:$JAVA_HOME/jre/lib
export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH:$HOME/bin
# 指定调度日期
v_yesterday=$(date -d "${1}" +'%Y-%m-%d')
v_today=$(date -d "${v_yesterday} +1 day" +'%Y-%m-%d')
/app/apps/dwnd/data-integration/kitchen.sh -file=/app/apps/dwnd/etl/ods/wxapp/job_wxapp_to_dw.kjb -param:v_yesterday=$v_yesterday -param:v_today=$v_today -level=Detailed -logfile=/app/apps/dwnd/etl/log/${tasktime}_job_wxapp_to_dw.log
