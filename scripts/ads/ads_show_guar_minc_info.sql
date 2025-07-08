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
select day_id
     , city_cd
     , city_name
     , county_cd
     , county_name
     , mon
     , mon_desc
     , inc_cust
     , inc_bal
     , guar_bal
     , accum_bal
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
where day_id =
      date_format(
              date_sub(concat(date_format(date_add('${v_sdate}', interval 1 month), '%Y%m'), '01'), interval 1 day),
              '%Y%m%d') -- 月底

;

commit;
