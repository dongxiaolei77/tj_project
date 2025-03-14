
-- ---------------------------------------
-- 开发人   :  xueguangmin
-- 开发时间 ： 20220117
-- 目标表   ： dwd_cust_card_info 绑卡信息 
-- 源表     ： dwd_cust_info  客户基本信息表
			-- ods_crm_cust_card_info
 
-- 变更记录 ： 20220117:统一变动    
-- 			   20220516 日志变量注释  xgm
-- ---------------------------------------
-- set @etl_date='${v_sdate}' ; -- date_format(${v_sdate},'%Y%m%d')
-- set @time=now();
-- set @table_name='dwd_cust_card_info';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1; 
   
   
   
truncate table dw_base.dwd_cust_card_info; 
commit;

insert into dw_base.dwd_cust_card_info 

(
cust_id	, -- 客户号
card_no	, -- 卡号
-- card_type	, -- 卡类型
tel_no	, -- 预留手机号
-- sort	, -- 扣款顺序
stt	, -- 状态
bank_no	, -- 银行代码
-- bus_type	, -- 支持业务类型
bank_name	, -- 银行账户名称
create_dt	 -- 绑定日期
)

select  

a.cust_id	, -- 客户号
b.card_no	, -- 卡号
-- b.card_type	, -- 卡类型
b.tel_no	, -- 预留手机号
-- b.sort	, -- 扣款顺序
b.status	, -- 状态
b.bank_type	, -- 银行代码
-- b.business_types	, -- 支持业务类型
b.cust_name	, -- 银行账户名称
date_format(b.create_time,'%Y%m%d')   -- 绑定日期
from dw_base.dwd_cust_info a 
inner join  (select  card_no,
			tel_no,
			status,
			bank_type,
			cust_name,
			cust_id,
			id,
			update_time,
			create_time   
		from (  select card_no ,
					tel_no,
					status,
					bank_type,
					cust_name,
					cust_id,
					id,
					update_time,
					create_time
					,row_number() over(partition by id order by  update_time desc) as rk
				from  dw_nd.ods_crm_cust_card_info b 
				where date_format(update_time,'%Y%m%d') <=  '${v_sdate}'  -- mdy
			) b  
		where rk = 1) b
			on a.cust_id=b.cust_id  ;
-- select row_count() into @rowcnt;
commit;
-- 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('客户绑卡信息数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;