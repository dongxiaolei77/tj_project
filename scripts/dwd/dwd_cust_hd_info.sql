
-- ---------------------------------------
-- 开发人   :  xueguangmin
-- 开发时间 ： 20220117
-- 目标表   ： dwd_cust_hd_info 海鼎客户表 
-- 源表     ： ods_imp_hd_cust_info 海鼎客户信息
-- 变更记录 ： 20220117:统一变动
--             20220516 日志变量注释  xgm       
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_cust_hd_info';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1; 

-- 海鼎的数据  
truncate  table dw_base.dwd_cust_hd_info ;commit;
insert into  dw_base.dwd_cust_hd_info 
(

cust_id	, -- 客户号
cust_name	, -- 客户姓名
cust_stt	, -- 客户状态
cust_type	, -- 客户类型
cert_type	, -- 证件类型
cert_no	, -- 证件号码
provc_name	, -- 省
city_name	, -- 地市
county_name	, -- 区县
addr	, -- 地址详情
is_hny	, -- 是否惠农云
is_dyy	, -- 是否道一云
is_ident	, -- 核身是否通过
open_dt	, -- 开户日期
item_stt	, -- 项目状态
s_cust_id	, -- 源系统客户号
data_source	  -- 数据来源 1: 惠农云系统,2:来自台账的客户,3:潍坊V贷客户,4:海鼎客户 
)

select  

ifnull(CONCAT(case when title='公司' then 21 else 10 end,trim(indust_regist_no)),cust_no)  as cust_id, -- 客户号
cust_name	, -- 客户名称
    0 as cust_stt,     -- 客户状态
    case when title='公司' then 2 else 1 end as cust_type , --  客户类型
    case when title='公司' then 21 else 10 end  as cert_type ,-- 证件类型
    indust_regist_no as cert_no , --   证件号码
    substr(concat(substring_index(street,'省',1),'省'),1,20) as provc_name, -- 省
    substr(city,1,20) as city_name , -- 地市
    substr(concat(substring_index(substring_index(street,'省',-1),'县',1),'县'),1,20) as county_name , -- 区县
    street  as addr , -- 地址详情
    0 as is_hny , -- 是否惠农云
    0 as is_dyy, -- 是否道一云
    0 as is_ident, -- 核身是否通过
	
      '${v_sdate}' ,-- date_add(DATE_FORMAT(now(),'%Y-%m-%d %H:%i:%S'), interval -1 day) as open_dt ,--  开户日期   -- mdy
    ''  as item_stt , -- 项目状态
	cust_no as s_cust_id  , -- 源系统客户号
    '4' as data_source -- 数据来源 1: 惠农云系统,2:来自台账的客户 ,3:潍坊V贷

from  dw_nd.ods_imp_hd_cust_info  
where  length(indust_regist_no) <>11    
group by indust_regist_no;
commit;

-- select row_count() into @rowcnt;
-- commit;
-- 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('海鼎客户加工完成,共插入',@rowcnt,'条'),@time,now());commit;

