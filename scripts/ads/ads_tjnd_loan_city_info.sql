-- ---------------------------------------
-- 开发人   : WangYX
-- 开发时间 ：20250928
-- 目标表   ：dw_base.ads_tjnd_loan_city_info   国担上报-县级业务台账统计
-- 源表     ：dwd_tjnd_data_report_guar_tag
--            ods_tjnd_yw_business_book_new
--            dim_area_info
-- 备注     ：
-- 变更记录 ： 
-- ---------------------------------------

delete from dw_base.ads_tjnd_loan_city_info where day_id = '${v_sdate}';

insert into dw_base.ads_tjnd_loan_city_info
(
 day_id	             -- 数据日期
,distribute_name	 -- 县（区）名称
,city_name	         -- 该县所属地级市
,year_guar_amt	     -- 本年新增担保金额（万元）
,year_guar_qty	     -- 本年新增担保项目数
,accum_guar_amt	     -- 121号文以来累计新增担保金额（万元）
,accum_guar_qty	     -- 121号文以来累计新增担保项目数
,guar_amt	         -- 期末在保余额（万元）
,guar_qty	         -- 期末在保项目数
)
select '${v_sdate}' as day_id
	,county_name
	,coalesce(b.sup_area_name,a.city_name) as city_name
	,sum(year_guar_amt) as year_guar_amt
	,count(year_guar_qty) as year_guar_qty
	,sum(accum_guar_amt) as accum_guar_amt
	,count(accum_guar_qty) as accum_guar_qty
	,sum(guar_amt) as guar_amt
	,count(guar_qty) as guar_qty
from
(
	select
	 coalesce(t2.sup_area_name,t3.area_name) as city_name                           -- 地市名称
	,coalesce(t2.area_name,'其他区县') as county_name                               -- 区县名称
	,if(date_format(t1.on_guared_dt,'%Y') = left('${v_sdate}',4),t4.loan_amt,0) as year_guar_amt          -- 本年新增担保金额
	,if(date_format(t1.on_guared_dt,'%Y') = left('${v_sdate}',4),t4.proj_no_prov,null) as year_guar_qty   -- 本年新增担保项目数
	,0 as accum_guar_amt                                                            -- 累计担保金额
	,null as accum_guar_qty                                                         -- 累计担保项目数
	,if(t1.proj_stt_cd in ('01','02','03'),t1.proj_onguar_amt_totl,0) as guar_amt   -- 在保余额
	,if(t1.proj_stt_cd in ('01','02','03'),t1.proj_no_prov,null) as guar_qty        -- 在保项目数
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
	left join dw_base.dim_area_info t2
	on t1.proj_blogto_area_cd = t2.area_cd	and t2.area_lvl = '3'
	left join dw_base.dim_area_info t3
	on t1.proj_blogto_area_cd = t3.area_cd
	and t3.area_lvl = '2'
	where t1.day_id = '${v_sdate}'
	
	union all
	
	select
    city_name                            -- 地市名称
	,county_name                         -- 区县名称
	,0 as year_guar_amt                  -- 本年新增担保金额
	,null as year_guar_qty               -- 本年新增担保项目数
	,guar_amt as accum_guar_amt          -- 累计担保金额
	,guar_id as accum_guar_qty           -- 累计担保项目数
	,0 as guar_amt                       -- 在保余额
	,null as guar_qty                    -- 在保项目数
	from (
		select 
		guar_id
		,city_name
		,coalesce(county_name,'其他区县') as county_name
		,guar_amt
		from dw_base.dwd_guar_info_all  		
		where item_stt in ('已放款','已解保','已代偿')
		
		union all
		
		select
		 t1.guarantee_code as guar_id
		,coalesce(t3.area_name,t4.sup_area_name,'其他区县') as city_name
		,coalesce(t4.area_name,'市辖区') as county_name
		,t2.receipt_amount as guar_amt
		from dw_nd.ods_tjnd_yw_z_migrate_afg_business_infomation t1
		inner join (
			select
			id_business_information
			,sum(receipt_amount) as receipt_amount
			from dw_nd.ods_tjnd_yw_z_migrate_afg_voucher_infomation
			where delete_flag = 1
			group by id_business_information
		) t2
		on t1.id = t2.id_business_information
		left join dw_nd.ods_creditmid_v2_z_migrate_base_customers_history t5
		on t1.id_customer = t5.id
		left join dw_base.dim_area_info t3
		on t1.city = t3.area_cd
		and t3.area_lvl = '2'
		left join dw_base.dim_area_info t4
		on coalesce(replace(t1.district,'"]',''),JSON_UNQUOTE(JSON_EXTRACT(t5.area,'$[1]'))) = t4.area_cd
		and t4.area_lvl = '3'
		where t1.gur_state != '50' -- [排除在保转进件]
	) t	
)a
left join (
	            select area_cd
				      ,case when area_name = '市辖区' then null else area_name end as area_name
				      ,case when sup_area_name = '市辖区' and area_cd like '110%' then '北京市'
					        when sup_area_name = '市辖区' and area_cd like '120%' then '天津市'
							else sup_area_name
							end as sup_area_name
	            from dw_base.dim_area_info 
				where area_lvl = '3'
		 ) b 
on a.county_name = b.area_name  
where '${v_sdate}' = date_format(last_day(makedate(extract(year from '${v_sdate}'),1) + interval quarter('${v_sdate}')*3-1 month),'%Y%m%d') -- 季度最后一天上报数据
group by county_name,city_name;
commit;








