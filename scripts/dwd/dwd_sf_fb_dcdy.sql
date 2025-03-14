-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_sf_fb_dcdy 风报-动产抵押表
-- 源表     ：dw_nd.ods_extdata_fb_dcdy 动产抵押表、dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ： 20220117:统一变动
--             20220516 日志变量注释  xgm     
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_fb_dcdy';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;


-- 动产抵押
-- drop index idx_ods_extdata_fb_dcdy_seq on   dw_nd.ods_extdata_fb_dcdy ;
-- create  index idx_ods_extdata_fb_dcdy_seq on   dw_nd.ods_extdata_fb_dcdy(seqnum) ;

truncate table dw_base.dwd_sf_fb_dcdy ;
insert into dw_base.dwd_sf_fb_dcdy
(
cust_id	, -- 客户号
cust_name	, -- 客户姓名
bus_type	, -- 交易业务类型
debtor	, -- 债务人
credit_amt	, -- 债权数额
credit_type	, -- 债权种类
reles_dt	, -- 发布时间
remark	, -- 备注
perform_period	, -- 履行期限
party	, -- 当事人
collateral_desc	, -- 抵押物概况
guarantee_scop	, -- 担保范围
cancel_reason	, -- 注销原因
cancel_dt	, -- 注销日期
reg_dt	, -- 登记日期
reg_org	, -- 登记机关
reg_type	, -- 登记种类
reg_no	, -- 登记编号
seq_num	, -- 生成查询批次号
query_dt	 -- 查询日期
)
  
select  
   b.cust_id	, -- 客户号
   b.cust_name	, -- 客户姓名
   a.transaction_type	, -- 交易业务类型
   a.debtor	, -- 债务人
   a.credit_amount	, -- 债权数额
   a.credit_type	, -- 债权种类
   a.release_time	, -- 发布时间
   a.remark	, -- 备注
   a.performance_deadline	, -- 履行期限
   a.party	, -- 当事人
   a.collateral_profile	, -- 抵押物概况
   a.guarantee_purview	, -- 担保范围
   a.cancellation_reason	, -- 注销原因
   a.cancellation_date	, -- 注销日期
   a.registration_date	, -- 登记日期
   a.registration_authority	, -- 登记机关
   a.registration_types	, -- 登记种类
   a.registration_no	, -- 登记编号
   a.seqnum	, -- 生成查询批次号
   a.createdate	 -- 当前日期
from (select transaction_type	, -- 交易业务类型
   debtor	, -- 债务人
   credit_amount	, -- 债权数额
   credit_type	, -- 债权种类
   release_time	, -- 发布时间
   remark	, -- 备注
   performance_deadline	, -- 履行期限
   party	, -- 当事人
   collateral_profile	, -- 抵押物概况
   guarantee_purview	, -- 担保范围
   cancellation_reason	, -- 注销原因
   cancellation_date	, -- 注销日期
   registration_date	, -- 登记日期
   registration_authority	, -- 登记机关
   registration_types	, -- 登记种类
   registration_no	, -- 登记编号
   seqnum	, -- 生成查询批次号
   createdate	 -- 当前日期 
		from dw_nd.ods_extdata_fb_dcdy a 
		where  date_format(createdate,'%Y%m%d') <= '${v_sdate}'

) a


left join dw_base.dwd_sf_to_msg_log  b  on a.seqNum=b.seq_num ;
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('风报-担保信息数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
