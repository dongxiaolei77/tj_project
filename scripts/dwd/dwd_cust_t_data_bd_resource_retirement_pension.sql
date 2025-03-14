-- ---------------------------------------
-- 开发人   :  xueguangmin
-- 开发时间 ： 20220117
-- 目标表   ： dwd_cust_t_data_bd_resource_retirement_pension 大数据局-人力资源社会保障厅-退休人员养老金发放概况
-- 源表     ： ods_de_t_data_bd_resource_retirement_pension  大数据局-人力资源社会保障厅-个人缴费信息汇总
				-- ods_de_t_msg_log 报文日志表
				-- ods_de_t_cust_info 客户信息表
				-- dwd_cust_info 客户基本信息表
-- 变更记录 ： 20220117:统一变动
			-- 20220324：新建临时表 tmp_dwd_cust_t_data_bd_resource_retirement_pension_retpen
--             20220516 日志变量注释  xgm   
-- ---------------------------------------

-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_cust_t_data_bd_resource_retirement_pension';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;


drop table if exists dw_base.tmp_dwd_cust_t_data_bd_resource_retirement_pension_retpen;
commit;
create table dw_base.tmp_dwd_cust_t_data_bd_resource_retirement_pension_retpen
(
	pnsn_sum varchar(50) COMMENT '缴费年月距今月数(月)',
	seqNum varchar(50) COMMENT '生成查询批次号',
	createDate varchar(20) COMMENT '当前日期',
	dataId varchar(32) COMMENT '主键',
	index (seqNum)
) engine=innodb default charset=utf8mb4 collate=utf8mb4_bin row_format=dynamic ; 
commit;
insert into dw_base.tmp_dwd_cust_t_data_bd_resource_retirement_pension_retpen
select 
	t1.pnsn_sum
	,t1.seqNum
	,t1.createDate
	,t1.dataId
from dw_nd.ods_de_t_data_bd_resource_retirement_pension t1
where createDate between date_format('${v_sdate}','%Y-%m-%d') 
	and date_format(date_add('${v_sdate}', interval 1 day),'%Y-%m-%d');
commit;


 
-- 大数据局-人力资源社会保障厅-退休人员养老金发放概况
-- truncate  table dw_base.dwd_cust_t_data_bd_resource_retirement_pension;
delete from dw_base.dwd_cust_t_data_bd_resource_retirement_pension
where date_format(createDate,'%Y%m%d') =  '${v_sdate}';
commit;

insert into dw_base.dwd_cust_t_data_bd_resource_retirement_pension
	(
	cust_id,
	cust_name,
	cert_no,
	pnsn_sum,
	seqNum,
	createDate,
	dataId
	)
select 
	t4.cust_id,
	t4.cust_name,
	t4.cert_no,
	t1.pnsn_sum,
	t1.seqNum,
	t1.createDate,
	t1.dataId
from  dw_base.tmp_dwd_cust_t_data_bd_resource_retirement_pension_retpen t1
-- dw_nd.ods_de_t_data_bd_resource_retirement_pension t1
left join dw_base.tmp_dwd_cust_t_data_bd_cfdy_msglog_t2 t2
-- (select msg_id,cust_id,msg_type,req_url,req_original_msg,req_msg,req_user_id,req_msg_seq_no,req_time,req_channel,req_product_grp_code,res_original_msg,res_msg,res_code,res_time,creator,create_time,updator,update_time    
-- from  dw_nd.ods_de_t_msg_log 
--  where date_format(update_time,'%Y%m%d') =  '${v_sdate}'  -- mdy
-- group by msg_id) t2
on t1.seqnum=t2.msg_id
left join dw_base.tmp_dwd_cust_t_data_bd_cfdy_custinfo_t3 t3
-- (select cust_id,cust_type,cust_name,id_no,mobile,channel,channel_cust_id,legal_name,legal_id_no,creator,create_time,updator,update_time  
-- from  dw_nd.ods_de_t_cust_info 
--  where date_format(update_time,'%Y%m%d') <=  '${v_sdate}'  -- mdy
-- group by cust_id) t3
on t2.cust_id=t3.cust_id
left join dw_base.tmp_dwd_cust_t_data_bd_cfdy_dcustinfo_t4  t4
on t3.id_no=t4.cert_no ;
commit;

-- select row_count() into @rowcnt;
commit;
-- insert into dw_base.pub_etl_log -- values (@etl_date,@pro_name,@table_name,@sorting,concat('大数据局-人力资源社会保障厅-退休人员养老金发放概况表加工完成,共插入',@rowcnt,'条'),@time,now());commit;

