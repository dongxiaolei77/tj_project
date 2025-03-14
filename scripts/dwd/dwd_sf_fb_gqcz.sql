
-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_sf_fb_gqcz 风报-股权出质表
-- 源表     ：dw_nd.ods_extdata_fb_gqcz 股权出质表、dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ： 20220117:统一变动 
--             20220516 日志变量注释  xgm   
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_fb_gqcz';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;

-- 股权出质
-- drop index idx_ods_extdata_fb_gqcz_seq on   dw_nd.ods_extdata_fb_gqcz ;
-- create  index idx_ods_extdata_fb_gqcz_seq on   dw_nd.ods_extdata_fb_gqcz(seqnum) ;
truncate table dw_base.dwd_sf_fb_gqcz ;
insert into dw_base.dwd_sf_fb_gqcz
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
pledger	, -- 出质人
quality_target	, -- 出质标的
equity_pledged_amt	, -- 出质股权数额
reles_dt	, -- 发布时间
remark	, -- 备注
cancel_reason	, -- 注销原因
cancel_dt	, -- 注销日期
statu	, -- 状态
reg_dt	, -- 登记日期
reg_type	, -- 登记种类
reg_no	, -- 登记编号
pledgee	, -- 质权人
seq_num	, -- 生成查询批次号
query_dt	 -- 查询日期
)
  
select  
   b.cust_id	, -- 客户号
   b.cust_name	, -- 客户姓名
   a.pledger	, -- 出质人
   a.quality_target	, -- 出质标的
   a.equity_pledged_amount	, -- 出质股权数额
   a.release_time	, -- 发布时间
   a.remark	, -- 备注
   a.cancellation_reason	, -- 注销原因
   a.cancellation_date	, -- 注销日期
   a.status	, -- 状态
   a.registration_date	, -- 登记日期
   a.registration_type	, -- 登记种类
   a.registration_no	, -- 登记编号
   a.pledgee	, -- 质权人
   a.seqnum	, -- 生成查询批次号
   a.createdate	 -- 当前日期
from (select pledger	, -- 出质人
			quality_target	, -- 出质标的
			equity_pledged_amount	, -- 出质股权数额
			release_time	, -- 发布时间
			remark	, -- 备注
			cancellation_reason	, -- 注销原因
			cancellation_date	, -- 注销日期
			status	, -- 状态
			registration_date	, -- 登记日期
			registration_type	, -- 登记种类
			registration_no	, -- 登记编号
			pledgee	, -- 质权人
			seqnum	, -- 生成查询批次号
			createdate	 -- 当前日期 
	from dw_nd.ods_extdata_fb_gqcz a 
	where  date_format(createdate,'%Y%m%d') <= '${v_sdate}'
) a
left join dw_base.dwd_sf_to_msg_log  b  on a.seqNum=b.seq_num ;
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('风报-股权出质数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
