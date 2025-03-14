-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_sf_fb_ktgg 风报-开庭公告表
-- 源表     ：dw_nd.ods_extdata_fb_ktgg 开庭公告表、dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ： 20220117:统一变动 
--             20220516 日志变量注释  xgm   
--             20241201 脚本的统一变更，MySQL5.0转MySQL8.0 zhangfl
-- ---------------------------------------
-- 开庭公告
truncate table dw_base.dwd_sf_fb_ktgg ;
insert into dw_base.dwd_sf_fb_ktgg
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
entities	, -- entities
other_roles	, -- 其他角色
plaintiff	, -- 原告/上诉人
reles_dt	, -- 发布时间
court_dt	, -- 开庭时间
party	, -- 当事人
party_detail	, -- 当事人详情
title	, -- 标题
case_type	, -- 案件类型
case_no	, -- 案号
case_reason	, -- 案由
message	, -- 正文
judge	, -- 法官
court1	, -- 法庭
court2	, -- 法院
defendant	, -- 被告/被上诉人
seq_num	, -- 生成查询批次号
query_dt	 -- 查询日期
)
  
select  
   b.cust_id	, -- 客户号
   b.cust_name	, -- 客户姓名
   a.entities	, -- entities
   a.other_roles	, -- 其他角色
   a.plaintiff	, -- 原告/上诉人
   a.release_time	, -- 发布时间
   a.court_date	, -- 开庭时间
   a.party	, -- 当事人
   a.party_detail	, -- 当事人详情
   a.title	, -- 标题
   a.case_type	, -- 案件类型
   a.case_no	, -- 案号
   a.case_reason	, -- 案由
   a.message	, -- 正文
   a.judge	, -- 法官
   a.court1	, -- 法庭
   a.court2	, -- 法院
   a.defendant	, -- 被告/被上诉人
   a.seqnum	, -- 生成查询批次号
   a.createdate	 -- 当前日期
from (select entities	, -- entities
			other_roles	, -- 其他角色
			plaintiff	, -- 原告/上诉人
			release_time	, -- 发布时间
			court_date	, -- 开庭时间
			party	, -- 当事人
			party_detail	, -- 当事人详情
			title	, -- 标题
			case_type	, -- 案件类型
			case_no	, -- 案号
			case_reason	, -- 案由
			message	, -- 正文
			judge	, -- 法官
			court1	, -- 法庭
			court2	, -- 法院
			defendant	, -- 被告/被上诉人
			seqnum	, -- 生成查询批次号
			createdate	 -- 当前日期 
	from dw_nd.ods_extdata_fb_ktgg a 
	where  date_format(createdate,'%Y%m%d') <= '${v_sdate}'
) a
left join dw_base.dwd_sf_to_msg_log  b  on a.seqNum=b.seq_num ;
commit; 
