-- ----------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20241212
-- 目标表   ：dw_base.dwd_tjnd_report_proj_post_loan_mgmt       保后检查记录
-- 源表     ：dw_base.dwd_nacga_report_guar_info_base_info               国担上报范围表
--            dw_nd.ods_tjnd_yw_z_report_bh_batch_inspection_detail               保后检查详情表
--            dw_nd.ods_tjnd_yw_z_report_bh_batch_inspection                      保后检查表
-- 备注     ：天津农担历史数据迁移，上报国农担，数据逻辑组装
-- 变更记录 ：
-- ----------------------------------------

-- 日增量加载
delete
from dw_base.dwd_tjnd_report_proj_post_loan_mgmt
where day_id = '${v_sdate}';
commit;

insert into dw_base.dwd_tjnd_report_proj_post_loan_mgmt
( day_id
, proj_no_prov -- 省农担担保项目编号
, loan_chk_mhd_cd -- 保后检查方式代码
, loan_chk_dt -- 保后检查执行日期
, loan_chk_opinion -- 保后检查意见
, dict_flag)
select distinct '${v_sdate}'     as day_id
              , proj_no_prov     as proj_no_prov
              , loan_chk_mhd_cd  as loan_chk_mhd_cd
              , loan_chk_dt      as loan_chk_dt
              , loan_chk_opinion as loan_chk_opinion
              , 0                as dict_flag
from (select t1.biz_no                                  as                                                  proj_no_prov
           , t2.check_method                            as                                                  loan_chk_mhd_cd
           , date_format(t3.spot_time, '%Y-%m-%d')      as                                                  loan_chk_dt
           , regexp_replace(t3.busi_proposal, '\n', '') as                                                  loan_chk_opinion
           , row_number() over (partition by t1.biz_no order by date_format(t3.spot_time, '%Y-%m-%d') desc) rn
      from dw_base.dwd_nacga_report_guar_info_base_info t1 -- 国担上报范围表
               inner join dw_nd.ods_tjnd_yw_z_report_bh_batch_inspection_detail t2-- 保后检查详情表s
                          on t1.biz_id = t2.id_cfbiz_underwriting
               inner join dw_nd.ods_tjnd_yw_z_report_bh_batch_inspection t3 -- 保后检查表
                          on t2.id_batch_inspection = t3.id
      where t1.day_id = '${v_sdate}') t1
where rn = 1
;
commit;