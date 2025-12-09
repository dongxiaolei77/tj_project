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
, dict_flag)
select distinct '${v_sdate}'                             as day_id
              , t1.biz_no                                as proj_no_prov
              , t2.id                                    as afg_survey_id
              , coalesce(t2.amount, 0)                   as ext_amt
              , date_format(t2.over_time, '%Y-%m-%d')    as gur_due_date
              , date_format(t2.GUR_DUE_DATE, '%Y-%m-%d') as ext_exp_dt
              , t2.integrated_opinion                    as ext_rsn
              , 0                                        as dict_flag
from dw_base.dwd_nacga_report_guar_info_base_info t1 -- 国担上报范围表
         inner join dw_nd.ods_creditmid_v2_z_migrate_afg_survey t2 -- 担保解除表
                    on t1.biz_id = t2.f_id
where t1.day_id = '${v_sdate}'
  and t2.application_type = 'ZQ' -- ZQ展期 YQ延期
  and t2.over_tag = 'BJ'
  and t2.submit_status = '1'

union all 
                                                                                    -- 【一部分老系统被  国担上报范围  排掉的数据】
select distinct '${v_sdate}'                             as day_id
              , t1.biz_no                                as proj_no_prov
              , t2.id                                    as afg_survey_id
              , coalesce(t2.amount, 0)                   as ext_amt
              , date_format(t2.over_time, '%Y-%m-%d')    as gur_due_date
              , date_format(t2.GUR_DUE_DATE, '%Y-%m-%d') as ext_exp_dt
              , t2.integrated_opinion                    as ext_rsn
              , 0                                        as dict_flag
from (
        select  a.guarantee_code          as biz_no
              , a.id_business_information as biz_id
              , a.guarantee_code          as proj_no
              , a.id_business_information as proj_id
              , 'old'                     as source -- 数据来源 老业务系统
        from dw_base.dwd_tjnd_yw_guar_info_all_qy a
        left join dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation b
                   on a.id_business_information = b.id
        left join dw_nd.ods_creditmid_v2_z_migrate_afg_guarantee_relieve c
                   on a.id_business_information = c.id_business_information
        where day_id = '${v_sdate}'
          and                                                   -- 保证责任失效日期不准确
           (((b.GUR_STATE = '50' and lend_reg_dt <= 20241231) or
             date_format(c.created_time, '%Y%m%d') >= 20250101) -- 2025年1月1日在保  50(在保)、90（解保）、93(代偿)
             or lend_reg_dt >= 20250101 -- 2025年1月1日以来纳入在保
             or (is_compt = 1 and payment_date >= 20250101)) -- 2025年1月1日新增已代偿业务
         and a.guarantee_code  in                   --   【 in 在保转进件业务】
        (
          select code
          from (select *, row_number() over (partition by code order by db_update_time desc) rn
                from dw_nd.ods_t_biz_project_main
                where proj_origin = '02') t1
          where rn = 1
        ) 
	 ) t1     -- 【在保转进件项目】
inner join dw_nd.ods_creditmid_v2_z_migrate_afg_survey t2 -- 担保解除表
   on t1.biz_id = t2.f_id
where t2.application_type = 'ZQ' -- ZQ展期 YQ延期
  and t2.over_tag = 'BJ'
  and t2.submit_status = '1'  
  
;
commit;

