-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250325
-- 目标表   ：dw_base.ads_rpt_tjnd_finance_compt_recovery_info     财务部-代偿及追偿回款情况
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_afg_business_infomation       业务申请表
--          dw_nd.ods_tjnd_yw_bh_compensatory               代偿表
--          dw_nd.ods_tjnd_yw_bh_recovery_tracking          追偿跟踪表
--          dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail   追偿跟踪详情表
--          新业务系统
--          dw_base.dwd_guar_compt_info                         代偿信息汇总表
--          dw_base.dwd_guar_info_stat                          担保台账星型表
--          dw_nd.ods_t_biz_proj_recovery_record                追偿记录表
--          dw_nd.ods_t_biz_proj_recovery_repay_detail_record   登记还款记录
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 重跑逻辑

delete from dw_base.ads_rpt_tjnd_finance_compt_recovery_info where day_id = '${v_sdate}';
commit;

-- 旧系统逻辑
 insert into dw_base.ads_rpt_tjnd_finance_compt_recovery_info
 (day_id, -- 数据日期
  guar_id, -- 业务id
  cust_name, -- 客户名称
  compt_date, -- 代偿日期
  compt_amt, -- 代偿金额（元）
  recovery_amt, -- 累计追偿金额（元）
  un_recovery_amt, -- 未收回金额（元）
  recovery_fee, -- 追偿费用（元）
  year_recovery_amt, -- 当年追偿金额（元）
  last_recovery_date -- 最近一次还款日期
 )
 select '${v_sdate}'                                as day_id,
        t1.id                                       as guar_id,
        cust_name,
        compt_date,
        compt_amt * 10000 as compt_amt,
        recovery_amt * 10000 as recovery_amt,
        case
            when (compt_amt - recovery_amt) < 0 then 0
            else (compt_amt - recovery_amt) * 10000
            end                                     as un_recovery_amt,
        lawyer_fee                                  as recovery_fee,                                -- 追偿费用（元）
        year_recovery_amt * 10000                   as year_recovery_amt,
        date_format(last_recovery_date, '%Y-%m-%d') as last_recovery_date
 from (
          select id,                        -- 业务id
                 CUSTOMER_NAME as cust_name -- 客户姓名
--        from dw_nd.ods_tjnd_yw_afg_business_infomation
		  from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation
		  where gur_state != '50'                    -- [排除在保转进件]
      ) t1
          inner join
      (
          select ID_CFBIZ_UNDERWRITING,           -- 业务id
                 TOTAL_COMPENSATION as compt_amt, -- 代偿金额
                 PAYMENT_DATE       as compt_date -- 代偿日期
--          from dw_nd.ods_tjnd_yw_bh_compensatory
		  from dw_nd.ods_creditmid_v2_z_migrate_bh_compensatory          -- 代偿表
          where status = 1
            and over_tag = 'BJ'
            and DELETED_BY is null
      ) t2
      on t1.id = t2.ID_CFBIZ_UNDERWRITING
          left join
      (
          select t1.ID_CFBIZ_UNDERWRITING,             -- 业务id
                 sum(CUR_RECOVERY)    as recovery_amt, -- 追偿金额
                 sum(LAWYER_FEE_PAID) as lawyer_fee    -- 追偿费用
--        from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
		  from dw_nd.ods_creditmid_v2_z_migrate_bh_recovery_tracking t1                       -- 追偿跟踪表
--        left join dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail t2
		  left join dw_nd.ods_creditmid_v2_z_migrate_bh_recovery_tracking_detail t2           -- 追偿跟踪详情表
                 on t1.id = t2.ID_RECOVERY_TRACKING
          group by t1.ID_CFBIZ_UNDERWRITING
      ) t3 on t1.id = t3.ID_CFBIZ_UNDERWRITING
          left join
      (
          select t1.ID_CFBIZ_UNDERWRITING,               -- 业务id
                 sum(CUR_RECOVERY) as year_recovery_amt, -- 当年追偿金额
                 max(ENTRY_DATA)   as last_recovery_date -- 最近一次还款日期
--        from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
		  from dw_nd.ods_creditmid_v2_z_migrate_bh_recovery_tracking t1                       -- 追偿跟踪表
--        left join dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail t2
		  left join dw_nd.ods_creditmid_v2_z_migrate_bh_recovery_tracking_detail t2           -- 追偿跟踪详情表
                 on t1.id = t2.ID_RECOVERY_TRACKING
          where year(t2.ENTRY_DATA) = year('${v_sdate}')
          group by t1.ID_CFBIZ_UNDERWRITING
      ) t4 on t1.ID = t4.ID_CFBIZ_UNDERWRITING;
 commit;

-- 新业务系统逻辑
insert into dw_base.ads_rpt_tjnd_finance_compt_recovery_info
(day_id, -- 数据日期
 guar_id, -- 业务id
 cust_name, -- 客户名称
 compt_date, -- 代偿日期
 compt_amt, -- 代偿金额（元）
 recovery_amt, -- 累计追偿金额（元）
 un_recovery_amt, -- 未收回金额（元）
 recovery_fee, -- 追偿费用（元）
 year_recovery_amt, -- 当年追偿金额（元）
 last_recovery_date -- 最近一次还款日期
)
select '${v_sdate}'             as day_id,
       t1.guar_id,
       cust_name,
       compt_date,
       compt_amt,
       recovery_amt,
       compt_amt - recovery_amt as un_recovery_amt,
       null                     as recovery_fee,
       year_recovery_amt,
       last_recovery_date
from (
         select guar_id    as guar_id,    -- 项目编号
                cust_name  as cust_name,  -- 客户姓名
                compt_time as compt_date, -- 代偿拨付日期
                compt_amt * 10000  as compt_amt   -- 代偿金额(本息)元
         from dw_base.dwd_guar_compt_info
         where day_id = '${v_sdate}'
     ) t1
         left join
     (
         select guar_id,   -- 项目编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select t1.project_id,                                -- 项目id
                sum(t2.shou_comp_amt)  as recovery_amt -- 追偿金额（元）
         from dw_nd.ods_t_biz_proj_recovery_record t1
                  left join dw_nd.ods_t_biz_proj_recovery_repay_detail_record t2 on t1.reco_id = t2.record_id
         group by t1.project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select t1.project_id,                                      -- 项目id
                sum(t2.shou_comp_amt)  as year_recovery_amt, -- 当年追偿金额（元）
                max(t2.real_repay_date)       as last_recovery_date -- 最近一次还款日期
         from dw_nd.ods_t_biz_proj_recovery_record t1
                  left join dw_nd.ods_t_biz_proj_recovery_repay_detail_record t2 on t1.reco_id = t2.record_id
         where year(real_repay_date) = year('${v_sdate}')
         group by t1.project_id
     ) t4 on t2.project_id = t4.project_id;
commit;