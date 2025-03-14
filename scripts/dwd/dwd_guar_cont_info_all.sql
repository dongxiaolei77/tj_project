-- ---------------------------------------
-- 开发人   ：
-- 开发时间 ：
-- 目标表   ：
-- 源表     ：dw_nd.ods_t_biz_project_main     主项目表
--            dw_nd.ods_t_biz_proj_xz          续支项目表
--            dw_nd.ods_t_biz_proj_loan_check  贷后检查表（取自主续支的数据）
--            dw_nd.ods_t_biz_proj_sign        签约表
--            dw_nd.ods_t_biz_proj_loan        放款表
--            dw_nd.ods_t_biz_proj_appr        批复表
--            dw_base.dwd_evt_wf_task_info     流程审批信息
--            dw_nd.ods_t_proj_comp_aply       代偿申请信息
--            dw_base.dim_area_info/dim_guar_class/dim_econ_info/dim_prod_code/dim_d_clus_scheme/dim_bank_info/dim_cust_class   行政区划码表/国担分类码表/国民经济分类码表/担保产品码表/产业集群编码/银行部门表/客户类型表
-- 变更记录 ：20241201 脚本的统一变更，MySQL5.0转MySQL8.0并优化逻辑 zhangfl
-- ---------------------------------------

-- 创建临时表，获取主项目表（进件）最新日期数据
drop table if exists dw_tmp.tmp_dwd_guar_cont_info_all_proj ;
commit;

create table dw_tmp.tmp_dwd_guar_cont_info_all_proj(
	 proj_id              varchar(64)   comment'项目id'                            
	,proj_no              varchar(64)   comment'项目编号'
	,wf_inst_id			  varchar(32)	comment'工作流节点id'                          
	,city_no			  varchar(20)   comment'城市代码'
	,county_no			  varchar(20)   comment'区县代码'
	,cust_type            varchar(20)    comment'客户类型:01-自然人 02-法人'
	,cust_class           varchar(50)   comment'客户分类:01-家庭农场 02-种养大户 03-农民合作社'
	,cust_name            varchar(64)   comment'客户名称'
	,cert_no              varchar(25)   comment'证件号码'
	,tel_no               varchar(20)   comment'联系电话'
	,cnty_guar_type       varchar(60)   comment'国担分类'
	,cnty_econ_type       varchar(60)   comment'国民经济分类'
	,loan_use			  varchar(1000) comment'贷款用途'
	,guar_prod            varchar(16)   comment'担保产品'                           
	,prod_schem           varchar(300)  comment'集群方案'
	,loan_bank            varchar(50)   comment'贷款银行'
	,loan_bank_dept       varchar(50)   comment'经办支行/部门'
	,loan_type            varchar(20)   comment'贷款方式'
	,item_code			  varchar(20)   comment'项目状态代码'
	,item_status          varchar(20)   comment'项目状态'
	,accept_dt			  varchar(8)	comment'受理日期'
	,unguar_dt			  varchar(8)	comment'解保日期'
  ,index idx_tmp_dwd_guar_cont_info_all_proj_proj_id ( proj_id )
  ,index idx_tmp_dwd_guar_cont_info_all_proj_proj_no ( proj_no )
  ,index idx_tmp_dwd_guar_cont_info_all_proj_wf_inst_id ( wf_inst_id )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit;

insert into dw_tmp.tmp_dwd_guar_cont_info_all_proj
(
proj_id
,proj_no
,wf_inst_id
,city_no
,county_no
,cust_type
,cust_class
,cust_name
,cert_no
,tel_no
,cnty_guar_type
,cnty_econ_type
,loan_use
,guar_prod
,prod_schem
,loan_bank
,loan_bank_dept
,loan_type
,item_code
,item_status
,accept_dt
,unguar_dt
)
select
 id                       as proj_id
,code                     as proj_no
,wf_inst_id				  as wf_inst_id
,city					  as city_no
,district				  as county_no
,case when main_type = '01' then '自然人'
	  when main_type = '02' then '法人或其他组织'
	  else '未知' end as cust_type
,cust_type				  as cust_class
,cust_name                as cust_name
,cust_identity_no         as cert_no
,cust_mobile              as tel_no
,national_guar_type       as cnty_guar_type
,case when length(national_econ_type)='23' then substr(national_econ_type,18,4)        
      when length(national_econ_type)='16' then substr(national_econ_type,12,3)
	  when length(national_econ_type)='10' then substr(national_econ_type,7,2)
	  else substr(national_econ_type,3,1)
	  end as cnty_econ_type
,money_purpose			  as loan_use
,guar_product             as guar_prod
,aggregate_scheme         as prod_schem
,loans_bank               as loan_bank
,handles_bank             as loan_bank_dept
,case when loan_type = '0' then '普通贷款'
	  when loan_type = '1' then '循环贷'
	  when loan_type = '2' then '非自主循环贷(一年一支用)'
	  else '未知' end  as loan_type
,proj_status              as item_code
,case when first_guarantee_has_end = '1' then '已解保'
	 when proj_status = '00' then '提报中'
     when proj_status = '10' then '审批中'
	 when proj_status = '20' then '待签约'
	 when proj_status = '30' then '待出函'
	 when proj_status = '40' then '待放款'
	 when proj_status = '50' then '已放款'
	 when proj_status = '97' then '已作废'
	 when proj_status = '98' then '已终止'
	 when proj_status = '99' then '已否决'
	 when proj_status = '91' then '不受理'
	 when proj_status = '90' then '已解保'
	 when proj_status = '92' then '超期终止'
	 when proj_status = '93' then '已代偿'
	 else proj_status end as item_status -- 项目状态
,date_format(submit_time,'%Y%m%d') 		  as accept_dt
,case when first_guarantee_has_end = '1' then date_format(guarantee_end_time,'%Y%m%d') else null end as unguar_dt
from(
	select
	id
	,code
	,wf_inst_id
	,city
	,district
	,main_type
	,cust_type
	,cust_name
	,cust_identity_no
	,cust_mobile
	,national_guar_type
	,national_econ_type
	,money_purpose
	,guar_product
	,aggregate_scheme
	,loans_bank
	,handles_bank
	,loan_type
	,proj_status
	,submit_time
	,first_guarantee_has_end
	,guarantee_end_time
	,row_number()over(partition by id order by update_time desc, db_update_time desc) rn
	from dw_nd.ods_t_biz_project_main  -- 主项目表
	where date_format(db_update_time,'%Y%m%d') <= date_format('${v_sdate}','%Y%m%d')
) t
where code is not null
and t.rn = 1
;
commit;


-- 创建临时表，获取续支项目表最新日期数据
drop table if exists dw_tmp.tmp_dwd_guar_cont_info_all_xz ;
commit;

create table dw_tmp.tmp_dwd_guar_cont_info_all_xz(
 guar_id			  varchar(64)	 comment'续支id'
,guar_no              varchar(64)    comment'项目编号'
,proj_id              varchar(64)    comment'项目id'
,guar_term			  varchar(4)	 comment'续支期数'
,guar_rate			  decimal(18,6)  comment'批复费率'
,guar_beg_dt          varchar(8)     comment'担保年度开始日期'
,guar_end_dt          varchar(8)     comment'担保年度到期日期'
,wf_inst_id			  varchar(64)	 comment'工作流节点id'
,accept_dt			  varchar(8)	 comment'受理日期'
,aprv_dt			  varchar(8)	 comment'批复日期'
,item_code			  varchar(20)   comment'项目状态代码'
,item_status          varchar(20)   comment'项目状态'
,unguar_dt			  varchar(8)	comment'解保日期'
,index idx_tmp_dwd_guar_cont_info_all_xz_guar_id ( guar_id )
,index idx_tmp_dwd_guar_cont_info_all_xz_guar_no ( guar_no )
,index idx_tmp_dwd_guar_cont_info_all_xz_proj_id ( proj_id )
,index idx_tmp_dwd_guar_cont_info_all_xz_wf_inst_id ( wf_inst_id )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit;

insert into dw_tmp.tmp_dwd_guar_cont_info_all_xz
(
 guar_id
,guar_no
,proj_id
,guar_term
,guar_rate
,guar_beg_dt
,guar_end_dt
,wf_inst_id
,accept_dt
,aprv_dt
,item_code
,item_status
,unguar_dt
)
select
 id 										as guar_id
,code										as proj_no
,project_id									as proj_id
,term										as guar_term
,appr_guar_rate     						as guar_rate
,date_format(guar_annu_startdate,'%Y%m%d')  as guar_beg_dt         
,date_format(guar_annu_duedate,'%Y%m%d')    as guar_end_dt 
,wf_inst_id									as wf_inst_id
,date_format(submit_time,'%Y%m%d') 			as accept_dt
,date_format(appr_date,'%Y%m%d') 			as aprv_dt
,proj_status                                as item_code
,case when guarantee_has_end = '1' then '已解保'
	 when proj_status = '10' then '提报中'
	 when proj_status in ('20','30') then '审批中'
	 when proj_status = '40' then '待出函'
	 when proj_status = '50' then '待放款'
	 when proj_status = '60' then '已放款'
	 when proj_status = '90' then '已解保'
	 when proj_status = '92' then '超期终止'
	 when proj_status = '98' then '已终止'
	 when proj_status = '99' then '已否决'
	 else proj_status end as item_status -- 项目状态
,case when guarantee_has_end = '1' then date_format(guarantee_end_time,'%Y%m%d') else null end as unguar_dt
from (
	select
	 id
	,code
	,project_id
	,term
	,appr_guar_rate
	,guar_annu_startdate
	,guar_annu_duedate
	,wf_inst_id
	,submit_time
	,appr_date
	,status as proj_status
	,guarantee_has_end
	,guarantee_end_time
	,row_number()over(partition by id order by update_time desc, db_update_time desc) rn
	from dw_nd.ods_t_biz_proj_xz
	where date_format(db_update_time,'%Y%m%d') <= date_format('${v_sdate}','%Y%m%d')
) t
where code is not null
and t.rn = 1
;
commit;


-- 创建临时表，获取贷后检查表（自主续支）最新日期数据
drop table if exists dw_tmp.tmp_dwd_guar_cont_info_all_zzxz ;
commit;

create table dw_tmp.tmp_dwd_guar_cont_info_all_zzxz(
 guar_id              varchar(64)    comment'自主续支项目id'
,guar_no              varchar(64)    comment'项目编号'
,proj_id              varchar(64)    comment'项目id'
,guar_term            int            comment'检查期数'
,guar_rate            decimal(10,6)  comment'担保费率'
,guar_beg_dt          varchar(8)     comment'担保年度开始日期'
,guar_end_dt          varchar(8)     comment'担保年度结束日期'
,wf_inst_id			  varchar(32)	 comment'工作流节点id'
,accept_dt			  varchar(8)	 comment'受理日期'
,item_code			  varchar(20)   comment'项目状态代码'
,item_status          varchar(20)   comment'项目状态'
,unguar_dt			  varchar(8)	comment'解保日期'
,index idx_tmp_dwd_guar_cont_info_all_zzxz_guar_id ( guar_id )
,index idx_tmp_dwd_guar_cont_info_all_zzxz_guar_no ( guar_no )
,index idx_tmp_dwd_guar_cont_info_all_zzxz_proj_id ( proj_id )
,index idx_tmp_dwd_guar_cont_info_all_zzxz_wf_inst_id ( wf_inst_id )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit;

insert into dw_tmp.tmp_dwd_guar_cont_info_all_zzxz
(
 guar_id
,guar_no
,proj_id
,guar_term
,guar_rate
,guar_beg_dt
,guar_end_dt
,wf_inst_id
,accept_dt
,item_code
,item_status
,unguar_dt
)
select
 id                                        as guar_id        
,code                                      as guar_no
,project_id								   as proj_id
,term                                      as guar_term
,guar_rate                                 as guar_rate
,date_format(guar_annu_startdate,'%Y%m%d') as guar_beg_dt
,date_format(guar_annu_duedate,'%Y%m%d')   as guar_end_dt
,wf_inst_id								   as wf_inst_id
,date_format(submit_time,'%Y%m%d') 		   as accept_dt
,proj_status                               as item_code
,case when guarantee_has_end = '1' then '已解保'
	 when proj_status = '03' then '已放款'
	 when proj_status = '90' then '已解保'
	 when proj_status = '98' then '已终止'
	 when proj_status = '99' then '已否决'
	 else proj_status end as item_status -- 项目状态
,case when guarantee_has_end = '1' then date_format(guarantee_end_time,'%Y%m%d') else null end as unguar_dt
from (
	select
	 id
	,code
	,project_id
	,term
	,guar_rate
	,guar_annu_startdate
	,guar_annu_duedate
	,wf_inst_id
	,submit_time
	,status as proj_status
	,type
	,guarantee_has_end
	,guarantee_end_time
	from (
		select
		 id
		,code
		,project_id
		,term
		,guar_rate
		,guar_annu_startdate
		,guar_annu_duedate
		,wf_inst_id
		,submit_time
		,status
		,type
		,guarantee_has_end
		,guarantee_end_time
		,row_number()over(partition by id order by update_time desc, db_update_time desc) rn
		from dw_nd.ods_t_biz_proj_loan_check
		where date_format(db_update_time,'%Y%m%d') <= date_format('${v_sdate}','%Y%m%d')
	 ) t1
	where t1.rn = 1
) t2
where code is not null and t2.type = '02' and t2.proj_status in ('03','90','93','98','99')
;
commit;


-- 创建临时表，获取项目签约表（合同）最新日期数据
drop table if exists dw_tmp.tmp_dwd_guar_cont_info_all_sign ;
commit;

create table dw_tmp.tmp_dwd_guar_cont_info_all_sign (
 proj_id        varchar(64)		comment'项目id'
,loan_no		varchar(200)    comment'借款合同编号'
,loan_amt		decimal(18,2)   comment'借款合同金额(万元)'
,loan_rate		decimal(10,6)   comment'借款合同年化利率'
,loan_term		varchar(20)     comment'借款合同期限(月)'
,loan_beg_dt	varchar(8)      comment'借款合同开始日'
,loan_end_dt	varchar(8)      comment'借款合同到期日'
,index idx_tmp_dwd_guar_cont_info_all_sign_proj_id ( proj_id )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit;

insert into dw_tmp.tmp_dwd_guar_cont_info_all_sign
(
 proj_id
,loan_no
,loan_amt
,loan_rate
,loan_term
,loan_beg_dt
,loan_end_dt
)
select
 project_id				-- 项目id
,jk_contr_code	        -- 借款合同编号
,jk_contr_amount	    -- 借款合同金额(万元)
,jk_ctrct_interest_rate	-- 借款合同年化利率
,jk_ctrct_term	        -- 借款合同期限(月)
,jk_ctrct_start_date	-- 借款合同开始日
,jk_ctrct_end_date	    -- 借款合同到期日
from
(
	select
	 project_id
	,jk_contr_code	          -- 借款合同编号
	,jk_contr_amount	      -- 借款合同金额(万元)
	,jk_ctrct_interest_rate   -- 借款合同年化利率
	,jk_ctrct_term	          -- 借款合同期限(月)
	,date_format(jk_ctrct_start_date,'%Y%m%d') as jk_ctrct_start_date  -- 借款合同开始日
	,date_format(jk_ctrct_end_date,'%Y%m%d') as jk_ctrct_end_date    -- 借款合同到期日
	,row_number()over(partition by project_id order by db_update_time desc) rn
	from dw_nd.ods_t_biz_proj_sign
	where date_format(db_update_time,'%Y%m%d') <= '${v_sdate}'
) t1
where t1.rn = 1
;
commit;


-- 创建临时表，获取项目放款表最新日期数据
drop table if exists dw_tmp.tmp_dwd_guar_cont_info_all_loan ;
commit;

create  table dw_tmp.tmp_dwd_guar_cont_info_all_loan (
 proj_id          varchar(64)	   comment'项目id'
,loan_notify_no	  varchar(255)     comment'放款通知书编号'
,loan_beg_dt	  varchar(8)       comment'贷款开始日'
,loan_end_dt      varchar(8)       comment'放款结束日'
,loan_amt	      decimal(18,2)    comment'放款金额'
,fk_date	  varchar(8)       	   comment'放款日期'
,loan_letter_dt	  varchar(8)       comment'放款通知书日期'
,index idx_tmp_dwd_guar_cont_info_all_loan_proj_id ( proj_id )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit;

insert into dw_tmp.tmp_dwd_guar_cont_info_all_loan
select
project_id	            -- 项目/续支id
,fk_letter_code	        -- 放款通知书编号
,date_format(fk_start_date,'%Y%m%d')	    -- 贷款开始日
,date_format(fk_end_date,'%Y%m%d')	        -- 贷款结束日
,fk_amount	            					-- 放款金额
,date_format(fk_date,'%Y%m%d')	    		-- 放款日期
,date_format(fk_letter_date,'%Y%m%d')	    -- 放款通知书日期
from 
(
	select 
	project_id	            -- 项目/续支id
	,fk_letter_code	        -- 放款通知书编号
	,fk_start_date	        -- 贷款开始日
	,fk_end_date	        -- 贷款结束日
	,fk_amount	            -- 放款金额
	,fk_date				-- 放款日期
	,fk_letter_date	        -- 放款通知书日期
	,row_number()over(partition by project_id order by db_update_time desc) rn
	from dw_nd.ods_t_biz_proj_loan
	where date_format(db_update_time,'%Y%m%d') <= '${v_sdate}'
) t
where t.rn = 1
;
commit ;


-- 创建临时表，获取项目批复信息
drop table if exists dw_tmp.tmp_dwd_guar_cont_info_all_appr ;commit;

create table dw_tmp.tmp_dwd_guar_cont_info_all_appr(
  proj_id     varchar(64), -- 项目编号
  guar_rate   varchar(64), -- 担保费率
  arrv_dt     varchar(8),  -- 批复日期
  INDEX idx_tmp_dwd_guar_cont_info_all_appr_proj_id ( proj_id )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;

insert into dw_tmp.tmp_dwd_guar_cont_info_all_appr
(
 proj_id
,guar_rate
,arrv_dt
)
select
 project_id
,guar_rate
,date_format(reply_date,'%Y%m%d')
from
(
	select
	project_id
	,guar_rate
	,reply_date
	,row_number()over(partition by project_id order by db_update_time desc) rn
	from
	dw_nd.ods_t_biz_proj_appr
	where date_format(db_update_time,'%Y%m%d') <= date_format('${v_sdate}','%Y%m%d')
	and business_type = 'ProjectRegister'
) a -- 项目申请表
where a.rn = 1
;
commit;


-- 创建临时表，获取工作流表数据
drop table if exists dw_tmp.tmp_dwd_guar_cont_info_all_task ;
commit;

create  table dw_tmp.tmp_dwd_guar_cont_info_all_task
(
 proj_no	     varchar(100)       -- 项目编号
,loan_reg_dt     varchar(8)        -- 放款登记日期
,index idx_tmp_dwd_guar_cont_info_all_task(proj_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit;

insert into dw_tmp.tmp_dwd_guar_cont_info_all_task
(
 proj_no
,loan_reg_dt
)
select 
 proj_no
,date_format(end_tm,'%Y%m%d')
from
(
select
proj_no
,end_tm
,row_number()over(partition by proj_no order by end_tm desc) rn
from dw_base.dwd_evt_wf_task_info
where task_name = '放款确认'
and end_tm is not null 
and proj_no is not null
) t
where t.rn = 1
;
commit;


-- 创建临时表，汇总系统上线后数据（进件、续支、自主续支）
drop table if exists dw_tmp.tmp_dwd_guar_cont_info_all ;
commit;

create  table dw_tmp.tmp_dwd_guar_cont_info_all (
 guar_no              varchar(64)     comment'担保年度业务编号'
,guar_id              varchar(64)     comment'担保年度业务id'
,proj_no              varchar(64)     comment'项目编号'
,proj_id              varchar(64)     comment'项目id'
,city_no              varchar(20)     comment'地市编码'
,city_name            varchar(20)     comment'地市名称'
,county_no            varchar(20)     comment'区县代码'
,county_name          varchar(100)    comment'区县名称'
,cust_type            varchar(20)     comment'客户类型'
,cust_class           varchar(50)     comment'客户分类'
,cust_name            varchar(64)     comment'客户名称'
,cert_no              varchar(25)     comment'证件号码'
,tel_no               varchar(32)     comment'联系电话'
,guar_class           varchar(60)     comment'国担分类'
,econ_class           varchar(60)     comment'国民经济分类'
,loan_use             varchar(1000)   comment'贷款用途'
,guar_prod            varchar(16)     comment'担保产品'
,industry_clus        varchar(300)    comment'产业集群'
,loan_bank            varchar(50)     comment'贷款银行'
,loan_bank_dept       varchar(50)     comment'贷款支行'
,loan_type            varchar(20)     comment'贷款类型'
,guar_term            varchar(4)      comment'担保年度期数'
,loan_no              varchar(200)    comment'贷款合同编号'
,loan_amt             decimal(18,2)   comment'贷款合同金额'
,loan_rate            decimal(10,6)   comment'贷款合同利率'
,loan_term            varchar(20)     comment'贷款合同期限'
,loan_beg_dt          varchar(8)      comment'贷款合同开始日期'
,loan_end_dt          varchar(8)      comment'贷款合同结束日期'
,guar_rate            decimal(10,6)   comment'担保费率'
,loan_notify_no       varchar(255)    comment'放款通知书编号'
,first_loan_dt        varchar(8)      comment'首次放款日期'
,first_loan_amt       decimal(18,2)   comment'首次放款金额'
,loan_reg_dt          varchar(8)      comment'放款登记日期'
,guar_amt             decimal(18,2)   comment'本年度放款金额'
,first_loan_reg_dt    varchar(8)      comment'首次放款登记日期'
,guar_beg_dt          varchar(8)      comment'担保年度开始日期'
,guar_end_dt          varchar(8)      comment'担保年度结束日期'
,wf_inst_id           varchar(64)     comment'工作流程节点ID'
,accept_dt            varchar(8)      comment'受理日期'
,aprv_dt              varchar(8)      comment'批复日期'
,notify_dt            varchar(8)      comment'出函日期'
,grant_dt             varchar(8)      comment'放款日期'
,unguar_dt            varchar(8)      comment'解保日期'
,item_code            varchar(20)     comment'项目状态编码'
,item_status          varchar(20)     comment'项目状态'
,loan_stt             varchar(20)     comment'合同状态'
,guar_type            varchar(10)     comment'项目类型'
,index idx_tmp_dwd_guar_cont_info_all_proj_id( proj_id )
,index idx_tmp_dwd_guar_cont_info_all_guar_no( guar_no )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit;


-- 项目进件，首笔放款信息
insert into dw_tmp.tmp_dwd_guar_cont_info_all
(
 guar_no              -- 担保年度业务编号
,guar_id              -- 担保年度业务id
,proj_no              -- 项目编号    
,proj_id              -- 项目id    
,city_no              -- 地市编码    
,city_name            -- 地市名称    
,county_no            -- 区县代码    
,county_name          -- 区县名称    
,cust_type            -- 客户类型    
,cust_class           -- 客户分类    
,cust_name            -- 客户名称    
,cert_no              -- 证件号码    
,tel_no               -- 联系电话    
,guar_class           -- 国担分类    
,econ_class           -- 国民经济分类  
,loan_use             -- 贷款用途    
,guar_prod            -- 担保产品    
,industry_clus        -- 产业集群    
,loan_bank            -- 贷款银行    
,loan_bank_dept       -- 贷款支行    
,loan_type            -- 贷款类型    
,guar_term            -- 担保年度期数  
,loan_no              -- 贷款合同编号  
,loan_amt             -- 贷款合同金额  
,loan_rate            -- 贷款合同利率  
,loan_term            -- 贷款合同期限  
,loan_beg_dt          -- 贷款合同开始日期
,loan_end_dt          -- 贷款合同结束日期
,guar_rate            -- 担保费率    
,loan_notify_no       -- 放款通知书编号 
,first_loan_dt        -- 首次放款日期  
,first_loan_amt       -- 首次放款金额  
,loan_reg_dt          -- 放款登记日期  
,guar_amt             -- 本年度放款金额 
,first_loan_reg_dt    -- 首次放款登记日期
,guar_beg_dt          -- 担保年度开始日期
,guar_end_dt          -- 担保年度结束日期
,wf_inst_id           -- 工作流程节点ID
,accept_dt            -- 受理日期    
,aprv_dt              -- 批复日期    
,notify_dt            -- 出函日期
,grant_dt             -- 放款日期
,unguar_dt            -- 解保日期
,item_code			  -- 项目状态编码
,item_status		  -- 项目状态
,loan_stt             -- 合同状态
,guar_type            -- 项目类型
)
select
 t1.proj_no as guar_no                 -- 担保年度业务编号
,t1.proj_id as guar_id                 -- 担保年度业务id
,t1.proj_no as proj_no                 -- 项目编号    
,t1.proj_id as proj_id                 -- 项目id    
,t1.city_no as city_no                 -- 地市编码    
,t6.sup_area_name as city_name         -- 地市名称    
,t1.county_no as county_no             -- 区县代码    
,t6.area_name as county_name       	   -- 区县名称    
,t1.cust_type as cust_type             -- 客户类型    
,t12.value as cust_class           	   -- 客户分类    
,t1.cust_name as cust_name             -- 客户名称    
,t1.cert_no as cert_no                 -- 证件号码    
,t1.tel_no as tel_no                   -- 联系电话    
,t7.value as guar_class                -- 国担分类    
,t8.econ_name as econ_class            -- 国民经济分类  
,t1.loan_use as loan_use               -- 贷款用途    
,t9.value as guar_prod                 -- 担保产品    
,t10.scheme_value as industry_clus     -- 产业集群    
,case when coalesce(t11.bank_name,loan_bank_dept) like '%农业银行%' then '农业银行'
      when coalesce(t11.bank_name,loan_bank_dept) like '%邮政储蓄%' or coalesce(t11.bank_name,loan_bank_dept) like '%邮储%' then '邮储银行'
      when coalesce(t11.bank_name,loan_bank_dept) like '%农村商业%' or coalesce(t11.bank_name,loan_bank_dept) like '%农商%' then '农商银行'
      else '其他银行' end as loan_bank -- 贷款银行
,coalesce(t11.bank_name,loan_bank_dept) as loan_bank_dept       -- 贷款支行    
,t1.loan_type as loan_type             -- 贷款类型    
,'0' as guar_term                      -- 担保年度期数  
,t2.loan_no as loan_no                 -- 贷款合同编号  
,t2.loan_amt as loan_amt               -- 贷款合同金额  
,t2.loan_rate as loan_rate             -- 贷款合同利率  
,t2.loan_term as loan_term             -- 贷款合同期限  
,t2.loan_beg_dt as loan_beg_dt         -- 贷款合同开始日期
,t2.loan_end_dt as loan_end_dt         -- 贷款合同结束日期
,t3.guar_rate as guar_rate             -- 担保费率    
,t4.loan_notify_no as loan_notify_no   -- 放款通知书编号 
,t4.fk_date as first_loan_dt       	   -- 首次放款日期  
,t4.loan_amt as first_loan_amt         -- 首次放款金额  
,t5.loan_reg_dt as loan_reg_dt         -- 放款登记日期  
,t4.loan_amt as guar_amt               -- 本年度放款金额 
,t5.loan_reg_dt as first_loan_reg_dt   -- 首次放款登记日期
,t4.fk_date as guar_beg_dt         	   -- 担保年度开始日期   -- t4.loan_beg_dt没有使用，字段空值较多
,t4.loan_end_dt as guar_end_dt         -- 担保年度结束日期
,t1.wf_inst_id as wf_inst_id           -- 工作流程节点ID
,t1.accept_dt as accept_dt             -- 受理日期    
,t3.arrv_dt as aprv_dt                 -- 批复日期    
,t4.loan_letter_dt as notify_dt        -- 出函日期    
,t4.fk_date as grant_dt            	   -- 放款日期    
,t1.unguar_dt as unguar_dt             -- 解保日期  
,t1.item_code			  			   -- 项目状态编码
,t1.item_status			  			   -- 项目状态    
,t1.item_status as loan_stt            -- 合同状态
,'进件' as guar_type                   -- 项目类型
from
dw_tmp.tmp_dwd_guar_cont_info_all_proj t1
left join dw_tmp.tmp_dwd_guar_cont_info_all_sign t2
on t1.proj_id = t2.proj_id
left join dw_tmp.tmp_dwd_guar_cont_info_all_appr t3
on t1.proj_id = t3.proj_id
left join dw_tmp.tmp_dwd_guar_cont_info_all_loan t4
on t1.proj_id = t4.proj_id
left join dw_tmp.tmp_dwd_guar_cont_info_all_task t5
on t1.proj_no = t5.proj_no
left join dw_base.dim_area_info t6
on t1.county_no = t6.area_cd
and t6.area_lvl = '3'
left join dw_base.dim_guar_class t7
on t1.cnty_guar_type = t7.code
left join dw_base.dim_econ_info t8
on t1.cnty_econ_type = t8.econ_cd
left join dw_base.dim_prod_code t9       	  -- 需要更新维护
on t1.guar_prod = t9.code
left join dw_base.dim_d_clus_scheme t10       -- 需要更新维护
on t1.prod_schem = t10.scheme_code
left join dw_base.dim_bank_info t11
on t1.loan_bank_dept = t11.bank_id
left join dw_base.dim_cust_class t12
on t1.cust_class = t12.code
;
commit;


-- 续支项目
insert into dw_tmp.tmp_dwd_guar_cont_info_all
(
 guar_no              -- 担保年度业务编号
,guar_id              -- 担保年度业务id
,proj_no              -- 项目编号    
,proj_id              -- 项目id    
,city_no              -- 地市编码    
,city_name            -- 地市名称    
,county_no            -- 区县代码    
,county_name          -- 区县名称    
,cust_type            -- 客户类型    
,cust_class           -- 客户分类    
,cust_name            -- 客户名称    
,cert_no              -- 证件号码    
,tel_no               -- 联系电话    
,guar_class           -- 国担分类    
,econ_class           -- 国民经济分类  
,loan_use             -- 贷款用途    
,guar_prod            -- 担保产品    
,industry_clus        -- 产业集群    
,loan_bank            -- 贷款银行    
,loan_bank_dept       -- 贷款支行    
,loan_type            -- 贷款类型    
,guar_term            -- 担保年度期数  
,loan_no              -- 贷款合同编号  
,loan_amt             -- 贷款合同金额  
,loan_rate            -- 贷款合同利率  
,loan_term            -- 贷款合同期限  
,loan_beg_dt          -- 贷款合同开始日期
,loan_end_dt          -- 贷款合同结束日期
,guar_rate            -- 担保费率    
,loan_notify_no       -- 放款通知书编号 
,first_loan_dt        -- 首次放款日期  
,first_loan_amt       -- 首次放款金额  
,loan_reg_dt          -- 放款登记日期  
,guar_amt             -- 本年度放款金额 
,first_loan_reg_dt    -- 首次放款登记日期
,guar_beg_dt          -- 担保年度开始日期
,guar_end_dt          -- 担保年度结束日期
,wf_inst_id           -- 工作流程节点ID
,accept_dt            -- 受理日期    
,aprv_dt              -- 批复日期    
,notify_dt            -- 出函日期
,grant_dt             -- 放款日期
,unguar_dt            -- 解保日期
,item_code		  	  -- 项目状态编码
,item_status		      -- 项目状态  
,loan_stt             -- 合同状态
,guar_type            -- 项目类型
)
select
 t1.guar_no				 -- 担保年度业务编号
,t1.guar_id				 -- 担保年度业务id
,t2.proj_no              -- 项目编号    
,t2.proj_id              -- 项目id    
,t2.city_no              -- 地市编码    
,t2.city_name            -- 地市名称    
,t2.county_no            -- 区县代码    
,t2.county_name          -- 区县名称    
,t2.cust_type            -- 客户类型    
,t2.cust_class           -- 客户分类    
,t2.cust_name            -- 客户名称    
,t2.cert_no              -- 证件号码    
,t2.tel_no               -- 联系电话    
,t2.guar_class           -- 国担分类    
,t2.econ_class           -- 国民经济分类  
,t2.loan_use             -- 贷款用途    
,t2.guar_prod            -- 担保产品
,t2.industry_clus        -- 产业集群
,t2.loan_bank            -- 贷款银行
,t2.loan_bank_dept       -- 贷款支行
,t2.loan_type            -- 贷款类型
,t1.guar_term            -- 担保年度期数
,t2.loan_no              -- 贷款合同编号
,t2.loan_amt             -- 贷款合同金额
,t2.loan_rate            -- 贷款合同利率
,t2.loan_term            -- 贷款合同期限
,t2.loan_beg_dt          -- 贷款合同开始日期
,t2.loan_end_dt          -- 贷款合同结束日期
,t1.guar_rate            -- 担保费率
,t3.loan_notify_no       -- 放款通知书编号
,t2.first_loan_dt        -- 首次放款日期
,t2.first_loan_amt       -- 首次放款金额
,t4.loan_reg_dt			 -- 放款登记日期
,t3.loan_amt             -- 本年度放款金额
,t2.first_loan_reg_dt    -- 首次放款登记日期
,t1.guar_beg_dt          -- 担保年度开始日期
,t1.guar_end_dt          -- 担保年度结束日期
,t1.wf_inst_id           -- 工作流程节点ID
,t1.accept_dt            -- 受理日期
,t1.aprv_dt              -- 批复日期
,t3.loan_letter_dt as notify_dt         -- 出函日期
,t3.fk_date as grant_dt             	-- 放款日期
,t1.unguar_dt as unguar_dt       		-- 解保日期
,t1.item_code			 -- 项目状态编码
,t1.item_status			 -- 项目状态  
,t2.item_status           -- 合同状态
,'续支' as guar_type     -- 项目类型
from
dw_tmp.tmp_dwd_guar_cont_info_all_xz t1
inner join dw_tmp.tmp_dwd_guar_cont_info_all t2
on t1.proj_id = t2.proj_id
and t2.guar_type = '进件'
left join dw_tmp.tmp_dwd_guar_cont_info_all_loan t3
on t1.guar_id = t3.proj_id
left join dw_tmp.tmp_dwd_guar_cont_info_all_task t4
on t1.guar_no = t4.proj_no
;
commit;


-- 自主续支项目
insert into dw_tmp.tmp_dwd_guar_cont_info_all
(
 guar_no              -- 担保年度业务编号
,guar_id              -- 担保年度业务id
,proj_no              -- 项目编号    
,proj_id              -- 项目id    
,city_no              -- 地市编码    
,city_name            -- 地市名称    
,county_no            -- 区县代码    
,county_name          -- 区县名称    
,cust_type            -- 客户类型    
,cust_class           -- 客户分类    
,cust_name            -- 客户名称    
,cert_no              -- 证件号码    
,tel_no               -- 联系电话    
,guar_class           -- 国担分类    
,econ_class           -- 国民经济分类  
,loan_use             -- 贷款用途    
,guar_prod            -- 担保产品    
,industry_clus        -- 产业集群    
,loan_bank            -- 贷款银行    
,loan_bank_dept       -- 贷款支行    
,loan_type            -- 贷款类型    
,guar_term            -- 担保年度期数  
,loan_no              -- 贷款合同编号  
,loan_amt             -- 贷款合同金额  
,loan_rate            -- 贷款合同利率  
,loan_term            -- 贷款合同期限  
,loan_beg_dt          -- 贷款合同开始日期
,loan_end_dt          -- 贷款合同结束日期
,guar_rate            -- 担保费率    
,loan_notify_no       -- 放款通知书编号 
,first_loan_dt        -- 首次放款日期  
,first_loan_amt       -- 首次放款金额  
,loan_reg_dt          -- 放款登记日期  
,guar_amt             -- 本年度放款金额 
,first_loan_reg_dt    -- 首次放款登记日期
,guar_beg_dt          -- 担保年度开始日期
,guar_end_dt          -- 担保年度结束日期
,wf_inst_id           -- 工作流程节点ID
,accept_dt            -- 受理日期    
,aprv_dt              -- 批复日期    
,notify_dt            -- 出函日期
,grant_dt             -- 放款日期
,unguar_dt            -- 解保日期
,item_code		  	  -- 项目状态编码
,item_status		      -- 项目状态
,loan_stt             -- 合同状态
,guar_type            -- 项目类型
)
select
 t1.guar_no as guar_no   -- 担保年度业务编号
,t1.guar_id as guar_id   -- 担保年度业务id
,t2.proj_no              -- 项目编号    
,t2.proj_id              -- 项目id    
,t2.city_no              -- 地市编码    
,t2.city_name            -- 地市名称    
,t2.county_no            -- 区县代码    
,t2.county_name          -- 区县名称    
,t2.cust_type            -- 客户类型    
,t2.cust_class           -- 客户分类    
,t2.cust_name            -- 客户名称    
,t2.cert_no              -- 证件号码    
,t2.tel_no               -- 联系电话    
,t2.guar_class           -- 国担分类    
,t2.econ_class           -- 国民经济分类  
,t2.loan_use             -- 贷款用途    
,t2.guar_prod            -- 担保产品
,t2.industry_clus        -- 产业集群
,t2.loan_bank            -- 贷款银行
,t2.loan_bank_dept       -- 贷款支行
,t2.loan_type            -- 贷款类型
,t1.guar_term            -- 担保年度期数
,t2.loan_no              -- 贷款合同编号
,t2.loan_amt             -- 贷款合同金额
,t2.loan_rate            -- 贷款合同利率
,t2.loan_term            -- 贷款合同期限
,t2.loan_beg_dt          -- 贷款合同开始日期
,t2.loan_end_dt          -- 贷款合同结束日期
,t1.guar_rate            -- 担保费率
,null as loan_notify_no  -- 放款通知书编号
,t2.first_loan_dt        -- 首次放款日期
,t2.first_loan_amt       -- 首次放款金额
,t3.loan_reg_dt			 -- 放款登记日期
,null as guar_amt        -- 本年度放款金额
,t2.first_loan_reg_dt    -- 首次放款登记日期
,t1.guar_beg_dt          -- 担保年度开始日期
,t1.guar_end_dt          -- 担保年度结束日期
,t1.wf_inst_id           -- 工作流程节点ID
,t1.accept_dt            -- 受理日期
,null as aprv_dt         -- 批复日期
,null as notify_dt       -- 出函日期
,null as grant_dt        -- 放款日期
,t1.unguar_dt as unguar_dt       	-- 解保日期
,t1.item_code			 -- 项目状态编码
,t1.item_status			 -- 项目状态  
,t2.item_status           -- 合同状态
,'自主续支' as guar_type     		-- 项目类型
from dw_tmp.tmp_dwd_guar_cont_info_all_zzxz t1
inner join dw_tmp.tmp_dwd_guar_cont_info_all t2
on t1.proj_id = t2.proj_id
and t2.guar_type = '进件'
left join dw_tmp.tmp_dwd_guar_cont_info_all_task t3
on t1.guar_no = t3.proj_no
;
commit;


-- 续支成功后（项目状态为已放款），首笔放款以及之前的续支更新为 "已解保"

drop table if exists dw_tmp.tmp_dwd_guar_cont_info_all_contn_succ
;
commit;

CREATE TABLE dw_tmp.tmp_dwd_guar_cont_info_all_contn_succ (
  proj_no varchar(60) COMMENT '项目编号（粒度合同）',
  guar_no varchar(60) COMMENT '担保年度业务编号',
  contn_pay_term varchar(8) COMMENT '续支期数',
  index idx_tmp_dwd_guar_cont_info_all_contn_succ_proj_no (proj_no),
  index idx_tmp_dwd_guar_cont_info_all_contn_succ_guar_no (guar_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='续支成功记录';
commit;

insert into dw_tmp.tmp_dwd_guar_cont_info_all_contn_succ
(
 proj_no
,guar_no
,contn_pay_term
)
select 
distinct
proj_no
,guar_no
,guar_term
from dw_tmp.tmp_dwd_guar_cont_info_all
where item_status = '已放款'
and guar_type='续支'
;
commit ;

-- 更新首笔放款
update dw_tmp.tmp_dwd_guar_cont_info_all t1 
set t1.item_status ='已解保' ,
    t1.unguar_dt = t1.loan_end_dt
where t1.guar_type='进件'
     and item_status = '已放款'
	 and exists (
	 select 1 from dw_tmp.tmp_dwd_guar_cont_info_all_contn_succ t2 
	 where t1.proj_no = t2.proj_no
	   and t1.guar_no <> t2.guar_no
	 )
;
commit ;

-- 更新上笔续支
update dw_tmp.tmp_dwd_guar_cont_info_all t1 
set t1.item_status ='已解保' ,
    t1.unguar_dt = t1.loan_end_dt
where t1.guar_type='续支'
     and item_status = '已放款'
	 and exists (
	 select 1 from dw_tmp.tmp_dwd_guar_cont_info_all_contn_succ t2 
	 where t1.proj_no = t2.proj_no
	   and t1.guar_no <> t2.guar_no
	   and t1.guar_term < t2.contn_pay_term
	 )
;
commit ;


-- 自主续支成功后（项目状态为已放款），首笔放款及之前的自主续支数据更新为 "已解保"
drop table if exists dw_tmp.tmp_dwd_guar_cont_info_all_check_succ
;
commit;

CREATE TABLE dw_tmp.tmp_dwd_guar_cont_info_all_check_succ (
  proj_no varchar(60) COMMENT '项目编号（粒度合同）',
  guar_no varchar(60) COMMENT '担保年度业务编号',
  guar_beg_dt varchar(8) COMMENT '放款开始日期',
  index idx_tmp_dwd_guar_cont_info_all_check_succ_proj_no (proj_no),
  index idx_tmp_dwd_guar_cont_info_all_check_succ_guar_no (guar_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='续支成功记录';
commit;

insert into dw_tmp.tmp_dwd_guar_cont_info_all_check_succ
(
 proj_no
,guar_no
,guar_beg_dt
)
select 
distinct
proj_no
,guar_no
,guar_beg_dt
from dw_tmp.tmp_dwd_guar_cont_info_all
where item_status = '已放款'
and guar_type='自主续支'
;
commit ;

-- 更新首笔放款
update dw_tmp.tmp_dwd_guar_cont_info_all t1 
set t1.item_status ='已解保' ,
    t1.unguar_dt = t1.loan_end_dt
where t1.guar_type='进件'
     and item_status = '已放款'
	 and exists (
	 select 1 from dw_tmp.tmp_dwd_guar_cont_info_all_check_succ t2 
	 where t1.proj_no = t2.proj_no
	   and t1.guar_no <> t2.guar_no
	 )
;
commit ;

-- 更新上笔自主续支
update dw_tmp.tmp_dwd_guar_cont_info_all t1 
set t1.item_status ='已解保' ,
    t1.unguar_dt = t1.loan_end_dt
where t1.guar_type='自主续支'
     and item_status = '已放款'
	 and exists (
	 select 1 from dw_tmp.tmp_dwd_guar_cont_info_all_check_succ t2 
	 where t1.proj_no = t2.proj_no
	   and t1.guar_no <> t2.guar_no
	   and t1.guar_beg_dt < t2.guar_beg_dt
	 )
;
commit ;


-- 数据汇入目标表
delete from dw_base.dwd_guar_cont_info_all ;
commit;


-- 担保业务系统
insert into dw_base.dwd_guar_cont_info_all
(
 day_id
,guar_no              -- 担保年度业务编号
,guar_id              -- 担保年度业务id
,proj_no              -- 项目编号    
,proj_id              -- 项目id    
,city_no              -- 地市编码    
,city_name            -- 地市名称    
,county_no            -- 区县代码    
,county_name          -- 区县名称    
,cust_type            -- 客户类型    
,cust_class           -- 客户分类    
,cust_name            -- 客户名称    
,cert_no              -- 证件号码    
,tel_no               -- 联系电话    
,guar_class           -- 国担分类    
,econ_class           -- 国民经济分类  
,loan_use             -- 贷款用途    
,guar_prod            -- 担保产品    
,industry_clus        -- 产业集群    
,loan_bank            -- 贷款银行    
,loan_bank_dept       -- 贷款支行    
,loan_type            -- 贷款类型    
,guar_term            -- 担保年度期数  
,loan_no              -- 贷款合同编号  
,loan_amt             -- 贷款合同金额  
,loan_rate            -- 贷款合同利率  
,loan_term            -- 贷款合同期限  
,loan_beg_dt          -- 贷款合同开始日期
,loan_end_dt          -- 贷款合同结束日期
,guar_rate            -- 担保费率    
,loan_notify_no       -- 放款通知书编号 
,first_loan_dt        -- 首次放款日期  
,first_loan_amt       -- 首次放款金额  
,loan_reg_dt          -- 放款登记日期  
,guar_amt             -- 本年度放款金额 
,first_loan_reg_dt    -- 首次放款登记日期
,guar_beg_dt          -- 担保年度开始日期
,guar_end_dt          -- 担保年度结束日期
,wf_inst_id           -- 工作流程节点ID
,accept_dt            -- 受理日期    
,aprv_dt              -- 批复日期    
,notify_dt            -- 出函日期
,grant_dt             -- 放款日期
,unguar_dt            -- 解保日期
,item_code            -- 项目状态编码
,item_stt          	  -- 项目状态
,loan_stt             -- 合同状态
,data_source          -- 数据来源
,guar_type            -- 项目类型
)
select
 '${v_sdate}' as day_id
,guar_no              -- 担保年度业务编号
,guar_id              -- 担保年度业务id
,proj_no              -- 项目编号    
,proj_id              -- 项目id    
,city_no              -- 地市编码    
,city_name            -- 地市名称    
,county_no            -- 区县代码    
,county_name          -- 区县名称    
,cust_type            -- 客户类型    
,cust_class           -- 客户分类    
,cust_name            -- 客户名称    
,cert_no              -- 证件号码    
,tel_no               -- 联系电话    
,guar_class           -- 国担分类    
,econ_class           -- 国民经济分类  
,loan_use             -- 贷款用途    
,guar_prod            -- 担保产品    
,industry_clus        -- 产业集群    
,loan_bank            -- 贷款银行    
,loan_bank_dept       -- 贷款支行    
,loan_type            -- 贷款类型    
,guar_term            -- 担保年度期数  
,loan_no              -- 贷款合同编号  
,loan_amt             -- 贷款合同金额  
,loan_rate            -- 贷款合同利率  
,loan_term            -- 贷款合同期限  
,loan_beg_dt          -- 贷款合同开始日期
,loan_end_dt          -- 贷款合同结束日期
,guar_rate            -- 担保费率    
,loan_notify_no       -- 放款通知书编号 
,first_loan_dt        -- 首次放款日期  
,first_loan_amt       -- 首次放款金额  
,loan_reg_dt          -- 放款登记日期  
,guar_amt             -- 本年度放款金额 
,first_loan_reg_dt    -- 首次放款登记日期
,guar_beg_dt          -- 担保年度开始日期
,guar_end_dt          -- 担保年度结束日期
,wf_inst_id           -- 工作流程节点ID
,accept_dt            -- 受理日期    
,aprv_dt              -- 批复日期    
,notify_dt            -- 出函日期
,grant_dt             -- 放款日期
,unguar_dt            -- 解保日期
,item_code            -- 项目状态编码
,item_status          -- 项目状态
,loan_stt             -- 合同状态
,'担保业务系统' as data_source          -- 数据来源
,guar_type            -- 项目类型
from dw_tmp.tmp_dwd_guar_cont_info_all
;
commit;


-- 更新代偿状态(根据画像系统)
drop table if exists dw_tmp.tmp_dwd_guar_cont_info_all_compt ;
commit ;
create table dw_tmp.tmp_dwd_guar_cont_info_all_compt (
guar_no varchar(60)
,is_compt varchar(1) -- 代偿标志 1-代偿 0-未代偿
,index idx_tmp_dwd_guar_cont_info_all_compt ( guar_no )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit ;

insert into dw_tmp.tmp_dwd_guar_cont_info_all_compt
select guar_id, is_compt
from
(
	select	proj_code as guar_id
			,'1' as is_compt
			,row_number()over(partition by proj_code order by db_update_time desc) rn
	from dw_nd.ods_t_proj_comp_aply
) t
where t.rn = 1

-- select
-- distinct seq_id
-- ,'1'
-- from 
-- (
-- select
-- seq_id 
-- from dw_nd.ods_imp_portrait_info_new
-- where s_risk_stt = '已代偿' 
-- ) t
;
commit ;

update dw_base.dwd_guar_cont_info_all t1
inner join dw_tmp.tmp_dwd_guar_cont_info_all_compt t2
on t1.guar_no = t2.guar_no
set t1.item_stt = '已代偿'
where t2.is_compt = '1';
commit;