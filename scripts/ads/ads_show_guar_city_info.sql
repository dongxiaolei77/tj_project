
-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220119
-- 目标表   ：dw_base.ads_show_guar_city_info 大屏-业务地市分布信息
-- 源表     ：dw_base.dws_guar_stat 担保业务汇总表,dw_base.dwd_org_info 机构信息
-- 变更记录 ：20220119:统一变动
-- 						20220518 dwd_org_info替换为dim_area_info    
-- ---------------------------------------
delete from dw_base.ads_show_guar_city_info where day_id = '${v_sdate}';
 
 commit ;
 
 insert into dw_base.ads_show_guar_city_info
 select
 '${v_sdate}'
 ,sup_area_cd
 ,sup_area_name
 ,country_cd
 ,area_name
 ,sum(guar_cust)
 ,sum(guar_bal/10000)
 from  dw_base.dws_guar_stat t1
 left join  dw_base.dim_area_info t2 -- mdy 20220518 wyx
 on t1.country_cd =t2.area_cd
 where t1.day_id = '${v_sdate}'
 group by sup_area_cd
 ,sup_area_name
 ,country_cd
 ,area_name
 ;
 commit ;