-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250515
-- 目标表   ：dw_base.ads_rpt_tjnd_risk_branch_inst_compt_stat 风险部-省级农担公司分支机构代偿情况统计季报
-- 源表     ：
--          新业务系统
--          dw_base.dwd_guar_info_all                           担保台账信息
--          dw_base.dwd_imp_area_branch                         区划映射办事处
--          dw_base.dwd_guar_info_onguar                        担保台账在保信息
--          dw_nd.ods_t_biz_proj_recovery_record                追偿记录表
--          dw_nd.ods_t_biz_proj_recovery_repay_detail_record   登记还款记录
--          dw_base.dwd_guar_compt_info                         代偿信息汇总表
--          ods_creditmid_v2_z_migrate_afg_business_infomation
--          ods_creditmid_v2_z_migrate_bh_compensatory
--          ods_creditmid_v2_z_migrate_afg_voucher_repayment
--          ods_creditmid_v2_z_migrate_bh_recovery_tracking
--          ods_creditmid_v2_z_migrate_bh_recovery_tracking_detail
-- 备注     ：
-- 变更记录 ：20250929 增加旧系统逻辑 WangYX
-- ---------------------------------------4
-- 创建临时表
drop table if exists dw_tmp.tmp_ads_rpt_tjnd_risk_branch_inst_compt_stat_y_unguar_amt;
create table  dw_tmp.tmp_ads_rpt_tjnd_risk_branch_inst_compt_stat_y_unguar_amt (
  inst_name varchar(50)  comment '办事处',
  year_unguar_amt decimal(18,2)  comment '本年解保金额',
  year_unguar_cnt int comment '本年解保项目数'
)  ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC COMMENT='办事处本年解保金额';
commit;
insert into dw_tmp.tmp_ads_rpt_tjnd_risk_branch_inst_compt_stat_y_unguar_amt
select inst_name
      ,sum(year_unguar_amt) / 10000 as year_unguar_amt
      ,count(if(proj_stt_cd in ('04','05') and year_unguar_amt > 0,1,null)) as year_unguar_cnt
from (
            -- 本年解保金额
            select t1.proj_no_prov,
			       t1.proj_stt_cd,
            	case
            		when t1.proj_blogto_org_no = '1200000001' then '宁河东丽办事处'
            		when t1.proj_blogto_org_no = '1200000002' then '津南滨海新区办事处'
            		when t1.proj_blogto_org_no = '1200000003' then '武清北辰办事处'
            		when t1.proj_blogto_org_no = '1200000004' then '西青静海办事处'
            		when t1.proj_blogto_org_no = '1200000005' then '蓟州办事处'
            		when t1.proj_blogto_org_no = '1200000006' then '宝坻办事处'
            		else ''
            	end as inst_name,
				case when t1.proj_stt_cd in ('04','05') and t2.year_unguar_amt > 0  and t1.proj_no_prov  like 'TJ%' then coalesce(t4.loan_amt,0) - coalesce(t5.ly_accu_rpmt_amt,0) -- [对于老系统项目，本年解保=累计放款金额-累积至上年末还款金额]
						 when t1.proj_stt_cd in ('04','05') then t2.year_unguar_amt
                         else 0 end                 as  year_unguar_amt	                      -- 本年新增解保金额   
            from dw_base.dwd_tjnd_report_proj_base_info	t1 -- 【项目信息汇总表】
            left join (                                             
            	select proj_no_prov -- 农担体系担保项目编号
                	,max(unguar_dt)     as unguar_dt -- 解保日期
            		,max(unguar_reg_dt) as unguar_reg_dt -- 解保登记日期
                    ,sum(case when year(unguar_reg_dt) = left('${v_sdate}',4) then unguar_amt else 0 end) as  year_unguar_amt       --	本年新增解保金额     [sum(解保金额) where 解保登记日期=本年]
              	from dw_base.dwd_tjnd_report_proj_unguar_info --  解保记录表
              	where day_id = '${v_sdate}'                                                              
              	group by proj_no_prov
            ) t2 on t1.proj_no_prov = t2.proj_no_prov
			left join (
				        select proj_no_prov
						      ,sum(loan_amt) * 10000      as loan_amt  -- 放款金额
						from dw_base.dwd_tjnd_report_proj_loan_rec_info       
						where day_id = '${v_sdate}'                                                              
                        group by proj_no_prov
					  )                                  t4           --     【放款】
			on t1.proj_no_prov = t4.proj_no_prov
            left join (
            	select proj_no_prov
            		,sum(case when year(rpmt_reg_dt) < left('${v_sdate}',4) then rpmt_prin_amt * 10000 else 0 end) as ly_accu_rpmt_amt  -- 截止到上年末的累计还款金额（元）     [sum(还款本金金额) where 还款登记日期 < 本年]
            	from dw_base.dwd_tjnd_report_proj_rpmt_info      -- 还款记录
            	where day_id = '${v_sdate}'                                                              
            	group by proj_no_prov
             ) t5 on t1.proj_no_prov = t5.proj_no_prov							 
            where t1.day_id = '${v_sdate}'
	  ) a 
group by inst_name;
commit;


-- step0 重跑策略
delete
from dw_base.ads_rpt_tjnd_risk_branch_inst_compt_stat
where day_id = '${v_sdate}';
commit;


insert into dw_base.ads_rpt_tjnd_risk_branch_inst_compt_stat
(
 day_id	          -- 数据日期
,inst_name	      -- 分支机构名称
,inst_type	      -- 分支机构类型
,off_staff_cnt	  -- 专职人员数量
,compt_amt	      -- 本年累计代偿金额
,compt_cnt	      -- 本年累计代偿项目数
,release_amt	  -- 本年累计解保金额
,release_cnt	  -- 本年累计解保项目数
,compt_chance	  -- 本年代偿率
,risk_amt	      -- 本年累计追偿金额
,risk_chance	  -- 本年考虑追偿后的代偿率
)
select 
 '${v_sdate}'                  as day_id	          -- 数据日期
,t2.inst_name	      -- 分支机构名称
,t2.inst_type	      -- 分支机构类型
,t2.off_staff_cnt	  -- 专职人员数量
,t2.compt_amt	      -- 本年累计代偿金额
,t2.compt_cnt	      -- 本年累计代偿项目数
,t3.year_unguar_amt as release_amt	  -- 本年累计解保金额                                           -- [这里统一用国农担报表的逻辑]
,t3.year_unguar_cnt as release_cnt	  -- 本年累计解保项目数
,round(t2.compt_amt / (t3.year_unguar_amt + t2.compt_amt) * 100,2) as compt_chance	  -- 本年代偿率
,t2.risk_amt	      -- 本年累计追偿金额
,round((t2.compt_amt - t2.risk_amt) / (t3.year_unguar_amt + t2.compt_amt) * 100,2) as risk_chance	  -- 本年考虑追偿后的代偿率
from 
(
select inst_name
,inst_type
,off_staff_cnt
,sum(t1.compt_amt) as compt_amt                            -- 本年累计代偿金额
,sum(t1.compt_cnt) as compt_cnt                            -- 本年累计代偿项目数
-- ,sum(t1.unguar_amt) + sum(t1.compt_amt) as release_amt     -- 本年累计解保金额
,sum(t1.unguar_cnt) + sum(t1.compt_cnt) as release_cnt     -- 本年累计解保项目数
-- ,round(sum(t1.compt_amt) / (sum(t1.unguar_amt) + sum(t1.compt_amt)) * 100,2) as compt_chance -- 本年代偿率
,sum(t1.year_recovery_amt) as risk_amt                     -- 本年累计追偿金额
-- ,round((sum(t1.compt_amt) - sum(year_recovery_amt)) / (sum(t1.unguar_amt) + sum(t1.compt_amt)) * 100,2) as risk_chance
from (
	select -- 旧系统
	case when enter_code = 'NHDLBranch'   then '宁河东丽办事处'   
		when enter_code = 'JNBHBranch'   then '津南滨海新区办事处' 
		when enter_code = 'BCWQBranch'   then '武清北辰办事处'   
		when enter_code = 'XQJHBranch'   then '西青静海办事处'   
		when enter_code = 'JZBranch'     then '蓟州办事处'       
		when enter_code = 'BDBranch'     then '宝坻办事处'       
		end as inst_name                                   -- 分支机构名称
	,'办事处' as inst_type                                 -- 分支机构类型
	,case when enter_code = 'NHDLBranch' then 4
		when enter_code = 'JNBHBranch' then 4
		when enter_code = 'BCWQBranch' then 4
		when enter_code = 'XQJHBranch' then 4
		when enter_code = 'JZBranch' then 5
		when enter_code = 'BDBranch' then 4
		end as off_staff_cnt                               -- 专职人员数量
	,count(case when year(date_format(t2.payment_date,'%Y-%m-%d')) = substring('${v_sdate}', 1, 4) and t2.over_tag = 'BJ' and t2.status = 1 then t2.id_cfbiz_underwriting
		else null end ) as compt_cnt                       -- 本年已代偿笔数
	,sum(case when year(date_format(t2.payment_date,'%Y-%m-%d')) = substring('${v_sdate}', 1, 4) and t2.over_tag = 'BJ' and t2.status = 1 then t2.total_compensation
		else 0 end ) as compt_amt                          -- 本年已代偿金额
	,count(t3.id_business_information) as unguar_cnt       -- 本年已解保笔数
	,sum(t3.unguar_amt) as unguar_amt		               -- 本年已解保金额
	,sum(t4.year_recovery_amt) as year_recovery_amt        -- 本年追偿金额
	from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation t1
	left join dw_nd.ods_creditmid_v2_z_migrate_bh_compensatory t2 -- 代偿表
	on t1.id = t2.id_cfbiz_underwriting
	left join (
		select
		id_business_information
		,sum(repayment_principal) as unguar_amt
		from dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_repayment
		where (delete_flag = '1' or delete_flag is null)
		and date_format(created_time,'%Y') = left('${v_sdate}',4)
		group by id_business_information
	) t3
	on t1.id = t3.id_business_information
	left join
	(
		select a.id_cfbiz_underwriting,
			sum(case
					when year(date_format(b.entry_data, '%Y-%m-%d')) = substring('${v_sdate}', 1, 4)
						then b.cur_recovery
					else 0 end) as year_recovery_amt -- 当年追偿金额
		from dw_nd.ods_creditmid_v2_z_migrate_bh_recovery_tracking a -- 追偿跟踪表
				inner join dw_nd.ods_creditmid_v2_z_migrate_bh_recovery_tracking_detail b -- 追偿跟踪详情表
--							on b.id_recovery_tracking = a.id
                            on ifnull(b.ID_RECOVERY_TRACKING = a.ID,b.GUARANTEE_CODE = a.RELATED_ITEM_NO) 
		group by a.id_cfbiz_underwriting
	) t4 -- 追偿跟踪表
	on t1.id = t4.id_cfbiz_underwriting
	where t1.gur_state != '50' -- [排除在保转进件]
	and '${v_sdate}' =
				date_format(last_day(makedate(extract(year from '${v_sdate}'), 1) +
										interval quarter('${v_sdate}') * 3 - 1 month),
							'%Y%m%d')
	group by enter_code
	
	union all
	
	select -- 新系统
	case when branch_off = 'NHDLBranch' then '宁河东丽办事处'
		when branch_off = 'JNBHBranch' then '津南滨海新区办事处'
		when branch_off = 'BCWQBranch' then '武清北辰办事处'
		when branch_off = 'XQJHBranch' then '西青静海办事处'
		when branch_off = 'JZBranch' then '蓟州办事处'
		when branch_off = 'BDBranch' then '宝坻办事处'
		end                             as inst_name
	,'办事处'                            as inst_type
	,case when branch_off = 'NHDLBranch' then 4
		when branch_off = 'JNBHBranch' then 4
		when branch_off = 'BCWQBranch' then 4
		when branch_off = 'XQJHBranch' then 4
		when branch_off = 'JZBranch' then 5
		when branch_off = 'BDBranch' then 4
		end as off_staff_cnt
	,count(t3.guar_id) as compt_cnt                -- 本年已代偿笔数
	,sum(t3.compt_amt) as compt_amt                -- 本年已代偿金额
	,sum(case when year(t2.unguar_dt) = year('${v_sdate}') and t1.item_stt = '已解保'
		then 1 else 0 end) as unguar_cnt         -- 本年已解保笔数
	,sum(case when year(t2.unguar_dt) = year('${v_sdate}') and t1.item_stt = '已解保'
		then guar_amt end) as unguar_amt		   -- 本年已解保金额
	,sum(year_recovery_amt) as year_recovery_amt   -- 本年追偿金额
	from(
			select guar_id,
					country_code,
					item_stt,
					guar_amt
			from dw_base.dwd_guar_info_all_his
			where day_id = '${v_sdate}'
			and data_source = '担保业务管理系统新'
			and '${v_sdate}' =
				date_format(last_day(makedate(extract(year from '${v_sdate}'), 1) +
										interval quarter('${v_sdate}') * 3 - 1 month),
							'%Y%m%d')
		) t1
			left join
		(
			select guar_id,    -- 业务编号
					project_id, -- 项目id
					unguar_dt   -- 解保日期
			from dw_base.dwd_guar_info_stat
		) t2 on t1.guar_id = t2.guar_id
			left join
		(
			select guar_id    as guar_id,    -- 项目编号
					compt_time as compt_date, -- 代偿拨付日期
					compt_amt  as compt_amt   -- 代偿金额(本息)万元
			from dw_base.dwd_guar_compt_info_his
			where day_id = '${v_sdate}'
			and year(compt_time) = year('${v_sdate}')
		) t3 on t1.guar_id = t3.guar_id
			left join
		(
			select t1.project_id,                                     -- 项目id
					sum(t2.shou_comp_amt) / 10000 as year_recovery_amt -- 当年追偿金额
			from dw_nd.ods_t_biz_proj_recovery_record t1
					left join dw_nd.ods_t_biz_proj_recovery_repay_detail_record t2 on t1.reco_id = t2.record_id
			where year(real_repay_date) = year('${v_sdate}')
			group by t1.project_id
		) t4 on t2.project_id = t4.project_id
			left join
		(
	        select code,branch as branch_off
	        from (select *,row_number() over (partition by code order by db_update_time desc) as rn from dw_nd.ods_t_biz_project_main) a 
            where a.rn = 1	
		) t5 on t1.guar_id = t5.code
	group by branch_off
) t1
group by inst_name,inst_type,off_staff_cnt
) t2
left join dw_tmp.tmp_ads_rpt_tjnd_risk_branch_inst_compt_stat_y_unguar_amt t3
on t2.inst_name = t3.inst_name 
where round(t2.compt_amt / (t3.year_unguar_amt + t2.compt_amt) * 100,2) >= 3 -- 代偿率、考虑追偿的代偿在3%以上（含3%）的分支机构
;
commit;



