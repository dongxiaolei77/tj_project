-- ----------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20241212
-- 目标表   ：dw_base.dwd_tjnd_report_proj_rk_wrn_info      风险预警记录
-- 源表     ：dw_base.dwd_nacga_report_guar_info_base_info               国担上报范围表
--            dw_nd.ods_tjnd_yw_z_report_bh_early_contract_detail                 预警业务详情表
--            dw_nd.ods_tjnd_yw_z_report_bh_early_warning                         预警表
-- 备注     ：
-- 变更记录 ：20250219 zhangruwen  wrrn_id赋值1
--           20250917 新逻辑部分补充在保转进件的项目
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


-- 日增量加载
insert into dw_base.dwd_tjnd_report_proj_rk_wrn_info
( day_id
, proj_no_prov -- 省农担担保项目编号
, rk_wrn_src_cd -- 风险预警来源代码
, rk_mgmt_rslt -- 风险处置结论
, wrn_id
, dict_flag)
select t_all.day_id
     , t_all.proj_no_prov  -- 省农担担保项目编号
     , t_all.rk_wrn_src_cd -- 风险预警来源代码
     , t_all.rk_mgmt_rslt  -- 风险处置结论
     , t_all.wrn_id
     , t_all.dict_flag
from 
(	 
select t4.day_id
     , t4.proj_no_prov  -- 省农担担保项目编号
     , t4.rk_wrn_src_cd -- 风险预警来源代码
     , t4.rk_mgmt_rslt  -- 风险处置结论
     , t4.wrn_id
     , t4.dict_flag
 --    , row_number() over(partition by t4.proj_no_prov order by dict_flag desc) as rn  -- [t4把两部分 union 起来，优先取新系统逻辑，取不到的取老系统的]    20250917
from (                                                                                              -- 【原老系统逻辑，在保转进件的业务】               20250917
        select distinct '${v_sdate}'                                                                   as day_id
              , t1.biz_no                                                                              as proj_no_prov
              , case
                    when t3.alert_source = 'SG' then '01'
                    when t3.alert_source = 'YH' then '02'
                    when t3.alert_source = 'XT' then '03'
                    when t3.alert_source = 'JK' then '04'
                end                                                                                     as rk_wrn_src_cd
              , regexp_replace(if(t3.processing_result is null, '无', t3.processing_result), '\n', '')  as rk_mgmt_rslt
              , t3.id                                                                                   as wrn_id
              , 0                                                                                       as dict_Flag
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
        	 )                                                        t1 -- 【在保转进件项目】
        inner join dw_nd.ods_tjnd_yw_bh_early_contract_detail         t2 -- 预警业务详情表
        on t1.biz_id = t2.id_cfbiz_underwriting
        inner join dw_nd.ods_creditmid_v2_z_migrate_bh_early_warning  t3 -- 预警表
        on t2.id_early_warning = t3.id

        union all
                                                                                                    -- 【新系统逻辑】
        select '${v_sdate}' as day_id
             , proj_no_prov  -- 省农担担保项目编号
             , rk_wrn_src_cd -- 风险预警来源代码
             , rk_mgmt_rslt  -- 风险处置结论
             , '1'          as wrn_id
             , 1            as dict_flag
        from (
                 select t2.biz_no                                                      as proj_no_prov
                      , case
                            when find_in_set('1', t1.task_source_cd) > 0 then '1'
                            when find_in_set('4', t1.task_source_cd) > 0 then '4'
                            when find_in_set('7', t1.task_source_cd) > 0 then '7'
                            else substring_index(t1.task_source_cd, ',', 1)
                     end                                                               as rk_wrn_src_cd -- 风险预警来源代码，取首次预警来源 /*取代偿业务的风险项目跟踪落实数据，只要包含自主保后、专项保后、常规保后（1，4，7）为农担公司人员，其余为大数据保后*/
                      , t1.task_stt                                                    as rk_mgmt_rslt  -- 风险处置结论
                      , row_number() over (partition by t2.biz_no order by t1.risk_dt) as rk /*取确认风险时间最新的一笔*/
                 from (
                          select t1.id
                               , t1.project_id                         as proj_id
                               , t1.task_source                        as task_source_cd
                               , case t1.task_status
                                     when '50' then '风险'
                                     when '60' then '风处会代偿同意'
                                     when '90' then '已解保'
                                     when '93' then '已代偿'
                                     when '94' then '已解除'
                                     when '95' then '已化解'
                                     when '96' then '已过期'
                                     when '98' then '已终止'
                                     when '99' then '已否决'
                                     else t1.task_status
                              end                                      as task_stt
                               , date_format(t1.create_time, '%Y%m%d') as risk_dt
                          from (
                                   select t1.id
                                        , t1.project_id
                                        , t1.task_source
                                        , t1.task_status
                                        , t1.create_time
                                        , row_number()
                                           over (partition by t1.id order by t1.db_update_time desc, t1.update_time desc) rn
                                   from dw_nd.ods_t_loan_after_risk_track t1 -- 风险项目跟踪与落实信息表
                               ) t1
                          where t1.rn = 1
                      ) t1
                          inner join dw_base.dwd_tjnd_report_biz_no_base t2 -- 国担上报范围表
                                     on t1.proj_id = t2.biz_id
                                         and t2.day_id = '${v_sdate}'
                 where t1.task_stt in ('已代偿', '已解除', '已化解')
             ) t
        where rk = 1
	 ) t4
) t_all
-- where t_all.rn = 1
;
commit;