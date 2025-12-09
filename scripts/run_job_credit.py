#-*- coding:utf-8 -*-
import os
import sys
import datetime
import time

import pymysql as pm


# 天津农担,征信前置库,执行征信send脚本专用
#if len(sys.argv)<3:
#    infostr = "Usage: %s rq frh" % sys.argv[0]
#    print(infostr)
#    print("参数个数不符:SQL文件名 日期")
#    sys.exit(1)

if sys.argv[1].endswith('.sql') == False or sys.argv[1].islower() == False:
    print("第一个参数必须是以.sql结尾的文件名且小写.")
    sys.exit(1)

#文件名
v_sqlfile_path = sys.argv[1]
v_sdate=sys.argv[2]

#日期
#today = datetime.date.today()
#yesterday = today - datetime.timedelta(days=1)
#v_sdate = datetime.datetime.strftime(yesterday, "%Y%m%d")

today = datetime.datetime.strptime(v_sdate[0:4]+'-'+v_sdate[4:6]+'-'+v_sdate[-2:],'%Y-%m-%d')
yesterday = today - datetime.timedelta(days=1)
v_yesterday = datetime.datetime.strftime(yesterday, "%Y%m%d")
print("跑批日期："+v_sdate)
print("昨日："+v_yesterday)


if v_sqlfile_path.startswith('dwd_'):
    #v_sqlfile_path=u'F:\\农担\\python\\dwd\\'+v_sqlfile_path
    v_sqlfile_path='/app/apps/dwnd/scripts/dwd/'+v_sqlfile_path
elif v_sqlfile_path.startswith('dws_'):
    v_sqlfile_path='/app/apps/dwnd/scripts/dws/'+v_sqlfile_path
elif v_sqlfile_path.startswith('dim_'):
    v_sqlfile_path='/app/apps/dwnd/scripts/dim/'+v_sqlfile_path
elif v_sqlfile_path.startswith('ads_'):
    v_sqlfile_path='/app/apps/dwnd/scripts/ads/'+v_sqlfile_path
elif v_sqlfile_path.startswith('exp_'):
    v_sqlfile_path='/app/apps/dwnd/scripts/exp/'+v_sqlfile_path
elif v_sqlfile_path.startswith('init_'):
    v_sqlfile_path='/app/apps/dwnd/scripts/init/'+v_sqlfile_path
elif v_sqlfile_path.startswith('create_table_'):
    v_sqlfile_path='/app/apps/dwnd/scripts/create_table/'+v_sqlfile_path
print("脚本路径为："+v_sqlfile_path)



#执行结果 True-成功，False-失败
_conn_status=False
_max_retries_count=20
_conn_retries_count=0
conn=None
curs=None
while not _conn_status and _conn_retries_count<=_max_retries_count:
    #主程序
    try:
        #连接数据库
        #配置库
        #测试
        #conn = pm.connect(host='10.50.22.10',port=3306,user='dwndopr',password='g_6ES4yv4AoH97CI',charset='utf8')
        #生产 172.31.139.10
        conn = pm.connect(host='60.29.26.62',port=8418,user='guest',password='abcd1234',charset='utf8',connect_timeout=5)
        #_conn_status=True
        curs = conn.cursor()
        _conn_status=True
        #curs.execute('SET GLOBAL connect_timeout=100')
        curs.execute('SET  wait_timeout=7200')
        curs.execute('SET  interactive_timeout=7200')
        ##读取SQL文件,获得sql语句的list
        print("sql文件"+v_sqlfile_path)
        with open(v_sqlfile_path, 'r',encoding='utf-8') as f:
            sql_list = f.read().split(';')[:-1]  # sql文件最后一行加上;
            #sql_list = [x.replace('\n', ' ') if '\n' in x else x for x in sql_list]  # 将每段sql里的换行符改成空格
        for sql  in sql_list:
            starttime = datetime.datetime.now()
            sql = sql.replace('${v_sdate}', v_sdate)
            sql = sql.replace('${v_yesterday}', v_yesterday)
            print(sql)
            # 20231101 fix:SQL执行出错，进行重试操作
            # try:
            rows_count=curs.execute(sql)
            print('----------------正常执行-------------------')
            print('----------------2-------------------')
            # except:
            #     print('----------------超时执行-------------------')
            #     conn.ping()
            #     curs.execute('SET  wait_timeout=7200')
            #     curs.execute('SET  interactive_timeout=7200')
            #     curs = conn.cursor()
            #     curs.execute(sql)
            #     print('----------------3-------------------')
            conn.commit()
            endtime = datetime.datetime.now()
            costtime = (endtime-starttime)
            costtimestr = '执行结束. 耗时[%d.%03d秒]' % (costtime.seconds, costtime.microseconds/1000)
            print(costtimestr)
    except Exception as ex:#异常处理
        print("连接超时!重试次数："+str(_conn_retries_count))
        print("Exception:", str(ex))
        _conn_status=False
        if _conn_retries_count == _max_retries_count:
            sys.exit(1)
        else:
            _conn_retries_count+=1
        # time.sleep(10)
    finally:
        #关闭数据库连接
        if curs is not None:
            curs.close()
        if conn is not None:
            conn.close()
