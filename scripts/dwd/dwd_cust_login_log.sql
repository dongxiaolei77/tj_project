

 
-- ---------------------------------------
-- 开发人   :  xueguangmin
-- 开发时间 ： 20220117
-- 目标表   ： dwd_cust_login_log 客户操作步骤登记表 
-- 源表     ： ods_gcredit_customer_login_log 账户登录日志表,
 
-- 变更记录 ： 20220117:统一变动   
--             20220309:新建临时表tmp_dwd_cust_login_log_bs
--             20220516 日志变量注释  xgm   
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_cust_login_log';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1; 

-- 客户登录账号信息表  在cust 模型中已实现 
-- 客户认证流水表-（补充注册信息表）  在cust 模型中已实现 
-- 客户登录流水表

drop table if exists dw_base.tmp_dwd_cust_login_log_bs ;
commit;
CREATE TABLE dw_base.tmp_dwd_cust_login_log_bs (
	seq_id varchar(30)  COMMENT '序列号',
	customer_id varchar(30) COMMENT '客户编号',
	login_no varchar(100) COMMENT '登录账号',
	login_time bigint(20)COMMENT '登录时间',
	login_status char(2)  COMMENT '登录状态',
	terminal_name varchar(100) COMMENT '所用设备',
	create_time bigint(20) COMMENT '创建时间',
	error_desc varchar(100) COMMENT '错误描述',
	terminal_sys_version varchar(100) COMMENT '设备系统版本号',
	wc_version varchar(100) COMMENT '微信版本号',
	error_code varchar(100) COMMENT '错误代码',
index (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;
commit;
insert into dw_base.tmp_dwd_cust_login_log_bs
select
	seq_id,
	customer_id,
	login_no,
	login_time,
	login_status,
	terminal_name,
	create_time,
	error_desc,
	terminal_sys_version,
	wc_version,
	error_code  
from 
	(  
	select 
		seq_id,
		customer_id,
		login_no,
		login_time,
		login_status,
		terminal_name,
		create_time,
		error_desc,
		terminal_sys_version,
		wc_version,
		error_code
		,row_number() over(partition by seq_id order by create_time desc) as rk
	from dw_nd.ods_gcredit_customer_login_log b  
	where date_format(from_unixtime(create_time/1000,'%Y%m%d') ,'%Y%m%d') <=  '${v_sdate}'   -- mdy
	) b
where rk = 1;
commit;

truncate table dw_base.dwd_cust_login_log; 
commit;

insert into dw_base.dwd_cust_login_log 
(
	login_no, -- 登录账号
	cust_id, -- 客户号
	login_dt, -- 登录时间
	login_stt, -- 登录状态
	tenal_name, -- 所用设备
	error_desc, -- 错误描述
	tenal_sys_version, -- 设备系统版本号
	wc_version, -- 微信版本号
	error_code  -- 错误代码
)
select
	b.login_no, -- 登录账号
	a.cust_id, -- 客户号
	from_unixtime(b.login_time/1000,'%Y%m%d')  , -- 登录时间
	login_status, -- 登录状态
	terminal_name, -- 所用设备
	error_desc, -- 错误描述
	terminal_sys_version, -- 设备系统版本号
	wc_version, -- 微信版本号
	error_code -- 错误代码
from dw_base.dwd_cust_info a 
inner join dw_base.tmp_dwd_cust_login_log_bs b 
on a.cust_id=b.customer_id  ;
commit;
-- select row_count() into @rowcnt;
commit;

-- 在这里考虑 改造cust 里面的 登录表与日志表 ，先将其dwd 模型化 再从dwd 统一出数据 
-- 优先考虑从这个crm模块出数
-- /*
-- 
-- insert into  dw_base.dwd_cust_login_log 
-- (
-- login_no	, -- 登录账号
-- -- cust_id	, -- 客户号
-- login_type	, -- 登录账号类型
-- auth_type	, -- 认证类型
-- auth_stt	, -- 认证状态
-- auth_data	, -- 认证信息
-- begin_time	, -- 认证开始时间
-- end_time	, -- 认证结束时间
-- auth_code	, -- 认证码
-- auth_channel	, -- 认证渠道
-- error_code	, -- 错误码
-- error_desc	 -- 错误描述
-- )
-- 
-- select  
-- 
-- 
-- login_no	, -- 登录账号
-- -- cust_id	, -- 客户号
-- login_type	, -- 登录账号类型
-- auth_type	, -- 认证类型
-- auth_status	, -- 认证状态
-- auth_data	, -- 认证信息
-- FROM_UNIXTIME(b.begin_time/1000,'%Y-%m-%d %H:%i:%S') ,
-- FROM_UNIXTIME(b.end_time/1000,'%Y-%m-%d %H:%i:%S') 
-- auth_code	, -- 认证码
-- auth_channel_code	, -- 认证渠道
-- error_code	, -- 错误码
-- error_desc	 -- 错误描述
-- 
-- FROM_UNIXTIME(b.login_time/1000,'%Y-%m-%d %H:%i:%S')   -- 登录时间
-- from dw_base.dwd_cust_info a 
-- inner join  (select  *   from   dw_nd.ods_gcredit_customer_auth_log b   group by b.seq_id ) b  on a.cust_id=b.customer_id  ;
-- 
-- commit;
-- 
-- 
-- */
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('客户登录日志数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
   
   
   