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
--          dw_nd.ods_tjnd_yw_afg_refund_details        退费申请详情表
--          dw_nd.ods_tjnd_yw_afg_voucher_repayment     还款凭证信息
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 旧业务系统逻辑
select t1.id                                    as guar_id,
       cust_name,
       cert_num,
       weibao_cont_no,
       case
           when gnd_indus_class = '0' then '农产品初加工'
           when gnd_indus_class = '1' then '粮食种植'
           when gnd_indus_class = '2' then '重要、特色农产品种植'
           when gnd_indus_class = '3' then '其他畜牧业'
           when gnd_indus_class = '4' then '生猪养殖'
           when gnd_indus_class = '5' then '农产品流通'
           when gnd_indus_class = '6' then '渔业生产'
           when gnd_indus_class = '7' then '农资、农机、农技等农业社会化服务'
           when gnd_indus_class = '8' then '农业新业态'
           when gnd_indus_class = '9' then '农田建设'
           when gnd_indus_class = '10' then '其他农业项目'
           end                                  as gnd_indus_class,
       null                                     as guar_type,
       case
           when unguar_type = '[]' then '信用/免担保'
           when unguar_type = '["counterGuarantor"]' then '保证'
           when unguar_type = '["gage"]' then '抵押'
           when unguar_type = '["collateral"]' then '质押'
           when unguar_type is not null then '组合'
           end                                  as unguar_type,
       guar_amt / 10000                         as guar_amt,
       case
           when guar_status = 'GT' then '在保'
           when guar_status = 'ED' then '解保'
           end                                  as guar_status,
       date_format(loan_enter_date, '%Y-%m-%d') as loan_enter_date,
       loan_date,
       (guar_amt - repayment_amt) / 10000       as in_force_balance,
       guar_start_date,
       guar_end_date,
       guar_term,
       loan_bank,
       year_guar_rate,
       guar_fee,
       null,
       case
           when is_micro_company = '0' then '否'
           when is_micro_company = '1' then '是'
           end                                  as is_micro_company,
       date_format(received_date, '%Y-%m-%d') as received_date,
       refund_amt,
       refund_date
from (
         select id,
                CUSTOMER_NAME      as cust_name,
                ID_NUMBER          as cert_num,
                COUNTER_GUR_METHOD as unguar_type,
                GUR_STATE          as guar_status,
                ID_CUSTOMER
         from dw_nd.ods_tjnd_yw_afg_business_infomation
     ) t1
         left join
     (
         select ID_BUSINESS_INFORMATION,
                sum(RECEIPT_AMOUNT)  as guar_amt,
                min(LOAN_START_DATE) as loan_date,
                min(LOAN_START_DATE) as guar_start_date,
                max(LOAN_END_DATE)   as guar_end_date,
                max(CREATED_TIME)    as loan_enter_date
         from dw_nd.ods_tjnd_yw_afg_voucher_infomation
         where DELETE_FLAG = 1
         group by ID_BUSINESS_INFORMATION
     ) t2 on t1.id = t2.ID_BUSINESS_INFORMATION
         left join
     (
         select ID_BUSINESS_INFORMATION,
                WTBZHT_NO      as weibao_cont_no,
                APPROVED_TERM  as guar_term,
                FULL_BANK_NAME as loan_bank,
                GUARANTEE_TATE as year_guar_rate,
                SHARE_FEE      as guar_fee,
                RECEIVED_TIME  as received_date
         from dw_nd.ods_tjnd_yw_afg_business_approval
     ) t3 on t1.id = t3.ID_BUSINESS_INFORMATION
         left join
     (
         select ID,
                INDUSTRY_CATEGORY_COMPANY as gnd_indus_class,
                IS_MICRO_COMPANY          as is_micro_company
         from dw_nd.ods_tjnd_yw_base_customers_history
     ) t4 on t1.ID_CUSTOMER = t4.ID
         left join
     (
         select ID_BUSINESS_INFORMATION,
                sum(ACTUAL_REFUND_AMOUNT) as refund_amt,
                max(REFUND_DATE)          as refund_date
         from dw_nd.ods_tjnd_yw_afg_refund_details
         where DELETE_FLAG = 1
           and OVER_TAG = 'BJ'
         group by ID_BUSINESS_INFORMATION
     ) t5
     on t1.id = t5.ID_BUSINESS_INFORMATION
         left join
     (
         select ID_BUSINESS_INFORMATION,
                sum(REPAYMENT_PRINCIPAL) as repayment_amt
         from dw_nd.ods_tjnd_yw_afg_voucher_repayment
         where DELETE_FLAG = 1
         group by ID_BUSINESS_INFORMATION
     ) t6 on t1.ID = t6.ID_BUSINESS_INFORMATION;

