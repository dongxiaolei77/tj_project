-- ---------------------------------------
-- 开发人   :  Wangyx
-- 开发时间 ： 20220719
-- 目标表   ： dwd_cust_cert_info 客户认证信息
-- 源表     ： ods_wxapp_cust_login_info 用户注册信息
--             ods_wxapp_cust_auth_step 注册步骤表
-- 变更记录 ：
-- ---------------------------------------


-- 创建临时表，获取用户注册信息表最新日期数据

drop table if exists dw_tmp.tmp_dwd_cust_cert_info_ref ; commit;
CREATE TABLE dw_tmp.tmp_dwd_cust_cert_info_ref (
login_no	varchar(100)     comment'登录账号'
,cust_id	varchar(50)      comment'客户编号'
,cust_name	varchar(500)   comment'客户名称'
,login_type	varchar(2)     comment'登录账号类型（P个人/C企业）'
,cert_type	varchar(2)     comment'证件类型（10--身份证 21--统一社会信用编码）'
,cert_no	varchar(50)      comment'证件号码'
,regist_dt	varchar(8)     comment'注册日期'
,ocr_status varchar(4)     comment'身份证ocr状态'
,video_status varchar(4)   comment'活体认证状态'
,status varchar(2)         comment'状态'
,index idx_dwd_cust_cert_info_login_no (login_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit;

insert into dw_tmp.tmp_dwd_cust_cert_info_ref
(
  login_no
 ,cust_id
 ,cust_name
 ,login_type
 ,cert_type
 ,cert_no
 ,regist_dt
 ,ocr_status
 ,video_status
 ,status
)
select
	login_no
	,customer_id
	,main_name
	,login_type
	,main_id_type
	,main_id_no
	,date_format(create_time,'%Y%m%d') as regist_dt
	,ocr_status
	,video_status
	,status
from
(
		select 
		    login_no        -- 登录账号
		    ,customer_id    -- 客户号
		    ,main_name      -- 客户姓名
		    ,case when login_type = '1' then 'P'
   			      when login_type = '2' then 'C'
				  else login_type end login_type    -- 登录账号类型（P 个人/C 企业）
		    ,case when main_id_type in ('10','22') then '10'
                  when main_id_type = '21' then main_id_type 
				  else main_id_type end main_id_type	-- 证件类型（10--身份证 21--统一社会信用编码）
		    ,main_id_no     -- 证件号码
		    ,create_time    -- 注册日期
		    ,ocr_status     -- 身份证ocr状态
		    ,video_status   -- 活体认证状态
		    ,status         -- 状态
			,row_number() over(partition by login_no order by update_time desc) as rk
		from dw_nd.ods_wxapp_cust_login_info
		where date_format(update_time,'%Y%m%d') <= '${v_sdate}'
) t
where rk = 1
;
commit ;


-- 创建临时表，获取注册步骤表最新日期数据

drop table if exists dw_tmp.tmp_dwd_cust_cert_info_step_ref ; commit;
CREATE TABLE dw_tmp.tmp_dwd_cust_cert_info_step_ref (
 cust_code varchar(60)
 ,step_num varchar(10)
 ,end_dt varchar(8)
,index idx_tmp_dwd_cust_cert_info_step (cust_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit;

insert into dw_tmp.tmp_dwd_cust_cert_info_step_ref
(
cust_code
,step_num
,end_dt
)
select
 cust_code
 ,step_num
 ,date_format(create_time,'%Y%m%d') as end_dt
from
(
	select
	    cust_code     -- 客户编号
	    ,step_num     -- 步骤号
	    ,create_time
		,row_number() over(partition by cust_code,step_num order by update_time desc) as rk
	from dw_nd.ods_wxapp_cust_auth_step
	where auth_type = '01'
) t
where rk = 1
;
commit ;



delete from dw_base.dwd_cust_cert_info ;
commit ;


-- 客户认证信息
insert into dw_base.dwd_cust_cert_info
(
	day_id                      -- 数据日期                                   
	,login_no                   -- 登录账号                                   
	,cust_id                    -- 客户编号                                   
	,cust_name                  -- 客户名称                                   
	,login_type                 -- 登录账号类型（P 个人/C 企业）                      
	,cert_type                  -- 证件类型（10--身份证 21--统一社会信用编码）             
	,cert_no                    -- 证件号码                                   
	,regist_dt                  -- 注册日期                                   
	,is_cert_ident              -- 是否身份认证(1--是 0--否）                      
	,cert_ident_result_cd       -- 身份认证结果码值（1S--认证通过）                     
	,cert_ident_result          -- 身份认证结果（1--通过 0--失败）                    
	,cert_ident_dt              -- 身份认证结束时间                               
	,is_face_ident              -- 是否活体认证(1--是 0--否）                      
	,face_ident_result_cd       -- 活体认证结果码值（2S--认证通过 2F--认证失败 2P--重试）     
	,face_ident_result          -- 活体认证结果（1--通过 0--失败）                    
	,face_ident_dt              -- 活体认证结束时间                               
	,is_offl_ident              -- 是否线下核身(1--是 0--否）                      
	,offl_ident_result_cd       -- 线下核身结果码值（3S--认证通过 3F--认证失败 3C--活体认证转人工）
	,offl_ident_result          -- 线下核身结果（1--通过 0--失败）                    
	,offl_ident_dt              -- 线下核身完成时间                               
	,is_ident                   -- 是否认证完成
	,is_empower                 -- 是否授权查询三方(1--是 0--否）                    
	,empower_dt                 -- 授权完成时间                                 
)
select
 '${v_sdate}'
,t1.login_no
,t1.cust_id
,t1.cust_name
,t1.login_type
,t1.cert_type
,t1.cert_no
,t1.regist_dt
,case when t2.cust_code is not null then '1' else '0' end as is_cert_ident -- 是否身份认证(1--是 0--否）
,case when t2.cust_code is not null then t1.ocr_status else null end as cert_ident_result_cd -- 身份认证结果码值（1S--认证通过） 
,case when t2.cust_code is null then null
			else case when t1.ocr_status = '1S' then '1' else '0' end
			end  as cert_ident_result -- 身份认证结果（1--通过 0--失败）
,t2.end_dt as cert_ident_dt -- 身份认证结束时间
,case when t3.cust_code is not null then '1'
			else case when t2.cust_code is not null then '0' else null end
			end as is_face_ident -- 是否活体认证(1--是 0--否）
,case when t3.cust_code is not null
	  then case when t1.video_status like'3%' then '2F' else t1.video_status end
	  else null end as face_ident_result_cd -- 活体认证结果码值（2S--认证通过 2F--认证失败 2P--重试）
,case when t3.cust_code is null then null
			else case when t1.video_status = '2S' then '1' else '0' end
			end as face_ident_result -- 活体认证结果（1--通过 0--失败）
,t3.end_dt as face_ident_dt -- 活体认证结束时间
,case when t4.cust_code is not null then '1'
			else case when t3.cust_code is not null then '0' else null end
			end as is_offl_ident -- 是否线下核身(1--是 0--否）
,case when t4.cust_code is not null then t1.video_status else null end as offl_ident_result_cd -- 线下核身结果码值（3S--认证通过 3F--认证失败 3C--活体认证转人工）
,case when t4.cust_code is null then null
			else case when t1.video_status = '3S' then '1' else '0' end
			end as offl_ident_result -- 线下核身结果（1--通过 0--失败）
,t4.end_dt as offl_ident_dt -- 线下核身完成时间
,case when t3.cust_code is null and t4.cust_code is null then null
			else case when t1.video_status in('2S','3S') then '1' else '0' end
		end as is_ident -- 是否认证完成
,case when t1.status = '10' and t5.cust_code is not null then '1' else '0' end as is_empower -- 是否授权查询三方(1--是 0--否） 
,t5.end_dt as empower_dt -- 授权完成时间
from dw_tmp.tmp_dwd_cust_cert_info_ref t1   -- 获取用户注册信息表最新日期数据
left join dw_tmp.tmp_dwd_cust_cert_info_step_ref t2  -- 获取注册步骤表最新日期数据
on t1.cust_id = t2.cust_code and t2.step_num = '2'
left join dw_tmp.tmp_dwd_cust_cert_info_step_ref t3
on t1.cust_id = t3.cust_code and t3.step_num = '3'
left join dw_tmp.tmp_dwd_cust_cert_info_step_ref t4
on t1.cust_id = t4.cust_code and t4.step_num = '4'
left join dw_tmp.tmp_dwd_cust_cert_info_step_ref t5
on t1.cust_id = t5.cust_code and t5.step_num = '5'
;
commit ;