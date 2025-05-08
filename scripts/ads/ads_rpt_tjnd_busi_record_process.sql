-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250324
-- 目标表   ：dw_base.ads_rpt_tjnd_busi_record_process    业务部-业务流程状态
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_afg_business_infomation   业务申请表
--          dw_nd.ods_tjnd_yw_afg_business_approval     审批
--          dw_nd.ods_tjnd_yw_base_customers_history    BO,客户信息历史表,NEW
--          dw_nd.ods_tjnd_yw_base_product_management   BO,产品管理,NEW
--          dw_nd.ods_tjnd_yw_afg_survey                展期/延期调查表
--          dw_nd.ods_tjnd_yw_base_cooperative_institution_agreement BO,机构合作协议,NEW
--
--          新业务系统
--          dw_base.dwd_guar_info_all                           担保台账信息
--          dw_nd.ods_t_biz_project_main                        主项目表
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 重跑逻辑
truncate table dw_base.ads_rpt_tjnd_busi_record_process;
commit;

-- 旧业务系统逻辑
# insert into dw_base.ads_rpt_tjnd_busi_record_process
# (day_id, -- 数据日期
#  guar_id, -- 业务id
#  cust_name, -- 客户名称
#  full_name, -- 合作银行
#  cert_num, -- 证件号码
#  main_type, -- 主体类型
#  cust_type, -- 客户性质
#  gnd_indus_class, -- 行业归类
#  area, -- 经营区域
#  apply_amt, -- 申请金额（万元）
#  apply_term, -- 申请期限
#  approval_total, -- 审批金额（万元）
#  is_guar_due, -- 是否展期/延期
#  guar_due_date, -- 展期/延期到期日
#  bank_proj_mgr_name, -- 银行客户经理
#  nd_proj_mgr_name, -- 农担项目经理
#  protocol_name, -- 协议名称
#  prod_mode, -- 产品体系
#  prod_name, -- 产品
#  first_instance_result, -- 预审结果
#  data_source, -- 数据来源
#  guar_status, -- 业务状态
#  apply_date, -- 申请日期
#  guar_hand_days -- 在保业务办理天数（按照每个业务状态停留时间计算）
# )
# select '${v_sdate}'                                       as day_id,
#        t1.id                                              as guar_id,
#        cust_name,
#        full_bank,
#        cert_num,
#        case
#            when main_type = '1' then '家庭农场（种养大户）'
#            when main_type = '2' then '家庭农场'
#            when main_type = '3' then '农民专业合作社'
#            when main_type = '4' then '农业企业'
#            end                                            as main_type,
#        case
#            when cust_type = 'enterprise' then '企业'
#            when cust_type = 'person' then '个人'
#            end                                            as cust_type,
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
#            end                                            as gnd_indus_class,
#        JSON_UNQUOTE(JSON_EXTRACT(area, '$[1]'))           as area,
#        apply_amt / 10000                                  as apply_amt,
#        apply_term,
#        approval_total / 10000                             as approval_total,
#        if(t5.F_ID is not null, '是', '否')                  as is_guar_due,
#        date_format(guar_due_date, '%Y-%m-%d')             as guar_due_date,
#        bank_proj_mgr_name,
#        nd_proj_mgr_name,
#        protocol_name,
#        prod_mode,
#        prod_name,
#        case
#            when first_instance_result = '1' then '通过'
#            when first_instance_result = '2' then '不通过'
#            when first_instance_result = '3' then '警示'
#            end                                            as first_instance_result,
#        if(data_source = '4', '银行接口', null)                as data_source,
#        case
#            when guar_status = 'GT' then '在保'
#            when guar_status = 'ED' then '解保'
#            end                                            as guar_status,
#        date_format(apply_date, '%Y-%m-%d')                as apply_date,
#        case
#            when guar_status in ('GT', 'ED') then timestampdiff(day, apply_date, in_guar_date)
#            else timestampdiff(day, apply_date, now()) end as guar_hand_days
# from (select ID,                                             -- 业务id
#              CUSTOMER_NAME         as cust_name,             -- 客户姓名
#              ID_NUMBER             as cert_num,              -- 证件号码
#              CUSTOMER_NATURE       as cust_type,             -- 客户性质
#              APPLICATION_AMOUNT    as apply_amt,             -- 申请金额
#              BANK_PROJECT_MANAGER  as bank_proj_mgr_name,    -- 银行客户经理
#              BUSINESS_SP_USER_NAME as nd_proj_mgr_name,      -- 农担项目经理姓名
#              BUSI_MODE_NAME        as prod_mode,             -- 业务模式名称
#              RESULT                as first_instance_result, -- 数字风控审批结果
#              DATA_SOURCE           as data_source,           -- 数据来源
#              GUR_STATE             as guar_status,           -- 担保状态
#              CREATED_TIME          as apply_date,            -- 创建日期
#              -- 用于关联字段
#              PRODUCT_GRADE,                                  -- 产品编码
#              ID_CUSTOMER,                                    -- 客户id
#              RELATED_AGREEMENT_ID                            -- 关联协议id
#       from dw_nd.ods_tjnd_yw_afg_business_infomation
#      ) t1
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,         -- 业务id
#                 FULL_BANK_NAME as full_bank,     -- 合作银行全称
#                 APPLY_TERM     as apply_term,    -- 申请期限
#                 APPROVAL_TOTAL as approval_total -- 本次审批金额
#          from dw_nd.ods_tjnd_yw_afg_business_approval
#      ) t2
#      on t1.ID = t2.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID,                                           -- 客户id
#                 MAINBODY_TYPE_CORP        as main_type,       -- 主体类型
#                 INDUSTRY_CATEGORY_COMPANY as gnd_indus_class, -- 行业分类(公司)
#                 AREA                      as area             -- 区域
#          from dw_nd.ods_tjnd_yw_base_customers_history
#      ) t3 on t1.ID_CUSTOMER = t3.ID
#          left join
#      (
#          select fieldcode,                -- 产品编码
#                 product_name as prod_name -- 产品名称
#          from dw_nd.ods_tjnd_yw_base_product_management
#      ) t4 on t1.PRODUCT_GRADE = t4.fieldcode
#          left join
#      (
#          select f_id,                              -- 业务id
#                 max(GUR_DUE_DATE) as guar_due_date -- 担保到期日(展期/延期)
#          from dw_nd.ods_tjnd_yw_afg_survey
#          where OVER_TAG = 'BJ'
#            and DELETE_FLAG = '1'
#          group by F_ID
#      ) t5 on t1.id = t5.F_ID
#          left join
#      (
#          select ID,           -- 协议id
#                 protocol_name -- 协议名称
#          from dw_nd.ods_tjnd_yw_base_cooperative_institution_agreement
#      ) t6 on t1.RELATED_AGREEMENT_ID = t6.ID
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,          -- 业务id
#                 min(CREATED_TIME) as in_guar_date -- 计入在保日期
#          from dw_nd.ods_tjnd_yw_afg_voucher_infomation
#          where DELETE_FLAG = 1
#          group by ID_BUSINESS_INFORMATION
#      ) t7 on t1.id = t7.ID_BUSINESS_INFORMATION;
# commit;


-- ----------------------------------------
-- 新业务系统逻辑
insert into dw_base.ads_rpt_tjnd_busi_record_process
(day_id, -- 数据日期
 guar_id, -- 业务id
 cust_name, -- 客户名称
 full_name, -- 合作银行
 cert_num, -- 证件号码
 main_type, -- 主体类型
 cust_type, -- 客户性质
 gnd_indus_class, -- 行业归类
 area, -- 经营区域
 apply_amt, -- 申请金额（万元）
 apply_term, -- 申请期限
 approval_total, -- 审批金额（万元）
 is_guar_due, -- 是否展期/延期
 guar_due_date, -- 展期/延期到期日
 bank_proj_mgr_name, -- 银行客户经理
 nd_proj_mgr_name, -- 农担项目经理
 protocol_name, -- 协议名称
 prod_mode, -- 产品体系
 prod_name, -- 产品
 first_instance_result, -- 预审结果
 data_source, -- 数据来源
 guar_status, -- 业务状态
 apply_date, -- 申请日期
 guar_hand_days -- 在保业务办理天数（按照每个业务状态停留时间计算）
)
select '${v_sdate}' as day_id,
       guar_id,
       cust_name,
       full_name,
       cert_num,
       main_type,
       cust_type,
       gnd_indus_class,
       area,
       apply_amt,
       apply_term,
       approval_total,
       is_guar_due,
       guar_due_date,
       bank_proj_mgr_name,
       nd_proj_mgr_name,
       null         as protocol_name,
       null         as prod_mode,
       prod_name,
       first_instance_result,
       null         as data_source,
       guar_status,
       apply_date,
       guar_hand_days

from (
         select guar_id                                                  as guar_id,            -- 业务编号
                cust_name                                                as cust_name,          -- 客户名称
                loan_bank                                                as full_name,          -- 贷款银行
                cert_no                                                  as cert_num,           -- 身份证号
                cust_class                                               as main_type,          -- 客户类型
                cust_type                                                as cust_type,          -- 客户类型
                guar_class                                               as gnd_indus_class,    -- 国担分类
                county_name                                              as area,               -- 区县
                appl_amt                                                 as apply_amt,          -- 申报金额(万元)
                aprv_amt                                                 as approval_total,     -- 批复金额
                case when guar_id like '%FXHJ%' then '是' else '否' end    as is_guar_due,        -- 是否展期/延期
                case when guar_id like '%FXHJ%' then loan_reg_dt end     as guar_due_date,      -- 展期/延期日期
                bank_mgr                                                 as bank_proj_mgr_name, -- 银行客户经理
                guar_prod                                                as prod_name,          -- 担保产品
                item_stt                                                 as guar_status,        -- 项目状态
                accept_dt                                                as apply_date,         -- 受理时间
                case
                    when item_stt in ('已解保', '已放款', '已代偿') then timestampdiff(day, accept_dt, loan_reg_dt)
                    else timestampdiff(day, accept_dt, '${v_sdate}') end as guar_hand_days      -- 在保业务办理天数
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
     ) t1
         left join
     (
         select code,                                                                     -- 业务编号
                apply_period                                    as apply_term,            -- 申保期限
                create_name                                     as nd_proj_mgr_name,      -- 创建者
                case
                    when pre_trial_result = '1' then '通过'
                    when pre_trial_result = '-1' then '不通过' end as first_instance_result, -- 预审结果
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main) t1
         where rn = 1
     ) t2 on t1.guar_id = t2.code;

commit;