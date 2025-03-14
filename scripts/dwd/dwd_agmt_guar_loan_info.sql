-- ---------------------------------------
-- 开发人   : liyy
-- 开发时间 ：20210311
-- 目标表   :  dwd_agmt_guar_loan_info
-- 源表     ：
--             dw_base.dwd_evt_wf_task_info         流程信息
--             dw_base.dwd_agmt_guar_contn_pay_info 续支信息
--             dw_base.dwd_agmt_guar_proj_info
--             dw_nd.ods_t_biz_proj_loan 项目放款表
--             dw_base.dwd_guar_info                历史项目信息
   
-- 变更记录 ：20210422 业务系统放款信息表中只有 本次放款日、本次到期日, 放款日期 部分迁移后没有数据，需要取历史的数据 dwd_guar_info 放款时间、到期时间
--            20211011 1.增加保后检查已终止数据 2.自主续支        
--            20220211统一修改
--            20240514 修改续支放款的取值逻辑，去掉t1.busi_type = 'ProjectXZ'，放款 inner join  续支数据 zhangfl
--            20241201 脚本的统一变更，MySQL5.0转MySQL8.0并优化逻辑 zhangfl
-- ---------------------------------------

set interactive_timeout = 7200;
set wait_timeout = 7200;

-- 1.临时表-流程放款确认
drop table if exists dw_tmp.tmp_dwd_agmt_guar_loan_info_reg_dt ;
commit;
create  table dw_tmp.tmp_dwd_agmt_guar_loan_info_reg_dt (
 day_id	    varchar(8)                        -- 数据日期
,proj_no	varchar(100)                      -- 项目ni
,loan_reg_dt    date                          -- 放款登记日期
,index(proj_no)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit;

insert into dw_tmp.tmp_dwd_agmt_guar_loan_info_reg_dt
select
'${v_sdate}'
,proj_no
,date_format(end_tm,'%Y-%m-%d')
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

-- 2.临时表存储项目id与项目编号关系
drop table if exists dw_tmp.tmp_dwd_agmt_guar_loan_info_main_reg_dt ;
commit;
create  table dw_tmp.tmp_dwd_agmt_guar_loan_info_main_reg_dt (
day_id          varchar(8)
,proj_id        varchar(100)
,proj_no        varchar(100)
,cust_id        varchar(60)
,loan_reg_dt    varchar(20)
,index(proj_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit;

insert into dw_tmp.tmp_dwd_agmt_guar_loan_info_main_reg_dt
select 
distinct '${v_sdate}'
,t1.proj_id
,t1.proj_no
,t1.cust_id
,t2.loan_reg_dt
from dw_base.dwd_agmt_guar_proj_info t1 
left join dw_tmp.tmp_dwd_agmt_guar_loan_info_reg_dt t2
on t1.proj_no = t2.proj_no
;
commit ;

-- 3.临时表--续支项目信息id与项目编号关系
drop table if exists dw_tmp.tmp_dwd_agmt_guar_loan_info_xz_reg_dt ;
commit;
create  table dw_tmp.tmp_dwd_agmt_guar_loan_info_xz_reg_dt (
day_id          varchar(8)
,contn_pay_id   varchar(100)
,contn_pay_no   varchar(100)
,proj_id        varchar(100)
,proj_no        varchar(100)
,cust_id        varchar(60)
,loan_reg_dt    date
,index(contn_pay_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit;

insert into dw_tmp.tmp_dwd_agmt_guar_loan_info_xz_reg_dt
select 
distinct '${v_sdate}'
,t1.contn_pay_id                     -- 续支ID
,t1.contn_pay_no                     -- 续支编号
,t1.proj_id                          -- 项目ID
,t1.proj_no                          -- 项目编号
,t1.cust_id                          -- 客户id
,t2.loan_reg_dt
from dw_base.dwd_agmt_guar_contn_pay_info t1 
left join dw_tmp.tmp_dwd_agmt_guar_loan_info_reg_dt  t2 
on t1.contn_pay_no = t2.proj_no
;
commit ;


-- 4.担保放款信息
drop table if exists dw_tmp.tmp_dwd_agmt_guar_loan_info ;
commit;
create  table dw_tmp.tmp_dwd_agmt_guar_loan_info (
id	            varchar(60)           comment '放款id'
,busi_id	    varchar(100)          comment '业务id（项目ID或续支ID）'
,busi_type	    varchar(32)           comment '业务类型'
,loan_letter_no	varchar(255)          comment '放款通知书编号'
,loan_letter_dt	date                  comment '放款通知书日期'
,risk_class	    varchar(2)            comment '五级分类'
,debt_no	    varchar(600)          comment '借据编号'
,loan_dt	    date                  comment '放款日期'
,loan_amt	    decimal(10,2)         comment '放款金额'
,loan_beg_dt	date                  comment '贷款开始日'
,loan_end_dt	date                  comment '贷款结束日'
,loan_reg_dt    date                  comment '放款登记日'
,index(busi_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit;

insert into dw_tmp.tmp_dwd_agmt_guar_loan_info
select 
id	                    -- 自增id
,project_id	            -- 项目/续支id
,business_type	        -- 业务类型
,fk_letter_code	        -- 放款通知书编号
,fk_letter_date	        -- 放款通知书日期
,five_level_classify	-- 五级分类
,debt_on_bond_code	    -- 借据编号
,fk_date	            -- 放款日期
,fk_amount	            -- 放款金额
,fk_start_date	        -- 贷款开始日
,fk_end_date	        -- 贷款结束日
,update_time
from 
(
select 
id	                    -- 自增id
,project_id	            -- 项目id
,business_type	        -- 业务类型
,fk_letter_code	        -- 放款通知书编号
,fk_letter_date	        -- 放款通知书日期
,five_level_classify	-- 五级分类
,debt_on_bond_code	    -- 借据编号
,fk_date	            -- 放款日期
,fk_amount	            -- 放款金额
,coalesce(fk_date,fk_start_date)  fk_start_date  	        -- 贷款开始日 modify 20210422
,fk_end_date	        -- 贷款结束日
,update_time
,db_update_time
,row_number()over(partition by project_id order by db_update_time desc ) rn
from dw_nd.ods_t_biz_proj_loan
where date_format(db_update_time,'%Y%m%d') <= '${v_sdate}'  -- 新增
) t
where t.rn = 1
;
commit ;


-- 5.取历史的贷款开始时间、结束时间(昨天的数据) -- 20241201 新系统这个表空数据
drop table if exists dw_tmp.tmp_dwd_agmt_guar_loan_info1 ;
commit;
create  table dw_tmp.tmp_dwd_agmt_guar_loan_info1 (
guar_id varchar(60)
,loan_beg_dt	date                  comment '贷款开始日'
,loan_end_dt	date                  comment '贷款结束日'
,loan_reg_dt    date                  comment '放款登记日'
,index(guar_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit;

insert into dw_tmp.tmp_dwd_agmt_guar_loan_info1
select
guar_id
,case when loan_begin_dt ='' then null else DATE_FORMAT(loan_begin_dt,'%Y-%m-%d') end
,case when loan_end_dt ='' then null else DATE_FORMAT(loan_end_dt,'%Y-%m-%d') end
,coalesce(case when loan_begin_dt ='' then null else DATE_FORMAT(loan_begin_dt,'%Y-%m-%d') end,
          case when loan_end_dt ='' then null else DATE_FORMAT(loan_end_dt,'%Y-%m-%d') end)
from dw_base.dwd_guar_info 
where item_stt in ('已放款','已解保')
;
commit ;



-- 6.数据落地
truncate  table  dw_base.dwd_agmt_guar_loan_info;
commit ;

-- 6.1主项目申请
insert into dw_base.dwd_agmt_guar_loan_info
select
  '${v_sdate}'
,id	            -- 放款id 
,busi_id	    -- 项目id（项目ID或续支ID）
,t2.proj_no     -- 项目编码 项目编码（粒度合同）
,t2.proj_no     -- 项目编码 项目编号（粒度支用，第一笔和项目编号相同，其余的为XZ项目编号）
,t2.cust_id      -- 客户id
,t1.busi_type      -- 业务类型
,t1.loan_letter_no	-- 放款通知书编号
,t1.loan_letter_dt	-- 放款通知书日期
,t1.risk_class	    -- 五级分类
,t1.debt_no	    -- 借据编号
,coalesce(t1.loan_dt,t3.loan_beg_dt)	    -- 放款日期
,t1.loan_amt	    -- 放款金额
,coalesce(t1.loan_beg_dt,t3.loan_beg_dt)	-- 贷款开始日
,coalesce(t1.loan_end_dt,t3.loan_end_dt)	-- 贷款结束日
,coalesce(t2.loan_reg_dt,t3.loan_reg_dt)    -- 贷款登记日 
from dw_tmp.tmp_dwd_agmt_guar_loan_info t1
left join dw_tmp.tmp_dwd_agmt_guar_loan_info_main_reg_dt t2
on t1.busi_id = t2.proj_id
left join dw_tmp.tmp_dwd_agmt_guar_loan_info1 t3
on t2.proj_no = t3.guar_id
where t1.busi_type = 'ProjectRegister'  -- 项目申请
or t1.busi_type is null 
;

commit ;


-- 6.2项目续支
insert into dw_base.dwd_agmt_guar_loan_info
select
 '${v_sdate}'
,id	            -- 放款id 
,busi_id	    -- 项目id（项目ID或续支ID）
,t2.proj_no     -- 项目编码
,t2.contn_pay_no   -- 续支编号
,t2.cust_id      -- 客户id
,t1.busi_type      -- 业务类型
,t1.loan_letter_no	-- 放款通知书编号
,t1.loan_letter_dt	-- 放款通知书日期
,t1.risk_class	    -- 五级分类
,t1.debt_no	    -- 借据编号
,coalesce(t1.loan_dt,t3.loan_beg_dt)	    -- 放款日期
,t1.loan_amt	    -- 放款金额
,coalesce(t1.loan_beg_dt,t3.loan_beg_dt)	-- 贷款开始日
,coalesce(t1.loan_end_dt,t3.loan_end_dt)	-- 贷款结束日
,coalesce(t2.loan_reg_dt,t3.loan_reg_dt)    -- 贷款登记日
from dw_tmp.tmp_dwd_agmt_guar_loan_info t1
inner join dw_tmp.tmp_dwd_agmt_guar_loan_info_xz_reg_dt t2 -- mdy 20240514
on t1.busi_id = t2.contn_pay_id
left join dw_tmp.tmp_dwd_agmt_guar_loan_info1 t3
on t2.proj_no = t3.guar_id
-- where t1.busi_type = 'ProjectXZ'  -- 项目申请 del 20240514
;

commit ;