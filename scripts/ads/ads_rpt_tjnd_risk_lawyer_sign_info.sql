-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250326
-- 目标表   ：dw_base.ads_rpt_tjnd_risk_lawyer_sign_info 风险部-律师登记
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_afg_business_infomation       业务申请表
--          dw_nd.ods_tjnd_yw_bh_compensatory               代偿表
--          dw_nd.ods_tjnd_yw_bh_recovery_tracking          追偿跟踪表
--          新业务系统
--          dw_base.dwd_guar_compt_info                     代偿信息汇总表
--          dw_base.dwd_guar_info_stat                      担保台账星型表
--          dw_nd.ods_t_ct_guar_person                      反担保保证信息表
--          dw_nd.ods_t_biz_proj_recovery_record            追偿记录表
--          dw_nd.ods_t_biz_proj_recovery_workpro           追偿工作进展情况表
-- 备注     ：
-- 变更记录 ：20251112 增加执行法官
-- ---------------------------------------
-- 重跑逻辑
delete
from dw_base.ads_rpt_tjnd_risk_lawyer_sign_info
where day_id = '${v_sdate}';

-- 旧业务系统逻辑
 insert into dw_base.ads_rpt_tjnd_risk_lawyer_sign_info
 (day_id, -- 数据日期
  guar_id, -- 业务id
  cust_name, -- 客户名称
  compt_date, -- 代偿时间
  unguar_per, -- 反担保人
  action_object, -- 诉请标的
  law_agency_name, -- 代理机构
  register_time, -- 立案时间
  case_no, -- 案号
  judge, -- 审理法官
  bank_account_freeze_status, -- 银行账户实际冻结情况
  freeze_start_time, -- 银行账户冻结开始时间
  freeze_end_time, -- 银行账户冻结结束时间
  chattel_seizure_status, -- 动产查封情况
  chattel_seizure_start_time, -- 动产查封开始时间
  chattel_seizure_end_time, -- 动产查封结束时间
  real_estate_seizure_status, -- 不动产查封情况
  real_estate_seizure_start_time, -- 不动产查封开始时间
  real_estate_seizure_end_time, -- 不动产查封结束时间
  court_hearing_time, -- 开庭时间
  court_judgment_result, -- 开庭结果
  mediation_judgment_content, -- 调解/判决书内容
  judgment_receipt_time, -- 调解/判决书签收时间
  execution_apply_date, -- 申请执行日
  document_number, -- 文书号
  execution_start_date, -- 执行时效开始日
  execution_expiry_date, -- 执行时效到期日
  asset_disposal_status, -- 财产处置情况(评估/询价/议价/拍卖/以物抵债等)
  height_restricted, -- 限高
  discredited, -- 失信
  termination_date, -- 终本日期
  recovery_date, -- 恢复日期
  closing_date, -- 终结日期
  settled, -- 是否结清
  settlement_date, -- 结清日
  remark, -- 备注
   enforcement_judge -- 执行法官
 )
 select '${v_sdate}' as day_id,
        t1.ID        as guar_id,
        cust_name,
        compt_date,
        t6.NAME      as unguar_per,
        null         as action_object,
        null         as law_agency_name,
        register_time,
        null         as case_no,
        null         as judge,
        null         as bank_account_freeze_status,
        null         as freeze_start_time,
        null         as freeze_end_time,
        null         as chattel_seizure_status,
        null         as chattel_seizure_start_time,
        null         as chattel_seizure_end_time,
        null         as real_estate_seizure_status,
        null         as real_estate_seizure_start_time,
        null         as real_estate_seizure_end_time,
        null         as court_hearing_time,
        null         as court_judgment_result,
        null         as mediation_judgment_content,
        null         as judgment_receipt_time,
        null         as execution_apply_date,
        null         as document_number,
        null         as execution_start_date,
        null         as execution_expiry_date,
        null         as asset_disposal_status,
        null         as height_restricted,
        null         as discredited,
        null         as termination_date,
        null         as recovery_date,
        null         as closing_date,
        null         as settled,
        null         as settlement_date,
        null         as remark,
		null         as  enforcement_judge -- 执行法官     20251112
 from (select ID,
              CUSTOMER_NAME as cust_name
       from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation
      ) t1
          inner join
      (
          select ID_CFBIZ_UNDERWRITING,
                 PAYMENT_DATE as compt_date
          from dw_nd.ods_creditmid_v2_z_migrate_bh_compensatory     -- 代偿表
          where status = 1
            and over_tag = 'BJ'
            and DELETED_BY is null
      ) t2 on t1.id = t2.ID_CFBIZ_UNDERWRITING
          left join
      (
          select ID_CFBIZ_UNDERWRITING,
                 min(DATE_OF_PROSECUTION) as register_time
          from dw_nd.ods_creditmid_v2_z_migrate_bh_recovery_tracking  --     共同还款人信息表   
          group by ID_CFBIZ_UNDERWRITING
      ) t5 on t1.id = t5.ID_CFBIZ_UNDERWRITING
         left join 
	  (
	     select ID_BUSINESS_INFORMATION
		       ,group_concat(NAME) as name
         from dw_nd.ods_creditmid_v2_z_migrate_afg_counter_guarantor 
		 group by ID_BUSINESS_INFORMATION
	  ) t6 on t1.id = t6.ID_BUSINESS_INFORMATION
;
 commit;

-- 新系统逻辑
insert into dw_base.ads_rpt_tjnd_risk_lawyer_sign_info
(day_id, -- 数据日期
 guar_id, -- 业务id
 cust_name, -- 客户名称
 compt_date, -- 代偿时间
 unguar_per, -- 反担保人
 action_object, -- 诉请标的
 law_agency_name, -- 代理机构
 register_time, -- 立案时间
 case_no, -- 案号
 judge, -- 审理法官
 bank_account_freeze_status, -- 银行账户实际冻结情况
 freeze_start_time, -- 银行账户冻结开始时间
 freeze_end_time, -- 银行账户冻结结束时间
 chattel_seizure_status, -- 动产查封情况
 chattel_seizure_start_time, -- 动产查封开始时间
 chattel_seizure_end_time, -- 动产查封结束时间
 real_estate_seizure_status, -- 不动产查封情况
 real_estate_seizure_start_time, -- 不动产查封开始时间
 real_estate_seizure_end_time, -- 不动产查封结束时间
 court_hearing_time, -- 开庭时间
 court_judgment_result, -- 开庭结果
 mediation_judgment_content, -- 调解/判决书内容
 judgment_receipt_time, -- 调解/判决书签收时间
 execution_apply_date, -- 申请执行日
 document_number, -- 文书号
 execution_start_date, -- 执行时效开始日
 execution_expiry_date, -- 执行时效到期日
 asset_disposal_status, -- 财产处置情况(评估/询价/议价/拍卖/以物抵债等)
 height_restricted, -- 限高
 discredited, -- 失信
 termination_date, -- 终本日期
 recovery_date, -- 恢复日期
 closing_date, -- 终结日期
 settled, -- 是否结清
 settlement_date, -- 结清日
 remark, -- 备注
 enforcement_judge -- 执行法官             20251112
)
select '${v_sdate}'        as day_id,
       t1.guar_id,
       cust_name,
       compt_date,
       ct_guar_person_name as unguar_per,                                                           -- 反担保人
       action_object,
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
       settlement_date,
       null                as remark
	  ,enforcement_judge  -- 执行法官
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
         where day_id = '${v_sdate}'
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
         select t1.project_id,
                action_object,                  -- 诉请标的
                law_agency_name,                -- 代理机构
                register_time,                  -- 立案时间
                case_no,                        -- 案号
                judge,                          -- 审理法官
                bank_account_freeze_status,     -- 银行账户实际冻结情况
                freeze_start_time,              -- 银行账户冻结开始时间
                freeze_end_time,                -- 银行账户冻结结束时间
                chattel_seizure_status,         -- 动产查封情况
                chattel_seizure_start_time,     -- 动产查封开始时间
                chattel_seizure_end_time,       -- 动产查封结束时间
                real_estate_seizure_status,     -- 不动产查封情况
                real_estate_seizure_start_time, -- 不动产查封开始时间
                real_estate_seizure_end_time,   -- 不动产查封结束时间
                court_hearing_time,             -- 开庭时间
                court_judgment_result,          -- 开庭结果
                mediation_judgment_content,     -- 调解/判决书内容
                judgment_receipt_time,          -- 调解/判决书签收时间
                execution_apply_date,           -- 申请执行日
                document_number,                -- 文书号
                execution_start_date,           -- 执行时效开始日
                execution_expiry_date,          -- 执行时效到期日
                asset_disposal_status,          -- 财产处置情况(评估/询价/议价/拍卖/以物抵债等)
                height_restricted,              -- 限高
                discredited,                    -- 失信
                termination_date,               -- 终本日期
                recovery_date,                  -- 恢复日期
                closing_date,                   -- 终结日期
                settled,                        -- 是否结清
                settlement_date                 -- 结清日
			   ,case when t2.case_other = '26' then t2.remark else null end as enforcement_judge      -- 执行法官
         from (
                  select *, row_number() over (partition by reco_id order by db_update_time desc) rn
                  from dw_nd.ods_t_biz_proj_recovery_record
              ) t1
                  left join
              (
                  select *, row_number() over (partition by reco_id order by db_update_time desc) rn
                  from dw_nd.ods_t_biz_proj_recovery_workpro        -- 追偿工作进展情况表
              ) t2 on t1.reco_id = t2.reco_id and t1.rn = 1 and t2.rn = 1
     ) t4 on t2.project_id = t4.project_id;
commit;