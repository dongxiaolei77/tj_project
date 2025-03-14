-- ---------------------------------------
-- 开发人   : WLN
-- 开发时间 ：20230329
-- 目标表   ：dw_base.dwd_cust_biz_status_info 
-- 源表     ：dw_base.dwd_guar_info_all
--            dw_base.dim_area_info
-- 变更记录 ：20230829 增加经营地址_市、经营地址_县、经营品类、经营分类、国民经济分类、客户经理 wyx

-- ---------------------------------------


-- 创建临时表，获取客户直通经营分类

drop table if exists dw_tmp.tmp_dwd_cust_biz_status_info_busi_type ;
commit ;

create table dw_tmp.tmp_dwd_cust_biz_status_info_busi_type(
cert_no varchar(32),
busi_type varchar(32) ,
INDEX idx_tmp_dwd_cust_biz_status_info_busi_type ( cert_no )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit ;

insert into dw_tmp.tmp_dwd_cust_biz_status_info_busi_type(
cert_no
,busi_type
)
select
 t2.id_no
,concat(t3.value,'类')
from(
	select
	id
	,id_no
	,business_type
	from(
		select
		id
		,id_no
		,business_type
		,row_number() over(partition by id order by update_time desc) as rk
		from dw_nd.ods_crm_cust_per_info
	) t1
	where rk = 1
) t2
inner join (
	select code,value from
	(select code,value
	,row_number() over(partition by id order by update_time desc) as rk
	from dw_nd.ods_t_sys_data_dict_value_v2
	where dict_code = 'businessType'
	)
	t where rk = 1
) t3
on t2.business_type = t3.code
;
commit;



-- 创建临时表，获取经营分类
drop table if exists dw_tmp.tmp_dwd_cust_biz_status_info_busi_class ;
commit ;

create table dw_tmp.tmp_dwd_cust_biz_status_info_busi_class(
cert_no varchar(32),
busi_type varchar(32) ,
busi_pl varchar(64),
INDEX idx_tmp_dwd_cust_biz_status_info_busi_class ( cert_no )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit ;

insert into dw_tmp.tmp_dwd_cust_biz_status_info_busi_class
(
cert_no
,busi_type
,busi_pl
)
select
 t1.cert_no
,group_concat(distinct case when t2.proj_origin = '05' then t3.busi_type else t4.ind_type_lv1_value end separator '/') as busi_type
,group_concat(distinct t5.ind_type_lv2_value separator '/') as busi_class
from
dw_base.dwd_guar_info_all t
inner join dw_base.dwd_guar_cont_info_all t1
on t.guar_id = t1.guar_no
inner join 
(
	select
	code
	,cust_identity_no
	,national_econ_type
	,proj_origin
	,proj_status
	from (
	select
	code
	,cust_identity_no
	,national_econ_type
	,proj_origin
	,proj_status
	,row_number() over(partition by code order by db_update_time desc) as rk
	from dw_nd.ods_t_biz_project_main
	) t
	where rk = 1
) t2
on t1.proj_no = t2.code
left join dw_tmp.tmp_dwd_cust_biz_status_info_busi_type t3
on t2.cust_identity_no = t3.cert_no
left join (select distinct econ_code_lv4,ind_type_lv1_value from dw_base.dim_econ_pl_map) t4
on t2.national_econ_type = t4.econ_code_lv4
left join (select distinct econ_code_lv4,ind_type_lv2_value from dw_base.dim_econ_pl_map) t5
on t2.national_econ_type = t5.econ_code_lv4
where t.item_stt = '已放款'
group by t1.cert_no
;
commit;


truncate table dw_base.dwd_cust_biz_status_info; commit;

insert into dw_base.dwd_cust_biz_status_info
(
 cust_id
,cust_name
,cert_no
,tel_no
,cust_type
,city_code
,city_name
,district_code
,district_name
,city_name_1
,district_name_1
,busi_pl
,busi_class
,econ_class
,bank_mgr
)

select  distinct t1.cust_id
       ,t1.cust_name
       ,t1.cert_no
	   ,t1.tel_no
	   ,t1.cust_type
	   ,t2.area_cd
	   ,t1.city_name
	   ,coalesce(t1.district_cd,t3.area_cd)
	   ,t1.county_name
	   ,coalesce(t4.city_name_1,'其他')
	   ,coalesce(t4.district_name_1,'其他')
	   ,coalesce(t5.busi_pl,'其他')
	   ,coalesce(t5.busi_type,'其他') as busi_class
	   ,coalesce(t4.econ_class,'其他')
	   ,coalesce(t4.bank_mgr,'其他')

from (
	select cust_id
		   ,cust_name
		   ,cert_no
		   ,tel_no
		   ,cust_type
		   ,city_name
		   ,county_name
		   ,district_cd
	from (
		select a.cust_id
			   ,a.cust_name
			   ,a.cert_no
			   ,a.tel_no
			   ,a.cust_type
			   ,a.city_name
			   ,a.county_name
			   ,b.district_cd
			   ,row_number() over(partition by a.cert_no order by a.loan_reg_dt desc) as rk
		from dw_base.dwd_guar_info_all a 
		left join dw_base.dwd_agmt_guar_info b on a.guar_id = b.proj_dtl_no
		where a.item_stt = '已放款'
	)t
	where rk = 1
)t1
left join (
	select
	cert_no
	,group_concat(distinct city_name separator '/') as city_name_1
	,group_concat(distinct county_name separator '/') as district_name_1
	,group_concat(distinct econ_class separator '/') as econ_class
	,case when right(group_concat(distinct bank_mgr  separator '/'),1) = '/'
				then left(group_concat(distinct bank_mgr separator '/'),char_length(group_concat(distinct bank_mgr separator '/'))-1)
				else group_concat(distinct bank_mgr separator '/')
				end as bank_mgr
	from
	(select * from dw_base.dwd_guar_info_all where item_stt = '已放款')t
	group by cert_no
) t4
on t1.cert_no = t4.cert_no
left join dw_tmp.tmp_dwd_cust_biz_status_info_busi_class t5
on t1.cert_no = t5.cert_no
left join dw_base.dim_area_info t2
on t1.city_name = t2.area_name
left join dw_base.dim_area_info t3
on t1.county_name = t3.area_name
and t1.city_name = t3.sup_area_name
;
commit;
