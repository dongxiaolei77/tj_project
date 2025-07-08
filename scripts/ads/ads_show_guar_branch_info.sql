-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220119
-- 目标表   ：dw_base.ads_show_guar_branch_info  大屏-分支机构分布信息
-- 源表     ：dw_base.dws_guar_stat  担保业务汇总表
-- 变更记录 ：
-- ---------------------------------------
delete
from dw_base.ads_show_guar_branch_info
where day_id = '${v_sdate}';
commit;

insert into dw_base.ads_show_guar_branch_info
( day_id
, branch_office
, guar_cust
, guar_bal
, accum_guar_qty
, accum_guar_bal)
select '${v_sdate}'
     , branch_office
     , sum(guar_cust)  as guar_qty       -- 目前在保户数
     , sum(guar_bal)   as guar_bal       -- 目前在保金额
     , sum(accum_cust) as accum_guar_qty -- 累计担保笔数	  -- mdy 20221017 wyx
     , sum(accum_bal)  as accum_guar_bal -- 累计担保金额	  -- mdy 20221017 wyx
from dw_base.dws_guar_stat t1
where t1.day_id = '${v_sdate}'
group by t1.branch_office
;
commit;