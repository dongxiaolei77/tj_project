-- ---------------------------------------
-- 开发人   : wln
-- 开发时间 ：20220401
-- 目标表   ：dw_base.dwd_guar_tag
-- 源表     ：dw_base.dwd_guar_info_stat
--            dw_nd.ods_t_biz_proj_xz
--            dw_nd.ods_t_biz_proj_loan_check
-- 变更记录 ：20220909 update_time替换为db_update_time wyx
--            20240515 优化逻辑 zhangfl
-- ---------------------------------------
drop table if exists dw_tmp.tmp_guar_tag_tmp00;
commit;
create table if not exists dw_tmp.tmp_guar_tag_tmp00 
(
code	     varchar(50)
,code_xz     varchar(50)
,code_zzxz   varchar(50)
,index idx_tmp_guar_tag_tmp00_code( code )
) 
ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit ;

insert into dw_tmp.tmp_guar_tag_tmp00
(
code
,code_xz
,code_zzxz
)
select 
a.code             -- 进件项目编号
,b.CODE code_xz     -- 续支项目编号
,c.CODE code_zzxz   -- 自主续支项目编号
from 
(
  select CODE,id,guar_product from (
  select CODE,id,guar_product
  ,row_number() over(partition by id order by update_time desc) as rk
  from dw_nd.ods_t_biz_project_main 
  where code is not null 
  )a
  where rk = 1
)a
left join 
( 
	select CODE,project_id from (
  select CODE,project_id,id
  ,row_number()over(partition by id order by db_update_time desc,update_time desc) as rk
   from dw_nd.ods_t_biz_proj_xz 
  where wf_inst_id is not null 
  -- order by db_update_time desc,update_time desc -- mdy 20220909
  )a
  -- group by id
  where rk = 1
)b -- 续支
on a.id = b.project_Id
left join 
(
	select CODE,project_id from (
  select CODE,project_id,id
  ,row_number() over(partition by id order by db_update_time desc) as rk
  from dw_nd.ods_t_biz_proj_loan_check
  where wf_inst_id is not null 
  )a
  where rk = 1
)c -- 自主续支
on a.id = c.project_Id
;
commit;

drop table if exists dw_tmp.tmp_guar_tag_tmp01;
commit;
create table if not exists dw_tmp.tmp_guar_tag_tmp01 
(
cert_no	       varchar(50)
,city_code	   varchar(20)
,country_code  varchar(20)
,guar_code	   varchar(20)
,econ_code	   varchar(20)
,prod_code	   varchar(20)
,item_stt_code varchar(20)
,term	       varchar(20)
,loan_star_dt  varchar(8)
,loan_end_dt   varchar(8)
,loan_reg_dt   varchar(8)
,appl_amt	   decimal(18,2)
,loan_amt	   decimal(18,2)
,grant_amt	   decimal(18,2)
,guar_id	   varchar(50)
,project_id	   varchar(50)
,index idx_tmp_guar_tag_tmp01( cert_no,project_id )
) 
ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit ;


INSERT INTO dw_tmp.tmp_guar_tag_tmp01
(
cert_no	      
,city_code	  
,country_code 
,guar_code	  
,econ_code	  
,prod_code	  
,item_stt_code
,term	        
,loan_star_dt 
,loan_end_dt  
,loan_reg_dt  
,appl_amt	    
,loan_amt	    
,grant_amt	  
,guar_id	    
,project_id	  
)
select a.cert_no
       ,a.city_code     -- 地市
	   ,a.country_code  -- 县区
	   ,a.guar_code     -- 农担分类
	   ,a.econ_code     -- 国民经济分类
	   ,a.prod_code     -- 产品
	   ,a.item_stt_code -- 项目状态
	   ,a.term          -- 贷款合同期数
	   ,a.loan_star_dt  -- 贷款开始时间
	   ,a.loan_end_dt   -- 贷款结束时间
	   ,a.loan_reg_dt   -- 放款登记时间
	   ,a.appl_amt      -- 申请金额
	   ,a.loan_amt      -- 贷款金额
	   ,a.grant_amt     -- 放款金额
	   ,a.guar_id       -- 项目编号
		 ,case when a.guar_id like '%SDAGWF%XZ%'  then substr(a.guar_id,1,15)
		       when b.code is not null then b.code
		       when c.code is not null then c.code
					 when d.code is not null then d.code
					 else a.guar_id end project_id
					 
from dw_base.dwd_guar_info_stat a
left join
(
select * from dw_tmp.tmp_guar_tag_tmp00 
where code is not null 
)b
on a.guar_id = b.code
left join 
(
select * from dw_tmp.tmp_guar_tag_tmp00 
where code_xz is not null 
)c
on a.guar_id = c.code_xz
left join 
(
select * from dw_tmp.tmp_guar_tag_tmp00 
where code_zzxz is not null 
)d
on a.guar_id = d.code_zzxz
where a.item_stt_code in ('06','11','12')  -- 已放款 已解保 已代偿
;
commit;


-- dw_tmp.tmp_guar_tag_tmp01去重
drop table if exists dw_tmp.tmp_guar_tag_tmp01_qc;
commit;
create table if not exists dw_tmp.tmp_guar_tag_tmp01_qc 
(
cert_no	       varchar(50)
,city_code	   varchar(20)
,country_code  varchar(20)
,guar_code	   varchar(20)
,econ_code	   varchar(20)
,prod_code	   varchar(20)
,item_stt_code varchar(20)
,term	       varchar(20)
,loan_star_dt  varchar(8)
,loan_end_dt   varchar(8)
,loan_reg_dt   varchar(8)
,appl_amt	   decimal(18,2)
,loan_amt	   decimal(18,2)
,grant_amt	   decimal(18,2)
,guar_id	   varchar(50)
,project_id	   varchar(50)
,index idx_tmp_guar_tag_tmp01_qc( cert_no,project_id )
,index idx_tmp_guar_tag_tmp01_qc_guar_id(guar_id)
) 
ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit ;

INSERT INTO dw_tmp.tmp_guar_tag_tmp01_qc
(
cert_no	      
,city_code	  
,country_code 
,guar_code	  
,econ_code	  
,prod_code	  
,item_stt_code
,term	        
,loan_star_dt 
,loan_end_dt  
,loan_reg_dt  
,appl_amt	    
,loan_amt	    
,grant_amt	  
,guar_id	    
,project_id	  
)
select a.cert_no
       ,a.city_code     -- 地市
	   ,a.country_code  -- 县区
	   ,a.guar_code     -- 农担分类
	   ,a.econ_code     -- 国民经济分类
	   ,a.prod_code     -- 产品
	   ,a.item_stt_code -- 项目状态
	   ,a.term          -- 贷款合同期数
	   ,a.loan_star_dt  -- 贷款开始时间
	   ,a.loan_end_dt   -- 贷款结束时间
	   ,a.loan_reg_dt   -- 放款登记时间
	   ,a.appl_amt      -- 申请金额
	   ,a.loan_amt      -- 贷款金额
	   ,a.grant_amt     -- 放款金额
	   ,a.guar_id       -- 项目编号
	   ,a.project_id
from 
(
select
a.cert_no
       ,a.city_code     -- 地市
	   ,a.country_code  -- 县区
	   ,a.guar_code     -- 农担分类
	   ,a.econ_code     -- 国民经济分类
	   ,a.prod_code     -- 产品
	   ,a.item_stt_code -- 项目状态
	   ,a.term          -- 贷款合同期数
	   ,a.loan_star_dt  -- 贷款开始时间
	   ,a.loan_end_dt   -- 贷款结束时间
	   ,a.loan_reg_dt   -- 放款登记时间
	   ,a.appl_amt      -- 申请金额
	   ,a.loan_amt      -- 贷款金额
	   ,a.grant_amt     -- 放款金额
	   ,a.guar_id       -- 项目编号
	   ,a.project_id
	   ,row_number() over(partition by guar_id order by project_id desc) as rk
from dw_tmp.tmp_guar_tag_tmp01 a
)a
where rk = 1
;
commit;

-- 首保合同号
drop table if exists dw_tmp.tmp_guar_tag_tmp02;
commit;
create table if not exists dw_tmp.tmp_guar_tag_tmp02 
(
cert_no	       varchar(50)
,project_id	   varchar(50)
,loan_reg_dt   varchar(8)
,index idx_tmp_guar_tag_tmp02( cert_no,project_id )
) 
ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit ;
insert into dw_tmp.tmp_guar_tag_tmp02
(
cert_no	    
,project_id	
,loan_reg_dt
)
select cert_no
       ,project_id
	   ,loan_reg_dt
from 
(
    select cert_no
           ,project_id
    	   ,loan_reg_dt
    	   ,row_number() over(partition by cert_no order by loan_reg_dt asc) as rk
    from 
    (
        select cert_no
               ,project_id
        	   ,loan_reg_dt
        	   ,row_number() over(partition by cert_no,project_id order by loan_reg_dt asc) as rk
        from dw_tmp.tmp_guar_tag_tmp01_qc
        where loan_reg_dt <> ''
        and project_id <> ''
    )a
	where rk = 1
)a
where rk = 1
;
commit;

-- 续保合同号及对应的首次放款时间
drop table if exists dw_tmp.tmp_guar_tag_tmp03;
commit;
create table if not exists dw_tmp.tmp_guar_tag_tmp03 
(
cert_no	       varchar(50)
,project_id	   varchar(50)
,loan_reg_dt   varchar(8)
,index idx_tmp_guar_tag_tmp03( cert_no,project_id )
) 
ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit ;
insert into dw_tmp.tmp_guar_tag_tmp03 
(
cert_no	    
,project_id	
,loan_reg_dt
)
select a.cert_no
       ,a.project_id
	   ,a.loan_reg_dt 
from 
(
    select a.cert_no
           ,a.project_id
    	   ,a.loan_reg_dt 
    	   ,row_number() over(partition by cert_no,project_id order by loan_reg_dt asc) as rk
    from 
	(
        select a.cert_no
               ,a.project_id
        	   ,a.loan_reg_dt
        from dw_tmp.tmp_guar_tag_tmp01_qc a
        left join dw_tmp.tmp_guar_tag_tmp02 b
        on a.cert_no = b.cert_no
        and a.project_id = b.project_id
        where b.project_id is null 
        and a.loan_reg_dt <> ''
        and a.project_id <> ''
    )a
)a
where rk = 1
;
commit;

-- 首保的首次放款和续支区分 
drop table if exists dw_tmp.tmp_guar_tag_tmp04;
commit;
create table if not exists dw_tmp.tmp_guar_tag_tmp04 
(
cert_no	       varchar(50)
,project_id	   varchar(50)
,loan_reg_dt   varchar(8)
,guar_id       varchar(50)
,is_xz         varchar(50)
,index idx_tmp_guar_tag_tmp04( cert_no,project_id )
) 
ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit ;
insert into dw_tmp.tmp_guar_tag_tmp04 
(
cert_no	      
,project_id	  
,loan_reg_dt  
,guar_id      
,is_xz        
)
SELECT a.cert_no
       ,a.project_id
	   ,a.loan_reg_dt
		 ,a.guar_id
       ,case when b.cert_no is not null and a.guar_id not like '%XZ%'  and a.guar_id not like '%BHJC%' -- add %BHJC% 20240515
	         then '0' -- 首次放款
			 else '1'  -- 续支
	    end is_xz
from dw_tmp.tmp_guar_tag_tmp01_qc a
left join dw_tmp.tmp_guar_tag_tmp02 b 
on a.cert_no = b.cert_no
and a.project_id = b.project_id
and a.loan_reg_dt = b.loan_reg_dt
and b.project_id <> ''
and b.loan_reg_dt <> ''
where a.loan_reg_dt <> ''
and a.project_id <> ''
and a.project_id in (select project_id from dw_tmp.tmp_guar_tag_tmp02
                     where project_id <> ''
					)
;
commit;

-- 续保的首次放款和续支
drop table if exists dw_tmp.tmp_guar_tag_tmp05;
commit;
create table if not exists dw_tmp.tmp_guar_tag_tmp05 
(
cert_no	       varchar(50)
,project_id	   varchar(50)
,loan_reg_dt   varchar(8)
,guar_id       varchar(50)
,is_xz         varchar(50)
,index idx_tmp_guar_tag_tmp05( cert_no,project_id )
) 
ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit ;
insert into dw_tmp.tmp_guar_tag_tmp05 
(
cert_no	      
,project_id	  
,loan_reg_dt  
,guar_id      
,is_xz        
)
SELECT a.cert_no
       ,a.project_id
	   ,a.loan_reg_dt
		 ,a.guar_id 
       ,case when b.cert_no is not null and a.guar_id not like '%XZ%'  and a.guar_id not like '%BHJC%' -- add %BHJC% 20240515
	         then '0'  -- 首次放款
			 else '1'  -- 续支
	    end is_xz
from dw_tmp.tmp_guar_tag_tmp01_qc a
left join dw_tmp.tmp_guar_tag_tmp03 b 
on a.cert_no = b.cert_no
and a.project_id = b.project_id
and a.loan_reg_dt = b.loan_reg_dt
and b.loan_reg_dt <> ''
and b.project_id <> ''
where a.loan_reg_dt  <>''
and a.project_id <> ''
and a.project_id in (select project_id from dw_tmp.tmp_guar_tag_tmp03
                     where project_id <>''
					)
;
commit;

-- 插入全量数据
truncate table dw_base.dwd_guar_tag;

commit;

INSERT INTO dw_base.dwd_guar_tag
(
day_id
,guar_id	   
,project_id	 
,cert_no	     
,city_code	 
,country_code
,guar_code	 
,econ_code	 
,prod_code	 
,item_stt_code
,term	       
,loan_star_dt
,loan_end_dt 
,loan_reg_dt 
,appl_amt	   
,loan_amt	   
,grant_amt	 
,is_first_guar       
,is_xz       
)
select '${v_sdate}'
       ,a.guar_id       -- 项目编号
       ,a.project_id    -- 上一级项目编号
	   ,a.cert_no
       ,a.city_code     -- 地市
	   ,a.country_code  -- 县区
	   ,a.guar_code     -- 农担分类
	   ,a.econ_code     -- 国民经济分类
	   ,a.prod_code     -- 产品
	   ,a.item_stt_code -- 项目状态
	   ,a.term          -- 贷款合同期数
	   ,a.loan_star_dt  -- 贷款开始时间
	   ,a.loan_end_dt   -- 贷款结束时间
	   ,a.loan_reg_dt   -- 放款登记时间
	   ,a.appl_amt      -- 申请金额
	   ,a.loan_amt      -- 贷款金额
	   ,a.grant_amt     -- 放款金额
	   	   
       ,case when b.project_id is not null then '0'  -- 首保
		     when c.project_id is not null then '1'  -- 续保
		     else ''
		end is_first_guar   -- 首保/续保
       ,case when b.project_id is not null then d.is_xz
		     when c.project_id is not null then e.is_xz
		     else ''
		end is_xz  -- 首次放款/续支
from dw_tmp.tmp_guar_tag_tmp01_qc a
left join dw_tmp.tmp_guar_tag_tmp02 b
on a.cert_no = b.cert_no
and a.project_id = b.project_id
left join dw_tmp.tmp_guar_tag_tmp03 c
on a.cert_no = c.cert_no
and a.project_id = c.project_id
left join dw_tmp.tmp_guar_tag_tmp04 d
on a.cert_no = d.cert_no
and a.project_id = d.project_id
and a.guar_id = d.guar_id
left join dw_tmp.tmp_guar_tag_tmp05 e
on a.cert_no = e.cert_no
and a.project_id = e.project_id
and a.guar_id = e.guar_id
;
commit;
