-- ---------------------------------------
-- 开发人   : 
-- 开发时间 ：
-- 目标表   ：dwd_sf_bwjk_risk_list
-- 源表     ：dw_nd.ods_extdata_bwfintech_risk_list 金融逾期查询 
       --     dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ：  20220117统一修改
--              20220516 日志变量注释  xgm 
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_bwjk_risk_list';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;



-- 金融逾期
-- drop index idx_ods_extdata_bwfintech_risk_list_seq on   dw_nd.ods_extdata_bwfintech_risk_list ;
-- create  index idx_ods_extdata_bwfintech_risk_list_seq on   dw_nd.ods_extdata_bwfintech_risk_list(seqnum) ;
truncate table dw_base.dwd_sf_bwjk_risk_list ;
insert into dw_base.dwd_sf_bwjk_risk_list
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
first_happen_dt	, -- 逾期最早出现时间格式:yyyy-MM-dd
last_happen_dt	, -- 逾期最近出现时间格式:yyyy-MM-dd
accum_cn	, -- 逾期累计出现次数
present_overdue_amt	, -- 当前逾期金额金额区间，例1000~2000
present_overdue_dur	, -- 当前逾期时长M0：1~15天 M1：16~30 天 M2：31~60 天 M3：61~90天 M4：91~120天 M5：121~150天 M6：151~180天 M6+：180天以上
his_overdue_amt	, -- 历史最大逾期金额金额区间，例1000~2000
his_overdue_dur	, -- 历史最大逾期时长M0：1~15天 M1：16~30 天 M2：31~60 天 M3：61~90天 M4：91~120天 M5：121~150天 M6：151~180天 M6+：180天以上
seq_num	, -- 查询批次号
query_dt	 -- 创建日期
)
  
select  
   c.cust_id	, -- 客户号
   c.cust_name	, -- 客户姓名
   a.first_happen_time	, -- 逾期最早出现时间格式:yyyy-MM-dd
   a.recently_happen_time	, -- 逾期最近出现时间格式:yyyy-MM-dd
   a.accumulative_count	, -- 逾期累计出现次数
   a.present_overdue_amount	, -- 当前逾期金额金额区间，例1000~2000
   a.present_overdue_duration	, -- 当前逾期时长M0：1~15天 M1：16~30 天 M2：31~60 天 M3：61~90天 M4：91~120天 M5：121~150天 M6：151~180天 M6+：180天以上
   a.history_overdue_amount	, -- 历史最大逾期金额金额区间，例1000~2000
   a.history_overdue_duration	, -- 历史最大逾期时长M0：1~15天 M1：16~30 天 M2：31~60 天 M3：61~90天 M4：91~120天 M5：121~150天 M6：151~180天 M6+：180天以上
   a.seqNum	, -- 查询批次号
   a.createDate	 -- 创建时间
from  (select first_happen_time,recently_happen_time,accumulative_count
,present_overdue_amount,present_overdue_duration,history_overdue_amount
,history_overdue_duration,seqNum,createDate
from dw_nd.ods_extdata_bwfintech_risk_list 
where date_format(createDate,'%Y%m%d') <= '${v_sdate}') a 
left join  dw_base.dwd_sf_to_msg_log c 
 on a.seqNum=c.seq_num  ;
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('百维金科-金融逾期查询数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
