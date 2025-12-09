-- 再担保业务明细,非展期业务
-- 展期业务，直接给出新增的，不再判断原业务解保日期，由诸葛老师去核对是否上报
delete from dw_base.ads_sdnd_loan_guar_info where day_id = '${v_sdate}';
insert into dw_base.ads_sdnd_loan_guar_info(day_id,cust_name,is_policy,guar_amt,loan_amt,guar_beg_dt,guar_end_dt,loan_bank,guar_rate,loan_rate,guar_class_type,bank_duty_rate,loan_cont_beg_dt,cust_class_type,cert_no,loan_no,guar_cont_no,is_first_guar,code)
select '${v_sdate}' as day_id
	,cust_name
	,'是' as is_policy
	,loan_amt as guar_amt
	,loan_amt
	,guar_beg_dt
	,guar_end_dt
	,loan_bank
	,guar_rate 
	,loan_rate
	,guar_class_type -- 后续需要治理
	,bank_duty_rate -- 后续需要补充
	,coalesce(guar_beg_dt,loan_reg_dt) as loan_cont_beg_dt
	,cust_class_type -- 后续需要分类治理
	,cert_no
	,loan_no
	,guar_cont_no
	,is_first_guar
	,guar_id
from dw_base.dwd_sdnd_data_report_guar_tag a
where day_id = '${v_sdate}' 
	and item_stt = '已放款'
	and loan_reg_dt >= date_format('${v_sdate}','%Y%m01')
	and loan_reg_dt <= date_format(last_day('${v_sdate}'),'%Y%m%d')
	and policy_type = '政策性业务：[10-300]'
	and '${v_sdate}' = date_format(last_day('${v_sdate}'),'%Y%m%d') -- 每月底上报月度数据
	-- and is_fxhj = 0
;
commit;