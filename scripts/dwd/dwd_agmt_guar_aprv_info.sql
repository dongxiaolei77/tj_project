-- ---------------------------------------
-- 开发人   : liyy
-- 开发时间 ：20210311
-- 目标表   :  dwd_agmt_guar_aprv_info
-- 源表     ：dw_nd.ods_t_biz_proj_appr
--            dw_base.dwd_agmt_guar_proj_info
--            dw_base.dwd_agmt_guar_loan_info
--            dw_base.dwd_evt_wf_task_info
--            dw_base.dwd_agmt_guar_contn_pay_info  续支项目信息
-- 变更记录 ：20210422 业务系统放款信息表中只有 本次放款日、本次到期日, 放款日期 部分迁移后没有数据，需要取历史的数据 dwd_guar_info 放款时间、到期时间
--            20211011 1.增加保后检查已终止数据 2.自主续支        
--            20220211统一修改
--            20241201 脚本的统一变更，MySQL5.0转MySQL8.0并优化逻辑 zhangfl
-- ---------------------------------------
set interactive_timeout = 7200;
set wait_timeout = 7200;

-- 1. 临时表-批复
drop table if exists dw_tmp.tmp_dwd_agmt_guar_aprv_info ;
commit;
create  table dw_tmp.tmp_dwd_agmt_guar_aprv_info (
 day_id	    varchar(8)                        -- 数据日期
,aprv_id	varchar(100)                      -- 批复ID
,proj_id	varchar(100)                      -- 项目ID
,loan_type	varchar(20)                       -- 贷款方式
,busi_type	varchar(32)                       -- 业务类型
,aprv_no	varchar(40)                       -- 批复编号
,aprv_dt	date                              -- 批复日期
,aprv_amt	decimal(10,6)                     -- 批复金额(万元)
,aprv_term	int                               -- 批复期限(月)
,aprv_oppos_guar_cd	varchar(60)               -- 批复反担保措施 01-无02-抵押03-质押04-保证05-以物抵债00-其他
,aprv_oppos_guar_desc	varchar(5000)         -- 批复反担保措施说明
,guar_rate	decimal(10,6)                     -- 担保费率
,demand	varchar(1000)                         -- 限制性条件或其他
,aprv_sugt	varchar(1000)                     -- 批复意见
,index(proj_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit;

insert into dw_tmp.tmp_dwd_agmt_guar_aprv_info
select 
  '${v_sdate}' -- 数据日期
,id	                        -- 自增主键
,project_id	                -- 项目ID
,loan_type	                -- 贷款方式
,business_type	            -- 业务类型
,reply_code	                -- 批复编号
,reply_date	                -- 批复日期
,reply_amount	            -- 批复金额(万元)
,reply_period	            -- 批复期限(月)
,reply_counter_guar_meas	-- 批复反担保措施
,reply_counter_guar_desc	-- 批复反担保措施说明
,guar_rate	                -- 担保费率
,demand	                    -- 限制性条件或其他
,message	                -- 批复意见
from 
(
select
id	                        -- 自增主键
,project_id	                -- 项目ID
,loan_type	                -- 贷款方式
,business_type	            -- 业务类型
,reply_code	                -- 批复编号
,reply_date	                -- 批复日期
,reply_amount	            -- 批复金额(万元)
,reply_period	            -- 批复期限(月)
,reply_counter_guar_meas	-- 批复反担保措施
,reply_counter_guar_desc	-- 批复反担保措施说明
,guar_rate	                -- 担保费率
,demand	                    -- 限制性条件或其他
,message	                -- 批复意见
,update_time
,db_update_time
,row_number()over(partition by project_id order by db_update_time desc ) rn
from dw_nd.ods_t_biz_proj_appr
where  date_format(db_update_time,'%Y%m%d') <= '${v_sdate}'  --  新增
) t1
where t1.rn = 1
;
commit ;

-- 2.临时表-流程放款确认
drop table if exists dw_tmp.tmp_dwd_agmt_guar_aprv_reg_dt ;
commit;

create  table dw_tmp.tmp_dwd_agmt_guar_aprv_reg_dt (
 day_id	    varchar(8)                        -- 数据日期
,proj_no	   varchar(100)                      -- 项目ni
,loan_reg_dt    varchar(20)                   -- 放款登记日期
,index(proj_no)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit;

insert into dw_tmp.tmp_dwd_agmt_guar_aprv_reg_dt
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

-- 3.临时表存储项目id与项目编号关系
drop table if exists dw_tmp.tmp_dwd_agmt_guar_aprv_info_ref ;
commit;
create  table dw_tmp.tmp_dwd_agmt_guar_aprv_info_ref (
day_id          varchar(8)
,proj_id        varchar(100)
,proj_no        varchar(100)
,cust_id        varchar(60)
,loan_reg_dt    varchar(20)
,index(proj_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit;

insert into dw_tmp.tmp_dwd_agmt_guar_aprv_info_ref
select 
distinct '${v_sdate}'
,t1.proj_id
,t1.proj_no
,t1.cust_id
,t2.loan_reg_dt
from dw_base.dwd_agmt_guar_proj_info t1 
left join dw_tmp.tmp_dwd_agmt_guar_aprv_reg_dt t2
on t1.proj_no = t2.proj_no
;
commit ;



-- 4.临时表--续支项目信息id与项目编号关系
drop table if exists dw_tmp.tmp_dwd_agmt_guar_contn_pay_info_ref ;
commit;
create  table dw_tmp.tmp_dwd_agmt_guar_contn_pay_info_ref (
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

insert into dw_tmp.tmp_dwd_agmt_guar_contn_pay_info_ref
select 
distinct '${v_sdate}'
,t1.contn_pay_id                     -- 续支ID
,t1.contn_pay_no                     -- 续支编号
,t1.proj_id                          -- 项目ID
,t1.proj_no                          -- 项目编号
,t1.cust_id                          -- 客户id
,t2.loan_reg_dt
from dw_base.dwd_agmt_guar_contn_pay_info t1 
left join dw_tmp.tmp_dwd_agmt_guar_aprv_reg_dt  t2 
on t1.contn_pay_no = t2.proj_no
;
commit ;

-- 5.数据落地
truncate  table  dw_base.dwd_agmt_guar_aprv_info;
commit;
-- 5.1进件项目批复
insert into dw_base.dwd_agmt_guar_aprv_info
select
 t1.day_id	              -- 数据日期
,t1.aprv_id 	          -- 批复ID
,t1.proj_id	              -- 项目ID
,t2.proj_no               -- 项目编码（粒度合同）
,t2.proj_no               -- 项目编号（粒度支用，第一笔和项目编号相同，其余的为XZ项目编号）
,t2.cust_id
,t1.loan_type	          -- 贷款方式 0	普通贷款 1	自主循环贷（随借随还） 2	非自主循环贷（一年一支用）
,t1.busi_type	          -- 业务类型
,t1.aprv_no	              -- 批复编号
,t1.aprv_dt	              -- 批复日期
,t1.aprv_amt	          -- 批复金额(万元)
,t1.aprv_term	          -- 批复期限(月)
,t1.aprv_oppos_guar_cd	  -- 批复反担保措施 01-无02-抵押03-质押04-保证05-以物抵债00-其他
,t1.aprv_oppos_guar_desc  -- 批复反担保措施说明
,t1.guar_rate	          -- 担保费率
,t1.demand	              -- 限制性条件或其他
,t1.aprv_sugt	          -- 批复意见
from dw_tmp.tmp_dwd_agmt_guar_aprv_info t1
left join dw_tmp.tmp_dwd_agmt_guar_aprv_info_ref t2
on t1.proj_id = t2.proj_id
where t1.busi_type = 'ProjectRegister' or t1.busi_type is null 
;
commit;


-- 5.2续支批复
insert into dw_base.dwd_agmt_guar_aprv_info
select
 t1.day_id	              -- 数据日期
,t1.aprv_id 	          -- 批复ID
,t1.proj_id	              -- 项目ID
,t2.proj_no               -- 项目编码（粒度合同）
,t2.contn_pay_no          -- 项目编号（粒度支用，第一笔和项目编号相同，其余的为XZ项目编号）
,t2.cust_id
,t1.loan_type	          -- 贷款方式 0	普通贷款 1	自主循环贷（随借随还） 2	非自主循环贷（一年一支用）
,t1.busi_type	          -- 业务类型
,t1.aprv_no	              -- 批复编号
,t1.aprv_dt	              -- 批复日期
,t1.aprv_amt	          -- 批复金额(万元)
,t1.aprv_term	          -- 批复期限(月)
,t1.aprv_oppos_guar_cd	  -- 批复反担保措施 01-无02-抵押03-质押04-保证05-以物抵债00-其他
,t1.aprv_oppos_guar_desc  -- 批复反担保措施说明
,t1.guar_rate	          -- 担保费率
,t1.demand	              -- 限制性条件或其他
,t1.aprv_sugt	          -- 批复意见
from dw_tmp.tmp_dwd_agmt_guar_aprv_info t1
left join dw_tmp.tmp_dwd_agmt_guar_contn_pay_info_ref t2
on t1.proj_id = t2.proj_id
where t1.busi_type = 'ProjectXZ'
;
commit;
