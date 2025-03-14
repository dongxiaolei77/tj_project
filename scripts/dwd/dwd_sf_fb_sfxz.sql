-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_sf_fb_sfxz 风报-司法协助表
-- 源表     ：dw_nd.ods_extdata_fb_sfxz 司法协助表、dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ： 20220117c:统一变动  
--             20220516 日志变量注释  xgm  
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_fb_sfxz';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;


-- 司法协助
-- drop index idx_ods_extdata_fb_sfxz_seq on   dw_nd.ods_extdata_fb_sfxz ;
-- create  index idx_ods_extdata_fb_sfxz_seq on   dw_nd.ods_extdata_fb_sfxz(seqnum) ;
truncate table dw_base.dwd_sf_fb_sfxz ;
insert into dw_base.dwd_sf_fb_sfxz
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
public_dt	, -- 公示日期
freeze_from	, -- 冻结期限自
freeze_to	, -- 冻结期限至
assignee	, -- 受让人
exe_case	, -- 执行事项
exe_court	, -- 执行法院
exe_no	, -- 执行裁定书文号
exe_notice_no	, -- 执行通知书文号
re_freeze_from	, -- 续行冻结期限自
re_freeze_to	, -- 续行冻结期限至
comp_name	, -- 股权所在企业名称
stock_cn	, -- 股权数额
exed_name	, -- 被执行人
exed_cert_type	, -- 被执行人证件种类
upfreeze_expiry	, -- 解除冻结期限
seq_num	, -- 生成查询批次号
query_dt	 -- 当前日期
)
  
select  
   b.cust_id	, -- 客户号
   b.cust_name	, -- 客户姓名
   a.public_date	, -- 公示日期
   a.freeze_time_from	, -- 冻结期限自
   a.freeze_time_to	, -- 冻结期限至
   a.assignee	, -- 受让人
   a.execute_case	, -- 执行事项
   a.execute_court	, -- 执行法院
   a.execution_order_no	, -- 执行裁定书文号
   a.execution_notice_number	, -- 执行通知书文号
   a.renew_freeze_from	, -- 续行冻结期限自
   a.renew_freeze_to	, -- 续行冻结期限至
   a.company_name	, -- 股权所在企业名称
   a.stock_amount	, -- 股权数额
   a.beizhixing	, -- 被执行人
   a.beizhixing_id	, -- 被执行人证件种类
   a.freeze_time_limit	, -- 解除冻结期限
   a.seqnum	, -- 生成查询批次号
   a.createdate	 -- 当前日期
from (select  public_date	, -- 公示日期
			freeze_time_from	, -- 冻结期限自
			freeze_time_to	, -- 冻结期限至
			assignee	, -- 受让人
			execute_case	, -- 执行事项
			execute_court	, -- 执行法院
			execution_order_no	, -- 执行裁定书文号
			execution_notice_number	, -- 执行通知书文号
			renew_freeze_from	, -- 续行冻结期限自
			renew_freeze_to	, -- 续行冻结期限至
			company_name	, -- 股权所在企业名称
			stock_amount	, -- 股权数额
			beizhixing	, -- 被执行人
			beizhixing_id	, -- 被执行人证件种类
			freeze_time_limit	, -- 解除冻结期限
			seqnum	, -- 生成查询批次号
			createdate	 -- 当前日期 
	from dw_nd.ods_extdata_fb_sfxz a 
	where  date_format(createdate,'%Y%m%d') <= '${v_sdate}'
) a
left join dw_base.dwd_sf_to_msg_log  b  on a.seqNum=b.seq_num ;
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('风报-司法协助数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
