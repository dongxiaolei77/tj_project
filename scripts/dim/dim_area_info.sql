-- ---------------------------------------
-- 开发人   : zouziyu
-- 开发时间 ：20211027
-- 目标表   ：dim_area_info 行政区划维表
-- 源表     ：ods_t_sys_area 新业务中台地区表
-- 变更记录 ：因XX进行变更、变更日期XXX、变更人XX
--            20220517 调整行政级别，改为从ods_t_sys_area出
-- ---------------------------------------

-- 删除临时表
drop table if exists dw_base.tmp_dim_area_info;
commit;

-- 创建临时表
create table dw_base.tmp_dim_area_info(             
             area_id varchar(64),             -- 地区ID
             area_name varchar(32),           -- 地区名称
             ancestors text(0),               -- 地区路径
             parent_id varchar(100),          -- 上级地区ID
			 area_lvl varchar(2), -- mdy 20220517 wyx
			 INDEX (area_id)
)ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;

commit;

-- 临时表插入最新数据
insert into dw_base.tmp_dim_area_info(
             area_id,              -- 地区ID
             area_name,            -- 地区名称
             ancestors,            -- 地区路径
             parent_id,             -- 上级地区ID
			 area_lvl
)
select       t.area_id,                -- 地区ID
             t.area_name,              -- 地区名称
             t.ancestors,              -- 地区路径
             t.parent_id,               -- 上级地区ID
			 t.level
from(select     area_id,                              -- 地区ID
                area_name,                            -- 地区名称
	            ancestors,                            -- 地区路径
	            parent_id,                             -- 上级地区ID
				level,
				row_number()over(partition by area_id order by update_time desc) rn
    from dw_nd.ods_t_sys_area
	where area_name != '莱西市'                   -- 去除青岛市
	) t
where t.rn = 1
;
commit;	
 
			
-- 清空行政区划维表数据
delete from dw_base.dim_area_info;

commit;

-- 插入行政区划维表数据
insert into dw_base.dim_area_info(
            day_id,           -- 数据日期
            area_cd,          -- 行政编码
            area_name,        -- 行政名称
            area_lvl,         -- 级别
            area_url,         -- 路径
            sup_area_cd,      -- 上级行政编码
            sup_area_name     -- 上级行政名称
)
select      '${v_sdate}',                       -- 数据日期
             a.area_id,                         -- 行政编码
             a.area_name,                       -- 行政名称
	         a.area_lvl,              			-- 级别 -- mdy 20220517 wyx
	         a.ancestors,                       -- 路径
	         a.parent_id,                       -- 上级行政编码
	         b.area_name as sup_area_name       -- 上级行政名称
from dw_base.tmp_dim_area_info a                
left join dw_base.tmp_dim_area_info b           
on a.parent_id=b.area_id                        
order by a.area_id;

commit;
