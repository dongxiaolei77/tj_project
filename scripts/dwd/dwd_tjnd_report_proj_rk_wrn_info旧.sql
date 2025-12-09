-- ----------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20241212
-- 目标表   ：dw_base.dwd_tjnd_report_proj_rk_wrn_info      风险预警记录
-- 源表     ：dw_base.dwd_nacga_report_guar_info_base_info               国担上报范围表
--            dw_nd.ods_tjnd_yw_z_report_bh_early_contract_detail                 预警业务详情表
--            dw_nd.ods_tjnd_yw_z_report_bh_early_warning                         预警表
-- 备注     ：
-- 变更记录 ：
-- ----------------------------------------
-- 日增量加载
delete
from dw_base.dwd_tjnd_report_proj_rk_wrn_info
where day_id = '${v_sdate}';
commit;

insert into dw_base.dwd_tjnd_report_proj_rk_wrn_info
( day_id
, proj_no_prov -- 省农担担保项目编号
, rk_wrn_src_cd -- 风险预警来源代码
, rk_mgmt_rslt -- 风险处置结论
, wrn_id
, dict_flag)
select distinct '${v_sdate}'                                                                          as day_id
              , t1.biz_no                                                                             as proj_no_prov
              , case
                    when t3.alert_source = 'SG' then '01'
                    when t3.alert_source = 'YH' then '02'
                    when t3.alert_source = 'XT' then '03'
                    when t3.alert_source = 'JK' then '04'
    end                                                                                               as rk_wrn_src_cd
              , regexp_replace(if(t3.processing_result is null, '无', t3.processing_result), '\n', '') as rk_mgmt_rslt
              , t3.id                                                                                 as wrn_id
              , 0                                                                                     as dict_Flag
from dw_base.dwd_nacga_report_guar_info_base_info t1 -- 国担上报范围表
         inner join dw_nd.ods_tjnd_yw_bh_early_contract_detail t2 -- 预警业务详情表
                    on t1.biz_id = t2.id_cfbiz_underwriting
         inner join dw_nd.ods_creditmid_v2_z_migrate_bh_early_warning t3 -- 预警表
                    on t2.id_early_warning = t3.id
where t1.day_id = '${v_sdate}'
;
commit;
