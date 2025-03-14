-- ---------------------------------------
-- 开发人   : wln
-- 开发时间 ：20221118
-- 目标表   : dim_category_info  品类维表
-- 源表     ：
--            dw_nd.ods_t_sys_data_dict_value_v2

            
-- 变更记录 ：
-- ---------------------------------------

delete from dw_base.dim_category_info; commit;

insert into dw_base.dim_category_info

select t1.economy_first_code
       ,t1.economy_first_name
       ,t1.economy_second_code
       ,t1.economy_second_name
	   ,t2.code as economy_third_code
	   ,t2.value as economy_third_name
from (
	select t1.code as economy_first_code
		   ,t1.value as economy_first_name
		   ,t2.code as economy_second_code
		   ,t2.value as economy_second_name
	from dw_nd.ods_t_sys_data_dict_value_v2 t1
	left join dw_nd.ods_t_sys_data_dict_value_v2 t2
	on t1.code = t2.parent_dict_value_code
	and t2.dict_code = 'category' 
	where t1.dict_code = 'category'
	and length(t1.code) = 3 
)t1
left join dw_nd.ods_t_sys_data_dict_value_v2 t2
on t1.economy_second_code = t2.parent_dict_value_code
and t2.dict_code = 'category' 
;
commit;