-- ---------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20231220
-- 目标表   ：dw_base.dwd_evt_loan_inst_task_info               担保业务--保后任务流程日志表--事件域
-- 源表     ：dw_nd.ods_t_act_hi_taskinst_v2          工作流审批表-新版本
--            dw_nd.ods_t_loan_after_task      保后检查表
--            dw_nd.ods_t_project_v1           发起保后任务的项目表

-- 备注     ：
--            
-- 变更记录 ：20241201 脚本的统一变更，TDS转MySQL8.0 zhangfl

-- ---------------------------------------
truncate table dw_base.dwd_evt_loan_inst_task_info;
-- 2.V2版本_新业务流程
insert into dw_base.dwd_evt_loan_inst_task_info
(
 day_id                 -- '加载日期'
,cust_no                -- '数仓客户号'
,scr_cust_id            -- '原业务系统客户号',
,proj_no                -- '主项目编号'
,proj_id                -- '主项目ID'
,task_id                -- '流程ID'
,proc_inst_id           -- '流程实例ID'
,version                -- '版本号'
,task_no                -- '任务编号'
,task_name              -- '任务名称'
,task_owner             -- '任务所属人'
,task_transactor        -- '任务办理人'
,task_start_time        -- '任务开始时间'
,task_receive_time      -- '任务领取时间'
,task_end_time          -- '任务结束时间'
,duration               -- '任务持续时长'
,is_back                -- '是否退回 1是0否'
,back_task_no           -- '退回任务编号'
,is_withdraw            -- '是否被上一节点撤回 1是0否'
,withdraw_task_no       -- '主动撤回任务的节点编号'
,is_revoke              -- '客户是否撤销 1是0否'
,seq                    -- '第几次经过该任务'
,`comment`              -- '备注'
)
select	'${v_sdate}'
		,null              as cust_no
		,t3.cust_id        as scr_cust_id
		,t3.code           as proj_no
		,t2.project_id     as proj_id
		,t1.id_            as task_id
		,t1.proc_inst_id_  as proc_inst_id
		,2
		,t1.task_def_key_  as task_no
		,t1.name_          as task_name
		,t1.owner_         as task_owner
		,t1.assignee_      as task_transactor
		,t1.start_time_    as task_start_time
		,t1.claim_time_    as task_receive_time
		,t1.end_time_      as task_end_time
		,t1.duration_      as duration
		,case when t1.delete_reason_ regexp 'Change activity to' then '1'
			  else '0'
		 end               as is_back
		,case when t1.delete_reason_ regexp 'Change activity to' then substring_index(t1.delete_reason_, ' ', -1)
			  else null 
		 end               as back_task_no
		,case when t1.delete_reason_ regexp 'pre_node_revoke_to_delete' then '1'
			  else '0' 
		 end               as is_withdraw
		,case when t1.delete_reason_ regexp 'pre_node_revoke_to_delete' then t1.withdraw_task_no
			  else null 
		 end               as withdraw_task_no
		,case when t1.delete_reason_ regexp 'USER-END' then '1'
			  else '0'
		 end               as is_revoke
		,t1.seq
		,t1.delete_reason_ as `comment`
from 
(
	select	t1.id_
			,t1.task_def_key_
			,t1.proc_inst_id_
			,t1.name_
			,t1.owner_
			,t1.assignee_
			,t1.start_time_  as start_time_   -- 任务开始时间  
			,t1.claim_time_  as claim_time_   -- 任务领取时间
			,t1.end_time_    as end_time_     -- 任务结束时间
			,t1.duration_
			,t1.delete_reason_
			,dense_rank()over(partition by t1.proc_inst_id_, t1.task_def_key_ order by date_format(t1.start_time_, '%Y%m%d%H%i%s') asc) seq
			,lag(t1.task_def_key_,1)over(partition by t1.proc_inst_id_
											order by date_format(t1.start_time_, '%Y%m%d%H%i%s') asc,                                        -- 节点开始开始时间升序排序
													date_format(t1.end_time_, '%Y%m%d%H%i%s') asc,                                           -- 然后根据节点结束时间排序
													case when t1.delete_reason_ regexp 'pre_node_revoke_to_delete' then '0' else '1' end asc  -- 开始时间[时分秒]一样的，比如“评审委员会签”节点，是同时分配给几个人的，算一个节点，前一个节点撤回时，节点同时结束，但仅体现在一个人的流程上，优先排在前边
											)                                    as withdraw_task_no
	from
	(
		select	t1.id_
				,t1.task_def_key_
				,t1.proc_inst_id_
				,t1.name_
				,t1.owner_
				,t1.assignee_
				,t1.start_time_
				,t1.claim_time_
				,t1.end_time_
				,t1.duration_
				,t1.delete_reason_
				,row_number()over(partition by t1.id_ order by t1.last_updated_time_ desc ) rn
		from dw_nd.ods_t_act_hi_taskinst_v2 t1          -- 工作流审批表-新版本
	) t1
	where t1.rn = 1
) t1 
inner join
(
	select	t1.id
			,t1.project_id
			,t1.wf_inst_id
	from
	(
		select	t1.id
				,t1.project_id
				,t1.wf_inst_id
				,row_number()over(partition by t1.id order by t1.db_update_time desc, t1.update_time desc ) rn
		from dw_nd.ods_t_loan_after_task t1    -- 保后检查表
	) t1
	where t1.rn = 1
) t2
on t1.proc_inst_id_ = t2.wf_inst_id

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
) t3
on t2.project_id = t3.id
;
commit;