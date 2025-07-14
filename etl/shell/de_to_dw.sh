tasktime=`date "+%Y-%m-%d"`
export JAVA_HOME=/usr/java/jdk1.8.0_151
export CLASSPATH=$CLASSPATH:$JAVA_HOME/lib:$JAVA_HOME/jre/lib
export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH:$HOME/bin
#!/bin/bash
tasktime=`date "+%Y-%m-%d"`
export JAVA_HOME=/usr/java/jdk1.8.0_151
export CLASSPATH=$CLASSPATH:$JAVA_HOME/lib:$JAVA_HOME/jre/lib
export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH:$HOME/bin
# 指定调度日期
v_sday="$1"
v_sdate=$(date -d "${1}" +'%Y-%m-%d')
v_today_beg=$(date -d "${1}" +'%Y-%m-%d')
v_today_end=$(date -d "${1}" +'%Y-%m-%d')
/app/apps/dwnd/data-integration/kitchen.sh -file=/app/apps/dwnd/etl/ods/de/job_de_to_dw.kjb -param:v_sdate=$v_sdate -param:v_today_beg=$v_today_beg -param:v_today_end=$v_today_end -param:v_sday=$v_sday -level=Detailed -logfile=/app/apps/dwnd/etl/log/${tasktime}_job_de_to_dw.log