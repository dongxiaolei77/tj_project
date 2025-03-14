-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_sf_fb_gszl 风报-工商资料表
-- 源表     ：dw_nd.ods_extdata_fb_gszl 工商资料表、dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ： 20220117:统一变动  
--             20220516 日志变量注释  xgm  
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_fb_gszl';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;

-- 工商资料
-- drop index idx_ods_extdata_fb_gszl_seq on   dw_nd.ods_extdata_fb_gszl ;
-- create  index idx_ods_extdata_fb_gszl_seq on   dw_nd.ods_extdata_fb_gszl(seqnum) ;
truncate table dw_base.dwd_sf_fb_gszl ;
insert into dw_base.dwd_sf_fb_gszl
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
annual_evaluation	, -- A级纳税人评价年度
bus_org	, -- 业务主管单位
issue_dt	, -- 发照日期
issue_org	, -- 发证机关
revoke_dt	, -- 吊销日期
name	, -- 名称
addr	, -- 地址
dzhy	, -- 多证合一
found_dt	, -- 成立日期
manage_part	, -- 执行事务合伙人
manage_part_main	, -- 执行事务合伙人（委派代表）
investor	, -- 投资人
old_name	, -- 曾用名
approval_dt	, -- 核准日期
execute	, -- 法代/执行
legal_name	, -- 法定代表人
reg_no	, -- 注册号
reg_cny	, -- 注册资本币种
reg_capt	, -- 注册资本（万元）
reg_cancel_dt	, -- 注吊销日期
cancel_dt	, -- 注销日期
dispat_comp_name	, -- 派出企业名称
reg_dt	, -- 登记时间
reg_org	, -- 登记机关
reg_stt	, -- 登记状态
provc_city	, -- 省市
type	, -- 类型
typr_code	, -- 类型代码
economic_nature	, -- 经济性质
operating_period_from	, -- 经营期限自
operating_period_to	, -- 经营期限至
operator	, -- 经营者
business_scope	, -- 经营范围
credit_code	, -- 统一社会信用代码
tel_no	, -- 联系电话
stock	, -- 股票
valuation_level	, -- 评估等级
leader	, -- 负责人
trade_indust_org	, -- 迁入地工商局
chief_delegate	, -- 首席代表
seq_num	, -- 生成查询批次号
query_dt	 -- 查询日期
)
  
select  
   b.cust_id	, -- 客户号
   b.cust_name	, -- 客户姓名
   a.annual_evaluation	, -- A级纳税人评价年度
   a.business_executive_unit	, -- 业务主管单位
   a.issue_date	, -- 发照日期
   a.licence_issuing_authority	, -- 发证机关
   a.revoke_date	, -- 吊销日期
   a.name	, -- 名称
   a.address	, -- 地址
   a.dzhy	, -- 多证合一
   a.create_date	, -- 成立日期
   a.manage_partner	, -- 执行事务合伙人
   a.manage_partner_member	, -- 执行事务合伙人（委派代表）
   a.investor	, -- 投资人
   a.old_name	, -- 曾用名
   a.approval_date	, -- 核准日期
   a.execute	, -- 法代/执行
   a.legal_representative	, -- 法定代表人
   a.registration_number	, -- 注册号
   a.registration_currency	, -- 注册资本币种
   a.registration_amount	, -- 注册资本（万元）
   a.registration_cancellation_date	, -- 注吊销日期
   a.cancellation_date	, -- 注销日期
   a.dispatched_enterprise_name	, -- 派出企业名称
   a.registration_time	, -- 登记时间
   a.registration_office	, -- 登记机关
   a.registration_status	, -- 登记状态
   a.province_city	, -- 省市
   a.type	, -- 类型
   a.typr_code	, -- 类型代码
   a.economic_nature	, -- 经济性质
   a.operating_period_from	, -- 经营期限自
   a.operating_period_to	, -- 经营期限至
   a.operator	, -- 经营者
   a.business_scope	, -- 经营范围
   a.credit_code	, -- 统一社会信用代码
   a.phone_number	, -- 联系电话
   a.stock	, -- 股票
   a.valuation_level	, -- 评估等级
   a.leader	, -- 负责人
   a.trade_industry_bureau	, -- 迁入地工商局
   a.chief_delegate	, -- 首席代表
   a.seqnum	, -- 生成查询批次号
   a.createdate	 -- 当前日期
from (select    annual_evaluation	, -- A级纳税人评价年度
			business_executive_unit	, -- 业务主管单位
			issue_date	, -- 发照日期
			licence_issuing_authority	, -- 发证机关
			revoke_date	, -- 吊销日期
			name	, -- 名称
			address	, -- 地址
			dzhy	, -- 多证合一
			create_date	, -- 成立日期
			manage_partner	, -- 执行事务合伙人
			manage_partner_member	, -- 执行事务合伙人（委派代表）
			investor	, -- 投资人
			old_name	, -- 曾用名
			approval_date	, -- 核准日期
			execute	, -- 法代/执行
			legal_representative	, -- 法定代表人
			registration_number	, -- 注册号
			registration_currency	, -- 注册资本币种
			registration_amount	, -- 注册资本（万元）
			registration_cancellation_date	, -- 注吊销日期
			cancellation_date	, -- 注销日期
			dispatched_enterprise_name	, -- 派出企业名称
			registration_time	, -- 登记时间
			registration_office	, -- 登记机关
			registration_status	, -- 登记状态
			province_city	, -- 省市
			type	, -- 类型
			typr_code	, -- 类型代码
			economic_nature	, -- 经济性质
			operating_period_from	, -- 经营期限自
			operating_period_to	, -- 经营期限至
			operator	, -- 经营者
			business_scope	, -- 经营范围
			credit_code	, -- 统一社会信用代码
			phone_number	, -- 联系电话
			stock	, -- 股票
			valuation_level	, -- 评估等级
			leader	, -- 负责人
			trade_industry_bureau	, -- 迁入地工商局
			chief_delegate	, -- 首席代表
			seqnum	, -- 生成查询批次号
			createdate	 -- 当前日期 
	from dw_nd.ods_extdata_fb_gszl a 
	where  date_format(createdate,'%Y%m%d') <= '${v_sdate}'
) a
left join dw_base.dwd_sf_to_msg_log  b  on a.seqNum=b.seq_num ;
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('风报-工商资料数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
