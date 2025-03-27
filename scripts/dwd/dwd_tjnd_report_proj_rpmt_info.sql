-- ----------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20241212
-- 目标表   ：dw_base.dwd_tjnd_report_proj_rpmt_info      还款记录
-- 源表     ：dw_base.dwd_nacga_report_guar_info_base_info               国担上报范围表
--            dw_nd.ods_tjnd_yw_z_report_afg_voucher_repayment                    还款凭证信息
-- 备注     ：
-- 变更记录 ：
-- ----------------------------------------
-- 日增量加载
delete
from dw_base.dwd_tjnd_report_proj_rpmt_info
where day_id = '${v_sdate}';
commit;

insert into dw_base.dwd_tjnd_report_proj_rpmt_info
( day_id
, proj_rpmt_cd -- 省担还款记录编号
, proj_no_prov -- 省农担担保项目编号
, rpmt_amt -- 还款金额
, rpmt_prin_amt -- 还款本金金额
, rpmt_dt -- 还款日期
, rpmt_reg_dt -- 还款登记日期
, dict_flag)
select distinct '${v_sdate}'                                                                       as day_id
              , t2.ID                                                                              as proj_rpmt_cd -- 凭证编号
              , t1.biz_no                                                                          as proj_no_prov
              , (coalesce(t2.repayment_principal, 0) + coalesce(t2.repayment_interest, 0)) / 10000 as rpmt_amt
              , coalesce(t2.repayment_principal, 0) / 10000                                        as rpmt_prin_amt
              , date_format(t2.repayment_time, '%Y-%m-%d')                                         as rpmt_dt
              , date_format(t2.created_time, '%Y-%m-%d')                                           as rpmt_reg_dt
              , 0                                                                                  as dict_flag
from dw_base.dwd_nacga_report_guar_info_base_info t1 -- 国担上报范围表
         inner join dw_nd.ods_tjnd_yw_z_report_afg_voucher_repayment t2 -- 还款凭证信息
                    on t1.biz_id = t2.id_business_information
where t1.day_id = '${v_sdate}'
  and t2.delete_flag = 1
;
commit;
