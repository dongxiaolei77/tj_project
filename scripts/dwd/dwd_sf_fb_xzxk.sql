-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220120
-- 目标表   ：dw_base.dwd_sf_fb_xzxk 风报-行政许可表
-- 源表     ：dw_nd.ods_extdata_fb_xzxk 行政许可表、dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ： 20220120:统一变动    
--             20220516 日志变量注释  xgm
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_fb_xzxk';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;


-- 行政许可
-- drop index idx_ods_extdata_fb_xzxk_seq on   dw_nd.ods_extdata_fb_xzxk ;
-- create  index idx_ods_extdata_fb_xzxk_seq on   dw_nd.ods_extdata_fb_xzxk(seqnum) ;
truncate table dw_base.dwd_sf_fb_xzxk ;
insert into dw_base.dwd_sf_fb_xzxk
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
reles_dt	, -- 发布时间
party	, -- 当事人
source	, -- 来源
lice_name	, -- 许可事项名称
lice_cont	, -- 许可内容
lice_org	, -- 许可机关
lice_form	, -- 许可表格
seq_num	, -- 生成查询批次号
query_dt	 -- 查询日期
)
  
select  
   b.cust_id	, -- 客户号
   b.cust_name	, -- 客户姓名
   a.release_time	, -- 发布时间
   a.party	, -- 当事人
   a.source	, -- 来源
   a.name_of_license_item	, -- 许可事项名称
   a.licensed_content	, -- 许可内容
   a.licensing_authority	, -- 许可机关
   a.permission_form	, -- 许可表格
   a.seqnum	, -- 生成查询批次号
   a.createdate	 -- 当前日期
from (select release_time	, -- 发布时间
			party	, -- 当事人
			source	, -- 来源
			name_of_license_item	, -- 许可事项名称
			licensed_content	, -- 许可内容
			licensing_authority	, -- 许可机关
			permission_form	, -- 许可表格
			seqnum	, -- 生成查询批次号
			createdate	 -- 当前日期c 
	from dw_nd.ods_extdata_fb_xzxk a
	where  date_format(createdate,'%Y%m%d') <= '${v_sdate}'
) a
left join dw_base.dwd_sf_to_msg_log  b  on a.seqNum=b.seq_num ;
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('风报-行政许可数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
