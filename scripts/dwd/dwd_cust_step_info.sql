-- ---------------------------------------
-- 开发人   :  Wangyx
-- 开发时间 ： 20220928
-- 目标表   ： dwd_cust_step_info 客户注册步骤信息表
-- 源表     ： ods_wxapp_cust_auth_step 注册步骤表
--             dwd_cust_login_info 客户注册信息
-- 变更记录 ：
-- ---------------------------------------

truncate table dw_base.dwd_cust_step_info ;

insert into dw_base.dwd_cust_step_info
(
day_id
,cust_id
,login_no
,auth_type
,step_num
,step_status
,create_time
,update_time
,bus_id
)

select
'${v_sdate}'
,t1.cust_code    -- 客户号               
,t2.login_no     -- 注册账号              
,t1.auth_type    -- 01-身份认证  02-信息修改认证
,t1.step_num     -- 步骤号               
,t1.step_status  -- 步骤状态 1成功 0失败      
,t1.create_time  -- 开始时间              
,t1.update_time  -- 修改时间              
,t1.bus_id       -- 业务编号，实名认证对应客户号    
from
(
	select
	cust_code
	,auth_type
	,step_num
	,step_status
	,create_time
	,update_time
	,bus_id
	from
	(
		select
		id
		,cust_code
		,auth_type
		,step_num
		,step_status
		,create_time
		,update_time
		,bus_id
		,row_number() over(partition by id order by create_time desc) as rk
		from dw_nd.ods_wxapp_cust_auth_step
	) t
	where rk = 1
) t1
left join dw_base.dwd_cust_login_info t2
on t1.cust_code = t2.cust_id
;
commit ;