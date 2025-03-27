-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250325
-- 目标表   ：dw_base.ads_rpt_compt_year_detail 代偿及追偿还款情况
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_afg_business_infomation       业务申请表
--          dw_nd.ods_tjnd_yw_bh_compensatory               代偿表
--          dw_nd.ods_tjnd_yw_bh_recovery_tracking          追偿跟踪表
--          dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail   追偿跟踪详情表
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
select t1.id,
       cust_name,
       compt_date,
       compt_amt,
       recovery_amt,
       case
           when (compt_amt - recovery_amt) / 10000 < 0 then 0
           else (compt_amt - recovery_amt) / 10000
           end    as un_recovery_amt,
       lawyer_fee as recovery_fee,
       year_recovery_amt,
       last_recovery_date
from (
         select id,
                CUSTOMER_NAME as cust_name
         from dw_nd.ods_tjnd_yw_afg_business_infomation
     ) t1
         inner join
     (
         select ID_CFBIZ_UNDERWRITING,
                TOTAL_COMPENSATION as compt_amt,
                PAYMENT_DATE       as compt_date
         from dw_nd.ods_tjnd_yw_bh_compensatory
         where status = 1
           and over_tag = 'BJ'
           and DELETED_BY is null
     ) t2
     on t1.id = t2.ID_CFBIZ_UNDERWRITING
         left join
     (
         select t1.ID_CFBIZ_UNDERWRITING,
                sum(CUR_RECOVERY)    as recovery_amt,
                sum(LAWYER_FEE_PAID) as lawyer_fee
         from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
                  left join dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail t2
                            on t1.id = t2.ID_RECOVERY_TRACKING
         group by t1.ID_CFBIZ_UNDERWRITING
     ) t3 on t1.id = t3.ID_CFBIZ_UNDERWRITING
         left join
     (
         select t1.ID_CFBIZ_UNDERWRITING,
                sum(CUR_RECOVERY) as year_recovery_amt,
                max(ENTRY_DATA)   as last_recovery_date
         from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
                  left join dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail t2
                            on t1.id = t2.ID_RECOVERY_TRACKING
         where year(t2.ENTRY_DATA) = year(now())
         group by t1.ID_CFBIZ_UNDERWRITING
     ) t4 on t1.ID = t4.ID_CFBIZ_UNDERWRITING