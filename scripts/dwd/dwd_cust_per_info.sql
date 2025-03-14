-- ---------------------------------------
-- 开发人   :  Wangyx
-- 开发时间 ： 20220809
-- 目标表   ： dwd_cust_per_info 个人客户基本信息
-- 源表     ： dwd_cust_info
--             ods_crm_cust_per_info
--             ods_wxapp_cust_login_info
-- 变更记录 ：
-- ---------------------------------------

-- 创建临时表，获取预审客户基本信息

drop table if exists dw_tmp.tmp_dwd_cust_per_info_ref ;
commit;

CREATE TABLE dw_tmp.tmp_dwd_cust_per_info_ref (
cust_id      varchar(50)  comment'客户号'                      
,cust_type    varchar(2)   comment'客户类型（P个人/C企业）'            
,cust_name    varchar(500) comment'客户姓名'                     
,cert_type    varchar(2)   comment'证件类型（10-身份证 21-统一社会信用编码）'
,cert_no      varchar(50)  comment'证件号码'                     
,tel_no       varchar(50)  comment'手机号'                      
,regist_dt    varchar(8)   comment'注册日期'                       
,index idx_tmp_dwd_cust_per_info_ref_cust_id (cust_id)
,index idx_tmp_dwd_cust_per_info_ref_cert_no (cert_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

insert into dw_tmp.tmp_dwd_cust_per_info_ref
(
cust_id
,cust_type
,cust_name
,cert_type
,cert_no
,tel_no
,regist_dt
)
select
concat(cust_id_type,cust_id_no) as cust_id
,cust_type
,cust_name
,cust_id_type
,cust_id_no
,cust_mobile
,date_format(create_time,'%Y%m%d') as regist_dt 
from(
	select
	cust_id
	,case when cust_type = '01' then 'P'
				when cust_type in ('02','03') then 'C'
				else cust_type end as cust_type
	,cust_name
	,case when cust_id_type = '01' then '10'
				when cust_id_type = '02' then '21'
				else cust_id_type end as cust_id_type
	,cust_id_no
	,cust_mobile
	,create_time
	from(
		select
		cust_id
		,cust_type
		,cust_name
		,cust_id_type
		,cust_id_no
		,cust_mobile
		,create_time
		from(
			select
			log_id
			,cust_id
			,cust_type
			,cust_name
			,cust_id_type
			,cust_id_no
			,cust_mobile
			,create_time
			from dw_nd.ods_t_sdnd_credit_log
			where date_format(update_time,'%Y%m%d') <= '${v_sdate}'
			order by update_time desc
		) t
		group by cust_id_no
	) t1
) t2
;
commit;

-- 创建临时表，获取个人信息
drop table if exists dw_tmp.tmp_dwd_cust_per_info_crm_ref ; commit;
CREATE TABLE dw_tmp.tmp_dwd_cust_per_info_crm_ref (
cert_no            varchar(50)   comment'证件号码'
,cert_expiry_dt    varchar(10)   comment'证件有效期'
,sex               varchar(2)    comment'性别 1--男 2--女 3--未知'
,age               int           comment'年龄'
,marr_stt          varchar(2)    comment'婚姻状况（0--未婚 1--已婚 2--丧偶 3--离异'
,spouse_name       varchar(50)   comment'配偶姓名'
,children_status   varchar(2)    comment'子女状况'
,education_status  varchar(2)    comment'教育程度（最高学历）'
,degree_status     varchar(2)    comment'学位（学士 硕士 博士）'
,addr              varchar(200)  comment'地址详情'
,index idx_tmp_dwd_cust_per_info_crm_ref_cert_no (cert_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit;

insert into dw_tmp.tmp_dwd_cust_per_info_crm_ref
(
cert_no
,cert_expiry_dt
,sex
,age
,marr_stt
,spouse_name
,children_status
,education_status
,degree_status
,addr
)
select
id_no
,card_expire_date
,sex
,age
,marriage_status
,spouse_name
,children_status
,education_status
,degree_status
,card_address
from
(
	select
	id_no
	,card_expire_date
	,sex
	,age
	,marriage_status
	,spouse_name
	,children_status
	,education_status
	,degree_status
	,card_address
	,row_number() over(partition by id_no order by update_time desc) as rk
	from dw_nd.ods_crm_cust_per_info  
	where date_format(update_time,'%Y%m%d') <= '${v_sdate}'
	and id_no is not null
) t
where rk = 1
;
commit;


-- 创建临时表，获取个人民族信息
drop table if exists dw_tmp.tmp_dwd_cust_per_info_ref_nation ; commit;
CREATE TABLE dw_tmp.tmp_dwd_cust_per_info_ref_nation (
customer_id       varchar(50)   comment'客户号'
,cert_no          varchar(50)   comment'证件号码'
,nation    		  varchar(50)   comment'民族'
,index idx_tmp_dwd_cust_per_info_ref_nation_cert_no (cert_no)
,index idx_tmp_dwd_cust_per_info_ref_nation_customer_id (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit;

insert into dw_tmp.tmp_dwd_cust_per_info_ref_nation
(
customer_id
,cert_no
,nation
)
select
customer_id
,main_id_no
,nation
from(
	select
	customer_id
	,main_id_no
	,nation
	,row_number() over(partition by customer_id order by update_time desc) as rk
	from dw_nd.ods_wxapp_cust_login_info   
	where date_format(update_time,'%Y%m%d') <= '${v_sdate}'
	and customer_id is not null 
) t
where rk = 1  -- main_id_no 有比较多的空值
;
commit;


-- 创建临时表，获取客户年龄、性别
drop table if exists dw_tmp.tmp_cust_per_info_ref_age ; commit;
CREATE TABLE dw_tmp.tmp_cust_per_info_ref_age (
cert_no           varchar(50)   comment'证件号码'
,birt_dt           varchar(8)    comment'出生日期'
,sex               varchar(2)    comment'性别 1--男 2--女 3--未知'
,age               int           comment'年龄'
,index idx_tmp_cust_per_info_ref_age_cert_no (cert_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit;

insert into dw_tmp.tmp_cust_per_info_ref_age
(
cert_no
,birt_dt
,sex
,age
)
select
cert_no
,case when TIMESTAMPDIFF(year,date_format(substr(t1.cert_no,7,8),'%Y%m%d'),'${v_sdate}') between 1 and 130 then date_format(substr(t1.cert_no,7,8),'%Y%m%d') else null end as birt_dt
,case when TIMESTAMPDIFF(year,date_format(substr(t1.cert_no,7,8),'%Y%m%d'),'${v_sdate}') between 1 and 130 then if(mod(substring(t1.cert_no,17,1),2),'1','2') else null end as sex
,case when TIMESTAMPDIFF(year,date_format(substr(t1.cert_no,7,8),'%Y%m%d'),'${v_sdate}') between 1 and 130 then TIMESTAMPDIFF(year,date_format(substr(t1.cert_no,7,8),'%Y%m%d'),'${v_sdate}') else null end as age
from dw_tmp.tmp_dwd_cust_per_info_ref t1
where t1.cust_type = 'P'
and substr(t1.cert_no,7,2) in ('19','20','21','22','23','24','25','26','27')
and substr(t1.cert_no,11,2) between '01' and '12'
and case when substr(t1.cert_no,11,2) = '02' then substr(t1.cert_no,13,2) between '01' and '29'
		 else substr(t1.cert_no,13,2) between '01' and '31' end
;
commit;

-- 证件有效期格式不对的进行转化
drop table if exists dw_tmp.tmp_ods_crm_cust_certification_info; commit;
CREATE TABLE dw_tmp.tmp_ods_crm_cust_certification_info (
  `id` varchar(64) COLLATE utf8mb4_bin NOT NULL COMMENT '主键',
  `cust_code` varchar(64) COLLATE utf8mb4_bin DEFAULT NULL,
  `id_no` varchar(20) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '个人身份证号/企业统一信用代码',
  `id_type` varchar(2) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '证件类型',
  `cust_certification_video_file_id` varchar(64) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '客户认证视频文件ID',
  `cust_type` varchar(2) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '客户类型',
  `gender` varchar(2) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '性别 个人/企业法定代表人',
  `birthday` varchar(32) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '生日 个人/企业法定代表人',
  `nationality` varchar(10) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '民族 个人/企业法定代表人',
  `id_card_address` varchar(300) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '身份证地址 个人/企业法定代表人',
  `id_card_issuer` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '身份证颁发机构 个人/企业法定代表人',
  `id_card_front_file_id` varchar(64) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '身份证图片正面 个人/企业法定代表人',
  `id_card_back_file_id` varchar(64) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '身份证图片正面 个人/企业法定代表人',
  `legal_representative_name` varchar(20) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '企业法人姓名',
  `legal_representative_id_no` varchar(32) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '企业法定代表人身份证号',
  `business_license_file_id` varchar(64) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '企业 营业执照文件ID',
  `id_card_validity` varchar(32) COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'IDCard证件有效期',
  `business_license_validity` varchar(32) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '营业执照证件有效期',
  `comp_address` varchar(300) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '企业地址',
  `remark` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '补充说明',
  `creator` varchar(36) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '创建人',
  `create_name` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '创建人名称',
  `create_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '创建时间',
  `updator` varchar(36) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '更新人',
  `update_name` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '更新人名称',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `delete_flag` char(1) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '逻辑删除',
  KEY `id` (`id`),
  KEY `index_cust_code` (`cust_code`),
  KEY `index_id_no` (`id_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='客户认证信息表'; 
commit;

insert into dw_tmp.tmp_ods_crm_cust_certification_info
select 
id
,cust_code
,id_no
,id_type
,cust_certification_video_file_id
,cust_type
,gender
,birthday
,nationality
,id_card_address
,id_card_issuer
,id_card_front_file_id
,id_card_back_file_id
,legal_representative_name
,legal_representative_id_no
,business_license_file_id
,case when substr(substring_index(id_card_validity,'-',-1),5,2) > '12' then null else id_card_validity end as id_card_validity
,business_license_validity
,comp_address
,remark
,creator
,create_name
,create_time
,updator
,update_name
,update_time
,delete_flag
from (
	select * from (
	select t.*
	,row_number() over(partition by id_no order by update_time desc) as rk
	from dw_nd.ods_crm_cust_certification_info t) t1
	where rk = 1
) t2
;
commit;




-- 个人基本信息补充
drop table if exists dw_tmp.tmp_dwd_cust_per_info_crm_ref_add ; commit;
CREATE TABLE dw_tmp.tmp_dwd_cust_per_info_crm_ref_add (
cert_no            varchar(50)   comment'证件号码'
,cert_expiry_dt    varchar(10)   comment'证件有效期'
,birt_dt           varchar(8)    comment'出生日期'
,sex               varchar(2)    comment'性别 1--男 2--女 3--未知'
,nation    		   varchar(50)   comment'民族'
,addr              varchar(200)  comment'地址详情'
,index idx_tmp_dwd_cust_per_info_crm_ref_add_cert_no (cert_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit;

insert into dw_tmp.tmp_dwd_cust_per_info_crm_ref_add
(
cert_no
,cert_expiry_dt
,birt_dt
,sex
,nation
,addr
)
select
id_no
,id_card_validity
,date_format(birthday,'%Y%m%d') as birthday
,gender as sex
,nationality
,id_card_address
from
(
	select
	id_no
	,cust_type
	,gender
	,birthday
	,nationality
	,id_card_address
	,id_card_validity
	from
	(
		select 
		id_no
		,cust_type
		,gender
		,birthday
		,nationality
		,id_card_address
		,id_card_validity
		,row_number() over(partition by id_no order by create_time desc) as rk
		from (
			select
			id_no
			,cust_type
			,gender
			,birthday
			,nationality
			,id_card_address
			,date_format(substring_index(id_card_validity,'-',-1),'%Y-%m-%d') as id_card_validity
			,create_time
			from dw_tmp.tmp_ods_crm_cust_certification_info
			where date_format(update_time,'%Y%m%d') <= '${v_sdate}'
			and cust_type = '01'
			and id_card_validity not like '%长期%'
			and length(substring_index(id_card_validity,'-',-1)) >= 8
			and date(substring_index(id_card_validity,'-',-1)) is not null
            union all
			
			select
			id_no
			,cust_type
			,gender
			,birthday
			,nationality
			,id_card_address
			,'2099-01-01' as id_card_validity
			,create_time
			from dw_tmp.tmp_ods_crm_cust_certification_info
			where date_format(update_time,'%Y%m%d') <= '${v_sdate}'
			and cust_type = '01'
			and id_card_validity like '%长期%'
		)t
	) t
	where rk = 1
)t1 
;
commit;



-- 数据汇总进入目标表

truncate table dw_base.dwd_cust_per_info ; commit;  

insert into dw_base.dwd_cust_per_info 
(
day_id             -- 数据日期
,cust_id            -- 客户号
,cust_name          -- 客户姓名
,cert_type          -- 证件类型 10--身份证 21--统一社会信用编码
,cert_no            -- 证件号码
,cert_expiry_dt     -- 证件有效期
,birt_dt            -- 出生日期
,sex                -- 性别 1--男 2--女 3--未知
,age                -- 年龄
,tel_no             -- 手机号
,marr_stt           -- 婚姻状况（0--未婚 1--已婚 2--丧偶 3--离异）
,nation             -- 民族
,spouse_name        -- 配偶姓名
,heal_stt           -- 健康状况
,children_status    -- 子女状况
,education_status   -- 教育程度（最高学历）
,degree_status      -- 学位（学士 硕士 博士）
,addr               -- 地址详情
,regist_dt          -- 注册日期
,data_source        -- 数据来源 01--小程序 02--线下台账 03--预审
)
select distinct 
'${v_sdate}'
,t1.cust_id
,t1.cust_name
,t1.cert_type
,t1.cert_no
,coalesce(t2.cert_expiry_dt,t6.cert_expiry_dt) as cert_expiry_dt
,coalesce(t5.birt_dt,t6.birt_dt) as birt_dt
,coalesce(t2.sex,t5.sex,t6.sex) as sex
,coalesce(t2.age,t5.age) as age
,t1.tel_no
,t2.marr_stt
,coalesce(t3.nation,t4.nation,t6.nation)nation
,t2.spouse_name
,NULL as heal_stt
,t2.children_status
,t2.education_status
,t2.degree_status
,coalesce(t2.addr,t6.addr)
,t1.regist_dt
,t1.data_source
from dw_base.dwd_cust_info t1      
left join dw_tmp.tmp_cust_per_info_ref_age t5 -- 通过证件号获取符合规范的年龄、性别、出生日期
on t1.cert_no = t5.cert_no
left join dw_tmp.tmp_dwd_cust_per_info_crm_ref t2  -- 从ods_crm_cust_per_info获取个人信息
on t1.cert_no = t2.cert_no
left join dw_tmp.tmp_dwd_cust_per_info_ref_nation t3 -- 从ods_wxapp_cust_login_info获取个人民族信息
on t1.cust_id = t3.customer_id
left join dw_tmp.tmp_dwd_cust_per_info_ref_nation t4 -- 从ods_wxapp_cust_login_info获取个人民族信息
on t1.cert_no = t4.cert_no
left join dw_tmp.tmp_dwd_cust_per_info_crm_ref_add t6 -- 从ods_crm_cust_certification_info中补充个人基本信息
on t1.cert_no = t6.cert_no
where t1.cust_type = 'P'
;
commit;
