-- ---------------------------------------
-- 开发人   :  xueguangmin
-- 开发时间 ： 20220117
-- 目标表   ： dwd_cust_t_data_bd_cfdy 客户房地产权查封抵押表 
-- 源表     ： ods_de_t_data_bd_cfdy  房地产权查封抵押表,
				-- ods_de_t_msg_log 报文日志表
				-- ods_de_t_cust_info 客户信息表
				-- dwd_cust_info 客户基本信息表
-- 变更记录 ： 20220117:统一变动
			-- 20220316 新建临时表tmp_dwd_cust_t_data_bd_cfdy_dcustinfo_t4
--             20220516 日志变量注释  xgm
--             20241201 脚本的统一变更，MySQL5.0转MySQL8.0 zhangfl 
-- ---------------------------------------
set interactive_timeout = 7200;
set wait_timeout = 7200;
-- 大数据局数据-房产信息
--  添加临时表来优化
-- t1 房地产权查封抵押表临时表
drop table if exists dw_base.tmp_dwd_cust_t_data_bd_cfdy_cfdy_t1;
commit;
create table dw_base.tmp_dwd_cust_t_data_bd_cfdy_cfdy_t1(
	total_area varchar(100),  -- 不动产总面积
	total_cnt varchar(10),-- 不动产总数量
	details longtext,  -- 不动产查封明细
	seqNum varchar(50),  -- 生成查询批次号
	createDate varchar(20),  -- 当前日期
	dataId varchar(32),  -- 主键
	index idx_tmp_dwd_cust_t_data_bd_cfdy_cfdy_t1_dataId(dataId),
	index idx_tmp_dwd_cust_t_data_bd_cfdy_cfdy_t1_seqNum(seqNum)
) engine=innodb  default charset=utf8mb4 collate=utf8mb4_bin row_format=dynamic comment='房地产权查封抵押表临时表'; 
commit;

insert into dw_base.tmp_dwd_cust_t_data_bd_cfdy_cfdy_t1
select 
	t1.total_area,
	t1.total_cnt,
	t1.details,
	t1.seqNum,
	t1.createDate,
	t1.dataId
from dw_nd.ods_de_t_data_bd_cfdy t1  -- 房地产权查封抵押表
where createDate between date_format('${v_sdate}','%Y-%m-%d') 
					and date_format(date_add('${v_sdate}', interval 1 day),'%Y-%m-%d');
commit;

-- t2 完成
drop table if exists dw_base.tmp_dwd_cust_t_data_bd_cfdy_msglog_t2;
commit;
create table dw_base.tmp_dwd_cust_t_data_bd_cfdy_msglog_t2(
	msg_id varchar (32),
	cust_id varchar (32),
	-- msg_type varchar (20),
	-- req_url longtext,
	-- req_original_msg longtext,
	-- req_msg longtext,
	-- req_user_id varchar (32),
	-- req_msg_seq_no varchar (50),
	-- req_time timestamp (3),
	-- req_channel varchar (20),
	-- req_product_grp_code varchar (20),
	-- res_original_msg longtext ,
	-- res_msg longtext,
	-- res_code varchar (10),
	-- res_time timestamp (3),
	-- creator varchar (64),
	-- create_time datetime ,
	-- updator varchar (64),
	update_time datetime ,
	index idx_tmp_dwd_cust_t_data_bd_cfdy_msglog_t2_dataId(msg_id),
	index idx_tmp_dwd_cust_t_data_bd_cfdy_msglog_t2_seqNum(cust_id)
) engine=innodb default charset=utf8mb4 collate=utf8mb4_bin row_format=dynamic comment='报文日志表临时表'; 
commit;

insert into dw_base.tmp_dwd_cust_t_data_bd_cfdy_msglog_t2
select msg_id,
	cust_id ,
	update_time
from(
select 
	msg_id,
	cust_id ,
	-- msg_type,
	-- req_url,
	-- req_original_msg,
	-- req_msg,
	-- req_user_id,
	-- req_msg_seq_no,
	-- req_time,
	-- req_channel,
	-- req_product_grp_code,
	-- res_original_msg,
	-- res_msg,
	-- res_code,
	-- res_time,
	-- creator,
	-- create_time,
	-- updator,
	update_time,
	ROW_NUMBER()over(PARTITION BY msg_id order by update_time asc) rn
from dw_nd.ods_de_t_msg_log b  -- 报文日志表
where date_format(update_time,'%Y%m%d')   -- mdy
 between date_format('${v_sdate}','%Y-%m-%d') 
 and date_format(date_add('${v_sdate}', interval 1 day),'%Y-%m-%d')
	-- exists ( select 1 from dw_base.tmp_dwd_cust_t_data_bd_cfdy_cfdy_t1 a where a.seqnum=b.msg_id)
) t
where rn = 1
;
commit;

-- t3 完成
drop table if exists dw_base.tmp_dwd_cust_t_data_bd_cfdy_custinfo_t3;
commit;
create table dw_base.tmp_dwd_cust_t_data_bd_cfdy_custinfo_t3(
	cust_id	varchar (32),
	-- cust_type varchar (10),
	-- cust_name varchar (64),
	id_no varchar (20),
	-- mobile varchar (20),
	-- channel varchar (20),
	-- channel_cust_id varchar (40),
	-- legal_name varchar (64),
	-- legal_id_no varchar (20),
	-- creator varchar (64),
	-- create_time datetime ,
	-- updator varchar (64),
	update_time datetime ,
	index idx_tmp_dwd_cust_t_data_bd_cfdy_custinfo_t3_dataId(cust_id),
	index idx_tmp_dwd_cust_t_data_bd_cfdy_custinfo_t3_seqNum(id_no)
) engine=innodb default charset=utf8mb4 collate=utf8mb4_bin row_format=dynamic comment='房地产权查封抵押表临时表'; 
commit;

insert into dw_base.tmp_dwd_cust_t_data_bd_cfdy_custinfo_t3
select cust_id
,id_no
,update_time
from (
select
	cust_id,
	-- cust_type,
	-- cust_name,
	id_no ,
	-- mobile,
	-- channel,
	-- channel_cust_id,
	-- legal_name,
	-- legal_id_no,
	-- creator,
	-- create_time,
	-- updator,
	update_time,
	row_number()over(partition by cust_id order by update_time asc) rn
from  dw_nd.ods_de_t_cust_info   -- 客户信息表
where date_format(update_time,'%Y%m%d') <=  '${v_sdate}'  -- mdy
) t
where rn = 1;
commit;


-- t4  
drop table if exists dw_base.tmp_dwd_cust_t_data_bd_cfdy_dcustinfo_t4; -- mdy 20220316
commit;
create table dw_base.tmp_dwd_cust_t_data_bd_cfdy_dcustinfo_t4(
cust_id varchar (32),
cust_name varchar (50),
cert_no varchar (50),
index (cert_no)
) engine=innodb  default charset=utf8mb4 collate=utf8mb4_bin row_format=dynamic comment='房地产权查封抵押表临时表'; 

insert into dw_base.tmp_dwd_cust_t_data_bd_cfdy_dcustinfo_t4
select cust_id,
	cust_name,
	cert_no
from(
select  
	cust_id,
	cust_name,
	cert_no,
	row_number()over(partition by cert_no order by cust_id ) rn
from dw_base.dwd_cust_info -- 客户基本信息表
) t
where rn = 1  ;
commit;

-- 临时表添加完成



-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_cust_t_data_bd_cfdy';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1; 

-- truncate table dw_base.dwd_cust_t_data_bd_cfdy;
  delete from  dw_base.dwd_cust_t_data_bd_cfdy
where date_format(createDate,'%Y%m%d') =  '${v_sdate}';

commit;
insert into dw_base.dwd_cust_t_data_bd_cfdy
	(
	cust_id,
	cust_name,
	cert_no,
	total_area,
	total_cnt,
	details,
	seqNum,
	createDate,
	dataId
	)
select 
	t4.cust_id,
	t4.cust_name,
	t4.cert_no,
	t1.total_area,
	t1.total_cnt,
	t1.details,
	t1.seqNum,
	t1.createDate,
	t1.dataId
from dw_base.tmp_dwd_cust_t_data_bd_cfdy_cfdy_t1 t1
-- (select t1.total_area,t1.total_cnt,t1.details,t1.seqNum,t1.createDate,t1.dataId
-- from dw_nd.ods_de_t_data_bd_cfdy t1
-- where date_format(createDate,'%Y%m%d') <=  '${v_sdate}') t1
-- dw_nd.ods_de_t_data_bd_cfdy t1
left join dw_base.tmp_dwd_cust_t_data_bd_cfdy_msglog_t2 t2
-- (select msg_id,cust_id,msg_type,req_url,req_original_msg,req_msg,req_user_id,req_msg_seq_no,req_time,req_channel,req_product_grp_code,res_original_msg,res_msg,res_code,res_time,creator,create_time,updator,update_time
-- from  dw_nd.ods_de_t_msg_log 
-- where date_format(update_time,'%Y%m%d') <=  '${v_sdate}'  -- mdy
-- group by msg_id) t2
on t1.seqnum=t2.msg_id
left join dw_base.tmp_dwd_cust_t_data_bd_cfdy_custinfo_t3 t3
-- (select cust_id,cust_type,cust_name,id_no,mobile,channel,channel_cust_id,legal_name,legal_id_no,creator,create_time,updator,update_time
-- from  dw_nd.ods_de_t_cust_info 
-- where date_format(update_time,'%Y%m%d') <=  '${v_sdate}'  -- mdy
-- group by cust_id) t3
on t2.cust_id=t3.cust_id
left join dw_base.tmp_dwd_cust_t_data_bd_cfdy_dcustinfo_t4 t4
on t3.id_no=t4.cert_no;
commit;

-- select row_count() into @rowcnt;
-- commit;
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('客户房产信息加工完成,共插入',@rowcnt,'条'),@time,now());
-- commit;
