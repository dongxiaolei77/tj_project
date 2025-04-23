-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220119
-- 目标表   ：dw_base.dws_guar_stat 担保业务汇总表
-- 源表     ：dw_base.dwd_guar_info_stat 担保台账星型表,dw_nd.ods_imp_portrait_info_new 画像系统数据同步_new
--            dw_nd.ods_t_proj_comp_aply 代偿信息
--            dw_nd.ods_t_proj_comp_appropriation 代偿拨付信息
-- 变更记录 ：20220119:统一变动 
--			  20220427 增加实收代偿款,实收分险金,实收补偿款，回款金额 = 实收代偿款 + 实收分险金 + 实收补偿款，目标表代偿金额改为：代偿金额 = 代偿金额 - 回款金额
--            20221014 增加解保户数、累计放款笔数、累计放款金额、累计代偿户数
--            20230613 增加字段：不考虑分险的代偿金额 zhangfl
--            20230815 修改逻辑：代偿金额、代偿笔数从担保业务系统出，不再从画像系统出 zhangfl
-- ---------------------------------------
drop table if exists dw_base.tmp_dws_guar_stat_compt;
commit;

create table dw_base.tmp_dws_guar_stat_compt
(
    guar_id   varchar(50),
    compt_bal decimal(18, 4),
    index (guar_id)
) engine = InnoDB
  default charset = utf8mb4
  collate = utf8mb4_bin
  row_format = dynamic;

commit;

-- del 20230815
-- insert into dw_base.tmp_dws_guar_stat_compt
-- select
-- seq_id 
-- ,s_compt_amt
-- from dw_nd.ods_imp_portrait_info_new
-- where s_risk_stt = '已代偿' 

-- and  date_format(create_time,'%Y%m%d') <='${v_sdate}'  -- mdy

insert into dw_base.tmp_dws_guar_stat_compt
select t1.proj_code           as guar_id
     , t2.approp_totl / 10000 as compt_bal
from (
         select id, proj_code, status
         from (
                  select id
                       , project_id
                       , proj_code
                       , status
                       , row_number() over (partition by project_id order by db_update_time desc) as rn
                  from dw_nd.ods_t_proj_comp_aply
              ) a
         where rn = 1
     ) t1 -- 代偿信息
         left join (
    select comp_id, approp_totl
    from (
             select comp_id
                  , approp_totl
                  , row_number() over (partition by comp_id order by db_update_time desc) as rn
             from dw_nd.ods_t_proj_comp_appropriation
         ) a
    where rn = 1
) t2 -- 代偿拨付信息
                   on t2.comp_id = t1.id
where t1.status = '50' -- 已代偿
;
commit;


-- 创建临时表，取最新日期数据，获取实收代偿款

drop table if exists dw_base.tmp_dws_guar_stat_return_amt;
commit; -- mdy 20220427 wyx

create table dw_base.tmp_dws_guar_stat_return_amt
(
    serial_id  varchar(100),
    return_amt decimal(18, 4),
    key idx_tmp_dws_guar_stat_return_amt_serial_id (serial_id)
) engine = InnoDB
  default charset = utf8mb4
  collate = utf8mb4_bin;
commit;


insert into dw_base.tmp_dws_guar_stat_return_amt
( serial_id
, return_amt)
select t1.project_id
     , sum(shou_total_amt) / 10000 as shou_total_amt
from (
         select project_id
              , reco_id
              , row_number() over (partition by project_id order by db_update_time desc) as rn
         from dw_nd.ods_t_biz_proj_recovery_record -- 追偿记录表
     ) t1
         left join (
    select record_id
         , shou_total_amt
         , row_number() over (partition by detail_id order by db_update_time desc) as rn
    from dw_nd.ods_t_biz_proj_recovery_repay_detail_record --  登记还款记录
) t2
                   on t1.reco_id = t2.record_id and t2.rn = 1
where t1.rn = 1
group by t1.project_id
;
-- select
-- 	serial_id
-- 	,return_amt/10000 as return_amt
-- from
-- (
-- select 
-- 	serial_id
-- 	,return_amt
-- from dw_nd.ods_yd_v_ods_f_yw_zcmx order by update_time desc
-- ) t1
-- group by serial_id

;
commit;


-- 创建临时表，取最新日期数据，获取实收分险金、实收补偿款
# drop table if exists dw_base.tmp_dws_guar_stat_risk_amt ; commit; -- mdy 20220427 wyx
#
# create table dw_base.tmp_dws_guar_stat_risk_amt(
# serial_id   varchar(100) ,
# gov_risk_pay_amt decimal(18,4) ,
# re_guar_risk_amt decimal(18,4) ,
# key idx_tmp_dws_guar_stat_risk_amt_serial_id (serial_id)
# )ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
# commit ;
#
#
# insert into dw_base.tmp_dws_guar_stat_risk_amt
# (
# serial_id
# ,gov_risk_pay_amt
# ,re_guar_risk_amt
# )
# select
# 	serial_id
# 	,gov_risk_pay_amt/10000 as gov_risk_pay_amt
# 	,re_guar_risk_amt/10000 as re_guar_risk_amt
# from
# (
# select
# 	serial_id
# 	,gov_risk_pay_amt -- 政府已分险额
# 	,re_guar_risk_amt -- 国家农担再担保业务分险金额
# from dw_nd.ods_yd_v_ods_f_yw_fxxxwh order by update_time desc
# ) t1
# group by serial_id
# ;commit;


delete
from dw_base.dws_guar_stat
where day_id = '${v_sdate}';
commit;

insert into dw_base.dws_guar_stat
(day_id,
 city_cd,
 country_cd,
 cust_type,
 guar_type,
 bank_type,
 loan_scale,
 accum_cust,
 guar_cust,
 lsmn_inc_cust,
 td_inc_cust,
 tmn_inc_cust,
 ty_inc_cust,
 accum_bal,
 guar_bal,
 lsmn_inc_bal,
 td_inc_bal,
 tmn_inc_bal,
 ty_inc_bal,
 compt_bal,
 portrait_comp_bal,
 compt_qty,
 clsd_bal,
 rel_guar_qty,
 comp_loan_amt,
 loan_qty,
 loan_bal
 )
select '${v_sdate}'
     , city_code                                                                          -- 地市 dim_org_info
     , country_code                                                                       -- 县区
     , cust_class_code                                                                    -- 业务主体（dim_cust_class）
     , guar_code                                                                          -- 产业分布 （dim_guar_class）
     , bank_code                                                                          -- 合作银行(dim_bank_class)
     , loan_scale                                                                         -- 100-300万
     , sum(1)                                                                             -- 累保户数
     , sum(case
               when item_stt_code = '06'
                   then 1
               else 0 end)                                                                -- 在保户数

     , sum(case
               when substr(loan_reg_dt, 1, 6) = date_format(DATE_SUB('${v_sdate}', interval 1 month), '%Y%m')
                   then 1
               else 0 end)                                                                -- 上月新增户数

     , sum(case
               when substr(loan_reg_dt, 1, 8) = '${v_sdate}'
                   then 1
               else 0 end)                                                                -- 昨日新增户数 20210426 改为本日新增

     , sum(case
               when substr(loan_reg_dt, 1, 6) = date_format('${v_sdate}', '%Y%m')
                   then 1
               else 0 end)                                                                -- 本月新增户数

     , sum(case
               when substr(loan_reg_dt, 1, 4) = date_format('${v_sdate}', '%Y')
                   then 1
               else 0 end)                                                                -- 本年新增户数


     , sum(loan_amt)                                                                      -- 累保金额
     , sum(case
               when item_stt_code = '06'
                   then loan_amt
               else 0 end)                                                                -- 在保金额
     , sum(case
               when substr(loan_reg_dt, 1, 6) = date_format(DATE_SUB('${v_sdate}', interval 1 month), '%Y%m')
                   then loan_amt
               else 0 end)                                                                -- 上月新增金额
     , sum(case
               when substr(loan_reg_dt, 1, 8) = date_format('${v_sdate}', '%Y%m%d')
                   then loan_amt
               else 0 end)                                                                -- 昨日新增金额  20210426 改为本日新增
     , sum(case
               when substr(loan_reg_dt, 1, 6) = date_format('${v_sdate}', '%Y%m')
                   then loan_amt
               else 0 end)                                                                -- 本月新增户金额
     , sum(case
               when substr(loan_reg_dt, 1, 4) = date_format('${v_sdate}', '%Y')
                   then loan_amt
               else 0 end)                                                                -- 本年新增金额
     -- , sum(coalesce(compt_bal,0) - (coalesce(return_amt,0) + coalesce(gov_risk_pay_amt,0) + coalesce(re_guar_risk_amt,0))) -- 代偿金额 -- mdy 20220427 wyx
     , sum(coalesce(compt_bal, 0) - coalesce(return_amt, 0))                              -- 代偿金额 ,缺少分险信息
     , sum(coalesce(compt_bal, 0))                                   as portrait_comp_bal -- 代偿金额（不考虑分险） + 20230613 zhangfl
     , sum(case when compt_bal is not null then 1 else 0 end)        as compt_qty         -- 累计代偿户数 -- mdy 20221014
     , sum(case when item_stt_code = '11' then loan_amt else 0 end)                       -- 解保金额
     , sum(case when item_stt_code = '11' then 1 else 0 end)         as rel_guar_qty      -- 解保笔数 -- mdy 20221014
     , sum(case when compt_bal is not null then loan_amt else 0 end) as comp_loan_amt     -- 代偿合同金额
     , sum(1)                                                        as loan_qty          -- 累计放款笔数 -- mdy 20221014
     , sum(loan_amt)                                                 as loan_bal          -- 累计放款金额 -- mdy 20221014

from (
         select city_code       -- 地市 dim_org_info
              , country_code    -- 县区
              , cust_class_code -- 业务主体（dim_cust_class）
              , guar_code       -- 产业分布 （dim_guar_class）
              , bank_code       -- 合作银行(dim_bank_class)
              , case
                    when (loan_amt >= 0 and loan_amt < 10) or loan_amt is null then '1' -- 0-10万
                    when loan_amt >= 10 and loan_amt <= 50 then '2' -- 10-50万
                    when loan_amt > 50 and loan_amt <= 100 then '3' -- 50-100万
                    when loan_amt > 100 and loan_amt <= 300 then '4' -- 100-300万
                    when loan_amt > 300 then '5' -- 300万以上
             end loan_scale     -- 100-300万
              , t1.item_stt_code
              , loan_reg_dt
              , loan_amt
              , t2.compt_bal
              , t3.return_amt
              , t4.gov_risk_pay_amt
              , t4.re_guar_risk_amt
         from dw_base.dwd_guar_info_stat t1
                  left join dw_base.tmp_dws_guar_stat_compt t2 -- mdy 20220427 wyx
                            on t1.guar_id = t2.guar_id
                  left join dw_base.tmp_dws_guar_stat_return_amt t3 -- mdy 20220427 wyx
                            on t1.guar_id = t3.serial_id
                  left join dw_base.tmp_dws_guar_stat_risk_amt t4 -- mdy 20220427 wyx
                            on t1.guar_id = t4.serial_id
         where item_stt_code in ('06', '11', '12') -- 已放款 已解保 代偿 -- mdy 20211122
     ) t
group by city_code       -- 地市
       , country_code
       , cust_class_code -- 业务主体（dim_cust_class）
       , guar_code       -- 产业分布 （dim_guar_class）
       , bank_code       -- 合作银行(dim_bank_class)
       , loan_scale
;
commit;