-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250327
-- 目标表   ：dw_base.ads_rpt_finance_record_stat_info 财务部-业务情况统计
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_afg_business_infomation   业务申请表
--          dw_nd.ods_tjnd_yw_afg_business_approval     审批
--          dw_nd.ods_tjnd_yw_afg_voucher_infomation    放款凭证信息
--          dw_nd.ods_tjnd_yw_base_customers_history    BO,客户信息历史表,NEW
--          dw_nd.ods_tjnd_yw_afg_refund_details        退费申请详情表
--          dw_nd.ods_tjnd_yw_afg_voucher_repayment     还款凭证信息
--          dw_nd.ods_tjnd_yw_base_product_management   BO,产品管理,NEW
--          新业务系统逻辑
--          dw_base.dwd_guar_info_all                   担保台账信息
--          dw_nd.ods_t_biz_project_main                主项目表
--          dw_nd.ods_gcredit_loan_ac_dxloanbookfee     费用交易流水信息文件
--          dw_base.dwd_guar_info_stat                  担保台账星型表
--          dw_nd.ods_t_biz_proj_refund                 退费项目表

-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 重跑逻辑
truncate table dw_base.ads_rpt_tjnd_finance_record_stat_info;
commit;

-- 旧业务系统逻辑
# insert into dw_base.ads_rpt_tjnd_finance_record_stat_info
# (day_id, -- 数据日期
#  guar_id, -- 业务id
#  cust_name, -- 客户(企业)名称
#  cert_num, -- 证件号码
#  weibao_cont_no, -- 委保合同编号
#  gnd_indus_class, -- 企业行业类型
#  guar_type, -- 担保类型
#  unguar_type, -- 反担保方式
#  guar_amt, -- 担保额
#  guar_status, -- 担保状态
#  loan_enter_date, -- 放款录入日期
#  loan_date, -- 实际放款日期
#  in_force_balance, -- 担保余额
#  guar_start_date, -- 担保期限（起）
#  guar_end_date, -- 担保期限（止）
#  guar_term, -- 担保期限（月）
#  loan_bank, -- 贷款银行
#  year_guar_rate, -- 年保费比率
#  guar_fee, -- 担保保费
#  is_peasant_household, -- 是否农业户口
#  is_micro_company, -- 是否小微企业
#  received_date, -- 保费入账日
#  refund_amt, -- 退费金额
#  refund_date, -- 退费日期
#  unmatured_liability_reserve, -- 未到期责任准备金
#  guar_liability_reserve, -- 担保赔偿责任准备金
#  extraction_month -- 提取月份
# )
# select '${v_sdate}'                             as day_id,
#        t1.id                                    as guar_id,
#        cust_name,
#        cert_num,
#        weibao_cont_no,
#        case
#            when gnd_indus_class = '0' then '农产品初加工'
#            when gnd_indus_class = '1' then '粮食种植'
#            when gnd_indus_class = '2' then '重要、特色农产品种植'
#            when gnd_indus_class = '3' then '其他畜牧业'
#            when gnd_indus_class = '4' then '生猪养殖'
#            when gnd_indus_class = '5' then '农产品流通'
#            when gnd_indus_class = '6' then '渔业生产'
#            when gnd_indus_class = '7' then '农资、农机、农技等农业社会化服务'
#            when gnd_indus_class = '8' then '农业新业态'
#            when gnd_indus_class = '9' then '农田建设'
#            when gnd_indus_class = '10' then '其他农业项目'
#            end                                  as gnd_indus_class,
#        guar_type,
#        case
#            when unguar_type = '[]' then '信用/免担保'
#            when unguar_type = '["counterGuarantor"]' then '保证'
#            when unguar_type = '["gage"]' then '抵押'
#            when unguar_type = '["collateral"]' then '质押'
#            when unguar_type is not null then '组合'
#            end                                  as unguar_type,
#        guar_amt / 10000                         as guar_amt,
#        case
#            when guar_status = 'GT' then '在保'
#            when guar_status = 'ED' then '解保'
#            end                                  as guar_status,
#        date_format(loan_enter_date, '%Y-%m-%d') as loan_enter_date,
#        loan_date,
#        (guar_amt - repayment_amt) / 10000       as in_force_balance,
#        guar_start_date,
#        guar_end_date,
#        guar_term,
#        loan_bank,
#        year_guar_rate,
#        guar_fee,
#        null                                     as is_peasant_household,
#        case
#            when is_micro_company = '0' then '否'
#            when is_micro_company = '1' then '是'
#            end                                  as is_micro_company,
#        date_format(received_date, '%Y-%m-%d')   as received_date,
#        refund_amt,
#        refund_date,
#        null                                     as unmatured_liability_reserve,
#        null                                     as guar_liability_reserve,
#        null                                     as extraction_month
# from (
#          select id,                                -- 业务id
#                 CUSTOMER_NAME      as cust_name,   -- 客户姓名
#                 ID_NUMBER          as cert_num,    -- 证件号码
#                 COUNTER_GUR_METHOD as unguar_type, -- 反担保方式
#                 GUR_STATE          as guar_status, -- 担保状态
#                 ID_CUSTOMER,                       -- 客户id
#                 PRODUCT_GRADE                      -- 产品编码
#          from dw_nd.ods_tjnd_yw_afg_business_infomation
#      ) t1
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                 -- 业务id
#                 sum(RECEIPT_AMOUNT)  as guar_amt,        -- 担保额
#                 min(LOAN_START_DATE) as loan_date,       -- 实际放款日期
#                 min(LOAN_START_DATE) as guar_start_date, -- 贷款起始日期
#                 max(LOAN_END_DATE)   as guar_end_date,   --  贷款结束日期
#                 max(CREATED_TIME)    as loan_enter_date  -- 放款录入日期
#          from dw_nd.ods_tjnd_yw_afg_voucher_infomation
#          where DELETE_FLAG = 1
#          group by ID_BUSINESS_INFORMATION
#      ) t2 on t1.id = t2.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,          -- 业务id
#                 WTBZHT_NO      as weibao_cont_no, -- 委托保证合同编号
#                 APPROVED_TERM  as guar_term,      -- 本次审批期限
#                 FULL_BANK_NAME as loan_bank,      -- 合作银行全称
#                 GUARANTEE_TATE as year_guar_rate, -- 担保费率
#                 SHARE_FEE      as guar_fee,       -- 实际应收保费
#                 RECEIVED_TIME  as received_date   -- 收费日期
#          from dw_nd.ods_tjnd_yw_afg_business_approval
#      ) t3 on t1.id = t3.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID,                                           -- 客户id
#                 INDUSTRY_CATEGORY_COMPANY as gnd_indus_class, -- 行业分类(公司)
#                 IS_MICRO_COMPANY          as is_micro_company -- 是否小微企业
#          from dw_nd.ods_tjnd_yw_base_customers_history
#      ) t4 on t1.ID_CUSTOMER = t4.ID
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                 -- 业务id
#                 sum(ACTUAL_REFUND_AMOUNT) as refund_amt, -- 退费金额
#                 max(REFUND_DATE)          as refund_date -- 退费日期
#          from dw_nd.ods_tjnd_yw_afg_refund_details
#          where DELETE_FLAG = 1
#            and OVER_TAG = 'BJ'
#          group by ID_BUSINESS_INFORMATION
#      ) t5
#      on t1.id = t5.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                  -- 业务id
#                 sum(REPAYMENT_PRINCIPAL) as repayment_amt -- 还款金额
#          from dw_nd.ods_tjnd_yw_afg_voucher_repayment
#          where DELETE_FLAG = 1
#          group by ID_BUSINESS_INFORMATION
#      ) t6 on t1.ID = t6.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select fieldcode,                -- 产品编码
#                 PRODUCT_NAME as guar_type -- 产品名称
#          from dw_nd.ods_tjnd_yw_base_product_management
#      ) t7 on t1.PRODUCT_GRADE = t7.fieldcode;
# commit;


-- 新业务系统逻辑
insert into dw_base.ads_rpt_tjnd_finance_record_stat_info
(day_id, -- 数据日期
 guar_id, -- 业务id
 cust_name, -- 客户(企业)名称
 cert_num, -- 证件号码
 weibao_cont_no, -- 委保合同编号
 gnd_indus_class, -- 企业行业类型
 guar_type, -- 担保类型
 unguar_type, -- 反担保方式
 guar_amt, -- 担保额
 guar_status, -- 担保状态
 loan_enter_date, -- 放款录入日期
 loan_date, -- 实际放款日期
 in_force_balance, -- 担保余额
 guar_start_date, -- 担保期限（起）
 guar_end_date, -- 担保期限（止）
 guar_term, -- 担保期限（月）
 loan_bank, -- 贷款银行
 year_guar_rate, -- 年保费比率
 guar_fee, -- 担保保费
 is_peasant_household, -- 是否农业户口
 is_micro_company, -- 是否小微企业
 received_date, -- 保费入账日
 refund_amt, -- 退费金额
 refund_date, -- 退费日期
 unmatured_liability_reserve, -- 未到期责任准备金
 guar_liability_reserve, -- 担保赔偿责任准备金
 extraction_month -- 提取月份
)
select '${v_sdate}' as day_id,
       t1.guar_id,
       cust_name,
       cert_num,
       weibao_cont_no,
       gnd_indus_class,
       guar_type,
       unguar_type,
       guar_amt,
       guar_status,
       loan_enter_date,
       loan_date,
       onguar_amt   as in_force_balance,
       guar_start_date,
       guar_end_date,
       guar_term,
       loan_bank,
       year_guar_rate,
       guar_fee,
       null         as is_peasant_household,
       null         as is_micro_company,
       received_date,
       refund_amt,
       refund_date,
       null         as unmatured_liability_reserve,
       null         as guar_liability_reserve,
       null         as extraction_month
from (
         select guar_id       as guar_id,         -- 项目编号
                cust_name     as cust_name,       -- 客户名称
                cert_no       as cert_num,        -- 身份证号
                trust_cont_no as weibao_cont_no,  -- 委保合同编号
                guar_class    as gnd_indus_class, -- 行业类型
                protect_guar  as unguar_type,     -- 反担保措施
                guar_amt      as guar_amt,        -- 放款金额
                item_stt      as guar_status,     -- 项目状态
                loan_reg_dt   as loan_enter_date, -- 放款登记日期
                grant_dt      as loan_date,       -- 放款日期
                loan_begin_dt as guar_start_date, -- 贷款开始时间
                loan_end_dt   as guar_end_date,   -- 贷款结束时间
                loan_term     as guar_term,       -- 贷款合同期限
                loan_bank     as loan_bank,       -- 贷款银行
                guar_rate     as year_guar_rate,  -- 担保费率
                guar_fee      as guar_fee         -- 保费金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
     ) t1
         left join
     (
         select code,      -- 项目编号
                guar_type, -- 担保类型
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main) t1
         where rn = 1
     ) t2 on t1.guar_id = t2.code
         left join
     (
         select drawndn_seqno,                   -- 项目编号
                max(trade_date) as received_date -- 保费入账日
         from dw_nd.ods_gcredit_loan_ac_dxloanbookfee
         group by drawndn_seqno
     ) t3 on t1.guar_id = t3.drawndn_seqno
         left join
     (
         select guar_id,   -- 项目编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                               -- 项目id
                sum(refund_amount) * 10000 as refund_amt, -- 退费金额(元)
                max(pay_date)              as refund_date -- 缴费日期
         from dw_nd.ods_t_biz_proj_refund
         group by project_id
     ) t5 on t4.project_id = t4.project_id
         left join
     (
         select guar_id,
                onguar_amt
         from dw_base.dwd_guar_info_onguar
         where day_id = '${v_sdate}'
     ) t6 on t1.guar_id = t6.guar_id;
commit;