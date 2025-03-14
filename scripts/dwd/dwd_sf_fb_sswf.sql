-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_sf_fb_sswf 风报-重大税收违法表
-- 源表     ：dw_nd.ods_extdata_fb_sswf 重大税收违法表、dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ： 20220117:统一变动   
--             20220516 日志变量注释  xgm 
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_fb_sswf';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;


-- 重大税收违法
-- drop index idx_ods_extdata_fb_sswf_seq on   dw_nd.ods_extdata_fb_sswf ;
-- create  index idx_ods_extdata_fb_sswf_seq on   dw_nd.ods_extdata_fb_sswf(seqnum) ;
truncate table dw_base.dwd_sf_fb_sswf ;
insert into dw_base.dwd_sf_fb_sswf
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
illegal_facts	, -- 主要违法事实
event_dt	, -- 事件时间
reles_dt	, -- 发布时间
case_report_period	, -- 案件上报期
case_nature	, -- 案件性质
legal_basis	, -- 相关法律依据及税务处理处罚情况
tax_name	, -- 纳税人名称
tax_no	, -- 纳税人识别码
org_code	, -- 组织机构代码
seq_num	, -- 生成查询批次号
query_dt	 -- 当前日期
)
  
select  
   b.cust_id	, -- 客户号
   b.cust_name	, -- 客户姓名
   a.main_illegal_facts	, -- 主要违法事实
   a.event_time	, -- 事件时间
   a.release_time	, -- 发布时间
   a.case_reporting_period	, -- 案件上报期
   a.case_nature	, -- 案件性质
   a.legalbasis_punishments	, -- 相关法律依据及税务处理处罚情况
   a.name_of_taxpayer	, -- 纳税人名称
   a.taxpayer_identification_number	, -- 纳税人识别码
   a.organization_code	, -- 组织机构代码
   a.seqnum	, -- 生成查询批次号
   a.createdate	 -- 当前日期
from (select main_illegal_facts	, -- 主要违法事实
			event_time	, -- 事件时间
			release_time	, -- 发布时间
			case_reporting_period	, -- 案件上报期
			case_nature	, -- 案件性质
			legalbasis_punishments	, -- 相关法律依据及税务处理处罚情况
			name_of_taxpayer	, -- 纳税人名称
			taxpayer_identification_number	, -- 纳税人识别码
			organization_code	, -- 组织机构代码
			seqnum	, -- 生成查询批次号
			createdate	 -- 当前日期 
	from dw_nd.ods_extdata_fb_sswf a 
	where  date_format(createdate,'%Y%m%d') <= '${v_sdate}'
) a 
left join dw_base.dwd_sf_to_msg_log  b  on a.seqNum=b.seq_num ;
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('风报-重大税收违法数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;


