-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220119
-- 目标表   ：dw_base.ads_show_guar_minc_info 大屏-业务月新增信息
-- 源表     ：dw_base.dws_guar_stat 担保业务汇总表,dw_base.dwd_org_info 机构信息
-- 变更记录 ：20220119:统一变动
-- 						20220518 dwd_org_info替换为dim_area_info
--            20250528 dxl修改 添加区县维度 修改亿元单位为万元
-- ---------------------------------------

delete
from dw_base.ads_show_guar_minc_info
where day_id = '${v_sdate}';

commit;

insert into dw_base.ads_show_guar_minc_info
select t.day_id
     , t.city_cd
     , t.city_name
     , t.county_cd
     , t.county_name
     , t.mon
     , t.mon_desc
     , t.inc_cust
     , t.inc_bal
     , t.guar_bal
     , coalesce(t.accum_bal,0) + coalesce(tt1.accum_bal,0) as accum_bal   -- 累保金额
from (
         select '${v_sdate}'                                 day_id
              , t1.city_cd
              , t2.area_name  as                             city_name
              , t1.country_cd as                             county_cd
              , t3.area_name  as                             county_name
              , date_format('${v_sdate}', '%Y%m')            mon
              , concat(date_format('${v_sdate}', '%m'), '月') mon_desc
              , sum(tmn_inc_cust)                            inc_cust
              , sum(tmn_inc_bal)                             inc_bal
              , sum(guar_bal)                                guar_bal  -- mdy 20211122
              , sum(accum_bal)                               accum_bal -- mdy 20211122
         from dw_base.dws_guar_stat t1
                  left join dw_base.dim_area_info t2 -- mdy 20220518 wyx
                            on t1.city_cd = t2.area_cd
                                and t2.area_lvl = '2'
                  left join dw_base.dim_area_info t3 -- mdy 20221014 wyx
                            on t1.country_cd = t3.area_cd
                                and t3.area_lvl = '3'
         where t1.day_id = '${v_sdate}'
         group by t1.city_cd
                , t2.area_name
                , t1.country_cd
                , t3.area_name
     ) t
left join (
            select t2.sup_area_cd   as city_code  
                  ,t1.area          as county_code		
				  ,sum(loan_contract_amount) as accum_bal  -- 累保金额
			from (
	                select a.id
			              ,coalesce(
						             case when a.id in ('81043','82301','82383','88728','91752') then JSON_UNQUOTE(JSON_EXTRACT(a.area, '$[2]'))
				                          else JSON_UNQUOTE(JSON_EXTRACT(a.area, '$[1]')) 
					                      end 
						           ,JSON_UNQUOTE(JSON_EXTRACT(b.area, '$[1]'))
								   ) as area			  
			              ,c.loan_contract_amount      -- 借款合同金额
			        from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation    a
			        left join dw_nd.ods_creditmid_v2_z_migrate_base_customers_history b  -- 客户表
			        on a.id = b.id_business_information 
			        left join dw_nd.ods_creditmid_v2_z_migrate_afg_business_approval c
			        on a.id = c.id_business_information
			        where a.gur_state in ('90','93')                    -- [排除在保转进件]
			          and a.guarantee_code not in ('TJRD-2021-5S93-979U','TJRD-2021-5Z85-959X')        -- [这两笔在进件业务]
			     ) t1
	        left join dw_base.dim_area_info t2
	        on t1.area = t2.area_cd and t2.area_lvl = '3' and t2.day_id = '${v_sdate}'
			group by t2.sup_area_cd,t1.area 
		 ) tt1
on t.city_cd = tt1.city_code
and t.county_cd = tt1.county_code
where t.day_id =
      date_format(
              date_sub(concat(date_format(date_add('${v_sdate}', interval 1 month), '%Y%m'), '01'), interval 1 day),
              '%Y%m%d') -- 月底

;

commit;
