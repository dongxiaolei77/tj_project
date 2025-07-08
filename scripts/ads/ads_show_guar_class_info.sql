-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220119
-- 目标表   ：dw_base.ads_show_guar_class_info 大屏-业务产业分布信息
-- 源表     ：dw_base.dws_guar_stat 担保业务汇总表,dw_base.dim_guar_class 国家农担分类维表,dw_base.dwd_org_info 机构信息
-- 变更记录 ：20220119:统一变动
-- 			  20220518 dwd_org_info替换为dim_area_info
--            20221017 增加累计担保笔数、累计担保金额 wyx
--            20250528 dxl修改 添加区县维度 修改亿元单位为万元
-- ---------------------------------------

delete
from dw_base.ads_show_guar_class_info
where day_id = '${v_sdate}';

commit;

insert into dw_base.ads_show_guar_class_info
( day_id
, city_code
, city_name
, county_code
, county_name
, guar_class
, guar_desc
, guar_cust
, guar_bal
, accum_guar_qty
, accum_guar_bal)
select '${v_sdate}'
     , t1.city_cd
     , t3.area_name
     , t1.country_cd
     , t4.area_name
     , case when t1.guar_type in ('11', '99') then '10' else guar_type end
     , case
           when guar_type = '02' then '特色种植'
           when guar_type = '12' then '农资/机/技服务'
           when guar_type in ('11', '99') then '其他农业项目'
           else t2.value end
     , sum(guar_cust)  as guar_qty       -- 目前在保户数
     , sum(guar_bal)   as guar_bal       -- 目前在保金额
     , sum(accum_cust) as accum_guar_qty -- 累计担保笔数	  -- mdy 20221017 wyx
     , sum(accum_bal)  as accum_guar_bal -- 累计担保金额	  -- mdy 20221017 wyx
from dw_base.dws_guar_stat t1
         left join dw_base.dim_guar_class t2
                   on t1.guar_type = t2.code
         left join dw_base.dim_area_info t3 -- mdy 20220518 wyx
                   on t1.city_cd = t3.area_cd
                       and t3.area_lvl = '2'
         left join dw_base.dim_area_info t4 -- mdy 20221014 wyx
                   on t1.country_cd = t4.area_cd
                       and t4.area_lvl = '3'
where t1.day_id = '${v_sdate}'
group by case when t1.guar_type in ('11', '99') then '10' else guar_type end
       , case
             when guar_type = '02' then '特色种植'
             when guar_type = '12' then '农资/机/技服务'
             when guar_type in ('11', '99') then '其他农业项目'
             else t2.value end
       , t1.city_cd
       , t3.area_name
       , t1.country_cd
       , t4.area_name
;


commit;
