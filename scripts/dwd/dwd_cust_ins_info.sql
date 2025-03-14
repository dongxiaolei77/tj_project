
-- ---------------------------------------
-- 开发人   :  xueguangmin
-- 开发时间 ： 20220117
-- 目标表   ： dwd_cust_ins_info 保险客户表 
-- 源表     ： ods_imp_cust_ins_inf 客户投保明细信息
-- 变更记录 ： 20220117:统一变动   
--             20220516 日志变量注释  xgm    
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_cust_ins_info';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1; 



-- 客户投保信息  投保数据信息  根据客户信息生成投保数据信息 
-- 保险客户表删除索引，然后在重建索引


-- drop index idx_ods_imp_cust_ins_inf_id on   dw_nd.ods_imp_cust_ins_inf ;
-- create  index idx_ods_imp_cust_ins_inf_id on   dw_nd.ods_imp_cust_ins_inf(id_number) ;

truncate  table dw_base.dwd_cust_ins_info ;commit;
insert into  dw_base.dwd_cust_ins_info 
(

cust_id	, -- 客户号
cust_name	, -- 客户姓名
cust_stt	, -- 客户状态
cust_type	, -- 客户类型
cert_type	, -- 证件类型
cert_no	, -- 证件号码
tel_no	, --  手机号 
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
    CONCAT(10,id_number)  as cust_id, -- 客户号
    cust_name	, -- 客户名称
    0 as cust_stt,     -- 客户状态
    1 cust_type , --  客户类型
    10  as cert_type ,-- 证件类型
    id_number as cert_no , --   证件号码
    substr(contact_tel,1,20) as tel_no	, --  手机号
    '山东省' as provc_name, -- 省
    city_name as city_name , -- 地市
    county_name as county_name , -- 区县
    cust_name  as addr , -- 地址详情
    0 as is_hny , -- 是否惠农云
    0 as is_dyy, -- 是否道一云
    0 as is_ident, -- 核身是否通过
    -- date_add(DATE_FORMAT(now(),'%Y-%m-%d %H:%i:%S'), interval -1 day)   -- mdy
	 '${v_sdate}'  as open_dt ,--  开户日期
    ''  as item_stt , -- 项目状态
	''  as s_cust_id  , -- 源系统客户号
    '5' as data_source -- 数据来源 1: 惠农云系统,2:来自台账的客户,3:潍坊V贷客户,4:海鼎客户,5:保险客户

from  dw_nd.ods_imp_cust_ins_inf  
group by id_number;commit;
-- select row_count() into @rowcnt;
-- commit;
-- 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('客户保险数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;

