-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220120
-- 目标表   ：dw_base.dwd_sf_fb_sxbzxr 风报-失信被执行人表
-- 源表     ：dw_nd.ods_extdata_fb_sxbzxr 失信被执行人、dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ： 20220120:统一变动  
--             20220516 日志变量注释  xgm  
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_fb_sxbzxr';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;

-- 失信被执行人
-- drop index idx_ods_extdata_fb_sxbzxr_seq on   dw_nd.ods_extdata_fb_sxbzxr ;
-- create  index idx_ods_extdata_fb_sxbzxr_seq on   dw_nd.ods_extdata_fb_sxbzxr(seqnum) ;
truncate table dw_base.dwd_sf_fb_sxbzxr ;
insert into dw_base.dwd_sf_fb_sxbzxr
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
exe_org	, -- 做出执行依据单位
reles_dt	, -- 发布时间
un_credit_desc	, -- 失信被执行人行为具体情形
executed	, -- 已履行
age	, -- 年龄
exe_no	, -- 执行依据文号
court_org	, -- 执行法院
un_executed	, -- 未履行
case_no	, -- 案号
legal_name	, -- 法定代表人或者负责人姓名
doc_work	, -- 生效法律文书确定的义务
provc	, -- 省份
case_dt	, -- 立案时间
exe_name	, -- 被执行人姓名/名称
exe_detail	, -- 被执行人的履行情况
seq_num	, -- 生成查询批次号
query_dt	 -- 查询日期
)
  
select  
   b.cust_id	, -- 客户号
   b.cust_name	, -- 客户姓名
   a.execution_office	, -- 做出执行依据单位
   a.release_time	, -- 发布时间
   a.sxbzxrxwjtqx	, -- 失信被执行人行为具体情形
   a.executed	, -- 已履行
   a.age	, -- 年龄
   a.zxyjwh	, -- 执行依据文号
   a.execute_court	, -- 执行法院
   a.not_executed	, -- 未履行
   a.case_no	, -- 案号
   a.fddbrhzfzrxm	, -- 法定代表人或者负责人姓名
   a.sxflwsqddyw	, -- 生效法律文书确定的义务
   a.province	, -- 省份
   a.case_time	, -- 立案时间
   a.executed_name	, -- 被执行人姓名/名称
   a.executed_detail	, -- 被执行人的履行情况
   a.seqnum	, -- 生成查询批次号
   a.createdate	 -- 当前日期
from (select execution_office	, -- 做出执行依据单位
		release_time	, -- 发布时间
		sxbzxrxwjtqx	, -- 失信被执行人行为具体情形
		executed	, -- 已履行
		age	, -- 年龄
		zxyjwh	, -- 执行依据文号
		execute_court	, -- 执行法院
		not_executed	, -- 未履行
		case_no	, -- 案号
		fddbrhzfzrxm	, -- 法定代表人或者负责人姓名
		sxflwsqddyw	, -- 生效法律文书确定的义务
		province	, -- 省份
		case_time	, -- 立案时间
		executed_name	, -- 被执行人姓名/名称
		executed_detail	, -- 被执行人的履行情况
		seqnum	, -- 生成查询批次号
		createdate	 -- 当前日期 
		from dw_nd.ods_extdata_fb_sxbzxr a 
	where  date_format(createdate,'%Y%m%d') <= '${v_sdate}'
) a
left join dw_base.dwd_sf_to_msg_log  b  on a.seqNum=b.seq_num ;
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('风报-失信被执行人数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
