-- ----------------------------------------
-- 开发人   : wangyj
-- 开发时间 ：20241218
-- 目标表   :dwd_tjnd_report_proj_base_info                     -- 项目基础信息表
-- 源表     ： dw_base.dwd_tjnd_yw_guar_info_all_qy             -- 迁移业务宽表
--            dw_base.dwd_nacga_report_guar_info_base_info      -- 国农担上报业务范围表
-- 备注     ：
-- 变更记录 ：
-- ----------------------------------------

delete
from dw_base.dwd_tjnd_report_proj_base_info
where day_id = '${v_sdate}';
commit;

-- 旧业务系统数据逻辑
insert into dw_base.dwd_tjnd_report_proj_base_info
( day_id -- 数据日期
, proj_no_prov -- 省农担担保项目编号
, cert_no -- 证件号码(用于映射cust_no_nacga)
, cust_name -- 项目主体名称
, cert_typ_cd -- 项目主体证件类型代码
, cust_cert_no -- 项目主体证件号码
, proj_rsue_cd -- 项目来源代码
, proj_typ_cd -- 项目类型代码
, proj_blogto_area_cd -- 项目所属区域代码
, proj_blogto_org_no -- 项目所属机构
, proj_main_typ_cd -- 项目主体类型代码
, proj_blog_busntp_no_nacga -- 项目所属行业代码（农担体系）
, proj_blog_busntp_prov_cd -- 项目所属行业（省农担）
, proj_nation_econ_cd -- 项目所属行业代码（国民经济分类）
, proj_fin_sup_typ_cd -- 资金支持品种
, proj_fin_sup_link_cd -- 资金支持环节
, proj_prod_name -- 担保产品名称
, is_frst_guar -- 是否首担
, is_policy_biz -- 是否政策性业务
, is_guar_upon_loan_apply -- 是否见贷即保
, is_comp_limit_rate -- 是否限率代偿
, limit_rate -- 限率
, fin_org_risk_share_ratio -- 金融机构分险比例
, gov_risk_share_ratio -- 政府分险比例
, other_risk_share_ratio -- 其他机构分险比例
, is_buy_ag_ins -- 是否购买农业保险
, subsidy_cls -- 补贴种类
, subsidy_amt -- 补贴金额
, core_corp_name -- 合作核心企业
, proj_stt_cd -- 项目状态代码
, count_guar_cls_cd -- 反担保方式代码
, on_guared_dt -- 计入在保日期
, proj_onguar_amt_totl -- 项目在保余额
, biz_scale -- 经营规模
, biz_year -- 经营年限
, biz_lcal_typ_cd -- 经营场地类型代码
, opr_income -- 营业收入
, opr_debts -- 经营性负债
, create_jobs_num -- 带动就业人数
, create_income_amt -- 带动农民增收金额
, biz_lcal_addr -- 经营详细地址
, apply_dt -- 申请日期
, apply_amt -- 项目申请金额
, apply_period -- 项目申请期限
, is_in_litigation -- 涉及司法诉讼
, is_in_judgment -- 涉及司法判决
, is_in_regulatory -- 涉及行政处罚
, aprv_dt -- 农担批复日期
, loan_cont_no -- 借款合同编号
, loan_begin_dt -- 借款合同生效日期
, loan_bank_no -- 签约金融机构代码
, loan_bank_br_name -- 签约金融机构（分支机构）
, loan_amt -- 借款合同额度
, loan_period -- 借款合同期限
, loan_cont_intr -- 借款合同利率
, is_self_renewal -- 是否为自主循环使用
, loan_repay_typ -- 借款合同还款方式代码
, guar_fee_rate -- 担保费率
, gtee_bank_no -- 保证合同金融机构代码
, gtee_agmt_no -- 保证合同编号
, gtee_scp_cd -- 保证合同保证范围代码
, gtee_expd_cd -- 保证合同保证期间代码
, gtee_mhd_cd -- 保证方式代码
, gtee_eff_dt -- 保证责任生效日期
, gtee_expr_dt -- 保证责任失效日期
, comp_duran -- 代偿宽限期
, comp_rmv_amt -- 项目核销金额
, comp_rmv_dt -- 项目核销日期
, gtee_cont_amt -- 保证合同金额
, ag_cnty_cd -- 农业大县代码
, core_corp_cert_no -- 合作核心企业统一社会信用代码
)
select '${v_sdate}'                                                 as day_id
     , a.GUARANTEE_CODE                                             as proj_no_prov              -- 省农担担保项目编号
     , a.ID_NUMBER                                                  as cert_no                   -- 证件号码(用于映射cust_no_nacga)
     , a.CUSTOMER_NAME                                              as cust_name                 -- 项目主体名称
     , a.CERT_TYPE                                                  as cert_typ_cd               -- 项目主体证件类型代码，待映射
     , a.ID_NUMBER                                                  as cust_cert_no              -- 项目主体证件号码
     , c.ITEM_SOURCE                                                as proj_rsue_cd              -- 项目来源代码，待补充
     , c.ITEM_TYPE                                                  as proj_typ_cd               -- 项目类型代码，待补充
     , JSON_UNQUOTE(JSON_EXTRACT(a.area, '$[1]'))                     as proj_blogto_area_cd       -- 项目所属区域代码
     , a.enter_code                                                 as proj_blogto_org_no        -- 项目所属机构，待映射
     , a.MAINBODY_TYPE_CORP                                         as proj_main_typ_cd          -- 项目主体类型代码，待映射
     , INDUSTRY_CATEGORY_COMPANY                                    as proj_blog_busntp_no_nacga -- 项目所属行业代码（农担体系），待映射
     , INDUSTRY_CATEGORY_COMPANY                                    as proj_blog_busntp_prov_cd  -- 项目所属行业（省农担）
     , JSON_UNQUOTE(JSON_EXTRACT(INDUSTRY_CATEGORY_NATION, '$[3]')) as proj_nation_econ_cd       -- 项目所属行业代码（国民经济分类），待映射
     , c.SUPPLY_TYPE                                                as proj_fin_sup_typ_cd       -- 资金支持品种，待补充
     , c.SUPPLY_PHASE                                               as proj_fin_sup_link_cd      -- 资金支持环节，待补充
     , PRODUCT_NAME                                                 as proj_prod_name            -- 担保产品名称
     , c.FIRST_GUARANTEE                                            as is_frst_guar              -- 是否首担
     , case
           when a.approval_total between 10 and 300 then '1'
           else '0'
    end                                                             as is_policy_biz             -- 是否政策性业务
     , case
           when a.BUSI_MODE_NAME = '见贷即保' then '1'
           else '0'
    end                                                             as is_guar_upon_loan_apply   -- 是否见贷即保
     , c.IS_LIMITED_RATE_COMPENSATION                               as is_comp_limit_rate        -- 是否限率代偿，待补充
     , if(c.IS_LIMITED_RATE_COMPENSATION=1,0.03,null)               as limit_rate                -- 限率
     , bank_cale_rate                                               as fin_org_risk_share_ratio  -- 金融机构分险比例
     , gov_cale_rate                                                as gov_risk_share_ratio      -- 政府分险比例
     , coop_cale_rate                                               as other_risk_share_ratio    -- 其他机构分险比例
     , null                                                         as is_buy_ag_ins             -- 是否购买农业保险，非必填
     , null                                                         as subsidy_cls               -- 补贴种类，非必填
     , null                                                         as subsidy_amt               -- 补贴金额，非必填 需除以10000
     , null                                                         as core_corp_name            -- 合作核心企业，非必填
     , a.GUR_STATE                                                  as proj_stt_cd               -- 项目状态代码，待映射
     , a.COUNTER_GUR_METHOD                                           as count_guar_cls_cd         -- 反担保方式代码，待映射
     , date_format(lend_reg_dt, '%Y-%m-%d')                         as on_guared_dt              -- 计入在保日期
     , a.GT_AMOUNT / 10000                                          as proj_onguar_amt_totl      -- 项目在保余额
     , null                                                         as biz_scale                 -- 经营规模
     , null                                                         as biz_year                  -- 经营年限，非必填
     , null                                                         as biz_lcal_typ_cd           -- 经营场地类型代码，非必填
     , BUSINESS_REVENUE / 10000                                     as opr_income                -- 营业收入，非必填 需除以10000
     , OPERATION_LOAN / 10000                                       as opr_debts                 -- 经营性负债
     , null                                                         as create_jobs_num           -- 带动就业人数，非必填
     , null                                                         as create_income_amt         -- 带动农民增收金额，非必填 需除以10000
     , OFFICE_ADDRESS                                               as biz_lcal_addr             -- 经营详细地址
     , date_format(apply_time, '%Y-%m-%d')                          as apply_dt                  -- 申请日期
     , a.APPLICATION_AMOUNT / 10000                                 as apply_amt                 -- 项目申请金额
     , cast(a.term as signed integer)                               as apply_period              -- 项目申请期限
     , null                                                         as is_in_litigation          -- 涉及司法诉讼，已去除
     , null                                                         as is_in_judgment            -- 涉及司法判决，已去除
     , null                                                         as is_in_regulatory          -- 涉及行政处罚，已去除
     , date_format(c.RECEIPT_DATE, '%Y-%m-%d')                         as aprv_dt                   -- 农担批复日期
     , a.LOAN_CONTRACT_NO                                           as loan_cont_no              -- 借款合同编号
     , a.CONTRACR_START_DATE                                        as loan_begin_dt             -- 借款合同生效日期
     , a.COOPERATIVE_BANK_FIRST                                     as loan_bank_no              -- 签约金融机构代码，待映射
     , a.FULL_BANK_NAME                                             as loan_bank_br_name         -- 签约金融机构（分支机构）
     , a.LOAN_CONTRACT_AMOUNT / 10000                               as loan_amt                  -- 借款合同额度
     , cast(a.GUARANTEE_PERIOD as signed integer)                   as loan_period               -- 借款合同期限
     , a.YEAR_LOAN_RATE                                             as loan_cont_intr            -- 借款合同利率
     , c.IS_AUTO_REVOLVING_LOAN                                     as is_self_renewal           -- 是否为自主循环使用，待补充
     , REPAYMENT_WAY                                                as loan_repay_typ            -- 借款合同还款方式代码
     , a.GUARANTEE_TATE                                             as guar_fee_rate             -- 担保费率
     , a.COOPERATIVE_BANK_FIRST                                     as gtee_bank_no              -- 保证合同金融机构代码，待映射
     , a.GUARANTY_CONTRACT_NO                                       as gtee_agmt_no              -- 保证合同编号
     , d.GUARANTEE_RANGE                                            as gtee_scp_cd               -- 保证合同保证范围代码，待补充
     , d.GUARANTEE_TIME_SLOT                                        as gtee_expd_cd              -- 保证合同保证期间代码，待补充
     , d.GUARANTEE_WAY                                              as gtee_mhd_cd               -- 保证方式代码，待补充
     , d.GUARANTEE_START_DATE                                       as gtee_eff_dt               -- 保证责任生效日期，待补充
     , d.GUARANTEE_END_DATE                                         as gtee_expr_dt              -- 保证责任失效日期，待补充
     , cast(COMPENSATION_PERIOD  as SIGNED)                         as comp_duran                -- 代偿宽限期
     , null                                                         as comp_rmv_amt              -- 项目核销金额，非必填
     , null                                                         as comp_rmv_dt               -- 项目核销日期，非必填
     , GUARANTEE_CONTRACT_AMOUNT / 10000                            as gtee_cont_amt             -- 保证合同金额，待补充 需除以10000
     , '999999'                                                     as ag_cnty_cd                -- 农业大县代码，不涉及
     , null                                                         as core_corp_cert_no         -- 合作核心企业统一社会信用代码，非必填
from dw_base.dwd_tjnd_yw_guar_info_all_qy a
         inner join dw_base.dwd_nacga_report_guar_info_base_info b
                    on a.guarantee_code = b.biz_no
         inner join dw_nd.ods_tjnd_yw_z_report_afg_business_infomation c on a.id_business_information = c.id
         inner join dw_nd.ods_tjnd_yw_z_report_afg_business_approval d
                    on a.id_business_information = d.ID_BUSINESS_INFORMATION
where a.day_id = '${v_sdate}'
  and b.day_id = '${v_sdate}';