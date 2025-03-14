-- ---------------------------------------
-- 开发人   :  
-- 开发时间 ： 
-- 目标表   ： dw_base.dwd_cust_info_offline_init 线下客户数据初始化
-- 源表     ： dw_base.dwd_guar_info_all
--             dw_nd.ods_imp_econ_coop

-- 变更记录 ：20241201 脚本的统一变更，MySQL5.0转MySQL8.0 zhangfl 
-- ---------------------------------------
-- 线下客户数据初始化(只在上线时跑一次)

drop table if exists dw_base.dwd_cust_info_offline_init ; commit;
CREATE TABLE dw_base.dwd_cust_info_offline_init (
day_id       varchar(8)   comment'数据日期'                     
,cust_id      varchar(30)  comment'客户号'                      
,cust_type    varchar(2)   comment'客户类型（P个人/C企业）'            
,cust_name    varchar(500) comment'客户姓名'                     
,cert_type    varchar(2)   comment'证件类型（10-身份证 21-统一社会信用编码）'
,cert_no      varchar(50)  comment'证件号码'                     
,tel_no       varchar(50)  comment'手机号'                      
,regist_dt    varchar(8)   comment'注册日期'                       
,index idx_dwd_cust_info_offline_cust_id (cust_id)
,index idx_dwd_cust_info_offline_cert_no (cert_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin comment'线下客户数据初始化';
commit;


-- dwd_guar_info_all中所有
insert into dw_base.dwd_cust_info_offline_init
(
day_id
,cust_id
,cust_type
,cust_name
,cert_type
,cert_no
,tel_no
,regist_dt
)
select
'${v_sdate}'
,cust_id
,cust_type
,cust_name
,cert_type
,cert_no
,tel_no
,create_dt as regist_dt
from(
	select
	coalesce(cust_id,concat(cert_type,cert_no)) as cust_id
	,cust_type
	,cust_name
	,cert_type
	,cert_no
	,tel_no
	,create_dt
	from(
		select
		cust_id
		,case when cust_type = '自然人' then 'P'
					when cust_type = '法人或其他组织' then 'C'
				else cust_type end as cust_type
		,cust_name
		,case when substr(cert_no,1,2) in ('90','91','92','93','N1','N2','G1','	9') then '21'
				else '10' end as cert_type 
		,cert_no
		,tel_no
		,create_dt
		,row_number()over(partition by cert_no order by create_dt desc) rn
		from dw_base.dwd_guar_info_all
	) t
	where rn = 1
) t1

;
commit;


-- 经济合作社
insert into dw_base.dwd_cust_info_offline_init
(
day_id
,cust_id
,cust_type
,cust_name
,cert_type
,cert_no
,tel_no
,regist_dt
)
select
'${v_sdate}'
,concat(21,credit_code) as cust_id
,'C' as cust_type
,ent_name as cust_name
,'21' as cert_type
,credit_code as cert_no
,fr_mobile as tel_no
,date_format(create_time,'%Y%m%d') as regist_dt
from dw_nd.ods_imp_econ_coop t1
where t1.credit_code not in (select cert_no from dw_base.dwd_cust_info_offline_init)
;
commit;