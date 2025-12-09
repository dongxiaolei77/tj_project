-- ----------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20241212
-- 目标表   ：dw_base.dwd_tjnd_report_proj_ovd_info      逾期记录
-- 源表     ：dw_base.dwd_nacga_report_guar_info_base_info               国担上报范围表
--            dw_nd.ods_tjnd_yw_z_report_bh_overdue_plan                          逾期登记表
-- 备注     ：
-- 变更记录 ：
-- ----------------------------------------
-- 日增量加载
delete
from dw_base.dwd_tjnd_report_proj_ovd_info
where day_id = '${v_sdate}';
commit;
-- 老系统数据不上报
-- insert into dw_base.dwd_tjnd_report_proj_ovd_info
-- ( day_id
-- , proj_no_prov -- 省农担担保项目编号
-- , ovd_dt -- 逾期日期
-- , ovd_amt -- 逾期本金金额
-- , other_ovd_amt -- 逾期利息以及其他费用金额
-- , other_ovd_bal -- 逾期利息以及其他费用金额余额
-- , ovd_prin_rmv_bank_rk_seg_amt -- 逾期本金(扣除银行分险)
-- , other_ovd_rmv_bank_rk_seg_amt -- 逾期利息以及其他费用金额(扣除银行分险)
-- , ovd_prin_rmv_bank_rk_seg_bal -- 逾期本金余额(扣除银行分险)
-- , other_ovd_rmv_bank_rk_seg_bal -- 逾期利息以及其他费用金额余额(扣除银行分险)
-- , subj_rk_rsn_cd -- 客观风险类型代码
-- , obj_rk_rsn_cd -- 主观风险类型代码
-- , ovd_rsn_desc -- 项目逾期原因详述
-- , rk_mtg_meas -- 风险化解措施
-- , ovd_prin_bal -- 逾期本金余额
-- , dict_flag)
-- select distinct '${v_sdate}'                                 as day_id
--               , t1.biz_no                                    as proj_no_prov
--               , date_format(t2.overdue_pri_time, '%Y-%m-%d') as ovd_dt
--               , coalesce(t2.overdue_pri * 10000, 0)          as ovd_amt
--               , coalesce(t2.overdue_int * 10000, 0)          as other_ovd_amt
--               , null                                         as other_ovd_bal
--               , null                                         as ovd_prin_rmv_bank_rk_seg_amt
--               , null                                         as other_ovd_rmv_bank_rk_seg_amt
--               , null                                         as ovd_prin_rmv_bank_rk_seg_bal
--               , null                                         as other_ovd_rmv_bank_rk_seg_bal
--               , t2.overdue_reason                            as subj_rk_rsn_cd  -- 客观风险类型代码
--               , t2.overdue_sub_reason                        as obj_rk_rsn_cd   -- 主观风险类型代码
--               , t2.pla_describe                              as ovd_rsn_desc
--               , t2.manage_plan                               as rk_mtg_meas
--               , null                                         as ovd_prin_bal
--               , 0                                            as dict_flag
-- from dw_base.dwd_nacga_report_guar_info_base_info t1 -- 国担上报范围表
--          inner join dw_nd.ods_creditmid_v2_z_migrate_bh_overdue_plan t2 -- 逾期登记表
--                     on t1.biz_id = t2.id_cfbiz_underwriting
-- where t1.day_id = '${v_sdate}'
-- ;
-- commit;

-- 新系统逻辑
insert into dw_base.dwd_tjnd_report_proj_ovd_info
( day_id
, proj_no_prov -- 省农担担保项目编号
, ovd_dt -- 逾期日期
, ovd_amt -- 逾期本金金额
, other_ovd_amt -- 逾期利息以及其他费用金额
, other_ovd_bal -- 逾期利息以及其他费用金额余额
, ovd_prin_rmv_bank_rk_seg_amt -- 逾期本金(扣除银行分险)
, other_ovd_rmv_bank_rk_seg_amt -- 逾期利息以及其他费用金额(扣除银行分险)
, ovd_prin_rmv_bank_rk_seg_bal -- 逾期本金余额(扣除银行分险)
, other_ovd_rmv_bank_rk_seg_bal -- 逾期利息以及其他费用金额余额(扣除银行分险)
, subj_rk_rsn_cd -- 客观风险类型代码
, obj_rk_rsn_cd -- 主观风险类型代码
, ovd_rsn_desc -- 项目逾期原因详述
, rk_mtg_meas -- 风险化解措施
, ovd_prin_bal -- 逾期本金余额
, dict_flag)
select '${v_sdate}'                                 as day_id
      , t2.guar_id                                    as proj_no_prov
      , date_format(t1.overdue_date, '%Y-%m-%d') as ovd_dt        -- 逾期日期
      , coalesce(t1.overdue_principal, 0)            as ovd_amt       -- 逾期本金金额
      , coalesce(t1.overdue_int, 0)                  as other_ovd_amt -- 逾期利息以及其他费用金额
      , coalesce(t1.overdue_int, 0)                  as other_ovd_bal -- 逾期利息以及其他费用金额余额
      , coalesce(t1.overdue_principal * (1 - if(t2.guar_id like 'TJ%', t23.bank_org_rate, t3.bank_risk / 100)), 0)  as ovd_prin_rmv_bank_rk_seg_amt                -- 逾期本金(扣除银行分险)                     [逾期本金金额 * （1 - 银行分险比例）]
      , coalesce(t1.overdue_int * (1 - if(t2.guar_id like 'TJ%', t23.bank_org_rate, t3.bank_risk / 100)), 0)        as other_ovd_rmv_bank_rk_seg_amt               -- 逾期利息以及其他费用金额(扣除银行分险)     [逾期利息 * （1 - 银行分险比例）]
      , coalesce(t1.overdue_principal * (1 - if(t2.guar_id like 'TJ%', t23.bank_org_rate, t3.bank_risk / 100)), 0)  as ovd_prin_rmv_bank_rk_seg_bal                -- 逾期本金余额(扣除银行分险)                 [逾期本金金额 * （1 - 银行分险比例）]
      , coalesce(t1.overdue_int * (1 - if(t2.guar_id like 'TJ%', t23.bank_org_rate, t3.bank_risk / 100)), 0)        as other_ovd_rmv_bank_rk_seg_bal               -- 逾期利息以及其他费用金额余额(扣除银行分险) [逾期利息 * （1 - 银行分险比例）]
      , coalesce(t1.objective_risk_type,t1.objective_risk_type_relation)                       as subj_rk_rsn_cd -- 客观风险类型代码
      , t1.subjective_risk_type                      as obj_rk_rsn_cd  -- 主观风险类型代码
      , t1.overdue_reason_detail                     as ovd_rsn_desc   -- 项目逾期原因详述
      , t1.risk_resolution_measures                  as rk_mtg_meas    -- 风险化解措施
      , null                                         as ovd_prin_bal
      , 1                                            as dict_flag
from (
       select task_id
	         ,project_id
             ,overdue_principal            --  逾期本金
			 ,overdue_int                  --  逾期利息（元）
			 ,overdue_date                 --  逾期日期
			 ,objective_risk_type          -- 客观风险类型
			 ,substring_index(regexp_replace(objective_risk_type_relation, '"|\\[|\\]', ''), ',', 1) as objective_risk_type_relation -- 客观风险类型
			 ,subjective_risk_type         -- 主观风险类型
			 ,overdue_reason_detail        -- 项目逾期原因详述
			 ,risk_resolution_measures     -- 风险化解措施
       from (select *,row_number() over (partition by project_id order by db_update_time desc,update_time desc) rn from dw_nd.ods_t_loan_after_check where is_delete = '0') a  -- 保后检查表
	   where a.rn = 1 
	     and is_debt_overdue != '0'    -- 本次贷款是否逾期  [判断这笔项目为逾期；0-未逾期，1-本息逾期，2-利息逾期，3-本金逾期]    
		 and overdue_date is not null  -- [判断这笔项目为逾期]
	 ) t1 
left join dw_base.dwd_guar_info_stat t2 -- 业务台账表
on t1.project_id = t2.project_id
left join(select biz_no,bank_risk from dw_base.dwd_tjnd_report_biz_loan_bank where day_id = '${v_sdate}') t3 -- 省担国担银行分险比例映射底表
on t2.guar_id = t3.biz_no 
left join (
            select id       -- 主键id
			      ,pool_id  -- 任务池id
			from (select *,row_number() over (partition by id order by db_update_time desc,update_time desc) rn from dw_nd.ods_t_loan_after_task) b -- 保后任务详情表
			where b.rn = 1 and task_status in ('40','50','93','94','95')  -- [这些是已完成的项目]
		  ) t4
on t1.task_id = t4.id
left join (
            select id      -- 主键id
			from (select *,row_number() over (partition by id order by db_update_time desc,update_time desc) rn from dw_nd.ods_t_loan_after_task_pool) c  -- 保后任务池           [在保后检查完成的页面才能提报，用这个表判断]
			where c.rn = 1
		  ) t5 
on t4.pool_id = t5.id
left join dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation t21 on t2.project_id = t21.id              -- [这一块是算老系统数据的银行分险比例]
left join dw_nd.ods_tjnd_yw_base_cooperative_institution_agreement t23 -- 合作机构表（老逻辑底表）
on t21.related_agreement_id = t23.ID
inner join dw_base.dwd_tjnd_report_biz_no_base t24  -- 国担上报范围表
on t1.project_id = t24.biz_id and t24.day_id = '${v_sdate}'
where t5.id is not null
;
commit;
-- [不是逾期在保的变更金额为0]
update dw_base.dwd_tjnd_report_proj_ovd_info t1  
left join (select guar_id,item_stt from dw_base.dwd_guar_info_all where day_id = '${v_sdate}') t2 
on t1.proj_no_prov = t2.guar_id 
set
  t1.ovd_amt = null -- 逾期本金金额
, t1.other_ovd_amt = null -- 逾期利息以及其他费用金额
, t1.other_ovd_bal = null -- 逾期利息以及其他费用金额余额
, t1.ovd_prin_rmv_bank_rk_seg_amt = null -- 逾期本金(扣除银行分险)
, t1.other_ovd_rmv_bank_rk_seg_amt = null -- 逾期利息以及其他费用金额(扣除银行分险)
, t1.ovd_prin_rmv_bank_rk_seg_bal = 0 -- 逾期本金余额(扣除银行分险)
, t1.other_ovd_rmv_bank_rk_seg_bal = 0 -- 逾期利息以及其他费用金额余额(扣除银行分险)
where t1.day_id = '${v_sdate}' and t2.item_stt != '已放款'
;
commit;
