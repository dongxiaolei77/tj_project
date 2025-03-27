-- ----------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20241212
-- 目标表   ：dw_base.dwd_tjnd_report_proj_ovd_info      逾期记录
-- 源表     ：dw_base.dwd_nacga_report_guar_info_base_info               国担上报范围表
--            dw_nd.ods_tjnd_yw_z_report_bh_overdue_plan                          逾期登记表
-- 备注     ：
-- 变更记录 ：
-- ----------------------------------------
-- 日增量加载
delete
from dw_base.dwd_tjnd_report_proj_ovd_info
where day_id = '${v_sdate}';
commit;

insert into dw_base.dwd_tjnd_report_proj_ovd_info
( day_id
, proj_no_prov -- 省农担担保项目编号
, ovd_dt -- 逾期日期
, ovd_amt -- 逾期本金金额
, other_ovd_amt -- 逾期利息以及其他费用金额
, other_ovd_bal -- 逾期利息以及其他费用金额余额
, ovd_prin_rmv_bank_rk_seg_amt -- 逾期本金(扣除银行分险)
, other_ovd_rmv_bank_rk_seg_amt -- 逾期利息以及其他费用金额(扣除银行分险)
, ovd_prin_rmv_bank_rk_seg_bal -- 逾期本金余额(扣除银行分险)
, other_ovd_rmv_bank_rk_seg_bal -- 逾期利息以及其他费用金额余额(扣除银行分险)
, subj_rk_rsn_cd -- 客观风险类型代码
, obj_rk_rsn_cd -- 主观风险类型代码
, ovd_rsn_desc -- 项目逾期原因详述
, rk_mtg_meas -- 风险化解措施
, ovd_prin_bal -- 逾期本金余额
, dict_flag)
select distinct '${v_sdate}'                                 as day_id
              , t1.biz_no                                    as proj_no_prov
              , date_format(t2.overdue_pri_time, '%Y-%m-%d') as ovd_dt
              , coalesce(t2.overdue_pri, 0)                  as ovd_amt
              , coalesce(t2.overdue_int, 0)                  as other_ovd_amt
              , null                                         as other_ovd_bal
              , null                                         as ovd_prin_rmv_bank_rk_seg_amt
              , null                                         as other_ovd_rmv_bank_rk_seg_amt
              , null                                         as ovd_prin_rmv_bank_rk_seg_bal
              , null                                         as other_ovd_rmv_bank_rk_seg_bal
              , t2.overdue_reason                            as subj_rk_rsn_cd
              , t2.overdue_sub_reason                        as obj_rk_rsn_cd
              , t2.pla_describe                              as ovd_rsn_desc
              , t2.manage_plan                               as rk_mtg_meas
              , null                                         as ovd_prin_bal
              , 0                                            as dict_flag
from dw_base.dwd_nacga_report_guar_info_base_info t1 -- 国担上报范围表
         inner join dw_nd.ods_tjnd_yw_z_report_bh_overdue_plan t2 -- 逾期登记表
                    on t1.biz_id = t2.id_cfbiz_underwriting
where t1.day_id = '${v_sdate}'
;
commit;