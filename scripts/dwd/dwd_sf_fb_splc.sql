
-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_sf_fb_splc 风报-审判流程表
-- 源表     ：dw_nd.ods_extdata_fb_splc 审判流程表、dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ： 20220117:统一变动  
--             20220516 日志变量注释  xgm  
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_fb_splc';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;

-- 审判流程
-- drop index idx_ods_extdata_fb_splc_seq on   dw_nd.ods_extdata_fb_splc ;
-- create  index idx_ods_extdata_fb_splc_seq on   dw_nd.ods_extdata_fb_splc(seqnum) ;
truncate table dw_base.dwd_sf_fb_splc ;
insert into dw_base.dwd_sf_fb_splc
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
main_judge	, -- 主审法官
notice_people	, -- 公告人
notice_type	, -- 公告类型
reles_dt	, -- 发布时间
panel_member	, -- 合议庭成员
zihao	, -- 字号
judge_proc	, -- 审判程序
judge_led	, -- 审判长
judge_dt	, -- 审限日期
filing_dt	, -- 归档日期
party	, -- 当事人
judge_org	, -- 承办部门
bdj_amt	, -- 标的金额
case_type	, -- 案件类别
case_stt	, -- 案件进度
case_no	, -- 案号
case_reason	, -- 案由
case_dt	, -- 立案日期
case_time	, -- 立案时间
end_case_way	, -- 结案方式
end_case_dt	, -- 结案日期
seq_num	, -- 生成查询批次号
query_dt	 -- 查询日期
)
  
select  
   b.cust_id	, -- 客户号
   b.cust_name	, -- 客户姓名
   a.main_judge	, -- 主审法官
   a.notice_people	, -- 公告人
   a.notice_type	, -- 公告类型
   a.release_time	, -- 发布时间
   a.collegial_panel_member	, -- 合议庭成员
   a.zihao	, -- 字号
   a.judicial_procedure	, -- 审判程序
   a.presiding_judge	, -- 审判长
   a.judge_date	, -- 审限日期
   a.filing_date	, -- 归档日期
   a.party	, -- 当事人
   a.cbbm	, -- 承办部门
   a.bdje	, -- 标的金额
   a.case_type	, -- 案件类别
   a.case_status	, -- 案件进度
   a.case_no	, -- 案号
   a.case_reason	, -- 案由
   a.case_date	, -- 立案日期
   a.case_time	, -- 立案时间
   a.end_case_way	, -- 结案方式
   a.end_case_date	, -- 结案日期
   a.seqnum	, -- 生成查询批次号
   a.createdate	 -- 当前日期
from (select main_judge	, -- 主审法官
			notice_people	, -- 公告人
			notice_type	, -- 公告类型
			release_time	, -- 发布时间
			collegial_panel_member	, -- 合议庭成员
			zihao	, -- 字号
			judicial_procedure	, -- 审判程序
			presiding_judge	, -- 审判长
			judge_date	, -- 审限日期
			filing_date	, -- 归档日期
			party	, -- 当事人
			cbbm	, -- 承办部门
			bdje	, -- 标的金额
			case_type	, -- 案件类别
			case_status	, -- 案件进度
			case_no	, -- 案号
			case_reason	, -- 案由
			case_date	, -- 立案日期
			case_time	, -- 立案时间
			end_case_way	, -- 结案方式
			end_case_date	, -- 结案日期
			seqnum	, -- 生成查询批次号
			createdate	 -- 当前日期 
	from dw_nd.ods_extdata_fb_splc a
	where  date_format(createdate,'%Y%m%d') <= '${v_sdate}'
) a
left join dw_base.dwd_sf_to_msg_log  b  on a.seqNum=b.seq_num ;
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('风报-审判流程数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
