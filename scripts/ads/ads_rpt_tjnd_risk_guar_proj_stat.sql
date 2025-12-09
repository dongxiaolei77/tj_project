-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250212
-- 目标表   ：dw_base.ads_rpt_risk_guar_proj_stat 省级农担公司1000万以上在保项目情况表
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_afg_business_infomation 业务申请表
--          dw_tmp.tmp_ads_rpt_guar_proj_init 天津原业务系统1000万以上在保项目初始化表
--          新业务系统
--
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- step0 重跑策略
delete
from dw_base.ads_rpt_tjnd_risk_guar_proj_stat
where day_id = '${v_sdate}';
commit;

-- step1 天津原业务系统数据 插入数据
# insert into dw_base.ads_rpt_tjnd_risk_guar_proj_stat
# (day_id, -- 数据日期
#  guar_id, -- 业务id
#  cust_name, -- 客户名称
#  proj_status, -- 项目状态
#  ind_name, -- 行业
#  main_biz, -- 主营业务
#  ln_purp, -- 贷款用途
#  loan_amt, -- 放款金额(万元)
#  gt_amt, -- 在保余额(万元)
#  issue_dt, -- 发放日
#  exp_dt, -- 到期日
#  gover_ratio, -- 政府分险比例
#  bank_ratio, -- 银行分险比例
#  other_ratio, -- 地方担保公司等其他方分险比例
#  un_guar_mode, -- 反担保措施
#  un_guar_abst, -- 反担保摘要
#  risk_level, -- 风险等级
#  first_guar_dt, -- 首次担保时间
#  first_guar_amt, -- 首次担保金额(万元)
#  renewal_cnt, -- 续保次数
#  eexit_dt, -- 预计退出时间
#  eexit_plan -- 退出计划
# )
# select '${v_sdate}'                   as day_id,
#        t1.id                          as guar_id,
#        t1.cust_name,
#        t1.proj_status,
#        t1.ind_name,
#        t1.main_biz,
#        t1.ln_purp,
#        t1.loan_amt / 10000            as loan_amt,
#        round(t2.GT_AMOUNT / 10000, 2) as gt_amt,
#        t1.issue_dt,
#        t1.exp_dt,
#        t1.gover_ratio,
#        t1.bank_ratio,
#        t1.other_ratio,
#        t1.un_guar_mode,
#        t1.un_guar_abst,
#        t1.risk_level,
#        t1.first_guar_dt,
#        t1.first_guar_amt / 10000      as first_guar_amt,
#        t1.renewal_cnt,
#        t1.eexit_dt,
#        t1.eexit_plan
# from dw_tmp.tmp_ads_rpt_guar_proj_init t1
#          join
#      (select id,
#              GT_AMOUNT * 10000 GT_AMOUNT
# --      from dw_nd.ods_tjnd_yw_afg_business_infomation
#       from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation
#       where CUSTOMER_NAME = '天津梦得集团有限公司'
#         and GUR_STATE = '50' -- GT - 50 在保
#         and GT_AMOUNT * 10000 > 10000000
#       union all
#       select id,
#              GT_AMOUNT * 10000 as GT_AMOUNT
# --      from dw_nd.ods_tjnd_yw_afg_business_infomation
#       from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation
#       where CUSTOMER_NAME = '天津市东信国际花卉有限公司'
#         and GUR_STATE = '50' -- GT - 50 在保
#         and GT_AMOUNT * 10000 > 10000000) t2 on t1.id = t2.ID;
# commit;

-- ---------------------------------------------------------------------
-- step2 新业务系统逻辑
insert into dw_base.ads_rpt_tjnd_risk_guar_proj_stat
(day_id, -- 数据日期
 guar_id, -- 业务id
 cust_name, -- 客户名称
 proj_status, -- 项目状态
 ind_name, -- 行业
 main_biz, -- 主营业务
 ln_purp, -- 贷款用途
 loan_amt, -- 放款金额(万元)
 gt_amt, -- 在保余额(万元)
 issue_dt, -- 发放日
 exp_dt, -- 到期日
 gover_ratio, -- 政府分险比例
 bank_ratio, -- 银行分险比例
 other_ratio, -- 地方担保公司等其他方分险比例
 un_guar_mode, -- 反担保措施
 un_guar_abst, -- 反担保摘要
 risk_level, -- 风险等级
 first_guar_dt, -- 首次担保时间
 first_guar_amt, -- 首次担保金额(万元)
 renewal_cnt, -- 续保次数
 eexit_dt, -- 预计退出时间
 eexit_plan -- 退出计划
)
select '${v_sdate}'                                    as day_id,
       t1.guar_id,
       t1.cust_name,
       case
           when guar_cnt = 1 then '新增'
           when guar_cnt > 1 then '续保'
           end                                         as proj_status,
       ind_name,
       main_biz,
       ln_purp,
       loan_amt                                        as loan_amt,
       onguar_amt                                      as gt_amt,
       issue_dt,
       exp_dt,
       0                                               as gover_ratio,
       coalesce(t10.BANK_ORG_RATE * 100, t8.bank_risk) as bank_ratio,
       0                                               as other_ratio,
       replace(
               replace(
                       replace(
                               replace(
                                       replace(un_guar_mode, '01', '信用'),
                                       '02', '抵押'),
                               '03', '质押'),
                       '04', '保证'),
               '05', '以物抵债') as un_guar_mode,
       null                                            as un_guar_abst,
       null                                            as risk_level,
       first_guar_dt,
       first_guar_amt                                  as first_guar_amt,
       guar_cnt - 1                                    as renewal_cnt,
       eexit_dt,
       concat('预计', year(eexit_dt), '年底结清')            as eexit_plan
from (
         select guar_id       as guar_id,   -- 台账编号
                cust_name     as cust_name, -- 客户名称
                guar_class    as ind_name,  -- 国担分类
                loan_use      as ln_purp,   -- 借款用途
                guar_amt      as loan_amt,  -- 放款金额
                loan_begin_dt as issue_dt,  -- 贷款开始时间
                loan_end_dt   as exp_dt     -- 贷款结束时间
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
     ) t1
         inner join -- 取在保余额大于1000万的业务
    (
        select guar_id,   -- 台账编号
               onguar_amt -- 在保余额(万元)
        from dw_base.dwd_guar_info_onguar
        where day_id = '${v_sdate}'
          and onguar_amt > 1000
    ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select cust_name,                                           -- 客户名称 sum(onguar_amt) as gt_amt, -- 现用放款金额 需修改为在保余额
                count(t1.guar_id)                  as guar_cnt,      -- 担保次数
                case when rn = 1 then grant_dt end as first_guar_dt, -- 首次担保时间
                case when rn = 1 then guar_amt end as first_guar_amt -- 首次担保金额(万元)
         from (
                  select *,
                         row_number() over (partition by cust_name order by grant_dt) rn -- 排序取放款时间最早的一条
                  from dw_base.dwd_guar_info_all
                  where day_id = '${v_sdate}'
              ) t1
         group by cust_name
     ) t3
     on t1.cust_name = t3.cust_name
         left join
     (
         select code,                          -- 项目id
                main_business_one as main_biz, -- 经营主业
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main) t1
         where rn = 1
     ) t4 on t1.guar_id = t4.code
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t5 on t1.guar_id = t5.guar_id
         left join
     -- 批复表 反担保措施
         (
             select project_id, reply_counter_guar_meas as un_guar_mode
             from (
                      select *, row_number() over (partition by id order by db_update_time desc) rn
                      from dw_nd.ods_t_biz_proj_appr
                  ) t1
             where rn = 1
         ) t6 on t5.project_id = t6.project_id
         left join
     -- 签约表 借款合同到期日期
         (
             select project_id, jk_ctrct_end_date as eexit_dt
             from (
                      select *, row_number() over (partition by id order by db_update_time desc) rn
                      from dw_nd.ods_t_biz_proj_sign
                  ) t1
             where rn = 1
         ) t7 on t5.project_id = t7.project_id
         left join

     -- loan_bank 银行分险比例
         (
             select biz_no, bank_risk
             from dw_base.dwd_tjnd_report_biz_loan_bank
             where day_id = '${v_sdate}'
         ) t8 on t1.guar_id = t8.biz_no
         -- 协议表 老系统银行分险比例
         left join dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation t9
                   on t1.guar_id = t9.GUARANTEE_CODE
         left join dw_nd.ods_tjnd_yw_base_cooperative_institution_agreement t10 -- 合作机构表（老逻辑底表）
                   on t9.related_agreement_id = t10.ID
;
commit;