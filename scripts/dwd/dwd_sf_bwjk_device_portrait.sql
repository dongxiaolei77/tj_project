-- ---------------------------------------
-- 开发人   : 
-- 开发时间 ：
-- 目标表   ：dwd_sf_bwjk_device_portrait
-- 源表     ：dw_nd.ods_extdata_bwfintech_custommadedevice_portrait 定制设备查询-行为特征信息
         --   dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ：  20220117统一修改
--             20220516 日志变量注释  xgm   
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_bwjk_device_portrait';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;

-- 定制设备查询-行为特征信息
truncate table dw_base.dwd_sf_bwjk_device_portrait ;
insert into dw_base.dwd_sf_bwjk_device_portrait
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
por_no	, -- 风险点特征标签编号，如：POR_1008881
por_name	, -- 风险点特征标签名称，如：近3月，影音视听-音乐类APP天使用次数
por_class_no	, -- 风险点特征标签分类编号，如：app
por_class_name	, -- 风险点特征标签分类名称，如：APP使用核验
value	, -- 风险点特征标签的值，如：35
abnormal_stt	, -- 风险点特征标签的状态：0-正常、1-异常、2-未知
seq_num	, -- 查询批次号
query_dt	 -- 查询日期
)
  
select  
   c.cust_id	, -- 客户号
   c.cust_name	, -- 客户姓名
   a.porId	, -- 风险点特征标签编号，如：POR_1008881
   a.porName	, -- 风险点特征标签名称，如：近3月，影音视听-音乐类APP天使用次数
   a.porClassCode	, -- 风险点特征标签分类编号，如：app
   a.porClassName	, -- 风险点特征标签分类名称，如：APP使用核验
   a.value	, -- 风险点特征标签的值，如：35
   a.abnormalState	, -- 风险点特征标签的状态：0-正常、1-异常、2-未知
   a.seqNum	, -- 查询批次号
   a.createDate	 -- 创建日期
from  (select porId,porName,porClassCode,porClassName,value
,abnormalState,seqNum,createDate
from dw_nd.ods_extdata_bwfintech_custommadedevice_portrait
 where date_format(createDate,'%Y%m%d') <= '${v_sdate}') a 
left join   dw_base.dwd_sf_to_msg_log  c 
 on a.seqNum=c.seq_num ; 
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('百维金科-行为特征信息数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
