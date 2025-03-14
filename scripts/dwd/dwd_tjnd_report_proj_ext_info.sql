-- ----------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20241212
-- 目标表   ：dw_base.dwd_tjnd_report_proj_ext_info      展期记录
-- 源表     ：dw_base.dwd_nacga_report_guar_info_base_info               国担上报范围表
--            dw_nd.ods_tjnd_yw_z_report_afg_survey                               展期/延期调查表
-- 备注     ：
-- 变更记录 ：
-- ----------------------------------------
-- 日增量加载
delete
from dw_base.dwd_tjnd_report_proj_ext_info
where day_id = '${v_sdate}';
commit;

insert into dw_base.dwd_tjnd_report_proj_ext_info
( day_id
, proj_no_prov
, afg_survey_id
, ext_amt -- 展期金额
, ext_sbmt_dt -- 展期确认日期
, ext_exp_dt -- 展期到期日期
, ext_rsn -- 展期原因
)
select distinct '${v_sdate}'                             as day_id
	      , t1.biz_no				 as proj_no_prov
	      , t2.id					 as afg_survey_id
              , coalesce(t2.amount, 0) / 10000           as ext_amt
              , date_format(t2.over_time, '%Y-%m-%d')    as gur_due_date
              , date_format(t2.GUR_DUE_DATE, '%Y-%m-%d') as ext_exp_dt
              , t2.integrated_opinion                    as ext_rsn
from dw_base.dwd_nacga_report_guar_info_base_info t1 -- 国担上报范围表
         inner join dw_nd.ods_tjnd_yw_z_report_afg_survey t2 -- 担保解除表
                    on t1.biz_id = t2.f_id
where t1.day_id = '${v_sdate}'
  and t2.application_type = 'ZQ' -- ZQ展期 YQ延期
  and t2.over_tag='BJ' and t2.submit_status='1'
;
commit;
