tasktime=`date "+%Y-%m-%d"`
export JAVA_HOME=/usr/java/jdk1.8.0_151
export CLASSPATH=$CLASSPATH:$JAVA_HOME/lib:$JAVA_HOME/jre/lib
export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH:$HOME/bin
/app/apps/dwnd/data-integration/kitchen.sh -file=/app/apps/dwnd/etl/dw/dw_to_creditmid_v2_z_migrate/job_ods_tjnd_yw_z_migrate_to_dw.kjb -level=Detailed -logfile=/app/apps/dwnd/etl/log/${tasktime}_job_ods_tjnd_yw_z_migrate_to_dw.kjb.log
