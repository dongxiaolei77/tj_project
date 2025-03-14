-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250212
-- 目标表   ：dw_base.ads_rpt_guar_proj_stat 省级农担公司1000万以上在保项目情况表
-- 源表     ：dw_nd.ods_tjnd_yw_afg_business_infomation 业务申请表
--          dw_tmp.tmp_ads_rpt_guar_proj_init 天津原业务系统1000万以上在保项目初始化表
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- step0 重跑策略
delete
from dw_base.ads_rpt_guar_proj_stat
where day_id = '${v_sdate}';
commit;

-- step1 天津原业务系统数据 插入数据
insert into dw_base.ads_rpt_guar_proj_stat
select '${v_sdate}'                   as day_id,
       t1.id,
       t1.cust_name,
       t1.proj_status,
       t1.ind_name,
       t1.main_biz,
       t1.ln_purp,
       t1.loan_amt,
       round(t2.GT_AMOUNT / 10000, 2) as gt_amt,
       t1.issue_dt,
       t1.exp_dt,
       t1.gover_ratio,
       t1.bank_ratio,
       t1.other_ratio,
       t1.un_guar_mode,
       t1.un_guar_abst,
       t1.risk_level,
       t1.first_guar_dt,
       t1.first_guar_amt,
       t1.renewal_cnt,
       t1.eexit_dt,
       t1.eexit_plan
from dw_tmp.tmp_ads_rpt_guar_proj_init t1
         join
     (select id, GT_AMOUNT
      from dw_nd.ods_tjnd_yw_afg_business_infomation
      where CUSTOMER_NAME = '天津梦得集团有限公司'
        and GUR_STATE = 'GT'
        and GT_AMOUNT > 10000000
      union all
      select id, GT_AMOUNT
      from dw_nd.ods_tjnd_yw_afg_business_infomation
      where CUSTOMER_NAME = '天津市东信国际花卉有限公司'
        and GUR_STATE = 'GT'
        and GT_AMOUNT > 10000000) t2 on t1.id = t2.ID;
commit;

-- step2 删除非近30天和非每个月月底数据
delete
from dw_base.ads_rpt_guar_proj_stat
where day_id <> date_format(last_day(day_id), '%Y%m%d')
  and day_id <= date_format(date_sub('${v_sdate}',interval 30 day),'%Y%m%d');
commit;