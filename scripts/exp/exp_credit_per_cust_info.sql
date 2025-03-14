-- ---------------------------------------
-- 开发人   : 
-- 开发时间 ：
-- 目标表   ：dw_base.exp_credit_per_cust_info  个人客户信息表
-- 源表     ：
-- 变更记录 ：20220308  dw_nd.ods_gcredit_customer_person_detail 替换为  dw_nd.ods_crm_cust_per_info，新增dw_nd.ods_crm_cust_certification_info客户认证信息表 取证件有效期和签发机关               
--             新增 dw_nd.ods_crm_cust_info  取客户电话号码   zzy
-- ---------------------------------------

-- 生成文件
-- exp_credit_per_cust_info  个人基本信息
-- exp_credit_per_cust_dlt_info 整段删除
-- exp_credit_per_cust_ref_info 家庭关系关系 不上报

-- 客户授权
-- 

-- 上报客户信息表
drop table if exists dw_base.tmp_exp_credit_per_cust_info_cust ;

commit;
create  table dw_base.tmp_exp_credit_per_cust_info_cust (
cust_id varchar(60) -- 客户编号
,name   varchar(60)
,id_type  varchar(2)
,id_num   varchar(20)
,key(cust_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;

commit;

insert into dw_base.tmp_exp_credit_per_cust_info_cust 

select 
cust_id -- 客户号
,name -- 姓名
,id_type -- 证件类型
,id_num -- 证件号码
from 
(
    select * from (
        select
        t1.cust_id -- 客户号
        ,t1.name -- 姓名
        ,t1.id_type -- 证件类型
        ,t1.id_num -- 证件号码
        ,row_number() over (partition by CUST_ID order by DAY_ID desc) rn
        from dw_base.exp_credit_per_guar_info t1
        where day_id <= '${v_sdate}'
    )t
    union all
    select * from (
        select
        t1.cust_id -- 客户号
        ,t1.name -- 姓名
        ,t1.id_type -- 证件类型
        ,t1.id_num -- 证件号码
        ,row_number() over (partition by cust_id order by day_id desc) rn
        from dw_base.exp_credit_per_compt_info t1
        where day_id <= '${v_sdate}'
    )t
) t
where t.rn = 1
group by id_num
;

commit ;

-- 组织客户报文信息

-- 性别
drop table if exists dw_base.tmp_exp_credit_per_cust_info_sex ;

commit;

create  table dw_base.tmp_exp_credit_per_cust_info_sex (
cust_id varchar(60) -- 客户编号
,sex	varchar(1)  -- 	性别  1-男 2-女
,key(cust_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;

commit;

insert into dw_base.tmp_exp_credit_per_cust_info_sex

select customer_id
,sex_type
from
(
select
customer_id
,sex_type
,update_time
,row_number() over (partition by CUSTOMER_ID order by UPDATE_TIME desc) rn
from dw_nd.ods_wxapp_cust_login_info
) t 
where rn = 1
;
commit ;
-- 客户基本信息
drop table if exists dw_base.tmp_exp_credit_per_cust_info_base ;

commit;

create  table dw_base.tmp_exp_credit_per_cust_info_base (
cust_id varchar(60) -- 客户编号
,sex	varchar(1)  -- 	性别  1-男 2-女
,dob	date	    -- 出生日期
,house_add	varchar(100)	-- 户籍地址
,resi_addr	varchar(100)	-- 居住地详细地址
,email	varchar(60)	    -- 电子邮箱
,edu_level	varchar(2)	-- 学历
,key(cust_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;

commit;

insert into dw_base.tmp_exp_credit_per_cust_info_base
select a.cust_id,
       a.sex,
	   a.dob,
	   a.house_add,
	   a.resi_addr,
	   '' email,         --  注册或尽调时不填，没有数据
	   a.edu_level
from   (select cust_code cust_id,                                --   customer_id
               sex,                                              --   sex_type  -- 性别 1-男 2-女
               date_format(substr(id_no,7,8),'%Y-%m-%d') dob,    --   date_birth -- 出生日期
               hk_address house_add,                             --   id_address -- 户籍地址
			   live_address resi_addr,                           --   居住地址
               case when education_status = '0' then '80'  -- 小学
                    when education_status = '1' then '70'  -- 初中
                    when education_status = '2' then '60'  -- 高中
                    when education_status = '3' then '40'  -- 中专
                    when education_status = '4' then '30'  -- 大专
                    when education_status = '5' then '20'  -- 本科
                    when education_status = '6' then '10'  -- 研究生
                    when education_status = '7' then '90'  -- 博士  其他
                    when education_status = '12' then '60' -- 12 高中及以上  高中
                    when education_status = '15' then '20' -- 15 本科及以上  本科
                    when education_status = '18' then '90' -- 18 其它 其他
                    else '99' end edu_level, -- 未知              --   学历 		    crm 上数据为空
               row_number() over (partition by cust_code order by update_time desc) rn
        FROM dw_nd.ods_crm_cust_per_info        --  修改       dw_nd.ods_gcredit_customer_person_detail           20220308
		where id_type in ('10','01')   --  10、01都是个人
        ) a
where rn = 1;


commit;


-- 证件有效期格式不对的进行转化
drop table if exists dw_tmp.tmp_ods_crm_cust_certification_info_01; commit;
CREATE TABLE dw_tmp.tmp_ods_crm_cust_certification_info_01 (
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


insert into dw_tmp.tmp_ods_crm_cust_certification_info_01
select t1.* from (
	select id
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
	,id_card_validity
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
	,row_number() over (partition by id order by update_time desc) rn
	from dw_nd.ods_crm_cust_certification_info
	)t
	where rn = 1
)t1
inner join dw_base.tmp_exp_credit_per_cust_info_cust t2
on t1.id_no = t2.id_num
;
commit;

--  证件相关    新增临时表，取客户证件有效期和签发机关 
drop table if exists dw_base.tmp_exp_credit_per_cust_info_id_card ;

commit;

create  table dw_base.tmp_exp_credit_per_cust_info_id_card (
 cust_id        varchar(60) -- 客户号
,id_efct_date	date	    -- 证件有效期起始日期
,id_due_date	date	    -- 证件有效期到期日期
,id_org_name	varchar(80)	-- 证件签发机关名称
,key(cust_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;

commit;

insert into dw_base.tmp_exp_credit_per_cust_info_id_card
select b.cust_id,
       b.id_efct_date,
	   b.id_due_date,
       b.id_org_name
from   (select cust_code cust_id,             -- 客户号
               id_card_validity,
               case when substr(id_card_validity,5,4) > '1231' then date_format(concat(substr(id_card_validity,1,4),substr(id_card_validity,14,4)),'%Y-%m-%d')
							      else date_format(substr(id_card_validity,1,8),'%Y-%m-%d') end as id_efct_date, -- idcard证件有效期起始日
			   case when substr(id_card_validity,10)like '%长期%' or date_format(substr(id_card_validity,10),'%Y-%m-%d') > '2099-12-31'  then '2099-12-31' 
			        else  date_format(substr(id_card_validity,10),'%Y-%m-%d') end id_due_date,  -- idcard证件有效期到期日
			   id_card_issuer id_org_name,                           -- 身份证颁发机构
               row_number() over (partition by cust_code order by update_time desc) rn
	    from dw_tmp.tmp_ods_crm_cust_certification_info_01       -- 客户认证信息表                   20220308
		where length(id_card_validity)=17
		or id_card_validity like '%长期%') b
where rn = 1;
commit;

-- 电话号码    原临时表为 tmp_exp_credit_per_cust_info_addr 取得详细地址，现改为手机号码
drop table if exists dw_base.tmp_exp_credit_per_cust_info_tel_no ;

commit;

create  table dw_base.tmp_exp_credit_per_cust_info_tel_no (
cust_id varchar(60) -- 客户编号
,cell_phone	varchar(11)	-- 手机号码
,key(cust_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;

commit;

insert into dw_base.tmp_exp_credit_per_cust_info_tel_no
select
t.cust_id,
t.cell_phone
from
(
select
cust_code cust_id,                             -- 客户号
substr(cust_mobile,1,11) cell_phone,            -- 联系电话
row_number() over (partition by cust_code order by update_time desc) rn
from dw_nd.ods_crm_cust_info  -- 修改          原表 dw_nd.ods_gcredit_customer_add           20220308
where cust_type = '01'             --  01个人 02企业
) t
where rn = 1
;

commit;


-- drop table if exists dw_base.tmp_exp_credit_per_cust_info_mari ;
-- 
-- commit;
-- 
-- create  table dw_base.tmp_exp_credit_per_cust_info_mari (
-- cust_id varchar(60) -- 客户编号
-- ,MARI_STATUS	varchar(2)	-- 婚姻状况
-- ,SPO_NAME	varchar(30)	-- 配偶姓名
-- ,key(cust_id)
-- ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
-- 
-- commit;
-- 
-- insert into dw_base.tmp_exp_credit_per_cust_info_mari
-- select *
-- from
-- (
-- select
-- customer_id
-- ,'20' -- 婚姻状况 20-已婚
-- ,ref_person_name -- 配偶姓名
-- from dw_nd.ods_gcredit_customer_social_ref
-- where ref_type = '1'
-- order by create_time desc 
-- ) t
-- group by customer_id
-- ;
-- 
-- commit;

-- 每天全量
delete from dw_base.exp_credit_per_cust_info_ready where day_id = '${v_sdate}';

commit;

insert into dw_base.exp_credit_per_cust_info_ready
select
'${v_sdate}' -- 数据日期
,t1.cust_id -- 客户号
,t1.name -- 姓名
,t1.id_type -- 证件类型
,t1.id_num -- 证件号码
,'X3701010000337' -- 信息来源编码  -- 修改
,'' -- 报告时点说明代码
,'X3701010000337' -- 客户资料维护机构代码
,'20' -- 客户资料类型 担保客户资料
,coalesce(t6.sex,'9') -- 性别
,date_format(coalesce(t2.dob,substr(t1.id_num,7,8)),'%Y-%m-%d') -- 出生日期
,'CHN' -- 国籍
,coalesce(t2.house_add,'') -- 户籍地址
,'' -- 户籍所在地行政区划
,coalesce(t5.cell_phone,'') -- 手机号码
,coalesce(t2.email,'') -- 电子邮箱
,'99' -- 婚姻状况
,null -- 配偶姓名
,null -- 配偶证件类型
,null -- 配偶证件号码
,null -- 配偶联系电话
,null -- 配偶工作单位
,coalesce(t2.edu_level,'99') -- 学历
,'9' -- 学位
,'99' -- 就业状况
,null -- 单位名称
,null -- 单位性质
,null -- 单位所属行业
,null -- 单位详细地址
,null -- 单位所在地邮编
,null -- 单位所在地行政区划
,null -- 单位电话
,null -- 职业
,null -- 职务
,null -- 职称
,null -- 本单位工作起始年份
,'9' -- 居住状况
,coalesce(t2.resi_addr,'') -- 居住地详细地址
,'' -- 居住地邮编
,'' -- 居住地行政区划
,'' -- 住宅电话
,'暂缺' -- 通讯地址
,'999999' -- 通讯地邮编
,'' -- 通讯地行政区划
,null -- 自报年收入
,null -- 纳税年收入
,t3.id_efct_date -- 证件有效期起始日期
,t3.id_due_date -- 证件有效期到期日期
,coalesce(t3.id_org_name,'') -- 证件签发机关名称
,'' -- 证件签发机关所在地行政区划
from dw_base.tmp_exp_credit_per_cust_info_cust t1
left join dw_base.tmp_exp_credit_per_cust_info_base t2          -- 学历、地址    原关联表拆分，证件相关数据关联新表     20220308     
on t1.cust_id = t2.cust_id
left join dw_base.tmp_exp_credit_per_cust_info_id_card t3       -- 修改证件相关关联表                                   20220308
on t1.cust_id = t3.cust_id
-- left join dw_base.tmp_exp_credit_per_cust_info_mari t4
-- on t1.cust_id = t4.cust_id
left join dw_base.tmp_exp_credit_per_cust_info_tel_no t5        -- 增加联系电话关联表                                   20220308
on t1.cust_id = t5.cust_id
left join dw_base.tmp_exp_credit_per_cust_info_sex t6 
on t1.cust_id = t6.cust_id
;

commit;


-- 插入新增客户
delete from dw_base.exp_credit_per_cust_info where day_id = '${v_sdate}';

commit;

insert into dw_base.exp_credit_per_cust_info
select
t1.DAY_ID
,t1.CUST_ID
,t1.NAME
,t1.ID_TYPE
,t1.ID_NUM
,t1.inf_surc_code                    -- 信息来源编码
,'10' -- 10-新增客户资料/首次上报
,t1.CIMOC
,t1.CUSTOMER_TYPE  
,t1.SEX
,t1.DOB
,t1.NATION
,t1.HOUSE_ADD
,t1.HH_DIST
,t1.CELL_PHONE
,t1.EMAIL
,t1.MARI_STATUS
,t1.SPO_NAME
,t1.SPO_ID_TYPE
,t1.SPO_ID_NUM
,t1.SPO_TEL
,t1.SPS_CMPY_NM
,t1.EDU_LEVEL
,t1.ACA_DEGREE
,t1.EMP_STATUS
,t1.CPNNAME
,t1.CPN_TYPE
,t1.INDUSTRY
,t1.CPN_ADDR
,t1.CPN_PC
,t1.CPN_DIST
,t1.CPN_TEL
,t1.OCCUPATION
,t1.TITLE
,t1.TECH_TITLE
,t1.WORK_START_DATE
,t1.RESI_STATUS
,t1.RESI_ADDR
,t1.RESI_PC
,t1.RESI_DIST
,t1.HOME_TEL
,t1.MAIL_ADDR
,t1.MAIL_PC
,t1.MAIL_DIST
,t1.ANNL_INC
,t1.TAX_INCOME
,t1.ID_EFCT_DATE
,t1.ID_DUE_DATE
,t1.ID_ORG_NAME
,t1.ID_DIST
,'add'
from dw_base.exp_credit_per_cust_info_ready t1
where day_id = '${v_sdate}'
and not exists (
select
1
from dw_base.exp_credit_per_cust_info_ready t2 
where t2.day_id = (select max(day_id) from dw_base.exp_credit_per_cust_info_ready
                   where day_id <'${v_sdate}'
				   )
and t1.CUST_ID = t2.CUST_ID
)
;

commit;

 
-- 插入修改客户
insert into dw_base.exp_credit_per_cust_info
select
t1.DAY_ID
,t1.CUST_ID
,t1.NAME
,t1.ID_TYPE
,t1.ID_NUM
,t1.inf_surc_code
,'20' -- 20-更新客户资料
,t1.CIMOC
,t1.CUSTOMER_TYPE  
,t1.SEX
,t1.DOB
,t1.NATION
,t1.HOUSE_ADD
,t1.HH_DIST
,t1.CELL_PHONE
,t1.EMAIL
,t1.MARI_STATUS
,t1.SPO_NAME
,t1.SPO_ID_TYPE
,t1.SPO_ID_NUM
,t1.SPO_TEL
,t1.SPS_CMPY_NM
,t1.EDU_LEVEL
,t1.ACA_DEGREE
,t1.EMP_STATUS
,t1.CPNNAME
,t1.CPN_TYPE
,t1.INDUSTRY
,t1.CPN_ADDR
,t1.CPN_PC
,t1.CPN_DIST
,t1.CPN_TEL
,t1.OCCUPATION
,t1.TITLE
,t1.TECH_TITLE
,t1.WORK_START_DATE
,t1.RESI_STATUS
,t1.RESI_ADDR
,t1.RESI_PC
,t1.RESI_DIST
,t1.HOME_TEL
,t1.MAIL_ADDR
,t1.MAIL_PC
,t1.MAIL_DIST
,t1.ANNL_INC
,t1.TAX_INCOME
,t1.ID_EFCT_DATE
,t1.ID_DUE_DATE
,t1.ID_ORG_NAME
,t1.ID_DIST
,'modify'
from dw_base.exp_credit_per_cust_info_ready t1
where day_id = '${v_sdate}'
and  exists (
select
1
from dw_base.exp_credit_per_cust_info_ready t2 
where day_id = (select max(day_id) from dw_base.exp_credit_per_cust_info_ready
                where day_id <'${v_sdate}'
				)
and t1.CUST_ID = t2.CUST_ID 
and (
  t1.NAME <> t2.NAME 
 -- or t1.SEX <> t2.SEX 
 -- or t1.DOB <> t2.DOB
 -- or t1.HOUSE_ADD <> t2.HOUSE_ADD
 -- or t1.CELL_PHONE <> t2.CELL_PHONE 
 -- or t1.EMAIL <> t2.EMAIL
 -- or t1.MARI_STATUS <> t2.MARI_STATUS
 -- or t1.SPO_NAME <> t2.SPO_NAME
 -- or t1.RESI_ADDR <> t2.RESI_ADDR
 -- or t1.ID_EFCT_DATE <> t2.ID_EFCT_DATE
 -- or t1.ID_DUE_DATE <> t2.ID_DUE_DATE
 -- or t1.ID_ORG_NAME <> t2.ID_ORG_NAME
  )
)
;

commit;

-- 整段删除 考虑通过页面组装
-- delete from dw_base.exp_credit_per_cust_dlt_info where day_id = DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d');
-- insert into dw_base.exp_credit_per_cust_dlt_info
-- select
-- t1.day_id	 -- 数据日期
-- ,t2.cust_id
-- ,t1.inf_rec_type -- 信息记录类型 114-个人基本信息整笔删除请求记录;
-- 134-个人证件有效期信息整笔删除请求记录
-- ,case when t1.inf_rec_type ='114' then '个人基本信息整笔删除请求记录'
--       when t1.inf_rec_type ='134' then '个人证件有效期信息整笔删除请求记录'
--       end
-- ,t1.name	-- a姓名
-- ,t2.id_type	-- a证件类型
-- ,t1.id_num	-- a证件号码
-- ,t2.inf_surc_code -- 信息来源编码
-- from dw_base.exp_credit_per_cust_dlt_info_ready t1
-- inner join dw_base.exp_credit_per_cust_info_ready t2
-- on t1.id_num = t2.id_num
-- and t2.day_id = DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d')
-- where t1.day_id = DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d')
-- ;
-- -- 家庭关系关系 不上报
-- delete from dw_base.exp_credit_per_cust_ref_info_ready where day_id = DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d');

-- insert into dw_base.exp_credit_per_cust_ref_info_ready
-- select
-- DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d') -- 数据日期
-- ,t2.cust_id -- 客户号
-- ,t2.name -- A姓名
-- ,t2.id_type -- A证件类型
-- ,t2.id_num -- A证件号码
-- ,t1.ref_person_name -- B姓名
-- ,t1.FAM_MEM_CERT_TYPE -- B证件类型
-- ,t1.FAM_MEM_CERT_NUM -- B证件号码
-- ,t1.FAM_REL -- 家族关系
-- ,t1.FAM_RELA_ASS_FLAG -- 家族成员关联标识
-- from
-- (select 
-- *
-- from
-- (
-- select
-- customer_id
-- ,ref_person_name -- B姓名
-- ,'' FAM_MEM_CERT_TYPE -- B证件类型
-- ,'' FAM_MEM_CERT_NUM --	B证件号码
-- ,case when ref_type = '3' then '5' 
--       when ref_type in ('4','5') then '8' 
-- 	  end FAM_REL -- 家族关系
-- ,'1'	FAM_RELA_ASS_FLAG -- 家族成员关联标识
-- from dw_nd.ods_gcredit_customer_social_ref 
-- where ref_type <> '1' 
-- order by create_time desc 
-- ) t
-- group by customer_id,ref_person_name
-- ) t1
-- inner join dw_base.tmp_exp_credit_per_cust_info_id t2
-- on t1.customer_id = t2.cust_id
-- ;

-- 新增

-- delete from dw_base.exp_credit_per_cust_ref_info where day_id = DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d');
 
-- insert into dw_base.exp_credit_per_cust_ref_info
-- select
-- t1.DAY_ID           
-- ,t1.CUST_ID          
-- ,t1.NAME             
-- ,t1.ID_TYPE          
-- ,t1.ID_NUM           
-- ,t1.FAM_MEM_NAME     
-- ,t1.FAM_MEM_CERT_TYPE
-- ,t1.FAM_MEM_CERT_NUM 
-- ,t1.FAM_REL          
-- ,t1.FAM_RELA_ASS_FLAG
-- ,'add'
-- from dw_base.exp_credit_per_cust_ref_info_ready t1
-- where day_id = DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d')
-- and not exists (
-- select
-- 1
-- from dw_base.exp_credit_per_cust_ref_info_ready t2 
-- where day_id = DATE_FORMAT(date_sub(date(now()),interval 2 day),'%Y%m%d') 
-- and t1.CUST_ID = t2.CUST_ID
-- and t1.FAM_MEM_NAME = t2.FAM_MEM_NAME
-- )
-- ;

-- 考虑到推送任务已切换到星环，未避免mysql和星环同步运行期间产生 同时推送，现注释改脚本推送内容 20241012

-- 同步集市

delete from dw_pbc.exp_credit_per_cust_info where day_id = '${v_sdate}' ;
commit ;

insert into dw_pbc.exp_credit_per_cust_info 
select * 
from dw_base.exp_credit_per_cust_info
where day_id = '${v_sdate}'
;
commit ;