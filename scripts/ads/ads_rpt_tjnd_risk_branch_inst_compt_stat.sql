-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250515
-- 目标表   ：dw_base.ads_rpt_tjnd_risk_branch_inst_compt_stat 风险部-省级农担公司分支机构代偿情况统计季报
-- 源表     ：
--          新业务系统
--          dw_base.dwd_guar_info_all                           担保台账信息
--          dw_base.dwd_imp_area_branch                         区划映射办事处
--          dw_base.dwd_guar_info_onguar                        担保台账在保信息
--          dw_nd.ods_t_biz_proj_recovery_record                追偿记录表
--          dw_nd.ods_t_biz_proj_recovery_repay_detail_record   登记还款记录
--          dw_base.dwd_guar_compt_info                         代偿信息汇总表
--
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------4
-- step0 重跑策略
delete
from dw_base.ads_rpt_tjnd_risk_branch_inst_compt_stat
where day_id = '${v_sdate}';
commit;

-- 旧系统逻辑


-- 新系统逻辑
select '${v_sdate}'                        as day_id,
       case
           when branch_off = 'NHDLBranch' then '宁河东丽办事处'
           when branch_off = 'JNBHBranch' then '津南滨海新区办事处'
           when branch_off = 'BCWQBranch' then '武清北辰办事处'
           when branch_off = 'XQJHBranch' then '西青静海办事处'
           when branch_off = 'JZBranch' then '蓟州办事处'
           when branch_off = 'BDBranch' then '宝坻办事处'
           end                             as inst_name,
       '办事处'                               as inst_type,
       case
           when branch_off = 'NHDLBranch' then 4
           when branch_off = 'JNBHBranch' then 4
           when branch_off = 'BCWQBranch' then 4
           when branch_off = 'XQJHBranch' then 4
           when branch_off = 'JZBranch' then 5
           when branch_off = 'BDBranch' then 4
           end                             as off_staff_cnt,
       sum(t3.compt_amt)                   as compt_amt,
       count(t3.guar_id)                   as compt_cnt,
       sum(case when year(t2.unguar_dt) = year('${v_sdate}') and t1.item_stt = '已解保' then guar_amt end) +
       sum(t3.compt_amt)                   as release_amt,
       sum(case when year(t2.unguar_dt) = year('${v_sdate}') and t1.item_stt = '已解保' then 1 else 0 end) +
       count(t3.guar_id)                   as release_cnt,
       round(sum(t3.compt_amt) /
             (sum(case when year(t2.unguar_dt) = year('${v_sdate}') and t1.item_stt = '已解保' then guar_amt end) +
              sum(t3.compt_amt) * 100), 2) as compt_chance,
       sum(year_recovery_amt)              as risk_amt,
       round((sum(t3.compt_amt) - sum(year_recovery_amt)) /
             (sum(case when year(t2.unguar_dt) = year('${v_sdate}') and t1.item_stt = '已解保' then guar_amt end) +
              sum(t3.compt_amt) * 100), 2) as risk_chance
from (
         select guar_id,
                country_code,
                item_stt,
                guar_amt
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and '${v_sdate}' =
               date_format(last_day(makedate(extract(year from '${v_sdate}'), 1) +
                                    interval quarter('${v_sdate}') * 3 - 1 month),
                           '%Y%m%d')
     ) t1
         left join
     (
         select guar_id,    -- 业务编号
                project_id, -- 项目id
                unguar_dt   -- 解保日期
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select guar_id    as guar_id,    -- 项目编号
                compt_time as compt_date, -- 代偿拨付日期
                compt_amt  as compt_amt   -- 代偿金额(本息)万元
         from dw_base.dwd_guar_compt_info
         where day_id = '${v_sdate}'
           and year(compt_time) = year('${v_sdate}')
     ) t3 on t1.guar_id = t3.guar_id
         left join
     (
         select t1.project_id,                                     -- 项目id
                sum(t2.shou_comp_amt) / 10000 as year_recovery_amt -- 当年追偿金额
         from dw_nd.ods_t_biz_proj_recovery_record t1
                  left join dw_nd.ods_t_biz_proj_recovery_repay_detail_record t2 on t1.reco_id = t2.record_id
         where year(real_repay_date) = year('${v_sdate}')
         group by t1.project_id
     ) t4 on t2.project_id = t4.project_id
         left join
     (
         select CITY_CODE_,              -- 区县编码
                ROLE_CODE_ as branch_off -- 办事处编码
         from dw_base.dwd_imp_area_branch
     ) t5 on t1.country_code = t5.CITY_CODE_
group by branch_off
-- 代偿率、考虑追偿的代偿在3%以上（含3%）的分支机构
having round(sum(t3.compt_amt) /
             (sum(case when year(t2.unguar_dt) = year('${v_sdate}') and t1.item_stt = '已解保' then guar_amt end) +
              sum(t3.compt_amt) * 100), 2) >= 3
;
commit;
