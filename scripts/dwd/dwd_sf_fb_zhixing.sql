-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_sf_fb_zhixing 风报-被执行人表
-- 源表     ：dw_nd.ods_extdata_fb_zhixing 被执行人表、dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ： 20220117:统一变动  
--             20220516 日志变量注释  xgm  
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_fb_zhixing';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;  


-- 被执行人
truncate table dw_base.dwd_sf_fb_zhixing ;
insert into dw_base.dwd_sf_fb_zhixing
 (
   cust_id	, -- 客户号
   cust_name	, -- 客户姓名
   reles_dt	, -- 发布时间
   subject_matter	, -- 执行标的
   exe_court	, -- 执行法院
   case_stt	, -- 案件状态
   case_no	, -- 案号
   case_dt	, -- 立案时间
   exe_name	, -- 被执行人姓名/名称
   entit_name	, -- 执行相关的实体名称
   seq_num	, -- 生成查询批次号
   query_dt	 -- 查询日期
 )

select 

b.cust_id	, -- 客户号
b.cust_name	, -- 客户姓名
release_time	, -- 发布时间
subject_matter_of_enforcement	, -- 执行标的
execution_of_court	, -- 执行法院
state_of_case	, -- 案件状态
case_no	, -- 案号
case_of_time	, -- 立案时间
name_to_execution	, -- 被执行人姓名/名称
entities	, -- 执行相关的实体名称
seqnum	, -- 生成查询批次号
createdate	 -- 当前日期
from (select release_time	, -- 发布时间
			subject_matter_of_enforcement	, -- 执行标的
			execution_of_court	, -- 执行法院
			state_of_case	, -- 案件状态
			case_no	, -- 案号
			case_of_time	, -- 立案时间
			name_to_execution	, -- 被执行人姓名/名称
			entities	, -- 执行相关的实体名称
			seqnum	, -- 生成查询批次号
			createdate	 -- 当前日期 
	from dw_nd.ods_extdata_fb_zhixing a  
	where  date_format(createdate,'%Y%m%d') <= '${v_sdate}'
) a 
left join dw_base.dwd_sf_to_msg_log  b  on a.seqNum=b.seq_num ;
-- select row_count() into @rowcnt;
commit;

-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('执行人数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
