-- ---------------------------------------
-- 开发人   : liyy
-- 开发时间 ：20210311
-- 目标表   :  dwd_agmt_guar_check_info
-- 源表     ： dw_base.dwd_evt_wf_task_info
--             dw_base.dwd_agmt_guar_proj_info
--             dw_nd.ods_t_biz_proj_loan_check 贷后检查信息表

-- 变更记录 ：20210422 业务系统放款信息表中只有 本次放款日、本次到期日, 放款日期 部分迁移后没有数据，需要取历史的数据 dwd_guar_info 放款时间、到期时间
--            20211011 1.增加保后检查已终止数据 2.自主续支        
--            20220211统一修改
--            20241201 脚本的统一变更，MySQL5.0转MySQL8.0并优化逻辑 zhangfl
-- ---------------------------------------

set interactive_timeout = 7200;
set wait_timeout = 7200;

-- 1.临时表--流程放款确认
drop table if exists dw_tmp.tmp_dwd_agmt_guar_check_info_reg_dt ;
commit;
create  table dw_tmp.tmp_dwd_agmt_guar_check_info_reg_dt 
(
 day_id	         varchar(8)         -- 数据日期
,proj_no	     varchar(100)       -- 项目ni
,loan_reg_dt     varchar(20)        -- 放款登记日期
,index(proj_no)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit;

insert into dw_tmp.tmp_dwd_agmt_guar_check_info_reg_dt
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
drop table if exists dw_tmp.tmp_dwd_agmt_guar_proj_info_ref ;
commit;

create  table dw_tmp.tmp_dwd_agmt_guar_proj_info_ref (
day_id          varchar(8)
,proj_id        varchar(100)
,proj_no        varchar(100)
,cust_id        varchar(60)
,loan_reg_dt    varchar(20)
,index(proj_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit;

insert into dw_tmp.tmp_dwd_agmt_guar_proj_info_ref
select 
distinct '${v_sdate}'
,t1.proj_id
,t1.proj_no
,t1.cust_id
,t2.loan_reg_dt
from dw_base.dwd_agmt_guar_proj_info t1 
left join dw_tmp.tmp_dwd_agmt_guar_check_info_reg_dt t2
on t1.proj_no = t2.proj_no
;
commit ;

-- 3.数据落地-贷后检查
truncate  table  dw_base.dwd_agmt_guar_check_info;
commit ;

insert into dw_base.dwd_agmt_guar_check_info
select 
  '${v_sdate}' -- 数据日期
,t2.id	                            -- 保后检核id
,t2.code	                        -- 保后检核编号
,t2.project_id	                    -- 项目id
,t3.proj_no                     -- 项目编号
,t3.cust_id                     -- 客户编号
,t2.type                        -- 业务类型，01普通贷款业务，02续支自助循环贷业务
,t2.report_date	                -- 登记日期
,t2.check_date	                    -- 检查日期
,t2.guar_annu_startdate	        -- 担保年度开始日
,t2.guar_annu_duedate	            -- 担保年度到期日
,t2.check_mode	                    -- 检查方式：01-现场
,t2.check_conclusion	            -- 检查结论：01-正常
,t2.risk_disposition_way	        -- 风险处置方式：01-解保
,t2.risk_disposition_conclusion	-- 风险处置结论：01-预警
,t2.risk_disposition_comment	    -- 风险处置说明
,t2.guar_rate                      -- 担保费率
,t2.send_guar_fee	                -- 是否发送保费账单
,t2.status	                        -- 检查状态：01-登记中
,create_time
,update_time
,coalesce(submit_time, create_time)
,t2.appr_amount
from 
(
select
id	                            -- 主键
,code	                        -- 业务编号
,project_id	                    -- 项目id
,type                           -- 业务类型，01普通贷款业务，02续支自助循环贷业务
,report_date	                -- 登记日期
,check_date	                    -- 检查日期
,guar_annu_startdate	        -- 担保年度开始日
,guar_annu_duedate	            -- 担保年度到期日
,check_mode	                    -- 检查方式：01-现场 02-非现场
,check_conclusion	            -- 检查结论：01-正常 02-关注 03-可疑 04-次级 05-损失
,risk_disposition_way	        -- 风险处置方式：01-解保 02-代偿
,risk_disposition_conclusion	-- 风险处置结论：01-预警 02-解除 03-未解除
,risk_disposition_comment	    -- 风险处置说明
,guar_rate                      -- 担保费率
,send_guar_fee	                -- 是否发送保费账单
,status	                        -- 检查状态：01-登记中 02-确认中 03-已确认 98-已终止 99-已否决
,create_time
,update_time
,submit_time
,is_delete
,db_update_time
,appr_amount
from 
(
select 
id	                            -- 主键
,code	                        -- 业务编号
,project_id	                    -- 项目id
,type                           -- 业务类型，01普通贷款业务，02续支自助循环贷业务
,report_date	                -- 登记日期
,check_date	                    -- 检查日期
,guar_annu_startdate	        -- 担保年度开始日
,guar_annu_duedate	            -- 担保年度到期日
,check_mode	                    -- 检查方式：01-现场
,check_conclusion	            -- 检查结论：01-正常
,risk_disposition_way	        -- 风险处置方式：01-解保
,risk_disposition_conclusion	-- 风险处置结论：01-预警
,risk_disposition_comment	    -- 风险处置说明
,guar_rate                      -- 担保费率
,send_guar_fee	                -- 是否发送保费账单
,status	                        -- 检查状态：01-登记中
,create_time
,update_time
,submit_time
,is_delete
,appr_amount                    -- 年段担保金额
,db_update_time
,row_number()over(partition by code order by db_update_time desc ) rn
from dw_nd.ods_t_biz_proj_loan_check
where date_format(db_update_time,'%Y%m%d') <= '${v_sdate}'  -- 新增
) t1
where t1.rn = 1
) t2
left join dw_tmp.tmp_dwd_agmt_guar_proj_info_ref t3
on t2.project_id = t3.proj_id
where t2.is_delete = '0'
;
commit ;