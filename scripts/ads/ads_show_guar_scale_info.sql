-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220119
-- 目标表   ：dw_base.ads_show_guar_scale_info 大屏-业务合同规模分布信息
-- 源表     ：dw_base.dws_guar_stat  担保业务汇总表,dw_base.dwd_org_info 机构信息
-- 变更记录 ：20220119:统一变动
-- 			  20220518 dwd_org_info替换为dim_area_info
--            20221017 增加累计担保笔数、累计担保金额 wyx
--            20250528 dxl修改 添加区县维度 亿元更换为万元
-- ---------------------------------------

-- 创建临时表
drop table if exists  dw_base.tmp_ads_show_guar_scale_info_old_data;
commit;

create table dw_base.tmp_ads_show_guar_scale_info_old_data(
 city_code      varchar(50) comment '市编码'
,city_name      varchar(50) comment '市名称'
,county_code    varchar(50) comment '区编码'
,county_name    varchar(50) comment '区名称'
,loan_scale     varchar(50) comment '分类'
,guar_cust	    int            comment '在保项目数'
,guar_bal       decimal(18,6)  comment '在保金额'
,accum_cust     int            comment '累报项目数'
,accum_bal      decimal(18,6)  comment '累保金额'
) engine = InnoDB
  default charset = utf8mb4
  collate = utf8mb4_bin;
commit;

insert into dw_base.tmp_ads_show_guar_scale_info_old_data
	   select t2.sup_area_cd   as city_code
	         ,t2.sup_area_name as city_name
			 ,t1.area          as county_code
			 ,t2.area_name     as county_name 
			 ,case
                    when (t1.loan_contract_amount >= 0 and t1.loan_contract_amount < 10) or t1.loan_contract_amount is null then '1' -- 0-10万
                    when t1.loan_contract_amount >= 10 and t1.loan_contract_amount <= 50 then '2' -- 10-50万
                    when t1.loan_contract_amount > 50 and t1.loan_contract_amount <= 100 then '3' -- 50-100万
                    when t1.loan_contract_amount > 100 and t1.loan_contract_amount <= 300 then '4' -- 100-300万
                    when t1.loan_contract_amount > 300 then '5' -- 300万以上
              end as loan_scale		
             ,0 as guar_cust	
             ,0 as guar_bal
             ,1 as accum_cust
             ,t1.loan_contract_amount as accum_bal		 
	   from (
	          select coalesce( case when a.id in ('81043','82301','82383','88728','91752') then JSON_UNQUOTE(JSON_EXTRACT(a.area, '$[2]'))
				                    else JSON_UNQUOTE(JSON_EXTRACT(a.area, '$[1]')) 
					                end 
			                  ,JSON_UNQUOTE(JSON_EXTRACT(b.area, '$[1]'))) as area					  
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
	   where t1.area is not null
;
commit;

delete
from dw_base.ads_show_guar_scale_info
where day_id = '${v_sdate}';
commit;



insert into dw_base.ads_show_guar_scale_info
( day_id
, city_code
, city_name
, county_code
, county_name
, scale_code
, scale_desc
, guar_cust
, guar_bal
, accum_guar_qty
, accum_guar_bal)
select '${v_sdate}'
     , t.city_cd
     , t.city_name
     , t.country_cd
     , t.county_name
     , t.loan_scale
     , case
           when t.loan_scale = '1' then '0-10万'
           when t.loan_scale = '2' then '10-50万'
           when t.loan_scale = '3' then '50-100万'
           when t.loan_scale = '4' then '100-300万'
           else '300万以上'
    end
     , sum(guar_cust)  as guar_qty       -- 目前在保户数
     , sum(guar_bal)   as guar_bal       -- 目前在保金额
     , sum(accum_cust) as accum_guar_qty -- 累计担保笔数	  -- mdy 20221017 wyx
     , sum(accum_bal)  as accum_guar_bal -- 累计担保金额	  -- mdy 20221017 wyx
from (
       select t1.city_cd
            , t2.area_name as city_name
            , t1.country_cd
            , t3.area_name as county_name 
            , loan_scale
			, guar_cust
			, guar_bal
			, accum_cust
			, accum_bal   -- 万元
	   from dw_base.dws_guar_stat t1
         left join dw_base.dim_area_info t2 -- mdy 20220518 wyx
                   on t1.city_cd = t2.area_cd and t2.area_lvl = '2'
         left join dw_base.dim_area_info t3 -- mdy 20221014 wyx
                   on t1.country_cd = t3.area_cd
                       and t3.area_lvl = '3'
       where t1.day_id = '${v_sdate}'
	   union all 
       select  city_code   
	          ,city_name   
	          ,county_code 
	          ,county_name 
	          ,loan_scale  
	          ,guar_cust	 
	          ,guar_bal    
	          ,accum_cust  
	          ,accum_bal   
	   from dw_base.tmp_ads_show_guar_scale_info_old_data
	 ) t	 
group by t.loan_scale
       , case
             when loan_scale = '1' then '0-10万'
             when loan_scale = '2' then '10-50万'
             when loan_scale = '3' then '50-100万'
             when loan_scale = '4' then '100-300万'
             else '300万以上'
    end
       , t.city_cd
       , t.city_name
       , t.country_cd
       , t.county_name
;
commit;