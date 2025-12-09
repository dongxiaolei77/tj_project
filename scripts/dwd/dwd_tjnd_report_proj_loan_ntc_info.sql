-- ----------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20241212
-- 目标表   ：dwd_tjnd_report_proj_loan_ntc_info       放款通知记录表
-- 源表     ：dw_base.dwd_nacga_report_guar_info_base_info               国担上报范围表
--            dw_nd.ods_tjnd_yw_z_report_afg_business_approval                    审批信息
--            dw_nd.ods_tjnd_yw_z_report_afg_guarantee_letter                     保函生成记录表
-- 备注     ：天津农担历史数据迁移，上报国农担，数据逻辑组装
-- 变更记录 ：zhangruwen 20250219
--           20250916  添加在保转进件判断
-- ----------------------------------------
-- 日增量加载
delete
from dw_base.dwd_tjnd_report_proj_loan_ntc_info
where day_id = '${v_sdate}';
commit;

insert into dw_base.dwd_tjnd_report_proj_loan_ntc_info
( day_id
, proj_no_prov -- 省农担担保项目编号
, loan_ntc_no -- 放款通知书编号
, loan_ntc_amt -- 放款通知书金额
, loan_ntc_eff_dt -- 放款通知书生效日期
, loan_ntc_period -- 放款通知书有效期限
, dict_flag)
select distinct '${v_sdate}'                           as day_id
              , t1.biz_no                              as proj_no_prov
              , t2.letter_of_guarante_no               as loan_ntc_no
              , t2.loan_contract_amount                as loan_ntc_amt
              , date_format(t3.creat_time, '%Y-%m-%d') as loan_ntc_eff_dt
              , t3.GUARANTEE_LETTER_END_DATE           as loan_ntc_period
              , 0                                      as dict_flag
from dw_base.dwd_nacga_report_guar_info_base_info t1 -- 国担上报范围表
         inner join dw_nd.ods_creditmid_v2_z_migrate_afg_business_approval t2 -- 审批信息
                    on t1.biz_id = t2.id_business_information
         left join
     (
         select *
              , row_number() over (partition by id_approval order by creat_time desc) as rk
         from dw_nd.ods_creditmid_v2_z_migrate_afg_guarantee_letter
         where letter_type = '0' -- 保函类型 0.放款通知书4.担保意向函5银行保证合同
     ) t3 -- 保函生成记录表
     on t2.id = t3.id_approval
where t3.rk = 1
  and t1.day_id = '${v_sdate}'
;
commit;

-- 日增量加载
insert into dw_base.dwd_tjnd_report_proj_loan_ntc_info
( day_id
, proj_no_prov -- 省农担担保项目编号
, loan_ntc_no -- 放款通知书编号
, loan_ntc_amt -- 放款通知书金额
, loan_ntc_eff_dt -- 放款通知书生效日期
, loan_ntc_period -- 放款通知书有效期限
, dict_flag)
select distinct '${v_sdate}'                                                as day_id
              , t1.biz_no                                                   as proj_no_prov    -- 省农担担保项目编号
              , t2.loan_notify_no                                           as loan_ntc_no     -- 放款通知书编号
              , if(t1.biz_no like 'TJ%',t5.loan_contract_amount,          -- [判断是否是在保转进件的项目，取老系统金额]  20250916
			    if(t2.guar_amt = 0 or t2.guar_amt > t2.loan_amt or t2.guar_amt is null, t2.loan_amt,
                   t2.guar_amt))                                            as loan_ntc_amt    -- 放款通知书金额 /*金额为0或者为空、或者大于合同金额，取合同金额，线上业务空值的用最终授信额度补充*/
              , date(coalesce(t2.notify_dt, t3.active_dt, t4.loan_strt_dt)) as loan_ntc_eff_dt -- 放款通知书生效日期 /*优先取放款通知书出函日期日期，线上业务取额度激活日期，空值用放款记录表的放款日期补充*/
              , if(t1.biz_no like 'TJ%', 1, 6)                              as loan_ntc_period -- 放款通知书有效期限
              , 1                                                           as dict_flag
from dw_base.dwd_tjnd_report_biz_no_base t1 -- 国担上报范围表
         inner join dw_base.dwd_guar_info_all t2
                    on t1.biz_no = t2.guar_id

         left join
     (
         select t1.id
              , t1.apply_code
              , date_format(t1.active_date, '%Y%m%d') as active_dt
         from (
                  select t1.id,
                         t1.apply_code,
                         t1.active_date,
                         row_number() over (partition by t1.id order by t1.update_time desc) rn
                  from dw_nd.ods_bizhall_guar_online_biz t1 -- 标准化线上业务台账表
              ) t1
         where t1.rn = 1
     ) t3
     on t1.biz_no = t3.apply_code
         inner join dw_base.dwd_tjnd_report_proj_loan_rec_info t4 -- 放款记录
                    on t1.biz_no = t4.proj_no_prov
                        and t4.day_id = '${v_sdate}'
		left join (
		           select id_business_information
				         ,case when id_business_information = '91133' then round(loan_contract_amount,2) else loan_contract_amount end as loan_contract_amount  -- [这一笔单独处理]
                   from dw_nd.ods_creditmid_v2_z_migrate_afg_business_approval				   
				  ) t5
		on t1.biz_id = t5.id_business_information
where t1.day_id = '${v_sdate}'
;
commit;
