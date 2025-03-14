-- ---------------------------------------
-- 开发人   : zhangfl
-- 开发时间 : 20240819
-- 目标表   : dw_base.dwd_evt_loan_after_task_info                   担保业务--保后检查信息表--事件域
-- 源表     : dw_nd.ods_t_loan_after_task           保后任务详情表
--            dw_nd.ods_t_project_v1                保后项目主表
--            dw_nd.ods_t_loan_after_task_pool      保后任务池
--            dw_nd.ods_t_loan_after_check          保后检查表
--            dw_nd.ods_t_sys_data_dict_value_v2    字典表
--            dw_base.dim_area_info                          地理行政区划表--公共域
--            dw_tmp.tmp_incre_table
-- 备注     : 
-- 变更记录 : 20241201 脚本的统一变更，TDS转MySQL8.0 zhangfl
-- ---------------------------------------
truncate table dw_base.dwd_evt_loan_after_task_info;
insert into dw_base.dwd_evt_loan_after_task_info
(
day_id               -- '数据加载日期'
,id                  -- '物理ID'
,proj_no             -- '主项目编号'
,proj_id             -- '主项目ID'
,wf_inst_id          -- '流程实例ID'
,scr_cust_id         -- '业务系统客户号'
,cust_name           -- '客户姓名'
,cert_no             -- '证件号'
,city_code           -- '地市编码'
,city_name           -- '地市名称'
,district_code       -- '区县编码'
,district_name       -- '区县名称'
,report_dt           -- '保后检查登记日期'
,check_dt            -- '保后检查日期'
,check_type          -- '保后检查方式'
,check_opinion       -- '保后检查意见'
,task_source         -- '任务来源'
,task_time           -- '任务预警时间'
,fir_task_time       -- '客户首次预警时间'
,data_warn_reason    -- '大数据预警原因'
,data_month          -- '大数据统计月份'
,data_warn_type      -- '大数据风险类别'
,task_stt            -- '任务状态'
,limit_dt            -- '任务完成时限'
)
select	'${v_sdate}'
		,t1.id
		,t2.code                                                               as proj_no
		,t1.project_id                                                         as proj_id
		,t1.wf_inst_id
		,t2.cust_id                                                            as scr_cust_id
		,t4.cust_name
		,t4.cust_identity_no                                                   as cert_no
		,if(length(t4.city) = 0 or t4.city is null, null, t4.city)             as city_code
		,t9.area_name                                                          as city_name
		,if(length(t4.district) = 0 or t4.district is null, null, t4.district) as district_code
		,t8.area_name                                                          as district_name
		,date_format(t5.report_date, '%Y%m%d')                                   as report_dt
		,date_format(t5.check_date, '%Y%m%d')                                    as check_dt
		,case t5.check_mode
			when '00' then '无要求'
			when '01' then '现场'
			when '02' then '非现场'
			else t5.check_mode
		 end as check_type
		,case t5.check_conclusion
			when '01' then '正常'
			when '02' then '关注'
			when '03' then '可疑'
			when '04' then '次级'
			when '05' then '损失'
			else t5.check_conclusion
		 end as check_opinion
		,t6.task_source
		,date_format(t1.task_time, '%Y%m%d')                                     as task_time
		,date_format(t4.first_warn_time, '%Y%m%d')                               as fir_task_time
		,t1.data_warn_reason
		,t1.data_month
		,t7.data_warn_type
		,case t1.task_status
			when '10' then '待确认'
			when '20' then '提报中'
			when '30' then '审核中'
			when '40' then '正常'
			when '50' then '风险'
			when '60' then '风处会代偿同意'
			when '61' then '风处会代偿否决'
			when '93' then '已代偿'
			when '94' then '已解除'
			when '95' then '已化解'
			when '96' then '已过期'
			when '98' then '已终止'
			when '99' then '已否决'
			else t1.task_status
		 end as task_stt
		,date_format(t1.limit_time, '%Y%m%d')                                    as limit_dt
from
(
	select	t1.id
			,t1.pool_id
			,t1.project_id
			,t1.wf_inst_id
			,t1.task_time
			,t1.data_warn_reason
			,t1.data_month
			,t1.task_status
			,t1.limit_time
	from
	(
		select	t1.id
				,t1.pool_id
				,t1.project_id
				,t1.wf_inst_id
				,t1.task_time
				,t1.data_warn_reason
				,t1.data_month
				,t1.task_status
				,t1.limit_time
				,row_number()over(partition by t1.id order by t1.db_update_time desc, t1.update_time desc ) rn
		from dw_nd.ods_t_loan_after_task t1    -- 保后任务详情表
	) t1
	where t1.rn = 1
) t1
left join
(
	select	t1.id
			,t1.cust_id
			,t1.code
	from
	(
		select	t1.id
				,t1.cust_id
				,t1.code
				,row_number()over(partition by t1.id order by t1.update_time desc ) rn
		from dw_nd.ods_t_project_v1 t1          -- 发起保后任务的项目表
	)t1
	where t1.rn = 1
) t2           -- 保后项目主表
on t1.project_id = t2.id

left join
(
	select	t1.id
			,t1.city
			,t1.district
			,t1.cust_name
			,t1.cust_identity_no
			,t1.first_warn_time
	from
	(
		select	t1.id
				,t1.city
				,t1.district
				,t1.cust_name
				,t1.cust_identity_no
				,t1.first_warn_time
				,row_number()over(partition by t1.id order by t1.db_update_time desc, t1.update_time desc ) rn
		from dw_nd.ods_t_loan_after_task_pool t1 -- 保后任务池
	) t1
	where t1.rn = 1
) t4
on t1.pool_id = t4.id
left join
(
	select	t1.task_id
			,t1.report_date
			,t1.check_date
			,t1.check_mode
			,if(length(t1.check_conclusion) = 0 or t1.check_conclusion is null, null, t1.check_conclusion) as check_conclusion
			,row_number()over(partition by t1.task_id order by t1.report_date desc, t1.db_update_time desc, t1.update_time desc) rn
	from dw_nd.ods_t_loan_after_check t1      -- 保后检查表
) t5
on t5.task_id = t1.id
and t5.rn = 1
left join
(
	select	t1.id
			,group_concat(t2.value, ',') as task_source
	from
	(-- 任务来源拆分
		select	t1.id
				,substring_index(substring_index(t1.task_source,',',t2.ID + 1),',',-1) as task_source
		from
		(
			select	id
					,task_source
			from
			(  
				select	id
						,task_source
						,row_number()over(partition by t1.id order by t1.db_update_time desc, t1.update_time desc) rn
				from dw_nd.ods_t_loan_after_task t1 -- 保后任务详情表
				where date_format(t1.db_update_time, '%Y%m%d') <= '${v_sdate}'
			) t1
			where t1.rn = 1
		) t1
		inner join dw_tmp.tmp_incre_table t2
		on t2.ID < (length(t1.task_source) - length(replace(t1.task_source,',',''))+1)
	) t1
	left join
	(
		select	t1.code
				,t1.value
				,row_number()over(partition by code order by t1.update_time desc) rn
		from dw_nd.ods_t_sys_data_dict_value_v2 t1
		where dict_code = 'taskSource'
	) t2
	on t1.task_source = t2.code
	and t2.rn = 1
	group by t1.id
) t6
on t1.id = t6.id
left join
(
	select	t1.id
			,group_concat(t2.value, ',') as data_warn_type
	from
	(-- 任务来源拆分
		select	t1.id
				,substring_index(substring_index(t1.data_warn_type,',',t2.ID + 1),',',-1) as data_warn_type
		from
		(
			select	id
					,data_warn_type
			from
			(  
				select	id
						,data_warn_type
						,row_number()over(partition by t1.id order by t1.db_update_time desc, t1.update_time desc) rn
				from dw_nd.ods_t_loan_after_task t1 -- 保后任务详情表
				where date_format(t1.db_update_time, '%Y%m%d') <= '${v_sdate}'
			) t1
			where t1.rn = 1
		) t1
		inner join dw_tmp.tmp_incre_table t2
		on t2.ID < (length(t1.data_warn_type) - length(replace(t1.data_warn_type,',',''))+1)
	) t1
	left join
	(
		select	t1.code
				,t1.value
				,row_number()over(partition by code order by t1.update_time desc) rn
		from dw_nd.ods_t_sys_data_dict_value_v2 t1
		where dict_code = 'riskType'
	) t2
	on t1.data_warn_type = t2.code
	and t2.rn = 1
	group by t1.id
) t7
on t1.id = t7.id

left join dw_base.dim_area_info t8                     -- 地理行政区划表--公共域
on t4.district = t8.area_cd
left join dw_base.dim_area_info t9                     -- 地理行政区划表--公共域
on t4.city = t9.area_cd

;

commit;
