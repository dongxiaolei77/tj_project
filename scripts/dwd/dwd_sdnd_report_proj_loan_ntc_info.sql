-- ----------------------------------------
-- 开发人   : 
-- 开发时间 ：
-- 目标表   ：dwd_sdnd_report_proj_loan_ntc_info       放款通知记录表
-- 源表     ：dw_base.dwd_guar_info_all                业务信息宽表--项目域
--           dw_base.dwd_sdnd_report_biz_no_base      国担上报范围表
--           dw_base.dwd_sdnd_report_proj_loan_rec_info 放款记录
--           dw_nd.ods_bizhall_guar_online_biz        标准化线上业务台账表
-- 备注     ：
-- 变更记录 ：20240831 增加注释，代码结构优化 WangYX
--            20241201 脚本的统一变更，TDS转MySQL8.0 zhangfl
-- ----------------------------------------

-- 日增量加载
delete from dw_base.dwd_sdnd_report_proj_loan_ntc_info where day_id = '${v_sdate}'; 
commit;

insert into dw_base.dwd_sdnd_report_proj_loan_ntc_info
(
 day_id
,proj_no_prov	    -- 省农担担保项目编号
,loan_ntc_no	    -- 放款通知书编号
,loan_ntc_amt	    -- 放款通知书金额
,loan_ntc_eff_dt	-- 放款通知书生效日期
,loan_ntc_period	-- 放款通知书有效期限
)
select distinct '${v_sdate}' as day_id
	,t1.biz_no 												as proj_no_prov	                    -- 省农担担保项目编号
	,t2.loan_notify_no 			                            as loan_ntc_no			            -- 放款通知书编号
	,if(t2.guar_amt = 0 or t2.guar_amt > t2.loan_amt or t2.guar_amt is null,t2.loan_amt,t2.guar_amt) as loan_ntc_amt -- 放款通知书金额 /*金额为0或者为空、或者大于合同金额，取合同金额，线上业务空值的用最终授信额度补充*/
	,date(coalesce(t2.notify_dt,t3.active_dt,t4.loan_strt_dt)) as loan_ntc_eff_dt		-- 放款通知书生效日期 /*优先取放款通知书出函日期日期，线上业务取额度激活日期，空值用放款记录表的放款日期补充*/
	,6 														as loan_ntc_period		            -- 放款通知书有效期限
from dw_base.dwd_sdnd_report_biz_no_base t1 -- 国担上报范围表
inner join dw_base.dwd_guar_info_all t2
on t1.biz_no = t2.guar_id 

left join
(
	select	t1.id
			,t1.apply_code
			,date_format(t1.active_date, '%Y%m%d') as active_dt
	from
	(
		select	t1.id, t1.apply_code, t1.active_date, row_number()over(partition by t1.id order by t1.update_time desc) rn
		from dw_nd.ods_bizhall_guar_online_biz t1 -- 标准化线上业务台账表
	) t1
	where t1.rn = 1
) t3
on t1.biz_no = t3.apply_code
inner join dw_base.dwd_sdnd_report_proj_loan_rec_info t4 -- 放款记录
on t1.biz_no = t4.proj_no_prov
and t4.day_id = '${v_sdate}'
where t1.day_id = '${v_sdate}'
;
commit;