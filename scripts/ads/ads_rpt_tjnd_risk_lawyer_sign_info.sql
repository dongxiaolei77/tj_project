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

-- 新系统逻辑
select *
from (
         select guar_id,                 -- 业务id
                cust_name,               -- 客户名称
                compt_time as compt_date -- 代偿拨付日期
         from dw_base.dwd_guar_compt_info
         where day_id = '${v_sdate}'
     ) t1
         left join
     (
         select guar_id,
                project_id
         from dw_base.dwd_guar_info_stat
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,
                ct_guar_person_name -- 反担保人名称
         from (
                  select *, row_number() over (partition by project_id order by db_update_time desc ) rn
                  from dw_nd.ods_t_ct_guar_person
              ) t1
         where rn = 1
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select action_object,
                law_agency_name,
                register_time,
                case_no,
                judge,
                bank_account_freeze_status,
                freeze_start_time,
                freeze_end_time,
                chattel_seizure_status,
                chattel_seizure_start_time,
                chattel_seizure_end_time,
                real_estate_seizure_status,
                real_estate_seizure_start_time,
                real_estate_seizure_end_time,
                court_hearing_time,
                court_judgment_result,
                mediation_judgment_content,
                judgment_receipt_time,
                execution_apply_date,
                document_number,
                execution_start_date,
                execution_expiry_date,
                asset_disposal_status,
                height_restricted,
                discredited,
                termination_date,
                recovery_date,
                closing_date,
                settled,
                settlement_date
         from dw_nd.ods_t_biz_proj_recovery_record t1
                  left join dw_nd.ods_t_biz_proj_recovery_workpro t2 on t1.reco_id = t2.reco_id
     )