
-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_sf_fb_ssgg 风报-诉讼公告表
-- 源表     ：dw_nd.ods_extdata_fb_ssgg 诉讼公告表、dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ： 20220117:统一变动  
--             20220516 日志变量注释  xgm  
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_fb_ssgg';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;

-- 涉诉公告
-- drop index idx_ods_extdata_fb_ssgg_seq on   dw_nd.ods_extdata_fb_ssgg ;
-- create  index idx_ods_extdata_fb_ssgg_seq on   dw_nd.ods_extdata_fb_ssgg(seqnum) ;
truncate table dw_base.dwd_sf_fb_ssgg ;
insert into dw_base.dwd_sf_fb_ssgg
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
entities	, -- entities
public_person	, -- 公告人
public_dt	, -- 公告时间
public_type	, -- 公告类型
party	, -- 当事人
message	, -- 正文
seq_num	, -- 生成查询批次号
query_dt	 -- 查询日期
)
  
select  
   b.cust_id	, -- 客户号
   b.cust_name	, -- 客户姓名
   a.entities	, -- entities
   a.public_person	, -- 公告人
   a.public_time	, -- 公告时间
   a.public_type	, -- 公告类型
   a.party	, -- 当事人
   a.message	, -- 正文
   a.seqnum	, -- 生成查询批次号
   a.createdate	 -- 当前日期
from (select entities	, -- entities
			public_person	, -- 公告人
			public_time	, -- 公告时间
			public_type	, -- 公告类型
			party	, -- 当事人
			message	, -- 正文
			seqnum	, -- 生成查询批次号
			createdate	 -- 当前日期 
		from dw_nd.ods_extdata_fb_ssgg a 
	where  date_format(createdate,'%Y%m%d') <= '${v_sdate}'
)  a
left join dw_base.dwd_sf_to_msg_log  b  on a.seqNum=b.seq_num ;
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('风报-诉讼公告数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
