-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250326
-- 目标表   ：dw_base.ads_rpt_compt_info 代偿及追偿基本情况统计表
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_afg_business_infomation       业务申请表
--          dw_nd.ods_tjnd_yw_bh_compensatory               代偿表
--          dw_nd.ods_tjnd_yw_bh_recovery_tracking          追偿跟踪表
--          dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail   追偿跟踪详情表
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 旧业务系统逻辑
select t1.id                as guar_id,
       cust_name,
       cert_num,
       compt_amt,
       compt_date,
       nd_proj_mgr,
       case
           when branch_off = 'YW_NHDLBSC' then '宁河东丽办事处'
           when branch_off = 'YW_JNBHXQBSC' then '津南滨海新区办事处'
           when branch_off = 'YW_WQBCBSC' then '武清北辰办事处'
           when branch_off = 'YW_XQJHBSC' then '西青静海办事处'
           when branch_off = 'YW_JZBSC' then '蓟州办事处'
           when branch_off = 'YW_BDBSC' then '宝坻办事处'
           end              as branch_off,
       null,
       null,
       null,
       null,
       null,
       null,
       null,
       null,
       null,
       lawyer_fee,
       null,
       null,
       null,
       null,
       null,
       null,
       null,
       null,
       null,
       recovery_amt / 10000 as recovery_amt,
       case
           when compt_remark is not null then compt_remark
           when recovery_remark is not null then recovery_remark
           end              as remark
from (
         select ID,
                CUSTOMER_NAME         as cust_name,
                ID_NUMBER             as cert_num,
                BUSINESS_SP_USER_NAME as nd_proj_mgr,
                enter_code            as branch_off
         from dw_nd.ods_tjnd_yw_afg_business_infomation
     ) t1
         inner join
     (
         select ID_CFBIZ_UNDERWRITING,
                TOTAL_COMPENSATION as compt_amt,
                PAYMENT_DATE       as compt_date,
                REMARK             as compt_remark
         from dw_nd.ods_tjnd_yw_bh_compensatory
         where status = 1
           and over_tag = 'BJ'
           and DELETED_BY is null
     ) t2 on t1.id = t2.ID_CFBIZ_UNDERWRITING
         left join
     (
         select t1.ID_CFBIZ_UNDERWRITING,
                sum(CUR_RECOVERY)                           as recovery_amt,
                sum(LAWYER_FEE_PAID)                        as lawyer_fee,
                group_concat(distinct REMARK separator '；') as recovery_remark
         from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
                  left join dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail t2
                            on t1.id = t2.ID_RECOVERY_TRACKING
         group by t1.ID_CFBIZ_UNDERWRITING
     ) t5 on t1.id = t5.ID_CFBIZ_UNDERWRITING;
commit;