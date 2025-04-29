delete from dw_base.ads_tjnd_loan_bank_info where day_id = '${v_sdate}';
insert into dw_base.ads_tjnd_loan_bank_info
select '${v_sdate}' as day_id
	,case when a.bank_class like'%农商行%' then '农商行' else a.bank_class end as bank_class  -- wyx 20231017
	,sum(if(is_add_curryear = 1,loan_amt,0)) as year_guar_amt
	,count(if(is_add_curryear = 1,1,null)) as year_guar_qty
	,sum(if(is_unguar_curryear = 1,loan_amt,0)) as year_unguar_amt
	,count(if(is_unguar_curryear = 1,1,null)) as year_unguar_qty
	,sum(if(item_stt = '已放款',loan_amt,0)) as guar_amt
	,count(if(item_stt = '已放款',1,null)) as guar_qty
	,sum(loan_rate)/count(if(loan_rate is not null,1,null)) as loan_rate
	,sum(guar_rate)/count(if(guar_rate is not null,1,null)) as guar_rate
from dw_base.dwd_tjnd_data_report_guar_tag a
where day_id = '${v_sdate}' and '${v_sdate}' = date_format(last_day(makedate(extract(year from '${v_sdate}'),1) + interval quarter('${v_sdate}')*3-1 month),'%Y%m%d')
group by case when a.bank_class like'%农商行%' then '农商行' else a.bank_class end;
commit;