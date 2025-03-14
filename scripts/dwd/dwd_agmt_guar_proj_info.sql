-- ---------------------------------------
-- 开发人   : liyy
-- 开发时间 ：20210311
-- 目标表   :  dwd_agmt_guar_proj_info
-- 源表     ：
--            dw_nd.ods_t_risk_check_opinion      风险审查意见表
--            dw_nd.ods_t_sys_data_dict_value_v2  数据字典值表
--            dw_nd.ods_t_biz_project_main        主项目表
--            dw_nd.ods_t_biz_proj_sign           项目签约表

-- 变更记录 ：20210422 业务系统放款信息表中只有 本次放款日、本次到期日, 放款日期 部分迁移后没有数据，需要取历史的数据 dwd_guar_info 放款时间、到期时间
--            20211011 1.增加保后检查已终止数据 2.自主续支        
--            20220211统一修改
--            20220928 数据有超出范围
--            20230220 ods_t_biz_project_main 表里面部分数据的产品代码为中文，关联字典表转译为码值 zhangfl
--            20241201 脚本的统一变更，MySQL5.0转MySQL8.0并优化逻辑 zhangfl 
-- ---------------------------------------
set interactive_timeout = 7200;
set wait_timeout = 7200;

-- -------------------------------
-- 1. 20211104 担保产品 风险审查意见表
drop table if exists dw_tmp.tmp_dwd_agmt_guar_proj_info_riskopinion ;
commit;
create  table dw_tmp.tmp_dwd_agmt_guar_proj_info_riskopinion (
 proj_id	varchar(100)                      -- 项目
,guar_prod    varchar(20)                          -- 担保产品 
,index(proj_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit;

insert into dw_tmp.tmp_dwd_agmt_guar_proj_info_riskopinion
select 
project_id
,guar_product
from 
(
select 
project_id
,guar_product
,update_time
,row_number()over(partition by project_id order by update_time desc) rn
from dw_nd.ods_t_risk_check_opinion
 where date_format(update_time,'%Y%m%d') <= '${v_sdate}'  -- 新增
) t 
where guar_product is not null
and t.rn = 1 
;
commit;

-- 2.新增产品类型的码值临时表  20230220 zhangfl
drop table if exists dw_tmp.tmp_dwd_agmt_guar_proj_info_prod_dict;
commit;
create table if not exists dw_tmp.tmp_dwd_agmt_guar_proj_info_prod_dict
(  code varchar(100) ,
   value varchar(1024) 
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;

insert into dw_tmp.tmp_dwd_agmt_guar_proj_info_prod_dict
(code,
 value
 )
select code,value 
from
(
	select id,code,value,row_number()over(partition by id order by update_time desc) rn
	from dw_nd.ods_t_sys_data_dict_value_v2
	where dict_code = 'productWarranty'
) a 
where a.rn = 1
;
commit;


-- 3.业务信息表--进件
drop table if exists dw_tmp.tmp_dwd_agmt_guar_proj_info_main ;
commit;

create  table dw_tmp.tmp_dwd_agmt_guar_proj_info_main (
proj_id	varchar(100)                   -- 项目ID
,proj_no	varchar(60)                    -- 项目编号
,wf_id	varchar(60)                    -- 工作流实例id
,source	varchar(60)                    -- 项目来源
,province_cd	varchar(60)                -- 所属省份
,city_cd	varchar(60)                    -- 所属地市
,district_cd	varchar(60)                -- 所属区县
,guar_class_cd	varchar(60)            -- 国家农担分类
,econ_class_cd	varchar(60)            -- 国民经济分类
,main_busi	varchar(500)               -- 经营主业
,proj_type_cd	varchar(2)             -- 项目分类 01 首保项目、02 续保项目、 03 续保增额
,proj_cata_cd	varchar(2)             -- 项目类型 01 产业集群\产业链、02 普通项目、03 灾后重建
,main_type_cd	varchar(2)             -- 主体类型 01 自然人、02 法人
,cust_type_cd	varchar(20)             -- 客户类型 01 家庭农场、02 种养大户、03 农民合作社
,cust_id	varchar(60)                    -- 客户id，后续关联到CRM
,cust_name	varchar(100)               -- 客户名称
,cert_no	varchar(50)                    -- 身份证\统一社会信用码
,tel_no	varchar(50)                    -- 客户手机号
,appl_amt	decimal(18,6)              -- 申保金额
,appl_term	int                        -- 申保期限
,oppos_guar_cd	varchar(30)            -- 申保反担保措施
,oppos_guar_desc	varchar(5000)          -- 申保反担保措施说明
,guar_prod_cd	varchar(16)            -- 担保产品
,guar_type	varchar(2)                 -- 担保方式: 01 一般保证、02 连带责任保证
,clus_scheme_cd	varchar(1000)            -- 集群方案：项目类型为产业集群时，数据字典
,loan_type	varchar(2)                 -- 贷款方式：01 普通贷款、02 循环贷（随借随还）
,repay_type	varchar(2)                 -- 还款方式:普通贷款时，必填。分期付息到期还本、利随本清、等额本金、等额本息
,loan_rate	decimal(10,6)              -- 贷款年利率
,loan_use	varchar(1000)              -- 借款用途
,is_first_loan	int                    -- 是否首贷，1是，0否
,is_first_guar	int                    -- 是否首保 1是 0否
,is_supp_poor	int                    -- 是否扶贫 1是，0否
,loan_bank	varchar(50)                -- 贷款银行全称(合同章)
,handle_bank	varchar(50)                -- 经办行(支行/部门)
,bank_mgr_id	varchar(64)                -- 银行客户经理ID
,bank_mgr_name	varchar(20)            -- 银行客户经理名称
,bank_mgr_tel	varchar(20)            -- 银行客户经理联系方式
,bank_mgr_cert_no varchar(50)            -- 银行客户经理身份证号
,pre_aprv_id	varchar(60)                -- 预审编号
,pre_aprv_result	varchar(6)             -- 预审结果，1通过，-1不通过
,version	int                            -- 版本
,is_del	int                            -- 是否删除:1-删除，0-未删除
,proj_stt	varchar(2)                 -- 项目状态：00-提报中，02-审批中。。。
,proj_orig	varchar(2)                 -- 项目数据来源：01-担保业务系统，02-迁移数据
,create_dt	date                       -- 项目创建日期
,update_dt	date                       -- 最近一次更新时间
,submit_dt  date                       -- 提报时间

,appl_id varchar(100) -- 申请id
,cust_addr varchar(255) -- 客户通讯地址
,cust_email varchar(200) -- 客户邮件地址
,mrg_stt varchar(4) -- 婚姻状态
,spouse_name varchar(100) -- 配偶姓名
,spouse_cert_no varchar(50) -- 配偶证件号码
,is_together_debt varchar(1) -- 是否共同借款人
,is_sign_online varchar(1) -- 是否线上签约

,index(proj_no)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;

commit;

insert into dw_tmp.tmp_dwd_agmt_guar_proj_info_main
select 
id	                        -- 主键自增
,code	                    -- 业务编号
,wf_inst_id	                -- 工作流实例id
,source	                    -- 项目来源
,province	                -- 所属省份
,city	                    -- 所属地市
,district	                -- 所属区县
,national_guar_type	        -- 国家农担分类
,national_econ_type	        -- 国民经济分类
,main_business	            -- 经营主业
,proj_type	                -- 项目分类 01 首保项目、02 续保项目、 03 续保增额
,proj_catagory	            -- 项目类型 01 产业集群\产业链、02 普通项目、03 灾后重建
,main_type	                -- 主体类型 01 自然人、02 法人
,cust_type	                -- 客户类型 01 家庭农场、02 种养大户、03 农民合作社
,cust_id	                -- 客户id，后续关联到CRM
,cust_name	                -- 客户名称
,cust_identity_no	        -- 身份证\统一社会信用码
,cust_mobile	            -- 客户手机号
,apply_amount	            -- 申保金额
,apply_period	            -- 申保期限
,apply_counter_guar_meas	-- 申保反担保措施
,apply_counter_guar_desc	-- 申保反担保措施说明
,guar_product	            -- 担保产品，从字典获取
,guar_type	                -- 担保方式: 01 一般保证、02 连带责任保证
,aggregate_scheme	        -- 集群方案：项目类型为产业集群时，数据字典
,loan_type	                -- 贷款方式：01 普通贷款、02 循环贷（随借随还）
,loan_repay_type	        -- 还款方式:普通贷款时，必填。分期付息到期还本、利随本清、等额本金、等额本息
,loan_rate	                -- 贷款年利率
,money_purpose	            -- 借款用途
,is_first_loan	            -- 是否首贷，1是，0否
,is_first_maintenance	    -- 是否首保 1是 0否
,is_poverty_relief	        -- 是否扶贫 1是，0否
,loans_bank	                -- 贷款银行全称(合同章)
,handles_bank	            -- 经办行(支行/部门)
,bank_cust_manager_id	    -- 银行客户经理ID
,bank_cust_manager_name	    -- 银行客户经理名称
,bank_cust_manager_mobile	-- 银行客户经理联系方式
,bank_cust_manager_id_no
,pre_trial_code	            -- 预审编号
,pre_trial_result	        -- 预审结果，1通过，-1不通过
,version	                -- 版本
,is_delete	                -- 是否删除:1-删除，0-未删除
,proj_status	            -- 项目状态：00-提报中，02-审批中。。。
,proj_origin	            -- 项目数据来源：01-担保业务系统，02-迁移数据
,create_time	                -- 项目创建日期
,update_time
,submit_time

,apply_id   -- 申请id
,cust_addr   -- 客户通讯地址
,cust_email   -- 客户邮件地址
,marital_status   -- 婚姻状态
,spouse_name  -- 配偶姓名
,spouse_id_no   -- 配偶证件号码
,spouse_co_borrower   -- 是否共同借款人
,is_sign_online   -- 是否线上签约
from 
(
select 
id	                        -- 主键自增
,code	                    -- 业务编号
,wf_inst_id	                -- 工作流实例id
,case when source in ('银行直报' ,'1')	then '02'                    -- 项目来源
      when source in ('2')	then '01'
	  else source end source
,province	                -- 所属省份
,city	                    -- 所属地市
,district	                -- 所属区县
,national_guar_type	        -- 国家农担分类
,national_econ_type	        -- 国民经济分类
,main_business	            -- 经营主业
,case when proj_type ='续保项目' then '02'
      when proj_type ='首保项目' then '01'
	  when proj_type ='续保增额' then '03'
	  else proj_type
	  end proj_type -- 项目分类 01 首保项目、02 续保项目、 03 续保增额 04	续支项目
,proj_catagory	            -- 项目类型 01 产业集群\产业链、02 普通项目、03 灾后重建
,main_type	                -- 主体类型 01 自然人、02 法人
,case when cust_type ='龙头企业' then '06' else 	 cust_type end cust_type               -- 客户类型 01 家庭农场、02 种养大户、03 农民合作社
,cust_id	                -- 客户id，后续关联到CRM
,cust_name	                -- 客户名称
,cust_identity_no	        -- 身份证\统一社会信用码
,cust_mobile	            -- 客户手机号
,apply_amount	            -- 申保金额
,apply_period	            -- 申保期限
,apply_counter_guar_meas	-- 申保反担保措施
,apply_counter_guar_desc	-- 申保反担保措施说明
,guar_product	            -- 担保产品，从字典获取
,guar_type	                -- 担保方式: 01 一般保证、02 连带责任保证
,aggregate_scheme	        -- 集群方案：项目类型为产业集群时，数据字典
,case when loan_type= '循环贷' then '02'  	
      when loan_type= '普通贷款' then '01'
      else loan_type end   loan_type              -- 贷款方式：01 普通贷款、02 循环贷（随借随还）
,loan_repay_type	        -- 还款方式:普通贷款时，必填。分期付息到期还本、利随本清、等额本金、等额本息
,loan_rate	                -- 贷款年利率
,money_purpose	            -- 借款用途
,is_first_loan	            -- 是否首贷，1是，0否
,is_first_maintenance	    -- 是否首保 1是 0否
,is_poverty_relief	        -- 是否扶贫 1是，0否
,loans_bank	                -- 贷款银行全称(合同章)
,handles_bank	            -- 经办行(支行/部门)
,bank_cust_manager_id	    -- 银行客户经理ID
,bank_cust_manager_name	    -- 银行客户经理名称
,bank_cust_manager_mobile	-- 银行客户经理联系方式
,bank_cust_manager_id_no
,pre_trial_code	            -- 预审编号
,pre_trial_result	        -- 预审结果，1通过，-1不通过
,version	                -- 版本
,is_delete	                -- 是否删除:1-删除，0-未删除
,proj_status	            -- 项目状态：00-提报中，02-审批中。。。
,proj_origin	            -- 项目数据来源：01-担保业务系统，02-迁移数据
,create_time
,update_time
,submit_time

,apply_id   -- 申请id
,cust_addr   -- 客户通讯地址
,cust_email   -- 客户邮件地址
,marital_status   -- 婚姻状态
,spouse_name  -- 配偶姓名
,spouse_id_no   -- 配偶证件号码
,spouse_co_borrower   -- 是否共同借款人
,is_sign_online   -- 是否线上签约

,db_update_time
,row_number()over(partition by code order by db_update_time desc) rn
from dw_nd.ods_t_biz_project_main
 where date_format(db_update_time,'%Y%m%d') <= '${v_sdate}' -- 新增
) t1
where t1.rn = 1
;
commit ;

-- 4.签约信息
drop table if exists dw_tmp.tmp_dwd_agmt_guar_proj_info_sign ;
commit;
create  table dw_tmp.tmp_dwd_agmt_guar_proj_info_sign (
proj_id        varchar(100)
,loan_cont_id	varchar(200)    -- 借款合同编号
,loan_cont_amt	decimal(10,6)    -- 借款合同金额(万元)
,loan_cont_term	int            -- 借款合同期限(月)
,loan_cont_beg_dt	date       -- 借款合同开始日
,loan_cont_end_dt	date       -- 借款合同到期日
,loan_cont_rate	decimal(10,6)  -- 借款合同年化利率
,is_sign_max_guar	int        -- 是否已签订最高额度保证合同 1是 0 否
,guar_cont_id	varchar(300)    -- 单笔保证合同编号
,index(proj_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit;

insert into dw_tmp.tmp_dwd_agmt_guar_proj_info_sign 
select
project_id
,jk_contr_code	        -- 借款合同编号
,jk_contr_amount	        -- 借款合同金额(万元)
,jk_ctrct_term	        -- 借款合同期限(月)
,jk_ctrct_start_date	    -- 借款合同开始日
,jk_ctrct_end_date	    -- 借款合同到期日
,jk_ctrct_interest_rate	-- 借款合同年化利率
,is_sign_max_guar_ctrct	-- 是否已签订最高额度保证合同 1是 0 否
,single_guar_ctrct_code	-- 单笔保证合同编号
from
(
select
project_id
,jk_contr_code	        -- 借款合同编号
,jk_contr_amount	        -- 借款合同金额(万元)
,jk_ctrct_term	        -- 借款合同期限(月)
,DATE_FORMAT(jk_ctrct_start_date,'%Y-%m-%d')	jk_ctrct_start_date    -- 借款合同开始日
,DATE_FORMAT(jk_ctrct_end_date,'%Y-%m-%d')	    jk_ctrct_end_date -- 借款合同到期日
,case when jk_ctrct_interest_rate >	100 then 0 else jk_ctrct_interest_rate end jk_ctrct_interest_rate -- 借款合同年化利率
,is_sign_max_guar_ctrct	-- 是否已签订最高额度保证合同 1是 0 否
,single_guar_ctrct_code	-- 单笔保证合同编号
,update_time
,db_update_time
,row_number()over(partition by project_id order by db_update_time desc) rn
from dw_nd.ods_t_biz_proj_sign
 where date_format(db_update_time,'%Y%m%d') <= '${v_sdate}'   -- 新增
) t1
where t1.rn = 1
;
commit ;

-- 5.数据落地
truncate  table  dw_base.dwd_agmt_guar_proj_info;
commit ;

-- 担保项目信息
insert into dw_base.dwd_agmt_guar_proj_info
select
'${v_sdate}'
,t1.proj_id
,t1.proj_no
,t1.wf_id
,t1.source
,t1.province_cd
,t1.city_cd
,t1.district_cd
,t1.guar_class_cd
,t1.econ_class_cd
,t1.main_busi
,t1.proj_type_cd
,t1.proj_cata_cd
,t1.main_type_cd
,t1.cust_type_cd
,t1.cust_id
,t1.cust_name
,t1.cert_no
,t1.tel_no
,case when t1.appl_amt>=10000 then t1.appl_amt/10000 else t1.appl_amt end -- mdy 20220928
,t1.appl_term
,t1.oppos_guar_cd
,t1.oppos_guar_desc
,coalesce(t3.guar_prod,t4.code,t1.guar_prod_cd) -- 20211104 |  20230220
,t1.guar_type
,t1.clus_scheme_cd
,t1.loan_type
,t1.repay_type
,t1.loan_rate
,t1.loan_use
,t1.is_first_loan
,t1.is_first_guar
,t1.is_supp_poor
,t1.loan_bank
,t1.handle_bank
,t1.bank_mgr_id
,t1.bank_mgr_name
,t1.bank_mgr_tel
,t1.bank_mgr_cert_no
,t1.pre_aprv_id
,t1.pre_aprv_result
,t1.version
,t1.is_del
,t1.proj_stt
,t1.proj_orig
,t2.loan_cont_id
,t2.loan_cont_amt
,t2.loan_cont_term
,t2.loan_cont_beg_dt
,t2.loan_cont_end_dt
,t2.loan_cont_rate
,t2.is_sign_max_guar
,t2.guar_cont_id
,t1.create_dt
,t1.update_dt
,t1.submit_dt
,t1.appl_id   -- 申请id
,t1.cust_addr   -- 客户通讯地址
,t1.cust_email   -- 客户邮件地址
,t1.mrg_stt   -- 婚姻状态
,t1.spouse_name  -- 配偶姓名
,t1.spouse_cert_no   -- 配偶证件号码
,t1.is_together_debt   -- 是否共同借款人
,t1.is_sign_online   -- 是否线上签约
from dw_tmp.tmp_dwd_agmt_guar_proj_info_main t1
left join dw_tmp.tmp_dwd_agmt_guar_proj_info_sign t2
on t1.proj_id = t2.proj_id
left join dw_tmp.tmp_dwd_agmt_guar_proj_info_riskopinion t3
on t1.proj_id = t3.proj_id
left join dw_tmp.tmp_dwd_agmt_guar_proj_info_prod_dict t4
on t1.guar_prod_cd = t4.value
;
commit ;
