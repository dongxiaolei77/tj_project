-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250328
-- 目标表   ：dw_base.ads_rpt_tjnd_finance_compt_manage  财务部-代偿管理
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_bh_compensatory               代偿表
--          dw_nd.ods_tjnd_yw_base_product_management       BO,产品管理,NEW
--          dw_nd.ods_tjnd_yw_base_enterprise               部门表
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 重跑策略
truncate table dw_base.ads_rpt_tjnd_finance_compt_manage;
commit;
-- 旧业务系统逻辑
insert into dw_base.ads_rpt_tjnd_finance_compt_manage
(day_id, -- 数据日期
 loan_cont_no, -- 担保合同编号
 cust_name, -- 客户名称
 cert_num, -- 证件号码
 compt_apply_date, -- 代偿申请日
 compt_total, -- 代偿总额
 compt_principal, -- 代偿本金
 compt_interest, -- 代偿利息
 proposed_way_of_recovery, -- 拟追偿方式
 payment_date, -- 打款时间
 rimit_bank_account, -- 打款银行账户
 handler, -- 经办人
 handle_time, -- 经办时间
 related_item_no, -- 关联项目编号
 product_name, -- 产品一级
 enter_full_name, -- 合作银行
 bank_outlets, -- 银行网点
 amt_insured, -- 核保金额(元)
 on_balance, -- 在保余额(元)
 guar_start_date, -- 担保开始日期
 guar_end_date, -- 担保到期日期
 level_five, -- 五级分类
 warning_class, -- 四级分类
 bank_mgr, -- 银行客户经理
 tel, -- 联系方式
 over_tag -- 流程状态
)
select '${v_sdate}'                              as day_id,
       loan_cont_no,
       cust_name,
       cert_num,
       date_format(compt_apply_date, '%Y-%m-%d') as compt_apply_date,
       compt_total,
       compt_principal,
       compt_interest,
       proposed_way_of_recovery,
       payment_date,
       rimit_bank_account,
       t4.username                               as handler,
       handle_time,
       related_item_no,
       product_name,
       enterfullname                             as enter_full_name,
       bank_outlets,
       amt_insured,
       on_balance,
       date_format(guar_start_date, '%Y-%m-%d')  as guar_start_date,
       date_format(guar_end_date, '%Y-%m-%d')    as guar_end_date,
       level_five,
       warning_class,
       bank_mgr,
       tel,
       if(over_tag = 'BJ', '代偿申请结束', '代偿申请审批中')  as over_tag
from (
         select RELATED_CONTRACT_NO            as loan_cont_no,             -- 关联合同编号
                CUSTOMER_NAME                  as cust_name,                -- 客户名称
                ID_NO                          as cert_num,                 -- 证件号码
                COMPENSTATION_APPLICATION_DATE as compt_apply_date,         -- 代偿申请日
                TOTAL_COMPENSATION             as compt_total,              -- 代偿总额
                COMPENSATORY_PRINCIPAL         as compt_principal,          -- 代偿本金
                COMPENSATORY_INTEREST          as compt_interest,           -- 代偿利息
                PROPOSED_WAY_OF_RECOVERY       as proposed_way_of_recovery, -- 拟追偿方式
                PAYMENT_DATE                   as payment_date,             -- 打款时间
                REMIT_BANK_ACCOUNT             as rimit_bank_account,       -- 打款银行账户
                HANDLER                        as handler,                  -- 经办人id
                HANDLE_TIME                    as handle_time,              -- 经办时间
                RELATED_ITEM_NO                as related_item_no,          -- 关联项目编号
                BANK_OUTLETS                   as bank_outlets,             -- 银行网点
                AMOUNT_INSURED                 as amt_insured,              -- 核保金额(元)
                ON_BALANCE                     as on_balance,               -- 在保余额(元)
                CONTRACR_START_DATE            as guar_start_date,          -- 担保开始日期
                CONTRACR_END_DATE              as guar_end_date,            -- 担保到期日期
                LEVEL_FIVE                     as level_five,               -- 五级分类
                WARNING_CLASS                  as warning_class,            -- 四级分类
                BANK_ACC_MANAGER               as bank_mgr,                 -- 银行客户经理
                TEL                            as tel,                      -- 联系方式
                OVER_TAG                       as over_tag,                 -- 流程状态
                PRODUCT_GRADE_FIRST,                                        -- 产品编码
                THREE_LEVEL_BRANCH                                          -- 银行编码
         from dw_nd.ods_tjnd_yw_bh_compensatory
     ) t1
         left join
     (
         select fieldcode,   -- 产品编码
                PRODUCT_NAME -- 产品名称
         from dw_nd.ods_tjnd_yw_base_product_management
     ) t2 on t1.PRODUCT_GRADE_FIRST = t2.fieldcode
         left join
     (
         select fieldcode,    -- 银行编码
                enterfullname -- 银行名称
         from dw_nd.ods_tjnd_yw_base_enterprise
     ) t3 on t1.THREE_LEVEL_BRANCH = t3.fieldcode
         left join
     (
         select userid,  -- 经办人id
                username -- 经办人姓名
         from dw_nd.ods_tjnd_yw_base_operator
     ) t4 on t1.handler = t4.userid;
commit;


-- --------------------------------------
-- 新业务系统逻辑
insert into dw_base.ads_rpt_tjnd_finance_compt_manage
(day_id, -- 数据日期
 loan_cont_no, -- 担保合同编号
 cust_name, -- 客户名称
 cert_num, -- 证件号码
 compt_apply_date, -- 代偿申请日
 compt_total, -- 代偿总额
 compt_principal, -- 代偿本金
 compt_interest, -- 代偿利息
 proposed_way_of_recovery, -- 拟追偿方式
 payment_date, -- 打款时间
 rimit_bank_account, -- 打款银行账户
 handler, -- 经办人
 handle_time, -- 经办时间
 related_item_no, -- 关联项目编号
 product_name, -- 产品一级
 enter_full_name, -- 合作银行
 bank_outlets, -- 银行网点
 amt_insured, -- 核保金额(元)
 on_balance, -- 在保余额(元)
 guar_start_date, -- 担保开始日期
 guar_end_date, -- 担保到期日期
 level_five, -- 五级分类
 warning_class, -- 四级分类
 bank_mgr, -- 银行客户经理
 tel, -- 联系方式
 over_tag -- 流程状态
)
select '${v_sdate}' as day_id,
       loan_cont_no,
       cust_name,
       cert_num,
       compt_apply_date,
       compt_total,
       compt_principal,
       compt_interest,
       proposed_way_of_recovery,
       payment_date,
       rimit_bank_account,
       handler,
       handle_time,
       related_item_no,
       product_name,
       enter_full_name,
       null         as bank_outlets,
       null         as amt_insured,
       on_balance,
       guar_start_date,
       guar_end_date,
       level_five,
       null         as warning_class,
       bank_mgr,
       tel,
       over_tag
from (
         select id,                                         -- 代偿id
                project_id,                                 -- 项目id
                jk_contr_code          as loan_cont_no,     -- 借款合同编号
                cust_name              as cust_name,        -- 客户名称
                cust_identity_no       as cert_num,         -- 客户证件号码
                create_time            as compt_apply_date, -- 创建时间
                project_id             as related_item_no,  -- 项目id
                guar_product           as product_name,     -- 担保产品
                loans_bank             as enter_full_name,  -- 合作银行
                fk_start_date          as guar_start_date,  -- 贷款开始时间
                fk_end_date            as guar_end_date,    -- 贷款结束时间
                bank_cust_manager_name as bank_mgr,         -- 银行客户经理
                cust_mobile            as tel,              --  联系电话
                status                 as over_tag,         -- 代偿状态
                rn
         from (select *, row_number() over (partition by project_id order by db_update_time desc) as rn
               from dw_nd.ods_t_proj_comp_aply) t1
         where rn = 1
     ) t1
         left join
     (
         select comp_id,                                       -- 代偿id
                overdue_totl      as compt_total,              -- 截至拨付当日逾期金额（本息之和）
                overdue_pr        as compt_principal,          -- 逾期本金(元)
                overdue_int       as compt_interest,           -- 逾期利息(元)
                repay_type        as proposed_way_of_recovery, -- 付款方式
                act_disburse_date as payment_date,             -- 代偿款实际拨付日期
                pay_acct_bank     as rimit_bank_account,       -- 付款账号银行
                create_name       as handler,                  -- 创建者
                update_time       as handle_time,              -- 最后修改时间
                rn
         from (select *, row_number() over (partition by comp_id order by db_update_time desc) as rn
               from dw_nd.ods_t_proj_comp_appropriation) t1
         where rn = 1
     ) t2 on t1.id = t2.comp_id
         left join
     (
         select project_id,                        -- 项目id
                five_level_classify as level_five, -- 五级分类
                rn
         from (select *, row_number() over (partition by project_id order by db_update_time desc) as rn
               from dw_nd.ods_t_biz_proj_loan) t1
         where rn = 1
     ) t3 on t1.project_id = t3.project_id
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t4 on t1.project_id = t4.project_id
         left join
     (
         select guar_id,
                onguar_amt as on_balance -- 在保余额
         from dw_base.dwd_guar_info_onguar
         where day_id = '${v_sdate}'
     ) t5 on t4.guar_id = t5.guar_id;
commit;