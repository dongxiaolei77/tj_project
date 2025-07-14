#!/bin/bash
tasktime=`date "+%Y-%m-%d"`
export JAVA_HOME=/usr/java/jdk1.8.0_151
export CLASSPATH=$CLASSPATH:$JAVA_HOME/lib:$JAVA_HOME/jre/lib
export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH:$HOME/bin
# 指定调度日期
v_sdate="$1"
v_sdate_beg=$(date -d "${1}" +'%Y-%m-%d')
v_sdate_end=$(date -d "${1}" +'%Y-%m-%d')
/app/apps/dwnd/data-integration/kitchen.sh -file=/app/apps/dwnd/etl/ods/data_access/job_data_access_to_dw.kjb -param:v_sdate=$v_sdate -param:v_sdate_beg=$v_sdate_beg -param:v_sdate_end=$v_sdate_end -level=Detailed -logfile=/app/apps/dwnd/etl/log/${tasktime}_job_data_access_to_dw.log

