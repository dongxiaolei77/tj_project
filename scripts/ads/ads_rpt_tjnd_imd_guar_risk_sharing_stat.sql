-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250421
-- 目标表   ：dw_base.ads_rpt_tjnd_imd_guar_risk_sharing_stat    综合部-融资担保公司主要业务风险分担统计表
-- 源表     ：
--          新业务系统
--          dw_base.dwd_guar_info_all             担保台账信息
--          dw_base.dwd_guar_info_onguar          担保台账在保信息
--          dw_base.dwd_guar_compt_info           代偿信息汇总表
--          dw_base.dwd_tjnd_report_biz_loan_bank 国农担上报--银行信息
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 重跑策略
delete
from dw_base.ads_rpt_tjnd_imd_guar_risk_sharing_stat
where day_id = '${v_sdate}';
commit;

-- 1. 插入合计数据
insert into dw_base.ads_rpt_tjnd_imd_guar_risk_sharing_stat
(day_id, -- 数据日期
 stat_type, -- 统计类型
 onguar_amt, -- 在保余额(万元)
 year_compt_amt -- 当年代偿金额(万元)
)
select '${v_sdate}'    as day_id,
       '合计'            as stat_type,
       sum(onguar_amt) as onguar_amt,
       sum(compt_amt)  as year_compt_amt
from (
         select guar_id
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
     ) t1
         left join
     (
         select guar_id,
                onguar_amt -- 在保余额(万元)
         from dw_base.dwd_guar_info_onguar
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select guar_id,
                compt_amt -- 代偿拨付金额(本息) 万元
         from dw_base.dwd_guar_compt_info
         where day_id = '${v_sdate}'
           -- 取代偿拨付日期为本年
           and year(compt_time) = year('${v_sdate}')
     ) t3 on t1.guar_id = t3.guar_id;
commit;

-- 2.插入机构自身数据
insert into dw_base.ads_rpt_tjnd_imd_guar_risk_sharing_stat
(day_id, -- 数据日期
 stat_type, -- 统计类型
 onguar_amt, -- 在保余额(万元)
 year_compt_amt -- 当年代偿金额(万元)
)
select '${v_sdate}'                      as day_id,
       '机构自身'                            as stat_type,
       sum(onguar_amt) * tjnd_risk / 100 as onguar_amt,
       sum(compt_amt)                    as year_compt_amt
from (
         select guar_id
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
     ) t1
         left join
     (
         select guar_id,
                onguar_amt -- 在保余额(万元)
         from dw_base.dwd_guar_info_onguar
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select guar_id,
                compt_amt -- 代偿拨付金额(本息) 万元
         from dw_base.dwd_guar_compt_info
         where day_id = '${v_sdate}'
           -- 取代偿拨付日期为本年
           and year(compt_time) = year('${v_sdate}')
     ) t3 on t1.guar_id = t3.guar_id
         left join
     (
         select biz_no,   -- 业务id
                tjnd_risk -- 农担分险比例
         from dw_base.dwd_tjnd_report_biz_loan_bank
         where day_id = '${v_sdate}'
     ) t4 on t1.guar_id = t4.biz_no;
commit;

-- 3.插入银行数据
insert into dw_base.ads_rpt_tjnd_imd_guar_risk_sharing_stat
(day_id, -- 数据日期
 stat_type, -- 统计类型
 onguar_amt, -- 在保余额(万元)
 year_compt_amt -- 当年代偿金额(万元)
)
select '${v_sdate}'                      as day_id,
       '银行'                              as stat_type,
       sum(onguar_amt) * bank_risk / 100 as onguar_amt,
       null                              as year_compt_amt
from (
         select guar_id
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
     ) t1
         left join
     (
         select guar_id,
                onguar_amt -- 在保余额(万元)
         from dw_base.dwd_guar_info_onguar
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select guar_id,
                compt_amt -- 代偿拨付金额(本息) 万元
         from dw_base.dwd_guar_compt_info
         where day_id = '${v_sdate}'
           -- 取代偿拨付日期为本年
           and year(compt_time) = year('${v_sdate}')
     ) t3 on t1.guar_id = t3.guar_id
         left join
     (
         select biz_no,   -- 业务id
                bank_risk -- 银行分险比例
         from dw_base.dwd_tjnd_report_biz_loan_bank
         where day_id = '${v_sdate}'
     ) t4 on t1.guar_id = t4.biz_no;
commit;