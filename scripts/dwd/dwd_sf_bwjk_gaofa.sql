-- ---------------------------------------
-- 开发人   : 
-- 开发时间 ：
-- 目标表   ： dwd_sf_bwjk_gaofa
-- 源表     ：dw_nd.ods_extdata_bwfintech_gaofa 高法失信查询 
           -- dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ：  20220117统一修改
--              20220516 日志变量注释  xgm 
-- ---------------------------------------

-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_bwjk_gaofa';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1; 


-- 高法失信查询 

-- drop index idx_ods_extdata_bwfintech_gaofa_seq on   dw_nd.ods_extdata_bwfintech_gaofa ;
-- create  index idx_ods_extdata_bwfintech_gaofa_seq on   dw_nd.ods_extdata_bwfintech_gaofa(seqnum) ;
truncate table dw_base.dwd_sf_bwjk_gaofa ;
insert into dw_base.dwd_sf_bwjk_gaofa
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
exe_court	, -- 执行法院
provc_name	, -- 省份
case_no	, -- 案件编号
exe_statu	, -- 执行状态
case_type	, -- 案件分类
filing_dt	, -- 立案日期例：2017年01月03日
case_detail	, -- 案件详情
seq_num	, -- 查询批次号
query_dt	 -- 创建日期
)
  
select  
   c.cust_id	, -- 客户号
   c.cust_name	, -- 客户姓名
   a.exe_court	, -- 执行法院
   a.province	, -- 省份
   a.case_no	, -- 案件编号
   a.exe_status	, -- 执行状态
   a.case_type	, -- 案件分类
   a.filing_time	, -- 立案日期例：2017年01月03日
   a.case_detail	, -- 案件详情
   a.seqNum	, -- 查询批次号
   a.createDate	 -- 创建日期
from  (select exe_court,province,case_no,exe_status,case_type,
filing_time,case_detail,seqNum,createDate
 from dw_nd.ods_extdata_bwfintech_gaofa 
where date_format(createDate,'%Y%m%d') <= '${v_sdate}') a 
left join   dw_base.dwd_sf_to_msg_log c 
 on a.seqNum=c.seq_num  ;

-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('百维金科-高法失信查询数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
