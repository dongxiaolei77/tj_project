-- ---------------------------------------
-- 开发人   : liyy
-- 开发时间 ：20210311
-- 目标表   :  dwd_evt_wf_task_info
-- 源表     ：
         --   dw_nd.ods_t_act_hi_taskinst_v2 工作流审批表
         --   dw_nd.ods_act_hi_approve        工作流--审批节点信息
         --   dw_nd.ods_self_task_return_info 任务撤回退回记录信息
         --   dw_nd.ods_t_biz_project_main 主项目表
         --   dw_nd.ods_t_biz_proj_xz 续支项目表
         --   dw_nd.ods_t_biz_proj_loan_check 贷后检查信息表

-- 变更记录 ：20210422 业务系统放款信息表中只有 本次放款日、本次到期日, 放款日期 部分迁移后没有数据，需要取历史的数据 dwd_guar_info 放款时间、到期时间
--            20211011 1.增加保后检查已终止数据 2.自主续支        
--            20220211统一修改
--            20220909 update_time替换为db_update_time wyx
--            20230927 增加一个字段：任务节点状态 0处理中 1已退回 2已撤回 3已完成 zhangfl
--            20241201 脚本的统一变更，MySQL5.0转MySQL8.0 zhangfl 
-- ---------------------------------------

-- add 20230927 增加任务节点的状态
drop table if exists dw_tmp.tmp_dwd_evt_wf_task_info_status ;
create Table if not exists dw_tmp.tmp_dwd_evt_wf_task_info_status(
task_id                 varchar(64)     comment '任务ID'
,data_source            varchar(20)     comment '数据来源'
,task_status            varchar(2)      comment '任务状态: 0处理中 1已退回 2已撤回 3已完成'

,index idx_tmp_dwd_evt_wf_task_info_status_task_id(task_id, data_source)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin comment= '工作流节点最新状态';

-- V1
-- V2
insert into dw_tmp.tmp_dwd_evt_wf_task_info_status(
task_id
,data_source
,task_status
)
select t1.id_ as task_id
   ,'V2'
   ,case 
      when t1.end_time_ is null then '0' 
      when t2.type_code_ <> 0 then t2.type_code_ 
      when t3.operate = '1' then '2'
      when t3.operate = '2' then '1' 
      else '3' 
    end as task_status 
from
(
	select id_, end_time_, LAST_UPDATED_TIME_
	from
	(
		select id_, end_time_, LAST_UPDATED_TIME_ ,row_number()over(partition by id_ order by last_updated_time_ desc) rn
		from dw_nd.ods_t_act_hi_taskinst_v2
	) a
	where a.rn = 1
)   t1  -- 工作流审批表V2
left join 
(
	select task_id_, max(type_code_ ) as type_code_
	from dw_nd.ods_act_hi_approve 
	group by task_id_
) t2   -- 工作流--审批节点信息V2（有完全重复数据，去重
on t1.id_ = t2.task_id_ and t2.type_code_ in (0,1,2)
left join dw_nd.ods_self_task_return_info t3 -- 任务撤回退回记录信息
on t1.id_ = t3.task_id and t3.operate in (1,2)

where date_format(t1.LAST_UPDATED_TIME_,'%Y%m%d') = '${v_sdate}' -- 增量
;
commit;


-- 工作流任务信息表
drop table if exists dw_base.tmp_dwd_evt_wf_task_info ;

commit;

CREATE TABLE dw_base.tmp_dwd_evt_wf_task_info (
   day_id varchar(8) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '数据日期',
   task_id varchar(64) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '任务ID',
   proj_no varchar(60) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '项目编号',
   task_type varchar(100) comment '任务类型' ,
   verson_id int(11) DEFAULT NULL COMMENT '版本号',
   task_node varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '任务节点编号',
   inst_id varchar(64) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '流程实例ID',
   exec_id varchar(64) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '执行实例ID',
   task_name varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '任务名',
   worker_id varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '办理人',
   begin_tm datetime DEFAULT NULL COMMENT '任务开始时间',
   recv_tm datetime DEFAULT NULL COMMENT '任务领取时间',
   end_tm datetime DEFAULT NULL COMMENT '任务结束时间',
   take_tm int(11) DEFAULT NULL COMMENT '任务持续时间',
   del_resn varchar(4000) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '删除原因',
   updt_tm datetime DEFAULT NULL COMMENT '最近更新时间',
   data_source varchar(20) comment '数据来源',
   task_status varchar(2)  comment '任务状态: 0处理中 1已退回 2已撤回 3已完成',
   KEY task_id (task_id)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=COMPACT COMMENT='工作流审批表'
 ;

commit;

-- 版本1
-- 版本2 
drop table if exists dw_base.tmp_dwd_evt_wf_task_info_guar ;

commit;

CREATE TABLE dw_base.tmp_dwd_evt_wf_task_info_guar (
   code varchar(80) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '数据日期',
   wf_inst_id varchar(80) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '任务ID',
   index(wf_inst_id)
) ;

insert into dw_base.tmp_dwd_evt_wf_task_info_guar
select distinct  code,wf_inst_id 
from dw_nd.ods_t_biz_project_main  
where wf_inst_id is not null 
 and   date_format(update_time,'%Y%m%d') <= '${v_sdate}' -- 新增
;
commit;
insert into dw_base.tmp_dwd_evt_wf_task_info_guar
select  
distinct code,wf_inst_id
from  dw_nd.ods_t_biz_proj_xz 
where wf_inst_id is not null 
and   date_format(db_update_time,'%Y%m%d') <= '${v_sdate}'  -- 新增 -- mdy 20220909
;
commit ;
insert into dw_base.tmp_dwd_evt_wf_task_info_guar
select  
distinct code,wf_inst_id
from dw_nd.ods_t_biz_proj_loan_check
where wf_inst_id is not null 
and   date_format(update_time,'%Y%m%d') <= '${v_sdate}' -- 新增
;
commit ;


insert into dw_base.tmp_dwd_evt_wf_task_info
select
'${v_sdate}' 
-- date_format(LAST_UPDATED_TIME_,'%Y%m%d')
,ID_            -- 任务ID
,t2.code
,substring_index(t1.proc_def_id_,':',1)
,REV_           -- 版本号
,TASK_DEF_KEY_  -- 任务定义键
,PROC_INST_ID_  -- 流程实例ID
,EXECUTION_ID_  -- 执行实例ID
,NAME_               -- 任务名
,ASSIGNEE_           -- 办理人
,START_TIME_         -- 任务开始时间
,CLAIM_TIME_         -- 任务领取时间
,END_TIME_           -- 任务结束时间
,DURATION_/1000           -- 任务持续时间
,DELETE_REASON_      -- 删除原因
,LAST_UPDATED_TIME_  -- 最近更新时间
,'V2'
,t3.task_status      -- 任务状态
from dw_nd.ods_t_act_hi_taskinst_v2  t1 
left join dw_base.tmp_dwd_evt_wf_task_info_guar t2 
on t1.PROC_INST_ID_= t2.wf_inst_id
left join dw_tmp.tmp_dwd_evt_wf_task_info_status t3
on t1.ID_ = t3.task_id and t3.data_source = 'V2'
where date_format(LAST_UPDATED_TIME_,'%Y%m%d') = '${v_sdate}'
;
commit;

-- 重跑策略
delete from dw_base.dwd_evt_wf_task_info    where  task_id in  
(
select task_id from dw_base.tmp_dwd_evt_wf_task_info t2  
)  ;
commit ;

insert into dw_base.dwd_evt_wf_task_info
select 
day_id       -- 数据日期
,task_id     -- 任务ID
,proj_no     -- 项目编号
,task_type   -- 任务类型
,verson_id   -- 版本号
,task_node   -- 任务节点编号
,inst_id     -- 流程实例ID
,exec_id     -- 执行实例ID
,task_name   -- 任务名
,worker_id   -- 办理人
,begin_tm    -- 任务开始时间
,recv_tm     -- 任务领取时间
,end_tm      -- 任务结束时间
,take_tm     -- 任务持续时间
,del_resn    -- 删除原因
,updt_tm     -- 最近更新时间
,data_source
,task_status
from dw_base.tmp_dwd_evt_wf_task_info
;
commit ;

