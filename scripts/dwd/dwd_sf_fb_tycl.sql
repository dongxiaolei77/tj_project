-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220120
-- 目标表   ：dw_base.dwd_sf_fb_sxbzxr 风报-失信被执行人表
-- 源表     ：dw_nd.ods_extdata_fb_sxbzxr 失信被执行人、dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ： 20220120:统一变动  
--             20220516 日志变量注释  xgm  
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_fb_tycl';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1; 

-- 在这里需要考虑优化的问题 
-- 20210120编写 xgm
-- drop index idx_ods_de_t_param_re_fb_tycl_seq on   dw_nd.ods_de_t_param_re_fb_tycl ;
-- create  index idx_ods_de_t_param_re_fb_tycl_seq on   dw_nd.ods_de_t_param_re_fb_tycl(seqnum) ;


-- 风报通用策略 
truncate table dw_base.dwd_sf_fb_tycl ;
insert into dw_base.dwd_sf_fb_tycl
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
basic	, -- 基础信息
gdxxList	, -- 工商资料-股东信息
gsbgList	, -- 工商变更
xzcfList	, -- 行政处罚
dcdyList	, -- 动产抵押
gqczList	, -- 股权出质
sfxzList	, -- 司法协助
jyycList	, -- 经营异常
dbxxList	, -- 担保信息
ssfzchList	, -- 税务非正常户
zdsswfList	, -- 重大税收违法
cjqsList	, -- 催缴/欠税
ktggList	, -- 开庭公告
cpwsList	, -- 裁判文书
bzxrList	, -- 被执行人
sxbzxrList	, -- 失信被执行人
ssggList	, -- 涉诉公告
splcList	, -- 审判流程
seq_num	, -- 生成查询批次号
query_dt	  -- 查询日期
)
select  
b.cust_id, -- 客户号
b.cust_name,  
a.basic	, -- 基础信息
a.gdxxList	, -- 工商资料-股东信息
a.gsbgList	, -- 工商变更
a.xzcfList	, -- 行政处罚
a.dcdyList	, -- 动产抵押
a.gqczList	, -- 股权出质
a.sfxzList	, -- 司法协助
a.jyycList	, -- 经营异常
a.dbxxList	, -- 担保信息
a.ssfzchList	, -- 税务非正常户
a.zdsswfList	, -- 重大税收违法
a.cjqsList	, -- 催缴/欠税
a.ktggList	, -- 开庭公告
a.cpwsList	, -- 裁判文书
a.bzxrList	, -- 被执行人
a.sxbzxrList	, -- 失信被执行人
a.ssggList	, -- 涉诉公告
a.splcList	, -- 审判流程
a.seqnum	, -- 生成查询批次号
a.createdate	  -- 当前日期
from   (select basic	, -- 基础信息
		gdxxList	, -- 工商资料-股东信息
		gsbgList	, -- 工商变更
		xzcfList	, -- 行政处罚
		dcdyList	, -- 动产抵押
		gqczList	, -- 股权出质
		sfxzList	, -- 司法协助
		jyycList	, -- 经营异常
		dbxxList	, -- 担保信息
		ssfzchList	, -- 税务非正常户
		zdsswfList	, -- 重大税收违法
		cjqsList	, -- 催缴/欠税
		ktggList	, -- 开庭公告
		cpwsList	, -- 裁判文书
		bzxrList	, -- 被执行人
		sxbzxrList	, -- 失信被执行人
		ssggList	, -- 涉诉公告
		splcList	, -- 审判流程
		seqnum	, -- 生成查询批次号
		createdate	  -- 当前日期 
	from dw_nd.ods_de_t_param_re_fb_tycl a 
	where  date_format(createdate,'%Y%m%d') <= '${v_sdate}'
) a 
left join dw_base.dwd_sf_to_msg_log  b  on a.seqNum=b.seq_num ;
-- select row_count() into @rowcnt;
commit;
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('风报通用策略加工完成,共插入',@rowcnt,'条'),@time,now());commit;
