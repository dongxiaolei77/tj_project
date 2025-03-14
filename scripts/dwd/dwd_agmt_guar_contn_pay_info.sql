-- ---------------------------------------
-- 开发人   : liyy
-- 开发时间 ：20210311
-- 目标表   :  dwd_agmt_guar_contn_pay_info
-- 源表     ：dw_base.dwd_evt_wf_task_info    流程信息
--            dw_base.dwd_agmt_guar_proj_info 担保项目信息
--            dw_nd.ods_t_biz_proj_xz 续支项目表

-- 变更记录 ：20210422 业务系统放款信息表中只有 本次放款日、本次到期日, 放款日期 部分迁移后没有数据，需要取历史的数据 dwd_guar_info 放款时间、到期时间
--            20211011 1.增加保后检查已终止数据 2.自主续支        
--            20220211统一修改
--            20220909 update_time替换为db_update_time wyx
--            20241201 脚本的统一变更，MySQL5.0转MySQL8.0并优化逻辑 zhangfl
-- ---------------------------------------
set interactive_timeout = 7200;
set wait_timeout = 7200;

-- 1.临时表-流程放款确认
drop table if exists dw_tmp.tmp_dwd_agmt_guar_contn_pay_info_ref ;
commit;
create  table dw_tmp.tmp_dwd_agmt_guar_contn_pay_info_ref (
 day_id	    varchar(8)                        -- 数据日期
,proj_no	   varchar(100)                      -- 项目ni
,loan_reg_dt    varchar(20)                   -- 放款登记日期
,index(proj_no)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit;

insert into dw_tmp.tmp_dwd_agmt_guar_contn_pay_info_ref
select 
'${v_sdate}'
,proj_no
,date_format(end_tm,'%Y-%m-%d')
from
(
select
proj_no
,end_tm
,row_number()over(partition by proj_no order by end_tm desc ) rn
from dw_base.dwd_evt_wf_task_info
where task_name = '放款确认'
and end_tm is not null 
and proj_no is not null 
) t
where t.rn = 1
;
commit;

-- 2.临时表存储项目id与项目编号关系
drop table if exists dw_tmp.tmp_dwd_agmt_guar_contn_pay_reg_dt ;
commit;
create  table dw_tmp.tmp_dwd_agmt_guar_contn_pay_reg_dt (
day_id          varchar(8)
,proj_id        varchar(100)
,proj_no        varchar(100)
,cust_id        varchar(60)
,loan_reg_dt    varchar(20)
,index(proj_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit;

insert into dw_tmp.tmp_dwd_agmt_guar_contn_pay_reg_dt
select 
distinct '${v_sdate}'
,t1.proj_id
,t1.proj_no
,t1.cust_id
,t2.loan_reg_dt
from dw_base.dwd_agmt_guar_proj_info t1 
left join dw_tmp.tmp_dwd_agmt_guar_contn_pay_info_ref t2
on t1.proj_no = t2.proj_no
;
commit ;

-- 续支
drop table if exists dw_tmp.dwd_agmt_guar_contn_pay_info_xz ;
commit;

create  table dw_tmp.dwd_agmt_guar_contn_pay_info_xz (
contn_pay_id	varchar(60)                        -- 续支ID
,contn_pay_no	varchar(32)                        -- 续支编号
,proj_id	varchar(100)                       -- 项目ID
,appl_amt	decimal(10,6)                  -- 续支申请金额
,contn_pay_time	int                                -- 续支期数
,guar_beg_dt	date                           -- 担保年度开始日
,guar_end_dt	date                           -- 担保年度到期日
,apply_period	int                        -- 续支申请期限
,aprv_dt	date                               -- 批复日期
,aprv_amt	decimal(10,6)                  -- 批复金额
,aprv_term	int                            -- 批复期限
,aprv_rate	decimal(10,6)                  -- 批复费率
,main_condition	varchar(2)                 -- 主体情况：01-向好 02-维持 03-不利
,main_condition_info	varchar(1000)          -- 主体情况说明
,ast_condition	varchar(2)                 -- 资产情况：01-增加 02-维持 03-减少
,ast_condition_info	varchar(1000)          -- 资产情况说明
,debt_condition	varchar(2)                 -- 负债情况：01-增加 02-维持 03-减少
,debt_condition_info	varchar(1000)          -- 负债情况说明
,income_condition	varchar(2)             -- 收入情况：01-增加 02-维持 03-下降
,income_condition_info	varchar(1000)      -- 收入情况说明
,prft_condition	varchar(2)                 -- 利润情况：01-增加 02-维持 03-下降
,prft_condition_info	varchar(1000)          -- 利润情况说明
,oppos_guar_condition	varchar(2)         -- 反担保措施情况：01-维持 02-弱化
,oppos_guar_condition_info	varchar(5000)  -- 反担保措施说明
,appr_comment	varchar(1000)              -- 审查意见
,create_name	varchar(20)                    -- 申请人姓名
,wf_inst_id	varchar(320)                   -- 流程实例Id
,status	varchar(2)                         -- 状态：10-提报中 20-审批中 30-待缴费
,create_dt date                             -- 续支开始时间
,update_dt	date                           -- 最近一次更新时间
,submit_dt  date                           -- 提报时间
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;

commit ;

insert into dw_tmp.dwd_agmt_guar_contn_pay_info_xz
select
id
,code                                   -- 续支编号
,project_id                            -- 项目编号
,apply_amount                          -- 续支申请金额
,term                                  -- 续支期数
,DATE_FORMAT(guar_annu_startdate,'%Y-%m-%d')                   -- 担保年度开始日
,DATE_FORMAT(guar_annu_duedate,'%Y-%m-%d')                     -- 担保年度到期日
,apply_period                          -- 续支申请期限
,DATE_FORMAT(appr_date,'%Y-%m-%d')                             -- 批复日期
,appr_amount                           -- 批复金额
,appr_period                           -- 批复期限
,appr_guar_rate                        -- 批复费率
,subject_condition                     -- 主体情况：01-向好 02-维持 03-不利
,subject_condition_info                -- 主体情况说明
,asset_condition                       -- 资产情况：01-增加 02-维持 03-减少
,asset_condition_info                  -- 资产情况说明
,debt_condition                        -- 负债情况：01-增加 02-维持 03-减少
,debt_condition_info                   -- 负债情况说明
,income_condition                      -- 收入情况：01-增加 02-维持 03-下降
,income_condition_info                 -- 收入情况说明
,profit_condition                      -- 利润情况：01-增加 02-维持 03-下降
,profit_condition_info                 -- 利润情况说明
,counter_guar_condition                -- 反担保措施情况：01-维持 02-弱化
,counter_guar_condition_info           -- 反担保措施说明
,appr_comment                          -- 审查意见
,create_name                           -- 申请人姓名
,wf_inst_id                            -- 流程实例Id
,status                                -- 状态：10-提报中 20-审批中 30-待缴费
,create_time
,update_time
,coalesce(submit_time, create_time)
from 
(
select
id
,code                                   -- 续支编号
,project_id                            -- 项目编号
,apply_amount                          -- 续支申请金额
,term                                  -- 续支期数
,guar_annu_startdate                   -- 担保年度开始日
,guar_annu_duedate                     -- 担保年度到期日
,apply_period                          -- 续支申请期限
,appr_date                             -- 批复日期
,appr_amount                           -- 批复金额
,appr_period                           -- 批复期限
,appr_guar_rate                        -- 批复费率
,subject_condition                     -- 主体情况：01-向好 02-维持 03-不利
,subject_condition_info                -- 主体情况说明
,asset_condition                       -- 资产情况：01-增加 02-维持 03-减少
,asset_condition_info                  -- 资产情况说明
,debt_condition                        -- 负债情况：01-增加 02-维持 03-减少
,debt_condition_info                   -- 负债情况说明
,income_condition                      -- 收入情况：01-增加 02-维持 03-下降
,income_condition_info                 -- 收入情况说明
,profit_condition                      -- 利润情况：01-增加 02-维持 03-下降
,profit_condition_info                 -- 利润情况说明
,counter_guar_condition                -- 反担保措施情况：01-维持 02-弱化
,counter_guar_condition_info           -- 反担保措施说明
,appr_comment                          -- 审查意见
,create_name                           -- 申请人姓名
,wf_inst_id                            -- 流程实例Id
,status                                -- 状态：10-提报中 20-审批中 30-待缴费
,create_time
,update_time
,submit_time
,row_number()over(partition by code order by db_update_time desc ,update_time desc ) rn
from dw_nd.ods_t_biz_proj_xz
where date_format(db_update_time,'%Y%m%d') <= '${v_sdate}'  -- mdy 20220909
) t
where t.rn = 1
;

commit ;

-- 3.数据落地
truncate  table  dw_base.dwd_agmt_guar_contn_pay_info;
commit ;

-- 续支信息
insert into dw_base.dwd_agmt_guar_contn_pay_info
select
  '${v_sdate}'                            -- 数据日期 
,t1.contn_pay_id                     -- 续支ID
,t1.contn_pay_no                     -- 续支编号
,t1.proj_id                          -- 项目ID
,t2.proj_no                          -- 项目编号
,t2.cust_id                          -- 客户id
,t1.appl_amt                         -- 续支申请金额
,t1.contn_pay_time                          -- 续支期数
,t1.guar_beg_dt                      -- 担保年度开始日
,t1.guar_end_dt                      -- 担保年度到期日
,t1.apply_period                     -- 续支申请期限
,t1.aprv_dt                          -- 批复日期
,t1.aprv_amt                         -- 批复金额
,t1.aprv_term                        -- 批复期限
,t1.aprv_rate                        -- 批复费率
,t1.main_condition                   -- 主体情况：01-向好 02-维持 03-不利
,t1.main_condition_info              -- 主体情况说明
,t1.ast_condition                    -- 资产情况：01-增加 02-维持 03-减少
,t1.ast_condition_info               -- 资产情况说明
,t1.debt_condition                   -- 负债情况：01-增加 02-维持 03-减少
,t1.debt_condition_info              -- 负债情况说明
,t1.income_condition                 -- 收入情况：01-增加 02-维持 03-下降
,t1.income_condition_info            -- 收入情况说明
,t1.prft_condition                   -- 利润情况：01-增加 02-维持 03-下降
,t1.prft_condition_info              -- 利润情况说明
,t1.oppos_guar_condition             -- 反担保措施情况：01-维持 02-弱化
,t1.oppos_guar_condition_info        -- 反担保措施说明
,t1.appr_comment                     -- 审查意见
,t1.create_name                      -- 申请人姓名
,t1.wf_inst_id                       -- 流程实例Id
,t1.status                           -- 状态：10-提报中 20-审批中 30-待缴费
,t1.create_dt
,t1.update_dt
,t1.submit_dt
from dw_tmp.dwd_agmt_guar_contn_pay_info_xz t1
left join dw_tmp.tmp_dwd_agmt_guar_contn_pay_reg_dt t2
on t1.proj_id = t2.proj_id
;
commit;
