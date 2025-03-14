-- ---------------------------------------
-- 开发人   :  Wangyx
-- 开发时间 ： 20220510
-- 目标表   ： dwd_guar_compt_info 代偿汇总信息表  
-- 源表     ： dw_nd.ods_t_proj_comp_aply   代偿申请信息
--             dw_nd.ods_t_biz_project_main 主项目表
--             dw_nd.ods_t_proj_comp_appropriation 代偿拨付信息
--             dw_nd.ods_t_sys_dept 部门表
--             dw_nd.ods_t_sys_data_dict_value 字典表
--             dw_base.dwd_guar_info_stat 担保年度业务全量表
--             dw_base.dwd_guar_info_all  担保年度业务全量表
-- 变更记录 ： 20220520 银行维表切源，ods_t_sys_dept改为dim_bank_info
--             20230824 代偿时间调整
--             20241201 脚本的统一变更，MySQL5.0转MySQL8.0 zhangfl
-- ---------------------------------------

-- 创建临时表，获取担保业务系统--代偿申请表最新日期数据

drop table if exists dw_tmp.tmp_dwd_proj_comp_dtl;

create table dw_tmp.tmp_dwd_proj_comp_dtl(
id varchar(64)
,project_id varchar(64)	-- 项目id（仅连接用）
,proj_code varchar(40) -- 原业务编号
,cust_name	varchar(100) -- 客户名称
,cert_no	varchar(25) -- 客户证件号码
,jk_contr_code	varchar(200) -- 借款合同编号
,loan_start_date	varchar(10)
,loan_end_date	varchar(10)
,city_code	varchar(20)
,country_code	varchar(20)
,cust_mobile	varchar(20)
,guar_code	varchar(32) -- 国家农担分类
,guar_product_code	varchar(32) -- 担保产品名称
,loan_bank	varchar(50) -- 贷款银行
,bank_cust_manager_name	varchar(20) -- 银行客户经理
,money_purpose	varchar(1000) -- 借款用途
,guar_amount	decimal(18,2) -- 担保金额(批复金额)
,reply_date	varchar(10) -- 批复日期
,loan_period	int -- 贷款期限(月)
,repay_type	varchar(32) -- 还款方式
,fk_date	varchar(10) -- 放款日期
,overdue_date	varchar(10) -- 逾期日期
,compt_time	varchar(10) -- 代偿发起时间
,counter_guarantee	varchar(1000) -- 反担保措施
,wf_inst_id varchar(64) COMMENT '工作流实例id'
,index idx_tmp_dwd_guar_compt_apply_project_id(project_id)
,index idx_tmp_dwd_guar_compt_apply_wf_inst_id(wf_inst_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ; 
commit;

insert into dw_tmp.tmp_dwd_proj_comp_dtl
(
id
,project_id
,proj_code
,cust_name
,cert_no
,jk_contr_code
,loan_start_date
,loan_end_date
,city_code
,country_code
,cust_mobile
,guar_code
,guar_product_code
,loan_bank
,bank_cust_manager_name
,money_purpose
,guar_amount
,reply_date
,loan_period
,repay_type
,fk_date
,overdue_date
,compt_time
,counter_guarantee
,wf_inst_id
)
select
id
,project_id
,proj_code
,cust_name
,cust_identity_no
,jk_contr_code
,date_format(fk_start_date,'%Y%m%d')
,date_format(fk_end_date,'%Y%m%d')
,city
,district
,cust_mobile
,national_guar_type
,guar_product
,loans_bank
,bank_cust_manager_name
,money_purpose
,reply_amount
,date_format(reply_date,'%Y%m%d')
,reply_period
,loan_repay_type
,date_format(fk_date,'%Y%m%d')
,date_format(overdue_date,'%Y%m%d')
,date_format(submit_time,'%Y%m%d')
,reply_counter_guar_desc
,wf_inst_id
from
(
select
id
,project_id
,proj_code
,cust_name
,cust_identity_no
,jk_contr_code
,fk_start_date
,fk_end_date
,city
,district
,cust_mobile
,national_guar_type
,guar_product
,loans_bank
,bank_cust_manager_name
,money_purpose
,reply_amount
,reply_date
,reply_period
,loan_repay_type
,fk_date
,overdue_date
,submit_time
,reply_counter_guar_desc
,update_time
,status
,wf_inst_id
from
(
select
id
,project_id
,proj_code
,cust_name
,cust_identity_no
,jk_contr_code
,fk_start_date
,fk_end_date
,city
,district
,cust_mobile
,national_guar_type
,guar_product
,loans_bank
,bank_cust_manager_name
,money_purpose
,reply_amount
,reply_date
,reply_period
,loan_repay_type
,fk_date
,overdue_date
,submit_time
,reply_counter_guar_desc
,update_time
,status
,wf_inst_id
,row_number()over(partition by project_id order by db_update_time desc,update_time desc) rn
from dw_nd.ods_t_proj_comp_aply
) t1
where t1.rn = 1
) t2
where status = '50'
; commit ;



-- 创建临时表，获取主项目表业务编号

drop table if exists dw_tmp.tmp_dwd_proj_comp_dtl_main ;

create table dw_tmp.tmp_dwd_proj_comp_dtl_main(
  id     varchar(64), -- 账户id
  code   varchar(64), -- 账户编号                                 
  INDEX idx_tmp_dwd_proj_comp_dtl_main_id ( id )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ; 
commit;

insert into dw_tmp.tmp_dwd_proj_comp_dtl_main
(
id
,code  
)
select id,code 
from
(
select id,code,update_time, row_number()over(partition by id order by db_update_time desc,update_time desc ) rn
from dw_nd.ods_t_biz_project_main -- 主项目表

) t1
where t1.rn = 1
;commit;



-- 创建临时表，获取--须拨付代偿款金额（本息）

drop table if exists dw_tmp.tmp_dwd_proj_comp_dtl_compt ; commit;

create table dw_tmp.tmp_dwd_proj_comp_dtl_compt(
	 compt_id   varchar(64)    -- 代偿ID
	,compt_amt	decimal(18,6) 
	,INDEX idx_tmp_dwd_proj_comp_dtl_compt_id ( compt_id )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit;

insert into dw_tmp.tmp_dwd_proj_comp_dtl_compt
(
compt_id
,compt_amt
)
select
comp_id
,approp_totl/10000 as compt_amt
from(
select
comp_id
,approp_totl
,update_time
,row_number()over(partition by comp_id order by db_update_time desc,update_time desc ) rn
from dw_nd.ods_t_proj_comp_appropriation
) t1
where t1.rn = 1
;
commit;



-- 创建临时表，获取担保产品、还款方式代码
drop table if exists dw_tmp.tmp_dwd_proj_comp_dtl_product ; commit;

create table dw_tmp.tmp_dwd_proj_comp_dtl_product(
	 code   varchar(64)
	,value	varchar(255)
	,dict_code varchar(32)
	,INDEX idx_tmp_dwd_proj_comp_dtl_product_code ( code )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit;

insert into dw_tmp.tmp_dwd_proj_comp_dtl_product
(
code
,value
,dict_code
)
	select
	code
	,value
	,dict_code
from
(
		select
		code
		,value
		,dict_code
		,update_time
		,row_number()over(partition by code order by update_time desc) rn
		from dw_nd.ods_t_sys_data_dict_value
		where dict_code in ('productWarranty','repaymentMethod')
) t1
where t1.rn = 1
;commit;


-- 代偿时间 -- mdy 20230824
drop table if exists dw_tmp.tmp_dwd_guar_compt_info_taskinst_v2 ;
commit;
	
CREATE TABLE dw_tmp.tmp_dwd_guar_compt_info_taskinst_v2 (
  wf_inst_id varchar(64) COLLATE utf8mb4_bin DEFAULT NULL,
  proc_def_id varchar(64) COLLATE utf8mb4_bin DEFAULT NULL,
  task_name varchar(64) COLLATE utf8mb4_bin DEFAULT NULL,
  end_time varchar(8) COLLATE utf8mb4_bin DEFAULT NULL,
  KEY idx_tmp_dwd_guar_compt_info_taskinst_v2_wf_inst_id (wf_inst_id),
  KEY idx_tmp_tmp_dwd_guar_compt_info_taskinst_v2_proc_def_id (proc_def_id),
  KEY idx_tmp_tmp_dwd_guar_compt_info_taskinst_v2_task_name (task_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
commit;


insert into dw_tmp.tmp_dwd_guar_compt_info_taskinst_v2
(
wf_inst_id
,proc_def_id
,task_name
,end_time
)
select
   a.proc_inst_id_
  ,a.proc_def_id_
  ,a.name_
  ,date_format(end_time_,'%Y%m%d')
from 
(
  select
   id_
  ,proc_inst_id_
  ,proc_def_id_
  ,name_
  ,end_time_
  ,row_number()over(partition by proc_inst_id_,name_  order by last_updated_time_ desc ) rn
  from dw_nd.ods_t_act_hi_taskinst_v2 -- 工作流审批表v2
  where date_format(last_updated_time_,'%Y%m%d') <= '${v_sdate}'
) a
where a.rn = 1
;
commit;

drop table if exists dw_tmp.tmp_dwd_guar_compt_info_end_time ;
commit;
	
CREATE TABLE dw_tmp.tmp_dwd_guar_compt_info_end_time (
  wf_inst_id varchar(64) COLLATE utf8mb4_bin DEFAULT NULL,
  end_time varchar(8) COLLATE utf8mb4_bin DEFAULT NULL,
  KEY idx_tmp_dwd_guar_compt_info_end_time_wf_inst_id (wf_inst_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
commit;

insert into dw_tmp.tmp_dwd_guar_compt_info_end_time
(
wf_inst_id
,end_time
)

select
	t1.wf_inst_id
	,max(end_time) as end_time
	from
	dw_tmp.tmp_dwd_guar_compt_info_taskinst_v2 t1  -- 工作流审批表
	inner join dw_nd.ods_t_act_re_procdef_v2 t2
	on t1.proc_def_id = t2.id_
	where t2.key_= 'guarantee-dc' -- 代偿流程
	and t1.task_name in ('财务支付','计财部拨付')
	group by t1.wf_inst_id
;
commit;

-- 部分迁移数据，没有工作流代偿拨付时间，取画像系统数据代偿时间，一次性导入固定
-- tmp 临时表执行一次不再变化 20230824
-- drop table if exists dw_tmp.tmp_dwd_guar_compt_info_portrait ;
-- commit;
-- 	
-- CREATE TABLE dw_tmp.tmp_dwd_guar_compt_info_portrait (
--   guar_id varchar(64) COLLATE utf8mb4_bin DEFAULT NULL comment '业务编号',
--   compt_dt varchar(8) COLLATE utf8mb4_bin DEFAULT NULL comment '代偿日期',
--   KEY idx_tmp_dwd_guar_compt_info_portrait_id (guar_id)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin comment = '画像系统代偿数据临时表--执行一次不再变化 20230824';
-- commit;
-- 
-- insert into dw_tmp.tmp_dwd_guar_compt_info_portrait
-- (
-- guar_id
-- ,compt_dt
-- )
-- select seq_id as guar_id
--        ,date_format(s_compt_dt, '%Y%m%d') as compt_dt
--   from dw_nd.ods_imp_portrait_info_new
--  where s_risk_stt = '已代偿'
-- ;
-- commit;

-- 清空目标表历史数据
delete from dw_base.dwd_guar_compt_info ; commit;


-- 担保业务系统代偿数据插入目标表

insert into dw_base.dwd_guar_compt_info
(
day_id
,source                    -- 来源（担保业务系统）                            
,project_id                -- 项目ID                                                  
,guar_id                   -- 业务编号                                                
,proj_code                 -- 原业务编号                                              
,cust_name                 -- 客户名称                                                
,cert_no                   -- 客户证件号码                                            
,jk_contr_code             -- 借款合同编号                                            
,loan_start_date           -- 放款开始日                                              
,loan_end_date             -- 放款结束日                                              
,city_code                 -- 所在地市                                    
,country_code              -- 所在县区                                  
,cust_mobile               -- 联系方式                                                
,guar_code                 -- 国家农担分类                                
,econ_code                 -- 国民经济分类                               
,guar_product_code         -- 担保产品名称            
,loan_bank                 -- 贷款银行                                                
,bank_cust_manager_name    -- 银行客户经理                                            
,money_purpose             -- 借款用途                                                
,guar_amount               -- 担保金额(批复金额)                                      
,reply_date                -- 批复日期                                                
,loan_period               -- 贷款期限(月)                                            
,contract_amt              -- 贷款合同金额
,repay_type                -- 还款方式   
,fk_date                   -- 放款日期                                               
,overdue_date              -- 逾期日期                                                
,compt_time                -- 代偿发起时间                      
,compt_amt                 -- 须拨付代偿款金额（本息）           
,counter_guarantee         -- 反担保措施
)
 select
 '${v_sdate}'
,'担保业务系统' as source
,t1.project_id
,coalesce(t2.code,t1.proj_code,null) as guar_id
,t1.proj_code
,t1.cust_name
,t1.cert_no
,t1.jk_contr_code
,t1.loan_start_date
,t1.loan_end_date
,t1.city_code
,t1.country_code
,t1.cust_mobile
,t1.guar_code
,coalesce(t3.econ_code,null)
,coalesce(t1.guar_product_code,'9999')
,coalesce(t6.bank_name,t5.loan_bank,t1.loan_bank) as loan_bank
,coalesce(t5.bank_mgr,t1.bank_cust_manager_name) as bank_cust_manager_name
,t1.money_purpose
,coalesce(t5.aprv_amt,t1.guar_amount) as guar_amount             
,coalesce(t5.aprv_dt,t1.reply_date) as reply_date
,coalesce(t3.term,t1.loan_period) as loan_period
,t3.loan_amt as contract_amt
,coalesce(t1.repay_type,'9999')
,coalesce(t3.loan_reg_dt,t1.fk_date) as fk_date
,t1.overdue_date
-- ,coalesce(t7.end_time, t8.compt_dt) as compt_time
,t7.end_time as compt_time
,t4.compt_amt  -- 代偿金额
,t1.counter_guarantee
from dw_tmp.tmp_dwd_proj_comp_dtl t1  -- 代偿申请表去重
left join dw_tmp.tmp_dwd_proj_comp_dtl_main t2
on t1.project_id = t2.id
left join dw_base.dwd_guar_info_stat t3
on t1.proj_code = t3.guar_id
and t3.guar_id is not null
left join dw_base.dwd_guar_info_all t5
on t1.proj_code = t5.guar_id
left join dw_tmp.tmp_dwd_proj_comp_dtl_compt t4
on t1.id = t4.compt_id
left join dw_tmp.tmp_dwd_guar_compt_info_end_time t7 -- mdy 20230824 wyx
on t1.wf_inst_id = t7.wf_inst_id
-- left join dw_tmp.tmp_dwd_guar_compt_info_portrait t8
-- on t8.guar_id = t2.code
left join dw_base.dim_bank_info t6 -- mdy 20220520 wyx
on t1.loan_bank = t6.bank_id
;
commit;


-- 历史表
delete from dw_base.dwd_guar_compt_info_his where day_id = '${v_sdate}' ; commit;
insert into dw_base.dwd_guar_compt_info_his
select * from dw_base.dwd_guar_compt_info
where day_id = '${v_sdate}'
;
commit;
