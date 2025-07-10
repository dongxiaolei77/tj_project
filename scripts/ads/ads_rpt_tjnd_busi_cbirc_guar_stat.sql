-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250424
-- 目标表   ：dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat   业务部-担保业务状况统计表(金融局报表)
-- 源表     ：
--          新业务系统
--          dw_base.dwd_guar_info_all               担保台账信息
--          dw_base.dwd_guar_info_all_his           担保台账信息
--          dw_base.dwd_guar_info_stat              担保台账星形表
--          dw_nd.ods_t_biz_proj_repayment_detail   还款信息表
--          dw_base.dwd_guar_compt_info_his         代偿信息汇总表
--          dw_base.dwd_guar_info_onguar            担保台账在保信息
--          dw_nd.ods_t_biz_project_main            主项目表
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 重跑策略
delete
from dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
where day_id = '${v_sdate}';
commit;
-- 1.1担保金额小计
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}' as day_id,
       '1.融资担保业务'   as proj_name,
       '1.1担保金额小计'  as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select sum(onguar_amt) as start_num -- 在保余额(万元)
         from dw_base.dwd_guar_info_onguar
              -- 取数据日期为上上月底
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
     ) t1,
     ( -- 本期增加(发生额)
         select sum(guar_amt) as now_add_num -- 放款金额(万元)
         from dw_base.dwd_guar_info_all_his
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
           and date_format(loan_reg_dt, '%Y%m') =
               DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
     ) t2,
     ( -- 本期减少(发生额)
         select sum(if(t3.biz_no is not null, coalesce(t1.guar_amt, 0),
                       coalesce(t4.repayment_amount, 0))) as now_reduce_num
         from (
                  select guar_id,
                         guar_amt -- 放款金额(万元) 解保了对应解保金额
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  left join
              dw_base.dwd_guar_info_stat t2 on t1.guar_id = t2.guar_id
                  left join
              (
                  select biz_no
                  from dw_base.dwd_guar_biz_unguar_info
                  where day_id = '${v_sdate}'
                    and biz_unguar_reason = '合同解保'
                    -- 解保日期为当期
                    and date_format(biz_unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t3 on t1.guar_id = t3.biz_no
                  left join
              (
                  select id,
                         project_id,
                         actual_repayment_amount / 10000 as repayment_amount -- 还款金额(万元)
                  from (select *, row_number() over (partition by id order by db_update_time desc) rn
                        from dw_nd.ods_t_biz_proj_repayment_detail) t1
                  where rn = 1
                    and date_format(repay_date, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t4 on t2.project_id = t4.project_id
     ) t3,
     ( -- 期末数
         select sum(onguar_amt) as end_num -- 在保余额(万元)
         from dw_base.dwd_guar_info_onguar
              -- 取数据日期为上上月底
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
     ) t4;
commit;

-- 1.1.1借款担保
-- 1.1担保金额小计
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}' as day_id,
       '1.融资担保业务'   as proj_name,
       '1.1.1借款担保'  as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select sum(onguar_amt) as start_num -- 在保余额(万元)
         from dw_base.dwd_guar_info_onguar
              -- 取数据日期为上上月底
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
     ) t1,
     ( -- 本期增加(发生额)
         select sum(guar_amt) as now_add_num -- 放款金额(万元)
         from dw_base.dwd_guar_info_all_his
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
           and date_format(loan_reg_dt, '%Y%m') =
               DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
     ) t2,
     ( -- 本期减少(发生额)
         select sum(if(t3.biz_no is not null, coalesce(t1.guar_amt, 0),
                       coalesce(t4.repayment_amount, 0))) as now_reduce_num
         from (
                  select guar_id,
                         guar_amt -- 放款金额(万元) 解保了对应解保金额
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  left join
              dw_base.dwd_guar_info_stat t2 on t1.guar_id = t2.guar_id
                  left join
              (
                  select biz_no
                  from dw_base.dwd_guar_biz_unguar_info
                  where day_id = '${v_sdate}'
                    and biz_unguar_reason = '合同解保'
                    -- 解保日期为当期
                    and date_format(biz_unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t3 on t1.guar_id = t3.biz_no
                  left join
              (
                  select id,
                         project_id,
                         actual_repayment_amount / 10000 as repayment_amount -- 还款金额(万元)
                  from (select *, row_number() over (partition by id order by db_update_time desc) rn
                        from dw_nd.ods_t_biz_proj_repayment_detail) t1
                  where rn = 1
                    and date_format(repay_date, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t4 on t2.project_id = t4.project_id
     ) t3,
     ( -- 期末数
         select sum(onguar_amt) as end_num -- 在保余额(万元)
         from dw_base.dwd_guar_info_onguar
              -- 取数据日期为上上月底
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
     ) t4;
commit;
-- 1.1.1.1贷款担保
-- 1.1担保金额小计
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'  as day_id,
       '1.融资担保业务'    as proj_name,
       '1.1.1.1贷款担保' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select sum(onguar_amt) as start_num -- 在保余额(万元)
         from dw_base.dwd_guar_info_onguar
              -- 取数据日期为上上月底
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
     ) t1,
     ( -- 本期增加(发生额)
         select sum(guar_amt) as now_add_num -- 放款金额(万元)
         from dw_base.dwd_guar_info_all_his
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
           and date_format(loan_reg_dt, '%Y%m') =
               DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
     ) t2,
     ( -- 本期减少(发生额)
         select sum(if(t3.biz_no is not null, coalesce(t1.guar_amt, 0),
                       coalesce(t4.repayment_amount, 0))) as now_reduce_num
         from (
                  select guar_id,
                         guar_amt -- 放款金额(万元) 解保了对应解保金额
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  left join
              dw_base.dwd_guar_info_stat t2 on t1.guar_id = t2.guar_id
                  left join
              (
                  select biz_no
                  from dw_base.dwd_guar_biz_unguar_info
                  where day_id = '${v_sdate}'
                    and biz_unguar_reason = '合同解保'
                    -- 解保日期为当期
                    and date_format(biz_unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t3 on t1.guar_id = t3.biz_no
                  left join
              (
                  select id,
                         project_id,
                         actual_repayment_amount / 10000 as repayment_amount -- 还款金额(万元)
                  from (select *, row_number() over (partition by id order by db_update_time desc) rn
                        from dw_nd.ods_t_biz_proj_repayment_detail) t1
                  where rn = 1
                    and date_format(repay_date, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t4 on t2.project_id = t4.project_id
     ) t3,
     ( -- 期末数
         select sum(onguar_amt) as end_num -- 在保余额(万元)
         from dw_base.dwd_guar_info_onguar
              -- 取数据日期为上上月底
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
     ) t4;
commit;

-- 1.1.1.2票据承兑担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'    as day_id,
       '1.融资担保业务'      as proj_name,
       '1.1.1.2票据承兑担保' as proj_detail,
       0,
       0,
       0,
       0;
commit;
-- 1.1.1.3信用证担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'   as day_id,
       '1.融资担保业务'     as proj_name,
       '1.1.1.3信用证担保' as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 1.1.1.4其他借款担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'    as day_id,
       '1.融资担保业务'      as proj_name,
       '1.1.1.4其他借款担保' as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 1.1.1.4.1其中：综合消费贷款担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'           as day_id,
       '1.融资担保业务'             as proj_name,
       '1.1.1.4.1其中：综合消费贷款担保' as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 1.1.1.4.2其中：住房置业贷款担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'           as day_id,
       '1.融资担保业务'             as proj_name,
       '1.1.1.4.2其中：住房置业贷款担保' as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 1.1.1.4.3其中：互联网借贷担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'          as day_id,
       '1.融资担保业务'            as proj_name,
       '1.1.1.4.3其中：互联网借贷担保' as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 1.1.2发行债券担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'  as day_id,
       '1.融资担保业务'    as proj_name,
       '1.1.2发行债券担保' as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 1.1.3其他融资担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'  as day_id,
       '1.融资担保业务'    as proj_name,
       '1.1.3其他融资担保' as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 1.2担保笔数
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}' as day_id,
       '1.融资担保业务'   as proj_name,
       '1.2担保笔数'    as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.start_num
from ( -- 期初数
         select count(guar_id) as start_num -- 上上月底在保笔数
         from dw_base.dwd_guar_info_all_his
              -- 取数据日期为上上月底
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
           and item_stt = '已放款'
     ) t1,
     ( -- 本期增加(发生额)
         select count(guar_id) as now_add_num -- 上月新增在保笔数
         from dw_base.dwd_guar_info_all_his
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
           and date_format(loan_reg_dt, '%Y%m') =
               DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
           and item_stt = '已放款'
     ) t2,
     ( -- 本期减少(发生额)
         select count(guar_id) as now_reduce_num -- 上月新增解保笔数
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
           and date_format(unguar_dt, '%Y%m') =
               DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
     ) t3,
     ( -- 期末数
         select count(guar_id) as start_num -- 上月底在保笔数
         from dw_base.dwd_guar_info_all_his
              -- 取数据日期为上上月底
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
           and item_stt = '已放款'
     ) t4;
commit;


-- 1.2.1其中：发行债券担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '1.融资担保业务'       as proj_name,
       '1.2.1其中：发行债券担保' as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 1.3担保户数
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}' as day_id,
       '1.融资担保业务'   as proj_name,
       '1.3担保户数'    as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.start_num
from ( -- 期初数
         select count(distinct cert_no) as start_num -- 上上月底在保户数
         from dw_base.dwd_guar_info_all_his
              -- 取数据日期为上上月底
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
           and item_stt = '已放款'
     ) t1,
     ( -- 本期增加(发生额)
         select count(distinct cert_no) as now_add_num -- 上月新增在保户数
         from dw_base.dwd_guar_info_all_his
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
           and date_format(loan_reg_dt, '%Y%m') =
               DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
           and item_stt = '已放款'
     ) t2,
     ( -- 本期减少(发生额)
         select count(distinct cert_no) as now_reduce_num -- 上月新增解保户数
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
           and date_format(unguar_dt, '%Y%m') =
               DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
     ) t3,
     ( -- 期末数
         select count(distinct cert_no) as start_num -- 上月底在保户数
         from dw_base.dwd_guar_info_all_his
              -- 取数据日期为上上月底
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
           and item_stt = '已放款'
     ) t4;
commit;

-- 1.3.1其中：发行债券担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '1.融资担保业务'       as proj_name,
       '1.3.1其中：发行债券担保' as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 1.4代偿金额
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}' as day_id,
       '1.融资担保业务'   as proj_name,
       '1.4代偿金额'    as proj_detail,
       t1.start_num,
       t2.now_add_num,
       0,
       t3.end_num
from (
         -- 期初数
         select sum(compt_amt) as start_num -- 截止至上上月底代偿金额
         from dw_base.dwd_guar_compt_info
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
     ) t1,
     (
         -- 本期增加(发生额)
         select sum(compt_amt) as now_add_num -- 截止至上月底代偿金额
         from dw_base.dwd_guar_compt_info
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
           and date_format(compt_time, '%Y%m') =
               DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
     ) t2,
     (
         -- 期末数
         select sum(compt_amt) as end_num -- 截止至上月底代偿金额
         from dw_base.dwd_guar_compt_info
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
     ) t3;
commit;


-- 1.4.1其中：发行债券担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '1.融资担保业务'       as proj_name,
       '1.4.1其中：发行债券担保' as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 1.5代偿户数
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}' as day_id,
       '1.融资担保业务'   as proj_name,
       '1.5代偿户数'    as proj_detail,
       t1.start_num,
       t2.now_add_num,
       0,
       t3.end_num
from (
         -- 期初数
         select count(distinct cert_no) as start_num -- 截止至上上月底代偿户数
         from dw_base.dwd_guar_compt_info
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
     ) t1,
     (
         -- 本期增加(发生额)
         select count(distinct cert_no) as now_add_num -- 截止至上月底代偿户数
         from dw_base.dwd_guar_compt_info
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
           and date_format(compt_time, '%Y%m') =
               DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
     ) t2,
     (
         -- 期末数
         select count(distinct cert_no) as end_num -- 截止至上月底代偿户数
         from dw_base.dwd_guar_compt_info
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
     ) t3;
commit;


-- 1.5.1其中：发行债券担保户数
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'       as day_id,
       '1.融资担保业务'         as proj_name,
       '1.5.1其中：发行债券担保户数' as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 1.6损失金额
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}' as day_id,
       '1.融资担保业务'   as proj_name,
       '1.6损失金额'    as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 1.6.1其中：发行债券担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '1.融资担保业务'       as proj_name,
       '1.6.1其中：发行债券担保' as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 2.1担保金额小计
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}' as day_id,
       '2.非融资担保业务'  as proj_name,
       '2.1担保金额小计'  as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 2.1.1投标担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}' as day_id,
       '2.非融资担保业务'  as proj_name,
       '2.1.1投标担保'  as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 2.1.2工程履约担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'  as day_id,
       '2.非融资担保业务'   as proj_name,
       '2.1.2工程履约担保' as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 2.1.3诉讼保全担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'  as day_id,
       '2.非融资担保业务'   as proj_name,
       '2.1.3诉讼保全担保' as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 2.1.4其他非融资担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'   as day_id,
       '2.非融资担保业务'    as proj_name,
       '2.1.4其他非融资担保' as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 2.2担保笔数
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}' as day_id,
       '2.非融资担保业务'  as proj_name,
       '2.2担保笔数'    as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 2.3担保户数
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}' as day_id,
       '2.非融资担保业务'  as proj_name,
       '2.3担保户数'    as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 2.4代偿金额
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}' as day_id,
       '2.非融资担保业务'  as proj_name,
       '2.4代偿金额'    as proj_detail,
       0,
       0,
       0,
       0;
commit;
-- 2.5代偿户数
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}' as day_id,
       '2.非融资担保业务'  as proj_name,
       '2.5代偿户数'    as proj_detail,
       0,
       0,
       0,
       0;
commit;
-- 2.6损失金额
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}' as day_id,
       '2.非融资担保业务'  as proj_name,
       '2.6损失金额'    as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 3.1担保金额合计
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}' as day_id,
       '3.担保业务合计'   as proj_name,
       '3.1担保金额合计'  as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select sum(onguar_amt) as start_num -- 在保余额(万元)
         from dw_base.dwd_guar_info_onguar
              -- 取数据日期为上上月底
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
     ) t1,
     ( -- 本期增加(发生额)
         select sum(guar_amt) as now_add_num -- 放款金额(万元)
         from dw_base.dwd_guar_info_all_his
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
           and date_format(loan_reg_dt, '%Y%m') =
               DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
     ) t2,
     ( -- 本期减少(发生额)
         select sum(if(t3.biz_no is not null, coalesce(t1.guar_amt, 0),
                       coalesce(t4.repayment_amount, 0))) as now_reduce_num
         from (
                  select guar_id,
                         guar_amt -- 放款金额(万元) 解保了对应解保金额
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  left join
              dw_base.dwd_guar_info_stat t2 on t1.guar_id = t2.guar_id
                  left join
              (
                  select biz_no
                  from dw_base.dwd_guar_biz_unguar_info
                  where day_id = '${v_sdate}'
                    and biz_unguar_reason = '合同解保'
                    -- 解保日期为当期
                    and date_format(biz_unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t3 on t1.guar_id = t3.biz_no
                  left join
              (
                  select id,
                         project_id,
                         actual_repayment_amount / 10000 as repayment_amount -- 还款金额(万元)
                  from (select *, row_number() over (partition by id order by db_update_time desc) rn
                        from dw_nd.ods_t_biz_proj_repayment_detail) t1
                  where rn = 1
                    and date_format(repay_date, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t4 on t2.project_id = t4.project_id
     ) t3,
     ( -- 期末数
         select sum(onguar_amt) as end_num -- 在保余额(万元)
         from dw_base.dwd_guar_info_onguar
              -- 取数据日期为上上月底
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
     ) t4;
commit;

-- 3.2担保笔数合计
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}' as day_id,
       '3.担保业务合计'   as proj_name,
       '3.2担保笔数合计'  as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.start_num
from ( -- 期初数
         select count(guar_id) as start_num -- 上上月底在保笔数
         from dw_base.dwd_guar_info_all_his
              -- 取数据日期为上上月底
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
           and item_stt = '已放款'
     ) t1,
     ( -- 本期增加(发生额)
         select count(guar_id) as now_add_num -- 上月新增在保笔数
         from dw_base.dwd_guar_info_all_his
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
           and date_format(loan_reg_dt, '%Y%m') =
               DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
           and item_stt = '已放款'
     ) t2,
     ( -- 本期减少(发生额)
         select count(guar_id) as now_reduce_num -- 上月新增解保笔数
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
           and date_format(unguar_dt, '%Y%m') =
               DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
     ) t3,
     ( -- 期末数
         select count(guar_id) as start_num -- 上月底在保笔数
         from dw_base.dwd_guar_info_all_his
              -- 取数据日期为上上月底
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
           and item_stt = '已放款'
     ) t4;
commit;
-- 3.3担保户数合计
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}' as day_id,
       '3.担保业务合计'   as proj_name,
       '3.3担保户数合计'  as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.start_num
from ( -- 期初数
         select count(distinct cert_no) as start_num -- 上上月底在保户数
         from dw_base.dwd_guar_info_all_his
              -- 取数据日期为上上月底
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
           and item_stt = '已放款'
     ) t1,
     ( -- 本期增加(发生额)
         select count(distinct cert_no) as now_add_num -- 上月新增在保户数
         from dw_base.dwd_guar_info_all_his
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
           and date_format(loan_reg_dt, '%Y%m') =
               DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
           and item_stt = '已放款'
     ) t2,
     ( -- 本期减少(发生额)
         select count(distinct cert_no) as now_reduce_num -- 上月新增解保户数
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
           and date_format(unguar_dt, '%Y%m') =
               DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
     ) t3,
     ( -- 期末数
         select count(distinct cert_no) as start_num -- 上月底在保户数
         from dw_base.dwd_guar_info_all_his
              -- 取数据日期为上上月底
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
           and item_stt = '已放款'
     ) t4;
commit;
-- 3.4代偿金额合计
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}' as day_id,
       '3.担保业务合计'   as proj_name,
       '3.4代偿金额合计'  as proj_detail,
       t1.start_num,
       t2.now_add_num,
       0,
       t3.end_num
from (
         -- 期初数
         select sum(compt_amt) as start_num -- 截止至上上月底代偿金额
         from dw_base.dwd_guar_compt_info
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
     ) t1,
     (
         -- 本期增加(发生额)
         select sum(compt_amt) as now_add_num -- 截止至上月底代偿金额
         from dw_base.dwd_guar_compt_info
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
           and date_format(compt_time, '%Y%m') =
               DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
     ) t2,
     (
         -- 期末数
         select sum(compt_amt) as end_num -- 截止至上月底代偿金额
         from dw_base.dwd_guar_compt_info
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
     ) t3;
commit;
-- 3.5代偿户数合计
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}' as day_id,
       '3.担保业务合计'   as proj_name,
       '3.5代偿户数合计'  as proj_detail,
       t1.start_num,
       t2.now_add_num,
       0,
       t3.end_num
from (
         -- 期初数
         select count(distinct cert_no) as start_num -- 截止至上上月底代偿户数
         from dw_base.dwd_guar_compt_info
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
     ) t1,
     (
         -- 本期增加(发生额)
         select count(distinct cert_no) as now_add_num -- 截止至上月底代偿户数
         from dw_base.dwd_guar_compt_info
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
           and date_format(compt_time, '%Y%m') =
               DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
     ) t2,
     (
         -- 期末数
         select count(distinct cert_no) as end_num -- 截止至上月底代偿户数
         from dw_base.dwd_guar_compt_info
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
     ) t3;
commit;

-- 3.6损失金额合计
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}' as day_id,
       '3.担保业务合计'   as proj_name,
       '3.6损失金额合计'  as proj_detail,
       0,
       0,
       0,
       0;
commit;
-- 3.7应代偿未代偿情况
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'  as day_id,
       '3.担保业务合计'    as proj_name,
       '3.7应代偿未代偿情况' as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 4.1政策性融资担保金额
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'   as day_id,
       '4.政策性融资担保业务'  as proj_name,
       '4.1政策性融资担保金额' as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 4.1.1其中：中小微企业
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'    as day_id,
       '4.政策性融资担保业务'   as proj_name,
       '4.1.1其中：中小微企业' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select sum(onguar_amt) as start_num -- 在保余额(万元)
         from (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02 中型企业 03 小型企业 04 微型企业
                    and enterprise_scale in ('02', '03', '04')
              ) t2 on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select sum(guar_amt) as now_add_num -- 放款金额(万元)
         from (
                  select guar_id,
                         guar_amt
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02 中型企业 03 小型企业 04 微型企业
                    and enterprise_scale in ('02', '03', '04')
              ) t2 on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select sum(if(t3.biz_no is not null, coalesce(t1.guar_amt, 0),
                       coalesce(t4.repayment_amount, 0))) as now_reduce_num
         from (
                  select guar_id,
                         guar_amt -- 放款金额(万元) 解保了对应解保金额
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  left join
              dw_base.dwd_guar_info_stat t2 on t1.guar_id = t2.guar_id
                  left join
              (
                  select biz_no
                  from dw_base.dwd_guar_biz_unguar_info
                  where day_id = '${v_sdate}'
                    and biz_unguar_reason = '合同解保'
                    -- 解保日期为当期
                    and date_format(biz_unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t3 on t1.guar_id = t3.biz_no
                  left join
              (
                  select id,
                         project_id,
                         actual_repayment_amount / 10000 as repayment_amount -- 还款金额(万元)
                  from (select *, row_number() over (partition by id order by db_update_time desc) rn
                        from dw_nd.ods_t_biz_proj_repayment_detail) t1
                  where rn = 1
                    and date_format(repay_date, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t4 on t2.project_id = t4.project_id
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02 中型企业 03 小型企业 04 微型企业
                    and enterprise_scale in ('02', '03', '04')
              ) t5 on t1.guar_id = t5.code
     ) t3,
     ( -- 期末数
         select sum(onguar_amt) as end_num -- 在保余额(万元)
         from (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02 中型企业 03 小型企业 04 微型企业
                    and enterprise_scale in ('02', '03', '04')
              ) t2 on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.1.2其中：“三农”主体
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.1.2其中：“三农”主体' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select sum(onguar_amt) as start_num -- 在保余额(万元)
         from (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否农户为是
                    and is_farmer = 1
              ) t2 on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select sum(guar_amt) as now_add_num -- 放款金额(万元)
         from (
                  select guar_id,
                         guar_amt
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否农户为是
                    and is_farmer = 1
              ) t2 on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select sum(if(t3.biz_no is not null, coalesce(t1.guar_amt, 0),
                       coalesce(t4.repayment_amount, 0))) as now_reduce_num
         from (
                  select guar_id,
                         guar_amt -- 放款金额(万元) 解保了对应解保金额
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  left join
              dw_base.dwd_guar_info_stat t2 on t1.guar_id = t2.guar_id
                  left join
              (
                  select biz_no
                  from dw_base.dwd_guar_biz_unguar_info
                  where day_id = '${v_sdate}'
                    and biz_unguar_reason = '合同解保'
                    -- 解保日期为当期
                    and date_format(biz_unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t3 on t1.guar_id = t3.biz_no
                  left join
              (
                  select id,
                         project_id,
                         actual_repayment_amount / 10000 as repayment_amount -- 还款金额(万元)
                  from (select *, row_number() over (partition by id order by db_update_time desc) rn
                        from dw_nd.ods_t_biz_proj_repayment_detail) t1
                  where rn = 1
                    and date_format(repay_date, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t4 on t2.project_id = t4.project_id
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否农户为是
                    and is_farmer = 1
              ) t5 on t1.guar_id = t5.code
     ) t3,
     ( -- 期末数
         select sum(onguar_amt) as end_num -- 在保余额(万元)
         from (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否农户为是
                    and is_farmer = 1
              ) t2 on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.1.3其中：个体工商户
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'    as day_id,
       '4.政策性融资担保业务'   as proj_name,
       '4.1.3其中：个体工商户' as proj_detail,
       0,
       0,
       0,
       0;
commit;

-- 4.1.4其中：战略性新兴产业
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'      as day_id,
       '4.政策性融资担保业务'     as proj_name,
       '4.1.4其中：战略性新兴产业' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select sum(onguar_amt) as start_num -- 在保余额(万元)
         from (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 06对应战略性新兴产业
                    and cust_main_label like '%06%'
              ) t2 on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select sum(guar_amt) as now_add_num -- 放款金额(万元)
         from (
                  select guar_id,
                         guar_amt
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 06对应战略性新兴产业
                    and cust_main_label like '%06%'
              ) t2 on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select sum(if(t3.biz_no is not null, coalesce(t1.guar_amt, 0),
                       coalesce(t4.repayment_amount, 0))) as now_reduce_num
         from (
                  select guar_id,
                         guar_amt -- 放款金额(万元) 解保了对应解保金额
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  left join
              dw_base.dwd_guar_info_stat t2 on t1.guar_id = t2.guar_id
                  left join
              (
                  select biz_no
                  from dw_base.dwd_guar_biz_unguar_info
                  where day_id = '${v_sdate}'
                    and biz_unguar_reason = '合同解保'
                    -- 解保日期为当期
                    and date_format(biz_unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t3 on t1.guar_id = t3.biz_no
                  left join
              (
                  select id,
                         project_id,
                         actual_repayment_amount / 10000 as repayment_amount -- 还款金额(万元)
                  from (select *, row_number() over (partition by id order by db_update_time desc) rn
                        from dw_nd.ods_t_biz_proj_repayment_detail) t1
                  where rn = 1
                    and date_format(repay_date, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t4 on t2.project_id = t4.project_id
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 06对应战略性新兴产业
                    and cust_main_label like '%06%'
              ) t5 on t1.guar_id = t5.code
     ) t3,
     ( -- 期末数
         select sum(onguar_amt) as end_num -- 在保余额(万元)
         from (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 06对应战略性新兴产业
                    and cust_main_label like '%06%'
              ) t2 on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.1.5其中：首贷户担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'    as day_id,
       '4.政策性融资担保业务'   as proj_name,
       '4.1.5其中：首贷户担保' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select sum(onguar_amt) as start_num -- 在保余额(万元)
         from (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否首贷 为是
                    and is_first_loan = 1
              ) t2 on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select sum(guar_amt) as now_add_num -- 放款金额(万元)
         from (
                  select guar_id,
                         guar_amt
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否首贷 为是
                    and is_first_loan = 1
              ) t2 on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select sum(if(t3.biz_no is not null, coalesce(t1.guar_amt, 0),
                       coalesce(t4.repayment_amount, 0))) as now_reduce_num
         from (
                  select guar_id,
                         guar_amt -- 放款金额(万元) 解保了对应解保金额
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  left join
              dw_base.dwd_guar_info_stat t2 on t1.guar_id = t2.guar_id
                  left join
              (
                  select biz_no
                  from dw_base.dwd_guar_biz_unguar_info
                  where day_id = '${v_sdate}'
                    and biz_unguar_reason = '合同解保'
                    -- 解保日期为当期
                    and date_format(biz_unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t3 on t1.guar_id = t3.biz_no
                  left join
              (
                  select id,
                         project_id,
                         actual_repayment_amount / 10000 as repayment_amount -- 还款金额(万元)
                  from (select *, row_number() over (partition by id order by db_update_time desc) rn
                        from dw_nd.ods_t_biz_proj_repayment_detail) t1
                  where rn = 1
                    and date_format(repay_date, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t4 on t2.project_id = t4.project_id
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否首贷 为是
                    and is_first_loan = 1
              ) t5 on t1.guar_id = t5.code
     ) t3,
     ( -- 期末数
         select sum(onguar_amt) as end_num -- 在保余额(万元)
         from (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否首贷 为是
                    and is_first_loan = 1
              ) t2 on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.1.6其中：科技创新担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.1.6其中：科技创新担保' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select sum(onguar_amt) as start_num -- 在保余额(万元)
         from (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02对应科技创新担保
                    and cust_main_label like '%02%'
              ) t2 on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select sum(guar_amt) as now_add_num -- 放款金额(万元)
         from (
                  select guar_id,
                         guar_amt
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02对应科技创新担保
                    and cust_main_label like '%02%'
              ) t2 on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select sum(if(t3.biz_no is not null, coalesce(t1.guar_amt, 0),
                       coalesce(t4.repayment_amount, 0))) as now_reduce_num
         from (
                  select guar_id,
                         guar_amt -- 放款金额(万元) 解保了对应解保金额
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  left join
              dw_base.dwd_guar_info_stat t2 on t1.guar_id = t2.guar_id
                  left join
              (
                  select biz_no
                  from dw_base.dwd_guar_biz_unguar_info
                  where day_id = '${v_sdate}'
                    and biz_unguar_reason = '合同解保'
                    -- 解保日期为当期
                    and date_format(biz_unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t3 on t1.guar_id = t3.biz_no
                  left join
              (
                  select id,
                         project_id,
                         actual_repayment_amount / 10000 as repayment_amount -- 还款金额(万元)
                  from (select *, row_number() over (partition by id order by db_update_time desc) rn
                        from dw_nd.ods_t_biz_proj_repayment_detail) t1
                  where rn = 1
                    and date_format(repay_date, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t4 on t2.project_id = t4.project_id
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02对应科技创新担保
                    and cust_main_label like '%02%'
              ) t5 on t1.guar_id = t5.code
     ) t3,
     ( -- 期末数
         select sum(onguar_amt) as end_num -- 在保余额(万元)
         from (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02对应科技创新担保
                    and cust_main_label like '%02%'
              ) t2 on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.1.7其中：服务绿色产业
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.1.7其中：服务绿色产业' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select sum(onguar_amt) as start_num -- 在保余额(万元)
         from (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 04对应服务绿色产业
                    and cust_main_label like '%04%'
              ) t2 on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select sum(guar_amt) as now_add_num -- 放款金额(万元)
         from (
                  select guar_id,
                         guar_amt
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 04对应服务绿色产业
                    and cust_main_label like '%04%'
              ) t2 on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select sum(if(t3.biz_no is not null, coalesce(t1.guar_amt, 0),
                       coalesce(t4.repayment_amount, 0))) as now_reduce_num
         from (
                  select guar_id,
                         guar_amt -- 放款金额(万元) 解保了对应解保金额
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  left join
              dw_base.dwd_guar_info_stat t2 on t1.guar_id = t2.guar_id
                  left join
              (
                  select biz_no
                  from dw_base.dwd_guar_biz_unguar_info
                  where day_id = '${v_sdate}'
                    and biz_unguar_reason = '合同解保'
                    -- 解保日期为当期
                    and date_format(biz_unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t3 on t1.guar_id = t3.biz_no
                  left join
              (
                  select id,
                         project_id,
                         actual_repayment_amount / 10000 as repayment_amount -- 还款金额(万元)
                  from (select *, row_number() over (partition by id order by db_update_time desc) rn
                        from dw_nd.ods_t_biz_proj_repayment_detail) t1
                  where rn = 1
                    and date_format(repay_date, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t4 on t2.project_id = t4.project_id
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 04对应服务绿色产业
                    and cust_main_label like '%04%'
              ) t5 on t1.guar_id = t5.code
     ) t3,
     ( -- 期末数
         select sum(onguar_amt) as end_num -- 在保余额(万元)
         from (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 04对应服务绿色产业
                    and cust_main_label like '%04%'
              ) t2 on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.1.8其中：服务航运产业
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.1.8其中：服务航运产业' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select sum(onguar_amt) as start_num -- 在保余额(万元)
         from (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 05对应服务航运产业
                    and cust_main_label like '%05%'
              ) t2 on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select sum(guar_amt) as now_add_num -- 放款金额(万元)
         from (
                  select guar_id,
                         guar_amt
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 05对应服务航运产业
                    and cust_main_label like '%05%'
              ) t2 on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select sum(if(t3.biz_no is not null, coalesce(t1.guar_amt, 0),
                       coalesce(t4.repayment_amount, 0))) as now_reduce_num
         from (
                  select guar_id,
                         guar_amt -- 放款金额(万元) 解保了对应解保金额
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  left join
              dw_base.dwd_guar_info_stat t2 on t1.guar_id = t2.guar_id
                  left join
              (
                  select biz_no
                  from dw_base.dwd_guar_biz_unguar_info
                  where day_id = '${v_sdate}'
                    and biz_unguar_reason = '合同解保'
                    -- 解保日期为当期
                    and date_format(biz_unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t3 on t1.guar_id = t3.biz_no
                  left join
              (
                  select id,
                         project_id,
                         actual_repayment_amount / 10000 as repayment_amount -- 还款金额(万元)
                  from (select *, row_number() over (partition by id order by db_update_time desc) rn
                        from dw_nd.ods_t_biz_proj_repayment_detail) t1
                  where rn = 1
                    and date_format(repay_date, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t4 on t2.project_id = t4.project_id
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 05对应服务航运产业
                    and cust_main_label like '%05%'
              ) t5 on t1.guar_id = t5.code
     ) t3,
     ( -- 期末数
         select sum(onguar_amt) as end_num -- 在保余额(万元)
         from (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 05对应服务航运产业
                    and cust_main_label like '%05%'
              ) t2 on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.1.9其中：创业担保贷款
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.1.9其中：创业担保贷款' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select sum(onguar_amt) as start_num -- 在保余额(万元)
         from (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 03对应创业担保贷款
                    and cust_main_label like '%03%'
              ) t2 on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select sum(guar_amt) as now_add_num -- 放款金额(万元)
         from (
                  select guar_id,
                         guar_amt
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 03对应创业担保贷款
                    and cust_main_label like '%03%'
              ) t2 on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select sum(if(t3.biz_no is not null, coalesce(t1.guar_amt, 0),
                       coalesce(t4.repayment_amount, 0))) as now_reduce_num
         from (
                  select guar_id,
                         guar_amt -- 放款金额(万元) 解保了对应解保金额
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  left join
              dw_base.dwd_guar_info_stat t2 on t1.guar_id = t2.guar_id
                  left join
              (
                  select biz_no
                  from dw_base.dwd_guar_biz_unguar_info
                  where day_id = '${v_sdate}'
                    and biz_unguar_reason = '合同解保'
                    -- 解保日期为当期
                    and date_format(biz_unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t3 on t1.guar_id = t3.biz_no
                  left join
              (
                  select id,
                         project_id,
                         actual_repayment_amount / 10000 as repayment_amount -- 还款金额(万元)
                  from (select *, row_number() over (partition by id order by db_update_time desc) rn
                        from dw_nd.ods_t_biz_proj_repayment_detail) t1
                  where rn = 1
                    and date_format(repay_date, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t4 on t2.project_id = t4.project_id
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 03对应创业担保贷款
                    and cust_main_label like '%03%'
              ) t5 on t1.guar_id = t5.code
     ) t3,
     ( -- 期末数
         select sum(onguar_amt) as end_num -- 在保余额(万元)
         from (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 03对应创业担保贷款
                    and cust_main_label like '%03%'
              ) t2 on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.1.10其中：民营经济
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'    as day_id,
       '4.政策性融资担保业务'   as proj_name,
       '4.1.10其中：民营经济' as proj_detail,
       0,
       0,
       0,
       0;
commit;
-- 4.1.11其中：担保费低于1%的担保业务金额
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'              as day_id,
       '4.政策性融资担保业务'             as proj_name,
       '4.1.11其中：担保费低于1%的担保业务金额' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select sum(onguar_amt) as start_num -- 在保余额(万元)
         from (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    -- 担保费率低于1%
                    and guar_rate < 1
              ) t2 on t1.guar_id = t2.guar_id
     ) t1,
     ( -- 本期增加(发生额)
         select sum(guar_amt) as now_add_num -- 放款金额(万元)
         from dw_base.dwd_guar_info_all_his
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
           and date_format(loan_reg_dt, '%Y%m') =
               DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
           -- 担保费率低于1%
           and guar_rate < 1
     ) t2,
     ( -- 本期减少(发生额)
         select sum(if(t3.biz_no is not null, coalesce(t1.guar_amt, 0),
                       coalesce(t4.repayment_amount, 0))) as now_reduce_num
         from (
                  select guar_id,
                         guar_amt -- 放款金额(万元) 解保了对应解保金额
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    -- 担保费率低于1%
                    and guar_rate < 1
              ) t1
                  left join
              dw_base.dwd_guar_info_stat t2 on t1.guar_id = t2.guar_id
                  left join
              (
                  select biz_no
                  from dw_base.dwd_guar_biz_unguar_info
                  where day_id = '${v_sdate}'
                    and biz_unguar_reason = '合同解保'
                    -- 解保日期为当期
                    and date_format(biz_unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t3 on t1.guar_id = t3.biz_no
                  left join
              (
                  select id,
                         project_id,
                         actual_repayment_amount / 10000 as repayment_amount -- 还款金额(万元)
                  from (select *, row_number() over (partition by id order by db_update_time desc) rn
                        from dw_nd.ods_t_biz_proj_repayment_detail) t1
                  where rn = 1
                    and date_format(repay_date, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t4 on t2.project_id = t4.project_id
     ) t3,
     ( -- 期末数
         select sum(onguar_amt) as end_num -- 在保余额(万元)
         from (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    -- 担保费率低于1%
                    and guar_rate < 1
              ) t2 on t1.guar_id = t2.guar_id
     ) t4;
commit;

-- 4.2政策性融资担保笔数合计
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.2政策性融资担保笔数合计' as proj_detail,
       0,
       0,
       0,
       0;
commit;
-- 4.2.1其中：中小微企业
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'    as day_id,
       '4.政策性融资担保业务'   as proj_name,
       '4.2.1其中：中小微企业' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select count(guar_id) as start_num -- 上上月底在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02 中型企业 03 小型企业 04 微型企业
                    and enterprise_scale in ('02', '03', '04')
              ) t2
              on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select count(guar_id) as now_add_num -- 上月新增在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02 中型企业 03 小型企业 04 微型企业
                    and enterprise_scale in ('02', '03', '04')
              ) t2
              on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select count(guar_id) as now_reduce_num -- 上月新增解保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_stat
                  where day_id = '${v_sdate}'
                    and date_format(unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02 中型企业 03 小型企业 04 微型企业
                    and enterprise_scale in ('02', '03', '04')
              ) t2 on t1.guar_id = t2.code
     ) t3,
     ( -- 期末数
         select count(guar_id) as end_num -- 上月底在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02 中型企业 03 小型企业 04 微型企业
                    and enterprise_scale in ('02', '03', '04')
              ) t2
              on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.2.2其中：“三农”主体
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.2.2其中：“三农”主体' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select count(guar_id) as start_num -- 上上月底在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否农户为是
                    and is_farmer = 1
              ) t2
              on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select count(guar_id) as now_add_num -- 上月新增在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否农户为是
                    and is_farmer = 1
              ) t2
              on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select count(guar_id) as now_reduce_num -- 上月新增解保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_stat
                  where day_id = '${v_sdate}'
                    and date_format(unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否农户为是
                    and is_farmer = 1
              ) t2 on t1.guar_id = t2.code
     ) t3,
     ( -- 期末数
         select count(guar_id) as end_num -- 上月底在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否农户为是
                    and is_farmer = 1
              ) t2
              on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.2.3其中：个体工商户
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'    as day_id,
       '4.政策性融资担保业务'   as proj_name,
       '4.2.3其中：个体工商户' as proj_detail,
       0,
       0,
       0,
       0;
commit;
-- 4.2.4其中：战略性新兴产业
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'      as day_id,
       '4.政策性融资担保业务'     as proj_name,
       '4.2.4其中：战略性新兴产业' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select count(guar_id) as start_num -- 上上月底在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 06对应战略性新兴产业
                    and cust_main_label like '%06%'
              ) t2
              on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select count(guar_id) as now_add_num -- 上月新增在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 06对应战略性新兴产业
                    and cust_main_label like '%06%'
              ) t2
              on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select count(guar_id) as now_reduce_num -- 上月新增解保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_stat
                  where day_id = '${v_sdate}'
                    and date_format(unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 06对应战略性新兴产业
                    and cust_main_label like '%06%'
              ) t2 on t1.guar_id = t2.code
     ) t3,
     ( -- 期末数
         select count(guar_id) as end_num -- 上月底在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 06对应战略性新兴产业
                    and cust_main_label like '%06%'
              ) t2
              on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.2.5其中：首贷户担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'    as day_id,
       '4.政策性融资担保业务'   as proj_name,
       '4.2.5其中：首贷户担保' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select count(guar_id) as start_num -- 上上月底在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否首贷 为是
                    and is_first_loan = 1
              ) t2
              on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select count(guar_id) as now_add_num -- 上月新增在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否首贷 为是
                    and is_first_loan = 1
              ) t2
              on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select count(guar_id) as now_reduce_num -- 上月新增解保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_stat
                  where day_id = '${v_sdate}'
                    and date_format(unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否首贷 为是
                    and is_first_loan = 1
              ) t2 on t1.guar_id = t2.code
     ) t3,
     ( -- 期末数
         select count(guar_id) as end_num -- 上月底在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否首贷 为是
                    and is_first_loan = 1
              ) t2
              on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.2.6其中：科技创新担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.2.6其中：科技创新担保' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select count(guar_id) as start_num -- 上上月底在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02对应科技创新担保
                    and cust_main_label like '%02%'
              ) t2
              on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select count(guar_id) as now_add_num -- 上月新增在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02对应科技创新担保
                    and cust_main_label like '%02%'
              ) t2
              on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select count(guar_id) as now_reduce_num -- 上月新增解保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_stat
                  where day_id = '${v_sdate}'
                    and date_format(unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02对应科技创新担保
                    and cust_main_label like '%02%'
              ) t2 on t1.guar_id = t2.code
     ) t3,
     ( -- 期末数
         select count(guar_id) as end_num -- 上月底在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02对应科技创新担保
                    and cust_main_label like '%02%'
              ) t2
              on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.2.7其中：服务绿色产业
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.2.7其中：服务绿色产业' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select count(guar_id) as start_num -- 上上月底在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 04对应服务绿色产业
                    and cust_main_label like '%04%'
              ) t2
              on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select count(guar_id) as now_add_num -- 上月新增在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 04对应服务绿色产业
                    and cust_main_label like '%04%'
              ) t2
              on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select count(guar_id) as now_reduce_num -- 上月新增解保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_stat
                  where day_id = '${v_sdate}'
                    and date_format(unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 04对应服务绿色产业
                    and cust_main_label like '%04%'
              ) t2 on t1.guar_id = t2.code
     ) t3,
     ( -- 期末数
         select count(guar_id) as end_num -- 上月底在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 04对应服务绿色产业
                    and cust_main_label like '%04%'
              ) t2
              on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.2.8其中：服务航运产业
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.2.8其中：服务航运产业' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select count(guar_id) as start_num -- 上上月底在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 05对应服务航运产业
                    and cust_main_label like '%05%'
              ) t2
              on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select count(guar_id) as now_add_num -- 上月新增在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 05对应服务航运产业
                    and cust_main_label like '%05%'
              ) t2
              on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select count(guar_id) as now_reduce_num -- 上月新增解保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_stat
                  where day_id = '${v_sdate}'
                    and date_format(unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 05对应服务航运产业
                    and cust_main_label like '%05%'
              ) t2 on t1.guar_id = t2.code
     ) t3,
     ( -- 期末数
         select count(guar_id) as end_num -- 上月底在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 05对应服务航运产业
                    and cust_main_label like '%05%'
              ) t2
              on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.2.9其中：创业担保贷款
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.2.9其中：创业担保贷款' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select count(guar_id) as start_num -- 上上月底在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 03对应创业担保贷款
                    and cust_main_label like '%03%'
              ) t2
              on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select count(guar_id) as now_add_num -- 上月新增在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 03对应创业担保贷款
                    and cust_main_label like '%03%'
              ) t2
              on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select count(guar_id) as now_reduce_num -- 上月新增解保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_stat
                  where day_id = '${v_sdate}'
                    and date_format(unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 03对应创业担保贷款
                    and cust_main_label like '%03%'
              ) t2 on t1.guar_id = t2.code
     ) t3,
     ( -- 期末数
         select count(guar_id) as end_num -- 上月底在保笔数
         from (
                  select guar_id
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 03对应创业担保贷款
                    and cust_main_label like '%03%'
              ) t2
              on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.2.10其中：民营经济
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'    as day_id,
       '4.政策性融资担保业务'   as proj_name,
       '4.2.10其中：民营经济' as proj_detail,
       0,
       0,
       0,
       0;
commit;
-- 4.3政策性融资担保户数合计
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.3政策性融资担保户数合计' as proj_detail,
       0,
       0,
       0,
       0;
commit;
-- 4.3.1其中：中小微企业
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'    as day_id,
       '4.政策性融资担保业务'   as proj_name,
       '4.3.1其中：中小微企业' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select count(distinct cert_no) as start_num -- 上上月底在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02 中型企业 03 小型企业 04 微型企业
                    and enterprise_scale in ('02', '03', '04')
              ) t2
              on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select count(distinct cert_no) as now_add_num -- 上月新增在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02 中型企业 03 小型企业 04 微型企业
                    and enterprise_scale in ('02', '03', '04')
              ) t2
              on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select count(distinct cert_no) as now_reduce_num -- 上月新增解保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_stat
                  where day_id = '${v_sdate}'
                    and date_format(unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02 中型企业 03 小型企业 04 微型企业
                    and enterprise_scale in ('02', '03', '04')
              ) t2 on t1.guar_id = t2.code
     ) t3,
     ( -- 期末数
         select count(distinct cert_no) as end_num -- 上月底在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02 中型企业 03 小型企业 04 微型企业
                    and enterprise_scale in ('02', '03', '04')
              ) t2
              on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.3.2其中：“三农”主体
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.3.2其中：“三农”主体' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select count(distinct cert_no) as start_num -- 上上月底在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否农户为是
                    and is_farmer = 1
              ) t2
              on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select count(distinct cert_no) as now_add_num -- 上月新增在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否农户为是
                    and is_farmer = 1
              ) t2
              on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select count(distinct cert_no) as now_reduce_num -- 上月新增解保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_stat
                  where day_id = '${v_sdate}'
                    and date_format(unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否农户为是
                    and is_farmer = 1
              ) t2 on t1.guar_id = t2.code
     ) t3,
     ( -- 期末数
         select count(distinct cert_no) as end_num -- 上月底在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否农户为是
                    and is_farmer = 1
              ) t2
              on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.3.3其中：个体工商户
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'    as day_id,
       '4.政策性融资担保业务'   as proj_name,
       '4.3.3其中：个体工商户' as proj_detail,
       0,
       0,
       0,
       0;
commit;
-- 4.3.4其中：战略性新兴产业
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'      as day_id,
       '4.政策性融资担保业务'     as proj_name,
       '4.3.4其中：战略性新兴产业' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select count(distinct cert_no) as start_num -- 上上月底在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 06对应战略性新兴产业
                    and cust_main_label like '%06%'
              ) t2
              on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select count(distinct cert_no) as now_add_num -- 上月新增在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 06对应战略性新兴产业
                    and cust_main_label like '%06%'
              ) t2
              on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select count(distinct cert_no) as now_reduce_num -- 上月新增解保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_stat
                  where day_id = '${v_sdate}'
                    and date_format(unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 06对应战略性新兴产业
                    and cust_main_label like '%06%'
              ) t2 on t1.guar_id = t2.code
     ) t3,
     ( -- 期末数
         select count(distinct cert_no) as end_num -- 上月底在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 06对应战略性新兴产业
                    and cust_main_label like '%06%'
              ) t2
              on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.3.5其中：首贷户担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'    as day_id,
       '4.政策性融资担保业务'   as proj_name,
       '4.3.5其中：首贷户担保' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select count(distinct cert_no) as start_num -- 上上月底在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否首贷 为是
                    and is_first_loan = 1
              ) t2
              on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select count(distinct cert_no) as now_add_num -- 上月新增在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否首贷 为是
                    and is_first_loan = 1
              ) t2
              on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select count(distinct cert_no) as now_reduce_num -- 上月新增解保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_stat
                  where day_id = '${v_sdate}'
                    and date_format(unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否首贷 为是
                    and is_first_loan = 1
              ) t2 on t1.guar_id = t2.code
     ) t3,
     ( -- 期末数
         select count(distinct cert_no) as end_num -- 上月底在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否首贷 为是
                    and is_first_loan = 1
              ) t2
              on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.3.6其中：科技创新担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.3.6其中：科技创新担保' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select count(distinct cert_no) as start_num -- 上上月底在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02对应科技创新担保
                    and cust_main_label like '%02%'
              ) t2
              on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select count(distinct cert_no) as now_add_num -- 上月新增在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02对应科技创新担保
                    and cust_main_label like '%02%'
              ) t2
              on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select count(distinct cert_no) as now_reduce_num -- 上月新增解保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_stat
                  where day_id = '${v_sdate}'
                    and date_format(unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02对应科技创新担保
                    and cust_main_label like '%02%'
              ) t2 on t1.guar_id = t2.code
     ) t3,
     ( -- 期末数
         select count(distinct cert_no) as end_num -- 上月底在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02对应科技创新担保
                    and cust_main_label like '%02%'
              ) t2
              on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.3.7其中：服务绿色产业
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.3.7其中：服务绿色产业' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select count(distinct cert_no) as start_num -- 上上月底在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 04对应服务绿色产业
                    and cust_main_label like '%04%'
              ) t2
              on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select count(distinct cert_no) as now_add_num -- 上月新增在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 04对应服务绿色产业
                    and cust_main_label like '%04%'
              ) t2
              on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select count(distinct cert_no) as now_reduce_num -- 上月新增解保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_stat
                  where day_id = '${v_sdate}'
                    and date_format(unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 04对应服务绿色产业
                    and cust_main_label like '%04%'
              ) t2 on t1.guar_id = t2.code
     ) t3,
     ( -- 期末数
         select count(distinct cert_no) as end_num -- 上月底在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 04对应服务绿色产业
                    and cust_main_label like '%04%'
              ) t2
              on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.3.8其中：服务航运产业
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.3.8其中：服务航运产业' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select count(distinct cert_no) as start_num -- 上上月底在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 05对应服务航运产业
                    and cust_main_label like '%05%'
              ) t2
              on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select count(distinct cert_no) as now_add_num -- 上月新增在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 05对应服务航运产业
                    and cust_main_label like '%05%'
              ) t2
              on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select count(distinct cert_no) as now_reduce_num -- 上月新增解保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_stat
                  where day_id = '${v_sdate}'
                    and date_format(unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 05对应服务航运产业
                    and cust_main_label like '%05%'
              ) t2 on t1.guar_id = t2.code
     ) t3,
     ( -- 期末数
         select count(distinct cert_no) as end_num -- 上月底在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 05对应服务航运产业
                    and cust_main_label like '%05%'
              ) t2
              on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.3.9其中：创业担保贷款
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.3.9其中：创业担保贷款' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select count(distinct cert_no) as start_num -- 上上月底在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 03对应创业担保贷款
                    and cust_main_label like '%03%'
              ) t2
              on t1.guar_id = t2.code
     ) t1,
     ( -- 本期增加(发生额)
         select count(distinct cert_no) as now_add_num -- 上月新增在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 03对应创业担保贷款
                    and cust_main_label like '%03%'
              ) t2
              on t1.guar_id = t2.code
     ) t2,
     ( -- 本期减少(发生额)
         select count(distinct cert_no) as now_reduce_num -- 上月新增解保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_stat
                  where day_id = '${v_sdate}'
                    and date_format(unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 03对应创业担保贷款
                    and cust_main_label like '%03%'
              ) t2 on t1.guar_id = t2.code
     ) t3,
     ( -- 期末数
         select count(distinct cert_no) as end_num -- 上月底在保户数
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 03对应创业担保贷款
                    and cust_main_label like '%03%'
              ) t2
              on t1.guar_id = t2.code
     ) t4;
commit;
-- 4.3.10其中：民营经济
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'    as day_id,
       '4.政策性融资担保业务'   as proj_name,
       '4.3.10其中：民营经济' as proj_detail,
       0,
       0,
       0,
       0;
commit;
-- 4.4代偿金额合计
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'  as day_id,
       '4.政策性融资担保业务' as proj_name,
       '4.4代偿金额合计'   as proj_detail,
       0,
       0,
       0,
       0;
commit;
-- 4.4.1其中：中小微企业
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'    as day_id,
       '4.政策性融资担保业务'   as proj_name,
       '4.4.1其中：中小微企业' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       0,
       t3.end_num
from (
         -- 期初数
         select sum(compt_amt) as start_num -- 截止至上上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02 中型企业 03 小型企业 04 微型企业
                    and enterprise_scale in ('02', '03', '04')
              ) t2 on t1.guar_id = t2.code
     ) t1,
     (
         -- 本期增加(发生额)
         select sum(compt_amt) as now_add_num -- 截止至上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(compt_time, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02 中型企业 03 小型企业 04 微型企业
                    and enterprise_scale in ('02', '03', '04')
              ) t2 on t1.guar_id = t2.code
     ) t2,
     (
         -- 期末数
         select sum(compt_amt) as end_num -- 截止至上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02 中型企业 03 小型企业 04 微型企业
                    and enterprise_scale in ('02', '03', '04')
              ) t2 on t1.guar_id = t2.code
     ) t3;
commit;
-- 4.4.2其中：“三农”主体
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.4.2其中：“三农”主体' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       0,
       t3.end_num
from (
         -- 期初数
         select sum(compt_amt) as start_num -- 截止至上上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否农户为是
                    and is_farmer = 1
              ) t2 on t1.guar_id = t2.code
     ) t1,
     (
         -- 本期增加(发生额)
         select sum(compt_amt) as now_add_num -- 截止至上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(compt_time, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否农户为是
                    and is_farmer = 1
              ) t2 on t1.guar_id = t2.code
     ) t2,
     (
         -- 期末数
         select sum(compt_amt) as end_num -- 截止至上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否农户为是
                    and is_farmer = 1
              ) t2 on t1.guar_id = t2.code
     ) t3;
commit;
-- 4.4.3其中：个体工商户
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'    as day_id,
       '4.政策性融资担保业务'   as proj_name,
       '4.4.3其中：个体工商户' as proj_detail,
       0,
       0,
       0,
       0;
commit;
-- 4.4.4其中：战略性新兴产业
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'      as day_id,
       '4.政策性融资担保业务'     as proj_name,
       '4.4.4其中：战略性新兴产业' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       0,
       t3.end_num
from (
         -- 期初数
         select sum(compt_amt) as start_num -- 截止至上上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 06对应战略性新兴产业
                    and cust_main_label like '%06%'
              ) t2 on t1.guar_id = t2.code
     ) t1,
     (
         -- 本期增加(发生额)
         select sum(compt_amt) as now_add_num -- 截止至上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(compt_time, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 06对应战略性新兴产业
                    and cust_main_label like '%06%'
              ) t2 on t1.guar_id = t2.code
     ) t2,
     (
         -- 期末数
         select sum(compt_amt) as end_num -- 截止至上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 06对应战略性新兴产业
                    and cust_main_label like '%06%'
              ) t2 on t1.guar_id = t2.code
     ) t3;
commit;
-- 4.4.5其中：首贷户担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'    as day_id,
       '4.政策性融资担保业务'   as proj_name,
       '4.4.5其中：首贷户担保' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       0,
       t3.end_num
from (
         -- 期初数
         select sum(compt_amt) as start_num -- 截止至上上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否首贷 为是
                    and is_first_loan = 1
              ) t2 on t1.guar_id = t2.code
     ) t1,
     (
         -- 本期增加(发生额)
         select sum(compt_amt) as now_add_num -- 截止至上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(compt_time, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否首贷 为是
                    and is_first_loan = 1
              ) t2 on t1.guar_id = t2.code
     ) t2,
     (
         -- 期末数
         select sum(compt_amt) as end_num -- 截止至上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否首贷 为是
                    and is_first_loan = 1
              ) t2 on t1.guar_id = t2.code
     ) t3;
commit;
-- 4.4.6其中：科技创新担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.4.6其中：科技创新担保' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       0,
       t3.end_num
from (
         -- 期初数
         select sum(compt_amt) as start_num -- 截止至上上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02对应科技创新担保
                    and cust_main_label like '%02%'
              ) t2 on t1.guar_id = t2.code
     ) t1,
     (
         -- 本期增加(发生额)
         select sum(compt_amt) as now_add_num -- 截止至上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(compt_time, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02对应科技创新担保
                    and cust_main_label like '%02%'
              ) t2 on t1.guar_id = t2.code
     ) t2,
     (
         -- 期末数
         select sum(compt_amt) as end_num -- 截止至上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02对应科技创新担保
                    and cust_main_label like '%02%'
              ) t2 on t1.guar_id = t2.code
     ) t3;
commit;
-- 4.4.7其中：服务绿色产业
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.4.7其中：服务绿色产业' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       0,
       t3.end_num
from (
         -- 期初数
         select sum(compt_amt) as start_num -- 截止至上上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 04对应服务绿色产业
                    and cust_main_label like '%04%'
              ) t2 on t1.guar_id = t2.code
     ) t1,
     (
         -- 本期增加(发生额)
         select sum(compt_amt) as now_add_num -- 截止至上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(compt_time, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 04对应服务绿色产业
                    and cust_main_label like '%04%'
              ) t2 on t1.guar_id = t2.code
     ) t2,
     (
         -- 期末数
         select sum(compt_amt) as end_num -- 截止至上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 04对应服务绿色产业
                    and cust_main_label like '%04%'
              ) t2 on t1.guar_id = t2.code
     ) t3;
commit;
-- 4.4.8其中：服务航运产业
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.4.8其中：服务航运产业' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       0,
       t3.end_num
from (
         -- 期初数
         select sum(compt_amt) as start_num -- 截止至上上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 05对应服务航运产业
                    and cust_main_label like '%05%'
              ) t2 on t1.guar_id = t2.code
     ) t1,
     (
         -- 本期增加(发生额)
         select sum(compt_amt) as now_add_num -- 截止至上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(compt_time, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 05对应服务航运产业
                    and cust_main_label like '%05%'
              ) t2 on t1.guar_id = t2.code
     ) t2,
     (
         -- 期末数
         select sum(compt_amt) as end_num -- 截止至上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 05对应服务航运产业
                    and cust_main_label like '%05%'
              ) t2 on t1.guar_id = t2.code
     ) t3;
commit;
-- 4.4.9其中：创业担保贷款
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.4.9其中：创业担保贷款' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       0,
       t3.end_num
from (
         -- 期初数
         select sum(compt_amt) as start_num -- 截止至上上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 03对应创业担保贷款
                    and cust_main_label like '%03%'
              ) t2 on t1.guar_id = t2.code
     ) t1,
     (
         -- 本期增加(发生额)
         select sum(compt_amt) as now_add_num -- 截止至上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(compt_time, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 03对应创业担保贷款
                    and cust_main_label like '%03%'
              ) t2 on t1.guar_id = t2.code
     ) t2,
     (
         -- 期末数
         select sum(compt_amt) as end_num -- 截止至上月底代偿金额
         from (
                  select guar_id, compt_amt
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 03对应创业担保贷款
                    and cust_main_label like '%03%'
              ) t2 on t1.guar_id = t2.code
     ) t3;
commit;
-- 4.4.10其中：民营经济
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'    as day_id,
       '4.政策性融资担保业务'   as proj_name,
       '4.4.10其中：民营经济' as proj_detail,
       0,
       0,
       0,
       0;
commit;
-- 4.5代偿户数合计
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'  as day_id,
       '4.政策性融资担保业务' as proj_name,
       '4.5代偿户数合计'   as proj_detail,
       0,
       0,
       0,
       0;
commit;
-- 4.5.1其中：中小微企业
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'    as day_id,
       '4.政策性融资担保业务'   as proj_name,
       '4.5.1其中：中小微企业' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       0,
       t3.end_num
from (
         -- 期初数
         select count(distinct cert_no) as start_num -- 截止至上上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02 中型企业 03 小型企业 04 微型企业
                    and enterprise_scale in ('02', '03', '04')
              ) t2 on t1.guar_id = t2.code
     ) t1,
     (
         -- 本期增加(发生额)
         select count(distinct cert_no) as now_add_num -- 截止至上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(compt_time, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02 中型企业 03 小型企业 04 微型企业
                    and enterprise_scale in ('02', '03', '04')
              ) t2 on t1.guar_id = t2.code
     ) t2,
     (
         -- 期末数
         select count(distinct cert_no) as end_num -- 截止至上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02 中型企业 03 小型企业 04 微型企业
                    and enterprise_scale in ('02', '03', '04')
              ) t2 on t1.guar_id = t2.code
     ) t3;
commit;
-- 4.5.2其中：“三农”主体
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.5.2其中：“三农”主体' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       0,
       t3.end_num
from (
         -- 期初数
         select count(distinct cert_no) as start_num -- 截止至上上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否农户为是
                    and is_farmer = 1
              ) t2 on t1.guar_id = t2.code
     ) t1,
     (
         -- 本期增加(发生额)
         select count(distinct cert_no) as now_add_num -- 截止至上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(compt_time, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否农户为是
                    and is_farmer = 1
              ) t2 on t1.guar_id = t2.code
     ) t2,
     (
         -- 期末数
         select count(distinct cert_no) as end_num -- 截止至上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否农户为是
                    and is_farmer = 1
              ) t2 on t1.guar_id = t2.code
     ) t3;
commit;
-- 4.5.3其中：个体工商户
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'    as day_id,
       '4.政策性融资担保业务'   as proj_name,
       '4.5.3其中：个体工商户' as proj_detail,
       0,
       0,
       0,
       0;
commit;
-- 4.5.4其中：战略性新兴产业
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'      as day_id,
       '4.政策性融资担保业务'     as proj_name,
       '4.5.4其中：战略性新兴产业' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       0,
       t3.end_num
from (
         -- 期初数
         select count(distinct cert_no) as start_num -- 截止至上上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 06对应战略性新兴产业
                    and cust_main_label like '%06%'
              ) t2 on t1.guar_id = t2.code
     ) t1,
     (
         -- 本期增加(发生额)
         select count(distinct cert_no) as now_add_num -- 截止至上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(compt_time, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 06对应战略性新兴产业
                    and cust_main_label like '%06%'
              ) t2 on t1.guar_id = t2.code
     ) t2,
     (
         -- 期末数
         select count(distinct cert_no) as end_num -- 截止至上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 06对应战略性新兴产业
                    and cust_main_label like '%06%'
              ) t2 on t1.guar_id = t2.code
     ) t3;
commit;
-- 4.5.5其中：首贷户担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'    as day_id,
       '4.政策性融资担保业务'   as proj_name,
       '4.5.5其中：首贷户担保' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       0,
       t3.end_num
from (
         -- 期初数
         select count(distinct cert_no) as start_num -- 截止至上上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否首贷 为是
                    and is_first_loan = 1
              ) t2 on t1.guar_id = t2.code
     ) t1,
     (
         -- 本期增加(发生额)
         select count(distinct cert_no) as now_add_num -- 截止至上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(compt_time, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否首贷 为是
                    and is_first_loan = 1
              ) t2 on t1.guar_id = t2.code
     ) t2,
     (
         -- 期末数
         select count(distinct cert_no) as end_num -- 截止至上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否首贷 为是
                    and is_first_loan = 1
              ) t2 on t1.guar_id = t2.code
     ) t3;
commit;
-- 4.5.6其中：科技创新担保
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.5.6其中：科技创新担保' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       0,
       t3.end_num
from (
         -- 期初数
         select count(distinct cert_no) as start_num -- 截止至上上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02对应科技创新担保
                    and cust_main_label like '%02%'
              ) t2 on t1.guar_id = t2.code
     ) t1,
     (
         -- 本期增加(发生额)
         select count(distinct cert_no) as now_add_num -- 截止至上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(compt_time, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02对应科技创新担保
                    and cust_main_label like '%02%'
              ) t2 on t1.guar_id = t2.code
     ) t2,
     (
         -- 期末数
         select count(distinct cert_no) as end_num -- 截止至上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02对应科技创新担保
                    and cust_main_label like '%02%'
              ) t2 on t1.guar_id = t2.code
     ) t3;
commit;
-- 4.5.7其中：服务绿色产业
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.5.7其中：服务绿色产业' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       0,
       t3.end_num
from (
         -- 期初数
         select count(distinct cert_no) as start_num -- 截止至上上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 04对应服务绿色产业
                    and cust_main_label like '%04%'
              ) t2 on t1.guar_id = t2.code
     ) t1,
     (
         -- 本期增加(发生额)
         select count(distinct cert_no) as now_add_num -- 截止至上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(compt_time, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 04对应服务绿色产业
                    and cust_main_label like '%04%'
              ) t2 on t1.guar_id = t2.code
     ) t2,
     (
         -- 期末数
         select count(distinct cert_no) as end_num -- 截止至上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 04对应服务绿色产业
                    and cust_main_label like '%04%'
              ) t2 on t1.guar_id = t2.code
     ) t3;
commit;
-- 4.5.8其中：服务航运产业
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.5.8其中：服务航运产业' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       0,
       t3.end_num
from (
         -- 期初数
         select count(distinct cert_no) as start_num -- 截止至上上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 05对应服务航运产业
                    and cust_main_label like '%05%'
              ) t2 on t1.guar_id = t2.code
     ) t1,
     (
         -- 本期增加(发生额)
         select count(distinct cert_no) as now_add_num -- 截止至上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(compt_time, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 05对应服务航运产业
                    and cust_main_label like '%05%'
              ) t2 on t1.guar_id = t2.code
     ) t2,
     (
         -- 期末数
         select count(distinct cert_no) as end_num -- 截止至上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 05对应服务航运产业
                    and cust_main_label like '%05%'
              ) t2 on t1.guar_id = t2.code
     ) t3;
commit;
-- 4.5.9其中：创业担保贷款
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '4.政策性融资担保业务'    as proj_name,
       '4.5.9其中：创业担保贷款' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       0,
       t3.end_num
from (
         -- 期初数
         select count(distinct cert_no) as start_num -- 截止至上上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 03对应创业担保贷款
                    and cust_main_label like '%03%'
              ) t2 on t1.guar_id = t2.code
     ) t1,
     (
         -- 本期增加(发生额)
         select count(distinct cert_no) as now_add_num -- 截止至上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(compt_time, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 03对应创业担保贷款
                    and cust_main_label like '%03%'
              ) t2 on t1.guar_id = t2.code
     ) t2,
     (
         -- 期末数
         select count(distinct cert_no) as end_num -- 截止至上月底代偿金额
         from (
                  select guar_id, cert_no
                  from dw_base.dwd_guar_compt_info
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 03对应创业担保贷款
                    and cust_main_label like '%03%'
              ) t2 on t1.guar_id = t2.code
     ) t3;
commit;
-- 4.5.10民营经济
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'  as day_id,
       '4.政策性融资担保业务' as proj_name,
       '4.5.10民营经济'  as proj_detail,
       0,
       0,
       0,
       0;
commit;
-- 5.1融资担保综合担保费收入
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '5.融资担保综合担保费收入'  as proj_name,
       '5.1融资担保综合担保费收入' as proj_detail,
       0,
       t1.now_add_num,
       0,
       0
from ( -- 本期增加(发生额)
         select sum(guar_fee) / 10000 as now_add_num -- 保费金额(万元)
         from dw_base.dwd_guar_info_all_his
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
           and date_format(loan_reg_dt, '%Y%m') =
               DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
     ) t1;
commit;
-- 5.1.1其中：中小微企业融资担保综合担保费收入
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'               as day_id,
       '5.融资担保综合担保费收入'            as proj_name,
       '5.1.1其中：中小微企业融资担保综合担保费收入' as proj_detail,
       0,
       t1.now_add_num,
       0,
       0
from ( -- 本期增加(发生额)
         select sum(guar_fee) / 10000 as now_add_num -- 保费金额(万元)
         from (
                  select guar_id, guar_fee
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02 中型企业 03 小型企业 04 微型企业
                    and enterprise_scale in ('02', '03', '04')
              ) t2
              on t1.guar_id = t2.code
     ) t1;
commit;
-- 5.1.2其中：涉农融资担保综合担保费收入
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'            as day_id,
       '5.融资担保综合担保费收入'         as proj_name,
       '5.1.2其中：涉农融资担保综合担保费收入' as proj_detail,
       0,
       t1.now_add_num,
       0,
       0
from ( -- 本期增加(发生额)
         select sum(guar_fee) / 10000 as now_add_num -- 保费金额(万元)
         from (
                  select guar_id, guar_fee
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否农户为是
                    and is_farmer = 1
              ) t2
              on t1.guar_id = t2.code
     ) t1;
commit;

-- 5.2融资担保综合担保费率
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'    as day_id,
       '5.融资担保综合担保费收入' as proj_name,
       '5.2融资担保综合担保费率' as proj_detail,
       0,
       0,
       0,
       t1.end_num
from ( -- 本期增加(发生额)
         select (sum(guar_fee) / 10000) / sum(guar_amt) as end_num -- 担保费率
         from dw_base.dwd_guar_info_all_his
         where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
           and date_format(loan_reg_dt, '%Y%m') =
               DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
     ) t1;
commit;
-- 5.2.1其中：中小微企业融资担保综合担保费率
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'              as day_id,
       '5.融资担保综合担保费收入'           as proj_name,
       '5.2.1其中：中小微企业融资担保综合担保费率' as proj_detail,
       0,
       0,
       0,
       t1.end_num
from ( -- 本期增加(发生额)
         select (sum(guar_fee) / 10000) / sum(guar_amt) as end_num -- 担保费率
         from (
                  select guar_id, guar_fee, guar_amt
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 02 中型企业 03 小型企业 04 微型企业
                    and enterprise_scale in ('02', '03', '04')
              ) t2
              on t1.guar_id = t2.code
     ) t1;
commit;
-- 5.2.2其中：涉农融资担保综合担保费率
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'              as day_id,
       '5.融资担保综合担保费收入'           as proj_name,
       '5.2.1其中：中小微企业融资担保综合担保费率' as proj_detail,
       0,
       0,
       0,
       t1.end_num
from ( -- 本期增加(发生额)
         select (sum(guar_fee) / 10000) / sum(guar_amt) as end_num -- 担保费率
         from (
                  select guar_id, guar_fee, guar_amt
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  inner join
              (
                  select code -- 业务编号
                  from (
                           select *, row_number() over (partition by code order by db_update_time desc) as rn
                           from dw_nd.ods_t_biz_project_main) t1
                  where rn = 1
                    -- 是否农户为是
                    and is_farmer = 1
              ) t2
              on t1.guar_id = t2.code
     ) t1;
commit;
-- 6.1本年累计获得的奖补资金
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'     as day_id,
       '6.本年累计获得的奖补资金'  as proj_name,
       '6.1本年累计获得的奖补资金' as proj_detail,
       0,
       0,
       0,
       0;
commit;
-- 7.1跨省开展的融资担保业务金额
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'       as day_id,
       '7.跨省开展业务情况'       as proj_name,
       '7.1跨省开展的融资担保业务金额' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select sum(onguar_amt) as start_num -- 在保余额(万元)
         from (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t1
                  left join
              (
                  select guar_id, city_code
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
              ) t2 on t1.guar_id = t2.guar_id
                  left join
              dw_base.dim_area_info t3 on t2.city_code = t3.area_cd
              -- 判断非天津市
         where t3.sup_area_name != '天津市'
     ) t1,
     ( -- 本期增加(发生额)
         select sum(guar_amt) as now_add_num -- 放款金额(万元)
         from (
                  select guar_id, guar_amt, city_code
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  left join
              dw_base.dim_area_info t2 on t1.city_code = t2.area_cd
              -- 判断非天津市
         where t2.sup_area_name != '天津市'
     ) t2,
     ( -- 本期减少(发生额)
         select sum(if(t3.biz_no is not null, coalesce(t1.guar_amt, 0),
                       coalesce(t4.repayment_amount, 0))) as now_reduce_num
         from (
                  select guar_id,
                         city_code,
                         guar_amt -- 放款金额(万元) 解保了对应解保金额
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  left join
              dw_base.dwd_guar_info_stat t2 on t1.guar_id = t2.guar_id
                  left join
              (
                  select biz_no
                  from dw_base.dwd_guar_biz_unguar_info
                  where day_id = '${v_sdate}'
                    and biz_unguar_reason = '合同解保'
                    -- 解保日期为当期
                    and date_format(biz_unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t3 on t1.guar_id = t3.biz_no
                  left join
              (
                  select id,
                         project_id,
                         actual_repayment_amount / 10000 as repayment_amount -- 还款金额(万元)
                  from (select *, row_number() over (partition by id order by db_update_time desc) rn
                        from dw_nd.ods_t_biz_proj_repayment_detail) t1
                  where rn = 1
                    and date_format(repay_date, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t4 on t2.project_id = t4.project_id
                  left join
              dw_base.dim_area_info t5 on t1.city_code = t5.area_cd
              -- 判断非天津市
         where t5.sup_area_name != '天津市'
     ) t3,
     ( -- 期末数
         select sum(onguar_amt) as end_num -- 在保余额(万元)
         from (
                  select guar_id, onguar_amt
                  from dw_base.dwd_guar_info_onguar
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t1
                  left join
              (
                  select guar_id, city_code
                  from dw_base.dwd_guar_info_all_his
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
              ) t2 on t1.guar_id = t2.guar_id
                  left join
              dw_base.dim_area_info t3 on t2.city_code = t3.area_cd
              -- 判断非天津市
         where t3.sup_area_name != '天津市'
     ) t4;
commit;
-- 7.2跨省开展的融资担保业务笔数
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'       as day_id,
       '7.跨省开展业务情况'       as proj_name,
       '7.2跨省开展的融资担保业务笔数' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select count(guar_id) as start_num -- 上上月底在保笔数
         from (
                  select guar_id, city_code
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  left join
              dw_base.dim_area_info t2 on t1.city_code = t2.area_cd
              -- 判断非天津市
         where t2.sup_area_name != '天津市'
     ) t1,
     ( -- 本期增加(发生额)
         select count(guar_id) as now_add_num -- 上月新增在保笔数
         from (
                  select guar_id, city_code
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
                    and item_stt = '已放款'
              ) t1
                  left join
              dw_base.dim_area_info t2 on t1.city_code = t2.area_cd
              -- 判断非天津市
         where t2.sup_area_name != '天津市'
     ) t2,
     ( -- 本期减少(发生额)
         select count(guar_id) as now_reduce_num -- 上月新增解保笔数
         from (
                  select guar_id, city_code
                  from dw_base.dwd_guar_info_stat
                  where day_id = '${v_sdate}'
                    and date_format(unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  left join
              dw_base.dim_area_info t2 on t1.city_code = t2.area_cd
              -- 判断非天津市
         where t2.sup_area_name != '天津市'
     ) t3,
     ( -- 期末数
         select count(guar_id) as end_num -- 上月底在保笔数
         from (
                  select guar_id, city_code
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  left join
              dw_base.dim_area_info t2 on t1.city_code = t2.area_cd
              -- 判断非天津市
         where t2.sup_area_name != '天津市'
     ) t4;
commit;
-- 7.3跨省开展的融资担保业务户数
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'       as day_id,
       '7.跨省开展业务情况'       as proj_name,
       '7.3跨省开展的融资担保业务户数' as proj_detail,
       t1.start_num,
       t2.now_add_num,
       t3.now_reduce_num,
       t4.end_num
from ( -- 期初数
         select count(distinct cert_no) as start_num -- 上上月底在保户数
         from (
                  select guar_id, city_code, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -2 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  left join
              dw_base.dim_area_info t2 on t1.city_code = t2.area_cd
              -- 判断非天津市
         where t2.sup_area_name != '天津市'
     ) t1,
     ( -- 本期增加(发生额)
         select count(distinct cert_no) as now_add_num -- 上月新增在保户数
         from (
                  select guar_id, city_code, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and date_format(loan_reg_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
                    and item_stt = '已放款'
              ) t1
                  left join
              dw_base.dim_area_info t2 on t1.city_code = t2.area_cd
              -- 判断非天津市
         where t2.sup_area_name != '天津市'
     ) t2,
     ( -- 本期减少(发生额)
         select count(distinct cert_no) as now_reduce_num -- 上月新增解保户数
         from (
                  select guar_id, city_code, cert_no
                  from dw_base.dwd_guar_info_stat
                  where day_id = '${v_sdate}'
                    and date_format(unguar_dt, '%Y%m') =
                        DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m')
              ) t1
                  left join
              dw_base.dim_area_info t2 on t1.city_code = t2.area_cd
              -- 判断非天津市
         where t2.sup_area_name != '天津市'
     ) t3,
     ( -- 期末数
         select count(distinct cert_no) as end_num -- 上月底在保户数
         from (
                  select guar_id, city_code, cert_no
                  from dw_base.dwd_guar_info_all_his
                       -- 取数据日期为上上月底
                  where day_id = DATE_FORMAT(LAST_DAY(DATE_ADD('${v_sdate}', interval -1 month)), '%Y%m%d')
                    and item_stt = '已放款'
              ) t1
                  left join
              dw_base.dim_area_info t2 on t1.city_code = t2.area_cd
              -- 判断非天津市
         where t2.sup_area_name != '天津市'
     ) t4;
commit;
-- 7.4跨省开展的非融资担保直保金额
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'        as day_id,
       '7.跨省开展业务情况'        as proj_name,
       '7.4跨省开展的非融资担保直保金额' as proj_detail,
       0,
       0,
       0,
       0;
commit;
-- 7.5跨省开展的非融资担保直保笔数
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'        as day_id,
       '7.跨省开展业务情况'        as proj_name,
       '7.5跨省开展的非融资担保直保笔数' as proj_detail,
       0,
       0,
       0,
       0;
commit;
-- 7.6跨省开展的非融资担保直保户数
insert into dw_base.ads_rpt_tjnd_busi_cbirc_guar_stat
(day_id, -- 数据日期
 proj_name, -- 项目名称
 proj_detail, -- 项目名称详情
 start_num, -- 期初数
 now_add_num, -- 本期增加(发生额)
 now_reduce_num, -- 本期减少(发生额)
 end_num -- 期末数
)
select '${v_sdate}'        as day_id,
       '7.跨省开展业务情况'        as proj_name,
       '7.6跨省开展的非融资担保直保户数' as proj_detail,
       0,
       0,
       0,
       0;
commit;