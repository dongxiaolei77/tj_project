-- ---------------------------------------
-- 开发人   : WangYX
-- 开发时间 ：20250928
-- 目标表   ：dw_base.ads_tjnd_loan_bank_info   国担上报-天津农担银担合作
-- 源表     ：dwd_tjnd_data_report_guar_tag
--            ods_tjnd_yw_business_book_new
--            ods_tjnd_yw_base_enterprise
--            dwd_imp_tjnd_report_bank_financial_institution
-- 备注     ：
-- 变更记录 ：20251028 新增4个字段 
-- ---------------------------------------

delete from dw_base.ads_tjnd_loan_bank_info where day_id = '${v_sdate}';

insert into dw_base.ads_tjnd_loan_bank_info
(
 day_id	            -- 数据日期
,bank_class	        -- 贷款银行名称
,is_sign_contract   -- 是否与省级分行签署合作协议     20251028
,bank_credit_limit  -- 银行授信额度（亿元）           20251028
,year_guar_amt	    -- 本年新增担保金额（万元）
,year_guar_qty	    -- 本年新增担保项目数
,year_unguar_amt	-- 本年解除担保金额（万元）
,year_unguar_qty	-- 本年解除担保项目数
,guar_amt	        -- 在保余额（万元）
,guar_qty	        -- 在保项目数
,margin_requirement -- 保证金要求                     20251028
,bank_risk_ratio    -- 风险分担(银行分险比例)         20251028
,avg_bank_rate	    -- 银行利率(%)
,avg_guar_rate	    -- 担保费率(%)
)
select  tt1.day_id	            -- 数据日期
       ,tt1.bank_class	        -- 贷款银行名称
       ,case when tt2.bank_name is not null then '是' else '否' end as is_sign_contract   -- 是否与省级分行签署合作协议     20251028
       ,tt2.bank_credit_limit  -- 银行授信额度（亿元）           20251028
       ,tt1.year_guar_amt	    -- 本年新增担保金额（万元）
       ,tt1.year_guar_qty	    -- 本年新增担保项目数
       ,tt1.year_unguar_amt	-- 本年解除担保金额（万元）
       ,tt1.year_unguar_qty	-- 本年解除担保项目数
       ,tt1.guar_amt	        -- 在保余额（万元）
       ,tt1.guar_qty	        -- 在保项目数
       ,tt2.margin_requirement -- 保证金要求                     20251028
       ,tt2.bank_risk_ratio    -- 风险分担(银行分险比例)         20251028
       ,tt1.avg_bank_rate	    -- 银行利率(%)
       ,tt1.avg_guar_rate	    -- 担保费率(%)
from (
select '${v_sdate}' as day_id
	,coalesce(a.bank_class,'未知') as bank_class
	,sum(year_guar_amt) as year_guar_amt
	,count(year_guar_qty) as year_guar_qty
	,sum(year_unguar_amt) as year_unguar_amt
	,count(year_unguar_qty) as year_unguar_qty
	,sum(guar_amt) as guar_amt
	,count(guar_qty) as guar_qty
	,sum(loan_rate)/count(if(loan_rate is not null,1,null)) * 100 as avg_bank_rate
	,sum(guar_rate)/count(if(guar_rate is not null,1,null)) * 100 as avg_guar_rate
from (
	select
	 coalesce(t2.gnd_dept_name,t5.中文全称) as bank_class
	,if(date_format(t1.on_guared_dt,'%Y') = left('${v_sdate}',4),t4.loan_amt,0) as year_guar_amt          -- 本年新增担保金额
	,if(date_format(t1.on_guared_dt,'%Y') = left('${v_sdate}',4),t4.proj_no_prov,null) as year_guar_qty   -- 本年新增担保项目数
	,if(date_format(t3.unguar_reg_dt,'%Y') = left('${v_sdate}',4) and t1.proj_stt_cd in ('04','05'),t3.unguar_amt,0) as year_unguar_amt        -- 本年新增解保金额
	,if(date_format(t3.unguar_reg_dt,'%Y') = left('${v_sdate}',4) and t1.proj_stt_cd in ('04','05'),t3.proj_no_prov,null) as year_unguar_qty   -- 本年新增解保项目数
	,if(t1.proj_stt_cd in ('01','02','03'),t1.proj_onguar_amt_totl,0) as guar_amt     -- 在保余额
	,if(t1.proj_stt_cd in ('01','02','03'),t1.proj_no_prov,null) as guar_qty          -- 在保项目数
	,t1.loan_cont_intr as loan_rate
	,t1.guar_fee_rate as guar_rate
	from dw_base.dwd_tjnd_report_proj_base_info t1
	left join (
		select
		 proj_no_prov
		,sum(loan_amt) as loan_amt
		from dw_base.dwd_tjnd_report_proj_loan_rec_info
		where day_id = '${v_sdate}'
		group by proj_no_prov
	) t4
	on t1.proj_no_prov = t4.proj_no_prov
	left join dw_base.dwd_tjnd_report_proj_unguar_info t3
	on t1.proj_no_prov = t3.proj_no_prov
	and t3.day_id = '${v_sdate}'
	left join dw_base.dwd_tjnd_report_biz_loan_bank t2
	on t1.proj_no_prov = t2.biz_no
	and t2.day_id = '${v_sdate}'
	left join dw_base.dwd_imp_tjnd_report_bank_financial_institution t5
	on t1.loan_bank_no = t5.机构编码
	where t1.day_id = '${v_sdate}'
) a
 where '${v_sdate}' = date_format(last_day(makedate(extract(year from '${v_sdate}'),1) + interval quarter('${v_sdate}')*3-1 month),'%Y%m%d')
group by a.bank_class
) tt1
left join (
           select case when bank_name = '天津华明村镇银行股份有限公司'          then '天津华明村镇银行股份有限公司'
                       when bank_name = '天津农村商业银行股份有限公司'          then '天津农村商业银行股份有限公司'
                       when bank_name = '中国光大银行股份有限公司天津分行'      then '中国光大银行股份有限公司'
                       when bank_name = '天津银行股份有限公司'                  then '天津银行股份有限公司'
                       when bank_name = '中国银行股份有限公司'                  then '中国银行股份有限公司'
                       when bank_name = '天津滨海江淮村镇银行'                  then '天津滨海江淮村镇银行'
                       when bank_name = '天津武清村镇银行股份有限公司'          then '天津武清村镇银行股份有限公司'
                       when bank_name = '中国农业银行股份有限公司天津市分行'    then '中国农业银行股份有限公司'
                       when bank_name = '中国工商银行股份有限公司天津市分行'    then '中国工商银行股份有限公司'
                       when bank_name = '中国建设银行股份有限公司天津市分行'    then '中国建设银行股份有限公司'
                       when bank_name = '天津宁河村镇银行股份有限公司'          then '天津宁河村镇银行股份有限公司'
                       when bank_name = '中国邮政储蓄银行股份有限公司天津分行'  then '中国邮政储蓄银行股份有限公司'
                       when bank_name = '天津静海新华村镇银行股份有限公司'      then '天津静海新华村镇银行股份有限公司'
                       when bank_name = '天津津南村镇银行股份有限公司'          then '天津津南村镇银行股份有限公司'
                       when bank_name = '天津滨海农村商业银行股份有限公司'      then '天津滨海农村商业银行股份有限公司'
                       when bank_name = '天津宝坻浦发村镇银行股份有限公司'      then '天津宝坻浦发村镇银行股份有限公司'
                       when bank_name = '交通银行股份有限公司 天津市分行'       then '交通银行股份有限公司'
					   end as bank_name
				 ,credit_line as  bank_credit_limit  -- 银行授信额度（亿元）           20251028
				 ,'无'        as  margin_requirement -- 保证金要求                     20251028
                 ,fin_org_risk_share_ratio as bank_risk_ratio    -- 风险分担(银行分险比例)         20251028
			from dw_nd.ods_imp_tjnd_bank_credit_detail
		  ) tt2
on tt1.bank_class = tt2.bank_name
;
commit;











