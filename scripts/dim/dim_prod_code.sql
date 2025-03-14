-- ---------------------------------------
-- 开发人   : zhangfl
-- 开发时间 : 20230220
-- 目标表   : dw_base.dim_prod_code                 产品类型维表
-- 源表     : dw_nd.ods_t_sys_data_dict_value_v2    数据字典值表V2
--            
--            

-- 备注     : 

-- 变更记录 : 
-- ---------------------------------------


truncate table dw_base.dim_prod_code;
commit;


insert into dw_base.dim_prod_code
select id
	   ,code
       ,value
       ,create_time
       ,update_time
       ,create_name
       ,update_name
	   ,'' as user_id
	   ,'' as del_flag
  from (
       select id
			  ,code
              ,value
              ,create_time
              ,update_time
              ,create_name
              ,update_name
         from (select id, code, value, create_time, update_time, create_name, update_name, row_number()over(partition by id order by update_time desc) rn
                 from dw_nd.ods_t_sys_data_dict_value_v2
                where dict_code = 'productWarranty' ) a 
        where a.rn = 1
      ) t;
commit;
