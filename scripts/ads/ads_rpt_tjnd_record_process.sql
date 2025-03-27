-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250324
-- 目标表   ：dw_base.ads_rpt_record_process    业务流程状态表
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_afg_business_infomation   业务申请表
--          dw_nd.ods_tjnd_yw_afg_business_approval     审批
--          dw_nd.ods_tjnd_yw_base_customers_history    BO,客户信息历史表,NEW
--          dw_nd.ods_tjnd_yw_base_product_management   BO,产品管理,NEW
--          dw_nd.ods_tjnd_yw_afg_survey                展期/延期调查表
--          dw_nd.ods_tjnd_yw_base_cooperative_institution_agreement BO,机构合作协议,NEW
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 旧业务系统逻辑
select t1.id                                              as guar_id,
       cust_name,
       full_bank,
       cert_num,
       case
           when main_type = '1' then '家庭农场（种养大户）'
           when main_type = '2' then '家庭农场'
           when main_type = '3' then '农民专业合作社'
           when main_type = '4' then '农业企业'
           end                                            as main_type,
       case
           when cust_type = 'enterprise' then '企业'
           when cust_type = 'person' then '个人'
           end                                            as cust_type,
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
           end                                            as gnd_indus_class,
       JSON_UNQUOTE(JSON_EXTRACT(area, '$[1]'))           as area,
       apply_amt / 10000                                  as apply_amt,
       apply_term,
       approval_total / 10000                             as approval_total,
       if(t5.F_ID is not null, '是', '否')                  as is_guar_due,
       guar_due_date,
       bank_proj_mgr_name,
       nd_proj_mgr_name,
       protocol_name,
       prod_mode,
       prod_name,
       case
           when first_instance_result = '1' then '通过'
           when first_instance_result = '2' then '不通过'
           when first_instance_result = '3' then '警示'
           end                                            as first_instance_result,
       if(data_source = '4', '银行接口', null)                as data_source,
       case
           when guar_status = 'GT' then '在保'
           when guar_status = 'ED' then '解保'
           end                                            as guar_status,
       apply_date,
       case
           when guar_status in ('GT', 'ED') then timestampdiff(day, apply_date, in_guar_date)
           else timestampdiff(day, apply_date, now()) end as guar_hand_days
from (select ID,
             CUSTOMER_NAME         as cust_name,
             ID_NUMBER             as cert_num,
             CUSTOMER_NATURE       as cust_type,
             APPLICATION_AMOUNT    as apply_amt,
             BANK_PROJECT_MANAGER  as bank_proj_mgr_name,
             BUSINESS_SP_USER_NAME as nd_proj_mgr_name,
             BUSI_MODE_NAME        as prod_mode,
             RESULT                as first_instance_result,
             DATA_SOURCE           as data_source,
             GUR_STATE             as guar_status,
             CREATED_TIME          as apply_date,
             -- 用于关联字段
             PRODUCT_GRADE,
             ID_CUSTOMER,
             RELATED_AGREEMENT_ID
      from dw_nd.ods_tjnd_yw_afg_business_infomation
     ) t1
         left join
     (
         select ID_BUSINESS_INFORMATION,
                FULL_BANK_NAME as full_bank,
                APPLY_TERM     as apply_term,
                APPROVAL_TOTAL as approval_total
         from dw_nd.ods_tjnd_yw_afg_business_approval
     ) t2
     on t1.ID = t2.ID_BUSINESS_INFORMATION
         left join
     (
         select ID,
                MAINBODY_TYPE_CORP        as main_type,
                INDUSTRY_CATEGORY_COMPANY as gnd_indus_class,
                AREA                      as area
         from dw_nd.ods_tjnd_yw_base_customers_history
     ) t3 on t1.ID_CUSTOMER = t3.ID
         left join
     (
         select fieldcode,
                product_name as prod_name
         from dw_nd.ods_tjnd_yw_base_product_management
     ) t4 on t1.PRODUCT_GRADE = t4.fieldcode
         left join
     (
         select f_id, max(GUR_DUE_DATE) as guar_due_date
         from dw_nd.ods_tjnd_yw_afg_survey
         where OVER_TAG = 'BJ'
           and DELETE_FLAG = '1'
         group by F_ID
     ) t5 on t1.id = t5.F_ID
         left join
     (
         select ID,
                protocol_name
         from dw_nd.ods_tjnd_yw_base_cooperative_institution_agreement
     ) t6 on t1.RELATED_AGREEMENT_ID = t6.ID
         left join
     (
         select ID_BUSINESS_INFORMATION,
                min(CREATED_TIME) as in_guar_date
         from dw_nd.ods_tjnd_yw_afg_voucher_infomation
         where DELETE_FLAG = 1
         group by ID_BUSINESS_INFORMATION
     ) t7 on t1.id = t7.ID_BUSINESS_INFORMATION;
