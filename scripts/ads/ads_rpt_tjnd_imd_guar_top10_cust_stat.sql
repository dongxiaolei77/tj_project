-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250423
-- 目标表   ：dw_base.ads_rpt_tjnd_imd_guar_top10_cust_stat    综合部-地方金融组织最大10家客户（含集团）集中度统计表
-- 源表     ：
--          新业务系统
--          dw_base.dwd_guar_info_all             担保台账信息
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 重跑策略
delete
from dw_base.ads_rpt_tjnd_imd_guar_top10_cust_stat
where day_id = '${v_sdate}';
commit;

-- 插入数据
insert into dw_base.ads_rpt_tjnd_imd_guar_top10_cust_stat
(day_id, -- 数据日期
 cust_name, -- 客户名称
 cert_no, -- 证件号码
 is_group_cust, -- 是否为集团客户
 guar_amt, -- 担保金额(万元)
 credit_risk_amt -- 信用风险敞口
)
select '${v_sdate}'  as day_id,
       cust_name,
       cert_no,
       '0'           as is_group_cust,
       sum(guar_amt) as guar_amt,
       sum(guar_amt) as credit_risk_amt
from dw_base.dwd_guar_info_all
where day_id = '${v_sdate}'
  and data_source = '担保业务管理系统新'
  and cust_type = '法人或其他组织'
group by cust_name, cert_no
order by guar_amt desc
limit 10;
commit;