-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250427
-- 目标表   ：dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat   业务部-担保业务状况统计表(金融局报表)
-- 源表     ：
--          新业务系统
--          dw_base.dwd_guar_info_all_his           担保台账信息
--          dw_base.dwd_guar_info_onguar            担保台账在保信息
--          dw_nd.ods_t_biz_project_main            主项目表
--          dw_base.dwd_tjnd_report_biz_loan_bank   国农担上报--银行信息
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 重跑逻辑
delete
from dw_base.ads_rpt_tjnd_busi_cbirc_liability_amt
where day_id = '${v_sdate}';
commit;

-- 创建临时表 存储单户在保余额500万元人民币以下的小微企业 数据
drop table if exists dw_base.tmp_ads_rpt_tjnd_busi_cbirc_liability_amt_500;
create table if not exists dw_base.tmp_ads_rpt_tjnd_busi_cbirc_liability_amt_500
(
    onguar_amt         decimal(32, 2) comment '在保余额(合同金额)',
    reality_onguar_amt decimal(32, 2) comment '实际在保余额',
    liability_amt      decimal(32, 2) comment '融资担保责任余额'
) comment '单户在保余额500万元人民币以下的小微企业';
commit;
-- 插入数据
insert into dw_base.tmp_ads_rpt_tjnd_busi_cbirc_liability_amt_500
select sum(sum_onguar_amt)        as onguar_amt,
       sum(reality_onguar_amt)    as reality_onguar_amt,
       sum(sum_onguar_amt) * 0.75 as liability_amt
from (
         select cert_no,
                sum(onguar_amt)                      sum_onguar_amt,
                sum(onguar_amt * tjnd_risk / 100) as reality_onguar_amt
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  left join
              (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t2 on t1.guar_id = t2.guar_id
                  left join
              (
                  select biz_no, tjnd_risk
                  from dw_base.dwd_tjnd_report_biz_loan_bank
                  where day_id = '${v_sdate}'
              ) t3 on t1.guar_id = t3.biz_no
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 03 小型企业 04 微型企业
                    and enterprise_scale in ('03', '04')
              ) t4 on t1.guar_id = t4.code
         group by cert_no
     ) t1
where sum_onguar_amt < 500;
commit;


-- 创建临时表 存储 单户在保余额200万元人民币以下的农户 数据
drop table if exists dw_base.tmp_ads_rpt_tjnd_busi_cbirc_liability_amt_200;
create table if not exists dw_base.tmp_ads_rpt_tjnd_busi_cbirc_liability_amt_200
(
    onguar_amt         decimal(32, 2) comment '在保余额(合同金额)',
    reality_onguar_amt decimal(32, 2) comment '实际在保余额',
    liability_amt      decimal(32, 2) comment '融资担保责任余额'
) comment '单户在保余额200万元人民币以下的农户';
commit;
-- 插入数据
insert into dw_base.tmp_ads_rpt_tjnd_busi_cbirc_liability_amt_200
select sum(sum_onguar_amt)        as onguar_amt,
       sum(reality_onguar_amt)    as reality_onguar_amt,
       sum(sum_onguar_amt) * 0.75 as liability_amt
from (
         select cert_no,
                sum(onguar_amt)                      sum_onguar_amt,
                sum(onguar_amt * tjnd_risk / 100) as reality_onguar_amt
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    -- 个人客户
                    and cust_type = '自然人'
              ) t1
                  left join
              (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t2 on t1.guar_id = t2.guar_id
                  left join
              (
                  select biz_no, tjnd_risk
                  from dw_base.dwd_tjnd_report_biz_loan_bank
                  where day_id = '${v_sdate}'
              ) t3 on t1.guar_id = t3.biz_no
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否农户为是
                    and is_farmer = 1
              ) t4 on t1.guar_id = t4.code
         group by cert_no
     ) t1
where sum_onguar_amt < 200;
commit;

-- 1.借款类担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_liability_amt
(day_id, -- 数据日期
 proj_name, -- 项目名称
 onguar_amt, -- 在保余额(合同金额)
 reality_onguar_amt, -- 实际在保余额
 weight, -- 权重
 liability_amt -- 融资担保责任余额
)
select '${v_sdate}'                                                            as day_id,
       '1.借款类担保'                                                               as proj_name,
       t1.onguar_amt                                                              onguar_amt,
       t1.reality_onguar_amt                                                   as reality_onguar_amt,
       null                                                                    as weight,
       -- 单户在保余额500万元人民币以下的小微企业 责任余额 +单户在保余额200万元人民币以下的农户 责任余额 +其他借款类担保 责任余额
       t2.liability_amt + t3.liability_amt +
           -- 计算其他借款类担保 融资担保责任余额 由于权重为100% 所以 融资担保责任余额 = 实际在保余额
       (t1.reality_onguar_amt - t2.reality_onguar_amt - t3.reality_onguar_amt) as liability_amt

from (
         select sum(onguar_amt)                      onguar_amt,
                sum(onguar_amt * tjnd_risk / 100) as reality_onguar_amt
         from (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  left join
              (
                  select biz_no, tjnd_risk
                  from dw_base.dwd_tjnd_report_biz_loan_bank
                  where day_id = '${v_sdate}'
              ) t2 on t1.guar_id = t2.biz_no
     ) t1,
     -- 单户在保余额500万元人民币以下的小微企业
     dw_base.tmp_ads_rpt_tjnd_busi_cbirc_liability_amt_500 t2,
     -- 单户在保余额200万元人民币以下的农户
     dw_base.tmp_ads_rpt_tjnd_busi_cbirc_liability_amt_200 t3;
commit;
-- 1.1单户在保余额500万元人民币以下的小微企业
insert into dw_base.ads_rpt_tjnd_busi_cbirc_liability_amt
(day_id, -- 数据日期
 proj_name, -- 项目名称
 onguar_amt, -- 在保余额(合同金额)
 reality_onguar_amt, -- 实际在保余额
 weight, -- 权重
 liability_amt -- 融资担保责任余额
)
select '${v_sdate}'               as day_id,
       '1.1单户在保余额500万元人民币以下的小微企业' as proj_name,
       t1.onguar_amt              as onguar_amt,
       t1.reality_onguar_amt      as reality_onguar_amt,
       '75%'                      as weight,
       t1.liability_amt           as liability_amt
from
    -- 单户在保余额500万元人民币以下的小微企业
    dw_base.tmp_ads_rpt_tjnd_busi_cbirc_liability_amt_500 t1;
commit;
-- 1.2单户在保余额200万元人民币以下的农户
insert into dw_base.ads_rpt_tjnd_busi_cbirc_liability_amt
(day_id, -- 数据日期
 proj_name, -- 项目名称
 onguar_amt, -- 在保余额(合同金额)
 reality_onguar_amt, -- 实际在保余额
 weight, -- 权重
 liability_amt -- 融资担保责任余额
)
select '${v_sdate}'             as day_id,
       '1.2单户在保余额200万元人民币以下的农户' as proj_name,
       t1.onguar_amt            as onguar_amt,
       t1.reality_onguar_amt    as reality_onguar_amt,
       '75%'                    as weight,
       t1.liability_amt         as liability_amt
from
    -- 单户在保余额200万元人民币以下的农户
    dw_base.tmp_ads_rpt_tjnd_busi_cbirc_liability_amt_200 t1;
commit;
-- 1.3住房置业担保业务
insert into dw_base.ads_rpt_tjnd_busi_cbirc_liability_amt
(day_id, -- 数据日期
 proj_name, -- 项目名称
 onguar_amt, -- 在保余额(合同金额)
 reality_onguar_amt, -- 实际在保余额
 weight, -- 权重
 liability_amt -- 融资担保责任余额
)
select '${v_sdate}'  as day_id,
       '1.3住房置业担保业务' as proj_name,
       0             as onguar_amt,
       0             as reality_onguar_amt,
       '30%'         as weight,
       0             as liability_amt;
commit;
-- 1.4其他借款类担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_liability_amt
(day_id, -- 数据日期
 proj_name, -- 项目名称
 onguar_amt, -- 在保余额(合同金额)
 reality_onguar_amt, -- 实际在保余额
 weight, -- 权重
 liability_amt -- 融资担保责任余额
)
select '${v_sdate}'                                                          as day_id,
       '1.4其他借款类担保'                                                          as proj_name,
       t1.onguar_amt - t2.onguar_amt - t3.onguar_amt                            onguar_amt,
       t1.reality_onguar_amt - t2.reality_onguar_amt - t3.reality_onguar_amt as reality_onguar_amt,
       '100%'                                                                as weight,
       -- 计算其他借款类担保 融资担保责任余额 由于权重为100% 所以 融资担保责任余额 = 实际在保余额
       t1.reality_onguar_amt - t2.reality_onguar_amt - t3.reality_onguar_amt as liability_amt

from (
         select sum(onguar_amt)                      onguar_amt,
                sum(onguar_amt * tjnd_risk / 100) as reality_onguar_amt
         from (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  left join
              (
                  select biz_no, tjnd_risk
                  from dw_base.dwd_tjnd_report_biz_loan_bank
                  where day_id = '${v_sdate}'
              ) t2 on t1.guar_id = t2.biz_no
     ) t1,
     -- 单户在保余额500万元人民币以下的小微企业
     dw_base.tmp_ads_rpt_tjnd_busi_cbirc_liability_amt_500 t2,
     -- 单户在保余额200万元人民币以下的农户
     dw_base.tmp_ads_rpt_tjnd_busi_cbirc_liability_amt_200 t3;
commit;
-- 2.发行债券担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_liability_amt
(day_id, -- 数据日期
 proj_name, -- 项目名称
 onguar_amt, -- 在保余额(合同金额)
 reality_onguar_amt, -- 实际在保余额
 weight, -- 权重
 liability_amt -- 融资担保责任余额
)
select '${v_sdate}' as day_id,
       '2.发行债券担保'   as proj_name,
       0            as onguar_amt,
       0            as reality_onguar_amt,
       null         as weight,
       0            as liability_amt;
commit;
-- 2.1主体信用评级AA级以上
insert into dw_base.ads_rpt_tjnd_busi_cbirc_liability_amt
(day_id, -- 数据日期
 proj_name, -- 项目名称
 onguar_amt, -- 在保余额(合同金额)
 reality_onguar_amt, -- 实际在保余额
 weight, -- 权重
 liability_amt -- 融资担保责任余额
)
select '${v_sdate}'     as day_id,
       '2.1主体信用评级AA级以上' as proj_name,
       0                as onguar_amt,
       0                as reality_onguar_amt,
       '80%'            as weight,
       0                as liability_amt;
commit;
-- 2.2其他发行债券担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_liability_amt
(day_id, -- 数据日期
 proj_name, -- 项目名称
 onguar_amt, -- 在保余额(合同金额)
 reality_onguar_amt, -- 实际在保余额
 weight, -- 权重
 liability_amt -- 融资担保责任余额
)
select '${v_sdate}'  as day_id,
       '2.2其他发行债券担保' as proj_name,
       0             as onguar_amt,
       0             as reality_onguar_amt,
       '80%'         as weight,
       0             as liability_amt;
commit;
-- 3.其他融资担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_liability_amt
(day_id, -- 数据日期
 proj_name, -- 项目名称
 onguar_amt, -- 在保余额(合同金额)
 reality_onguar_amt, -- 实际在保余额
 weight, -- 权重
 liability_amt -- 融资担保责任余额
)
select '${v_sdate}'  as day_id,
       '2.2其他发行债券担保' as proj_name,
       0             as onguar_amt,
       0             as reality_onguar_amt,
       '80%'         as weight,
       0             as liability_amt;
commit;
-- 4.合计
insert into dw_base.ads_rpt_tjnd_busi_cbirc_liability_amt
(day_id, -- 数据日期
 proj_name, -- 项目名称
 onguar_amt, -- 在保余额(合同金额)
 reality_onguar_amt, -- 实际在保余额
 weight, -- 权重
 liability_amt -- 融资担保责任余额
)
select '${v_sdate}'                                                            as day_id,
       '4.合计'                                                                  as proj_name,
       t1.onguar_amt                                                              onguar_amt,
       t1.reality_onguar_amt                                                   as reality_onguar_amt,
       null                                                                    as weight,
       -- 单户在保余额500万元人民币以下的小微企业 责任余额 +单户在保余额200万元人民币以下的农户 责任余额 +其他借款类担保 责任余额
       t2.liability_amt + t3.liability_amt +
           -- 计算其他借款类担保 融资担保责任余额 由于权重为100% 所以 融资担保责任余额 = 实际在保余额
       (t1.reality_onguar_amt - t2.reality_onguar_amt - t3.reality_onguar_amt) as liability_amt

from (
         select sum(onguar_amt)                      onguar_amt,
                sum(onguar_amt * tjnd_risk / 100) as reality_onguar_amt
         from (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  left join
              (
                  select biz_no, tjnd_risk
                  from dw_base.dwd_tjnd_report_biz_loan_bank
                  where day_id = '${v_sdate}'
              ) t2 on t1.guar_id = t2.biz_no
     ) t1,
     -- 单户在保余额500万元人民币以下的小微企业
     dw_base.tmp_ads_rpt_tjnd_busi_cbirc_liability_amt_500 t2,
     -- 单户在保余额200万元人民币以下的农户
     dw_base.tmp_ads_rpt_tjnd_busi_cbirc_liability_amt_200 t3;
commit;

