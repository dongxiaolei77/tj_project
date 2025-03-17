-- ----------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20241212
-- 目标表   ：dw_base.dwd_tjnd_report_proj_unguar_info      解保记录
-- 源表     ：dw_base.dwd_nacga_report_guar_info_base_info               国担上报范围表
--            dw_nd.ods_tjnd_yw_z_report_afg_voucher_repayment          还款凭证信息
-- 备注     ：
-- 变更记录 ：20250317 修改源表为z_report_afg_voucher_repayment
-- ----------------------------------------
-- 日增量加载
delete
from dw_base.dwd_tjnd_report_proj_unguar_info
where day_id = '${v_sdate}';
commit;

insert into dw_base.dwd_tjnd_report_proj_unguar_info
( day_id
, proj_no_prov -- 省农担担保项目编号
, unguar_amt -- 解保金额
, unguar_dt -- 解保日期
, unguar_reg_dt -- 解保登记日期
)
select distinct '${v_sdate}'                               as day_id
              , t1.biz_no                                  as proj_no_prov
              , coalesce(t2.REPAYMENT_PRINCIPAL, 0)        as unguar_amt
              , date_format(t2.REPAYMENT_TIME, '%Y-%m-%d') as unguar_dt
              , date_format(t2.created_time, '%Y-%m-%d')   as unguar_reg_dt
from dw_base.dwd_nacga_report_guar_info_base_info t1 -- 国担上报范围表
         inner join dw_nd.ods_tjnd_yw_z_report_afg_voucher_repayment t2 -- 还款凭证信息
                    on t1.biz_id = t2.id_business_information
where t1.day_id = '${v_sdate}'
  and REPAYMENT_PRINCIPAL > 0
  and DELETE_FLAG = 1
;
commit;