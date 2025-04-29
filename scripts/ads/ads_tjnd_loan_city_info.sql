delete from dw_base.ads_tjnd_loan_city_info  where day_id = '${v_sdate}';
insert into dw_base.ads_tjnd_loan_city_info
select '${v_sdate}' as day_id
	,county_name
	,city_name
	,sum(if(is_add_curryear = 1,loan_amt,0)) as year_guar_amt
	,count(if(is_add_curryear = 1,1,null)) as year_guar_qty
	,sum(loan_amt) as accum_guar_amt
	,count(1) as accum_guar_qty
	,sum(if(item_stt = '已放款',loan_amt,0)) as guar_amt
	,count(if(item_stt = '已放款',1,null)) as guar_qty
from
(
	select city_name,
	county_name,
	is_add_curryear,loan_amt,item_stt
	from dw_base.dwd_tjnd_data_report_guar_tag
	where day_id = '${v_sdate}' and '${v_sdate}' = date_format(last_day(makedate(extract(year from '${v_sdate}'),1) + interval quarter('${v_sdate}')*3-1 month),'%Y%m%d') -- 季度最后一天上报数据
)a
group by county_name,city_name;
commit;