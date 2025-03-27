-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250327
-- 目标表   ：dw_base.ads_rpt_record_stat_info 业务情况统计
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_afg_business_infomation   业务申请表
--          dw_nd.ods_tjnd_yw_afg_business_approval     审批
--          dw_nd.ods_tjnd_yw_afg_voucher_infomation    放款凭证信息
--          dw_nd.ods_tjnd_yw_base_customers_history    BO,客户信息历史表,NEW
--
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 旧业务系统逻辑
select *
from dw_nd.ods_tjnd_yw_afg_business_infomation t1
         left join (select ID_BUSINESS_INFORMATION
                    from dw_nd.ods_tjnd_yw_afg_voucher_infomation
                    where DELETE_FLAG = 1
                    group by ID_BUSINESS_INFORMATION) t2
                   on t1.id = t2.ID_BUSINESS_INFORMATION
         left join
     dw_nd.ods_tjnd_yw_afg_business_approval t3 on t1.id = t3.ID_BUSINESS_INFORMATION
         left join
     dw_nd.ods_tjnd_yw_base_customers_history t4 on t1.ID_CUSTOMER = t4.ID
         left join
    dw_nd.ods_tjnd_yw_afg_refund_details
