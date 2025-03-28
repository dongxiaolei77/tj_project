-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250328
-- 目标表   ：dw_base.ads_rpt_compt_manage 代偿管理
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_bh_compensatory               代偿表
--          dw_nd.ods_tjnd_yw_base_product_management       BO,产品管理,NEW
--          dw_nd.ods_tjnd_yw_base_enterprise               部门表
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 旧业务系统逻辑
select loan_cont_no,
       cust_name,
       cert_num,
       compt_apply_date,
       compt_total,
       compt_principal,
       compt_interest,
       proposed_way_of_recovery,
       payment_date,
       rimit_bank_account,
       t4.username,
       handle_time,
       related_item_no,
       product_name,
       enterfullname                            as enter_full_name,
       bank_outlets,
       amt_insured / 10000                      as amt_insured,
       on_balance / 10000                       as on_balance,
       guar_start_date,
       guar_end_date,
       level_five,
       warning_class,
       bank_mgr,
       tel,
       if(over_tag = 'BJ', '代偿申请结束', '代偿申请审批中') as over_tag
from (
         select RELATED_CONTRACT_NO            as loan_cont_no,
                CUSTOMER_NAME                  as cust_name,
                ID_NO                          as cert_num,
                COMPENSTATION_APPLICATION_DATE as compt_apply_date,
                TOTAL_COMPENSATION             as compt_total,
                COMPENSATORY_PRINCIPAL         as compt_principal,
                COMPENSATORY_INTEREST          as compt_interest,
                PROPOSED_WAY_OF_RECOVERY       as proposed_way_of_recovery,
                PAYMENT_DATE                   as payment_date,
                REMIT_BANK_ACCOUNT             as rimit_bank_account,
                HANDLER                        as handler,
                HANDLE_TIME                    as handle_time,
                RELATED_ITEM_NO                as related_item_no,
                BANK_OUTLETS                   as bank_outlets,
                AMOUNT_INSURED                 as amt_insured,
                ON_BALANCE                     as on_balance,
                CONTRACR_START_DATE            as guar_start_date,
                CONTRACR_END_DATE              as guar_end_date,
                LEVEL_FIVE                     as level_five,
                WARNING_CLASS                  as warning_class,
                BANK_ACC_MANAGER               as bank_mgr,
                TEL                            as tel,
                OVER_TAG                       as over_tag,
                PRODUCT_GRADE_FIRST,
                THREE_LEVEL_BRANCH
         from dw_nd.ods_tjnd_yw_bh_compensatory
     ) t1
         left join
     (
         select fieldcode,
                PRODUCT_NAME
         from dw_nd.ods_tjnd_yw_base_product_management
     ) t2 on t1.PRODUCT_GRADE_FIRST = t2.fieldcode
         left join
     (
         select fieldcode,
                enterfullname
         from dw_nd.ods_tjnd_yw_base_enterprise
     ) t3 on t1.THREE_LEVEL_BRANCH = t3.fieldcode
         left join
     (
         select userid,
                username
         from dw_nd.ods_tjnd_yw_base_operator
     ) t4 on t1.handler = t4.userid;