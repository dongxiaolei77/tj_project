-- ----------------------------------------
-- 开发人   : 
-- 开发时间 ：
-- 目标表   ：dwd_sdnd_report_proj_loan_rec_info       放款记录
-- 源表     ：dw_base.dwd_guar_info_all                 业务信息宽表--项目域
--           dw_base.dwd_sdnd_report_biz_no_base       国担上报范围表
--           dw_nd.ods_t_biz_proj_loan                 项目放款表
--           dw_base.dwd_sdnd_report_biz_loan_bank     国担上报银行映射表
--           dw_base.dwd_evt_wf_task_info              工作流审批表
--           dw_base.dwd_sdnd_report_proj_unguar_info  解保记录
--           dw_nd.ods_t_biz_proj_loan_check           贷后检查，取自主续支业务
-- 备注     ：
-- 变更记录 ：20240831 增加注释，代码结构优化 WangYX
--            20240918 放款凭证编号切源 wyx
--            20241201 脚本的统一变更，TDS转MySQL8.0 zhangfl
-- ----------------------------------------


-- 日增量加载
delete from dw_base.dwd_sdnd_report_proj_loan_rec_info where day_id = '${v_sdate}';
commit;

insert into dw_base.dwd_sdnd_report_proj_loan_rec_info
(
day_id
,proj_no_prov	    -- 省农担担保项目编号
,loan_doc_no	    -- 放款凭证编号
,loan_bank_no	    -- 放款金融机构代码
,loan_bank_br_name	-- 放款金融机构（分支机构）
,loan_amt	        -- 放款金额
,loan_rate	        -- 放款利率
,loan_strt_dt	    -- 放款日期
,loan_end_dt	    -- 放款到期日期
,loan_reg_dt	    -- 放款登记日期
)
select distinct '${v_sdate}' 							as day_id
	,t1.guar_id 										as proj_no_prov	        -- 省农担担保项目编号
	,substring_index(substring_index(substring_index(substring_index(substring_index(substring_index(t3.debt_on_bond_code,',',1), '，',1),";",1), '；',1), '/',1), '、',1) as loan_doc_no -- 放款凭证编号 -- 非结构化数据，提取第一笔编号--
	,case when t4.dept_name in ('农村商业银行','村镇银行') or (t1.guar_prod = '农耕e贷' and t4.bank_name = '农村商业银行') or t4.dept_id is null then t1.guar_id -- 省端机构名称为农村商业银行、村镇银行，或者产品名称为农耕e贷且银行名称为农村商业银行，或者省端机构为空值的，将放款金融机构代码映射为业务编号--
      else t4.dept_id 
      end 											    as loan_bank_no			-- 放款金融机构代码
	,coalesce(t4.bank_name,t4.dept_name)  				as loan_bank_br_name	-- 放款金融机构（分支机构） -- 银行名称空值的，用省端机构名称补充--
	,t1.loan_amt                                        as loan_amt			    -- 放款金额
	,t1.loan_rate/100									as loan_rate			-- 放款利率
	,case when left(t1.guar_id,4) in( 'ZZXZ','BHJC') and t5.task_end_time is not null then t5.task_end_time -- 自主续支优先取市管中心客户经理节点的完成日期--
		  when left(t1.guar_id,4) in( 'ZZXZ','BHJC') and t5.task_end_time is null then least(date(coalesce(t7.submit_dt,'99991231')),date(coalesce(t7.guar_start_dt,'99991231'))) -- 自主续支没有工作流节点的，在提报日期、放款登记日期（上报专用）、担保年度开始日中，取非空最小值--
	      else date(t1.loan_begin_dt) -- --
		  end                                           as loan_strt_dt	        -- 放款日期
	,greatest(date(coalesce(t1.loan_end_dt,'19000101')),coalesce(t6.unguar_dt,'19000101')) as loan_end_dt	-- 放款到期日期 -- 放款结束日、解保日期中，取非空最大值--
	,case when left(t1.guar_id,4) in( 'ZZXZ','BHJC') and t5.task_end_time is not null then t5.task_end_time
		  when left(t1.guar_id,4) in( 'ZZXZ','BHJC') and t7.submit_dt is not null then date(t7.submit_dt) -- 自主续支有有任务流节点取市管理中心客户经理节点的完成时间，没有取提报日期--
	      else date(t1.loan_reg_dt) -- 其他取放款登记日期（上报专用）--
		  end                                           as loan_reg_dt	        -- 放款登记日期
from dw_base.dwd_guar_info_all t1 -- 业务信息宽表--项目域
inner join dw_base.dwd_sdnd_report_biz_no_base t2 -- 国担上报范围表
on t1.guar_id = t2.biz_no
and t2.day_id = '${v_sdate}'
left join
(
	select	t1.id
			,t1.project_id
			,t1.debt_on_bond_code
	from
	(
		select	t1.id, t1.project_id, t1.debt_on_bond_code, row_number()over(partition by t1.id order by t1.db_update_time desc, t1.update_time desc) rn
		from dw_nd.ods_t_biz_proj_loan t1 -- 项目放款表
	) t1
	where t1.rn = 1
) t3
on t2.biz_id = t3.project_id

left join dw_base.dwd_sdnd_report_biz_loan_bank t4 -- 国担上报银行映射表
on t1.guar_id = t4.biz_no
left join
(
	select biz_no
		,date_format(task_end_time, '%Y%m%d') as task_end_time
	from(
		select proj_no as biz_no
			,end_tm as task_end_time
			,row_number() over(partition by proj_no order by end_tm desc) as rk
		from dw_base.dwd_evt_wf_task_info  -- 工作流审批表
		where task_name = '市管理中心客户经理'
	) t
	where rk = 1
) t5
on t1.guar_id = t5.biz_no
left join dw_base.dwd_sdnd_report_proj_unguar_info t6 -- 解保记录
on t1.guar_id = t6.proj_no_prov
and t6.day_id = '${v_sdate}'

left join
(
	select	t1.id
			,t1.project_id
			,t1.code
			,date_format(coalesce(t1.submit_time, t1.create_time), '%Y%m%d') as submit_dt
			,date_format(t1.guar_annu_startdate, '%Y%m%d') as guar_start_dt
	from
	(
		select	t1.id, t1.project_id, t1.code, t1.submit_time, t1.create_time, t1.guar_annu_startdate
				,row_number()over(partition by t1.id order by t1.db_update_time desc, t1.update_time desc) rn
		from dw_nd.ods_t_biz_proj_loan_check t1 -- 贷后检查，取自主续支业务
	) t1
	where t1.rn = 1
) t7
on t1.guar_id = t7.code
;
commit;

