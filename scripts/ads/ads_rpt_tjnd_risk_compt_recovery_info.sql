-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250326
-- 目标表   ：dw_base.ads_rpt_tjnd_risk_compt_recovery_info 风险部-代偿及追偿基本情况统计表
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_afg_business_infomation       业务申请表
--          dw_nd.ods_tjnd_yw_bh_compensatory               代偿表
--          dw_nd.ods_tjnd_yw_bh_recovery_tracking          追偿跟踪表
--          dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail   追偿跟踪详情表
-- 备注     ： 金额相关字段以万元为单位的保留小数点后6位，以元为单位的保留小数点后2位
-- 变更记录 ：
-- ---------------------------------------
-- 重跑策略
delete
from dw_base.ads_rpt_tjnd_risk_compt_recovery_info
where day_id = '${v_sdate}';
commit;

 -- group_concat 防止字段长度过长 自动截断操作
 set session group_concat_max_len = 102400;
 -- 旧业务系统逻辑
 insert into dw_base.ads_rpt_tjnd_risk_compt_recovery_info
 (day_id, -- 数据日期
  guar_id, -- 业务id
  cust_name, -- 客户名称
  cert_no, -- 证件号码
  compt_amt, -- 代偿金额(元)
  compt_date, -- 代偿时间
  nd_proj_mgr, -- 项目经理
  branch_off, -- 办事处
  is_reguar, -- 是否纳入再担保
  reguar_amt, -- 再担保补偿金额(元)
  recovery_stat, -- 追偿状态
  shou_law_amt, -- 诉讼费(调解费)(元)
  shou_cost_amt, -- 保全费(元)
  shou_cost_insure_amt, -- 保全保险费(元)
  shou_notice_amt, -- 公告费(元)
  shou_execute_amt, -- 执行费(元)
  shou_appraisal_amt, -- 评估费(元)
  shou_lawyer_amt, -- 律师费（固定代理）(元)
  month_lawyer_amt_royalty, -- 律师费本月提成(元)
  sum_lawyer_amt_royalty, -- 律师费提成合计(元)
  sum_recovery_fee, -- 追偿费用合计(元)
  month_recovery_amt, -- 本月追回金额(元)
  shou_comp_recovery_amt, -- 代偿资金收回金额(元)
  shou_recovery_fee_amt, -- 费用收回金额(元)
  shou_overdue_guar_amt, -- 逾期担保费收回金额(元)
  shou_overdue_damage_amt, -- 逾期付款违约金收回金额(元)
  shou_comp_interest_amt, -- 代偿资金利息收回金额(元)
  sum_recovery_amt, -- 收回金额合计(元)
  remark -- 备注
 )
 select '${v_sdate}' as day_id,
        t1.GUARANTEE_CODE        as guar_id,
        cust_name,
        cert_num,
        compt_amt * 10000 as compt_amt,
        compt_date,
        nd_proj_mgr,
        case
            when branch_off = 'NHDLBranch' then '宁河东丽办事处'
            when branch_off = 'JNBHBranch' then '津南滨海新区办事处'
            when branch_off = 'BCWQBranch' then '武清北辰办事处'
            when branch_off = 'XQJHBranch' then '西青静海办事处'
            when branch_off = 'JZBranch' then '蓟州办事处'
            when branch_off = 'BDBranch' then '宝坻办事处'
            end      as branch_off,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        coalesce(lawyer_fee,0)   as shou_lawyer_amt,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        coalesce(recovery_amt,0) * 10000 as sum_recovery_amt,
        case
            when compt_remark is not null then compt_remark
            when recovery_remark is not null then recovery_remark
            end      as remark
 from (
          select GUARANTEE_CODE,
		         ID,
                 CUSTOMER_NAME         as cust_name,
                 ID_NUMBER             as cert_num,
                 BUSINESS_SP_USER_NAME as nd_proj_mgr,
                 enter_code            as branch_off
          from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation
		  where GUARANTEE_CODE != 'TJRD-2021-5S93-979U'
      ) t1
          inner join
      (
          select ID_CFBIZ_UNDERWRITING,
                 TOTAL_COMPENSATION as compt_amt,
                 PAYMENT_DATE       as compt_date,
                 REMARK             as compt_remark
          from dw_nd.ods_creditmid_v2_z_migrate_bh_compensatory
          where status = 1
            and over_tag = 'BJ'
            and DELETED_BY is null
      ) t2 on t1.id = t2.ID_CFBIZ_UNDERWRITING
          left join
      (
          select t1.ID_CFBIZ_UNDERWRITING,
		         t1.LAWYER_FEE_PAID                             as lawyer_fee,         -- 律师费（固定代理）
                 sum(t2.CUR_RECOVERY)                           as recovery_amt,       -- 收回金额合计
                 group_concat(distinct t1.REMARK separator '；')   as recovery_remark
          from dw_nd.ods_creditmid_v2_z_migrate_bh_recovery_tracking t1             -- 追偿表
                   left join dw_nd.ods_creditmid_v2_z_migrate_bh_recovery_tracking_detail t2  -- 追偿详情（每期追偿金额）
 --                            on t1.id = t2.ID_RECOVERY_TRACKING
							 on  ifnull(t2.ID_RECOVERY_TRACKING = t1.ID,t2.GUARANTEE_CODE = t1.RELATED_ITEM_NO)
		  where t2.status = '1'
          group by t1.ID_CFBIZ_UNDERWRITING,t1.LAWYER_FEE_PAID
      ) t5 on t1.id = t5.ID_CFBIZ_UNDERWRITING
;
 commit;

-- 新业务系统逻辑
insert into dw_base.ads_rpt_tjnd_risk_compt_recovery_info
(day_id, -- 数据日期
 guar_id, -- 业务id
 cust_name, -- 客户名称
 cert_no, -- 证件号码
 compt_amt, -- 代偿金额(元)
 compt_date, -- 代偿时间
 nd_proj_mgr, -- 项目经理
 branch_off, -- 办事处
 is_reguar, -- 是否纳入再担保
 reguar_amt, -- 再担保补偿金额
 recovery_stat, -- 追偿状态
 shou_law_amt, -- 诉讼费(调解费)
 shou_cost_amt, -- 保全费(元)
 shou_cost_insure_amt, -- 保全保险费(元)
 shou_notice_amt, -- 公告费(元)
 shou_execute_amt, -- 执行费(元)
 shou_appraisal_amt, -- 评估费(元)
 shou_lawyer_amt, -- 律师费（固定代理）
 month_lawyer_amt_royalty, -- 律师费本月提成(元)
 sum_lawyer_amt_royalty, -- 律师费提成合计(元)
 sum_recovery_fee, -- 追偿费用合计(元)
 month_recovery_amt, -- 本月追回金额(元)
 shou_comp_recovery_amt, -- 代偿资金收回金额(元)
 shou_recovery_fee_amt, -- 费用收回金额(元)
 shou_overdue_guar_amt, -- 逾期担保费收回金额(元)
 shou_overdue_damage_amt, -- 逾期付款违约金收回金额(元)
 shou_comp_interest_amt, -- 代偿资金利息收回金额(元)
 sum_recovery_amt, -- 收回金额合计(元)
 remark -- 备注
)
select '${v_sdate}' as day_id,
       t1.guar_id,
       cust_name,
       cert_no,
       compt_amt * 10000 as compt_amt,
       t7.approp_date as compt_date,
       nd_proj_mgr,
       case
           when branch_off = 'NHDLBranch' then '宁河东丽办事处'
           when branch_off = 'JNBHBranch' then '津南滨海新区办事处'
           when branch_off = 'BCWQBranch' then '武清北辰办事处'
           when branch_off = 'XQJHBranch' then '西青静海办事处'
           when branch_off = 'JZBranch' then '蓟州办事处'
           when branch_off = 'BDBranch' then '宝坻办事处'
           end      as branch_off,
       null         as is_reguar,
       null         as reguar_amt,
       recovery_stat,
       shou_law_amt,
       shou_cost_amt,
       shou_cost_insure_amt,
       shou_notice_amt,
       shou_execute_amt,
       shou_appraisal_amt,
       coalesce(shou_lawyer_amt,0) as shou_lawyer_amt,
       month_lawyer_amt_royalty,
       sum_lawyer_amt_royalty,
       sum_recovery_fee,
       month_recovery_amt,
       shou_comp_recovery_amt,
       shou_recovery_fee_amt,
       shou_overdue_guar_amt,
       shou_overdue_damage_amt,
       shou_comp_interest_amt,
       coalesce(sum_recovery_amt,0) as sum_recovery_amt,
       null         as remark
from (
         select guar_id,                  -- 业务id
                cust_name,                -- 客户名称
                cert_no,                  -- 客户证件号码
                compt_time as compt_date, -- 代偿拨付日期
                compt_amt,
                country_code              -- 区县编码
         from dw_base.dwd_guar_compt_info
         where day_id = '${v_sdate}'
           and source != '迁移数据'
     ) t1
         left join
     (
         select guar_id,
                project_id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select code,                       -- 项目id
                create_name as nd_proj_mgr, -- 创建者
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main) t1
         where rn = 1
     ) t3 on t1.guar_id = t3.code
         left join
     (
         select t1.project_id,
                t1.status as recovery_stat, -- 追偿状态
                t2.*
         from (
                  select *, row_number() over (partition by reco_id order by db_update_time desc) rn
                  from dw_nd.ods_t_biz_proj_recovery_record
              ) t1
                  left join
              (
                  select record_id,
                         sum(shou_law_amt)            as shou_law_amt,             -- 诉讼费
                         sum(shou_cost_amt)           as shou_cost_amt,            -- 保全费
                         sum(shou_cost_insure_amt)    as shou_cost_insure_amt,     -- 保全保险费
                         sum(shou_notice_amt)         as shou_notice_amt,          -- 公告费
                         sum(shou_execute_amt)        as shou_execute_amt,         -- 执行费
                         sum(shou_appraisal_amt)      as shou_appraisal_amt,       -- 评估费
                         sum(shou_lawyer_fixed_amt)   as shou_lawyer_amt,          -- 律师费(固定代理)
                         sum(
                                 case
                                     when date_format(real_repay_date, '%Y%m') = DATE_FORMAT('${v_sdate}', '%Y%m')
                                         then shou_lawyer_bonus_amt
                                     else 0 end
                             )                        as month_lawyer_amt_royalty, -- 律师费本月提成
                         sum(shou_lawyer_bonus_amt)   as sum_lawyer_amt_royalty,   -- 律师费提成合计
                         sum(
                                     shou_law_amt + shou_cost_amt +
                                     shou_cost_insure_amt + shou_notice_amt +
                                     shou_execute_amt + shou_appraisal_amt +
                                     shou_lawyer_fixed_amt + shou_lawyer_bonus_amt
                             )                        as sum_recovery_fee,         -- 追偿费用合计
                         sum(
                                 case
                                     when date_format(real_repay_date, '%Y%m') = DATE_FORMAT('${v_sdate}', '%Y%m') then
                                             shou_comp_recovery_amt + shou_recovery_fee_amt +
                                             shou_overdue_guar_amt + shou_overdue_damage_amt +
                                             shou_comp_interest_amt
                                     else 0 end
                             )                        as month_recovery_amt,       -- 本月追回金额
                         sum(shou_comp_recovery_amt)  as shou_comp_recovery_amt,   -- 代偿资金收回金额
                         sum(shou_recovery_fee_amt)   as shou_recovery_fee_amt,    -- 费用收回金额
                         sum(shou_overdue_guar_amt)   as shou_overdue_guar_amt,    -- 逾期担保费收回金额
                         sum(shou_overdue_damage_amt) as shou_overdue_damage_amt,  -- 逾期付款违约金额收回金额
                         sum(shou_comp_interest_amt)  as shou_comp_interest_amt,   -- 代偿资金利息受贿金额
                         sum(
                                     shou_comp_recovery_amt + shou_recovery_fee_amt +
                                     shou_overdue_guar_amt + shou_overdue_damage_amt +
                                     shou_comp_interest_amt
                             )                        as sum_recovery_amt          -- 收回金额合计
                  from (
                           select *, row_number() over (partition by id order by db_update_time desc) rn
                           from dw_nd.ods_t_biz_proj_recovery_repay_detail_record
                       ) t1
                  where t1.rn = 1
                  group by record_id
              ) t2 on t1.reco_id = t2.record_id
         where t1.rn = 1
     ) t4 on t2.project_id = t4.project_id
         left join
     (
         select CITY_CODE_,              -- 区县编码
                ROLE_CODE_ as branch_off -- 办事处编码
         from dw_base.dwd_imp_area_branch
     ) t5 on t1.country_code = t5.CITY_CODE_
left join (
            select id
			     , proj_code
                 , case when status = '00' then '申请中'
				        when status = '10' then '审核中'
						when status = '20' then '拨付申请中'
						when status = '30' then '拨付审核中'
						when status = '60' then '已拨付待确认'
						when status = '40' then '待拨付'
						when status = '50' then '已代偿'
						when status = '98' then '已终止'
						when status = '99' then '已否决'
						end as unguar_stat   --  代偿_业务流程状态
				 ,  wf_inst_id -- 工作流实例id
            from (select *,row_number() over (partition by proj_code order by db_update_time desc) rn from dw_nd.ods_t_proj_comp_aply) d
            where d.rn = 1
		  ) t6
on t1.guar_id = t6.proj_code
left join (
            select comp_id
                  ,date_format(approp_date,'%Y-%m-%d') as approp_date  -- 代偿款拨付申请日
            from(select *,row_number()over(partition by comp_id order by db_update_time desc,update_time desc ) rn from dw_nd.ods_t_proj_comp_appropriation) e
            where e.rn = 1
		  ) t7
on t6.id = t7.comp_id
;
commit;