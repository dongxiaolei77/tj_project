-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_cust_sf_info 三方查询客户流水表 
-- 源表     ：dw_nd.ods_de_t_cust_info 客户信息表
--            dw_base.dwd_cust_info 客户基本信息表
-- 变更记录 ：20220117：统一变动   
--            20220516 日志变量注释  xgm
--            20241201 脚本的统一变更，MySQL5.0转MySQL8.0 zhangfl 
-- ---------------------------------------

-- 三方客户表  关联客户信息 
truncate  table  dw_base.dwd_cust_sf_info ;commit;
insert into dw_base.dwd_cust_sf_info 
(
day_id	, -- 数据日期
cust_id	, -- 客户ID
cust_type	, -- 
cust_name	, -- 客户名称
cert_no	, -- 证件号码
tel_no	, -- 手机号
channel	, -- 渠道
channel_cust_id	, -- 渠道客户ID
legal_name	, -- 企业法人名称
legal_cert_no	, -- 企业法人证件号码
creator	, -- 创建者
create_time	, -- 创建时间
updator	, -- 修改者
update_time	, -- 修改时间
s_cust_id , -- 原系统客户ID
dw_ins_dt	 -- 数仓插入日期
)

select  
'${v_sdate}' as day_id,
case when b.cust_id is null and a.cust_type='01' then CONCAT('10',a.id_no) when   b.cust_id is null and a.cust_type='02' then CONCAT('21',a.id_no) when b.cust_id is not null then b.cust_id else '' end as cust_id	, -- 客户ID
a.cust_type	, -- 
a.cust_name	, -- 客户名称
a.id_no	, -- 证件号码
a.mobile	, -- 手机号
a.channel	, -- 渠道
a.channel_cust_id	, -- 渠道客户ID
a.legal_name	, -- 企业法人名称
a.legal_id_no	, -- 企业法人证件号码
a.creator	, -- 创建者
a.create_time	, -- 创建时间
a.updator	, -- 修改者
a.update_time	, -- 修改时间
a.cust_id	, -- 原系统客户ID
now()  as dw_ins_dt-- 数仓插入日期

from ( 
select 
a.cust_type	, -- 
a.cust_name	, -- 客户名称
a.id_no	, -- 证件号码
a.mobile	, -- 手机号
a.channel	, -- 渠道
a.channel_cust_id	, -- 渠道客户ID
a.legal_name	, -- 企业法人名称
a.legal_id_no	, -- 企业法人证件号码
a.creator	, -- 创建者
a.create_time	, -- 创建时间
a.updator	, -- 修改者
a.update_time	, -- 修改时间
a.cust_id	 -- 原系统客户ID

from ( 
	select  cust_type	
			,cust_name	 
			,id_no	 
			,mobile	 
			,channel	 
			,channel_cust_id	
			,legal_name	
			,legal_id_no 
			,creator	
			,create_time	 
			,updator	
			,update_time 
			,cust_id
			,row_number()over(partition by a.cust_id order by update_time desc ) rn
	from   dw_nd.ods_de_t_cust_info a 
	where a.id_no is not null and a.id_no<> ''  
	and  date_format(update_time,'%Y%m%d') <= '${v_sdate}'
	) a  
	where rn = 1  ) a
left join dw_base.dwd_cust_info  b 
on a.id_no=b.cert_no  
where a.cust_name is not null and a.cust_name <>''
;
commit;
