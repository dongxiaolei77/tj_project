-- ---------------------------------------
-- 开发人   :  Wangyx
-- 开发时间 ： 20220519
-- 目标表   ： dim_bank_info 银行部门表
-- 源表     ： ods_t_sys_dept 部门表
-- ---------------------------------------


-- 创建临时表，获取银行数据

drop table if exists dw_tmp.tmp_dim_bank_info ; commit;

CREATE TABLE dw_tmp.tmp_dim_bank_info (
  `bank_id` varchar(64)  COMMENT '部门id',
  `bank_name` varchar(200)  COMMENT '部门名称',
  `parent_id` varchar(64)   COMMENT '父部门id',
  `ancestors` varchar(2000) COMMENT '祖级列表',
  `bank_type_cd` varchar(60)  COMMENT '银行类型编码',
  `order_num` int COMMENT '显示顺序',
  `leaf` int  COMMENT '是否叶子',
  `level` int  COMMENT '层级',
   KEY idx_tmp_dim_bank_info_bank_id (`bank_id`)
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin
;commit;

insert into dw_tmp.tmp_dim_bank_info
(
bank_id
,bank_name
,parent_id
,ancestors
,bank_type_cd
,order_num
,leaf
,level
)
select
 dept_id
,dept_name
,parent_id
,ancestors
,case when ancestors like '0,002,%'
	  then SUBSTRING_INDEX(SUBSTRING_INDEX(ancestors,',',3),',',-1)
	  else dept_id
	  end bank_type_cd
,order_num
,leaf
,level
from (
	select
	 dept_id
	,parent_id
	,ancestors
	,dept_name
	,order_num
	,leaf
	,level
	from 
	(select
		 dept_id
		,parent_id
		,ancestors
		,dept_name
		,order_num
		,leaf
		,level
		,row_number()over(partition by dept_id order by update_time desc) rn
		from dw_nd.ods_t_sys_dept
	) t
	where t.rn = 1
) t1
-- where (ancestors like '0,002%' or dept_id = '002') and dept_name not in ('鲁担数科','鲁担数科战略发展部')
;commit;


delete from dw_base.dim_bank_info ;
commit;

insert into dw_base.dim_bank_info
(
day_id
,bank_id
,bank_name
,parent_id
,parent_name
,ancestors
,bank_type_cd
,bank_type_name
,order_num
,leaf
,level
)
select
'${v_sdate}'
,t1.bank_id
,t1.bank_name
,t1.parent_id
,t2.bank_name as parent_name
,t1.ancestors
,case when t3.bank_name like'%农村商业%' then 'e8a8c9bf-a836-4245-9695-ad49e055e78f'
when t3.bank_name like'%村镇银行%' then 'ddsdsdsd-sdsdsdsd-sdsdsdsd'
when t3.bank_name like'%齐鲁银行%' then 'c7ce53c0-4238-4b08-aa8b-42a527059233'
else t1.bank_type_cd end as bank_type_cd
,case when t3.bank_name like'%农村商业%' then '农村商业银行'
when t3.bank_name like'%村镇银行%' then '村镇银行'
when t3.bank_name like'%齐鲁银行%' then '齐鲁银行股份有限公司'
else t3.bank_name end as bank_type_name
,t1.order_num
,t1.leaf
,t1.level
from
dw_tmp.tmp_dim_bank_info t1
left join dw_tmp.tmp_dim_bank_info t2
on t1.parent_id = t2.bank_id
left join dw_tmp.tmp_dim_bank_info t3
on t1.bank_type_cd = t3.bank_id
;commit;