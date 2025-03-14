-- ---------------------------------------
-- 开发人   :  Wangyx
-- 开发时间 ： 20220824
-- 目标表   ： dwd_cust_addr_info 客户地址信息
-- 源表     ： dwd_cust_info
--             dw_nd.ods_bizhall_guar_apply
--             dim_area_info
-- 变更记录 ：20230530 源 dwd_guar_apply_info 改为 dw_nd.ods_bizhall_guar_apply zhangfl
-- ---------------------------------------


-- 创建临时表，获取客户地址信息

drop table if exists dw_tmp.tmp_dwd_cust_addr_info_apply_ref ; commit;
CREATE TABLE dw_tmp.tmp_dwd_cust_addr_info_apply_ref (
cust_id     varchar(50)      comment'客户号'
,cert_no     varchar(50)      comment'证件号码'
,city_cd	varchar(10)      comment'地市'
,country_cd	varchar(10)      comment'区县'
,town_cd	varchar(30)      comment'村镇'
,index idx_tmp_dwd_cust_addr_info_ref_cert_no (cert_no)
,index idx_tmp_dwd_cust_addr_info_ref_cust_id (cust_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit;

insert into dw_tmp.tmp_dwd_cust_addr_info_apply_ref
(
cust_id
,cert_no
,city_cd
,country_cd
,town_cd
)
select
cust_id
,cert_no
,city_cd
,country_cd
,town_cd
from(
	select
	cust_id
	,cert_no
	,city_cd
	,country_cd
	,town_cd
	,row_number() over(partition by cust_id order by update_time desc, case when city_cd is not null then 1 else 0 end desc) as rk
	-- from dw_base.dwd_guar_apply_info 源改为 ODS 取数
    from (SELECT cust_code  as cust_id
                 ,cust_id_no as cert_no
                 ,case when t2.area_lvl ='2' 
                  then t1.region 
                   else 
                   (case when t2.sup_area_cd not in ('370000','0') then t2.sup_area_cd else null end ) end	city_cd
                 ,case when t2.area_lvl ='3'  -- 地市
                   then t1.region 
                   else null end as country_cd -- 区县
                 ,town_code  as town_cd
                 ,update_time
           from (  select cust_code, cust_id_no, region, town_code, update_time
                     from (select id, cust_code, cust_id_no, region, town_code, update_time
					          ,row_number() over(partition by id order by update_time desc) rk
                             from dw_nd.ods_bizhall_guar_apply 
                            ) a
                    where rk = 1
                ) t1
           left join dw_base.dim_area_info  t2
           on t1.region = t2.area_cd
          ) a
    where cust_id is not null 
) t
where rk = 1   -- cert_no有空值,改成cust_id
;
commit;


-- 创建临时表，获取客户地址信息（补充）

drop table if exists dw_tmp.tmp_dwd_cust_addr_info_ref_add ; commit;
CREATE TABLE dw_tmp.tmp_dwd_cust_addr_info_ref_add (
cert_no     varchar(50)   comment'证件号码'
,city_cd	varchar(10)   comment'地市'
,country_cd	varchar(10)   comment'区县'
,index idx_tmp_dwd_cust_addr_info_ref_add_cert_no (cert_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit;

insert into dw_tmp.tmp_dwd_cust_addr_info_ref_add
(
cert_no
,city_cd
,country_cd
)
select
cert_no
,city_code
,country_code
from
(
	select
	cert_no
	,city_code
	,country_code
	,row_number() over(partition by cert_no order by loan_star_dt desc) as rk
	from dw_base.dwd_guar_info_stat
) t
where rk = 1
;
commit;



truncate table dw_base.dwd_cust_addr_info ; commit; 

insert into dw_base.dwd_cust_addr_info 
(
day_id        	-- 数据日期    
,cust_id      	-- 客户号     
,cust_name    	-- 客户姓名    
,cert_no      	-- 证件号码    
,province_cd  	-- 省
,province_name  -- 省名称
,city_cd      	-- 市   
,city_name      -- 市名称   
,country_cd   	-- 县 
,country_name   -- 县名称      
,area_cd      	-- 最细粒度行政区划
,addr         	-- 地址详情    
)
select
'${v_sdate}'
,t.cust_id
,t.cust_name
,t.cert_no
,t.province_cd
,t2.sup_area_name as province_name
,t.city_cd
,t2.area_name as city_name
,t.country_cd
,t3.area_name as country_name
,t.town_cd
,t.addr
from
(
select
t1.cust_id
,t1.cust_name
,t1.cert_no
,coalesce(t5.sup_area_cd,t8.sup_area_cd,t6.sup_area_cd) as province_cd
,coalesce(t2.city_cd,t0.city_cd,t7.city_cd) as city_cd
,coalesce(t2.country_cd,t0.country_cd,t7.country_cd) as country_cd
,coalesce(t2.town_cd,t0.town_cd)town_cd
,coalesce(t3.addr,t4.reg_addr) as addr
from dw_base.dwd_cust_info t1  
left join (
	select cert_no,max(city_cd)city_cd,max(country_cd)country_cd,max(town_cd)town_cd
	from dw_tmp.tmp_dwd_cust_addr_info_apply_ref 
	group by cert_no
)t2
on t1.cert_no = t2.cert_no
left join dw_tmp.tmp_dwd_cust_addr_info_apply_ref t0
on t1.cust_id = t0.cust_id
left join dw_tmp.tmp_dwd_cust_addr_info_ref_add t7
on t1.cert_no = t7.cert_no
left join dw_base.dwd_cust_per_info t3  
on t1.cert_no = t3.cert_no
left join dw_base.dwd_cust_comp_info t4 
on t1.cert_no = t4.cert_no
left join dw_base.dim_area_info t5
on t2.city_cd = t5.area_cd
left join dw_base.dim_area_info t6
on t7.city_cd = t6.area_cd
left join dw_base.dim_area_info t8
on t0.city_cd = t8.area_cd
) t
left join dw_base.dim_area_info t2
on t.city_cd = t2.area_cd
left join dw_base.dim_area_info t3
on t.country_cd = t3.area_cd
where t.city_cd is not null
;
commit;