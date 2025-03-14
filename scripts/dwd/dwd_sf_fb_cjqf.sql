-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_sf_fb_cjqf 风报-催缴欠税表 
-- 源表     ：dw_nd.ods_extdata_fb_cjqf 催缴欠税表、dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ：  20220117:统一变动  
--              20220516 日志变量注释  xgm   
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_fb_cjqf';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;

-- 催缴欠税表
-- drop index idx_ods_extdata_fb_cjqf_seq on   dw_nd.ods_extdata_fb_cjqf ;
-- create  index idx_ods_extdata_fb_cjqf_seq on   dw_nd.ods_extdata_fb_cjqf(seqnum) ;

truncate table dw_base.dwd_sf_fb_cjqf ;
insert into dw_base.dwd_sf_fb_cjqf
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
reles_dt	, -- 发布时间
name	, -- 名称
legal_name	, -- 法定代表人姓名
tax_org	, -- 税务机关
tax_type	, -- 税种
addr	, -- 经营地址
ident_no	, -- 识别号
amt	, -- 金额
sup_tax_org	, -- 高级税务机关
seq_num	, -- 生成查询批次号
query_dt	 -- 查询日期
)
  
select  
   b.cust_id	, -- 客户号
   b.cust_name	, -- 客户姓名
   a.release_time	, -- 发布时间
   a.name	, -- 名称
   a.boss_name	, -- 法定代表人姓名
   a.tax_authority	, -- 税务机关
   a.tax_type	, -- 税种
   a.address	, -- 经营地址
   a.identify_no	, -- 识别号
   a.amount	, -- 金额
   a.senior_tax_authority	, -- 高级税务机关
   a.seqnum	, -- 生成查询批次号
   a.createdate	 -- 当前日期

from (select release_time	, -- 发布时间
			 name	, -- 名称
			 boss_name	, -- 法定代表人姓名
			 tax_authority	, -- 税务机关
			 tax_type	, -- 税种
			 address	, -- 经营地址
			 identify_no	, -- 识别号
			 amount	, -- 金额
			 senior_tax_authority	, -- 高级税务机关
			 seqnum	, -- 生成查询批次号
			 createdate	 -- 当前日期 
		from dw_nd.ods_extdata_fb_cjqf a 	
			where  date_format(createdate,'%Y%m%d') <= '${v_sdate}'
		) a
	
left join dw_base.dwd_sf_to_msg_log b
 on a.seqNum=b.seq_num ;

-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('裁判文书数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;

