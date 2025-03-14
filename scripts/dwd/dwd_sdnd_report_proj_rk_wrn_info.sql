-- ----------------------------------------
-- 开发人   : 
-- 开发时间 ：
-- 目标表   ：dw_base.dwd_sdnd_report_proj_rk_wrn_info      风险预警记录
-- 源表     ：                                     
--            dw_nd.ods_t_loan_after_risk_track    风险项目跟踪与落实信息表
--            dw_base.dwd_sdnd_report_biz_no_base  国担上报范围表
-- 备注     ：
-- 变更记录 ：20240831 增加注释，代码结构优化 WangYX
--            20241201 脚本的统一变更，TDS转MySQL8.0 zhangfl
-- ----------------------------------------
-- 日增量加载
delete from dw_base.dwd_sdnd_report_proj_rk_wrn_info where day_id = '${v_sdate}' ;
commit;

insert into dw_base.dwd_sdnd_report_proj_rk_wrn_info
(
day_id
,proj_no_prov	-- 省农担担保项目编号
,rk_wrn_src_cd	-- 风险预警来源代码
,rk_mgmt_rslt	-- 风险处置结论	
)
select	'${v_sdate}' as day_id
		,proj_no_prov	-- 省农担担保项目编号
		,rk_wrn_src_cd	-- 风险预警来源代码
		,rk_mgmt_rslt	-- 风险处置结论	
from(
	select t2.biz_no as proj_no_prov
		,case when find_in_set('1',t1.task_source_cd) > 0 then '1'
			when find_in_set('4',t1.task_source_cd) > 0 then '4'
			when find_in_set('7',t1.task_source_cd) > 0 then '7'
			else substring_index(t1.task_source_cd,',', 1)
			end as rk_wrn_src_cd		-- 风险预警来源代码，取首次预警来源 /*取代偿业务的风险项目跟踪落实数据，只要包含自主保后、专项保后、常规保后（1，4，7）为农担公司人员，其余为大数据保后*/
		,t1.task_stt as rk_mgmt_rslt    -- 风险处置结论
		,row_number() over(partition by t2.biz_no order by t1.risk_dt) as rk /*取确认风险时间最新的一笔*/
	from
	(
		select	t1.id
				,t1.project_id  as proj_id
				,t1.task_source as task_source_cd
				,case t1.task_status
					when '50' then '风险'
					when '60' then '风处会代偿同意'
					when '90' then '已解保'
					when '93' then '已代偿'
					when '94' then '已解除'
					when '95' then '已化解'
					when '96' then '已过期'
					when '98' then '已终止'
					when '99' then '已否决'
					else t1.task_status
				 end as task_stt
				,date_format(t1.create_time, '%Y%m%d') as risk_dt
		from
		(
			select	t1.id, t1.project_id, t1.task_source, t1.task_status, t1.create_time
					,row_number()over(partition by t1.id order by t1.db_update_time desc, t1.update_time desc) rn
			from dw_nd.ods_t_loan_after_risk_track t1 -- 风险项目跟踪与落实信息表
		) t1
		where t1.rn = 1
	) t1
	inner join dw_base.dwd_sdnd_report_biz_no_base t2 -- 国担上报范围表
	on t1.proj_id = t2.biz_id
	and t2.day_id = '${v_sdate}'
	where t1.task_stt in ('已代偿','已解除','已化解')
) t
where rk = 1
;
commit;