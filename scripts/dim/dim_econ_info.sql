-- ----------------------------------------------------------
-- 开发人   : zouziyu
-- 开发时间 ：20211029
-- 目标表   ：dw_base.dim_econ_info 国民经济分类维表
-- 源表     ：dw_nd.ods_imp_econ_info 国民经济分类临时表
-- 变更记录 ：20211108 关联源表改为 dw_nd.ods_imp_econ_info 自建表
--            20230531 切源到担保业务系统码表
-- ----------------------------------------------------------

drop table if exists dw_tmp.tmp_dim_econ_info_01; commit;
create table if not exists dw_tmp.tmp_dim_econ_info_01(
dict_code varchar(100) comment '字典码值'
,code varchar(100) comment '字典值编码'
,value varchar(100) comment '字典值'
,parent_dict_value_code varchar(100) comment '父字典值编码'
,index idx_tmp_dim_econ_info_01_dict_code(dict_code)
,index idx_tmp_dim_econ_info_01_parent_code(parent_dict_value_code)
);
commit;

insert into dw_tmp.tmp_dim_econ_info_01 

select dict_code
       ,code
	   ,value
	   ,parent_dict_value_code
from (
	select id
	    ,dict_code
		,code
		,value
		,parent_dict_value_code
		,row_number()over(partition by code order by update_time desc) rn
	from dw_nd.ods_t_sys_data_dict_value_v2
	where dict_code like '%gbt%'
)t
where t.rn = 1
;
commit;

-- 删除维表数据	
delete from dw_base.dim_econ_info;

commit;

-- 插入最新维表数据
insert into dw_base.dim_econ_info( 
            day_id,                -- 数据日期
            econ_cd,               -- 国民经济分类编码
            econ_name,             -- 国民经济分类名称
            econ_lvl,              -- 级别
            econ_url,              -- 国民经济分类路径
            sup_econ_cd,           -- 上级国民经济分类编码
            sup_econ_name          -- 上级国民经济分类名称
)
select  '${v_sdate}',             -- 数据日期
        t.code,                   -- 国民经济分类编码      
        t.value,                  -- 国民经济分类名称
		t.econ_lvl,               -- 级别
		t.econ_url,               -- 国民经济分类路径
		t.parent_dict_value_code, -- 上级国民经济分类编码
		t.sup_econ_name           -- 上级国民经济分类名称
		from(select a.code,                                  -- 国民经济分类编码
                    a.value,                                 -- 国民经济分类名称
			        case when a.dict_code='gbt1' then '01'
			             when a.dict_code='gbt2' then '02'
			       		 when a.dict_code='gbt3' then '03'
			       	     when a.dict_code='gbt4' then '04'
                    end as econ_lvl,                         --  级别
			        case when a.dict_code='gbt1' then a.code
			             when a.dict_code='gbt2' then concat_ws(',',a.parent_dict_value_code,a.code)
			       		 when a.dict_code='gbt3' then concat_ws(',',c.parent_dict_value_code,c.code,a.code)
			       		 when a.dict_code='gbt4' then concat_ws(',',d.parent_dict_value_code,d.code,b.code,a.code)
			       		 end as econ_url,                    --  国民经济分类路径
			        a.parent_dict_value_code,                --  上级国民经济分类编码
			        case when a.dict_code='gbt1' then null
			             when a.dict_code='gbt2' then e.value
			       		 when a.dict_code='gbt3' then c.value
			       		 when a.dict_code='gbt4' then b.value	
			       	     end as sup_econ_name                --  上级国民经济分类名称
                    from dw_tmp.tmp_dim_econ_info_01 a
                    left join  (select code,parent_dict_value_code,value from dw_tmp.tmp_dim_econ_info_01 where dict_code='gbt3') b
                    on a.parent_dict_value_code = b.code
                    left join (select code,parent_dict_value_code,value from dw_tmp.tmp_dim_econ_info_01 where dict_code='gbt2') c
                    on a.parent_dict_value_code = c.code
                    left join (select code,parent_dict_value_code,value from dw_tmp.tmp_dim_econ_info_01 where dict_code='gbt2') d
                    on b.parent_dict_value_code = d.code
                    left join (select code,value from dw_tmp.tmp_dim_econ_info_01 where dict_code='gbt1') e
                    on a.parent_dict_value_code = e.code) t;


commit;