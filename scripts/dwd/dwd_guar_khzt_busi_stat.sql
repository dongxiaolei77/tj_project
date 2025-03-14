-- ---------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20230327
-- 目标表   ：dwd_guar_khzt_busi_stat  客户直通业务统计（推业财）
-- 源表     ：dw_nd.ods_imp_portrait_info_new  画像系统数据同步_new
--            dw_base.dim_area_info            行政区划维表
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
delete from dw_base.dwd_guar_khzt_busi_stat where day_id = '${v_sdate}';
commit;

insert  into dw_base.dwd_guar_khzt_busi_stat
(
day_id            -- 数据日期
,city_code        -- 地市
,city_name        -- 地市名称
,district_code    -- 区县
,district_name    -- 区县名称
,year_inc_qty     -- 本年新增笔数
,year_inc_amt     -- 本年新增金额
)
select '${v_sdate}' as day_id
       ,coalesce(t2.area_cd, '379900')
       ,t1.city_name
       ,coalesce(t3.area_cd, '379999')
       ,t1.county_name
       ,t1.year_inc_qty
       ,t1.year_inc_amt
  from(
         select  coalesce(t.city_name, '其他地市') as city_name
                ,coalesce(t.county_name, '其他区县') as county_name
                ,count(1) as year_inc_qty
                ,sum(s_inc_amt) as year_inc_amt
           from dw_nd.ods_imp_portrait_info_new t
          where t.seq_id in  (select distinct proj_dtl_no
                                 from dw_base.dwd_agmt_guar_info
                                where proj_dtl_stt in ('50') and proj_id 
                                   in (select distinct guar_id 
                                         from dw_nd.ods_bizhall_guar_apply 
                                        where product_code in ('PA0080503','PA0080503P'))
                              )
           and date_format(t.s_reg_dt, '%Y') = date_format('${v_sdate}', '%Y')
         group by coalesce(t.city_name, '其他地市'), coalesce(t.county_name, '其他区县')
      ) t1 
 left join dw_base.dim_area_info t2
   on t1.city_name = t2.area_name and t2.area_lvl = '2'
 left join dw_base.dim_area_info t3
   on t1.county_name = t3.area_name and t1.city_name = t3.sup_area_name and t3.area_lvl = '3'
;
commit;