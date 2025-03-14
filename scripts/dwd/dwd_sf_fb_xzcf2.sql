-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220120
-- 目标表   ：dw_base.dwd_sf_fb_xzcf2 风报-行政处罚2表
-- 源表     ：dw_nd.ods_extdata_fb_xzcf2 行政处罚2表、dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ： 20220120:统一变动 
--             20220516 日志变量注释  xgm   
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_fb_xzcf2';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;


-- 行政处罚2
-- drop index idx_ods_extdata_fb_xzcf2_seq on   dw_nd.ods_extdata_fb_xzcf2 ;
-- create  index idx_ods_extdata_fb_xzcf2_seq on   dw_nd.ods_extdata_fb_xzcf2(seqnum) ;
truncate table dw_base.dwd_sf_fb_xzcf2 ;
insert into dw_base.dwd_sf_fb_xzcf2
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
event_dt	, -- 事件时间
reles_dt	, -- 发布时间
punish_res	, -- 处罚事由
punish_basis	, -- 处罚依据
punish_decis	, -- 处罚决定
punish_no	, -- 处罚决定书文号
punish_dt	, -- 处罚决定日期
punish_org	, -- 处罚决定机关
punish_form	, -- 处罚表格
party	, -- 当事人
source	, -- 来源
title	, -- 标题
case_name	, -- 案件名称
body	, -- 正文
seqnum	, -- 生成查询批次号
query_dt	 -- 查询日期
)
  
select  
   b.cust_id	, -- 客户号
   b.cust_name	, -- 客户姓名
   a.event_time	, -- 事件时间
   a.release_time	, -- 发布时间
   a.punishmentment_reason	, -- 处罚事由
   a.punishment_according	, -- 处罚依据
   a.punishment_decision	, -- 处罚决定
   a.punishment_decision_no	, -- 处罚决定书文号
   a.punishment_decision_date	, -- 处罚决定日期
   a.punishment_decision_department	, -- 处罚决定机关
   a.punishment_form	, -- 处罚表格
   a.party	, -- 当事人
   a.source	, -- 来源
   a.title	, -- 标题
   a.case_name	, -- 案件名称
   a.body	, -- 正文
   a.seqnum	, -- 生成查询批次号
   a.createdate	 -- 当前日期
from (select event_time	, -- 事件时间
			release_time	, -- 发布时间
			punishmentment_reason	, -- 处罚事由
			punishment_according	, -- 处罚依据
			punishment_decision	, -- 处罚决定
			punishment_decision_no	, -- 处罚决定书文号
			punishment_decision_date	, -- 处罚决定日期
			punishment_decision_department	, -- 处罚决定机关
			punishment_form	, -- 处罚表格
			party	, -- 当事人
			source	, -- 来源
			title	, -- 标题
			case_name	, -- 案件名称
			body	, -- 正文
			seqnum	, -- 生成查询批次号
			createdate	 -- 当前日期
	from dw_nd.ods_extdata_fb_xzcf2 a 
	where  date_format(createdate,'%Y%m%d') <= '${v_sdate}'
) a
left join dw_base.dwd_sf_to_msg_log  b  on a.seqNum=b.seq_num ;
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('风报-行政处罚2数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
