-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_sf_fb_dwtz 风报-对外投资表
-- 源表     ：dw_nd.ods_extdata_fb_dwtz 对外投资表、dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ： 20220117:统一变动 
--             20220516 日志变量注释  xgm   
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_fb_dwtz';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;

-- 对外投资
-- drop index idx_ods_extdata_fb_dwtz_seq on   dw_nd.ods_extdata_fb_dwtz ;
-- create  index idx_ods_extdata_fb_dwtz_seq on   dw_nd.ods_extdata_fb_dwtz(seqnum) ;
truncate table dw_base.dwd_sf_fb_dwtz ;
insert into dw_base.dwd_sf_fb_dwtz
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
name	, -- 名称
old_name	, -- 曾用名
approval_dt	, -- 核准日期
reg_no	, -- 注册号
reg_org	, -- 登记机关
reg_stt	, -- 登记状态
credit_code	, -- 统一社会信用代码
seq_num	, -- 生成查询批次号
query_dt	 -- 查询日期
)
  
select  
   b.cust_id	, -- 客户号
   b.cust_name	, -- 客户姓名
   a.name	, -- 名称
   a.old_name	, -- 曾用名
   a.approval_date	, -- 核准日期
   a.registration_number	, -- 注册号
   a.registration_authority	, -- 登记机关
   a.registration_status	, -- 登记状态
   a.credit_code	, -- 统一社会信用代码
   a.seqnum	, -- 生成查询批次号
   a.createdate	 -- 当前日期
from 
(	select name	, -- 名称
		   old_name	, -- 曾用名
		   approval_date	, -- 核准日期
		   registration_number	, -- 注册号
		   registration_authority	, -- 登记机关
		   registration_status	, -- 登记状态
		   credit_code	, -- 统一社会信用代码
		   seqnum	, -- 生成查询批次号
		   createdate	 -- 当前日期c
	from dw_nd.ods_extdata_fb_dwtz a 
	where  date_format(createdate,'%Y%m%d') <= '${v_sdate}'
) a
left join dw_base.dwd_sf_to_msg_log  b  on a.seqNum=b.seq_num ;
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('风报-担保信息数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
