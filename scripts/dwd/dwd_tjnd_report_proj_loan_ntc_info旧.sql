-- ----------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20241212
-- 目标表   ：dwd_tjnd_report_proj_loan_ntc_info       放款通知记录表
-- 源表     ：dw_base.dwd_nacga_report_guar_info_base_info               国担上报范围表
--            dw_nd.ods_tjnd_yw_z_report_afg_business_approval                    审批信息
--            dw_nd.ods_tjnd_yw_z_report_afg_guarantee_letter                     保函生成记录表
-- 备注     ：天津农担历史数据迁移，上报国农担，数据逻辑组装
-- 变更记录 ：
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
)
select distinct '${v_sdate}'                           as day_id
              , t1.biz_no                              as proj_no_prov
              , t2.letter_of_guarante_no               as loan_ntc_no
              , t2.loan_contract_amount / 10000              as loan_ntc_amt
              , date_format(t3.creat_time, '%Y-%m-%d') as loan_ntc_eff_dt
              , t3.GUARANTEE_LETTER_END_DATE           as loan_ntc_period
from dw_base.dwd_nacga_report_guar_info_base_info t1 -- 国担上报范围表
inner join dw_nd.ods_tjnd_yw_z_report_afg_business_approval t2 -- 审批信息
on t1.biz_id = t2.id_business_information
left join 
(
	select *
	,row_number()over(partition by id_approval order by creat_time desc) as rk
	from dw_nd.ods_tjnd_yw_z_report_afg_guarantee_letter 
	where letter_type = '0' -- 保函类型 0.放款通知书4.担保意向函5银行保证合同
)t3 -- 保函生成记录表
 on t2.id = t3.id_approval
 where t3.rk = 1 and t1.day_id = '${v_sdate}'
;
commit;
