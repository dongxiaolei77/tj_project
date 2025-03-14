-- ---------------------------------------
-- 开发人   : 
-- 开发时间 ：
-- 目标表   ：dwd_sf_bwjk_device_phonetoimei
-- 源表     ：dw_nd.ods_extdata_bwfintech_custommadedevice_phonetoimei 定制设备查询-手机号转设备号结果通知 
        --    dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ：  20220117统一修改
--              20220516 日志变量注释  xgm   
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_bwjk_device_phonetoimei';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;


-- 定制设备查询-手机号转设备号结果通知
truncate table dw_base.dwd_sf_bwjk_device_phonetoimei ;
insert into dw_base.dwd_sf_bwjk_device_phonetoimei
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
sub_report_no	, -- 子报告ID
sub_report_cost_no	, -- 收费子报告ID
sub_report_stt	, -- 子报告查询状态,1：查得，2：未查得，3：其他原因未查得
treat_error_code	, -- treatResult=3时的错误代码,详见数据字典,treatResult!=3时,该属性不存在
error_msg	, -- treatResult=3时的错误描述信息,treatResult!=3时,该属性的值为空
imei	, -- 是否查得手机号码设备号，固定为：查得，未查得时没有该节点
seq_sum	, -- 查询批次号
query_dt	 -- 查询日期
)
  
select  
   c.cust_id	, -- 客户号
   c.cust_name	, -- 客户姓名
   a.subReportType	, -- 子报告ID
   a.subReportTypeCost	, -- 收费子报告ID
   a.treatResult	, -- 子报告查询状态,1：查得，2：未查得，3：其他原因未查得
   a.treatErrorCode	, -- treatResult=3时的错误代码,详见数据字典,treatResult!=3时,该属性不存在
   a.errorMessage	, -- treatResult=3时的错误描述信息,treatResult!=3时,该属性的值为空
   a.imei	, -- 是否查得手机号码设备号，固定为：查得，未查得时没有该节点
   a.seqNum	, -- 查询批次号
   a.createDate	 -- 创建日期
from  (select subReportType,subReportTypeCost,treatResult,treatErrorCode
,errorMessage,imei,seqNum,createDate
from dw_nd.ods_extdata_bwfintech_custommadedevice_phonetoimei 
where date_format(createDate,'%Y%m%d') <= '${v_sdate}') a 
left join dw_base.dwd_sf_to_msg_log   c 
 on a.seqNum=c.seq_num  ;
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('百维金科-定制设备查询-手机号转设备号结果通知数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
