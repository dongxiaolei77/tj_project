-- 旧业务系统部分
-- ----------------------------------------
-- 开发人   : wangyj
-- 开发时间 ：20241218
-- 目标表   :dwd_tjnd_report_proj_base_info                     -- 项目基础信息表
-- 源表     ： dw_base.dwd_tjnd_yw_guar_info_all_qy             -- 迁移业务宽表
--            dw_base.dwd_nacga_report_guar_info_base_info      -- 国农担上报业务范围表
-- 备注     ：
-- 变更记录 ：
-- ----------------------------------------

-- 新业务系统部分
-- ----------------------------------------
-- 开发人   : WangYX
-- 开发时间 ：20240831
-- 目标表   ：dw_base.dwd_tjnd_report_proj_base_info       项目基础信息表
-- 源表     ：
--            dw_nd.ods_t_biz_project_main           进件业务信息表
--            dw_nd.ods_t_biz_proj_xz                续支业务信息表
--            dw_nd.ods_t_risk_check_opinion         风险审查意见表
--            dw_nd.ods_t_risk_group_opinion         小组意见表
--            dw_nd.ods_t_risk_officer_opinion       风险部负责人意见表
--            dw_nd.ods_t_jury_group_opinion         评审委员会表
--            dw_nd.ods_t_jury_summary_opinion       评审意见汇总表
--            dw_base.dwd_guar_info_all              业务信息宽表--项目域
--            dw_base.dwd_guar_info_stat             业务信息宽表--项目域
--            dw_base.dwd_guar_tag                   累保业务标签表--可判断是否首保
--            dw_base.dwd_tjnd_report_biz_no_base    上报业务基础表，关联取所有需上报业务
--            dw_nd.ods_bizhall_guar_apply           业务大厅申请表
--            dw_nd.ods_bizhall_guar_online_biz      标准化线上业务台账表
--            dw_nd.ods_comm_cont_comm_contract_info 电子签章合同信息表
--            dw_base.dwd_tjnd_report_biz_loan_bank  国担数据上报银行信息表
--            dw_nd.ods_t_biz_proj_sign              项目签约信息表
--            dw_nd.ods_t_biz_proj_appr              项目批复信息表
--            dw_nd.ods_t_biz_proj_loan              项目放款信息表
--            dw_nd.ods_cem_dictionaries             企业-产业集群关系
--            dw_nd.ods_cem_company_base             核心企业基本表
--            dw_base.dwd_tjnd_report_proj_rk_wrn_info     国担上报-风险预警记录表
--            dw_base.dwd_tjnd_report_proj_ovd_info        国担上报-逾期记录表
--            dw_nd.ods_nacga_report_prov_nacga_code_dict
--            dw_nd.ods_nacga_report_prov_nacga_code_mapping
--
-- 备注     ：
-- 变更记录 ：20241209 分支机构代码加工逻辑变更
--          20241210 只上报指标表上报的合作核心企业，修改计入在保日期为放款登记日期
--          20250228 脚本的统一变更，TDS转MySQL8.0 zhangfl
--          20250512 分支机构编码逻辑变更 wangyj
-- ----------------------------------------

-- 重跑逻辑
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
, dict_flag
, is_credit_auth -- 是否已授权征信上报
, is_comp_notice_credit -- 是否已通知上报代偿信息
, is_direct_guar -- 是否直接承担担保责任
, is_coop_cd -- 项目合作情况代码
, ovd_prin_rmv_bank_rk_seg_bal_3 -- 逾期三个月未代偿余额（扣除银行分险）
, other_ovd_rmv_bank_rk_seg_bal_3 -- 逾期三个月利息以及其他费用金额余额（扣除银行分险）
, comp_fst_comp_ntc_dt -- 首次代偿通知日期
)
select '${v_sdate}'                                                 as day_id
     , a.GUARANTEE_CODE                                             as proj_no_prov                    -- 省农担担保项目编号
     , a.ID_NUMBER                                                  as cert_no                         -- 证件号码(用于映射cust_no_nacga)
     , a.CUSTOMER_NAME                                              as cust_name                       -- 项目主体名称
     , a.CERT_TYPE                                                  as cert_typ_cd                     -- 项目主体证件类型代码，待映射
     , a.ID_NUMBER                                                  as cust_cert_no                    -- 项目主体证件号码
     , c.ITEM_SOURCE                                                as proj_rsue_cd                    -- 项目来源代码，待补充
     , c.ITEM_TYPE                                                  as proj_typ_cd                     -- 项目类型代码，待补充
     , JSON_UNQUOTE(JSON_EXTRACT(a.area, '$[1]'))                   as proj_blogto_area_cd             -- 项目所属区域代码
     , a.enter_code                                                 as proj_blogto_org_no              -- 项目所属机构，待映射
     , a.MAINBODY_TYPE_CORP                                         as proj_main_typ_cd                -- 项目主体类型代码，待映射
     , INDUSTRY_CATEGORY_COMPANY                                    as proj_blog_busntp_no_nacga       -- 项目所属行业代码（农担体系），待映射
     , INDUSTRY_CATEGORY_COMPANY                                    as proj_blog_busntp_prov_cd        -- 项目所属行业（省农担）
     , JSON_UNQUOTE(JSON_EXTRACT(INDUSTRY_CATEGORY_NATION, '$[3]')) as proj_nation_econ_cd             -- 项目所属行业代码（国民经济分类），待映射
     , c.SUPPLY_TYPE                                                as proj_fin_sup_typ_cd             -- 资金支持品种，待补充
     , c.SUPPLY_PHASE                                               as proj_fin_sup_link_cd            -- 资金支持环节，待补充
     , PRODUCT_NAME                                                 as proj_prod_name                  -- 担保产品名称
     , c.FIRST_GUARANTEE                                            as is_frst_guar                    -- 是否首担
     , case
           when a.approval_total / 10000 between 10 and 300 then '1'
           else '0'
    end                                                             as is_policy_biz                   -- 是否政策性业务
#      , case when a.BUSI_MODE_NAME = '见贷即保' then '1' else '0' end    as is_guar_upon_loan_apply   -- 是否见贷即保
     , '0'                                                          as is_guar_upon_loan_apply         -- 是否见贷即保 20250623 dxl
     , c.IS_LIMITED_RATE_COMPENSATION                               as is_comp_limit_rate              -- 是否限率代偿，待补充
     , if(c.IS_LIMITED_RATE_COMPENSATION = 1, 0.03, null)           as limit_rate                      -- 限率
     , bank_cale_rate                                               as fin_org_risk_share_ratio        -- 金融机构分险比例
     , gov_cale_rate                                                as gov_risk_share_ratio            -- 政府分险比例
     , coop_cale_rate                                               as other_risk_share_ratio          -- 其他机构分险比例
     , null                                                         as is_buy_ag_ins                   -- 是否购买农业保险，非必填
     , null                                                         as subsidy_cls                     -- 补贴种类，非必填
     , null                                                         as subsidy_amt                     -- 补贴金额，非必填 需除以10000
     , null                                                         as core_corp_name                  -- 合作核心企业，非必填
     , a.GUR_STATE                                                  as proj_stt_cd                     -- 项目状态代码，待映射
     , a.COUNTER_GUR_METHOD                                         as count_guar_cls_cd               -- 反担保方式代码，待映射
     , date_format(lend_reg_dt, '%Y-%m-%d')                         as on_guared_dt                    -- 计入在保日期
     , a.GT_AMOUNT / 10000                                          as proj_onguar_amt_totl            -- 项目在保余额
     , null                                                         as biz_scale                       -- 经营规模
     , null                                                         as biz_year                        -- 经营年限，非必填
     , null                                                         as biz_lcal_typ_cd                 -- 经营场地类型代码，非必填
     , BUSINESS_REVENUE / 10000                                     as opr_income                      -- 营业收入，非必填 需除以10000
     , OPERATION_LOAN / 10000                                       as opr_debts                       -- 经营性负债
     , null                                                         as create_jobs_num                 -- 带动就业人数，非必填
     , null                                                         as create_income_amt               -- 带动农民增收金额，非必填 需除以10000
     , OFFICE_ADDRESS                                               as biz_lcal_addr                   -- 经营详细地址
     , date_format(apply_time, '%Y-%m-%d')                          as apply_dt                        -- 申请日期
     , a.APPLICATION_AMOUNT / 10000                                 as apply_amt                       -- 项目申请金额
     , cast(a.term as signed integer)                               as apply_period                    -- 项目申请期限
     , null                                                         as is_in_litigation                -- 涉及司法诉讼，已去除
     , null                                                         as is_in_judgment                  -- 涉及司法判决，已去除
     , null                                                         as is_in_regulatory                -- 涉及行政处罚，已去除
     , date_format(c.RECEIPT_DATE, '%Y-%m-%d')                      as aprv_dt                         -- 农担批复日期
     , a.LOAN_CONTRACT_NO                                           as loan_cont_no                    -- 借款合同编号
     , a.CONTRACR_START_DATE                                        as loan_begin_dt                   -- 借款合同生效日期
     , a.COOPERATIVE_BANK_FIRST                                     as loan_bank_no                    -- 签约金融机构代码，待映射
     , a.FULL_BANK_NAME                                             as loan_bank_br_name               -- 签约金融机构（分支机构）
     , a.LOAN_CONTRACT_AMOUNT / 10000                               as loan_amt                        -- 借款合同额度
     , cast(a.GUARANTEE_PERIOD as signed integer)                   as loan_period                     -- 借款合同期限
     , a.YEAR_LOAN_RATE                                             as loan_cont_intr                  -- 借款合同利率
     , c.IS_AUTO_REVOLVING_LOAN                                     as is_self_renewal                 -- 是否为自主循环使用，待补充
     , REPAYMENT_WAY                                                as loan_repay_typ                  -- 借款合同还款方式代码
     , a.GUARANTEE_TATE                                             as guar_fee_rate                   -- 担保费率
     , a.COOPERATIVE_BANK_FIRST                                     as gtee_bank_no                    -- 保证合同金融机构代码，待映射
     , a.GUARANTY_CONTRACT_NO                                       as gtee_agmt_no                    -- 保证合同编号
     , d.GUARANTEE_RANGE                                            as gtee_scp_cd                     -- 保证合同保证范围代码，待补充
     , d.GUARANTEE_TIME_SLOT                                        as gtee_expd_cd                    -- 保证合同保证期间代码，待补充
     , d.GUARANTEE_WAY                                              as gtee_mhd_cd                     -- 保证方式代码，待补充
     , d.GUARANTEE_START_DATE                                       as gtee_eff_dt                     -- 保证责任生效日期，待补充
     , d.GUARANTEE_END_DATE                                         as gtee_expr_dt                    -- 保证责任失效日期，待补充
     , cast(COMPENSATION_PERIOD as signed)                          as comp_duran                      -- 代偿宽限期
     , null                                                         as comp_rmv_amt                    -- 项目核销金额，非必填
     , null                                                         as comp_rmv_dt                     -- 项目核销日期，非必填
     , GUARANTEE_CONTRACT_AMOUNT / 10000                            as gtee_cont_amt                   -- 保证合同金额，待补充 需除以10000
     , '999999'                                                     as ag_cnty_cd                      -- 农业大县代码，不涉及
     , null                                                         as core_corp_cert_no               -- 合作核心企业统一社会信用代码，非必填
     , 0                                                            as dict_flag
     , null                                                         as is_credit_auth                  -- 是否已授权征信上报
     , null                                                         as is_comp_notice_credit           -- 是否已通知上报代偿信息
     , '1'                                                          as is_direct_guar                  -- 是否直接承担担保责任
     , '00'                                                         as is_coop_cd                      -- 项目合作情况代码
     , '0'                                                          as OVD_RMV_BANK_RK_SEG_BAL_3       -- 逾期三个月未代偿余额（扣除银行分险）
     , '0'                                                          as other_ovd_rmv_bank_rk_seg_bal_3 -- 逾期三个月利息以及其他费用金额余额（扣除银行分险）
     , date_format(t2.compenstation_application_date, '%Y-%m-%d')   as COMP_FST_COMP_NTC_DT            -- 首次代偿通知日期
from dw_base.dwd_tjnd_yw_guar_info_all_qy a
         inner join dw_base.dwd_nacga_report_guar_info_base_info b
                    on a.guarantee_code = b.biz_no
         inner join dw_nd.ods_tjnd_yw_z_report_afg_business_infomation c on a.id_business_information = c.id
         inner join dw_nd.ods_tjnd_yw_z_report_afg_business_approval d
                    on a.id_business_information = d.ID_BUSINESS_INFORMATION
         left join
     (
         select id_cfbiz_underwriting, compenstation_application_date
         from dw_nd.ods_tjnd_yw_z_report_bh_compensatory
         where OVER_TAG = 'BJ'
           and STATUS = 1
     ) t2 -- 代偿表
     on b.biz_id = t2.id_cfbiz_underwriting
where a.day_id = '${v_sdate}'
  and b.day_id = '${v_sdate}';


-- 新业务系统逻辑
-- 临时表存业务的反担保措施
drop table if exists dw_tmp.tmp_dwd_tjnd_report_proj_base_info_ct_meas;
create table if not exists dw_tmp.tmp_dwd_tjnd_report_proj_base_info_ct_meas
(
    guar_id           varchar(100) comment '业务编号',
    counter_guar_meas varchar(100) comment '反担保措施'
) engine = InnoDB
  default charset = utf8mb4
  collate = utf8mb4_bin comment ='国担上报-项目基础信息临时表-存业务的反担保措施';
commit;

-- 进件业务
insert into dw_tmp.tmp_dwd_tjnd_report_proj_base_info_ct_meas
( guar_id
, counter_guar_meas)
select t1.code                    as guar_id
     , t2.reply_counter_guar_meas as counter_guar_meas
from (
         select distinct id, code
         from dw_nd.ods_t_biz_project_main t1 -- 进件业务信息表
         union all
         select distinct id, code
         from dw_nd.ods_t_biz_proj_xz t1 -- 续支业务信息表
     ) t1
         inner join
     (
         select t1.project_id
              , t1.create_time
              , t1.reply_counter_guar_meas
              , row_number() over (partition by t1.project_id order by t1.create_time desc) rn
         from (
                  select t1.project_id, t1.create_time, t1.reply_counter_guar_meas
                  from (
                           select t1.project_id
                                , t1.create_time
                                , t1.reply_counter_guar_meas
                                , row_number() over (partition by t1.project_id order by t1.update_time desc) rn
                           from dw_nd.ods_t_risk_check_opinion t1-- 风险审查意见表
                       ) t1
                  where t1.rn = 1
                    and t1.reply_counter_guar_meas is not null

                  union all
                  select t1.project_id, t1.create_time, t1.reply_counter_guar_meas
                  from (
                           select t1.project_id
                                , t1.create_time
                                , t1.reply_counter_guar_meas
                                , row_number() over (partition by t1.project_id order by t1.update_time desc) rn
                           from dw_nd.ods_t_risk_group_opinion t1-- 小组意见表
                       ) t1
                  where t1.rn = 1
                    and t1.reply_counter_guar_meas is not null

                  union all
                  select t1.project_id, t1.create_time, t1.reply_counter_guar_meas
                  from (
                           select t1.project_id
                                , t1.create_time
                                , t1.reply_counter_guar_meas
                                , row_number() over (partition by t1.project_id order by t1.update_time desc) rn
                           from dw_nd.ods_t_risk_officer_opinion t1-- 风险部负责人意见表
                       ) t1
                  where t1.rn = 1
                    and t1.reply_counter_guar_meas is not null

                  union all
                  select t1.project_id, t1.create_time, t1.reply_counter_guar_meas
                  from (
                           select t1.project_id
                                , t1.create_time
                                , t1.reply_counter_guar_meas
                                , row_number()
                                   over (partition by t1.project_id, t1.member_id, t1.`count` order by t1.update_time desc) rn
                           from dw_nd.ods_t_jury_group_opinion t1-- 评审委员会表
                       ) t1
                  where t1.rn = 1
                    and t1.reply_counter_guar_meas is not null

                  union all
                  select t1.project_id, t1.create_time, t1.reply_counter_guar_meas
                  from (
                           select t1.project_id
                                , t1.create_time
                                , t1.reply_counter_guar_meas
                                , row_number()
                                   over (partition by t1.project_id, t1.creator order by t1.update_time desc) rn
                           from dw_nd.ods_t_jury_summary_opinion t1-- 评审意见汇总表
                       ) t1
                  where t1.rn = 1
                    and t1.reply_counter_guar_meas is not null
              ) t1
     ) t2
     on t1.id = t2.project_id
         and t2.rn = 1
;


-- 日增量加载
insert into dw_base.dwd_tjnd_report_proj_base_info
( day_id
, proj_no_prov -- 省农担担保项目编号
, cert_no -- 证件号码
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
, dict_flag
, is_credit_auth -- 是否已授权征信上报
, is_comp_notice_credit -- 是否已通知上报代偿信息
, is_direct_guar -- 是否直接承担担保责任
, is_coop_cd -- 项目合作情况代码
, ovd_prin_rmv_bank_rk_seg_bal_3 -- 逾期三个月未代偿余额（扣除银行分险）
, other_ovd_rmv_bank_rk_seg_bal_3 -- 逾期三个月利息以及其他费用金额余额（扣除银行分险）
, comp_fst_comp_ntc_dt -- 首次代偿通知日期
)
select distinct '${v_sdate}'                              as day_id
              , t1.guar_id                                as proj_no_prov                    -- 省农担担保项目编号
              , t1.cert_no                                                                   -- 证件号码
              , regexp_replace(t1.cust_name, '\t|\n', '') as cust_name                       -- 项目主体名称 /*剔除特殊字符*/
              , case
                    when t1.cust_type = '自然人' then '01'
                    when t1.cust_type = '法人或其他组织' then '02'
                    else t0.cust_type_code
    end                                                   as cert_typ_cd                     -- 项目主体证件类型代码 /*关联国担上报个人、企业客户基本信息表，判断证件类型代码*/
              , t1.cert_no                                                                   -- 项目主体证件号码
              , case
                    when t4.source in ('1', '银行直报') then '02'
                    when t4.source = '2' or t1.data_source = '标准线上业务台账' then '01'
                    else t4.source
    end                                                   as proj_rsue_cd                    -- 项目来源代码 /*业务系统数据不规则且缺少映射，与业务部室确认后转换成上报标准*/
              , case
                    when t1.guar_id like '%FXHJ%' then '04'
                    when t3.is_first_guar = '1' then '02'
                    when t3.is_first_guar = '0' then '01'
                    else null
    end                                                   as proj_typ_cd                     -- 项目类型代码 /*通过业务编号判断，风险化解业务类型为风险续保；其他业务通过“是否首保”判断是新增或续保*/
              , coalesce(t0.country_code, t0.city_code)   as proj_blogto_area_cd             -- 项目所属区域代码 /*业务系统出，优先取县区级别，没有取市级别*/
              , t18.table_no_nacga                        as proj_blogto_org_no              -- 项目所属机构 /*上报系统映射*/ -- mdy 20241209 wyx
              , t0.cust_class_code                        as proj_main_typ_cd                -- 项目主体类型代码 /*关联国担上报个人、企业客户基本信息表,获取主体类型代码*/
              , case
                    when t1.guar_prod = '农耕e贷' then '01' /*农耕e贷转为粮食种植*/
                    else replace(t0.guar_code, '11', '10')
    end                                                   as proj_blog_busntp_no_nacga       -- 项目所属行业代码（农担体系）
              , case
                    when t1.guar_prod = '农耕e贷' then '粮食种植'
                    else replace(t1.guar_class, '非农项目', '其他农业项目')
    end                                                   as proj_blog_busntp_prov_cd        -- 项目所属行业（省农担）
              , case
                    when length(substring_index(t0.econ_code, ',', 1)) != 4 then null
                    else substring_index(t0.econ_code, ',', 1)
    end                                                   as proj_nation_econ_cd             -- 项目所属行业代码 /*国民经济分类映射*/
              , case
                    when t1.econ_class regexp "谷物|稻谷|小麦|玉米|杂粮" then '010000'
                    when t1.econ_class regexp "豆类" then '020000'
                    when t1.econ_class regexp "油科" then '030000'
                    when t1.econ_class regexp "薯类" then '040000'
                    when t1.econ_class regexp "棉花" then '050000'
                    when t1.econ_class regexp "麻类" then '060000'
                    when t1.econ_class regexp "糖类" then '070000'
                    when t1.econ_class regexp "烟草" then '080000'
                    when t1.econ_class regexp "蔬菜" then '090000'
                    when t1.econ_class regexp "食用菌" then '100000'
                    when t1.econ_class regexp "花卉|园艺" then '110000'
                    when t1.econ_class regexp "水果|苹果|梨|桃|杏|李子|葡萄|柑橘|香蕉|西瓜|硒砂瓜" then '120000'
                    when t1.econ_class regexp "坚果" then '130000'
                    when t1.econ_class regexp "含油果" then '140000'
                    when t1.econ_class regexp "香料作物" then '150000'
                    when t1.econ_class regexp "茶叶" then '160000'
                    when t1.econ_class regexp "饮料" then '170000'
                    when t1.econ_class regexp "中药材|中草药" then '180000'
                    when t1.econ_class regexp "草种植" then '190200'
                    when t1.econ_class regexp "割草" then '200000'
                    when t1.econ_class regexp "林木育种" then '210000'
                    when t1.econ_class regexp "林木育苗" then '220000'
                    when t1.econ_class regexp "造林和更新" then '230000'
                    when t1.econ_class regexp "森林" then '240200'
                    when t1.econ_class regexp "木材采运" then '270000'
                    when t1.econ_class regexp "竹材采运" then '280000'
                    when t1.econ_class regexp "木竹材林产品采集" then '290000'
                    when t1.econ_class regexp "非木竹材林产品采集" then '300000'
                    when t1.econ_class regexp "家禽|牲畜" then '310000'
                    when t1.econ_class = "牛的饲养" then '310100'
                    when t1.econ_class = "马的饲养" then '310200'
                    when t1.econ_class = "猪的饲养" then '310300'
                    when t1.econ_class = "羊的饲养" then '310400'
                    when t1.econ_class = "鸡的饲养" then '310800'
                    when t1.econ_class = "鸭的饲养" then '310900'
                    when t1.econ_class = "鹅的饲养" then '311000'
                    when t1.econ_class = "兔的饲养" then '311300'
                    when t1.econ_class = "蜜蜂饲养" then '311400'
                    when t1.econ_class regexp "其他畜牧|牲畜|畜牧" or t1.guar_class = '其他畜牧业' then '311500'
                    when t1.econ_class regexp "副食品|肉制品|淀粉及淀粉制品|豆制品|蛋制品" then '320000'
                    when t1.econ_class regexp "水产养殖|水产捕捞" then '330000'
                    when t1.econ_class regexp "海水养殖" then '330400'
                    when t1.econ_class regexp "内陆养殖" then '330500'
                    when t1.econ_class regexp "海水捕捞" then '340100'
                    when t1.econ_class regexp "内陆捕捞" then '340200'
                    when t1.econ_class = "水产品冷冻加工" then '350100'
                    when t1.econ_class regexp "水产品加工" then '350400'
                    when t1.econ_class regexp "水产品|鱼油" then '350000'
                    when t1.guar_class regexp "农产品初加工" or t1.econ_class regexp '制造|制品|屠宰|纺织|包装|织造' then '360300'
                    when t1.econ_class regexp "农业专业及辅助性活动|机械|防治|服务|灌溉|粪污" or t1.guar_class = '农资、农机、农技等农业社会化服务'
                        then '360500'
                    when t1.econ_class regexp "林业" then '360900'
                    when t1.econ_class regexp "畜牧专业及辅助性活动" then '361200'
                    when t1.econ_class regexp "渔业|鱼苗" or t1.guar_class = '渔业生产' then '361400'
                    when t1.econ_class regexp "农林牧渔专业技术" then '370000'
                    when t1.econ_class regexp "酒" then '380000'
                    when t1.econ_class regexp "肥料|化肥" then '390000'
                    when t1.econ_class regexp "农药" then '400000'
                    when t1.econ_class regexp "饲料" then '410000'
                    when t1.econ_class regexp "种子|种苗" then '420000'
                    when t1.econ_class regexp "农用薄膜" then '430000'
                    when t1.econ_class regexp "农田基础设施" then '440000'
                    when t1.econ_class regexp "互联网销售" then '450000'
                    when t1.econ_class regexp "专用设备" then '460000'
                    when t1.guar_class regexp "农业新业态" or t1.econ_class regexp '旅游' then '470000'
                    when t1.guar_class regexp "重要特色农产品种植|粮食种植" or t1.econ_class regexp '农' then '999999'
                    else '360500'
    end                                                   as proj_fin_sup_typ_cd             -- 资金支持品种
              , case
                    when t1.guar_class regexp '粮食种植|重要特色农产品种植' then '010000'
                    when t1.guar_class regexp '生猪养殖|其他畜牧业|渔业生产' and t1.remark not regexp '培育|繁育|捕捞' then '020000'
                    when t1.guar_class regexp '渔业生产' and t1.remark regexp '捕捞' then '040000'
                    when t1.guar_class regexp '生猪养殖|其他畜牧业' and t1.remark regexp '培育|繁育' then '050000'
                    when t1.guar_class regexp '农产品初加工' and t1.remark regexp '屠宰' then '060000'
                    when t1.guar_class regexp '农资、农机、农技等农业社会化服务' and t1.remark regexp '灌溉' then '070000'
                    when t1.guar_class regexp '农产品流通' and t1.remark regexp '收购' then '080100'
                    when t1.guar_class regexp '农产品流通' and t1.remark regexp '仓储|冷藏|存储' then '080301'
                    when t1.guar_class regexp '农产品流通' and t1.remark regexp '运输' then '090200'
                    when t1.guar_class regexp '农产品流通' then '080200'
                    when t1.guar_class regexp '农资、农机、农技等农业社会化服务' and t1.remark regexp '租赁' then '100000'
                    when t1.guar_class regexp '农产品初加工' and t1.remark not regexp '屠宰' then '110000'
                    when t1.guar_class regexp '农田建设' then '120000'
                    when t1.guar_class regexp '农资、农机、农技等农业社会化服务' and t1.remark regexp '服务' then '130000'
                    when t1.guar_class regexp '农业新业态' and t1.remark regexp '民宿|旅游|农家乐|渔家乐|住宿' then '140000'
                    when t1.guar_prod = '农耕e贷' then '010000'
                    else '999999'
    end                                                   as proj_fin_sup_link_cd            -- 资金支持环节 /*根据业务提供映射规则转换：国担分类+经营主业*/
              , t1.guar_prod                              as proj_prod_name                  -- 担保产品名称
              , if(t20.ID_NUMBER is null,
                   (case
                        when t3.is_first_guar = '0' and t3.is_xz = '0' then '1'
                        else '0' end),
                   '0')
                                                          as is_frst_guar                    -- 是否首担 /*首次担保+首次放款*/
              , case
                    when t1.guar_amt between 10 and 300 then '1'
                    else '0'
    end                                                   as is_policy_biz                   -- 是否政策性业务 /*政策性业务，10-300*/
              , '0'                                       as is_guar_upon_loan_apply         -- 是否见贷即保
              , t6.IS_COMP_LIMIT_RATE                     as is_comp_limit_rate              -- 是否限率代偿
              , t6.LIMIT_RATE / 100                       as limit_rate                      -- 限率
              , t6.bank_risk / 100                        as fin_org_risk_share_ratio        -- 金融机构分险比例
              , t6.gov_risk / 100                         as gov_risk_share_ratio            -- 政府分险比例
              , 0                                         as other_risk_share_ratio          -- 其他机构分险比例
              , null                                      as is_buy_ag_ins                   -- 是否购买农业保险
              , null                                      as subsidy_cls                     -- 补贴种类
              , null                                      as subsidy_amt                     -- 补贴金额
              , t14.company_name                          as core_corp_name                  -- 合作核心企业
              , case
                    when t17.proj_no_prov is not null and t1.item_stt = '已放款' then '03' /*关联逾期记录表，判断状态是否为逾期*/
                    when t16.proj_no_prov is not null and t1.item_stt = '已放款' then '02' /*关联风险预警记录表，判断状态是否有风险预警*/
                    when t1.item_stt = '已放款' then '01'
                    when t1.item_stt = '已代偿' and t0.guar_id = t0.project_no then '05'
                    else '04'
    end                                                   as proj_stt_cd                     -- 项目状态代码
              , case
                    when t19.counter_guar_meas like '%,%' then '9999' /*多个反担保方式代码的，置成组合*/
                    when regexp_replace(regexp_replace(t19.counter_guar_meas, '\\[|\\]|null|\\"|', ''), '^(,*+)', '') =
                         '00' then '01' /*剔除不规则数据*/
                    else coalesce(if(length(regexp_replace(
                            regexp_replace(t19.counter_guar_meas, '\\[|\\]|null|\\"|', ''), '^(,*+)', '')) = 0, '01',
                                     regexp_replace(regexp_replace(t19.counter_guar_meas, '\\[|\\]|null|\\"|', ''),
                                                    '^(,*+)', '')), '01') /*空值置成01*/
    end                                                   as count_guar_cls_cd               -- 反担保方式代码
              , case
                    when t1.data_source = '标准线上业务台账' then coalesce(date_format(t1.loan_begin_dt, '%Y-%m-%d'),
                                                                   date_format(t1.loan_reg_dt, '%Y-%m-%d'))
                    else date_format(t1.loan_reg_dt, '%Y-%m-%d')
    end                                                   as on_guared_dt                    -- 计入在保日期  mdy，改为与内部画像口径一致
              , if(t1.item_stt = '已放款', t1.guar_amt, 0)   as proj_onguar_amt_totl-- 项目在保余额 /*业务状态为“已放款”的合同金额*/
              , null                                      as biz_scale                       -- 经营规模
              , null                                      as biz_year                        -- 经营年限
              , null                                      as biz_lcal_typ_cd                 -- 经营场地类型代码
              , null                                      as opr_income                      -- 营业收入
              , null                                      as opr_debts                       -- 经营性负债
              , null                                      as create_jobs_num                 -- 带动就业人数
              , null                                      as create_income_amt               -- 带动农民增收金额
              , null                                      as biz_lcal_addr                   -- 经营详细地址
              , case
                    when left(t1.guar_id, 4) in ('ZZXZ', 'BHJC') then least(
                            date_format(coalesce(t1.accept_dt, '99991231'), '%Y-%m-%d'),
                            date_format(coalesce(t1.loan_begin_dt, '99991231'), '%Y-%m-%d')) /*自主续支存在续支补录历史担保年度数据，取非空最小值*/
                    else date_format(t1.accept_dt, '%Y-%m-%d')
    end                                                   as apply_dt                        -- 申请日期 /*mdy 20250107*/
              , case
                    when coalesce(t1.appl_amt, t5.bank_credit_limit) = 0 or
                         coalesce(t1.appl_amt, t5.bank_credit_limit) is null then t1.loan_amt
                    else coalesce(t1.appl_amt, t5.bank_credit_limit)
    end                                                   as apply_amt                       -- 项目申请金额 /*优先取申请金额，用银行授信额度补充，如果为0或空值，取合同金额*/
              , case
                    when left(t1.guar_id, 2) = 'XZ' and t1.aprv_term is not null then t1.aprv_term
                    else timestampdiff(month, t1.loan_begin_dt, t1.loan_end_dt)
    end                                                   as apply_period                    -- 项目申请期限 /*mdy 20250107*/
              , null                                      as is_in_litigation                -- 涉及司法诉讼
              , null                                      as is_in_judgment                  -- 涉及司法判决
              , null                                      as is_in_regulatory                -- 涉及行政处罚
              , case
                    when left(t1.guar_id, 4) in ('ZZXZ', 'BHJC')
                        then date_format(t1.loan_begin_dt, '%Y-%m-%d') /*自主续支，取担保年度开始日*/
                    else date_format(t1.aprv_dt, '%Y-%m-%d') /*其余取批复日期mdy 20250107*/
    end                                                   as aprv_dt                         -- 农担批复日期
              , case
                    when t1.data_source = '标准线上业务台账' and t1.loan_no is null
                        then t5.credit_serial_no /*线上业务合同编号为空的，取授信业务编号*/
                    else t1.loan_no
    end                                                   as loan_cont_no                    -- 借款合同编号
              , case
                    when t1.data_source = '标准线上业务台账' then date_format(t1.loan_begin_dt, '%Y-%m-%d')
                    else date_format(t7.jk_ctrct_start_date, '%Y-%m-%d')
    end                                                   as loan_begin_dt                   -- 借款合同生效日期    /*其余取借款合同开始日 mdy 20250107*/
              , case
                    when t6.dept_name in ('农村商业银行', '村镇银行') or (t1.guar_prod = '农耕e贷' and t6.bank_name = '农村商业银行') or
                         t6.dept_id is null then t1.guar_id
                    else t6.gnd_dept_id
    end                                                   as loan_bank_no                    -- 签约金融机构代码 /*为 农商银行、村镇银行的、为空的，根据银行简称映射，并将代码赋值为业务编号*/
              , coalesce(t6.bank_name, t6.dept_name)      as loan_bank_br_name               -- 签约金融机构（分支机构）
              , t1.loan_amt                               as loan_amt                        -- 借款合同额度
              , t1.loan_term                              as loan_period                     -- 借款合同期限
              , t1.loan_rate / 100                        as loan_cont_intr                  -- 借款合同利率
              , case
                    when coalesce(t9.loan_type, t4.loan_type) = '1' then '1' -- 1--自主循环贷(随借随还)
                    else '0'
    end                                                   as is_self_renewal                 -- 是否为自主循环使用
              , null                                      as loan_repay_typ                  -- 借款合同还款方式代码 main.loan_repay_type
              , case
                    when t1.guar_prod = '赈灾贷' and coalesce(t1.guar_rate, t8.guar_rate) / 100 = 0.03 then 0
                    else coalesce(t1.guar_rate, t8.guar_rate) / 100
    end                                                   as guar_fee_rate                   -- 担保费率 /*取不到的用进件的担保费率补充,赈灾贷业务费率全部置成0*/
              , case
                    when t6.dept_name in ('农村商业银行', '村镇银行') or (t1.guar_prod = '农耕e贷' and t6.bank_name = '农村商业银行') or
                         t6.dept_id is null then t1.guar_id
                    else t6.gnd_dept_id
    end                                                   as gtee_bank_no                    -- 保证合同金融机构代码 /*为 农商银行、村镇银行的、为空的，根据银行简称映射，并将代码赋值为业务编号*/
              , regexp_replace(trim(coalesce(t11.loan_notice_no, t5.loan_notice_no)), '\\(|\\（|\\)|\\）',
                               '')                        as gtee_agmt_no                    -- 保证合同编号 /*进件续支--放款通知书编号、自主续支--进件放款通知书、线上--电子签章*/
              , '03'                                      as gtee_scp_cd                     -- 保证合同保证范围代码 /*固定值 03-本金利息及其他费用*/
              , case if(left(t1.guar_id, 2) = 'XZ' and t1.aprv_term is not null, t1.aprv_term,
                        timestampdiff(month, t1.loan_begin_dt, t1.loan_end_dt))
                    when 3 then '00'
                    when 6 then '01'
                    when 12 then '02'
                    when 24 then '03'
                    when 36 then '04'
                    else '06'
    end                                                   as gtee_expd_cd                    -- 保证合同保证期间代码 /*与申请期限一致 mdy 20250107 */
              , case
                    when t1.data_source = '标准线上业务台账' then '02'
                    else t4.guar_type
    end                                                   as gtee_mhd_cd                     -- 保证方式代码 /*线上全部为连带责任保证，其余从业务系统出*/
              , case
                    when t1.data_source = '标准线上业务台账' then coalesce(date_format(t1.loan_begin_dt, '%Y-%m-%d'),
                                                                   date_format(t1.loan_reg_dt, '%Y-%m-%d'))
                    else date_format(t1.loan_reg_dt, '%Y-%m-%d')
    end                                                   as gtee_eff_dt                     -- 保证责任生效日期
              , date_format(t1.loan_end_dt, '%Y-%m-%d')   as gtee_expr_dt                    -- 保证责任失效日期
              , '90'                                      as comp_duran                      -- 代偿宽限期
              , null                                      as comp_rmv_amt                    -- 项目核销金额
              , null                                      as comp_rmv_dt                     -- 项目核销日期
              , t1.guar_amt                               as gtee_cont_amt                   -- 保证合同金额
              , '999999'                                  as ag_cnty_cd                      -- 农业大县代码
              , 1                                         as dict_flag
              , null                                      as is_credit_auth                  -- 是否已授权征信上报
              , null                                      as is_comp_notice_credit           -- 是否已通知上报代偿信息
              , '1'                                       as is_direct_guar                  -- 是否直接承担担保责任
              , '00'                                      as is_coop_cd                      -- 项目合作情况代码
              , '0'                                       as OVD_RMV_BANK_RK_SEG_BAL_3       -- 逾期三个月未代偿余额（扣除银行分险）
              , '0'                                       as other_ovd_rmv_bank_rk_seg_bal_3 -- 逾期三个月利息以及其他费用金额余额（扣除银行分险）
              , null                                      as COMP_FST_COMP_NTC_DT            -- 首次代偿通知日期
from dw_base.dwd_guar_info_all t1 -- 业务信息宽表--项目域
         inner join dw_base.dwd_guar_info_stat t0 -- 业务信息宽表--项目域
                    on t1.guar_id = t0.guar_id
         inner join dw_base.dwd_tjnd_report_biz_no_base t2 -- 上报业务基础表，关联取所有需上报业务
                    on t1.guar_id = t2.biz_no
                        and t2.day_id = '${v_sdate}'
         left join dw_base.dwd_guar_tag t3 -- 标签表
                   on t1.guar_id = t3.guar_id
         left join
     (
         select t1.id
              , t1.code as proj_no
              , t1.source
              , t1.loan_type
              , t1.guar_type
         from (
                  select t1.id
                       , t1.code
                       , t1.source
                       , t1.loan_type
                       , t1.guar_type
                       , row_number()
                          over (partition by t1.code order by t1.db_update_time desc, t1.update_time desc) rn
                  from dw_nd.ods_t_biz_project_main t1
              ) t1
         where t1.rn = 1
     ) t4 -- 担保系统进件业务表
     on t2.proj_no = t4.proj_no

         left join
     (
         select t1.apply_code
              , coalesce(t1.bank_credit_limit, t2.bank_credit_limit / 1000) as bank_credit_limit
              , t2.credit_serial_no
              , t3.signed_file_id                                           as loan_notice_no
              , t1.loan_time
         from (
                  select t1.apply_code
                       , t1.bank_credit_limit
                       , t1.loan_time
                       , row_number() over (partition by t1.apply_code order by t1.update_time desc) rn
                  from dw_nd.ods_bizhall_guar_apply t1 -- 业务大厅申请表
              ) t1
                  left join
              (
                  select t1.apply_code
                       , t1.bank_credit_limit
                       , t1.credit_serial_no
                  from (
                           select t1.apply_code
                                , t1.bank_credit_limit
                                , t1.credit_serial_no
                                , row_number() over (partition by t1.apply_code order by t1.update_time desc) rn
                           from dw_nd.ods_bizhall_guar_online_biz t1 -- 标准化线上业务台账表
                       ) t1
                  where t1.rn = 1
              ) t2
              on t1.apply_code = t2.apply_code
                  left join
              (
                  select t1.biz_id, t1.signed_file_id
                  from (
                           select t1.biz_id
                                , t1.signed_file_id
                                , t1.status
                                , row_number() over (partition by t1.biz_id order by t1.update_time desc) rn
                           from dw_nd.ods_comm_cont_comm_contract_info t1 -- 电子签章合同信息表
                           where t1.contract_name regexp '放款通知书'
                       ) t1
                  where t1.rn = 1
                    and t1.status = '2' --  2-- 已签署
              ) t3
              on t1.apply_code = t3.biz_id
         where t1.rn = 1
     ) t5
     on t1.guar_id = t5.apply_code
         left join dw_base.dwd_tjnd_report_biz_loan_bank t6 -- 省担国担银行分险比例映射底表
                   on t1.guar_id = t6.biz_no
         left join
     (
         select t1.project_id
              , t1.jk_ctrct_start_date
         from (
                  select t1.project_id
                       , t1.jk_ctrct_start_date
                       , row_number()
                          over (partition by t1.project_id order by t1.db_update_time desc, t1.update_time desc) rn
                  from dw_nd.ods_t_biz_proj_sign t1 -- 项目签约信息表
              ) t1
         where t1.rn = 1
     ) t7
     on t0.project_id = t7.project_id

         left join dw_base.dwd_guar_info_all t8 -- 业务信息宽表--项目域
                   on t2.proj_no = t8.guar_id
         left join
     (
         select t1.project_id
              , t1.loan_type
         from (
                  select t1.project_id
                       , t1.loan_type
                       , row_number()
                          over (partition by t1.project_id order by t1.db_update_time desc, t1.update_time desc) rn
                  from dw_nd.ods_t_biz_proj_appr t1 -- 项目批复信息表
              ) t1
         where t1.rn = 1
     ) t9
     on t0.project_id = t9.project_id

         left join
     (
         select t1.project_id
              , t1.loan_notice_no
         from (
                  select t1.project_id
                       , t1.fk_letter_code as                                                                    loan_notice_no
                       , row_number()
                          over (partition by t1.project_id order by t1.db_update_time desc, t1.update_time desc) rn
                  from dw_nd.ods_t_biz_proj_loan t1 -- 项目放款信息表
              ) t1
         where t1.rn = 1
     ) t11
     on if(t1.guar_id is not null and left(t1.guar_id, 4) in ('ZZXZ', 'BHJC'), t2.proj_id, t2.biz_id) = t11.project_id

         left join
     (
         select t1.dictionaries_code
              , t2.unified_social_credit_code as company_name
         from (
                  select t1.cem_base_id
                       , t1.dictionaries_code
                  from (
                           select t1.cem_base_id
                                , t1.dictionaries_code
                                , row_number() over (partition by t1.cem_base_id order by t1.update_time desc) rn
                           from dw_nd.ods_cem_dictionaries t1 -- 企业-产业集群关系
                       ) t1
                  where t1.rn = 1
              ) t1
                  inner join
              (
                  select t1.id, t1.company_name, t1.is_disable, t1.unified_social_credit_code
                  from (
                           select t1.id
                                , t1.company_name
                                , t1.is_disable
                                , t1.unified_social_credit_code
                                , row_number() over (partition by t1.id order by t1.update_time desc) rn
                           from dw_nd.ods_cem_company_base t1 -- 核心企业基本表
                       ) t1
                  where t1.rn = 1
              ) t2
              on t1.cem_base_id = t2.id
                  and t2.is_disable = '0' /*未禁用*/
     ) t14
     on t0.scheme_code = t14.dictionaries_code

         left join dw_base.dwd_tjnd_report_proj_rk_wrn_info t16 -- 国担上报-风险预警记录表
                   on t1.guar_id = t16.proj_no_prov
                       and t16.day_id = '${v_sdate}'
         left join dw_base.dwd_tjnd_report_proj_ovd_info t17 -- 国担上报-逾期记录表
                   on t1.guar_id = t17.proj_no_prov
                       and t17.day_id = '${v_sdate}'
         left join
     (
         select distinct city_code_
                       , branch_off
                       , table_no_nacga
         from (
                  select city_code_,
                         case
                             when ROLE_CODE_ = 'NHDLBranch' then '天津市宁河区'
                             when ROLE_CODE_ = 'JNBHBranch' then '天津市津南区'
                             when ROLE_CODE_ = 'BCWQBranch' then '天津市武清区'
                             when ROLE_CODE_ = 'XQJHBranch' then '天津市静海区'
                             when ROLE_CODE_ = 'JZBranch' then '天津市蓟州区'
                             when ROLE_CODE_ = 'BDBranch' then '天津市宝坻区'
                             end as branch_off
                  from dw_base.dwd_imp_area_branch
              ) a
                  left join
              (
                  select distinct t1.prov_key
                                , coalesce(t2.table_no_nacga, t3.table_no_nacga) as table_no_nacga
                  from dw_nd.ods_nacga_report_prov_nacga_code_dict t1
                           left join
                       (
                           select *
                           from (
                                    select *,
                                           row_number()
                                                   over (partition by table_no_nacga order by db_update_time desc) rn
                                    from dw_nd.ods_nacga_report_prov_nacga_code_mapping) t1
                           where rn = 1
                       ) t2
                       on t1.prov_key = t2.proj_no_prov
                           and t2.table_name = 'corp_br_org_info_front'
                           left join
                       (
                           select *
                           from (
                                    select *,
                                           row_number()
                                                   over (partition by table_no_nacga order by db_update_time desc) rn
                                    from dw_nd.ods_nacga_report_prov_nacga_code_mapping) t1
                           where rn = 1
                       ) t3
                       on left(prov_key, 3) = t3.proj_no_prov
                           and t3.table_name = 'corp_br_org_info_front'
                  where t1.table_name = 'CORP_BR_ORG_INFO'
                    and t1.field_name = 'BLOGTO_CNTY_CD'
              ) b on a.branch_off = b.prov_key
     ) t18
     on coalesce(t0.country_code, t0.city_code) = t18.city_code_
         left join dw_tmp.tmp_dwd_tjnd_report_proj_base_info_ct_meas t19
                   on if(t1.guar_id is not null and left(t1.guar_id, 4) in ('ZZXZ', 'BHJC'), t2.proj_no, t1.guar_id) =
                      t19.guar_id
         left join
     (
         select ID_NUMBER, FIRST_GUARANTEE
         from (
                  select ID_NUMBER,
                         FIRST_GUARANTEE,
                         row_number() over (partition by ID_NUMBER order by CREATED_TIME desc) rn
                  from dw_nd.ods_tjnd_yw_z_report_afg_business_infomation) t1
         where rn = 1
     ) t20 on t1.cert_no = t20.ID_NUMBER
;
commit;
-- 更新是否政策性业务代码
update dw_base.dwd_tjnd_report_proj_base_info t1
    inner join (
        select cust_cert_no,
               case
                   when sum(if(proj_stt_cd in ('01', '02', '03'), gtee_cont_amt, 0)) between 10 and 300 then '1'
                   else '0' end as is_policy_biz
        from dw_base.dwd_tjnd_report_proj_base_info
        where day_id = '${v_sdate}'
        group by cust_cert_no
    ) t2 on t1.cust_cert_no = t2.cust_cert_no
set t1.is_policy_biz = t2.is_policy_biz
where day_id = '${v_sdate}'
  and proj_stt_cd in ('01', '02', '03');
commit;