-- ----------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20241212
-- 目标表   ：dw_base.dwd_tjnd_report_proj_rpmt_info      还款记录
-- 源表     ：dw_base.dwd_nacga_report_guar_info_base_info               国担上报范围表
--            dw_nd.ods_tjnd_yw_z_report_afg_voucher_repayment                    还款凭证信息
-- 备注     ：
-- 变更记录 ：
-- ----------------------------------------
-- 日增量加载
delete
from dw_base.dwd_tjnd_report_proj_rpmt_info
where day_id = '${v_sdate}';
commit;

insert into dw_base.dwd_tjnd_report_proj_rpmt_info
( day_id
, proj_rpmt_cd -- 省担还款记录编号
, proj_no_prov -- 省农担担保项目编号
, rpmt_amt -- 还款金额
, rpmt_prin_amt -- 还款本金金额
, rpmt_dt -- 还款日期
, rpmt_reg_dt -- 还款登记日期
, dict_flag)
select distinct '${v_sdate}'                                                               as day_id
              , t2.ID                                                                      as proj_rpmt_cd -- 凭证编号
              , t1.biz_no                                                                  as proj_no_prov
              , (coalesce(t2.repayment_principal, 0) + coalesce(t2.repayment_interest, 0)) as rpmt_amt
              , coalesce(t2.repayment_principal, 0)                                        as rpmt_prin_amt
              , date_format(t2.repayment_time, '%Y-%m-%d')                                 as rpmt_dt
              , date_format(t2.created_time, '%Y-%m-%d')                                   as rpmt_reg_dt
              , 0                                                                          as dict_flag
from dw_base.dwd_nacga_report_guar_info_base_info t1 -- 国担上报范围表
         inner join dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_repayment t2 -- 还款凭证信息
                    on t1.biz_id = t2.id_business_information
where t1.day_id = '${v_sdate}'
  and t2.delete_flag = 1
  
union all 

select distinct '${v_sdate}'                                                               as day_id
              , t2.ID                                                                      as proj_rpmt_cd -- 凭证编号
              , t1.biz_no                                                                  as proj_no_prov
              , (coalesce(t2.repayment_principal, 0) + coalesce(t2.repayment_interest, 0)) as rpmt_amt
              , coalesce(t2.repayment_principal, 0)                                        as rpmt_prin_amt
              , date_format(t2.repayment_time, '%Y-%m-%d')                                 as rpmt_dt
              , date_format(t2.created_time, '%Y-%m-%d')                                   as rpmt_reg_dt
              , 0                                                                          as dict_flag
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
         and a.guarantee_code  in                   --   在保转进件业务
        (
          select code
          from (select *, row_number() over (partition by code order by db_update_time desc) rn
                from dw_nd.ods_t_biz_project_main
                where proj_origin = '02') t1
          where rn = 1      
	    ) 
	 ) t1 -- 国担上报范围表
inner join dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_repayment t2 -- 还款凭证信息
   on t1.biz_id = t2.id_business_information
where  t2.delete_flag = 1
;
commit;
