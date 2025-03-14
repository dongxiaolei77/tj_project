-- ---------------------------------------
-- 开发人   :  Wangyx
-- 开发时间 ： 20220824
-- 目标表   ： dwd_cust_ref_info 客户社会关系
-- 源表     ： dwd_cust_info
--             ods_crm_cust_per_ralation
--             ods_bizhall_guar_apply
-- 变更记录 ：
-- ---------------------------------------


-- 创建临时表，获取客户关系人（子女）信息

drop table if exists dw_tmp.tmp_dwd_cust_ref_info_crm_ref ; commit;
CREATE TABLE dw_tmp.tmp_dwd_cust_ref_info_crm_ref (
cust_id          varchar(50)  comment'客户号'
,ref_type        varchar(2)   comment'关系类型：1-配偶 2-子女 3-父母 4-其他'
,ref_name        varchar(30)  comment'关系人姓名'
,ref_cert_type   varchar(2)   comment'关系人证件类型：10-身份证 21-统一社会信用编码'
,ref_cert_no     varchar(50)  comment'关系人证件号码'
,index idx_tmp_dwd_cust_ref_info_crm_ref_cust_id (cust_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit;

insert into dw_tmp.tmp_dwd_cust_ref_info_crm_ref
(
cust_id
,ref_type
,ref_name
,ref_cert_type
,ref_cert_no
)
select
cust_code
,'2' as ref_type
,ref_name
,'10' as ref_cert_type
,max(ref_id_no) as ref_cert_no
from(
	select
	cust_code
	,ref_name
	,ref_id_no
	,ref_id_type
	from(
		select
		id
		,cust_code
		,ref_name
		,ref_id_no
		,ref_id_type
		,row_number() over(partition by id order by update_time desc) as rk
		from
		dw_nd.ods_crm_cust_per_ralation
		where date_format(update_time,'%Y%m%d') <= '${v_sdate}'
		and cust_code is not null 
		and (ref_name is not null or ref_id_no is not null )
	) t
	where rk = 1
) t1
group by cust_code,ref_name
;
commit;



-- 创建临时表，获取客户关系人（配偶）信息

drop table if exists dw_tmp.tmp_dwd_cust_ref_info_spouse ; commit;
CREATE TABLE dw_tmp.tmp_dwd_cust_ref_info_spouse (
cert_no          varchar(50)  comment'客户证件号'
,ref_type        varchar(2)   comment'关系类型：1-配偶 2-子女 3-父母 4-其他'
,ref_name        varchar(30)  comment'关系人姓名'
,ref_cert_type   varchar(2)   comment'关系人证件类型：10-身份证 21-统一社会信用编码'
,ref_cert_no     varchar(50)  comment'关系人证件号码'
,index idx_tmp_dwd_cust_ref_inf_spouse_cert_no (cert_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit;

insert into dw_tmp.tmp_dwd_cust_ref_info_spouse
(
cert_no
,ref_type
,ref_name
,ref_cert_type
,ref_cert_no
)
select
cust_id_no
,'1' as ref_type
,bank_part_name
,'10' as ref_cert_type
,bank_part_id_no
from
(
select
cust_id_no
,bank_part_name
,bank_part_id_no
,row_number() over(partition by cust_id_no order by update_time desc) as rk
from dw_nd.ods_bizhall_guar_apply
where bank_part_type = '1'
and date_format(update_time,'%Y%m%d') <= '${v_sdate}'
and cust_id_no is not null 
and (bank_part_name is not null or bank_part_id_no is not null )
) t
where rk = 1
;
commit;


truncate table dw_base.dwd_cust_ref_info ; commit;

insert into dw_base.dwd_cust_ref_info 
(
day_id          -- 数据日期                      
,cust_id        -- 客户号                       
,cust_name      -- 客户姓名                      
,cert_no        -- 证件号码                      
,ref_type       -- 关系类型：1-配偶 2-子女 3-父母 4-其他  
,ref_name       -- 关系人姓名                     
,ref_cert_type  -- 关系人证件类型：10-身份证 21-统一社会信用编码
,ref_cert_no    -- 关系人证件号码  
,ref_tel_no     -- 关系人手机号                    
)
select
'${v_sdate}'
,t1.cust_id
,t1.cust_name
,t1.cert_no
,t2.ref_type
,t2.ref_name
,case when t2.ref_cert_no is not null then t2.ref_cert_type else null end ref_cert_type
,t2.ref_cert_no
,null as ref_tel_no
from dw_base.dwd_cust_info t1  
inner join dw_tmp.tmp_dwd_cust_ref_info_crm_ref t2
on t1.cust_id = t2.cust_id

union all

select
'${v_sdate}'
,t1.cust_id
,t1.cust_name
,t1.cert_no
,t2.ref_type
,t2.ref_name
,case when t2.ref_cert_no is not null then t2.ref_cert_type else null end ref_cert_type
,t2.ref_cert_no
,null as ref_tel_no
from dw_base.dwd_cust_info t1 
inner join dw_tmp.tmp_dwd_cust_ref_info_spouse t2
on t1.cert_no = t2.cert_no
;
commit;