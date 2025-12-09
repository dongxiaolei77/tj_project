-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250421
-- 目标表   ：dw_base.ads_rpt_tjnd_imd_guar_overall_rate_stat    综合部-融资担保公司主要业务综合费率统计表
-- 源表     ：
--          新业务系统
--          dw_base.dwd_guar_info_all           担保台账信息
--          dw_base.dwd_guar_info_stat          担保台账星型表
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 重跑策略

-- 创建临时表存储旧系统数据
# drop table if exists dw_tmp.tmp_ads_rpt_tjnd_imd_guar_overall_rate_stat_zb_to_jj;
# commit;
# create table if not exists dw_tmp.tmp_ads_rpt_tjnd_imd_guar_overall_rate_stat_zb_to_jj
# (
#     guar_id     varchar(200) comment '项目编号',
#     guar_amt    decimal(18, 6) comment '放款金额',
#     guar_rate   decimal(18, 6) comment '担保费率',
#     loan_rate   decimal(18, 6) comment '贷款利率',
#     guar_status varchar(200) comment '项目状态'
# );
# commit;
# insert into dw_tmp.tmp_ads_rpt_tjnd_imd_guar_overall_rate_stat_zb_to_jj
# select t1.guar_id,
#        t3.guar_amt,
#        t2.guar_rate,
#        t2.loan_rate,
#        t1.guar_status
# from (
#          select id,                           -- 业务id
#                 guarantee_code as guar_id,    -- 业务编号
#                 gur_state      as guar_status -- 担保状态
#                 -- from dw_nd.ods_tjnd_yw_afg_business_infomation
#          from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation
#      ) t1
#          left join
#      (
#          select id_business_information,           -- 业务id
#                 guarantee_tate * 100 as guar_rate, -- 担保费率
#                 year_loan_rate * 100 as loan_rate  -- 年贷款利率
#                 -- from dw_nd.ods_tjnd_yw_afg_business_approval
#          from dw_nd.ods_creditmid_v2_z_migrate_afg_business_approval
#      ) t2
#      on t1.id = t2.id_business_information
#          left join
#      (
#          select id_business_information,        -- 业务id
#                 sum(receipt_amount) as guar_amt -- 凭证金额
#                 --  from dw_nd.ods_tjnd_yw_afg_voucher_infomation
#          from dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_infomation
#          where delete_flag = 1
#          group by id_business_information
#      ) t3
#      on t1.id = t3.id_business_information
# ;
# commit;


delete
from dw_base.ads_rpt_tjnd_imd_guar_overall_rate_stat
where day_id = '${v_sdate}';
commit;

-- 1.插入数据
insert into dw_base.ads_rpt_tjnd_imd_guar_overall_rate_stat
(day_id, -- 数据日期
 fina_avg_overall_rate, -- 融资担保业务合计-平均综合费率
 loan_avg_overall_rate, -- 借款类担保业务-平均综合费率
 gover_avg_overall_rate, -- 政策性担保业务-平均综合费率
 avg_loan_rate -- 平均贷款利率（贷款担保业务）
)
select '${v_sdate}'                                as day_id,
       sum(guar_amt * (guar_rate)) / sum(guar_amt) as fina_avg_overall_rate,
       sum(guar_amt * (guar_rate)) / sum(guar_amt) as loan_avg_overall_rate,
       sum(guar_amt * (guar_rate)) / sum(guar_amt) as gover_avg_overall_rate,
       sum(guar_amt * loan_rate) / sum(guar_amt)   as avg_loan_rate
from (
         select guar_id,
                guar_amt, -- 放款金额
                loan_rate
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
#            and data_source = '担保业务管理系统新'
           -- 只取在保业务数据
           and item_stt in ('已放款')
#          union all
#          select guar_id,
#                 guar_amt, -- 放款金额
#                 loan_rate
#          from dw_tmp.tmp_ads_rpt_tjnd_imd_guar_overall_rate_stat_zb_to_jj
#          where guar_status != '50'
#            and guar_status in ('90', '93') -- 担保状态
     ) t1
         left join
     (
         select guar_id,  -- 业务编号
                guar_rate -- 担保利率
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
#          union all
#          select guar_id,   -- 业务编号
#                 guar_rate, -- 担保利率
#          from dw_tmp.tmp_ads_rpt_tjnd_imd_guar_overall_rate_stat_zb_to_jj
     ) t2 on t1.guar_id = t2.guar_id;
commit;


		




