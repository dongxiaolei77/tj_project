-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250325
-- 目标表   ：dw_base.ads_rpt_compt_year_detail 代偿追偿年度台账详情
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_afg_business_infomation       业务申请表
--          dw_nd.ods_tjnd_yw_bh_compensatory               代偿表
--          dw_nd.ods_tjnd_yw_afg_business_approval         审批
--          dw_nd.ods_tjnd_yw_base_customers_history        BO,客户信息历史表,NEW
--          dw_nd.ods_tjnd_yw_bh_recovery_tracking          追偿跟踪表
--          dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail   追偿跟踪详情表
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 旧业务系统逻辑
select t1.id                                                                                               as guar_id,
       cust_name,
       case
           when cust_type = 'enterprise' then '企业'
           when cust_type = 'person' then '个人'
           end                                                                                             as cust_type,
       full_bank,
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
           end                                                                                             as gnd_indus_class,
       main_biz,
       loan_amt / 10000                                                                                    as loan_amt,
       null                                                                                                as ovd_amt,
       compt_amt / 10000                                                                                   as compt_amt,
       compt_date,
       recovery_amt / 10000                                                                                as recovery_amt,
       case
           when (compt_amt - recovery_amt) / 10000 < 0 then 0
           else (compt_amt - recovery_amt) / 10000 end                                                     as compt_balance,
       country,
       city,
       area,
       case
           when compt_remark is not null then compt_remark
           when recovery_remark is not null then recovery_remark
           end                                                                                             as remark
from (
         select ID,
                CUSTOMER_NAME                            as cust_name,
                CUSTOMER_NATURE                          as cust_type,
                FULL_BANK_NAME                           as full_bank,
                JSON_UNQUOTE(JSON_EXTRACT(area, '$[0]')) as country,
                JSON_UNQUOTE(JSON_EXTRACT(area, '$[0]')) as city,
                JSON_UNQUOTE(JSON_EXTRACT(area, '$[1]')) as area,
                ID_CUSTOMER
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
         select ID_BUSINESS_INFORMATION,
                LOAN_CONTRACT_AMOUNT as loan_amt
         from dw_nd.ods_tjnd_yw_afg_business_approval
     ) t3 on t1.id = t3.ID_BUSINESS_INFORMATION
         left join
     (
         select ID,
                INDUSTRY_CATEGORY_COMPANY as gnd_indus_class,
                BUSINESS_ITEM             as main_biz
         from dw_nd.ods_tjnd_yw_base_customers_history
     ) t4 on t1.ID_CUSTOMER = t4.id
         left join
     (
         select t1.ID_CFBIZ_UNDERWRITING,
                sum(CUR_RECOVERY)                           as recovery_amt,
                group_concat(distinct REMARK separator '；') as recovery_remark
         from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
                  left join dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail t2
                            on t1.id = t2.ID_RECOVERY_TRACKING
         group by t1.ID_CFBIZ_UNDERWRITING
     ) t5 on t1.id = t5.ID_CFBIZ_UNDERWRITING



