-- ---------------------------------------
-- 开发人   : 
-- 开发时间 ：
-- 目标表   ：dwd_sf_bwjk_blacklist
-- 源表     ：dw_nd.ods_extdata_bwfintech_blacklist 百维金科-黑名单查询
         --   dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ： 20220117统一修改
--             20220516 日志变量注释  xgm   
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_bwjk_blacklist';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1; 


truncate table dw_base.dwd_sf_bwjk_blacklist ;
insert into dw_base.dwd_sf_bwjk_blacklist
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
risk_code	, -- 风险码
risk_statu	, -- 命中状态 0 未中 1 中
risk_desc	, -- 描述
seq_num	, -- 查询批次号
query_dt	 -- 创建日期
)
  
select  
   c.cust_id	, -- 客户号
   c.cust_name	, -- 客户姓名
   a.blackCode	, -- 风险码
   a.riskStatus	, -- 命中状态 0 未中 1 中
   a.riskMsg	, -- 描述
   a.seqNum	, -- 查询批次号
   a.createDate	 -- 创建日期
from  (select blackCode,riskStatus,riskMsg,seqNum,createDate
 from dw_nd.ods_extdata_bwfintech_blacklist 
where date_format(createDate,'%Y%m%d') <= '${v_sdate}') a 
left join    dw_base.dwd_sf_to_msg_log  c  on a.seqNum=c.seq_num ; 
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('百维金科-黑名单查询数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
