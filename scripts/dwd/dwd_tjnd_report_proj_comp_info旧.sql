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
-- 变更记录 ：
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
, dict_flag
, COMP_OVD_AMT -- 代偿时逾期金额
)
select distinct '${v_sdate}'                                  as day_id
              , t1.biz_no                                     as proj_no_prov
              , date_format(t2.FIRST_NOTICE_DATE, '%Y-%m-%d') as comp_fst_comp_ntc_dt
              , case
                    when t2.overdue_reason = '1' then '010700'
                    when t2.overdue_reason = '2' then '010700'
                    when t2.overdue_reason = '3' then '020200'
                    when t2.overdue_reason = '4' then '000000'
                    when t2.overdue_reason = '5' then '000000'
                    when t2.overdue_reason = '6' then '000000'
                    when t2.overdue_reason = '7' then '000000'
                    when t2.overdue_reason = '8' then '000000'
                    when t2.overdue_reason = '9' then '000000'
                    when t2.overdue_reason = '10' then '030204'
                    when t2.overdue_reason = '11' then '000000'
                    when t2.overdue_reason = '12' then '000000'
                    when t2.overdue_reason = '13' then '999999'
                    when t2.overdue_reason = '14' then '011100'
                    else '000000'
    end                                                       as subj_comp_rsn_cd
              , case
                    when t2.overdue_sub_reason = '1' then '00'
                    when t2.overdue_sub_reason = '2' then '00'
                    when t2.overdue_sub_reason = '3' then '00'
                    when t2.overdue_sub_reason = '4' then '01'
                    when t2.overdue_sub_reason = '5' then '01'
                    when t2.overdue_sub_reason = '6' then '02'
                    when t2.overdue_sub_reason = '7' then '06'
                    when t2.overdue_sub_reason = '8' then '04'
                    when t2.overdue_sub_reason = '9' then '01'
                    when t2.overdue_sub_reason = '10' then '00'
                    when t2.overdue_sub_reason = '11' then '04'
                    when t2.overdue_sub_reason = '12' then '10'
                    when t2.overdue_sub_reason = '13' then '99'
                    when t2.overdue_sub_reason = '14' then '00'
                    else '00'
    end                                                       as obj_comp_rsn_cd
              , t2.pla_describe                               as comp_rsn_desc
              , cast(t4.compensation_period as signed)        as comp_duran
              , case
                    when t2.proposed_way_of_recovery = '1' then '自主追偿'
                    when t2.proposed_way_of_recovery = '2' then '委托律所'
                    when t2.proposed_way_of_recovery = '3' then '委托银行'
                    when t2.proposed_way_of_recovery = '4' then '其他'
                    else '其他'
    end                                                       as rcvg_meas
              , date_format(t5.date_of_set, '%Y-%m-%d')       as comp_unguar_dt
              , 0                                             as rbl_rk_shr_amt_br_gov   -- 目前天津农担不涉及, 默认为0，后续根据不同协议约定的分险方式计算
              , 0                                             as rbl_rk_shr_amt_br_other -- 目前天津农担不涉及, 默认为0，后续根据不同协议约定的分险方式计算
              , 0                                             as acc_comp_fee            -- 未采集：直接oa走报销，业务不记录
              , date_format(t2.payment_date, '%Y-%m-%d')      as comp_pmt_dt
              , coalesce(t2.total_compensation * 10000, 0)    as comp_pmt_amt
              , null                                          as comp_cert_dt
              , 0                                             as dict_flag
              , t2.OVERDUE_TOT                                                           -- 代偿时逾期金额
from dw_base.dwd_nacga_report_guar_info_base_info t1 -- 国担上报范围表
         inner join dw_nd.ods_creditmid_v2_z_migrate_bh_compensatory t2 -- 代偿表
                    on t1.biz_id = t2.id_cfbiz_underwriting
         inner join dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation t3 -- 业务申请表
                    on t1.biz_id = t3.id
         left join dw_nd.ods_tjnd_yw_base_cooperative_institution_agreement t4 -- BO,机构合作协议,NEW
                   on t3.related_agreement_id = t4.id
         left join dw_nd.ods_creditmid_v2_z_migrate_afg_guarantee_relieve t5 -- 担保解除表
                   on t1.biz_id = t5.id_business_information
where t1.day_id = '${v_sdate}'
  and t2.OVER_TAG = 'BJ'
  and t2.STATUS = 1
;
commit;
