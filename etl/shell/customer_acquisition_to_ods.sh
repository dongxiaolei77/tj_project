#!/bin/bash
tasktime=`date "+%Y-%m-%d"`
export JAVA_HOME=/usr/java/jdk1.8.0_151
export CLASSPATH=$CLASSPATH:$JAVA_HOME/lib:$JAVA_HOME/jre/lib
export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH:$HOME/bin
# 指定调度日期
v_sdate="$1"
v_begin_date=$(date -d "${1}" +'%Y-%m-%d')
v_end_date=$(date -d "${1}" +'%Y-%m-%d')
/app/apps/dwnd/data-integration/kitchen.sh -file=/app/apps/dwnd/etl/ods/customer_acquisition/job_customer_acquisition_to_ods.kjb -param:v_sdate=$v_sdate -param:v_begin_date=$v_begin_date -param:v_end_date=$v_end_date -level=Detailed -logfile=/app/apps/dwnd/etl/log/${tasktime}_job_customer_acquisition_to_dw.log
