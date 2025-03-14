-- ---------------------------------------
-- 开发人   :  Wangyx
-- 开发时间 ： 20220719
-- 目标表   ： dwd_cust_login_info 客户注册信息
-- 源表     ： ods_wxapp_cust_login_info 用户注册信息
-- 变更记录 ：20241201 脚本的统一变更，MySQL5.0转MySQL8.0 zhangfl 
-- ---------------------------------------
truncate table dw_base.dwd_cust_login_info ;
commit ;

insert into dw_base.dwd_cust_login_info
(
 day_id
 ,login_no
 ,cust_id
 ,login_type
 ,cust_name
 ,cert_type
 ,cert_no
 ,login_stt
 ,terminal_name
 ,openid
 ,video_dile_id
 ,regist_dt
)
select
	'${v_sdate}' 
	,login_no
	,customer_id
	,login_type 
	,main_name
	,main_id_type
	,main_id_no
	,status
	,terminal_name
	,openid
	,video_file_id
	,date_format(create_time,'%Y%m%d') as create_time
from
(
		select 
		login_no        -- 登录账号（个人：手机号码，企业：企业名称）
		,customer_id    -- 客户号
		,case when login_type = '1' then 'P'
   			  when login_type = '2' then 'C'
				  else login_type end login_type    -- 登录账号类型（P 个人/C 企业）
		,main_name      -- 客户姓名
		,case when main_id_type in ('10','22') then '10'
          when main_id_type = '21' then main_id_type
				  else main_id_type end main_id_type	-- 证件类型（10--身份证 21--统一社会信用编码）
		,main_id_no     -- 证件号码
		,status         -- 登录账号状态（00--已注册待认证 10--正常 11--冻结待审核 12--冻结 13--解冻待审核 15--关闭申请中 16--已关闭）
		,terminal_name  -- 最近登录设备
		,openid         -- openid
		,video_file_id  -- 人脸视频fleid
		,create_time    -- 注册日期（取创建时间）
		,row_number()over(partition by login_no order by update_time desc) rn
		from dw_nd.ods_wxapp_cust_login_info
		where date_format(update_time,'%Y%m%d') <= '${v_sdate}'
) t
where t.rn = 1
;
commit ;