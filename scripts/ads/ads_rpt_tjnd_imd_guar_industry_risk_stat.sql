-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250423
-- 目标表   ：dw_base.ads_rpt_tjnd_imd_guar_industry_risk_stat    综合部-融资担保公司行业风险统计表
-- 源表     ：
--          新业务系统
--          dw_base.dwd_guar_info_all                           担保台账信息
--          dw_base.dwd_guar_info_stat                          担保台账星型表
--          dw_base.dwd_guar_info_onguar                        担保台账在保信息
--          dw_base.dwd_tjnd_report_biz_loan_bank               国农担上报--银行信息
--          dw_base.dwd_guar_compt_info                         代偿信息汇总表
--          dw_nd.ods_t_biz_proj_recovery_record                追偿记录表
--          dw_nd.ods_t_biz_proj_recovery_repay_detail_record   登记还款记录
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 重跑策略
delete
from dw_base.ads_rpt_tjnd_imd_guar_industry_risk_stat
where day_id = '${v_sdate}';
commit;

-- 插入数据
insert into dw_base.ads_rpt_tjnd_imd_guar_industry_risk_stat
(day_id, -- 数据日期
 fina_guar_liability_amt, -- 融资担保责任余额
 guar_year_compt_amt, -- 担保代偿额-当年发生额
 guar_compt_amt, -- 担保代偿额-余额
 fina_guar_year_compt_amt, -- 融资担保代偿额-当年发生额
 fina_guar_compt_amt, -- 融资担保代偿额-余额
 guar_ovd_amt, -- 尚未履行代偿责任余额
 fina_guar_ovd_amt, -- 融资担保尚未履行代偿责任余额
 guar_year_recovery_amt, -- 担保代偿回收额
 fina_guar_year_recovery_amt, -- 融资担保代偿回收额
 loan_guar_ovd_amt, -- 贷款担保中应代偿额
 indus_ovd_amt -- 农、林、牧、渔业-应代偿额
)
select '${v_sdate}'                                                            as day_id,
       sum(tjnd_risk * onguar_amt)                                             as fina_guar_liability_amt,
       sum(year_compt_amt)                                                     as guar_year_compt_amt,
       sum(compt_amt)                                                          as guar_compt_amt,
       sum(year_compt_amt)                                                     as fina_guar_year_compt_amt,
       sum(compt_amt)                                                          as fina_guar_compt_amt,
       sum(case when is_compensate = '0' and is_ovd = '1' then onguar_amt end) as guar_ovd_amt,
       sum(case when is_compensate = '0' and is_ovd = '1' then onguar_amt end) as fina_guar_ovd_amt,
       sum(year_recovery_amt)                                                  as guar_year_recovery_amt,
       sum(year_recovery_amt)                                                  as fina_guar_year_recovery_amt,
       sum(case when is_compensate = '0' and is_ovd = '1' then onguar_amt end) as loan_guar_ovd_amt,
       sum(case when is_compensate = '0' and is_ovd = '1' then onguar_amt end) as indus_ovd_amt
from (
         select t1.guar_id,
                t1.is_compensate,                                   -- 是否代偿
                t1.is_ovd,                                          -- 是否逾期
                t3.onguar_amt,                                      -- 在保余额(万元)
                coalesce(t9.RISK_RATIO, t4.tjnd_risk) as tjnd_risk, -- 农担分险比例
                t5.year_compt_amt,                                  -- 当年代偿拨付金额(本息) 万元
                t6.compt_amt,                                       -- 代偿拨付金额(本息) 万元
                t7.year_recovery_amt                                -- 当年追偿金额
         from (
                  select guar_id,
                         is_compensate, -- 是否代偿
                         is_ovd         -- 是否逾期
                  from dw_base.dwd_guar_info_all
                  where day_id = '${v_sdate}'
                    and data_source = '担保业务管理系统新'
              ) t1
                  left join
              (
                  select guar_id,
                         project_id
                  from dw_base.dwd_guar_info_stat
                  where day_id = '${v_sdate}'
              ) t2 on t1.guar_id = t2.guar_id
                  left join
              (
                  select guar_id,
                         onguar_amt -- 在保余额(万元)
                  from dw_base.dwd_guar_info_onguar
                  where day_id = '${v_sdate}'
              ) t3 on t1.guar_id = t3.guar_id
                  left join
              (
                  select biz_no,
                         tjnd_risk / 100 as tjnd_risk -- 农担分险比例
                  from dw_base.dwd_tjnd_report_biz_loan_bank
                  where day_id = '${v_sdate}'
              ) t4 on t1.guar_id = t4.biz_no
                  left join
              (
                  select guar_id,
                         compt_amt as year_compt_amt -- 当年代偿拨付金额(本息) 万元
                  from dw_base.dwd_guar_compt_info
                  where day_id = '${v_sdate}'
                    -- 取代偿拨付日期为本年
                    and year(compt_time) = year('${v_sdate}')
              ) t5 on t1.guar_id = t5.guar_id
                  left join
              (
                  select guar_id,
                         compt_amt -- 代偿拨付金额(本息) 万元
                  from dw_base.dwd_guar_compt_info
                  where day_id = '${v_sdate}'
              ) t6 on t1.guar_id = t6.guar_id
                  left join
              (
                  select t1.project_id,                                     -- 项目id
                         sum(t2.shou_comp_amt) / 10000 as year_recovery_amt -- 当年追偿金额
                  from dw_nd.ods_t_biz_proj_recovery_record t1
                           left join dw_nd.ods_t_biz_proj_recovery_repay_detail_record t2 on t1.reco_id = t2.record_id
                  where year(real_repay_date) = year('${v_sdate}')
                  group by t1.project_id
              ) t7 on t2.project_id = t7.project_id
                  left join dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation t8 on t2.project_id = t8.id
                  left join dw_nd.ods_tjnd_yw_base_cooperative_institution_agreement t9 -- 合作机构表（老逻辑底表）
                            on t8.related_agreement_id = t9.ID

         union all
         -- [旧系统逻辑]

         select t1.guarantee_code                                  as guar_id,        -- 业务编号
                if(t3.id_cfbiz_underwriting is not null, '1', '0') as is_compensate,  -- 是否代偿
                if(t4.id_cfbiz_underwriting is not null, '1', '0') as is_ovd,         -- 是否逾期
                0                                                  as onguar_amt,     -- 在保余额(万元)
                0                                                  as tjnd_risk,      -- 农担分险比例
                case
                    when year(date_format(t2.payment_date, '%Y-%m-%d')) = substring('${v_sdate}', 1, 4)
                        then t2.total_compensation
                    else 0 end                                        year_compt_amt, -- 当年代偿拨付金额(本息) 万元
                t2.total_compensation                              as compt_amt,      -- 代偿拨付金额(本息) 万元
                t5.year_recovery_amt                                                  -- 当年追偿金额
         from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation t1 -- 申请表
                  inner join dw_nd.ods_creditmid_v2_z_migrate_bh_compensatory t2 -- 代偿表
                             on t1.id = t2.id_cfbiz_underwriting
                  left join
              (
                  select ID_CFBIZ_UNDERWRITING -- 业务id
                  from dw_nd.ods_creditmid_v2_z_migrate_bh_compensatory
                  where status = 1
                    and over_tag = 'BJ'
                    and deleted_by is null
              ) t3
              on t1.id = t3.id_cfbiz_underwriting
                  left join
              (
                  select id_cfbiz_underwriting -- 业务id
                  from (select *, row_number() over (partition by id_cfbiz_underwriting order by created_time desc) rn
                        from dw_nd.ods_creditmid_v2_z_migrate_bh_overdue_plan
                        where status = '1') t1
                  where rn = 1
              ) t4
              on t1.id = t4.id_cfbiz_underwriting
                  left join
              (
                  select a.id_cfbiz_underwriting,
                         sum(case
                                 when year(date_format(b.entry_data, '%Y-%m-%d')) = substring('${v_sdate}', 1, 4)
                                     then b.cur_recovery
                                 else 0 end) as year_recovery_amt -- 当年追偿金额
                  from dw_nd.ods_creditmid_v2_z_migrate_bh_recovery_tracking a -- 追偿跟踪表
                           inner join dw_nd.ods_creditmid_v2_z_migrate_bh_recovery_tracking_detail b -- 追偿跟踪详情表
                                      on b.id_recovery_tracking = a.id
                  group by a.id_cfbiz_underwriting
              ) t5 -- 追偿跟踪表
              on t1.id = t5.id_cfbiz_underwriting
         where t1.gur_state != '50' -- [排除在保转进件]
           and t2.over_tag = 'BJ'
           and t2.status = 1
     ) t
;
commit;