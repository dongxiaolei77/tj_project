
-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117 
-- 目标表   ：dw_base.dwd_fin_credit_apply   授信申请表-按产品
-- 源表     ：dw_nd.ods_gcredit_credit_apply_log 授信申请记录表
-- 变更记录 ： 20220117:统一变动 
--             20220516 日志变量注释  xgm      
-- ---------------------------------------




-- set @etl_date='${v_sdate}';
-- set @pro_name='dwd_fin_credit_info';
-- set @table_name='dwd_fin_credit_apply';
-- set @sorting=1;
-- set @time=now();
-- set @auto_increment_increment=1;  
-- insert into dw_base.pub_etl_log -- values (@etl_date,@pro_name,@table_name,@sorting,'开始执行脚本',@time,now());commit;
-- set @sorting=@sorting+1;


 -- 客户授信申请信息 
 
 truncate table  dw_base.dwd_fin_credit_apply;
 
 insert into  dw_base.dwd_fin_credit_apply 
(
   day_id   , --  数据日期
   cust_id , -- 客户编号
   login_no , --  登录账号
   prod_id  , --  产品编码
   credit_status , --  授信状态
   error_code ,  --  错误代码
   create_time , -- 创建时间
   update_time , -- 更新时间
   apply_type , -- 申请类型
   reopen_flag , -- 授信决策开放标识
   cust_lab , --  客户标识
   reject_code , -- 决策拒绝原因码
   credit_limit_id -- 关联额度编号
 ) 
select  day_id
	,customer_id
	,login_no
	,product_id
	,credit_status
	,error_code
     ,create_time
	, update_time
	,apply_type
	,reopen_flag
	,customer_label
	, reject_code
	,credit_limit_id 
from (
select 
	'${v_sdate}' as day_id
	,customer_id
	,login_no
	,product_id
	,credit_status
	,error_code
	,FROM_UNIXTIME(create_time/1000) as create_time
	,FROM_UNIXTIME(update_time/1000) as update_time
	,apply_type
	,reopen_flag
	,customer_label
	, reject_code
	,credit_limit_id
	,row_number() over(partition by login_no order by  update_time desc) as rk
from  dw_nd.ods_gcredit_credit_apply_log a  
where  a.product_id='20200616110988001'  
		and  date_format(FROM_UNIXTIME(update_time/1000),'%Y%m%d') <=  '${v_sdate}'
) a
where rk = 1 ;
-- select row_count() into @rowcnt;
commit;

-- insert into dw_base.pub_etl_log -- values (@etl_date,@pro_name,@table_name,@sorting,concat('客户授信申请信息表加载完成,共插入',@rowcnt,'条'),@time,now());commit;
