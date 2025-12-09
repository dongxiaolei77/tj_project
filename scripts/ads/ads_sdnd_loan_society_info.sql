delete from dw_base.ads_sdnd_loan_society_info where day_id = '${v_sdate}';
insert into dw_base.ads_sdnd_loan_society_info
select '${v_sdate}' as day_id
	,count(if(is_add_curryear = 1 and is_first_guar = '是',1,null)) as first_guar_qty
	,case when count(if(is_add_curryear = 1,1,null)) = 0 then null -- 除0报错
		else count(if(is_add_curryear = 1 and is_first_guar = '是',1,null))/count(if(is_add_curryear = 1,1,null)) 
	end as first_guar_qty_rate
	,sum(if(is_add_curryear = 1 and is_first_guar = '是',loan_amt,0)) as first_guar_amt
	,case when sum(if(is_add_curryear = 1,loan_amt,0)) = 0 then null -- 除0报错
		else sum(if(is_add_curryear = 1 and is_first_guar = '是',loan_amt,0))/sum(if(is_add_curryear = 1,loan_amt,0))
	end as first_guar_amt_rate
	,null
	,null
	,null
	,null
	,null
from dw_base.dwd_sdnd_data_report_guar_tag
where day_id = '${v_sdate}' and '${v_sdate}' = date_format(last_day(makedate(extract(year from '${v_sdate}'),1) + interval quarter('${v_sdate}')*3-1 month),'%Y%m%d');
commit;