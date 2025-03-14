-- ---------------------------------------
-- 开发人   : 
-- 开发时间 ：
-- 目标表   :dwd_sf_bwjk_duotou_loanapp
-- 源表     ：dw_nd.ods_extdata_bwfintech_duotou_loanapp 多头借贷--贷款申请详情
    --        dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ：  20220117统一修改
--              20220516 日志变量注释  xgm   
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_bwjk_duotou_loanapp';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;

-- 多头借贷--贷款申请详情
truncate table dw_base.dwd_sf_bwjk_duotou_loanapp ;
insert into dw_base.dwd_sf_bwjk_duotou_loanapp
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
plat_form_no , -- 申请机构编号 
aplit_result , -- 申请结果预留字段，暂无值(yes:成 功 no:失败) 
aplit_dt , -- 申请时间 
plat_form_type , -- 机构类型0:全部 1:银行 2:非银行 
aplit_org , -- 申请金额单位(W) 
seq_num	, -- 查询批次号
query_dt	 -- 查询日期
)
  
select  
   c.cust_id	, -- 客户号
   c.cust_name	, -- 客户姓名
   a.platform_code	, -- 申请机构编号
   a.application_result , -- 申请结果预留字段，暂无值(yes:成 功 no:失败) 
   a.application_time , -- 申请时间 
   a.platform , -- 机构类型0:全部 1:银行 2:非银行 
   a.application_money 	, -- 申请金额单位(W)
   a.seqNum	, -- 查询批次号
   a.createDate	 -- 创建日期
from 
(select platform_code,application_result,application_time
,platform,application_money,seqNum,createDate
from dw_nd.ods_extdata_bwfintech_duotou_loanapp
where date_format(createDate,'%Y%m%d') <= '${v_sdate}') a 
left join dw_base.dwd_sf_to_msg_log  c  on a.seqNum=c.seq_num ; 
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('多头借贷-贷款申请详情数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
