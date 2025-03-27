-- ----------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20241212
-- 目标表   ：dw_base.dwd_tjnd_report_proj_rcvr_info      追偿记录
-- 源表     ：dw_base.dwd_nacga_report_guar_info_base_info               国担上报范围表
--            dw_nd.ods_tjnd_yw_z_report_bh_recovery                              追偿表
--            dw_nd.ods_tjnd_yw_z_report_bh_recovery_tracking                     追偿跟踪表
--            dw_nd.ods_tjnd_yw_z_report_bh_recovery_tracking_detail              追偿跟踪详情表

-- 备注     ：
-- 变更记录 ：20250228 dxl
-- ----------------------------------------
-- 日增量加载
delete
from dw_base.dwd_tjnd_report_proj_rcvr_info
where day_id = '${v_sdate}';
commit;

-- 天津旧业务系统逻辑
insert into dw_base.dwd_tjnd_report_proj_rcvr_info
( day_id
, proj_rcvr_cd -- 省担追偿记录编号
, proj_no_prov -- 省农担担保项目编号
, rcvr_rcpt_amt -- 追偿入账金额
, rcvr_rcpt_dt -- 追偿入账日期
, dict_flag)
select distinct '${v_sdate}'                           as day_id
              , t2.recovery_no                         as proj_rcvr_cd
              , t1.biz_no                              as proj_no_prov
              , t4.cur_recovery                        as rcvr_rcpt_amt
              , date_format(t4.entry_data, '%Y-%m-%d') as rcvr_rcpt_dt
              , 0                                      as dict_flag
from dw_base.dwd_nacga_report_guar_info_base_info t1 -- 国担上报范围表
         inner join dw_nd.ods_tjnd_yw_bh_recovery t2 -- 追偿表
                    on t1.biz_id = t2.id_cfbiz_underwriting
         inner join dw_nd.ods_tjnd_yw_bh_recovery_tracking t3 -- 追偿跟踪表
                    on t3.id_recovery = t2.id
         inner join dw_nd.ods_tjnd_yw_z_report_bh_recovery_tracking_detail t4 -- 追偿跟踪详情表
                    on t4.id_recovery_tracking = t3.id
where t1.day_id = '${v_sdate}'
;
commit;

-- 天津新业务系统逻辑
insert into dw_base.dwd_tjnd_report_proj_rcvr_info
( day_id
, proj_rcvr_cd -- 省担追偿记录编号
, proj_no_prov -- 省农担担保项目编号
, rcvr_rcpt_amt -- 追偿入账金额
, rcvr_rcpt_dt -- 追偿入账日期
, dict_flag)
select '${v_sdate}'                                as day_id,
       t1.detail_id                                as proj_rcvr_cd,
       t1.record_id                                as proj_no_prov,
       t1.shou_comp_amt                            as rcvr_rcpt_amt,
       date_format(t1.real_repay_date, '%Y-%m-%d') as rcvr_rcpt_dt,
       1                                           as dict_flag
from (select *, row_number() over (partition by id order by db_update_time desc) rn
      from dw_nd.ods_t_biz_proj_recovery_repay_detail_record) t1 -- 登记还款记录
         inner join dw_base.dwd_tjnd_report_biz_no_base t2 -- 国担上报采集范围表
                    on t1.record_id = t2.biz_no
where t2.day_id = '${v_sdate}'
  and t1.rn = 1;
commit;