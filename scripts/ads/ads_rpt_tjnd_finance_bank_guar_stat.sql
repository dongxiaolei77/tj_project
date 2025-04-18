-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250326
-- 目标表   ：dw_base.ads_rpt_tjnd_finance_bank_guar_stat 财务部-按银行担保额度统计
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_afg_business_infomation                   业务申请表
--          dw_nd.ods_tjnd_yw_afg_voucher_infomation                    放款凭证信息
--          dw_nd.ods_tjnd_yw_base_cooperative_institution_agreement    BO,机构合作协议,NEW
--          dw_nd.ods_tjnd_yw_base_enterprise                           部门表
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 重跑逻辑
truncate table dw_base.ads_rpt_tjnd_finance_bank_guar_stat;
commit;
-- 插入数据
insert into dw_base.ads_rpt_tjnd_finance_bank_guar_stat
(day_id, -- 数据日期
 bank_name, -- 银行
 coop_amt, -- 授信额度
 total_guar_cnt, -- 累计担保笔数
 total_guar_amt, -- 累计担保金额(万元)
 gt_cnt, -- 在保笔数
 gt_amt, -- 业务在保余额(万元)
 gt_amt_proportion -- 在保额占比
)
select '${v_sdate}'                  as day_id,
       t1.bank_name,
       coop_amt,
       total_guar_cnt,
       total_guar_amt,
       gt_cnt,
       gt_amt,
       round(gt_amt / all_gt_amt, 4) as gt_amt_proportion
from (
         select bank_name,
                sum(total_guar_cnt) as total_guar_cnt,
                sum(total_guar_amt) as total_guar_amt,
                sum(gt_cnt)         as gt_cnt,
                sum(gt_amt)         as gt_amt
         from (
                  -- 旧系统取数逻辑
                  select bank_name,
                         sum(if(gur_state in ('GT', 'ED'), 1, 0))        as total_guar_cnt,
                         sum(if(gur_state in ('GT', 'ED'), guar_amt, 0)) as total_guar_amt,
                         sum(if(GUR_STATE = 'GT', 1, 0))                 as gt_cnt,
                         sum(if(GUR_STATE = 'GT', GT_AMOUNT, 0))         as gt_amt
                  from (
                           select id,                            -- 业务id
                                  COOPERATIVE_BANK_FIRST,        -- 银行编码
                                  GUR_STATE,                     -- 在保状态
                                  GT_AMOUNT / 10000 as gt_amount -- 在保余额
                           from dw_nd.ods_tjnd_yw_afg_business_infomation
                           where DELETE_FLAG = 1
                             and COOPERATIVE_BANK_FIRST is not null
                       ) t1
                           left join
                       (
                           select ID_BUSINESS_INFORMATION,                -- 业务id
                                  sum(RECEIPT_AMOUNT) / 10000 as guar_amt -- 放款金额
                           from dw_nd.ods_tjnd_yw_afg_voucher_infomation
                           where DELETE_FLAG = 1
                           group by ID_BUSINESS_INFORMATION
                       ) t2 on t1.id = t2.ID_BUSINESS_INFORMATION
                           left join
                       (
                           select fieldcode,                 -- 银行编码
                                  enterfullname as bank_name -- 银行名称
                           from dw_nd.ods_tjnd_yw_base_enterprise
                           where parentid = 200
                       ) t3 on t1.COOPERATIVE_BANK_FIRST = t3.fieldcode
                  group by bank_name
                           -- 新系统取数逻辑
                  union all
                  select t2.gnd_dept_name                                                           as bank_name,
                         count(case when item_stt in ('已放款', '已解保', '已代偿') then t1.guar_id end)     as total_guar_cnt,
                         sum(case when item_stt in ('已放款', '已解保', '已代偿') then guar_amt end) / 10000 as total_guar_amt,
                         count(case when item_stt = '已放款' then t1.guar_id end)                      as gt_cnt,
                         onguar_amt / 10000                                                         as gt_amt
                  from (select guar_id,   -- 项目编号
                               loan_bank, -- 银行名称
                               item_stt,  -- 项目状态
                               guar_amt,  -- 放款金额
                               loan_amt   -- 合同金额
                        from dw_base.dwd_guar_info_all
                        where day_id = '${v_sdate}'
                          and data_source = '担保业务管理系统新') t1
                           left join dw_base.dwd_tjnd_report_biz_loan_bank t2
                                     on t1.guar_id = t2.biz_no
                           left join
                       (
                           select guar_id,
                                  onguar_amt
                           from dw_base.dwd_guar_info_onguar
                           where day_id = '${v_sdate}'
                       ) t3 on t1.guar_id = t3.guar_id
                  group by t2.gnd_dept_name
              ) t1
         group by bank_name
     ) t1
         left join
     (
         select enterfullname as bank_name, -- 银行名称
                enterid                     -- 单位id
         from dw_nd.ods_tjnd_yw_base_enterprise
         where parentid = 200
     ) t2 on t1.bank_name = t2.bank_name
         left join
     -- 银行授信额度
         (
             select BANK_ORG_ID,                   -- 单位id
                    COOPERATION_AMOUNT as coop_amt -- 合作额度(万元)
             from dw_nd.ods_tjnd_yw_base_cooperative_institution_agreement
             where IS_ENABLED = 1
               and ORG_AGREEMENT_TYPE = 0
         ) t3 on t2.enterid = t3.BANK_ORG_ID
         left join
     -- 获取在保总额
         (
             select sum(all_gt_amt) / 10000 as all_gt_amt
             from (
                      select sum(if(GUR_STATE = 'GT', GT_AMOUNT, 0)) as all_gt_amt
                      from (
                               select id,
                                      COOPERATIVE_BANK_FIRST,
                                      GUR_STATE,
                                      GT_AMOUNT / 10000 as gt_amount
                               from dw_nd.ods_tjnd_yw_afg_business_infomation
                               where DELETE_FLAG = 1
                                 and COOPERATIVE_BANK_FIRST is not null
                           ) t1
                               left join
                           (
                               select fieldcode,
                                      enterfullname as bank_name
                               from dw_nd.ods_tjnd_yw_base_enterprise
                               where parentid = 200
                           ) t2 on t1.COOPERATIVE_BANK_FIRST = t2.fieldcode
                      union all
                      select onguar_amt as all_gt_amt
                      from (
                               select *
                               from dw_base.dwd_guar_info_all
                               where day_id = '${v_sdate}'
                                 and data_source = '担保业务管理系统新'
                           ) t1
                               left join
                           (
                               select guar_id,
                                      onguar_amt
                               from dw_base.dwd_guar_info_onguar
                               where day_id = '${v_sdate}'
                           ) t2 on t1.guar_id = t2.guar_id
                  ) t1
         ) t4 on 1 = 1
order by gt_amt
    desc;
commit;