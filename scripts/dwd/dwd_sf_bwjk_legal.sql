-- ---------------------------------------
-- 开发人   : 
-- 开发时间 ：
-- 目标表   ：dwd_sf_bwjk_legal
-- 源表     ：dw_nd.ods_extdata_bwfintech_legal 司法失信
    --        dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ：  20220117统一修改
--              20220516 日志变量注释  xgm 
-- ---------------------------------------

-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_bwjk_legal';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;

-- drop index idx_ods_extdata_bwfintech_legal_seq on   dw_nd.ods_extdata_bwfintech_legal ;
-- create  index idx_ods_extdata_bwfintech_legal_seq on   dw_nd.ods_extdata_bwfintech_legal(seqnum) ;

-- 司法失信
truncate table dw_base.dwd_sf_bwjk_legal ;
insert into dw_base.dwd_sf_bwjk_legal
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
legal_statu	, -- 司法失信命中0未命中   1命中
seq_num	, -- 查询批次号
query_dt	 -- 创建日期
)
  
select  
   c.cust_id	, -- 客户号
   c.cust_name	, -- 客户姓名
   a.legalStatus	, -- 司法失信命中0未命中   1命中
   a.seqNum	, -- 查询批次号
   a.createDate	 -- 创建日期
from (select  legalStatus,seqNum,createDate
from dw_nd.ods_extdata_bwfintech_legal
 where date_format(createDate,'%Y%m%d') <= '${v_sdate}') a 
left join dw_base.dwd_sf_to_msg_log c 
 on a.seqNum=c.seq_num ; 
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('百维金科-司法失信数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
