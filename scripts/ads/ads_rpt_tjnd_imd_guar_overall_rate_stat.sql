-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250421
-- 目标表   ：dw_base.ads_rpt_tjnd_imd_guar_overall_rate_stat    综合部-融资担保公司主要业务综合费率统计表
-- 源表     ：
--          新业务系统
--          dw_base.dwd_guar_info_all           担保台账信息
--          dw_base.dwd_guar_info_stat          担保台账星型表
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 重跑策略
delete
from dw_base.ads_rpt_tjnd_imd_guar_overall_rate_stat
where day_id = '${v_sdate}';
commit;

-- 1.插入数据
insert into dw_base.ads_rpt_tjnd_imd_guar_overall_rate_stat
(day_id, -- 数据日期
 fina_avg_overall_rate, -- 融资担保业务合计-平均综合费率
 loan_avg_overall_rate, -- 借款类担保业务-平均综合费率
 gover_avg_overall_rate, -- 政策性担保业务-平均综合费率
 avg_loan_rate -- 平均贷款利率（贷款担保业务）
)
select '${v_sdate}'                                            as day_id,
       sum(guar_amt) / sum(guar_amt * (guar_rate + loan_rate)) as fina_avg_overall_rate,
       sum(guar_amt) / sum(guar_amt * (guar_rate + loan_rate)) as loan_avg_overall_rate,
       sum(guar_amt) / sum(guar_amt * (guar_rate + loan_rate)) as gover_avg_overall_rate,
       sum(guar_amt) / sum(guar_amt * loan_rate)               as avg_loan_rate
from (
         select guar_id,
                guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                guar_rate, -- 担保利率
                loan_rate  -- 贷款利率
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id;
commit;
