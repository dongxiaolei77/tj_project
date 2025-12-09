-- ----------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20241212
-- 目标表   ：dw_base.dwd_tjnd_report_proj_unguar_info      解保记录
-- 源表     ：dw_base.dwd_nacga_report_guar_info_base_info               国担上报范围表
--            dw_nd.ods_tjnd_yw_z_report_afg_voucher_repayment          还款凭证信息
-- 备注     ：
-- 变更记录 ：20250317 修改源表为z_report_afg_voucher_repayment
--           20250917 新逻辑部分补充在保转进件的项目
-- ----------------------------------------
-- 老系统逻辑
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
select '${v_sdate}'          as day_id
     , t1.biz_no             as proj_no_prov
     , null                  as unguar_id
     , t2.unguar_amt * 10000 as unguar_amt
     , t2.unguar_dt          as unguar_dt
     , t2.unguar_reg_dt      as unguar_reg_dt
     , 0                     as dict_flag
from dw_base.dwd_nacga_report_guar_info_base_info t1 -- 国担上报范围表
         inner join (select ID_BUSINESS_INFORMATION,
                            sum(REPAYMENT_PRINCIPAL)                     as unguar_amt,
                            date_format(max(REPAYMENT_TIME), '%Y-%m-%d') as unguar_dt,
                            date_format(max(created_time), '%Y-%m-%d')   as unguar_reg_dt
                     from dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_repayment
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
, unguar_id -- 解保记录编号
, unguar_amt -- 解保金额
, unguar_dt -- 解保日期
, unguar_reg_dt -- 解保登记日期
, dict_flag)
select  t_all.day_id
      , t_all.proj_no_prov  -- 省农担担保项目编号
	  , t_all.unguar_id     -- 解保记录编号
      , t_all.unguar_amt    -- 解保金额
      , t_all.unguar_dt     -- 解保日期
      , t_all.unguar_reg_dt -- 解保登记日期
      , t_all.dict_flag 
from 
(
select  t4.day_id
      , t4.proj_no_prov  -- 省农担担保项目编号
	  , t4.unguar_id     -- 解保记录编号
      , t4.unguar_amt    -- 解保金额
      , t4.unguar_dt     -- 解保日期
      , t4.unguar_reg_dt -- 解保登记日期
      , t4.dict_flag
      , row_number() over(partition by t4.proj_no_prov order by dict_flag desc) as rn  -- [t4把两部分 union 起来，优先取新系统逻辑，取不到的取老系统的]    20250917
from (                                                                                              -- 【原老系统逻辑，在保转进件的业务】               20250917
        select '${v_sdate}'          as day_id
             , t1.biz_no             as proj_no_prov
             , null                  as unguar_id
             , t2.unguar_amt * 10000 as unguar_amt
             , t2.unguar_dt          as unguar_dt
             , t2.unguar_reg_dt      as unguar_reg_dt
             , '0'                   as dict_flag
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
        	 )                                        t1 -- 【在保转进件项目】
        inner join (select ID_BUSINESS_INFORMATION,
                           sum(REPAYMENT_PRINCIPAL)                     as unguar_amt,
						   date_format(max(case when ID_BUSINESS_INFORMATION = '91386' then '2024-06-22 00:00:00'         -- [特殊处理]
						                        else REPAYMENT_TIME end), '%Y-%m-%d') as unguar_dt,
                           date_format(max(created_time), '%Y-%m-%d')   as unguar_reg_dt
                    from dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_repayment
                    where REPAYMENT_PRINCIPAL > 0
                      and DELETE_FLAG = 1
                    group by id_business_information) t2 -- 还款凭证信息
        on t1.biz_id = t2.id_business_information
		
        union all 
                                                                                                    -- 【新系统逻辑】
        select distinct '${v_sdate}'                                            as day_id
                      , t1.guar_id                                              as proj_no_prov
					  , '1'                                                     as unguar_id     -- 解保记录编号
                      , t1.guar_amt * 10000                                     as unguar_amt    -- 解保金额
                      , DATE_FORMAT(CAST(t2.biz_unguar_dt as date), '%Y-%m-%d') as unguar_dt     -- 解保日期
                      , DATE_FORMAT(CAST(t2.biz_unguar_dt as date), '%Y-%m-%d') as unguar_reg_dt -- 解保登记日期
                      , '1'                                                     as dict_flag
        from dw_base.dwd_guar_info_all t1 -- 业务信息宽表--项目域
        left join dw_base.dwd_guar_biz_unguar_info t2 -- 担保年度业务解保信息表--项目域
        on t2.biz_no = t1.guar_id
        inner join dw_base.dwd_tjnd_report_biz_no_base t3 -- 国担上报范围表
        on t1.guar_id = t3.biz_no
        and t3.day_id = '${v_sdate}'
        where t1.item_stt in ('已解保', '已代偿')
          and t1.data_source <> '迁移台账' -- 排除来源迁移台账数据
	 ) t4
) t_all
where t_all.rn = 1
;
commit;