
-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_sf_fb_gsbg 风报-工商变更表
-- 源表     ：dw_nd.ods_extdata_fb_gsbg 工商变更表、dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ： 20220117:统一变动 
--             20220516 日志变量注释  xgm   
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_fb_gsbg';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;

-- 工商变更
-- drop index idx_ods_extdata_fb_gsbg_seq on   dw_nd.ods_extdata_fb_gsbg ;
-- create  index idx_ods_extdata_fb_gsbg_seq on   dw_nd.ods_extdata_fb_gsbg(seqnum) ;
truncate table dw_base.dwd_sf_fb_gsbg ;
insert into dw_base.dwd_sf_fb_gsbg
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
change_name	, -- 变更事项
change_before	, -- 变更前
change_after	, -- 变更后
change_dt	, -- 变更日期
seq_num	, -- 生成查询批次号
query_dt	 -- 查询日期
)
  
select  
   b.cust_id	, -- 客户号
   b.cust_name	, -- 客户姓名
   a.changes	, -- 变更事项
   a.change_before	, -- 变更前
   a.change_after	, -- 变更后
   a.change_date	, -- 变更日期
   a.seqnum	, -- 生成查询批次号
   a.createdate	  -- 当前日期
from (select changes	, -- 变更事项
			change_before	, -- 变更前
			change_after	, -- 变更后
			change_date	, -- 变更日期
			seqnum	, -- 生成查询批次号
			createdate	  -- 当前日期 
	from dw_nd.ods_extdata_fb_gsbg a 
	where  date_format(createdate,'%Y%m%d') <= '${v_sdate}'
) a
left join dw_base.dwd_sf_to_msg_log  b  on a.seqNum=b.seq_num ;
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('风报-工商变更数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
