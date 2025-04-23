-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220119
-- 目标表   ：dw_base.ads_show_guar_custclass_info 大屏-业务主体分布信息
-- 源表     ：dw_base.dws_guar_stat 担保业务汇总表,dw_base.dim_cust_class 客户类型维表,dw_base.dwd_org_info 机构信息
-- 变更记录 ：20220119:统一变动
-- 						20220518 dwd_org_info替换为dim_area_info    
-- ---------------------------------------
 delete from dw_base.ads_show_guar_custclass_info where day_id = '${v_sdate}';
 
 commit ;
 
 insert into dw_base.ads_show_guar_custclass_info
 select
 '${v_sdate}'
 ,city_cd
 ,t3.area_name
 ,t1.cust_type
 ,t2.value
 ,sum(guar_cust)
 ,sum(guar_bal/10000)
 from  dw_base.dws_guar_stat t1
 left join dw_base.dim_cust_class t2
 on t1.cust_type =t2.code
 left join dw_base.dim_area_info t3  -- mdy 20220518 wyx
 on t1.city_cd = t3.area_cd
 and t3.area_lvl = '2'
 where t1.day_id = '${v_sdate}'
 group by t1.cust_type
 ,t2.value
 ,city_cd
 ,t3.area_name
 ;
 commit ;