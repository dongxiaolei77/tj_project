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
, unguar_id -- 解保记录编号
, unguar_amt -- 解保金额
, unguar_dt -- 解保日期
, unguar_reg_dt -- 解保登记日期
, dict_flag)
select '${v_sdate}'     as day_id
     , t1.biz_no        as proj_no_prov
     , null             as unguar_id
     , t2.unguar_amt    as unguar_amt
     , t2.unguar_dt     as unguar_dt
     , t2.unguar_reg_dt as unguar_reg_dt
     , 0                as dict_flag
from dw_base.dwd_nacga_report_guar_info_base_info t1 -- 国担上报范围表
         inner join (select ID_BUSINESS_INFORMATION,
                            sum(REPAYMENT_PRINCIPAL)                     as unguar_amt,
                            date_format(max(REPAYMENT_TIME), '%Y-%m-%d') as unguar_dt,
                            date_format(max(created_time), '%Y-%m-%d')   as unguar_reg_dt
                     from dw_nd.ods_tjnd_yw_z_report_afg_voucher_repayment
                     where REPAYMENT_PRINCIPAL > 0
                       and DELETE_FLAG = 1
                     group by id_business_information) t2 -- 还款凭证信息
                    on t1.biz_id = t2.id_business_information
where t1.day_id = '${v_sdate}'
;
commit;

-- 新系统逻辑

insert into dw_base.dwd_tjnd_report_proj_unguar_info
( day_id
, proj_no_prov -- 省农担担保项目编号
, unguar_amt -- 解保金额
, unguar_dt -- 解保日期
, unguar_reg_dt -- 解保登记日期
, unguar_id -- 解保记录编号
, dict_flag)
select distinct '${v_sdate}'                                            as day_id
              , t1.guar_id                                              as proj_no_prov
              , t1.loan_amt * 10000                                     as unguar_amt    -- 解保金额
              , DATE_FORMAT(CAST(t2.biz_unguar_dt as date), '%Y-%m-%d') as unguar_dt     -- 解保日期
              , DATE_FORMAT(CAST(t2.biz_unguar_dt as date), '%Y-%m-%d') as unguar_reg_dt -- 解保登记日期
              , '1'                                                     as unguar_id     -- 解保记录编号
              , '1'                                                     as dict_flag
from dw_base.dwd_guar_info_all t1 -- 业务信息宽表--项目域
         left join dw_base.dwd_guar_biz_unguar_info t2 -- 担保年度业务解保信息表--项目域
                   on t2.biz_no = t1.guar_id
         inner join dw_base.dwd_tjnd_report_biz_no_base t3 -- 国担上报范围表
                    on t1.guar_id = t3.biz_no
                        and t3.day_id = '${v_sdate}'
where t1.item_stt in ('已解保', '已代偿')
  and t1.data_source <> '迁移台账' -- 排除来源迁移台账数据
;
commit;