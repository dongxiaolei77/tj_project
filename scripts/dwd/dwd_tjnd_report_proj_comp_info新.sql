-- ----------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20241212
-- 目标表   ：dw_base.dwd_tjnd_report_proj_comp_info      代偿记录
-- 源表     ：dw_base.dwd_nacga_report_guar_info_base_info               国担上报范围表
--            dw_nd.ods_tjnd_yw_z_report_bh_compensatory                          代偿表
--            dw_nd.ods_tjnd_yw_z_report_afg_business_infomation                  业务申请表
--            dw_nd.ods_tjnd_yw_z_report_base_cooperative_institution_agreement   BO,机构合作协议,NEW
--            dw_nd.ods_tjnd_yw_z_report_afg_guarantee_relieve                    担保解除表
-- 备注     ：
-- 变更记录 ：zhangruwen 20250219
-- ----------------------------------------
-- 日增量加载
delete
from dw_base.dwd_tjnd_report_proj_comp_info
where day_id = '${v_sdate}';
commit;

insert into dw_base.dwd_tjnd_report_proj_comp_info
( day_id
, proj_no_prov -- 省农担担保项目编号
, comp_fst_comp_ntc_dt -- 首次代偿通知日期
, subj_comp_rsn_cd -- 项目代偿客观原因
, obj_comp_rsn_cd -- 项目代偿主管原因
, comp_rsn_desc -- 项目代偿原因详述
, comp_duran -- 代偿宽限期
, rcvg_meas -- 追偿措施
, comp_unguar_dt -- 代偿解保日期
, rbl_rk_shr_amt_br_gov -- 应收分险金额(地方政府)
, rbl_rk_shr_amt_br_other -- 应收分险金额(其他机构)
, acc_comp_fee -- 累计追偿费用
, comp_pmt_dt -- 代偿拨付日期
, comp_pmt_amt -- 代偿拨付金额
, comp_cert_dt -- 代偿证明开具日期
, dict_flag)
select distinct '${v_sdate}'                                               as day_id
              , t1.biz_no                                                  as proj_no_prov
              , date_format(t2.compenstation_application_date, '%Y-%m-%d') as comp_fst_comp_ntc_dt
              , t2.overdue_reason                                          as subj_comp_rsn_cd
              , t2.overdue_sub_reason                                      as obj_comp_rsn_cd
              , t2.pla_describe                                            as comp_rsn_desc
              , cast(t4.compensation_period as signed)                     as comp_duran
              , t2.proposed_way_of_recovery                                as rcvg_meas
              , date_format(t5.date_of_set, '%Y-%m-%d')                    as comp_unguar_dt
              , 0                                                          as rbl_rk_shr_amt_br_gov   -- 目前天津农担不涉及, 默认为0，后续根据不同协议约定的分险方式计算
              , 0                                                          as rbl_rk_shr_amt_br_other -- 目前天津农担不涉及, 默认为0，后续根据不同协议约定的分险方式计算
              , 0                                                          as acc_comp_fee            -- 未采集：直接oa走报销，业务不记录
              , date_format(t2.payment_date, '%Y-%m-%d')                   as comp_pmt_dt
              , coalesce(t2.total_compensation, 0)                         as comp_pmt_amt
              , null                                                       as comp_cert_dt
              , 0                                                          as dict_flag
from dw_base.dwd_nacga_report_guar_info_base_info t1 -- 国担上报范围表
         inner join dw_nd.ods_tjnd_yw_z_report_bh_compensatory t2 -- 代偿表
                    on t1.biz_id = t2.id_cfbiz_underwriting
         inner join dw_nd.ods_tjnd_yw_z_report_afg_business_infomation t3 -- 业务申请表
                    on t1.biz_id = t3.id
         left join dw_nd.ods_tjnd_yw_z_report_base_cooperative_institution_agreement t4 -- BO,机构合作协议,NEW
                   on t3.related_agreement_id = t4.id
         left join dw_nd.ods_tjnd_yw_z_report_afg_guarantee_relieve t5 -- 担保解除表
                   on t1.biz_id = t5.id_business_information
where t1.day_id = '${v_sdate}'
  and t2.OVER_TAG = 'BJ'
  and t2.STATUS = 1
;
commit;
-- 日增量加载

insert into dw_base.dwd_tjnd_report_proj_comp_info
( day_id
, proj_no_prov -- 省农担担保项目编号
, comp_fst_comp_ntc_dt -- 首次代偿通知日期
, subj_comp_rsn_cd -- 项目代偿客观原因
, obj_comp_rsn_cd -- 项目代偿主管原因
, comp_rsn_desc -- 项目代偿原因详述
, comp_duran -- 代偿宽限期
, rcvg_meas -- 追偿措施
, comp_unguar_dt -- 代偿解保日期
, rbl_rk_shr_amt_br_gov -- 应收分险金额（地方政府）
, rbl_rk_shr_amt_br_other -- 应收分险金额（其他机构）
, acc_comp_fee -- 累计追偿费用
, comp_pmt_dt -- 代偿拨付日期
, comp_pmt_amt -- 代偿拨付金额
, comp_cert_dt -- 代偿证明开具日期
, dict_flag)
select '${v_sdate}'                                            as day_id
     , t1.guar_id                                              as proj_no_prov            -- 省农担担保项目编号
     , case
           when coalesce(t2.compt_aply_dt, '9999-12-31') < coalesce(t2.meet_date, '9999-12-31')
               then t2.compt_aply_dt
           when coalesce(t2.compt_aply_dt, '9999-12-31') > coalesce(t2.meet_date, '9999-12-31')
               then t2.meet_date
           else coalesce(t2.compt_aply_dt, t2.meet_date, date(t0.compt_dt), date(t1.loan_begin_dt))
    end                                                        as comp_fst_comp_ntc_dt    -- 首次代偿通知日期 -- 优先取代偿申请日期、风处会完成日期中的非空最小值，如果为空则用放款结束日期补充--
     , coalesce(substring_index(regexp_replace(t2.object_reason, '"\\[|\\]', ''), ',', 1),
                110)                                           as subj_comp_rsn_cd        -- 项目代偿客观原因 -- 非结构化数据，提取首位编码，空值置为其他--
     , '130'                                                   as obj_comp_rsn_cd         -- 主观原因 -- 暂定为其他--
     , coalesce(t8.value, '无')                                 as comp_rsn_desc           -- 项目代偿原因详述
     , '90'                                                    as comp_duran              -- 代偿宽限期
     , '诉讼追偿'                                                  as rcvg_meas               -- 追偿措施
     , t2.act_disburse_date                                    as comp_unguar_dt          -- 代偿解保日期
     , coalesce(t2.appro_aply_overdue_amt * t9.gov_risk / 100,
                t9.gov_risk_amt)                               as rbl_rk_shr_amt_br_gov   -- 应收分险金额（地方政府） -- 截止拨付申请日逾期总额(元)*政府分险比例--
     , 0                                                       as rbl_rk_shr_amt_br_other -- 应收分险金额（其他机构）
     , 0                                                       as acc_comp_fee            -- 累计追偿费用(sdnd从画像出，所以tjnd暂时置0)
     , coalesce(date(t0.compt_dt), date(t2.act_disburse_date)) as comp_pmt_dt             -- 代偿拨付日期 -- 日期存在问题，追偿日期早于代偿拨付日期，其中一笔未走完代偿流程就提前追偿；另外两笔与实际代偿拨付日期不符，已域业务部室沟通，取固定值--
     , t0.compt_amt                                            as comp_pmt_amt            -- 代偿拨付金额
     , null                                                    as comp_cert_dt            -- 代偿证明开具日期
     , 1                                                       as dict_flag
from dw_base.dwd_guar_info_all t1
         inner join dw_base.dwd_guar_info_stat t0
                    on t1.guar_id = t0.guar_id
         left join
     (
         select distinct t1.proj_id
                       , t2.objective_over_reason   as object_reason          -- 客观风险成因
                       , t2.overdue_reason          as comp_rsn_desc          -- 逾期根本原因
                       , date(t3.act_disburse_date) as act_disburse_date      -- 代偿款实际拨付日期
                       , date(t3.approp_date)       as compt_aply_dt          -- 代偿申请日期
                       , t3.overdue_totl            as appro_aply_overdue_amt -- 截止拨付申请日逾期总额(元)
                       , date(t4.meeting_date)      as meet_date              -- 上会日期
         from (
                  select t1.id
                       , t1.proj_id
                  from (
                           select t1.id
                                , t1.project_id as                                                                       proj_id
                                , row_number()
                                   over (partition by t1.project_id order by t1.db_update_time desc,t1.update_time desc) rn
                           from dw_nd.ods_t_proj_comp_aply t1
                       ) t1
                  where t1.rn = 1
              ) t1 -- 代偿申请信息表
                  left join
              (
                  select t1.comp_id
                       , t1.overdue_reason
                       , t1.objective_over_reason
                  from (
                           select t1.comp_id
                                , t1.overdue_reason
                                , t1.objective_over_reason
                                , row_number()
                                   over (partition by t1.comp_id order by t1.db_update_time desc,t1.update_time desc) rn
                           from dw_nd.ods_t_proj_comp_reason t1
                       ) t1
                  where t1.rn = 1
              ) t2
              on t1.id = t2.comp_id
                  left join
              (
                  select t1.comp_id
                       , t1.approp_date
                       , t1.act_disburse_date
                       , t1.overdue_totl
                  from (
                           select t1.comp_id
                                , date_format(t1.approp_date, '%Y%m%d')       as                                      approp_date
                                , date_format(t1.act_disburse_date, '%Y%m%d') as                                      act_disburse_date
                                , t1.overdue_totl
                                , row_number()
                                   over (partition by t1.comp_id order by t1.db_update_time desc,t1.update_time desc) rn
                           from dw_nd.ods_t_proj_comp_appropriation t1
                       ) t1
                  where t1.rn = 1
              ) t3
              on t1.id = t3.comp_id
                  left join
              (
                  select t1.ndc_id
                       , t1.meeting_date
                  from (
                           select t1.ndc_id
                                , date_format(t1.meeting_date, '%Y%m%d') as                                          meeting_date
                                , row_number()
                                   over (partition by t1.ndc_id order by t1.db_update_time desc,t1.update_time desc) rn
                           from dw_nd.ods_t_loan_after_ndc_summary_opinion t1
                       ) t1
                  where t1.rn = 1
              ) t4
              on t1.id = t4.ndc_id
     ) t2
     on t0.project_id = t2.proj_id
         inner join dw_base.dwd_tjnd_report_biz_no_base t6 -- 国担上报范围表
                    on t1.guar_id = t6.biz_no
                        and t6.day_id = '${v_sdate}'
         left join
     (
         select code, value
         from (
                  select code
                       , value
                       , row_number() over (partition by code order by update_time desc) rn
                  from dw_nd.ods_t_sys_data_dict_value_v2
                  where dict_code = 'overdueReason'
              ) t1
         where t1.rn = 1
     ) t8
     on t2.comp_rsn_desc = t8.code
         left join dw_base.dwd_tjnd_report_biz_loan_bank t9-- 国担上报银行映射表
                   on t1.guar_id = t9.biz_no
where t1.item_stt = '已代偿'
  and t1.guar_id not regexp 'XZ|ZZXZ|BHJC' -- 进件
  and t1.data_source <> '迁移数据'
;
commit;