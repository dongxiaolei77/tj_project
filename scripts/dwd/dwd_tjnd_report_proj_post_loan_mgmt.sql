-- ----------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20241212
-- 目标表   ：dw_base.dwd_tjnd_report_proj_post_loan_mgmt       保后检查记录
-- 源表     ：dw_base.dwd_nacga_report_guar_info_base_info               国担上报范围表
--            dw_nd.ods_tjnd_yw_z_report_bh_batch_inspection_detail               保后检查详情表
--            dw_nd.ods_tjnd_yw_z_report_bh_batch_inspection                      保后检查表
-- 备注     ：天津农担历史数据迁移，上报国农担，数据逻辑组装
-- 变更记录 ： zhangruwen20250219
--           20250917 新逻辑部分补充在保转进件的项目
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
              , 1                as dict_flag
from (select t1.biz_no                                  as                                                  proj_no_prov
           , t2.check_method                            as                                                  loan_chk_mhd_cd
           , date_format(t3.spot_time, '%Y-%m-%d')      as                                                  loan_chk_dt
           , regexp_replace(t3.busi_proposal, '\n', '') as                                                  loan_chk_opinion
           , row_number() over (partition by t1.biz_no order by date_format(t3.spot_time, '%Y-%m-%d') desc) rn
      from dw_base.dwd_nacga_report_guar_info_base_info t1 -- 国担上报范围表
               inner join dw_nd.ods_creditmid_v2_z_migrate_bh_batch_inspection_detail t2-- 保后检查详情表s
                          on t1.biz_id = t2.id_cfbiz_underwriting
               inner join dw_nd.ods_creditmid_v2_z_migrate_bh_batch_inspection t3 -- 保后检查表
                          on t2.id_batch_inspection = t3.id
      where t1.day_id = '${v_sdate}') t1
where rn = 1
;
commit;


-- 日增量加载
insert into dw_base.dwd_tjnd_report_proj_post_loan_mgmt
( day_id
, proj_no_prov -- 省农担担保项目编号
, loan_chk_mhd_cd -- 保后检查方式代码
, loan_chk_dt -- 保后检查执行日期
, loan_chk_opinion -- 保后检查意见
, dict_flag)
select t_all.day_id
     , t_all.proj_no_prov -- 省农担担保项目编号
     , t_all.loan_chk_mhd_cd -- 保后检查方式代码
     , t_all.loan_chk_dt -- 保后检查执行日期
     , t_all.loan_chk_opinion -- 保后检查意见
     , t_all.dict_flag
from 
(
select t4.day_id
     , t4.proj_no_prov      -- 省农担担保项目编号
     , t4.loan_chk_mhd_cd   -- 保后检查方式代码
     , t4.loan_chk_dt       -- 保后检查执行日期
     , t4.loan_chk_opinion  -- 保后检查意见
     , 1  as dict_flag 
     , row_number() over(partition by t4.proj_no_prov order by dict_flag desc) as rn  -- [t4把两部分 union 起来，优先取新系统逻辑，取不到的取老系统的]    20250917
from (                                                                                              -- 【原老系统逻辑，在保转进件的业务】               20250917
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
        	       )                                                                 t1 -- 【在保转进件项目】
              inner join dw_nd.ods_creditmid_v2_z_migrate_bh_batch_inspection_detail t2-- 保后检查详情表s
              on t1.biz_id = t2.id_cfbiz_underwriting
              inner join dw_nd.ods_creditmid_v2_z_migrate_bh_batch_inspection        t3 -- 保后检查表
              on t2.id_batch_inspection = t3.id
             ) t1
        where rn = 1 		 
		 
		union all
		                                                                                            -- 【新系统逻辑】
        select distinct '${v_sdate}'      as day_id
                      , t3.guar_id        as proj_no_prov     -- 省农担担保项目编号
                      , t1.check_mode     as loan_chk_mhd_cd  -- 保后检查方式代码
                      , date(t1.check_dt) as loan_chk_dt      -- 保后检查执行日期
                      , case t1.task_status
                            when '40' then '正常'
                            when '50' then '风险'
                            else t1.task_status
            end                           as loan_chk_opinion -- 保后检查意见
                      , 1                 as dict_flag
        from (
                 select a1.proj_id
                      , a1.check_mode
                      , a1.check_dt
                      , a1.task_status
                      , row_number() over (partition by a1.proj_id order by a1.check_dt desc) rn
                 from (
                          select t1.project_id                        as proj_id
                               , t2.check_mode
                               , date_format(t2.check_date, '%Y%m%d') as check_dt
                               , t1.task_status
                               , t1.wf_inst_id
                          from (
                                   select t1.id,
                                          t1.project_id,
                                          t1.task_status,
                                          t1.wf_inst_id,
                                          row_number()
                                                  over (partition by t1.id order by t1.db_update_time desc, t1.update_time desc) rn
                                   from dw_nd.ods_t_loan_after_task t1 -- 保后任务详情表
                               ) t1
                                   left join
                               (
                                   select t1.task_id
                                        , t1.report_date
                                        , t1.check_date
                                        , t1.check_mode
                                        , if(length(t1.check_conclusion) = 0 or t1.check_conclusion is null, null,
                                             t1.check_conclusion) as                                                                                check_conclusion
                                        , row_number()
                                           over (partition by t1.task_id order by t1.report_date desc, t1.db_update_time desc, t1.update_time desc) rn
                                   from dw_nd.ods_t_loan_after_check t1 -- 保后检查表
                               ) t2
                               on t2.task_id = t1.id
                                   and t2.rn = 1
                          where t1.rn = 1
                      ) a1
                          inner join (
                     select inst_id
                     from (
                              select inst_id
                                   , row_number() over (partition by inst_id order by end_tm desc ) as rn
                              from dw_base.dwd_evt_wf_task_info -- 工作流审批表
                              where day_id = '${v_sdate}'
                                and task_name = '市管中心主任'
                                and end_tm > date('2024-07-01')
                          ) t
                     where rn = 1
                 ) a2
                                     on a1.wf_inst_id = a2.inst_id
                                         and a1.task_status in ('40', '50') -- 40正常  50风险
             ) t1
                 left join
             (
                 select t1.guar_id, t1.project_id, t1.item_stt_code
                 from dw_base.dwd_guar_info_stat t1 -- 业务台账表
                 where t1.project_no = t1.guar_id -- 主项目
             ) t3
             on t1.proj_id = t3.project_id
                 inner join dw_base.dwd_tjnd_report_biz_no_base t4 -- 国担上报范围表
                            on t1.proj_id = t4.biz_id
                                and t4.day_id = '${v_sdate}'
        
        where t3.item_stt_code in ('06', '11', '12') -- 06'已放款',11'已解保',12'已代偿'
          and t1.rn = 1
     ) t4
) t_all
where t_all.rn = 1
;
commit;