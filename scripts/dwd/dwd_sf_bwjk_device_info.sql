-- ---------------------------------------
-- 开发人   : 
-- 开发时间 ：
-- 目标表   ：dwd_sf_bwjk_device_info
-- 源表     ：dw_nd.ods_extdata_bwfintech_custommadedevice_info 定制设备查询 
        --    dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ： 20220117统一修改
--             20220516 日志变量注释  xgm   
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_bwjk_device_info';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;

-- drop index idx_ods_extdata_bwfintech_custommadedevice_info_seq on   dw_nd.ods_extdata_bwfintech_custommadedevice_info ;
-- create  index idx_ods_extdata_bwfintech_custommadedevice_info_seq on   dw_nd.ods_extdata_bwfintech_custommadedevice_info(seqnum) ;
-- 定制设备查询
truncate table dw_base.dwd_sf_bwjk_device_info ;
insert into dw_base.dwd_sf_bwjk_device_info
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
risk_result_name	, -- 处置建议通过、拒绝、待评估
risk_result_code	, -- 处置建议英文PASS、REJECT、PEND
risk_score	, -- 风险分数风险分，0~100，分数越高，风险越大
detect_dt	, -- 侦测时间
treat_result	, -- 是否查得1查得2未查得 3 其他原因未查得
seq_num	, -- 查询批次号
query_dt	 -- 查询日期
)
  
select  
   c.cust_id	, -- 客户号
   c.cust_name	, -- 客户姓名
   a.riskResultName	, -- 处置建议通过、拒绝、待评估
   a.riskResultCode	, -- 处置建议英文PASS、REJECT、PEND
   a.riskScore	, -- 风险分数风险分，0~100，分数越高，风险越大
   a.detectTime	, -- 侦测时间
   a.treatResult	, -- 是否查得1查得2未查得 3 其他原因未查得
   a.seqNum	, -- 查询批次号
   a.createDate	 -- 创建日期
from  (select  riskResultName,riskResultCode,riskScore,detectTime
,treatResult,seqNum,createDate
from dw_nd.ods_extdata_bwfintech_custommadedevice_info 
where date_format(createDate,'%Y%m%d') <= '${v_sdate}') a 
left join  dw_base.dwd_sf_to_msg_log c 
 on a.seqNum=c.seq_num ; 
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('百维金科-定制设备查询数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
