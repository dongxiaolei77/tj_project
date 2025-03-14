
   -- ---------------------------------------
-- 开发人   :  xueguangmin
-- 开发时间 ： 20220117
-- 目标表   ： dwd_cust_risk_info 客户风险信息 
-- 源表     ： dwd_cust_info  客户基本信息表,
				-- ods_t_project_application_info项目申请信息表
-- 变更记录 ： 20220117:统一变动  
--             20220516 日志变量注释  xgm
--             20220831 客户模型重构：cert_type还原 wyx     
-- ---------------------------------------

-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_cust_risk_info';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1; 

-- 客户风险信息（一个历史一个最新）
truncate table dw_base.dwd_cust_risk_info; commit;

insert into dw_base.dwd_cust_risk_info
(
cust_id	, -- 客户编号
cust_name	, -- 客户姓名
cert_type	, -- 证件类型
cert_no	, -- 证件号码
five_level	, -- 五级分类
start_dt	, -- 开始日期
end_dt	  -- 结束日期
)
select  
a.cust_id	, -- 客户编号
a.cust_name	, -- 客户姓名
a.cert_type, -- 证件类型 
a.cert_no	, -- 证件号码
b.five_level_classification,
b.contract_start_dates,
b.contract_end_dates

from dw_base.dwd_cust_info a 
inner join  (
	select  five_level_classification
			,project_code
			,identity
			,contract_start_dates
			,contract_end_dates    
	from (  
			select five_level_classification
				,project_code
				,identity
				,contract_start_dates
				,contract_end_dates
				,row_number() over(partition by project_code order by create_time desc) as rk
			from  dw_nd.ods_t_project_application_info b  
			where date_format(create_time,'%Y%m%d') <=  '${v_sdate}'  -- mdy		
	) b  
	where rk = 1
) b  
on a.cert_no = b.identity  
;
commit;
