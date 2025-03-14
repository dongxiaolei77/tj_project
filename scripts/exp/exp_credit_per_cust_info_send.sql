-- exp_credit_per_cust_info  个人基本信息
-- exp_credit_per_cust_dlt_info 整段删除
-- exp_credit_per_cust_ref_info 家庭关系关系 不上报

-- 数据拆分
-- 个人基本信息-基础段
delete from dw_pbc.t_in_bas_bs_sgmt where day_id = '${v_sdate}';

commit ;

insert into dw_pbc.t_in_bas_bs_sgmt
select
concat(DAY_ID,CUST_ID)  -- ID
,DAY_ID -- DAY_ID
,CUST_ID
,'110' -- 信息记录类型
,NAME -- 姓名
,ID_TYPE -- 证件类型
,ID_NUM -- 证件号码
,inf_surc_code -- 信息来源编码
,DAY_ID -- 信息报告日期
,rpt_date_code -- 报告时点说明代码
,CIMOC -- 客户资料维护机构代码
,CUSTOMER_TYPE -- 客户资料类型
,now() -- 创建时间
from dw_pbc.exp_credit_per_cust_info t1
where t1.DAY_ID = '${v_sdate}'
;

commit ;


-- 个人基本信息-教育信息段
delete from dw_pbc.t_in_bas_edu_inf_sgmt where day_id = '${v_sdate}';

commit ;

insert into dw_pbc.t_in_bas_edu_inf_sgmt
select
concat(DAY_ID,CUST_ID)  -- ID
,DAY_ID -- DAY_ID
,CUST_ID
,EDU_LEVEL -- 学历
,ACA_DEGREE -- 学位
,DAY_ID -- 信息更新日期
,now() -- 创建时间
from dw_pbc.exp_credit_per_cust_info t1
where t1.DAY_ID = '${v_sdate}'
;

commit ;


-- 个人基本信息-基本概况段
delete from dw_pbc.t_in_bas_fcs_inf_sgmt where day_id = '${v_sdate}';

commit ;

insert into dw_pbc.t_in_bas_fcs_inf_sgmt
select
concat(DAY_ID,CUST_ID)  -- ID
,DAY_ID -- DAY_ID
,CUST_ID
,SEX -- 性别
,DOB -- 出生日期
,NATION -- 国籍
,HOUSE_ADD -- 户籍地址
,HH_DIST -- 户籍所在地行政区划
,CELL_PHONE -- 手机号码
,EMAIL -- 电子邮箱
,DAY_ID -- 信息更新日期
,now() -- 创建时间
from dw_pbc.exp_credit_per_cust_info t1
where t1.DAY_ID = '${v_sdate}'
;

commit ;


-- 个人基本信息-通讯地址段
delete from dw_pbc.t_in_bas_mlg_inf_sgmt where day_id = '${v_sdate}';

commit ;

insert into dw_pbc.t_in_bas_mlg_inf_sgmt
select
concat(DAY_ID,CUST_ID)  -- ID
,DAY_ID -- DAY_ID
,CUST_ID
,MAIL_ADDR -- 通讯地址
,MAIL_PC -- 通讯地邮编
,MAIL_DIST -- 通讯地行政区划
,DAY_ID -- 信息更新日期
,now() -- 创建时间
from dw_pbc.exp_credit_per_cust_info t1
where t1.DAY_ID = '${v_sdate}'
;

commit ;

 
-- 个人基本信息-职业信息段
delete from dw_pbc.t_in_bas_octpn_inf_sgmt where day_id = '${v_sdate}';

commit ;

insert into dw_pbc.t_in_bas_octpn_inf_sgmt
select
concat(DAY_ID,CUST_ID)  -- ID
,DAY_ID -- DAY_ID
,CUST_ID
,EMP_STATUS -- 就业状况
,CPNNAME -- 单位名称
,CPN_TYPE -- 单位性质
,INDUSTRY -- 单位所属行业
,CPN_ADDR -- 单位详细地址
,CPN_PC -- 单位所在地邮编
,CPN_DIST -- 单位所在地行政区划
,CPN_TEL -- 单位电话
,OCCUPATION -- 职业
,TITLE -- 职务
,TECH_TITLE -- 职称
,WORK_START_DATE -- 本单位工作起始年份
,DAY_ID -- 信息更新日期
,now() -- 创建时间
from dw_pbc.exp_credit_per_cust_info t1
where t1.DAY_ID = '${v_sdate}'
;

commit ;


-- 个人基本信息-居住地址段


delete from dw_pbc.t_in_bas_rednc_inf_sgmt where day_id = '${v_sdate}';

commit ;

insert into dw_pbc.t_in_bas_rednc_inf_sgmt
select
concat(DAY_ID,CUST_ID)  -- ID
,DAY_ID -- DAY_ID
,CUST_ID
,RESI_STATUS -- 居住状况
,RESI_ADDR -- 居住地详细地址
,RESI_PC -- 居住地邮编
,RESI_DIST -- 居住地行政区划
,HOME_TEL -- 住宅电话
,DAY_ID -- 信息更新日期
,now() -- 创建时间
from dw_pbc.exp_credit_per_cust_info t1
where t1.DAY_ID = '${v_sdate}'
;

commit ;


-- 个人基本信息-婚姻信息段
delete from dw_pbc.t_in_bas_sps_inf_sgmt where day_id = '${v_sdate}';

commit ;

insert into dw_pbc.t_in_bas_sps_inf_sgmt
select
concat(DAY_ID,CUST_ID)  -- ID
,DAY_ID -- DAY_ID
,CUST_ID
,MARI_STATUS -- 婚姻状况
,SPO_NAME -- 配偶姓名
,SPO_ID_TYPE -- 配偶证件类型
,SPO_ID_NUM -- 配偶证件号码
,SPO_TEL -- 配偶联系电话
,SPS_CMPY_NM -- 配偶工作单位
,DAY_ID -- 信息更新日期
,now() -- 创建时间
from dw_pbc.exp_credit_per_cust_info t1
where t1.DAY_ID = '${v_sdate}'
;

commit ;


-- 个人证件有效期信息记录
delete from dw_pbc.t_rd_in_id_efct_inf where day_id = '${v_sdate}';

commit ;

insert into dw_pbc.t_rd_in_id_efct_inf
select
null  -- ID
,DAY_ID -- DAY_ID
,CUST_ID
,'130' -- 信息记录类型
,NAME -- 姓名
,ID_TYPE -- 证件类型
,ID_NUM -- 证件号码
,inf_surc_code -- 信息来源编码
,ID_EFCT_DATE -- 证件有效期起始日期
,ID_DUE_DATE -- 证件有效期到期日期
,ID_ORG_NAME -- 证件签发机关名称
,ID_DIST -- 证件签发机关所在地行政区划
,'X3701010000337' -- 客户资料维护机构代码
,DAY_ID -- 信息报告日期
,0 -- 状态
,now() -- 创建时间
,now() -- 更新时间
,null -- 更新人ID
,null -- 上报文件ID
,null -- 上报文件行号
from dw_pbc.exp_credit_per_cust_info t1
where t1.DAY_ID = '${v_sdate}'
and id_efct_date <= '${v_sdate}'  -- 限制到期日
and ID_DUE_DATE >= '${v_sdate}' -- 限制到期日
;

commit ;



-- 个人基本信息记录
delete from dw_pbc.t_rd_in_bas_inf where day_id = '${v_sdate}';

commit ;

insert into dw_pbc.t_rd_in_bas_inf
select
null  -- ID
,DAY_ID -- DAY_ID
,CUST_ID
,DAY_ID -- 信息报告日期
,concat(DAY_ID,CUST_ID) -- 基础段ID
,concat(DAY_ID,CUST_ID) -- 其他标识段ID
,concat(DAY_ID,CUST_ID) -- 基本概况段ID
,concat(DAY_ID,CUST_ID) -- 婚姻信息段ID
,concat(DAY_ID,CUST_ID) -- 教育信息段ID
,concat(DAY_ID,CUST_ID) -- 职业信息段ID
,concat(DAY_ID,CUST_ID) -- 居住地址段ID
,concat(DAY_ID,CUST_ID) -- 通讯地址段ID
,null -- 收入信息段ID
,0 -- 状态
,now() -- 创建时间
,now() -- 更新时间
,null -- 更新人ID
,null -- 上报文件ID
,null -- 上报文件行号
from dw_pbc.exp_credit_per_cust_info t1
where t1.DAY_ID = '${v_sdate}'
;

commit ;





-- 	家族关系信息记录 不上报
-- delete from t_rd_in_fal_mmbs_inf where day_id = DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d');
-- 
-- commit ;
-- 
-- insert into t_rd_in_fal_mmbs_inf
-- select
-- null  -- ID
-- ,DAY_ID -- DAY_ID
-- ,CUST_ID
-- ,'120' -- 信息记录类型
-- ,NAME -- A 姓名
-- ,ID_TYPE -- A 证件类型
-- ,ID_NUM -- A 证件号码
-- ,FAM_MEM_NAME -- B 姓名
-- ,FAM_MEM_CERT_TYPE -- B 证件类型
-- ,FAM_MEM_CERT_NUM -- B 证件号码
-- ,FAM_REL -- 家族关系
-- ,FAM_RELA_ASS_FLAG -- 家族关系有效标志
-- ,'X3701010000337000001' -- 信息来源编码
-- ,DAY_ID -- 信息报告日期
-- ,0 -- 状态
-- ,now() -- 创建时间
-- ,now() -- 更新时间
-- ,null -- 更新人ID
-- ,null -- 上报文件ID
-- ,null -- 上报文件行号
-- from exp_credit_per_cust_ref_info t1
-- where t1.DAY_ID = DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d')
-- ;
-- 
-- commit ;

-- 个人基本信息-其他标识段
-- t_in_bas_id_sgmt
-- t_in_bas_id_sgmt_el

-- 个人基本信息-收入信息段 
-- t_in_bas_inc_inf_sgmt

-- 个人证件整合信息记录
-- t_rd_in_fal_mmbs_inf


 

