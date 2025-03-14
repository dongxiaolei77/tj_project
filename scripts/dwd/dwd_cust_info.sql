-- ---------------------------------------
-- 开发人   :  Wangyx
-- 开发时间 ： 20220809
-- 目标表   ： dwd_cust_info 客户基本信息
-- 源表     ： dwd_cust_login_info
--             ods_t_sdnd_credit_log
--             dwd_cust_info_ref_offline
-- 变更记录 ：
-- ---------------------------------------


-- 创建临时表，获取预审客户基本信息

drop table if exists dw_tmp.tmp_dwd_cust_info_ref_credit ;
commit;

CREATE TABLE dw_tmp.tmp_dwd_cust_info_ref_credit (
cust_id      varchar(50)  comment'客户号'                      
,cust_type    varchar(2)   comment'客户类型（P个人/C企业）'            
,cust_name    varchar(500) comment'客户姓名'                     
,cert_type    varchar(2)   comment'证件类型（10-身份证 21-统一社会信用编码）'
,cert_no      varchar(50)  comment'证件号码'                     
,tel_no       varchar(50)  comment'手机号'                      
,regist_dt    varchar(8)   comment'注册日期'                       
,index idx_tmp_dwd_cust_info_ref_offline_cust_id (cust_id)
,index idx_tmp_dwd_cust_info_ref_offline_cert_no (cert_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

insert into dw_tmp.tmp_dwd_cust_info_ref_credit
(
cust_id
,cust_type
,cust_name
,cert_type
,cert_no
,tel_no
,regist_dt
)
select
concat(cust_id_type,cust_id_no) as cust_id
,cust_type
,cust_name
,cust_id_type
,cust_id_no
,cust_mobile
,date_format(create_time,'%Y%m%d') as regist_dt 
from(
	select
	cust_id
	,case when cust_type = '01' then 'P'
				when cust_type in ('02','03') then 'C'
				else cust_type end as cust_type
	,cust_name
	,case when cust_id_type = '01' then '10'
				when cust_id_type = '02' then '21'
				else cust_id_type end as cust_id_type
	,cust_id_no
	,cust_mobile
	,create_time
	from(
		select
		cust_id
		,cust_type
		,cust_name
		,cust_id_type
		,cust_id_no
		,cust_mobile
		,create_time
		from(
			select
			log_id
			,cust_id
			,cust_type
			,cust_name
			,cust_id_type
			,cust_id_no
			,cust_mobile
			,create_time
			,row_number() over(partition by cust_id_no order by update_time desc) as rk
			from dw_nd.ods_t_sdnd_credit_log
			where date_format(update_time,'%Y%m%d') <= '${v_sdate}'
		) t
		where rk = 1
	) t1
) t2
;
commit;



-- 目标表全量更新

truncate table dw_base.dwd_cust_info ; commit; 


-- 小程序
insert into dw_base.dwd_cust_info 
(
day_id
,cust_id
,cust_type
,cust_name
,cert_type
,cert_no
,tel_no
,regist_dt
,data_source
)
select
'${v_sdate}'
,cust_id
,login_type
,cust_name
,case when cert_no is not null then cert_type else null end cert_type
,cert_no
,case when login_no REGEXP('^[0-9]+' ) = 1 then login_no else '' end tel_no
,regist_dt
,'01'
from
(
select
cust_id
,login_type
,cust_name
,cert_type
,cert_no
,login_no
,regist_dt
,row_number() over(partition by cert_no order by regist_dt desc) as rk
from dw_base.dwd_cust_login_info  
) t
where rk = 1
;
commit ;


-- 预审
insert into dw_base.dwd_cust_info
(
day_id
,cust_id
,cust_type
,cust_name
,cert_type
,cert_no
,tel_no
,regist_dt
,data_source
)
select
'${v_sdate}'
,cust_id
,cust_type
,cust_name
,case when cert_no is not null then cert_type else null end cert_type
,cert_no
,tel_no
,regist_dt
,'03'
from dw_tmp.tmp_dwd_cust_info_ref_credit t1  -- 预审客户基本信息
where not exists (
	select 1 from dw_base.dwd_cust_info t2 
	where t1.cert_no = t2.cert_no  
)
;
commit ;


-- 线下台账
insert into dw_base.dwd_cust_info
(
day_id
,cust_id
,cust_type
,cust_name
,cert_type
,cert_no
,tel_no
,regist_dt
,data_source
)
select
'${v_sdate}'
,cust_id
,cust_type
,cust_name
,cert_type
,cert_no
,tel_no
,regist_dt
,'02'
from dw_base.dwd_cust_info_offline_init t1
where not exists (
	select 1 from dw_base.dwd_cust_info t2  
	where t1.cert_no = t2.cert_no
)
;
commit ;