-- exp_credit_comp_cust_info 企业信息表
-- exp_credit_comp_sen_info 主要组成人员表
-- exp_credit_comp_sponsor_info 注册资本及主要出资人表 
-- exp_credit_comp_ref_info 关联关系信息记录表

-- ----------------------- 拆分
-- 企业基本信息-基础段
delete from creditda.t_en_bas_bs_sgmt where day_id = '${v_sdate}';
commit;

insert into creditda.t_en_bas_bs_sgmt
select
concat(DAY_ID,CUST_ID)  -- ID
,day_id
,CUST_ID
,'310' -- 信息记录类型
,ENT_NAME -- 企业名称
,ENT_CERT_TYPE -- 企业身份标识类型
,ENT_CERT_NUM -- 企业身份标识号码
,inf_surc_code -- 信息来源编码
,date_format(day_id,'%Y-%m-%d') -- 信息报告日期
,rpt_date_code -- 报告时点说明代码
,CIMOC -- 客户资料维护机构代码
,CUSTOMER_TYPE -- 客户资料类型
,ETP_STS -- 存续状态
,ORG_TYPE -- 组织机构类型 
,day_id -- 创建时间
from creditda.exp_credit_comp_cust_info t1
where day_id = '${v_sdate}'
;
commit;

-- 企业基本信息-联系方式
delete from creditda.t_en_bas_cota_inf_sgmt where day_id = '${v_sdate}';
commit;

insert into creditda.t_en_bas_cota_inf_sgmt
select
concat(DAY_ID,CUST_ID)  -- ID
,day_id
,CUST_ID
,CON_ADD_DISTRICT_CODE -- 联系地址行政区划代码
,CON_ADD -- 联系地址
,CON_PHONE -- 联系电话
,FIN_CON_PHONE -- 财务部门联系电话
,date_format(day_id,'%Y-%m-%d') -- 信息更新日期
,day_id -- 创建时间
from creditda.exp_credit_comp_cust_info t1
where day_id = '${v_sdate}'
;
commit;

-- 企业基本信息-基本概况段
delete from creditda.t_en_bas_fcs_inf_sgmt where day_id = '${v_sdate}';
commit;

insert into creditda.t_en_bas_fcs_inf_sgmt
select
concat(DAY_ID,CUST_ID)  -- ID
,day_id -- 
,CUST_ID -- 
,NATIONALITY -- 国别代码
,REG_ADD -- 登记地址
,ADM_DIV_OF_REG -- 登记地行政区划代码
,ESTABLISH_DATE -- 成立日期
,BIZ_END_DATE -- 营业许可到期日
,BIZ_RANGE -- 业务范围
,ECO_INDUS_CATE -- 行业分类代码
,ECO_TYPE -- 经济类型代码
,ENT_SCALE -- 企业规模
,date_format(day_id,'%Y-%m-%d') -- 信息更新日期
,day_id -- 创建时间
from creditda.exp_credit_comp_cust_info t1 
where day_id = '${v_sdate}'
;
commit;

-- 企业基本信息-主要组成人员段
delete from creditda.t_en_bas_mn_mmb_inf_sgmt where day_id = '${v_sdate}';
commit;
insert into creditda.t_en_bas_mn_mmb_inf_sgmt
select
concat(DAY_ID,CUST_ID)  -- ID
,day_id -- 
,CUST_ID -- 
,mmb_nm -- 主要组成人员个数
,date_format(day_id,'%Y-%m-%d') -- 信息更新日期
,day_id -- 创建时间
from 
(
select
day_id -- 
,CUST_ID -- 
,count(1)  mmb_nm -- 主要组成人员个数
from creditda.exp_credit_comp_sen_info t1
where t1.DAY_ID = '${v_sdate}'
group by  
 day_id  
,CUST_ID
) t
;
commit;

-- 企业基本信息-主要组成人员段 
delete from creditda.t_en_bas_mn_mmb_inf_sgmt_el where day_id = '${v_sdate}';
commit;

insert into creditda.t_en_bas_mn_mmb_inf_sgmt_el
select
null -- ID
,day_id -- 
,CUST_ID -- 
,concat(DAY_ID,CUST_ID) -- 主要组成人员段汇总信息表外键
,MMB_ALIAS -- 主要组成人员姓名
,MMB_ID_TYPE -- 主要组成人员证件类型
,MMB_ID_NUM -- 主要组成人员证件号码
,MMB_PSTN -- 主要组成人员职位
,day_id -- 创建时间
from creditda.exp_credit_comp_sen_info t1
where day_id = '${v_sdate}'
;
commit;

-- 企业基本信息-注册资本及主要出资人段
delete from creditda.t_en_bas_mn_sha_hod_inf_sgmt where day_id = '${v_sdate}';
commit;

insert into creditda.t_en_bas_mn_sha_hod_inf_sgmt
select
concat(DAY_ID,CUST_ID)  -- ID
,day_id -- 
,CUST_ID -- 
,'CNY' -- 注册资本币种
,reg_cap -- 注册资本
,mn_shar_hod_nm -- 主要出资人个数
,day_id -- 信息更新日期
,day_id -- 创建时间
from 
(
select
day_id -- 
,CUST_ID -- 
,max(reg_cap) reg_cap
,count(1)  mn_shar_hod_nm -- 主要出资人个数
from creditda.exp_credit_comp_sponsor_info t1
where t1.DAY_ID = '${v_sdate}'
group by  
 day_id  
,CUST_ID
) t1
;
commit;

delete from creditda.t_en_bas_mn_sha_hod_inf_sgmt_el where day_id = '${v_sdate}';
commit;

insert into creditda.t_en_bas_mn_sha_hod_inf_sgmt_el
select
null  -- ID
,day_id -- 
,CUST_ID -- 
,concat(DAY_ID,CUST_ID) -- 主要组成人员段汇总信息表外键
,SHAR_HOD_TYPE -- 出资人类型
,SHAR_HOD_CERT_TYPE -- 出资人身份类别
,SHAR_HOD_NAME -- 出资人姓名/名称
,SHAR_HOD_ID_TYPE -- 出资人身份标识类型
,SHAR_HOD_ID_NUM -- 出资人身份标识号码
,INV_RATIO -- 出资比例
,day_id -- 创建时间
from creditda.exp_credit_comp_sponsor_info t1  -- 主要出资人表
where t1.DAY_ID = '${v_sdate}'
;
commit;


-- 企业基本信息-上级机构段
delete from creditda.t_en_bas_spvsg_athrty_inf_sgmt where day_id = '${v_sdate}';
commit;

insert into creditda.t_en_bas_spvsg_athrty_inf_sgmt
select
concat(DAY_ID,CUST_ID)  -- ID
,day_id -- 
,CUST_ID -- 
,SUP_ORG_TYPE	-- 上级机构类型
,SUP_ORG_NAME	-- 上级机构名称
,SUP_ORG_CERT_TYPE -- 	上级机构身份标识类型
,SUP_ORG_CERT_NUM -- 	上级机构身份标识码
,date_format(day_id,'%Y-%m-%d') -- 信息更新日期
,day_id -- 创建时间
from creditda.exp_credit_comp_cust_info t1
where t1.DAY_ID = '${v_sdate}'
;
commit;

-- 企业间关联关系信息记录
delete from creditda.t_rd_en_icdn_rltp_inf where day_id = '${v_sdate}';
commit;

insert into creditda.t_rd_en_icdn_rltp_inf
select
null  -- ID
,day_id -- 
,CUST_ID -- 
,'350' -- 信息记录类型
,ENT_NAME -- 企业名称
,ENT_CERT_TYPE -- 企业身份标识类型
,ENT_CERT_NUM -- 企业身份标识号码
,ASSO_ENT_NAME -- 关联企业名称
,ASSO_ENT_CERT_TYPE -- 关联企业身份标识类型
,ASSO_ENT_CERT_NUM -- 关联企业身份标识号码
,ASSO_TYPE -- 关联关系类型
,ASSO_SIGN -- 关联标志
,date_format(day_id,'%Y-%m-%d') -- 信息报告日期
,0 status -- 状态
,day_id -- 创建时间
,day_id -- 更新时间
,null update_user_id  -- 更新人ID
,null file_id -- 上报文件ID
,null file_row -- 上报文件行号
from creditda.exp_credit_comp_ref_info t1
where t1.DAY_ID = '${v_sdate}'
;
commit;

delete from creditda.t_rd_en_bas_inf where day_id = '${v_sdate}';
commit;

insert into creditda.t_rd_en_bas_inf
select
null
,day_id
,cust_id
,date_format(day_id,'%Y-%m-%d') -- 信息报告日期
,concat(DAY_ID,CUST_ID)  -- 基础段ID
,concat(DAY_ID,CUST_ID)  -- 其他标识段ID
,concat(DAY_ID,CUST_ID)  -- 基本概况段ID
,concat(DAY_ID,CUST_ID)  -- 主要组成人员段ID
,concat(DAY_ID,CUST_ID)  -- 注册资本及主要出资人段ID
,concat(DAY_ID,CUST_ID)  -- 实际控制人段ID
,concat(DAY_ID,CUST_ID)  -- 上级机构段ID
,concat(DAY_ID,CUST_ID)  -- 联系方式段ID
,0 -- 状态
,day_id -- 创建时间
,day_id -- 更新时间
,null -- 更新人ID
,null -- 上报文件ID
,null -- 上报文件行号
from creditda.exp_credit_comp_cust_info  t1 
where t1.DAY_ID = '${v_sdate}'
;
commit;

-- 企业基本信息-实际控制人段
-- t_en_bas_actu_cotrl_inf_sgmt	
-- t_en_bas_actu_cotrl_inf_sgmt_el


-- 企业基本信息-其他标识段
-- t_en_bas_id_sgmt





-- 整笔删除
-- delete from creditda.t_rd_en_bs_inf_dlt where day_id = '${v_sdate}'; commit;
-- insert into creditda.t_rd_en_bs_inf_dlt
-- select
-- null
-- ,day_id
-- ,cust_id
-- ,DAY_ID -- 信息报告日期
-- ,'314'     -- 信息记录类型 企业基本信息整笔删除请求记录
-- ,inf_surc_code    -- 信息来源编码
-- ,ent_name         -- 企业名称
-- ,ent_cert_type    -- 企业身份标识类型
-- ,ent_cert_num     -- 企业身份标识号码
-- ,0           -- 状态
-- ,day_id -- 创建时间
-- ,day_id-- 更新时间
-- ,null -- 更新人ID
-- ,null -- 上报文件ID
-- ,null -- 上报文件行号
-- from  creditda.exp_credit_comp_cust_info  t1 
-- where t1.DAY_ID = '${v_sdate}'
-- and cust_id= '202007211053191951361051542'
-- ;
-- commit;

























