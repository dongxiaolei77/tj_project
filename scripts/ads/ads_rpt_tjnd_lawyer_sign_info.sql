-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250326
-- 目标表   ：dw_base.ads_rpt_lawyer_sign_info 律师登记
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_afg_business_infomation       业务申请表
--          dw_nd.ods_tjnd_yw_bh_compensatory               代偿表
--          dw_nd.ods_tjnd_yw_bh_recovery_tracking          追偿跟踪表
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 旧业务系统逻辑
select t1.ID,
       cust_name,
       compt_date,
       filing_date
from (
         select ID,
                CUSTOMER_NAME as cust_name
         from dw_nd.ods_tjnd_yw_afg_business_infomation
     ) t1
         inner join
     (
         select ID_CFBIZ_UNDERWRITING,
                PAYMENT_DATE as compt_date
         from dw_nd.ods_tjnd_yw_bh_compensatory
         where status = 1
           and over_tag = 'BJ'
           and DELETED_BY is null
     ) t2 on t1.id = t2.ID_CFBIZ_UNDERWRITING
         left join
     (
         select t1.ID_CFBIZ_UNDERWRITING,
                min(DATE_OF_PROSECUTION) as filing_date
         from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
         group by t1.ID_CFBIZ_UNDERWRITING
     ) t5 on t1.id = t5.ID_CFBIZ_UNDERWRITING