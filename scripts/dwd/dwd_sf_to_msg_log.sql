-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 源表     ：dw_nd.ods_de_t_msg_log 报文日志表,dw_base.dwd_cust_sf_info 三方查询客户流水表,dw_base.dim_sf_msg_code 三方-报文交易码
-- 变更记录 ： 20220117:统一变动
--             20220424xgm:优化，新建临时表 tmp_dwd_sf_to_msg_log_ods_log,优化where条件
--             20220516 日志变量注释  xgm
--             20241201 脚本的统一变更，MySQL5.0转MySQL8.0 zhangfl 
-- ---------------------------------------
-- 数据引擎调用三方  预审等 可根据这个编码判断 req_product_grp_code
drop table if exists dw_base.tmp_dwd_sf_to_msg_log_ods_log;
commit;
create table dw_base.tmp_dwd_sf_to_msg_log_ods_log (
  msg_id varchar(32)  COMMENT '报文ID',
  cust_id varchar(32)  COMMENT '客户ID',
  msg_type varchar(20) ,
  req_msg longtext COMMENT '请求报文',
  req_user_id varchar(32)  COMMENT '请求用户ID',
  req_time timestamp(3) COMMENT '请求时间',
  req_channel varchar(20)  COMMENT '请求渠道',
  req_product_grp_code varchar(20)  COMMENT '请求产品组编码',
  res_msg longtext  COMMENT '应答报文',
  res_code varchar(10)  COMMENT '应答编码',
  res_time timestamp(3)  COMMENT '应答时间',
  creator varchar(64) COMMENT '创建者',
  create_time datetime  COMMENT '创建时间',
  updator varchar(64)  COMMENT '修改者',
  update_time datetime  COMMENT '修改时间'
) engine=innodb default charset=utf8mb4;
commit;
insert into dw_base.tmp_dwd_sf_to_msg_log_ods_log
select 
	msg_id 	, -- 报文ID
	cust_id	, -- 客户ID
	msg_type	, -- 
	req_msg	, -- 请求报文
	req_user_id	, -- 请求用户ID
	req_time	, -- 请求时间
	req_channel	, -- 请求渠道
	req_product_grp_code	, -- 请求产品组编码
	res_msg	, -- 应答报文
	res_code	, -- 应答编码
	res_time	, -- 应答时间
	creator	, -- 创建者
	create_time	, -- 创建时间
	updator	, -- 修改者
	update_time	 -- 修改时间
from dw_nd.ods_de_t_msg_log 
where update_time between date_format('${v_sdate}','%Y-%m-%d') 
and date_format(date_add('${v_sdate}', interval 1 day),'%Y-%m-%d')
;
commit; 
-- 三方报文日志表--外部请求数据引擎
DELETE FROM dw_base.dwd_sf_to_msg_log 
where update_time between date_format('${v_sdate}','%Y-%m-%d') 
and date_format(date_add('${v_sdate}', interval 1 day),'%Y-%m-%d')
;
commit; 

-- truncate table dw_base.dwd_sf_to_msg_log;
insert into dw_base.dwd_sf_to_msg_log 
(
day_id ,-- 数据日期
cust_id	, -- 客户ID
cust_type	, -- 
cust_name	, -- 客户名称
cert_no	, -- 证件号码
tel_no	, -- 手机号
channel	, -- 渠道
channel_cust_id	, -- 渠道客户ID
legal_name	, -- 企业法人名称
legal_cert_no	, -- 企业法人证件号码
c_creator	, -- 创建者
c_create_time	, -- 创建时间
c_updator	, -- 修改者
c_update_time	, -- 修改时间
seq_num	, -- 报文ID
s_cust_id	, -- 原系统客户ID
msg_type	, -- 
req_msg	, -- 请求报文
req_user_id	, -- 请求用户ID
req_time	, -- 请求时间
req_channel	, -- 请求渠道
req_product_grp_code	, -- 请求产品组编码
req_product_grp_name	, -- 请求产品组名称
res_msg	, -- 应答报文
res_code	, -- 应答编码
res_time	, -- 应答时间
creator	, -- 创建者
create_time	, -- 创建时间
updator	, -- 修改者
update_time	, -- 修改时间
dw_ins_dt	 -- 数仓插入日期
) 

select 
	'${v_sdate}' as day_id, 
	b.cust_id	, -- 客户ID
	b.cust_type	, -- 
	b.cust_name	, -- 客户名称
	b.cert_no	, -- 证件号码
	b.tel_no	, -- 手机号
	b.channel	, -- 渠道
	b.channel_cust_id	, -- 渠道客户ID
	b.legal_name	, -- 企业法人名称
	b.legal_cert_no	, -- 企业法人证件号码
	b.creator	, -- 创建者
	b.create_time	, -- 创建时间
	b.updator	, -- 修改者
	b.update_time	, -- 修改时间
	a.msg_id as seq_num	, -- 报文ID
	a.cust_id as s_cust_id	, -- 客户ID
	a.msg_type	, -- 
	a.req_msg	, -- 请求报文
	a.req_user_id	, -- 请求用户ID
	a.req_time	, -- 请求时间
	a.req_channel	, -- 请求渠道
	a.req_product_grp_code	, -- 请求产品组编码
	c.msg_desc , -- 请求产品组名称
	a.res_msg	, -- 应答报文
	a.res_code	, -- 应答编码
	a.res_time	, -- 应答时间
	a.creator	, -- 创建者
	a.create_time	, -- 创建时间
	a.updator	, -- 修改者
	a.update_time	, -- 修改时间
	now()  as dw_ins_dt-- 数仓插入日期
from dw_base.tmp_dwd_sf_to_msg_log_ods_log a
-- dw_nd.ods_de_t_msg_log a  
left join dw_base.dwd_cust_sf_info b on a.cust_id=b.s_cust_id
left join dw_base.dim_sf_msg_code c on a.req_product_grp_code=c.msg_code ;
commit; 
