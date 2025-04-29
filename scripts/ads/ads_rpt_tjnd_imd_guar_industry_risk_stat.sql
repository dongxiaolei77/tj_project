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
       sum(year_recovery_amt)                                                  as guar_year_compt_amt,
       sum(compt_amt)                                                          as guar_compt_amt,
       sum(year_recovery_amt)                                                  as fina_guar_year_compt_amt,
       sum(compt_amt)                                                          as fina_guar_compt_amt,
       sum(case when is_compensate = '0' and is_ovd = '1' then onguar_amt end) as guar_ovd_amt,
       sum(case when is_compensate = '0' and is_ovd = '1' then onguar_amt end) as fina_guar_ovd_amt,
       sum(year_recovery_amt)                                                  as guar_year_recovery_amt,
       sum(year_recovery_amt)                                                  as fina_guar_year_recovery_amt,
       sum(case when is_compensate = '0' and is_ovd = '1' then onguar_amt end) as loan_guar_ovd_amt,
       sum(case when is_compensate = '0' and is_ovd = '1' then onguar_amt end) as indus_ovd_amt
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
;
commit;