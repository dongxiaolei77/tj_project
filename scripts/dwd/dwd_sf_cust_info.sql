-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_sf_cust_info 三方客户基本信息 
-- 源表     ：dw_nd.ods_de_t_param_nd_de_baseinfo 客户基本信息、dw_base.dwd_cust_info 客户基本信息表
-- 变更记录 ：20220117：统一变动   
--            20220516 日志变量注释  xgm  
-- ---------------------------------------



-- set @etl_date='${v_sdate}';
-- set @pro_name='dwd_out_sf_fb';
-- set @table_name='dwd_sf_cust_info';
-- set @sorting=1;
-- set @time=now();
-- set @auto_increment_increment=1;  
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,'开始执行脚本',@time,now());commit;
-- set @sorting=@sorting+1;

   
-- 三方的一些模型 


-- 三方客户总表 

truncate table dw_base.dwd_sf_cust_info ; commit;
insert into  dw_base.dwd_sf_cust_info
(

cust_id	, -- 客户号
cust_name	, -- 客户姓名
cert_type	, -- 证件类型
cust_type	, -- 客户类型
tel_no	, -- 手机号
cert_no	, -- 证件号码
pieces_no	, -- 进件号
ref_tel_no	, -- 直系亲属手机号码
residence_city	, -- 居住地所属城市
credit_code	, -- 统一社会信用代码
cert_expiry	, -- 证件有效期
prod_type	, -- 产品种类
is_face	, -- 人脸识别标识
is_approve	, -- 人工信审标识
step_desc	, -- 节点信息
is_xwbank	, -- 新网开户标识
card_no	, -- 银行卡号
last_apply_dt	, -- 上次申贷时间
apply_city	, -- 申贷所在城市
is_business	, -- 是否填写经营消息
is_other_auza	, -- 是否填写三方授权
is_sple_info	, -- 是否填写补充消息
prod_code	, -- 产品编号
addr	, -- 用户地址信息
is_pbccrc	, -- 是否补充人行征信 0 否 1是
seq_num	, -- 生成查询批次号
xy_cust_id	, -- 信用管理客户ID
query_dt	  -- 查询日期
)

select 
	case when b.cust_id is not null then b.cust_id else CONCAT(case when a.custType='01' then 10 else 21 end,trim(a.customerno)) end  as cust_id	, -- 客户号 
	ifnull(legalName,companyname) as cust_name , -- 客户姓名             
	ifnull(b.cert_type,case when a.trxType='01' then 10 else 21 end )  as cert_type	, -- 证件类型
	ifnull(case when b.cust_type = 'P' then '1' when b.cust_type = 'C' then '2' else b.cust_type end,case when a.custType='01' then 1 else 2 end )  as cust_type	, -- 客户类型
	wcMobile                 as tel_no	, -- 手机号 
	ifnull(b.cert_no, a.customerno  )  as cert_no	, -- 证件号码
	piecesNoId           as pieces_no	, -- 进件号
	relativeMobile       as ref_tel_no	, -- 直系亲属手机号码 
	residenceCity        as residence_city	, -- 居住地所属城市 
	creditCode           as credit_code	, -- 统一社会信用代码 
	effective            as cert_expiry	, -- 证件有效期 
	productType          as prod_type	, -- 产品种类 
	isFaceReco           as is_face	, -- 人脸识别标识 
	isApprove            as is_approve	, -- 人工信审标识 
	toDeStep             as step_desc	, -- 节点信息 
	isXWBank             as is_xwbank	, -- 新网开户标识 
	bankCard             as card_no	, -- 银行卡号 
	lastApplyDate        as last_apply_dt	, -- 上次申贷时间 
	applyCity            as apply_city	, -- 申贷所在城市 
	isBusiness           as is_business	, -- 是否填写经营消息 
	isOtherAuthorization as is_other_auza	, -- 是否填写三方授权 
	isSupplementInfo     as is_sple_info	, -- 是否填写补充消息 
	prodCode             as prod_code	, -- 产品编号 
	address              as addr	, -- 用户地址信息 
	isPbccrc             as is_pbccrc	, -- 是否补充人行征信 0 否 1是 
	seqNum               as seq_num	, -- 生成查询批次号 
	custId               as xy_cust_id	, -- 信用管理客户ID
	createDate           as cur_dt	  -- 当前日期
from 
	(
	select 
		piecesNoId
		,customerno
		,custId
		,companyname
		,trxType
		,custType
		,wcMobile
		,legalName
		,legalIdCard
		,relativeMobile
		,residenceCity
		,creditCode
		,effective
		,productType
		,isFaceReco
		,isApprove
		,toDeStep
		,isXWBank
		,bankCard
		,lastApplyDate
		,applyCity
		,isBusiness
		,isOtherAuthorization
		,isSupplementInfo
		,prodCode
		,address
		,isPbccrc
		,seqNum
		,createDate
		,dataId
	from dw_nd.ods_de_t_param_nd_de_baseinfo  a 
	where date_format(createDate,'%Y%m%d') <=  '${v_sdate}'
) a
left join dw_base.dwd_cust_info b 
on a.customerno=b.cust_id 
;
commit;
