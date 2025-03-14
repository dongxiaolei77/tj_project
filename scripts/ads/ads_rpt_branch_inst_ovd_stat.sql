-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250221
-- 目标表   ：dw_base.ads_rpt_branch_inst_ovd_stat 省级农担公司分支机构逾期情况统计季报
-- 源表     ：逾期台账 目前暂未抽取
-- dw_guar_info_all 待问题解决后进行抽数
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- step0 重跑策略
delete
from dw_base.ads_rpt_branch_inst_ovd_stat
where day_id = '${v_sdate}';
commit;


-- 处理逾期数据

-- 处理在保数据


-- 删除非当前季度前10天数据
delete
from dw_base.ads_rpt_branch_inst_ovd_stat
where day_id = '${v_sdate}'
   or day_id between MAKEDATE(YEAR('${v_sdate}'), 1) + interval (QUARTER('${v_sdate}') - 1) * 3 month and
        MAKEDATE(YEAR('${v_sdate}'), 1) + interval (QUARTER('${v_sdate}') - 1) * 3 month + interval 9 day;;
commit;

