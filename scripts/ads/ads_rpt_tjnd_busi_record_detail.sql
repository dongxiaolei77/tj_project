-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250320
-- 目标表   ：dw_base.ads_rpt_tjnd_busi_record_detail   业务部-业务明细
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
--          新业务系统
--          dw_base.dwd_guar_info_all                           担保台账信息
--          dw_base.dwd_guar_info_stat                          担保台账星型表
--          dw_nd.ods_t_biz_project_main                        主项目表
--          dw_nd.ods_t_biz_proj_recovery_record                追偿记录表
--          dw_nd.ods_t_biz_proj_recovery_repay_detail_record   登记还款记录
--          dw_nd.ods_t_biz_proj_repayment_detail
--          dw_base.dwd_guar_info_onguar                        担保台账在保信息
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 重跑逻辑
truncate table dw_base.ads_rpt_tjnd_busi_record_detail;
commit;
-- 旧业务系统逻辑
insert into dw_base.ads_rpt_tjnd_busi_record_detail
(day_id, -- 数据日期
 guar_id, -- 业务id
 cust_name, -- 客户名称
 cust_type, -- 客户性质
 guar_approved_amt, -- 担保审批金额（万元）
 loan_cont_amt, -- 借款合同金额（万元）
 guar_amt, -- 担保金额（万元）
 in_force_balance, -- 在保余额（万元）
 is_first_guar, -- 是否首担
 loan_date, -- 放款日期
 guar_start_date, -- 担保开始日期
 guar_end_date, -- 担保到期日期
 guar_date, -- 担保日期
 main_biz, -- 主营业务
 unguar_type, -- 反担保方式
 loan_bank_name, -- 放款银行全称
 guar_approved_rate, -- 担保审批费率(%)
 loan_rate, -- 年贷款利率(%)
 overall_cost, -- 综合成本(%)
 nd_proj_mgr_name, -- 农担项目经理姓名
 prod_type, -- 产品类型
 guar_approved_period, -- 担保审批期限(月）
 gnd_indus_class, -- 行业归类国农担标准
 phone_no, -- 联系方式
 is_guar_sight, -- 是否为见贷即保
 is_micro_company, -- 是否小微企业
 is_support_snzt, -- 是否支持三农主体
 is_support_scsf, -- 是否支持双创双服主体
 is_support_emerging_industry, -- 是否支持战略性新兴产业
 weibao_cont_no, -- 委托保证合同编号
 cert_type, -- 证件类型
 cert_num, -- 证件号码
 warr_cont_no, -- 保证合同编号
 area, -- 区县
 branch_off, -- 办事处
 guar_status, -- 担保状态
 corp_type, -- 企业类型
 repayment_amt, -- 还款本金金额
 repayment_date, -- 还款日期
 is_compt, -- 是否代偿
 is_ovd -- 是否逾期
)
select '${v_sdate}'                                                                 as day_id,
       t1.ID                                                                        as guar_id,
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
         select ID,                                        -- 业务id
                CUSTOMER_NAME         as cust_name,        -- 客户名称
                CUSTOMER_NATURE       as cust_type,        -- 客户性质
                COUNTER_GUR_METHOD    as unguar_type,      -- 反担保方式
                BUSINESS_SP_USER_NAME as nd_proj_mgr_name, -- 农担经理姓名
                BUSI_MODE_NAME        as is_guar_sight,    -- 是否为见贷即保
                CERT_TYPE             as cert_type,        -- 证件类型
                ID_NUMBER             as cert_num,         -- 证件号码
                AREA                  as area,             -- 区县
                enter_code            as branch_off,       -- 办事处
                GUR_STATE             as guar_status,      -- 担保状态
                FIRST_GUARANTEE       as is_first_guar,    -- 是否首担
                ID_CUSTOMER,                               -- 客户id
                PRODUCT_GRADE                              -- 产品编码
         from dw_nd.ods_tjnd_yw_afg_business_infomation
     ) t1
         left join
     (
         select ID_BUSINESS_INFORMATION,                      -- 业务id
                APPROVAL_TOTAL       as guar_approved_amt,    -- 本次审批金额
                LOAN_CONTRACT_AMOUNT as loan_cont_amt,        -- 借款合同金额
                FULL_BANK_NAME       as loan_bank_name,       -- 合作银行全称
                GUARANTEE_TATE       as guar_approved_rate,   -- 担保费率
                YEAR_LOAN_RATE       as loan_rate,            -- 年贷款利率
                APPROVED_TERM        as guar_approved_period, -- 本次审批期限
                WTBZHT_NO            as weibao_cont_no,       -- 委托保证合同编号
                GUARANTY_CONTRACT_NO as guar_cont_no          -- 保证合同编号
         from dw_nd.ods_tjnd_yw_afg_business_approval
     ) t2 on t1.ID = t2.ID_BUSINESS_INFORMATION
         left join
     (
         select ID_BUSINESS_INFORMATION,                 -- 业务id
                sum(RECEIPT_AMOUNT)  as guar_amt,        -- 凭证金额
                min(LOAN_START_DATE) as loan_date,       -- 贷款起始日期
                min(LOAN_START_DATE) as guar_start_date, -- 贷款起始日期
                max(LOAN_END_DATE)   as guar_end_date    -- 贷款结束日期
         from dw_nd.ods_tjnd_yw_afg_voucher_infomation
         where DELETE_FLAG = 1
         group by ID_BUSINESS_INFORMATION
     ) t3 on t1.id = t3.ID_BUSINESS_INFORMATION
         left join
     (
         select ID,                                                           -- 客户id
                BUSINESS_ITEM                as main_biz,                     -- 主营业务
                INDUSTRY_CATEGORY_COMPANY    as gnd_indus_class,              -- 行业分类(公司)
                TEL                          as phone_no,                     -- 联系电话
                IS_MICRO_COMPANY             as is_micro_company,             -- 是否小微企业
                IS_SUPPORT_SNZT              as is_support_snzt,              -- 是否支持三农主题
                IS_SUPPORT_SCSF              as is_support_scsf,              -- 是否支持双创双服主体
                IS_SUPPORT_EMERGING_INDUSTRY as is_support_emerging_industry, -- 是否支持战略性新兴产业
                ENTERPISE_TYPE               as corp_type                     -- 企业规模
         from dw_nd.ods_tjnd_yw_base_customers_history
     ) t4 on t1.ID_CUSTOMER = t4.ID
         left join
     (
         select fieldcode,                -- 产品编码
                PRODUCT_NAME as prod_type -- 产品名称
         from dw_nd.ods_tjnd_yw_base_product_management
     ) t5 on t1.PRODUCT_GRADE = t5.fieldcode
         left join
     (
         select ID_BUSINESS_INFORMATION,                   -- 业务id
                sum(REPAYMENT_PRINCIPAL) as repayment_amt, -- 还款金额
                max(REPAYMENT_TIME)      as repayment_date -- 还款时间
         from dw_nd.ods_tjnd_yw_afg_voucher_repayment
         where DELETE_FLAG = 1
         group by ID_BUSINESS_INFORMATION
     ) t6 on t1.ID = t6.ID_BUSINESS_INFORMATION
         left join
     (
         select ID_CFBIZ_UNDERWRITING -- 业务id
         from dw_nd.ods_tjnd_yw_bh_compensatory
         where status = 1
           and over_tag = 'BJ'
           and DELETED_BY is null
     ) t7 on t1.ID = t7.ID_CFBIZ_UNDERWRITING
         left join
     (
         select ID_CFBIZ_UNDERWRITING -- 业务id
         from (select *, row_number() over (partition by ID_CFBIZ_UNDERWRITING order by CREATED_TIME desc) rn
               from dw_nd.ods_tjnd_yw_bh_overdue_plan
               where STATUS = '1') t1
         where rn = 1
     ) t8 on t1.ID = t8.ID_CFBIZ_UNDERWRITING
         left join
     (
         select distinct CUSTOMER_NAME
         from dw_nd.ods_tjnd_yw_afg_business_infomation
         where GUR_STATE = 'ED' -- 判断是否首担 逻辑
     ) t9 on t1.cust_name = t9.CUSTOMER_NAME
         left join
     (
         select ID_BUSINESS_INFORMATION, -- 业务id
                DATE_OF_SET              -- 解保日期
         from dw_nd.ods_tjnd_yw_afg_guarantee_relieve
         where DELETED_FLAG = '1'
           and IS_RELIEVE_FLAG = '0'
     ) t10 on t1.ID = t10.ID_BUSINESS_INFORMATION;
commit;

-- ------------------------------------
-- 新业务系统逻辑
insert into dw_base.ads_rpt_tjnd_busi_record_detail
(day_id, -- 数据日期
 guar_id, -- 业务id
 cust_name, -- 客户名称
 cust_type, -- 客户性质
 guar_approved_amt, -- 担保审批金额（万元）
 loan_cont_amt, -- 借款合同金额（万元）
 guar_amt, -- 担保金额（万元）
 in_force_balance, -- 在保余额（万元）
 is_first_guar, -- 是否首担
 loan_date, -- 放款日期
 guar_start_date, -- 担保开始日期
 guar_end_date, -- 担保到期日期
 guar_date, -- 担保日期
 main_biz, -- 主营业务
 unguar_type, -- 反担保方式
 loan_bank_name, -- 放款银行全称
 guar_approved_rate, -- 担保审批费率(%)
 loan_rate, -- 年贷款利率(%)
 overall_cost, -- 综合成本(%)
 nd_proj_mgr_name, -- 农担项目经理姓名
 prod_type, -- 产品类型
 guar_approved_period, -- 担保审批期限(月）
 gnd_indus_class, -- 行业归类国农担标准
 phone_no, -- 联系方式
 is_guar_sight, -- 是否为见贷即保
 is_micro_company, -- 是否小微企业
 is_support_snzt, -- 是否支持三农主体
 is_support_scsf, -- 是否支持双创双服主体
 is_support_emerging_industry, -- 是否支持战略性新兴产业
 weibao_cont_no, -- 委托保证合同编号
 cert_type, -- 证件类型
 cert_num, -- 证件号码
 warr_cont_no, -- 保证合同编号
 area, -- 区县
 branch_off, -- 办事处
 guar_status, -- 担保状态
 corp_type, -- 企业类型
 repayment_amt, -- 还款本金金额
 repayment_date, -- 还款日期
 is_compt, -- 是否代偿
 is_ovd -- 是否逾期
)
select '${v_sdate}'                                              as day_id,
       t1.guar_id,
       cust_name,
       cust_type,
       guar_approved_amt,
       loan_cont_amt,
       guar_amt,
       in_force_balance,
       is_first_guar,
       loan_date,
       guar_start_date,
       guar_end_date,
       guar_date,
       main_biz,
       unguar_type,
       loan_bank_name,
       guar_approved_rate,
       loan_rate,
       round(guar_approved_rate + loan_rate, 6)                  as overall_cost,
       nd_proj_mgr_name,
       prod_type,
       guar_approved_period,
       gnd_indus_class,
       phone_no,
       '否'                                                       as is_guar_sight,
       case when corp_type in ('03', '04') then '是' else '否' end as is_micro_company,
       is_support_snzt,
       case
           when cust_main_label like '%02%' or
                cust_main_label like '%03%' or
                cust_main_label like '%04%' or
                cust_main_label like '%05%' then '是'
           else '否' end                                          as is_support_scsf,
       case
           when cust_main_label like '%06%' then '是'
           else '否' end                                          as is_support_emerging_industry,
       weibao_cont_no,
       cert_type,
       cert_num,
       warr_cont_no,
       area,
       case
           when branch_off = 'NHDLBranch' then '宁河东丽办事处'
           when branch_off = 'JNBHXQBranch' then '津南滨海新区办事处'
           when branch_off = 'WQBCBranch' then '武清北辰办事处'
           when branch_off = 'XQJHBranch' then '西青静海办事处'
           when branch_off = 'JZBranch' then '蓟州办事处'
           when branch_off = 'BDBranch' then '宝坻办事处'
           end                                                   as branch_off,
       guar_status,
       case
           when corp_type = '01' then '大型企业'
           when corp_type = '02' then '中型企业'
           when corp_type = '03' then '小型企业'
           when corp_type = '04' then '微型企业'
           end                                                   as corp_type,
       repayment_amt,
       repayment_date,
       is_compt,
       is_ovd
from (
         select guar_id        as guar_id,              -- 台账编号
                cust_name      as cust_name,            -- 客户名称
                cust_type      as cust_type,            -- 客户类型
                appl_amt       as guar_approved_amt,    -- 申报金额(万元)
                loan_amt       as loan_cont_amt,        -- 贷款合同金额
                guar_amt       as guar_amt,             -- 放款金额
                is_first_guar  as is_first_guar,        -- 是否首保
                loan_notify_dt as loan_date,            -- 放款时间
                loan_reg_dt    as guar_date,            -- 放款登记日期
                protect_guar   as unguar_type,          -- 反担保措施
                loan_bank      as loan_bank_name,       -- 贷款银行
                guar_prod      as prod_type,            -- 担保产品
                aprv_term      as guar_approved_period, -- 批复期限
                guar_class     as gnd_indus_class,      -- 国担分类
                tel_no         as phone_no,             -- 联系电话
                trust_cont_no  as weibao_cont_no,       -- 委保合同编号
                cust_type      as cert_type,            -- 客户类型
                cert_no        as cert_num,             -- 身份证号
                guar_cnot_no   as warr_cont_no,         -- 保证合同编号
                county_name    as area,                 -- 区县
                item_stt       as guar_status,          -- 项目状态
                is_compensate  as is_compt,             -- 是否代偿
                is_ovd         as is_ovd                -- 是否逾期
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
     ) t1
         left join
     (
         select guar_id,                            -- 业务编号
                project_id,                         -- 项目id
                loan_star_dt as guar_start_date,    -- 贷款开始时间
                loan_end_dt  as guar_end_date,      -- 贷款结束时间
                guar_rate    as guar_approved_rate, -- 担保利率
                loan_rate    as loan_rate           -- 贷款利率
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select code,                                  -- 项目id
                main_business_one as main_biz,         -- 经营主业
                enterprise_scale  as corp_type,        -- 企业规模
                create_name       as nd_proj_mgr_name, -- 创建者
                is_farmer         as is_support_snzt,  -- 是否支持三农主体
                cust_main_label,                       -- 客户主体标签
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main) t1
         where rn = 1
     ) t3 on t1.guar_id = t3.code
         left join
     (
         select project_id,                                    -- 项目id
                sum(actual_repayment_amount) as repayment_amt, -- 还款金额
                max(repay_date)              as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t4 on t2.project_id = t4.project_id
         left join
     (
         select guar_id,
                onguar_amt as in_force_balance -- 在保余额
         from dw_base.dwd_guar_info_onguar
         where day_id = '${v_sdate}'
     ) t5 on t1.guar_id = t5.guar_id
         left join
     (
         select CITY_NAME_,              -- 区县名称
                ROLE_CODE_ as branch_off -- 办事处编码
         from dw_base.dwd_imp_area_branch
     ) t6 on t1.area = t6.CITY_NAME_;
commit;