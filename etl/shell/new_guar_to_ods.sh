tasktime=`date "+%Y-%m-%d"`
export JAVA_HOME=/usr/java/jdk1.8.0_151
export CLASSPATH=$CLASSPATH:$JAVA_HOME/lib:$JAVA_HOME/jre/lib
export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH:$HOME/bin
/app/apps/dwnd/data-integration/kitchen.sh -file=/app/apps/dwnd/etl/ods/new_guar/job_fin_apply_project_check.kjb -level=Detailed -logfile=/app/apps/dwnd/etl/log/${tasktime}_job_fin_apply_project_check_today.log
