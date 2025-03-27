-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250320
-- 目标表   ：dw_base.ads_rpt_record_detail 业务明细表
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_afg_business_infomation   业务申请表
--          dw_nd.ods_tjnd_yw_afg_business_approval     审批
--          dw_nd.ods_tjnd_yw_afg_voucher_infomation    放款凭证信息
--          dw_nd.ods_tjnd_yw_base_customers_history    BO,客户信息历史表,NEW
--          dw_nd.ods_tjnd_yw_base_product_management   BO,产品管理,NEW
--          dw_nd.ods_tjnd_yw_afg_voucher_repayment     还款凭证信息
--          dw_nd.ods_tjnd_yw_bh_compensatory           代偿表
--          dw_nd.ods_tjnd_yw_bh_overdue_plan           逾期登记表
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 旧业务系统逻辑
select t1.ID,
       cust_name,
       case
           when cust_type = 'enterprise' then '企业'
           when cust_type = 'person' then '个人'
           end                                                                      as cust_type,
       guar_approved_amt / 10000                                                    as guar_approved_amt,
       loan_cont_amt / 10000                                                        as loan_cont_amt,
       guar_amt / 10000                                                             as guar_amt,
       (guar_amt - repayment_amt) / 10000                                           as in_force_balance,
       if(is_first_guar is not null,
          case
              when is_first_guar = '0' then '否'
              when is_first_guar = '1' then '是' end,
          if(t9.CUSTOMER_NAME is null, '是', '否'))                                   as is_first_guar,
       loan_date,
       guar_start_date,
       guar_end_date,
       case
           when guar_status = 'ED' then concat(loan_date, '至', t10.DATE_OF_SET) end as guar_date,
       main_biz,
       case
           when unguar_type = '[]' then '信用/免担保'
           when unguar_type = '["counterGuarantor"]' then '保证'
           when unguar_type = '["gage"]' then '抵押'
           when unguar_type = '["collateral"]' then '质押'
           when unguar_type is not null then '组合'
           end                                                                      as unguar_type,
       loan_bank_name,
       guar_approved_rate,
       loan_rate,
       guar_approved_rate + loan_rate                                               as overall_cost,
       nd_proj_mgr_name,
       prod_type,
       guar_approved_period,
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
           end                                                                      as gnd_indus_class,
       phone_no,
       is_guar_sight,
       case
           when is_micro_company = '0' then '否'
           when is_micro_company = '1' then '是'
           end                                                                      as is_micro_company,
       case
           when is_support_snzt = '0' then '否'
           when is_support_snzt = '1' then '是'
           end                                                                      as is_support_snzt,
       case
           when is_support_scsf = '0' then '否'
           when is_support_scsf = '1' then '是'
           end                                                                      as is_support_scsf,
       case
           when is_support_emerging_industry = '0' then '否'
           when is_support_emerging_industry = '1' then '是'
           end                                                                      as is_support_emerging_industry,
       weibao_cont_no,
       case
           when cert_type = '0' then '身份证'
           when cert_type = 'b' then '统一社会信用代码'
           end                                                                      as cert_type,
       cert_num,
       guar_cont_no,
       JSON_UNQUOTE(JSON_EXTRACT(area, '$[1]'))                                     as area,
       case
           when branch_off = 'YW_NHDLBSC' then '宁河东丽办事处'
           when branch_off = 'YW_JNBHXQBSC' then '津南滨海新区办事处'
           when branch_off = 'YW_WQBCBSC' then '武清北辰办事处'
           when branch_off = 'YW_XQJHBSC' then '西青静海办事处'
           when branch_off = 'YW_JZBSC' then '蓟州办事处'
           when branch_off = 'YW_BDBSC' then '宝坻办事处'
           end                                                                      as branch_off,
       case
           when guar_status = 'GT' then '在保'
           when guar_status = 'ED' then '解保'
           end                                                                      as guar_status,
       case
           when corp_type = '1' then '大型'
           when corp_type = '2' then '中型'
           when corp_type = '3' then '小型'
           when corp_type = '4' then '微型'
           end                                                                      as corp_type,
       repayment_amt,
       date_format(repayment_date, '%Y-%m-%d')                                      as repayment_date,
       if(t7.ID_CFBIZ_UNDERWRITING is not null, '是', '否')                           as is_compt,
       if(t8.ID_CFBIZ_UNDERWRITING is not null, '是', '否')                           as is_ovd
from (
         select ID,
                CUSTOMER_NAME         as cust_name,
                CUSTOMER_NATURE       as cust_type,
                COUNTER_GUR_METHOD    as unguar_type,
                BUSINESS_SP_USER_NAME as nd_proj_mgr_name,
                BUSI_MODE_NAME        as is_guar_sight,
                CERT_TYPE             as cert_type,
                ID_NUMBER             as cert_num,
                AREA                  as area,
                enter_code            as branch_off,
                GUR_STATE             as guar_status,
                FIRST_GUARANTEE       as is_first_guar,
                ID_CUSTOMER,
                PRODUCT_GRADE
         from dw_nd.ods_tjnd_yw_afg_business_infomation
     ) t1
         left join
     (
         select ID_BUSINESS_INFORMATION,
                APPROVAL_TOTAL       as guar_approved_amt,
                LOAN_CONTRACT_AMOUNT as loan_cont_amt,
                FULL_BANK_NAME       as loan_bank_name,
                GUARANTEE_TATE       as guar_approved_rate,
                YEAR_LOAN_RATE       as loan_rate,
                APPROVED_TERM        as guar_approved_period,
                WTBZHT_NO            as weibao_cont_no,
                GUARANTY_CONTRACT_NO as guar_cont_no
         from dw_nd.ods_tjnd_yw_afg_business_approval
     ) t2 on t1.ID = t2.ID_BUSINESS_INFORMATION
         left join
     (
         select ID_BUSINESS_INFORMATION,
                sum(RECEIPT_AMOUNT)  as guar_amt,
                min(LOAN_START_DATE) as loan_date,
                min(LOAN_START_DATE) as guar_start_date,
                max(LOAN_END_DATE)   as guar_end_date
         from dw_nd.ods_tjnd_yw_afg_voucher_infomation
         where DELETE_FLAG = 1
         group by ID_BUSINESS_INFORMATION
     ) t3 on t1.id = t3.ID_BUSINESS_INFORMATION
         left join
     (
         select ID,
                BUSINESS_ITEM                as main_biz,
                INDUSTRY_CATEGORY_COMPANY    as gnd_indus_class,
                TEL                          as phone_no,
                IS_MICRO_COMPANY             as is_micro_company,
                IS_SUPPORT_SNZT              as is_support_snzt,
                IS_SUPPORT_SCSF              as is_support_scsf,
                IS_SUPPORT_EMERGING_INDUSTRY as is_support_emerging_industry,
                ENTERPISE_TYPE               as corp_type
         from dw_nd.ods_tjnd_yw_base_customers_history
     ) t4 on t1.ID_CUSTOMER = t4.ID
         left join
     (
         select fieldcode,
                PRODUCT_NAME as prod_type
         from dw_nd.ods_tjnd_yw_base_product_management
     ) t5 on t1.PRODUCT_GRADE = t5.fieldcode
         left join
     (
         select ID_BUSINESS_INFORMATION,
                sum(REPAYMENT_PRINCIPAL) as repayment_amt,
                max(REPAYMENT_TIME)      as repayment_date
         from dw_nd.ods_tjnd_yw_afg_voucher_repayment
         where DELETE_FLAG = 1
         group by ID_BUSINESS_INFORMATION
     ) t6 on t1.ID = t6.ID_BUSINESS_INFORMATION
         left join
     (
         select ID_CFBIZ_UNDERWRITING
         from dw_nd.ods_tjnd_yw_bh_compensatory
         where status = 1
           and over_tag = 'BJ'
           and DELETED_BY is null
     ) t7 on t1.ID = t7.ID_CFBIZ_UNDERWRITING
         left join
     (
         select ID_CFBIZ_UNDERWRITING
         from (select *, row_number() over (partition by ID_CFBIZ_UNDERWRITING order by CREATED_TIME desc) rn
               from dw_nd.ods_tjnd_yw_bh_overdue_plan
               where STATUS = '1') t1
         where rn = 1
     ) t8 on t1.ID = t8.ID_CFBIZ_UNDERWRITING
         left join
     (
         select distinct CUSTOMER_NAME from dw_nd.ods_tjnd_yw_afg_business_infomation where GUR_STATE = 'ED'
     ) t9 on t1.cust_name = t9.CUSTOMER_NAME
         left join
     (
         select ID_BUSINESS_INFORMATION,
                DATE_OF_SET
         from dw_nd.ods_tjnd_yw_afg_guarantee_relieve
         where DELETED_FLAG = '1'
           and IS_RELIEVE_FLAG = '0'
     ) t10 on t1.ID = t10.ID_BUSINESS_INFORMATION;

