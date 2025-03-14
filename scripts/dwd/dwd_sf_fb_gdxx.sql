-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_sf_fb_gdxx 风报-股东信息表
-- 源表     ：dw_nd.ods_extdata_fb_gdxx 股东信息表、dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ： 20220117:统一变动   
--             20220516 日志变量注释  xgm 
--             20241201 脚本的统一变更，MySQL5.0转MySQL8.0 zhangfl   
-- ---------------------------------------
-- 股东信息
truncate table dw_base.dwd_sf_fb_gdxx ;
insert into dw_base.dwd_sf_fb_gdxx
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
paid_detail	, -- 实缴明细
paid_amt	, -- 实缴额
dirsh	, -- 持股比
holder	, -- 股东
holder_type	, -- 股东类型
paid_detail_2	, -- 认缴明细
paid_amt_2	, -- 认缴额
liability_form	, -- 责任形式
seq_num	, -- 生成查询批次号
query_dt	 -- 查询日期
)
  
select  
   b.cust_id	, -- 客户号
   b.cust_name	, -- 客户姓名
   a.paid_detail	, -- 实缴明细
   a.paid_amount	, -- 实缴额
   a.dirsh	, -- 持股比
   a.stockholder	, -- 股东
   a.stockholder_type	, -- 股东类型
   a.paid_detail_2	, -- 认缴明细
   a.paid_amount_2	, -- 认缴额
   a.liability_form	, -- 责任形式
   a.seqnum	, -- 生成查询批次号
   a.createdate	 -- 当前日期
from (select paid_detail	, -- 实缴明细
			paid_amount	, -- 实缴额
			dirsh	, -- 持股比
			stockholder	, -- 股东
			stockholder_type	, -- 股东类型
			paid_detail_2	, -- 认缴明细
			paid_amount_2	, -- 认缴额
			liability_form	, -- 责任形式
			seqnum	, -- 生成查询批次号
			createdate	 -- 当前日期 
		from dw_nd.ods_extdata_fb_gdxx a 
	where  date_format(createdate,'%Y%m%d') <= '${v_sdate}'
) a
left join dw_base.dwd_sf_to_msg_log  b  on a.seqNum=b.seq_num ;
commit; 
