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
-- insert into dw_base.ads_rpt_tjnd_imd_guar_risk_sharing_stat
-- (day_id, -- 数据日期
--  stat_type, -- 统计类型
--  onguar_amt, -- 在保余额(万元)
--  year_compt_amt -- 当年代偿金额(万元)
-- )
-- select '${v_sdate}'    as day_id,
--        '合计'            as stat_type,
--        sum(onguar_amt) as onguar_amt,
--        sum(compt_amt)  as year_compt_amt
-- from (
--          select t1.guar_id,
--                 t2.onguar_amt, -- 在保余额(万元)
--                 t3.compt_amt   -- 代偿拨付金额(本息) 万元
--          from (
--                   select guar_id
--                   from dw_base.dwd_guar_info_all
--                   where day_id = '${v_sdate}'
--                     and data_source = '担保业务管理系统新'
--               ) t1
--                   left join
--               (
--                   select guar_id,
--                          onguar_amt -- 在保余额(万元)
--                   from dw_base.dwd_guar_info_onguar
--                   where day_id = '${v_sdate}'
--               ) t2 on t1.guar_id = t2.guar_id
--                   left join
--               (
--                   select guar_id,
--                          compt_amt -- 代偿拨付金额(本息) 万元
--                   from dw_base.dwd_guar_compt_info
--                   where day_id = '${v_sdate}'
--                     -- 取代偿拨付日期为本年
--                     and year(compt_time) = year('${v_sdate}')
--               ) t3 on t1.guar_id = t3.guar_id
--          union all
--          select t1.guarantee_code     as guar_id,    -- 业务编号
--                 0                     as onguar_amt, -- 在保余额(万元)
--                 t2.total_compensation as compt_amt   -- 代偿拨付金额(本息) 万元
--          from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation t1 -- 申请表
--                   inner join dw_nd.ods_creditmid_v2_z_migrate_bh_compensatory t2 -- 代偿表
--                              on t1.id = t2.id_cfbiz_underwriting
--          where t1.gur_state != '50' -- [排除在保转进件]
--            and year(date_format(t2.payment_date, '%Y-%m-%d')) = substring('${v_sdate}', 1, 4)
--            and t2.over_tag = 'BJ'
--            and t2.status = 1
--      ) t
-- ;
-- commit;

-- 1.插入机构自身数据
insert into dw_base.ads_rpt_tjnd_imd_guar_risk_sharing_stat
(day_id, -- 数据日期
 stat_type, -- 统计类型
 onguar_amt, -- 在保余额(万元)
 year_compt_amt -- 当年代偿金额(万元)
)
select '${v_sdate}'    as day_id,
       '机构自身'          as stat_type,
       sum(onguar_amt) as onguar_amt,
       sum(compt_amt)  as year_compt_amt
from (
         select t1.guar_id,
                if(t1.guar_id like 'TJ%', onguar_amt * (1 - t6.bank_org_rate),
                   onguar_amt * tjnd_risk / 100) as onguar_amt, -- 在保余额(万元)
                t3.compt_amt,                                   -- 代偿拨付金额(本息) 万元
                t4.tjnd_risk                                    -- 农担分险比例
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all
                  where day_id = '${v_sdate}'
                    and data_source = '担保业务管理系统新' and guar_id != 'TJRD-2021-5S93-979U'
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
              ) t4 on t1.guar_id = t4.biz_no
                  left join dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation t5
                            on t1.guar_id = t5.GUARANTEE_CODE
                  left join dw_nd.ods_tjnd_yw_base_cooperative_institution_agreement t6-- 合作机构表（老逻辑底表）
                            on t5.related_agreement_id = t6.ID
         union all
         select t1.guarantee_code     as guar_id,    -- 业务编号
                0                     as onguar_amt, -- 在保余额(万元)
                t2.total_compensation as compt_amt,  -- 代偿拨付金额(本息) 万元
                0                     as tjnd_risk   -- 农担分险比例
         from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation t1 -- 申请表
                  inner join dw_nd.ods_creditmid_v2_z_migrate_bh_compensatory t2 -- 代偿表
                             on t1.id = t2.id_cfbiz_underwriting
         where t1.gur_state != '50' -- [排除在保转进件]
           and year(date_format(t2.payment_date, '%Y-%m-%d')) = substring('${v_sdate}', 1, 4)
           and t2.over_tag = 'BJ'
           and t2.status = 1
     ) t
;
commit;

-- 2.插入银行数据
insert into dw_base.ads_rpt_tjnd_imd_guar_risk_sharing_stat
(day_id, -- 数据日期
 stat_type, -- 统计类型
 onguar_amt, -- 在保余额(万元)
 year_compt_amt -- 当年代偿金额(万元)
)
select '${v_sdate}'                                                                                as day_id,
       '银行'                                                                                      as stat_type,
       sum(if(t1.guar_id like 'TJ%', onguar_amt * t6.bank_org_rate, onguar_amt * bank_risk / 100)) as onguar_amt,
       (select sum(COMP_OVD_AMT) / 10000 as COMP_OVD_AMT  -- 代偿时逾期金额(万元)  [本年代偿业务的逾期总额]
	    from dw_base.dwd_tjnd_report_proj_comp_info 
		where day_id = '${v_sdate}' and year(comp_pmt_dt) = left('${v_sdate}',4))
	    - 
	   (select year_compt_amt from dw_base.ads_rpt_tjnd_imd_guar_risk_sharing_stat where day_id = '${v_sdate}' and stat_type = '机构自身')  as year_compt_amt  -- [银行取本年代偿业务的逾期总额-机构自身代偿总额,]    
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
     ) t4 on t1.guar_id = t4.biz_no
         left join dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation t5 on t1.guar_id = t5.GUARANTEE_CODE
         left join dw_nd.ods_tjnd_yw_base_cooperative_institution_agreement t6-- 合作机构表（老逻辑底表）
                   on t5.related_agreement_id = t6.ID
;
commit;

-- 3. 插入合计数据
insert into dw_base.ads_rpt_tjnd_imd_guar_risk_sharing_stat
(day_id, -- 数据日期
 stat_type, -- 统计类型
 onguar_amt, -- 在保余额(万元)
 year_compt_amt -- 当年代偿金额(万元)
)
select '${v_sdate}'    as day_id,
       '合计'            as stat_type,
       sum(onguar_amt) as onguar_amt,
       sum(year_compt_amt)  as year_compt_amt
from dw_base.ads_rpt_tjnd_imd_guar_risk_sharing_stat where day_id = '${v_sdate}'
;
commit;