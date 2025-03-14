-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_sf_fb_db 风报-担保信息表 
-- 源表     ：dw_nd.ods_extdata_fb_db 担保信息表、dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ： 20220117:统一变动
--             20220516 日志变量注释  xgm     
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_fb_db';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1; 


-- 担保信息
-- drop index idx_ods_extdata_fb_db_seq on   dw_nd.ods_extdata_fb_db ;
-- create  index idx_ods_extdata_fb_db_seq on   dw_nd.ods_extdata_fb_db(seqnum) ;
truncate table dw_base.dwd_sf_fb_db ;
insert into dw_base.dwd_sf_fb_db
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
url	, -- url
event_dt	, -- 事件时间
bus_dt	, -- 交易日期
anct_party	, -- 公告方
anct_dt	, -- 公告日期
party	, -- 当事人
report_period	, -- 报告期
report_type	, -- 报告类型
guarantee_desc	, -- 担保事件说明
guarantor	, -- 担保方
guarantee_method	, -- 担保方式
guarantee_period	, -- 担保期限
guarantee_sdt	, -- 担保起止日期
guarantee_amt	, -- 担保金额
is_related	, -- 是否关联交易
is_finish	, -- 是否履行完毕
title	, -- 标题
is_guaranteed	, -- 被担保方
details	, -- 详情
seq_num	, -- 生成查询批次号
query_dt	 -- 查询日期
)
  
select  
   b.cust_id	, -- 客户号
   b.cust_name	, -- 客户姓名
   a.url	,  
   a.event_time	, -- 事件时间
   a.transaction_date	, -- 交易日期
   a.announcement_party	, -- 公告方
   a.announcement_date	, -- 公告日期
   a.party	, -- 当事人
   a.report_period	, -- 报告期
   a.report_type	, -- 报告类型
   a.guarantee_description	, -- 担保事件说明
   a.guarantor	, -- 担保方
   a.guarantee_method	, -- 担保方式
   a.guarantee_period	, -- 担保期限
   a.guarantee_start_date	, -- 担保起止日期
   a.guarantee_amount	, -- 担保金额
   a.is_related	, -- 是否关联交易
   a.is_finish	, -- 是否履行完毕
   a.title	, -- 标题
   a.is_guaranteed	, -- 被担保方
   a.details	, -- 详情
   a.seqnum	, -- 生成查询批次号
   a.createdate  -- 当前日期

from (select url	,  
			event_time	, -- 事件时间
			transaction_date	, -- 交易日期
			announcement_party	, -- 公告方
			announcement_date	, -- 公告日期
			party	, -- 当事人
			report_period	, -- 报告期
			report_type	, -- 报告类型
			guarantee_description	, -- 担保事件说明
			guarantor	, -- 担保方
			guarantee_method	, -- 担保方式
			guarantee_period	, -- 担保期限
			guarantee_start_date	, -- 担保起止日期
			guarantee_amount	, -- 担保金额
			is_related	, -- 是否关联交易
			is_finish	, -- 是否履行完毕
			title	, -- 标题
			is_guaranteed	, -- 被担保方
			details	, -- 详情
			seqnum	, -- 生成查询批次号
			createdate  -- 当前日期 
	 from dw_nd.ods_extdata_fb_db a 
	 where  date_format(createdate,'%Y%m%d') <= '${v_sdate}'
) a
left join dw_base.dwd_sf_to_msg_log  b  on a.seqNum=b.seq_num ;
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('风报-担保信息数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
