-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_sf_fb_cpws 风报-裁判文书表 
-- 源表     ：dw_nd.ods_extdata_fb_cpws 裁判文书表、dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ：20220117:统一变动   
--            20220516 日志变量注释  xgm  
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_fb_cpws';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1; 

-- 裁判文书
truncate table dw_base.dwd_sf_fb_cpws ;
insert into dw_base.dwd_sf_fb_cpws 
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
url	, -- url
disclos_reason	, -- 不公开理由
judg_tal_amt	, -- 判决总金额
judg_dt	, -- 判决时间
judg_amt	, -- 判决金额
reles_dt	, -- 发布时间
party	, -- 当事人
doc_type	, -- 文书类型
title	, -- 标题
case_type	, -- 案件类型
case_no	, -- 案号
case_reason	, -- 案由
paragraph	, -- 段落
judge	, -- 法官
court	, -- 法院
legal_fee	, -- 诉讼费
seq_num	, -- 生成查询批次号
query_dt	 -- 查询日期
) 

select  
   b.cust_id	, -- 客户号
   b.cust_name	, -- 客户姓名
   a.url	, -- url
   a.disclosing_reason	, -- 不公开理由
   a.total_amount_judgment	, -- 判决总金额
   a.time_judgment	, -- 判决时间
   a.amount_judgment	, -- 判决金额
   a.release_time	, -- 发布时间
   a.party	, -- 当事人
   a.document_type	, -- 文书类型
   a.title	, -- 标题
   a.case_type	, -- 案件类型
   a.case_no	, -- 案号
   a.case_reason	, -- 案由
   a.paragraph	, -- 段落
   a.judge	, -- 法官
   a.court	, -- 法院
   a.legal_fee	, -- 诉讼费
   a.seqnum	, -- 生成查询批次号
   a.createdate	 -- 当前日期
from (select url	, -- url
			 disclosing_reason	, -- 不公开理由
			 total_amount_judgment	, -- 判决总金额
			 time_judgment	, -- 判决时间
			 amount_judgment	, -- 判决金额
			 release_time	, -- 发布时间
			 party	, -- 当事人
			 document_type	, -- 文书类型
			 title	, -- 标题
			 case_type	, -- 案件类型
			 case_no	, -- 案号
			 case_reason	, -- 案由
			 paragraph	, -- 段落
			 judge	, -- 法官
			 court	, -- 法院
			 legal_fee	, -- 诉讼费
			 seqnum	, -- 生成查询批次号
			 createdate	 -- 当前日期 
		from dw_nd.ods_extdata_fb_cpws a
			where  date_format(createdate,'%Y%m%d') <= '${v_sdate}'

) a

-- dw_nd.ods_extdata_fb_cpws a 
left join dw_base.dwd_sf_to_msg_log  b  on a.seqNum=b.seq_num ;
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('裁判文书数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
