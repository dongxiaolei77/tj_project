-- ---------------------------------------
-- 开发人   :  Wangyx
-- 开发时间 ： 20220809
-- 目标表   ： dwd_cust_comp_info 企业客户基本信息
-- 源表     ： dwd_cust_info
--             ods_crm_cust_comp_info
-- 变更记录 ：
-- ---------------------------------------


-- 创建临时表，获取企业及法人信息
drop table if exists dw_tmp.tmp_dwd_cust_comp_info_legal_ref ; commit;
CREATE TABLE dw_tmp.tmp_dwd_cust_comp_info_legal_ref (
cert_no                   varchar(50)     comment'证件号码'
,business_license_name     varchar(200)    comment'营业执照名称'
,comp_regist_dt            varchar(8)      comment'企业注册时间'
,reg_capt                  decimal(18,2)   comment'注册资本(万元）'
,comp_type                 varchar(2)      comment'企业类型1一般企业2个体工商户'
,operat_scope              varchar(1000)   comment'经营范围'
,reg_addr                  varchar(255)    comment'注册地址'
,legal_cert_type           varchar(50)     comment'法人代表证件类型'
,legal_cert_no             varchar(50)     comment'法人代表证件号'
,legal_name                varchar(50)     comment'法人代表名称'
,legal_tel                 varchar(20)     comment'法人手机号'
,index idx_tmp_dwd_cust_comp_info_legal_ref_cert_no (cert_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit;

insert into dw_tmp.tmp_dwd_cust_comp_info_legal_ref
(
cert_no
,business_license_name
,comp_regist_dt
,reg_capt
,comp_type
,operat_scope
,reg_addr
,legal_cert_type
,legal_cert_no
,legal_name
,legal_tel
)
select
 unified_social_credit_code
,business_license_name
,register_time
,register_capital
,comp_type
,business_scope
,business_address
,'10'
,legal_person_id_no
,legal_person_name
,legal_person_mobile
from(
	select
	unified_social_credit_code -- 统一社会信用代码
	,business_license_name
	,date_format(substr(register_time,1,10),'%Y%m%d')register_time
	,register_capital
	,case when comp_type = '一般企业' then '1' when comp_type = '个体工商户' then '2'  else null end comp_type
	,business_scope
	,business_address
	,legal_person_id_no
	,legal_person_name
	,legal_person_mobile
	,row_number() over(partition by unified_social_credit_code order by update_time desc) as rk
from dw_nd.ods_crm_cust_comp_info
where date_format(update_time,'%Y%m%d') <= '${v_sdate}'
) t
where rk = 1
;
commit;


-- 企业信息补充
drop table if exists dw_tmp.tmp_dwd_cust_comp_info_legal_ref_add ; commit;
CREATE TABLE dw_tmp.tmp_dwd_cust_comp_info_legal_ref_add (
cert_no                   varchar(50)     comment'证件号码'
,reg_addr                  varchar(255)    comment'注册地址'
,legal_cert_type           varchar(50)     comment'法人代表证件类型'
,legal_cert_no             varchar(50)     comment'法人代表证件号'
,legal_name                varchar(50)     comment'法人代表名称'
,index idx_tmp_dwd_cust_comp_info_legal_ref_add_cert_no (cert_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit;

insert into dw_tmp.tmp_dwd_cust_comp_info_legal_ref_add
(
cert_no
,reg_addr
,legal_cert_type
,legal_cert_no
,legal_name
)
select
id_no as cert_no
,comp_address as reg_addr
,'10' as legal_cert_type
,legal_representative_id_no as legal_cert_no
,legal_representative_name as legal_name
from
(
	select
	id_no
	,cust_type
	,legal_representative_name
	,legal_representative_id_no
	,comp_address
	from
	(
		select
		id_no
		,cust_type
		,legal_representative_name
		,legal_representative_id_no
		,comp_address
		,row_number() over(partition by id_no order by create_time desc) as rk
		from dw_nd.ods_crm_cust_certification_info
		where date_format(update_time,'%Y%m%d') <= '20220907'
		and cust_type = '02'
		and( legal_representative_id_no is not null or comp_address is not null or legal_representative_name is not null )
	) t
	where rk = 1
) t1
;
commit;


-- 数据汇总进入目标表

truncate table dw_base.dwd_cust_comp_info ; commit; 

insert into dw_base.dwd_cust_comp_info 
(
day_id                   -- 数据日期                        
,cust_id                 -- 客户号                         
,cust_name               -- 客户姓名                        
,cert_type               -- 证件类型 10--身份证 21--统一社会信用编码   
,cert_no                 -- 证件号码                        
,business_license_name   -- 营业执照名称                      
,comp_regist_dt          -- 企业注册时间                      
,reg_capt                -- 注册资本(万元）                    
,comp_type               -- 企业类型 1 一般企业 2 个体工商户         
,operat_scope            -- 经营范围                        
,reg_addr                -- 注册地址                        
,tax_nation_no           -- 税务登记证号（国税）                  
,tax_city_no             -- 税务登记证号（地税）                  
,legal_cert_type         -- 法人代表证件类型                    
,legal_cert_no           -- 法人代表证件号                     
,legal_name              -- 法人代表名称                      
,legal_tel               -- 法人手机号                       
,regist_dt               -- 注册日期                        
,data_source             -- 数据来源 01--小程序 02--线下台账 03--预审
)
select
'${v_sdate}'
,t1.cust_id
,t1.cust_name
,t1.cert_type
,t1.cert_no
,t2.business_license_name
,t2.comp_regist_dt
,t2.reg_capt
,t2.comp_type
,t2.operat_scope
,coalesce(t2.reg_addr,t3.reg_addr) as reg_addr
,NULL as tax_nation_no
,NULL as tax_city_no
,coalesce(t2.legal_cert_type,t3.legal_cert_type) as legal_cert_type
,coalesce(t2.legal_cert_no,t3.legal_cert_no) as legal_cert_no
,coalesce(t2.legal_name,t3.legal_name) as legal_name
,t2.legal_tel
,t1.regist_dt
,t1.data_source
from dw_base.dwd_cust_info t1  
left join dw_tmp.tmp_dwd_cust_comp_info_legal_ref t2
on t1.cert_no = t2.cert_no
left join dw_tmp.tmp_dwd_cust_comp_info_legal_ref_add t3
on t1.cert_no = t3.cert_no
where t1.cust_type = 'C'
;
commit;