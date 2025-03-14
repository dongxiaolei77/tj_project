-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_sf_fb_jyyc 风报-经营异常表
-- 源表     ：dw_nd.ods_extdata_fb_jyyc 经营异常表、dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ： 20220117:统一变动  
--             20220516 日志变量注释  xgm  
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_fb_jyyc';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;

-- 经营异常
-- drop index idx_ods_extdata_fb_jyyc_seq on   dw_nd.ods_extdata_fb_jyyc ;
-- create  index idx_ods_extdata_fb_jyyc_seq on   dw_nd.ods_extdata_fb_jyyc(seqnum) ;
truncate table dw_base.dwd_sf_fb_jyyc ;
insert into dw_base.dwd_sf_fb_jyyc
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
decision_office	, -- 作出决定机关
decision_office_in	, -- 作出决定机关(列入)
decision_office_out	, -- 作出决定机关(移出)
in_dt	, -- 列入日期
except_reason	, -- 异常原因
out_reason	, -- 移出原因
out_dt	, -- 移出日期
seqnum	, -- 生成查询批次号
query_dt	 -- 查询日期
)
  
select  
   b.cust_id	, -- 客户号
   b.cust_name	, -- 客户姓名
   a.decision_office	, -- 作出决定机关
   a.decision_office_in	, -- 作出决定机关(列入)
   a.decision_office_out	, -- 作出决定机关(移出)
   a.in_reason	, -- 列入日期
   a.exception_reason	, -- 异常原因
   a.out_reason	, -- 移出原因
   a.out_date	, -- 移出日期
   a.seqnum	, -- 生成查询批次号
   a.createdate	 -- 当前日期
from (select decision_office	, -- 作出决定机关
			decision_office_in	, -- 作出决定机关(列入)
			decision_office_out	, -- 作出决定机关(移出)
			in_reason	, -- 列入日期
			exception_reason	, -- 异常原因
			out_reason	, -- 移出原因
			out_date	, -- 移出日期
			seqnum	, -- 生成查询批次号
			createdate	 -- 当前日期 
	from dw_nd.ods_extdata_fb_jyyc a 
	where  date_format(createdate,'%Y%m%d') <= '${v_sdate}'
) a
left join dw_base.dwd_sf_to_msg_log  b  on a.seqNum=b.seq_num ;
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('风报-经营异常数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
