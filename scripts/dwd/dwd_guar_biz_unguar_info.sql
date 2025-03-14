-- ---------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20240228
-- 目标表   ：dw_base.dwd_guar_biz_unguar_info                  担保年度业务解保信息表--项目域
-- 源表     ：dw_base.dwd_guar_info_all                         业务信息大宽表--项目域
--           dw_base.dwd_guar_info_stat                        业务信息大宽表--项目域
--           dw_nd.ods_t_biz_proj_xz                          续支项目表
--           dw_nd.ods_t_biz_project_main                     进件项目表
--           dw_nd.ods_t_biz_proj_loan_check                  贷后检查自主循环贷项目
--           dw_base.dwd_guar_biz_unguar_info_unguar_dt_lastday 临时表-担保年度业务解保信息表--每日跑批前是T-2业务解保情况

-- 备注     ：解保日期的取值，业务实际变为“已解保”状态业务的day_id，如果多次从“已放款”变为“已解保”，取最近一次的day_id日期
-- 针对MySQL，临时表dwd_guar_biz_unguar_info_unguar_dt_lastday 一旦存入数据不能删除，删除会导致数据异常，解保日期都不对了
           
-- 变更记录 ：20241201 脚本的统一变更，TDS转MySQL8.0 zhangfl

-- ---------------------------------------
-- 1.新建临时表，保存业务解保/代偿的日期
-- 由于MySQL效率问题，不适用历史表的处理逻辑
-- drop table if exists dw_tmp.tmp_dwd_guar_biz_unguar_info_unguar_dt;
-- create table if not exists dw_tmp.tmp_dwd_guar_biz_unguar_info_unguar_dt(
-- day_id              string      comment '数据日期'
-- ,biz_no             string      comment '项目编号'
-- ,biz_unguar_dt      string      comment '解保日期(项目状态变为已解保/代偿的日期)'
-- ,is_fk_once         string      comment '历史表是否有已放款的记录，如果没有则项目进来就是已解保'
-- )comment = '临时表-存项目担保年度解保日期';
-- 
-- insert into dw_tmp.tmp_dwd_guar_biz_unguar_info_unguar_dt
-- (
-- day_id              -- '数据日期'
-- ,biz_no             -- '项目编号'
-- ,biz_unguar_dt      -- '解保日期(项目状态变为已解保/代偿的日期)'
-- ,is_fk_once         -- '历史表是否有已放款的记录，如果没有则项目进来就是已解保'
-- )
-- select	'${v_sdate}'  as day_id
-- 		,t1.biz_no
-- 		,min(t1.day_id) as biz_unguar_dt
-- 		,case when t2.max_fk_day is null then '0' else '1' end as is_fk_once
-- from
-- (
-- 	select	t1.day_id
-- 			,t1.guar_id as biz_no
-- 	from dw_base.dwd_guar_info_all_his t1               -- 业务信息大宽表历史表--项目域
-- 	where t1.item_stt in( '已解保', '已代偿')
-- ) t1
-- left join
-- (
-- 	select	t1.biz_no
-- 			,max(t1.day_id) as max_fk_day           -- 取"已放款"状态业务最后的day_id
-- 	from
-- 	(
-- 		select	t1.day_id
-- 				,t1.guar_id as biz_no
-- 		from dw_base.dwd_guar_info_all_his t1     -- 业务信息大宽表历史表--mysql历史数据
-- 		where item_stt = '已放款'
-- 	) t1
-- 	group by t1.biz_no
-- ) t2
-- on t1.biz_no = t2.biz_no
-- where t1.day_id > t2.max_fk_day -- 取最终"已放款"日期之后的"已解保"数据
-- or t2.max_fk_day is null        -- 或者历史数据中不存在"已放款"记录的
-- 
-- group by t1.biz_no, case when t2.max_fk_day is null then '0' else '1' end
-- ;

-- 0.首次加载先建表
create table if not exists dw_base.dwd_guar_biz_unguar_info_unguar_dt_lastday(
day_id             varchar(8)  comment '数据日期'
,biz_no            varchar(50) comment '项目编号'
,biz_unguar_dt     varchar(8)  comment '解保日期(项目状态变为已解保的日期)'
  
,index ind_tmp_dwd_guar_biz_unguar_info_bizno(biz_no)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin comment= '临时表-担保年度业务解保信息表--每日跑批前是T-2业务解保情况';

-- 1.临时表-存续支/自主续支业务的主项目状态
drop table if exists dw_tmp.tmp_dwd_guar_biz_unguar_info_mainstt;
create table dw_tmp.tmp_dwd_guar_biz_unguar_info_mainstt
(
guar_id        varchar(64)    comment '项目编号'
,project_id    varchar(64)    comment '主项目id'
,project_no    varchar(64)    comment '主项目编号'
,proj_stt      varchar(20)    comment '主项目状态'

)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin comment= '临时表-存续支/自主续支业务的主项目状态'
;
commit;
insert into dw_tmp.tmp_dwd_guar_biz_unguar_info_mainstt
(
guar_id    
,project_id
,project_no
,proj_stt
)
select	t1.guar_id
		,t1.project_id
		,t1.project_no
		,case t1.proj_status
			when '00' then '提报中'
			when '10' then '审批中'
			when '20' then '待签约'
			when '30' then '待出函'
			when '40' then '待放款'
			when '50' then '已放款'
			when '97' then '已作废'
			when '98' then '已终止'
			when '99' then '已否决'
			when '91' then '不受理'
			when '90' then '已解保'
			when '92' then '超期终止'
			when '93' then '已代偿'
			else t1.proj_status
		 end as proj_stt
from 
(
	select	t1.code           as guar_id
			,t1.project_id
			,t2.code          as project_no
			,t2.proj_status
	from
	(
		select t1.id, t1.code, t1.project_id
		from
		(
			select t1.id, t1.code, t1.project_id, row_number()over(partition by t1.id order by t1.db_update_time desc, t1.update_time desc) rn
			from dw_nd.ods_t_biz_proj_xz t1  -- 续支项目表
		) t1
		where t1.rn = 1
	) t1
	left join
	(
		select t1.id, t1.code,t1.proj_status, row_number()over(partition by t1.id order by t1.db_update_time desc, t1.update_time desc) rn
		from dw_nd.ods_t_biz_project_main t1
	) t2
	on t1.project_id = t2.id
	and t2.rn = 1
	
	union all
	select	t1.code           as guar_id
			,t1.project_id
			,t2.code          as project_no
			,t2.proj_status
	from
	(
		select t1.id, t1.code, t1.project_id
		from
		(
			select t1.id, t1.code, t1.project_id, t1.type, row_number()over(partition by t1.id order by t1.db_update_time desc, t1.update_time desc) rn
			from dw_nd.ods_t_biz_proj_loan_check t1 -- 贷后检查自主循环贷项目
		) t1
		where t1.rn = 1
		and t1.type = '02' -- 02续支自助循环贷业务
	) t1
	left join
	(
		select t1.id, t1.code,t1.proj_status, row_number()over(partition by t1.id order by t1.db_update_time desc, t1.update_time desc) rn
		from dw_nd.ods_t_biz_project_main t1
	) t2
	on t1.project_id = t2.id
	and t2.rn = 1
) t1
;
commit;


-- 2.数据落地
truncate table dw_base.dwd_guar_biz_unguar_info;
insert into dw_base.dwd_guar_biz_unguar_info
(
day_id                     -- '数据加载日期'
,biz_no                    -- '业务编号'
,biz_id                    -- '业务ID：续支id/进件ID'
,proj_no                   -- '主项目编号'
,proj_id                   -- '主项目ID：进件ID'
,biz_unguar_reason         -- '担保年度解保原因'
,biz_unguar_dt             -- '担保年度解保日期'
)
select	distinct '${v_sdate}' as day_id
		,t1.guar_id           as biz_no 
		,t5.guar_id           as biz_id 
		,t0.project_no        as proj_no
		,t0.project_id        as proj_id
		,case when t1.loan_reg_dt < t2.loan_reg_dt then '续支解保'                             -- 同一主项目下，存在晚于当前担保年度项目的数据，则该记录为续支解保
			  when t1.loan_reg_dt = t2.loan_reg_dt and t1.goon_term < t2.goon_term then '续支解保' -- 同一主项目下，两笔续支放款登记日期相等的看期数
			  when t1.loan_reg_dt = t2.loan_reg_dt and t1.goon_term = t2.goon_term and t1.guar_id < t2.guar_id then '续支解保' -- 期数也一样的，看支用次数，支用次数是通过guar_id比较出来的
			  when t3.proj_no is not null then '续支解保'                                      -- 针对续支数据，没有放款登记日期的累保数据，其主项目应记为续支解保
			  when coalesce(t6.proj_stt, t1.item_stt) = '已解保' then '合同解保'                                       -- 如果项目状态='已解保'， 则该记录为合同解保
			  when coalesce(t6.proj_stt, t1.item_stt) = '已代偿' then '代偿解保'                                       -- 如果项目状态='已代偿'， 则该记录为代偿解保
			  else null
		 end as biz_unguar_reason
		,case when t4.biz_unguar_dt is null then '${v_sdate}' -- 之前没有"已解保"、"已代偿" 且 当前"已解保"、"已代偿"
           else t4.biz_unguar_dt
		 end as biz_unguar_dt
from dw_base.dwd_guar_info_all t1
inner join dw_base.dwd_guar_info_stat t0
on t1.guar_id = t0.guar_id
left join
(
	select	t1.guar_id
			,t1.project_no
			,t1.loan_reg_dt
			,t1.goon_term
			-- ,t1.biz_disb_cnt
	from
	(
		select	t1.guar_id
				,t2.project_no
				,t1.loan_reg_dt
				,t1.goon_term
				-- ,t1.biz_disb_cnt
				,row_number()over(partition by t2.project_no order by t1.loan_reg_dt desc, t1.goon_term desc, t1.guar_id desc) as rn -- 找同一合同项目下最后一笔续支业务
		from  dw_base.dwd_guar_info_all t1
		inner join dw_base.dwd_guar_info_stat t2
		on t1.guar_id = t2.guar_id
		where t1.item_stt in ('已放款', '已解保', '已代偿')
		and t1.guar_id regexp 'XZ|ZZXZ|BHJC' -- biz_type in ('续支', '自主续支')
	) t1
	where t1.rn = 1
) t2
on t0.project_no = t2.project_no
left join
(
	select distinct t2.project_no as proj_no
	from dw_base.dwd_guar_info_all t1
	inner join dw_base.dwd_guar_info_stat t2
	on t1.guar_id = t2.guar_id
	where t1.item_stt in ('已放款', '已解保', '已代偿')
	and t1.guar_id regexp 'XZ|ZZXZ|BHJC' -- biz_type in ('续支', '自主续支')
) t3 -- 存在续支放款的数据
on t1.guar_id = t3.proj_no
left join dw_base.dwd_guar_biz_unguar_info_unguar_dt_lastday t4
on t1.guar_id = t4.biz_no

left join
(
	select	distinct t1.guar_no
			,t1.guar_id
			,t1.proj_no
			,t1.proj_id
	from dw_base.dwd_guar_cont_info_all t1 -- 担保年度信息表
) t5
on t1.guar_id = t5.guar_no

left join dw_tmp.tmp_dwd_guar_biz_unguar_info_mainstt t6
on t1.guar_id = t6.guar_id

where t1.item_stt in( '已解保', '已代偿')
;
commit;

-- 3.临时表-担保年度业务解保信息表--T-2业务解保情况:保存当日已解保业务的数据，提供给明日对比使用
drop table if exists dw_base.dwd_guar_biz_unguar_info_unguar_dt_lastday;
create table if not exists dw_base.dwd_guar_biz_unguar_info_unguar_dt_lastday(
day_id             varchar(8)  comment '数据日期'
,biz_no            varchar(50) comment '项目编号'
,biz_unguar_dt     varchar(8)  comment '解保日期(项目状态变为已解保的日期)'

,index ind_tmp_dwd_guar_biz_unguar_info_bizno(biz_no)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin comment= '临时表-担保年度业务解保信息表--每日跑批前是T-2业务解保情况';

insert into dw_base.dwd_guar_biz_unguar_info_unguar_dt_lastday
(
day_id        
,biz_no       
,biz_unguar_dt 
)
select t1.day_id
		,t1.biz_no
		,t1.biz_unguar_dt
from dw_base.dwd_guar_biz_unguar_info t1
;
commit;