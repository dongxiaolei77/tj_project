-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_sf_fb_sshy 风报-所属行业表
-- 源表     ：dw_nd.ods_extdata_fb_sshy 所属行业表、dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ： 20220117:统一变动  
--             20220516 日志变量注释  xgm
--             20241201 脚本的统一变更，MySQL5.0转MySQL8.0 zhangfl 
-- ---------------------------------------
-- 所属行业
truncate table dw_base.dwd_sf_fb_sshy ;
insert into dw_base.dwd_sf_fb_sshy
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
industry_categ	, -- 行业大类
industry_categ_code	, -- 行业大类编码
industry_categ_ory	, -- 行业门类
industry_categ_ory_code	, -- 行业门类编码
seq_num	, -- 生成查询批次号
query_dt	 -- 当前日期
)
  
select  
   b.cust_id	, -- 客户号
   b.cust_name	, -- 客户姓名
   a.industry_categories	, -- 行业大类
   a.industry_categories_code	, -- 行业大类编码
   a.industry_category	, -- 行业门类
   a.industry_category_code	, -- 行业门类编码
   a.seqnum	, -- 生成查询批次号
   a.createdate	 -- 当前日期
from (select industry_categories	, -- 行业大类
			industry_categories_code	, -- 行业大类编码
			industry_category	, -- 行业门类
			industry_category_code	, -- 行业门类编码
			seqnum	, -- 生成查询批次号
			createdate	 -- 当前日期 
	from dw_nd.ods_extdata_fb_sshy a 
	where  date_format(createdate,'%Y%m%d') <= '${v_sdate}'
) a
left join dw_base.dwd_sf_to_msg_log  b  on a.seqNum=b.seq_num ;
commit; 