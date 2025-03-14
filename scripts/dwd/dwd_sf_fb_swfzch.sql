-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220120
-- 目标表   ：dw_base.dwd_sf_fb_swfzch 风报-税务非正常用户信息表
-- 源表     ：dw_nd.ods_extdata_fb_swfzch 税务非正常用户信息表、dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ： 20220120:统一变动 
--             20220516 日志变量注释  xgm   
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_fb_swfzch';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;

-- 税务非正常户信息
-- drop index idx_ods_extdata_fb_swfzch_seq on   dw_nd.ods_extdata_fb_swfzch ;
-- create  index idx_ods_extdata_fb_swfzch_seq on   dw_nd.ods_extdata_fb_swfzch(seqnum) ;
truncate table dw_base.dwd_sf_fb_swfzch ;
insert into dw_base.dwd_sf_fb_swfzch
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
enterprise_name	, -- 企业名称
reles_dt	, -- 发布期
legal_name	, -- 法定代表人
tax_org	, -- 税务机关
business_addr	, -- 经营地址
ident_st	, -- 认定时间
ident_no	, -- 识别号
seq_num	, -- 生成查询批次号
query_dt	 -- 当前日期
)
  
select  
   b.cust_id	, -- 客户号
   b.cust_name	, -- 客户姓名
   a.enterprise_name	, -- 企业名称
   a.launch_date	, -- 发布期
   a.legal_representative	, -- 法定代表人
   a.tax_authority	, -- 税务机关
   a.business_address	, -- 经营地址
   a.identified_time	, -- 认定时间
   a.identification_number	, -- 识别号
   a.seqnum	, -- 生成查询批次号
   a.createdate	 -- 当前日期
from (select enterprise_name	, -- 企业名称
			launch_date	, -- 发布期
			legal_representative	, -- 法定代表人
			tax_authority	, -- 税务机关
			business_address	, -- 经营地址
			identified_time	, -- 认定时间
			identification_number	, -- 识别号
			seqnum	, -- 生成查询批次号
			createdate	 -- 当前日期 
	from dw_nd.ods_extdata_fb_swfzch a 
	where  date_format(createdate,'%Y%m%d') <= '${v_sdate}'
) a
left join dw_base.dwd_sf_to_msg_log  b  on a.seqNum=b.seq_num ;
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('风报-税务非正常用户信息数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
