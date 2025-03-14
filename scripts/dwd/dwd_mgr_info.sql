-- ---------------------------------------
-- 开发人   : liyy
-- 开发时间 ：20210414
-- 目标表   ：dw_base.dwd_mgr_info 客户经理信息
-- 源表     ：dw_nd.ods_t_sys_user 新业务中台用户信息表
--            dw_base.dim_bank_info 部门表
--            dw_nd.ods_t_sys_area 新业务中台地区表

-- 变更记录 ：20220117统一修改
-- 			  20220520 银行维表切源，ods_t_sys_dept改为dim_bank_info
-- 			  20220523 补充银行名称
--            20241201 脚本的统一变更，MySQL5.0转MySQL8.0并优化逻辑 zhangfl
-- ---------------------------------------

-- 客户经理
-- delete from dw_base.dwd_mgr_info ;
truncate  table dw_base.dwd_mgr_info ; -- 新修改
commit ;

insert into dw_base.dwd_mgr_info
SELECT
        '${v_sdate}'
	    ,t1.user_id        -- 客户经理id
		,t1.real_name      -- 客户经理名称
		,t1.id_num         -- 客户经理身份证号
		,t1.phone_number   -- 客户经理手机号
		,t1.sex            -- 性别
		,t1.email          -- 邮箱
		,t1.STATUS         -- 客户经理状态0正常 1停用
		,t1.del_flag       -- 是否删除0代表存在 2代表删除
		,t1.dept_id        -- 部门ID
		,coalesce(t3.bank_name,t1.dept_id) -- mdy 20220523 wyx
		,t1.area_id
        ,t4.area_name
        ,DATE_FORMAT(create_time,'%Y-%m-%d')       -- 创建时间		       -- 创建时间		
FROM
	(
	SELECT
		user_id,
		real_name,
		id_num,
		phone_number,
		sex,
		email,
		STATUS,
		del_flag,
		dept_id,
		area_id,
        create_time		
	FROM
		(
		SELECT
			user_id,
			real_name,
			id_num,
			phone_number,
			sex,
			email,
			STATUS,
			del_flag,
			dept_id,
			area_id,
			update_time ,
			create_time,
			row_number()over(partition by user_id order by update_time DESC ) rn
		FROM
			dw_nd.ods_t_sys_user 
			where date_format(update_time,'%Y%m%d') <= '${v_sdate}'		
		) t 
	where t.rn = 1
	) t1

	INNER JOIN ( SELECT user_id FROM dw_nd.ods_t_sys_user_role WHERE role_id = '9da7791c-23ed-4f0a-84c8-bad473b76503' and  date_format(update_time,'%Y%m%d') <= '${v_sdate}' GROUP BY user_id ) t2 
	ON t1.user_id = t2.user_id -- 客户经理角色
	LEFT JOIN dw_base.dim_bank_info t3 -- mdy 20220520 wyx
	ON t1.dept_id = t3.bank_id
	LEFT JOIN 
	( 
		SELECT area_id, area_name 
		FROM 
		(
			SELECT area_id, area_name, update_time, row_number()over(partition by area_id order by update_time DESC ) rn
			FROM dw_nd.ods_t_sys_area
			where date_format(update_time,'%Y%m%d') <= '${v_sdate}'
		) t 
		where t.rn = 1
	) t4 
	ON t1.area_id = t4.area_id
	;
commit ;	