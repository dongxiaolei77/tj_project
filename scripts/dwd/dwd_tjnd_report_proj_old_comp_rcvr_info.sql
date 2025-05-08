-- ----------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250507
-- 目标表   ：dwd_tjnd_report_proj_old_comp_rcvr_info       历史代偿项目追偿统计信息
-- 源表     ：
-- 备注     ：天津农担历史数据迁移，上报国农担，数据逻辑组装
-- 变更记录 ：
-- ----------------------------------------
-- 日增量加载
delete
from dw_base.dwd_tjnd_report_proj_old_comp_rcvr_info
where day_id = date_format(date_add('${v_sdate}', interval 1 day), '%Y%m%d');
commit;

insert into dw_base.dwd_tjnd_report_proj_old_comp_rcvr_info
(day_id, -- 数据日期
 old_comp_no_nacga, -- 历史代偿项目编号
 cust_name, -- 客户名称
 is_comp_comp, -- 是否代偿补偿项目
 comp_comp_poli_cd, -- 代偿补偿政策代码
 rcvr_rcpt_dt, -- 追偿入账日期
 act_arrl_amt_comp, -- 本年累计实收金额合计
 act_arrl_amt_cntr, -- 本年累计实收金额:向客户或反担保人追偿（含处置反担保物）
 act_arrl_amt_gov, -- 本年累计实收金额:政府分险
 act_arrl_amt_org, -- 本年累计实收金额:地方担保、再担保、保险等其他机构分险
 act_arrl_amt_other -- 本年累计实收金额:其他情况
)
select date_format(date_add('${v_sdate}', interval 1 day), '%Y%m%d') as day_id,
       -- date_format('${v_sdate}', '%Y%m')     as year_mon, -- 年月 上报系统自动生成
       replace(HIS_COMP_ID, '_', '')                                 as old_comp_no_nacga,
       t1.CUSTOMER_NAME                                              as cust_name,
       IS_COMP                                                       as is_comp_comp,
       COMP_POLICY_CODE                                              as comp_comp_poli_code,
       date_format(rcvr_rcpt_dt, '%Y-%m-%d')                         as rcvr_rcpt_dt,
       recovery_amt / 10000                                          as act_arrl_amt_comp,
       recovery_amt / 10000                                          as act_arrl_amt_cntr,
       0                                                             as act_arrl_amt_gov,
       0                                                             as act_arrl_amt_org,
       0                                                             as act_arrl_amt_other
from dw_nd.ods_tjnd_yw_z_report_compensatory_history t1
         inner join
     dw_nd.ods_tjnd_yw_z_report_afg_business_infomation t2
     on t1.BUS_ID = t2.GUARANTEE_CODE
         left join
     (
         select t1.ID_CFBIZ_UNDERWRITING,          -- 业务id
                sum(CUR_RECOVERY) as recovery_amt, -- 追偿金额
                max(ENTRY_DATA)   as rcvr_rcpt_dt  -- 追偿入账日期
         from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
                  left join dw_nd.ods_tjnd_yw_z_report_bh_recovery_tracking_detail t2
                            on t1.id = t2.ID_RECOVERY_TRACKING
              -- 当年追偿还款
         where date_format(ENTRY_DATA, '%Y%m%d') >= concat(year('${v_sdate}'), '0101')
           -- 判断为上个月数据
           and date_format(ENTRY_DATA, '%Y%m%d') <= '${v_sdate}'
         group by t1.ID_CFBIZ_UNDERWRITING
     ) t3 on t2.ID = t3.ID_CFBIZ_UNDERWRITING
where '${v_sdate}' = date_format(last_day('${v_sdate}'), '%Y%m%d'); -- 月初跑批
commit;