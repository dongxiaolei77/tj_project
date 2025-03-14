-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220120
-- 目标表   ：dw_base.dwd_sf_fb_xzcfc 风报-行政处罚表
-- 源表     ：dw_nd.ods_extdata_fb_xzcf 行政处罚表、dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ： 20220120:统一变动
--             20220516 日志变量注释  xgm    
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_fb_xzcf';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;


-- 行政处罚
-- drop index idx_ods_extdata_fb_xzcf_seq on   dw_nd.ods_extdata_fb_xzcf ;
-- create  index idx_ods_extdata_fb_xzcf_seq on   dw_nd.ods_extdata_fb_xzcf(seqnum) ;
truncate table dw_base.dwd_sf_fb_xzcf ;
insert into dw_base.dwd_sf_fb_xzcf
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
url	, -- url
name_pel	, -- 个人姓名
main_facts	, -- 主要违法违规事实（案由）
event_dt	, -- 事件时间
punish_dt	, -- 作出处罚决定的日期
punish_org	, -- 作出处罚决定的机关名称
ori_link	, -- 原文链接
reles_dt	, -- 发布时间
name	, -- 名称
punish_form	, -- 处罚表格
punish_dpt	, -- 处罚部门
party	, -- 当事人
source	, -- 来源
title	, -- 标题
body	, -- 正文
legal_name	, -- 法定代表人（主要负责人）姓名
punish_basis	, -- 行政处罚依据
punish_decis	, -- 行政处罚决定
punish_no	, -- 行政处罚决定书文号
seq_num	, -- 生成查询批次号
query_dt	 -- 查询日期
)
  
select  
   b.cust_id	, -- 客户号
   b.cust_name	, -- 客户姓名
   a.url	, -- url
   a.personal_name	, -- 个人姓名
   a.main_illegal_facts	, -- 主要违法违规事实（案由）
   a.event_time	, -- 事件时间
   a.penalty_decision_date	, -- 作出处罚决定的日期
   a.penalty_decision_agency	, -- 作出处罚决定的机关名称
   a.original_link	, -- 原文链接
   a.release_time	, -- 发布时间
   a.name	, -- 名称
   a.punishment_form	, -- 处罚表格
   a.punishment_department	, -- 处罚部门
   a.party	, -- 当事人
   a.source	, -- 来源
   a.title	, -- 标题
   a.body	, -- 正文
   a.legal_representative	, -- 法定代表人（主要负责人）姓名
   a.administrative_penalty_basis	, -- 行政处罚依据
   a.administrative_penalty_decision	, -- 行政处罚决定
   a.administrative_penalty_titanic	, -- 行政处罚决定书文号
   a.seqnum	, -- 生成查询批次号
   a.createdate	 -- 当前日期
from (select url	, -- url
			personal_name	, -- 个人姓名
			main_illegal_facts	, -- 主要违法违规事实（案由）
			event_time	, -- 事件时间
			penalty_decision_date	, -- 作出处罚决定的日期
			penalty_decision_agency	, -- 作出处罚决定的机关名称
			original_link	, -- 原文链接
			release_time	, -- 发布时间
			name	, -- 名称
			punishment_form	, -- 处罚表格
			punishment_department	, -- 处罚部门
			party	, -- 当事人
			source	, -- 来源
			title	, -- 标题
			body	, -- 正文
			legal_representative	, -- 法定代表人（主要负责人）姓名
			administrative_penalty_basis	, -- 行政处罚依据
			administrative_penalty_decision	, -- 行政处罚决定
			administrative_penalty_titanic	, -- 行政处罚决定书文号
			seqnum	, -- 生成查询批次号
			createdate	 -- 当前日期 
	from dw_nd.ods_extdata_fb_xzcf a
	where  date_format(createdate,'%Y%m%d') <= '${v_sdate}'
) a
left join dw_base.dwd_sf_to_msg_log  b  on a.seqNum=b.seq_num ;
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('风报-行政处罚数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
