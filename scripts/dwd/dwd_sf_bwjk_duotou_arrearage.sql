-- ---------------------------------------
-- 开发人   : 
-- 开发时间 ：
-- 目标表   :dwd_sf_bwjk_duotou_arrearage
-- 源表     ：：dw_nd.ods_extdata_bwfintech_duotou_arrearage 多头借贷-欠款信息
    --        dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ：  20220117统一修改
--              20220516 日志变量注释  xgm   
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_bwjk_duotou_arrearage';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;

-- 多头借贷-欠款信息
truncate table dw_base.dwd_sf_bwjk_duotou_arrearage ;
insert into dw_base.dwd_sf_bwjk_duotou_arrearage
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
plat_form_type	, -- 机构类型0:全部 1:银行 2:非银 行
arrearage_org	, -- 欠款金额单位(W)
seq_num	, -- 查询批次号
query_dt	 -- 查询日期
)
  
select  
   c.cust_id	, -- 客户号
   c.cust_name	, -- 客户姓名
   a.platform	, -- 机构类型0:全部 1:银行 2:非银 行
   a.arrearage_money	, -- 欠款金额单位(W)
   a.seqNum	, -- 查询批次号
   a.createDate	 -- 创建日期
from  (select platform,arrearage_money,seqNum,createDate
from dw_nd.ods_extdata_bwfintech_duotou_arrearage
where date_format(createDate,'%Y%m%d') <= '${v_sdate}') a 
left join dw_base.dwd_sf_to_msg_log  c  on a.seqNum=c.seq_num ; 
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('多头借贷-欠款信息数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
