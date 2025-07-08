-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.ads_show_guar_accum_info 大屏-业务累计信息
-- 源表     ：dw_base.dws_guar_stat 担保业务汇总表,dw_base.dwd_org_info 机构信息
-- 变更记录 ：20220117:统一变动
-- 			  20220427:解保金额改为：解保金额 = 解保金额 + 代偿金额
-- 			  20220518 dwd_org_info替换为dim_area_info
--            20221014 增加区县、累计申请金额、累计申请笔数、累计解保户数、累计放款笔数、累计放款金额
--            20230417 增加字段：国担粮食种植类笔数、国担粮食种植类累保金额(亿元) zhangfl
--            20230613 增加字段：不考虑分险的代偿金额
--            20240301 增加字段：累计代偿合同金额
-- ---------------------------------------
 
 
 -- 创建临时表，获取累计申请金额、累计申请笔数
 drop table if exists dw_tmp.tmp_ads_show_guar_accum_info_apply; commit;
 CREATE TABLE dw_tmp.tmp_ads_show_guar_accum_info_apply (
  city_cd varchar(20) COMMENT '地市',
  country_cd varchar(10) COMMENT '县区',
  apply_qty int(11) COMMENT '累计申请笔数',
  apply_bal decimal(18,2) COMMENT '累计申请金额'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit;

insert into dw_tmp.tmp_ads_show_guar_accum_info_apply
(
city_cd
,country_cd
,apply_qty
,apply_bal
)
select
city_code as city_cd
,coalesce(t1.country_code,concat(substr(t1.city_code,1,4),'99')) as country_cd
,count(1) as apply_qty
,sum(coalesce(appl_amt,0)) as apply_bal
from dw_base.dwd_guar_info_stat t1
group by country_code,city_code
;
commit;
 
delete from dw_base.ads_show_guar_accum_info where day_id = '${v_sdate}';
commit ;

insert into dw_base.ads_show_guar_accum_info
(
 day_id
,city_code
,city_name
,country_code
,country_name
,apply_bal
,apply_qty
,accum_bal
,accum_cust
,guar_bal
,guar_cust
,lsday_inc_bal
,yd_inc_cust
,lsmn_inc_bal
,lsmn_inc_cust
,year_inc_bal
,year_inc_cust
,loan_bal
,loan_qty
,rel_guar_bal
,rel_guar_qty
,comp_loan_amt
,comp_bal
,portrait_comp_bal
,comp_qty
,plant_accum_bal
,plant_accum_qty
)
select
day_id
,t1.city_code
,t1.city_name
,t1.country_code
,coalesce(t1.country_name,'其他区县') as country_name
,coalesce(t2.apply_bal,0) as apply_bal
,coalesce(t2.apply_qty,0) as apply_qty
,t1.accum_bal
,t1.accum_cust
,t1.guar_bal
,t1.guar_cust
,t1.lsday_inc_bal
,t1.yd_inc_cust
,t1.lsmn_inc_bal
,t1.lsmn_inc_cust
,t1.year_inc_bal
,t1.year_inc_cust
,t1.loan_bal  -- mdy 20221014 wyx
,t1.loan_qty  -- mdy 20221014 wyx
,t1.rel_guar_bal
,t1.rel_guar_qty  -- mdy 20221014 wyx
,t1.comp_loan_amt -- mdy 20240301
,t1.comp_bal
,t1.portrait_comp_bal -- +20230613 累计代偿金额(不考虑分险)
,t1.comp_qty
,t1.plant_accum_bal
,t1.plant_accum_qty
from
(
	select
	'${v_sdate}' as day_id          --  数据日期
	,city_cd  as city_code          -- 地市
	,t2.area_name  as city_name     -- 地市名称
	,coalesce(t1.country_cd,concat(substr(t1.city_cd,1,4),'99')) as country_code  -- 区县  -- mdy 20221014 wyx
	,t3.area_name as country_name  -- 区县名称  -- mdy 20221014 wyx
	,sum(accum_bal) as accum_bal        -- 累保金额
	,sum(accum_cust) as accum_cust  -- 累保户数	
	,sum(guar_bal)  as guar_bal         -- 在保金额
	,sum(guar_cust) as guar_cust    -- 在保户数	
	,sum(td_inc_bal) as lsday_inc_bal   -- 昨日新增金额
	,sum(td_inc_cust) as yd_inc_cust   -- 昨日新增户数	
	,sum(lsmn_inc_bal) as lsmn_inc_bal  -- 上月新增金额
	,sum(lsmn_inc_cust) as lsmn_inc_cust  -- 上月新增户数	
	,sum(ty_inc_bal)  as year_inc_bal   --   今年来新增金额
	,sum(ty_inc_cust) as year_inc_cust -- 当年新增户数	
	,sum(t1.loan_bal)  as loan_bal -- 累计放款金额 -- mdy 20221014 wyx
	,sum(t1.loan_qty) as loan_qty  -- 累计放款笔数 -- mdy 20221014 wyx	
	,sum(clsd_bal)   as rel_guar_bal  --   解保金额 -- mdy 20221014 wyx
	,sum(t1.rel_guar_qty) as rel_guar_qty -- 累计解保户数 -- mdy 20221014 wyx
    ,sum(t1.comp_loan_amt) as comp_loan_amt -- 累计代偿合同金额 mdy 20240301
	,sum(compt_bal)  as comp_bal    -- 代偿金额(考虑分险)
    ,sum(t1.portrait_comp_bal) as portrait_comp_bal  -- 代偿金额(不考虑分险) + 20230613 zhangfl
	,sum(t1.compt_qty) as comp_qty   -- 累计代偿户数 -- mdy 20221017
    ,sum(case when t1.guar_type = '01' then t1.accum_bal else 0 end) as plant_accum_bal  -- 国担粮食种植类累保金额  +20230417
    ,sum(case when t1.guar_type = '01' then t1.accum_cust else 0 end) as plant_accum_qty       -- 国担粮食种植类笔数      +20230417

	from dw_base.dws_guar_stat t1
	left join dw_base.dim_area_info t2  -- mdy 20220518 wyx
	on t1.city_cd = t2.area_cd
	and t2.area_lvl = '2'
	left join dw_base.dim_area_info t3  -- mdy 20221014 wyx
	on t1.country_cd = t3.area_cd
	and t3.area_lvl = '3'
	where t1.day_id = '${v_sdate}'
	group by
	city_cd  -- 地市
	,country_cd  -- 区县
) t1
left join dw_tmp.tmp_ads_show_guar_accum_info_apply t2
on t1.city_code = t2.city_cd
and t1.country_code = t2.country_cd
;
commit ;