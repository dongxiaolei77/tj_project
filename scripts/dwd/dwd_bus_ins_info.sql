-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dwd_bus_ins_info 客户投保信息 
-- 源表     ：dwd_cust_ins_info 保险客户表,ods_imp_cust_ins_inf 客户投保明细信息
-- 变更记录 ：20220117:统一变动
			-- 20220511 日志变量注释xgm
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_bus_ins_info';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1; 

truncate table  dw_base.dwd_bus_ins_info ;commit;

insert into  dw_base.dwd_bus_ins_info 
(
   cust_id	, -- 客户号
   cust_name	, -- 客户姓名
   cert_no	, -- 证件号码
   tel_no	, -- 手机号
   ins_type	, -- 保险种类
   -- login_status	, -- 地块
   ins_area	, -- 投保面积（亩）
   ins_amt	, -- 保费总额（元）
   ins_year	, -- 投保年份
   -- provc_name	, -- 省
   city_name	, -- 地市
   county_name	, -- 区县
   town_name	, -- 所属镇办
   data_desc	 -- 数据描述
)

select  
   a.cust_id	, -- 客户号
   a.cust_name	, -- 客户姓名
   a.cert_no	, -- 证件号码
   substr(b.contact_tel,1,20)	, -- 手机号
   b.ins_type	, -- 保险种类
   -- login_status	, -- 地块
   b.ins_area	, -- 投保面积（亩）
   b.ins_amt	, -- 保费总额（元）
   b.ins_year	, -- 投保年份
   -- provc_name	, -- 省
   b.city_name	, -- 地市
   b.county_name	, -- 区县
   b.town_name	, -- 所属镇办
   b.data_desc	 -- 数据描述
from    dw_base.dwd_cust_ins_info a 
left join  dw_nd.ods_imp_cust_ins_inf b on a.cert_no=b.id_number ;
commit;

-- select row_count() into @rowcnt;
-- commit;
-- 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('保险数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
