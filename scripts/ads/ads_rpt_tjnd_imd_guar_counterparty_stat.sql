-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250421
-- 目标表   ：dw_base.ads_rpt_tjnd_imd_guar_counterparty_stat    综合部-融资担保公司主要业务分交易对手统计表
-- 源表     ：
--          新业务系统
--          dw_base.dwd_guar_info_all       担保台账信息
--          dw_base.dwd_guar_info_onguar    担保台账在保信息
--
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 重跑策略
delete
from dw_base.ads_rpt_tjnd_imd_guar_counterparty_stat
where day_id = '${v_sdate}';
commit;

-- -----------------------------------
-- 新系统逻辑
-- 1.插入住户和非金融企业数据
insert into dw_base.ads_rpt_tjnd_imd_guar_counterparty_stat
(day_id, -- 数据日期
 stat_type, -- 统计类型
 fina_guar_business, --  融资担保业务
 loan_guar, -- 借款类担保业务-贷款担保
 gover_guar_business -- 政策性担保业务
)
select '${v_sdate}'                                    as day_id,
       case
           when cust_type = '自然人' then '住户'
           when cust_type = '法人或其他组织' then '非金融企业' end as stat_type,
       sum(onguar_amt)                                 as fina_guar_business,
       sum(onguar_amt)                                 as loan_guar,
       sum(onguar_amt)                                 as gover_guar_business
from (
         select guar_id,
                cust_type
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
group by cust_type;
commit;

-- 2.插入合计
insert into dw_base.ads_rpt_tjnd_imd_guar_counterparty_stat
(day_id, -- 数据日期
 stat_type, -- 统计类型
 fina_guar_business, --  融资担保业务
 loan_guar, -- 借款类担保业务-贷款担保
 gover_guar_business -- 政策性担保业务
)
select '${v_sdate}'    as day_id,
       '合计'            as stat_type,
       sum(onguar_amt) as fina_guar_business,
       sum(onguar_amt) as loan_guar,
       sum(onguar_amt) as gover_guar_business
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
     ) t2 on t1.guar_id = t2.guar_id;
commit;