-- ---------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20230820
-- 目标表   ：ads_tjnd_guar_busi_dimension_stat
-- 源表     ：dw_base.dwd_tjnd_report_proj_base_info         -- 项目信息汇总表
--            dw_base.dwd_tjnd_report_proj_unguar_info           --  解保记录表
--            dw_base.dwd_tjnd_report_proj_comp_info         -- 代偿
--           dw_base.dwd_tjnd_report_proj_loan_rec_info      -- 放款
-- 备注     ：zzy 由原来的根据dw_base.dwd_tjnd_data_report_guar_tag开发，改成根据国农担上报项目表开发   ； 原来的旧逻辑   放到最底下了
-- 变更记录 ：

-- ---------------------------------------


-- 单户下保证合同金额表

-- drop table if exists dw_base.ads_biz_proj_cust_gtee_max_amt;
-- create table if not exists dw_base.ads_biz_proj_cust_gtee_max_amt(
--     proj_no_prov varchar(50) comment '项目编号',
--     cust_cert_no varchar(50) comment '项目主体证件号码',
-- 	is_onguar     varchar(50) comment '是否在保：1-是，0-否,99-删除的数据',
--     gtee_cont_max_amt decimal(18,2) comment '单户下保证合同金额最大值',
-- 	day_id varchar(50)
-- )
-- comment '单户下保证合同金额最大值信息表';
 


delete from dw_base.ads_biz_proj_cust_gtee_max_amt where day_id = '${v_sdate}';
commit;

insert into  dw_base.ads_biz_proj_cust_gtee_max_amt 
(
 proj_no_prov           -- '项目编号',
,cust_cert_no            -- '项目主体证件号码',
,is_onguar               -- '是否在保：1-是，0-否,99-删除的数据'
,gtee_cont_max_amt       -- '单户下保证合同金额最大值'  
,day_id                        
)
select coalesce(t1.proj_no_prov,t2.proj_no_prov) as proj_no_prov
      ,case when t1.proj_no_prov is null then t2.cust_cert_no else t1.cust_cert_no end as cust_cert_no
	  ,case when t1.proj_no_prov is null then '99'            else t1.is_onguar    end as is_onguar
	  ,case when t1.proj_no_prov is null then t2.gtee_cont_max_amt
	        when t1.is_onguar = '0' then coalesce(t2.gtee_cont_max_amt,t1.gtee_cont_amt) 
			else greatest(coalesce(t1.gtee_cont_max_amt,0),coalesce(t2.gtee_cont_max_amt,0))  end as gtee_cont_max_amt
	  ,'${v_sdate}' as day_id
from (                                                         -- 【当天数据】
       select  a1.proj_no_prov          
              ,a1.cust_cert_no        -- 项目主体证件号码
              ,a1.gtee_cont_amt * 10000 as gtee_cont_amt		  -- 保证合同金额	  
              ,case when a1.proj_stt_cd in ('01','02','03') then '1' else '0' end as is_onguar		  -- 项目状态（01-正常在保、02-预警在保、03-逾期在保）为在保
              ,sum(case when a1.proj_stt_cd in ('01','02','03') and a2.rn = 1 then a1.gtee_cont_amt * 10000 else 0 end) over(partition by a1.cust_cert_no) as gtee_cont_max_amt        -- [按'项目主体证件号码'开窗分组，取当前在保的保证合同金额的合计]
       from dw_base.dwd_tjnd_report_proj_base_info a1        -- 项目信息汇总表 
	   left join (
	              select proj_no_prov
				        ,row_number() over (partition by cust_cert_no,loan_cont_no order by gtee_cont_amt desc) as rn   -- [单户名下的所有在保项目保证合同金额合计（同一借款合同号对应的【保证合同金额】只计算一次）]
	              from dw_base.dwd_tjnd_report_proj_base_info         -- 项目信息汇总表
	              where day_id = '${v_sdate}' and proj_stt_cd in ('01','02','03') 
				 ) a2
	   on a1.proj_no_prov = a2.proj_no_prov
       where a1.day_id = '${v_sdate}'
	 ) t1 
left join (                                                   -- 【前一天的状态】
            select  proj_no_prov    
			       ,cust_cert_no  
                   ,is_onguar				   
			       ,gtee_cont_max_amt			   
			from dw_base.ads_biz_proj_cust_gtee_max_amt
			where day_id = date_format(DATE_SUB('${v_sdate}', INTERVAL 1 DAY),'%Y%m%d')
		  ) t2
on t1.proj_no_prov = t2.proj_no_prov
;
commit;


-- 创建临时表存储主要数据
drop table if exists dw_tmp.tmp_ads_tjnd_guar_busi_dimension_stat_main;
commit;
create table if not exists dw_tmp.tmp_ads_tjnd_guar_busi_dimension_stat_main(
    proj_no_prov  varchar(50) comment '项目编号',
    is_policy_biz varchar(50) comment '是否政策性',
	unguar_reg_dt date        comment '项目解保日期',
    on_guared_dt  date        comment '计入在保日期',
	proj_stt_cd   varchar(50) comment '项目状态',
	proj_onguar_amt_totl  decimal(18,2) comment '项目在保余额',
	year_guar_amt         decimal(18,2) comment '本年新增担保金额',
	year_unguar_amt       decimal(18,2) comment '本年新增解保金额',
	year_comp_amt         decimal(18,2) comment '本年新增代偿金额',
	month_guar_amt	      decimal(18,2) comment '本月新增担保金额',
	proj_blog_busntp_no_nacga  varchar(50) comment '项目所属行业代码（农担体系）',
	loan_period           varchar(50) comment '借款合同期限',
	proj_main_typ_cd      varchar(50) comment '项目主体类型代码'
)
comment '项目粒度分类表';
commit;
-- 担保金额 least(sum(放款金额)，保证合同额度 )
insert into dw_tmp.tmp_ads_tjnd_guar_busi_dimension_stat_main

                  select  t1.proj_no_prov           -- 农担体系担保项目编号		
				         ,t1.is_policy_biz          -- 是否政策性
						 ,t2.unguar_reg_dt          -- 解保登记日期	
                         ,t1.on_guared_dt   -- 计入在保日期	
                         ,t1.proj_stt_cd	 -- 项目状态		
                         ,t1.proj_onguar_amt_totl * 10000  as  proj_onguar_amt_totl  -- 项目在保余额						  
						 ,case when year(t1.on_guared_dt) = left('${v_sdate}',4) then t4.loan_amt else 0 end as  year_guar_amt        -- 本年新增担保金额   [计入在保日期在本年的业务的放款金额累加]
						 ,case when t1.proj_stt_cd in ('04','05') and t2.year_unguar_amt > 0  and t1.proj_no_prov  like 'TJ%' then coalesce(t4.loan_amt,0) - coalesce(t5.ly_accu_rpmt_amt,0) 
						       when t1.proj_stt_cd in ('04','05') then t2.year_unguar_amt
                               else 0 end                 as  year_unguar_amt	                      -- 本年新增解保金额   [本年已经解保的项目的本年解保金额减去这笔项目之前还款的金额]
                         ,t3.year_comp_amt	                                    -- 本年新增代偿金额
						 ,case when DATE_FORMAT(t1.on_guared_dt, '%Y%m')  = left('${v_sdate}',6) then t4.loan_amt else 0 end as  month_guar_amt            -- 本月新增担保金额   [计入在保日期在本月的业务的放款金额累加]
						 ,case when t1.dict_flag = '1' and t1.proj_blog_busntp_no_nacga = '02' then '02'
                               when t1.dict_flag = '1' and t1.proj_blog_busntp_no_nacga = '08' then '09'
                               when t1.dict_flag = '1' and t1.proj_blog_busntp_no_nacga = '01' then '01'
                               when t1.dict_flag = '1' and t1.proj_blog_busntp_no_nacga = '07' then '08'
                               when t1.dict_flag = '1' and t1.proj_blog_busntp_no_nacga = '10' then '02'
                               when t1.dict_flag = '1' and t1.proj_blog_busntp_no_nacga = '11' then '99'
                               when t1.dict_flag = '1' and t1.proj_blog_busntp_no_nacga = '09' then '10'
                               when t1.dict_flag = '1' and t1.proj_blog_busntp_no_nacga = '06' then '06'
                               when t1.dict_flag = '1' and t1.proj_blog_busntp_no_nacga = '05' then '05'
                               when t1.dict_flag = '1' and t1.proj_blog_busntp_no_nacga = '03' then '03'
                               when t1.dict_flag = '1' and t1.proj_blog_busntp_no_nacga = '04' then '04'
                               when t1.dict_flag = '1' and t1.proj_blog_busntp_no_nacga = '12' then '07'
                               else t1.proj_blog_busntp_no_nacga
						       end as proj_blog_busntp_no_nacga -- '项目所属行业代码（农担体系）',
						 ,t1.loan_period                   -- '借款合同期限',
						 ,t1.proj_main_typ_cd              -- '项目主体类型代码'
			       from dw_base.dwd_tjnd_report_proj_base_info	 t1          -- 【项目信息汇总表】
				   left join (                                             
                              select proj_no_prov                                                     -- 农担体系担保项目编号
							        ,max(unguar_dt)     as unguar_dt                                      -- 解保日期             [多条记录分组取最近日期]
									,max(unguar_reg_dt) as unguar_reg_dt                                  -- 解保登记日期         [多条记录分组取最近日期]
                                    ,sum(case when year(unguar_reg_dt) = left('${v_sdate}',4) then unguar_amt else 0 end) as  year_unguar_amt       --	本年新增解保金额     [sum(解保金额) where 解保登记日期=本年]
                              from dw_base.dwd_tjnd_report_proj_unguar_info           --  解保记录表
                  	          where day_id = '${v_sdate}'                                                              
                              group by proj_no_prov
                  		     )                                   t2           --	【解保】  
				   on t1.proj_no_prov = t2.proj_no_prov
				   left join (
				               select proj_no_prov
                                     ,sum(case when year(comp_pmt_dt) = left('${v_sdate}',4) then comp_pmt_amt else 0 end) as year_comp_amt	  -- 本年新增代偿金额        [sum(代偿拨付金额)  where 代偿拨付日期=本年]
							   from dw_base.dwd_tjnd_report_proj_comp_info 
							   where day_id = '${v_sdate}'                                                              
                               group by proj_no_prov
							 )                                  t3           --     【代偿】
				   on t1.proj_no_prov = t3.proj_no_prov
				   left join (
				               select proj_no_prov
							         ,sum(loan_amt) * 10000      as loan_amt  -- 放款金额
							   from dw_base.dwd_tjnd_report_proj_loan_rec_info       
							   where day_id = '${v_sdate}'                                                              
                               group by proj_no_prov
							 )                                  t4           --     【放款】
				   on t1.proj_no_prov = t4.proj_no_prov
				   left join (
				               select proj_no_prov
							         ,sum(case when year(rpmt_reg_dt) < left('${v_sdate}',4) then rpmt_prin_amt * 10000 else 0 end) as ly_accu_rpmt_amt  -- 截止到上年末的累计还款金额（元）     [sum(还款本金金额) where 还款登记日期 < 本年]
							   from dw_base.dwd_tjnd_report_proj_rpmt_info      -- 还款记录
							   where day_id = '${v_sdate}'                                                              
                               group by proj_no_prov
							 )                                  t5          --      【还款】
				   on t1.proj_no_prov = t5.proj_no_prov	
                   where t1.day_id = '${v_sdate}'  and '${v_sdate}' = date_format(last_day('${v_sdate}'),'%Y%m%d') -- 月底跑批
;
commit;

delete from dw_base.ads_tjnd_guar_busi_dimension_stat where day_id = '${v_sdate}';
commit;
-- 插入数据
-- 1.按照政策性划分
insert into dw_base.ads_tjnd_guar_busi_dimension_stat
( day_id            -- 数据日期
 ,divid_method      -- 划分方式
 ,class_type_code   -- 分类小项code
 ,class_type_name   -- 分类小项名称
 ,guar_amt          -- 在保余额（万元）
 ,guar_qty          -- 在保项目数
 ,year_guar_amt     -- 本年新增担保金额（万元）
 ,year_guar_qty     -- 本年新增担保项目数
 ,year_unguar_amt   -- 本年累计解保金额（万元）
 ,year_unguar_qty   -- 本年累计解保项目数
 ,year_comp_amt     -- 本年累计代偿金额（万元）
 ,year_comp_qty     -- 本年累计代偿项目数
 ,month_guar_amt    -- 本月新增担保金额（万元）
 ,month_guar_qty    -- 本月新增担保项目数
 )
select '${v_sdate}'     as day_id
       ,'按政策性划分'   as divid_method
	   ,'1'                     as class_type_code   -- 分类小项code
       ,'其中：  政策性业务情况' as class_type_name   -- 分类小项名称
       ,sum(proj_onguar_amt_totl) / 10000                 as guar_amt          -- 在保余额（万元）
       ,count(if(proj_stt_cd in ('01','02','03'),1,null)) as guar_qty          -- 在保项目数
       ,sum(year_guar_amt) / 10000 as year_guar_amt     -- 本年新增担保金额（万元）
       ,count(if(substr('${v_sdate}',1,4) = year(on_guared_dt),1,null)) as year_guar_qty     -- 本年新增担保项目数                [计入在保日期在本年的业务的笔数累加]
       ,sum(year_unguar_amt) / 10000 as year_unguar_amt   -- 本年累计解保金额（万元）
       ,count(if(proj_stt_cd in ('04','05') and year_unguar_amt > 0,1,null)) as    year_unguar_qty   -- 本年累计解保项目数     [项目系统为正常解保/代偿解保且解保登记日期在本年的业务累加]
       ,sum(year_comp_amt) / 10000 as year_comp_amt     -- 本年累计代偿金额（万元）
       ,count(if(year_comp_amt > 0,1,null)) as year_comp_qty     -- 本年累计代偿项目数  [ 计数（代偿拨付日期在本年的代偿拨付金额>0的项目数）]
       ,sum(month_guar_amt) / 10000 as month_guar_amt    -- 本月新增担保金额（万元）
       ,count(if(substr('${v_sdate}',1,6) = date_format(on_guared_dt,'%Y%m'),1,null)) as month_guar_qty    -- 本月新增担保项目数	   [计入在保日期在本月的业务的笔数累加]
from (   
       select proj_no_prov          -- '项目编号',
             ,is_policy_biz         -- '是否政策性',
	         ,unguar_reg_dt         -- '解保登记日期',
             ,on_guared_dt          -- '计入在保日期',
	         ,proj_stt_cd           -- '项目状态',
	         ,proj_onguar_amt_totl  -- '项目在保余额',
	         ,year_guar_amt         -- '本年新增担保金额',
	         ,year_unguar_amt       -- '本年新增解保金额',
	         ,year_comp_amt         -- '本年新增代偿金额',
	         ,month_guar_amt	    -- '本月新增担保金额'
			 ,proj_blog_busntp_no_nacga  -- '项目所属行业代码（农担体系）'
	   from dw_tmp.tmp_ads_tjnd_guar_busi_dimension_stat_main
       where is_policy_biz = '1' and proj_blog_busntp_no_nacga != '99'	-- [是政策性 AND 农业]    
     ) t1
union all 
select '${v_sdate}'     as day_id
       ,'按政策性划分'   as divid_method
	   ,'2'                     as class_type_code   -- 分类小项code
       ,'其中：生猪养殖300-1000万' as class_type_name   -- 分类小项名称
       ,sum(proj_onguar_amt_totl) / 10000                 as guar_amt          -- 在保余额（万元）
       ,count(if(proj_stt_cd in ('01','02','03'),1,null)) as guar_qty          -- 在保项目数
       ,sum(year_guar_amt) / 10000 as year_guar_amt     -- 本年新增担保金额（万元）
       ,count(if(substr('${v_sdate}',1,4) = year(on_guared_dt),1,null)) as year_guar_qty     -- 本年新增担保项目数                [计入在保日期在本年的业务的笔数累加]
       ,sum(year_unguar_amt) / 10000 as year_unguar_amt   -- 本年累计解保金额（万元）
       ,count(if(proj_stt_cd in ('04','05') and year_unguar_amt > 0,1,null)) as    year_unguar_qty   -- 本年累计解保项目数     [项目系统为正常解保/代偿解保且解保登记日期在本年的业务累加]
       ,sum(year_comp_amt) / 10000 as year_comp_amt     -- 本年累计代偿金额（万元）
       ,count(if(year_comp_amt > 0,1,null)) as year_comp_qty     -- 本年累计代偿项目数  [ 计数（代偿拨付日期在本年的代偿拨付金额>0的项目数）]
       ,sum(month_guar_amt) / 10000 as month_guar_amt    -- 本月新增担保金额（万元）
       ,count(if(substr('${v_sdate}',1,6) = date_format(on_guared_dt,'%Y%m'),1,null)) as month_guar_qty    -- 本月新增担保项目数	   [计入在保日期在本月的业务的笔数累加]
from (   
       select a.proj_no_prov          -- '项目编号',
             ,is_policy_biz         -- '是否政策性',
	         ,unguar_reg_dt         -- '解保登记日期',
             ,on_guared_dt          -- '计入在保日期',
	         ,proj_stt_cd           -- '项目状态',
	         ,proj_onguar_amt_totl  -- '项目在保余额',
	         ,year_guar_amt         -- '本年新增担保金额',
	         ,year_unguar_amt       -- '本年新增解保金额',
	         ,year_comp_amt         -- '本年新增代偿金额',
	         ,month_guar_amt	    -- '本月新增担保金额'
			 ,proj_blog_busntp_no_nacga  -- '项目所属行业代码（农担体系）'
	   from dw_tmp.tmp_ads_tjnd_guar_busi_dimension_stat_main a 
	   left join dw_base.ads_biz_proj_cust_gtee_max_amt b
	   on a.proj_no_prov = b.proj_no_prov and b.day_id = '${v_sdate}'
       where is_policy_biz = '0' and 3000000 < b.gtee_cont_max_amt and b.gtee_cont_max_amt <= 10000000 
	     and proj_blog_busntp_no_nacga = '03'  and proj_blog_busntp_no_nacga != '99'	 -- 非政策性 大于300万 and 小于等于1000万	     含猪  AND 农业
     ) t1
union all 
select '${v_sdate}'     as day_id
       ,'按政策性划分'   as divid_method
	   ,'3'                     as class_type_code   -- 分类小项code
       ,'其中：其他政策外双控业务' as class_type_name   -- 分类小项名称
       ,sum(proj_onguar_amt_totl) / 10000                 as guar_amt          -- 在保余额（万元）
       ,count(if(proj_stt_cd in ('01','02','03'),1,null)) as guar_qty          -- 在保项目数
       ,sum(year_guar_amt) / 10000 as year_guar_amt     -- 本年新增担保金额（万元）
       ,count(if(substr('${v_sdate}',1,4) = year(on_guared_dt),1,null)) as year_guar_qty     -- 本年新增担保项目数                [计入在保日期在本年的业务的笔数累加]
       ,sum(year_unguar_amt) / 10000 as year_unguar_amt   -- 本年累计解保金额（万元）
       ,count(if(proj_stt_cd in ('04','05') and year_unguar_amt > 0,1,null)) as    year_unguar_qty   -- 本年累计解保项目数     [项目系统为正常解保/代偿解保且解保登记日期在本年的业务累加]
       ,sum(year_comp_amt) / 10000 as year_comp_amt     -- 本年累计代偿金额（万元）
       ,count(if(year_comp_amt > 0,1,null)) as year_comp_qty     -- 本年累计代偿项目数  [ 计数（代偿拨付日期在本年的代偿拨付金额>0的项目数）]
       ,sum(month_guar_amt) / 10000 as month_guar_amt    -- 本月新增担保金额（万元）
       ,count(if(substr('${v_sdate}',1,6) = date_format(on_guared_dt,'%Y%m'),1,null)) as month_guar_qty    -- 本月新增担保项目数	   [计入在保日期在本月的业务的笔数累加]
from (   
       select a.proj_no_prov          -- '项目编号',
             ,is_policy_biz         -- '是否政策性',
	         ,unguar_reg_dt         -- '解保登记日期',
             ,on_guared_dt          -- '计入在保日期',
	         ,proj_stt_cd           -- '项目状态',
	         ,proj_onguar_amt_totl  -- '项目在保余额',
	         ,year_guar_amt         -- '本年新增担保金额',
	         ,year_unguar_amt       -- '本年新增解保金额',
	         ,year_comp_amt         -- '本年新增代偿金额',
	         ,month_guar_amt	    -- '本月新增担保金额'
			 ,proj_blog_busntp_no_nacga  -- '项目所属行业代码（农担体系）'
	   from dw_tmp.tmp_ads_tjnd_guar_busi_dimension_stat_main a 
	   left join dw_base.ads_biz_proj_cust_gtee_max_amt b
	   on a.proj_no_prov = b.proj_no_prov and b.day_id = '${v_sdate}'
       where (is_policy_biz = '0' and 3000000 < b.gtee_cont_max_amt and b.gtee_cont_max_amt <= 10000000 and proj_blog_busntp_no_nacga != '03' and proj_blog_busntp_no_nacga != '99')	 -- 非政策性 大于300万 and 小于等于1000万	不含猪  AND 农业
	      or (is_policy_biz = '0' and  b.gtee_cont_max_amt <= 3000000 and proj_blog_busntp_no_nacga != '99')  -- 非政策性 小于300万  AND 农业
     ) t1
union all 
select '${v_sdate}'     as day_id
       ,'按政策性划分'   as divid_method
	   ,'4'                     as class_type_code   -- 分类小项code
       ,'其中：“双控”外业务' as class_type_name   -- 分类小项名称
       ,sum(proj_onguar_amt_totl) / 10000                 as guar_amt          -- 在保余额（万元）
       ,count(if(proj_stt_cd in ('01','02','03'),1,null)) as guar_qty          -- 在保项目数
       ,sum(year_guar_amt) / 10000 as year_guar_amt     -- 本年新增担保金额（万元）
       ,count(if(substr('${v_sdate}',1,4) = year(on_guared_dt),1,null)) as year_guar_qty     -- 本年新增担保项目数                [计入在保日期在本年的业务的笔数累加]
       ,sum(year_unguar_amt) / 10000 as year_unguar_amt   -- 本年累计解保金额（万元）
       ,count(if(proj_stt_cd in ('04','05') and year_unguar_amt > 0,1,null)) as    year_unguar_qty   -- 本年累计解保项目数     [项目系统为正常解保/代偿解保且解保登记日期在本年的业务累加]
       ,sum(year_comp_amt) / 10000 as year_comp_amt     -- 本年累计代偿金额（万元）
       ,count(if(year_comp_amt > 0,1,null)) as year_comp_qty     -- 本年累计代偿项目数  [ 计数（代偿拨付日期在本年的代偿拨付金额>0的项目数）]
       ,sum(month_guar_amt) / 10000 as month_guar_amt    -- 本月新增担保金额（万元）
       ,count(if(substr('${v_sdate}',1,6) = date_format(on_guared_dt,'%Y%m'),1,null)) as month_guar_qty    -- 本月新增担保项目数	   [计入在保日期在本月的业务的笔数累加]
from (   
       select a.proj_no_prov          -- '项目编号',
             ,is_policy_biz         -- '是否政策性',
	         ,unguar_reg_dt         -- '解保登记日期',
             ,on_guared_dt          -- '计入在保日期',
	         ,proj_stt_cd           -- '项目状态',
	         ,proj_onguar_amt_totl  -- '项目在保余额',
	         ,year_guar_amt         -- '本年新增担保金额',
	         ,year_unguar_amt       -- '本年新增解保金额',
	         ,year_comp_amt         -- '本年新增代偿金额',
	         ,month_guar_amt	    -- '本月新增担保金额'
			 ,proj_blog_busntp_no_nacga  -- '项目所属行业代码（农担体系）'
	   from dw_tmp.tmp_ads_tjnd_guar_busi_dimension_stat_main a 
	   left join dw_base.ads_biz_proj_cust_gtee_max_amt b
	   on a.proj_no_prov = b.proj_no_prov and b.day_id = '${v_sdate}'
       where (is_policy_biz = '0' and b.gtee_cont_max_amt > 10000000) 	 -- 非政策性  大于1000万	
          or proj_blog_busntp_no_nacga = '99'	                         -- 非农项目   
     ) t1
;
commit; 


-- 2.按行业划分
insert into dw_base.ads_tjnd_guar_busi_dimension_stat
( day_id            -- 数据日期
 ,divid_method      -- 划分方式
 ,class_type_code   -- 分类小项code
 ,class_type_name   -- 分类小项名称
 ,guar_amt          -- 在保余额（万元）
 ,guar_qty          -- 在保项目数
 ,year_guar_amt     -- 本年新增担保金额（万元）
 ,year_guar_qty     -- 本年新增担保项目数
 ,year_unguar_amt   -- 本年累计解保金额（万元）
 ,year_unguar_qty   -- 本年累计解保项目数
 ,year_comp_amt     -- 本年累计代偿金额（万元）
 ,year_comp_qty     -- 本年累计代偿项目数
 ,month_guar_amt    -- 本月新增担保金额（万元）
 ,month_guar_qty    -- 本月新增担保项目数
 )
 select '${v_sdate}'     as day_id
       ,'按行业划分'   as divid_method
	   ,case when proj_blog_busntp_no_nacga = '01' then '1'
	         when proj_blog_busntp_no_nacga = '02' then '2'
	         when proj_blog_busntp_no_nacga = '03' then '3'
	         when proj_blog_busntp_no_nacga = '04' then '4'
	         when proj_blog_busntp_no_nacga = '05' then '5'
	         when proj_blog_busntp_no_nacga = '06' then '6'
	         when proj_blog_busntp_no_nacga = '07' then '7'
	         when proj_blog_busntp_no_nacga = '08' then '8'
	         when proj_blog_busntp_no_nacga = '09' then '9'
	         when proj_blog_busntp_no_nacga = '10' then '10'
	         when proj_blog_busntp_no_nacga = '11' then '11'
	         when proj_blog_busntp_no_nacga = '99' then '12'
	         end  as class_type_code   -- 分类小项code                  
	   ,case when proj_blog_busntp_no_nacga = '01' then	'农林业生产粮食种植'
             when proj_blog_busntp_no_nacga = '02' then	'农林业生产重要特色农产品种植'
             when proj_blog_busntp_no_nacga = '03' then	'畜牧业生产生猪养殖'
             when proj_blog_busntp_no_nacga = '04' then	'畜牧业生产其他畜牧业'
             when proj_blog_busntp_no_nacga = '05' then	'渔业生产'
             when proj_blog_busntp_no_nacga = '06' then	'农田建设'
             when proj_blog_busntp_no_nacga = '07' then	'农资、农机、农技等农业社会化服务'
             when proj_blog_busntp_no_nacga = '08' then	'农产品流通(含农产品收购、仓储保鲜、销售等)'
             when proj_blog_busntp_no_nacga = '09' then	'农产品初加工'
             when proj_blog_busntp_no_nacga = '10' then	'农业新业态'
             when proj_blog_busntp_no_nacga = '11' then	'其他农业项目'
             when proj_blog_busntp_no_nacga = '99' then	'非农项目'
			 end  as class_type_name   -- 分类小项名称
       ,sum(proj_onguar_amt_totl) / 10000                 as guar_amt          -- 在保余额（万元）
       ,count(if(proj_stt_cd in ('01','02','03'),1,null)) as guar_qty          -- 在保项目数
       ,sum(year_guar_amt) / 10000 as year_guar_amt     -- 本年新增担保金额（万元）
       ,count(if(substr('${v_sdate}',1,4) = year(on_guared_dt),1,null)) as year_guar_qty     -- 本年新增担保项目数                [计入在保日期在本年的业务的笔数累加]
       ,sum(year_unguar_amt) / 10000 as year_unguar_amt   -- 本年累计解保金额（万元）
       ,count(if(proj_stt_cd in ('04','05') and year_unguar_amt > 0,1,null)) as    year_unguar_qty   -- 本年累计解保项目数     [项目系统为正常解保/代偿解保且解保登记日期在本年的业务累加]
       ,sum(year_comp_amt) / 10000 as year_comp_amt     -- 本年累计代偿金额（万元）
       ,count(if(year_comp_amt > 0,1,null)) as year_comp_qty     -- 本年累计代偿项目数  [ 计数（代偿拨付日期在本年的代偿拨付金额>0的项目数）]
       ,sum(month_guar_amt) / 10000 as month_guar_amt    -- 本月新增担保金额（万元）
       ,count(if(substr('${v_sdate}',1,6) = date_format(on_guared_dt,'%Y%m'),1,null)) as month_guar_qty    -- 本月新增担保项目数	   [计入在保日期在本月的业务的笔数累加]
from (   
       select proj_no_prov          -- '项目编号',
             ,is_policy_biz         -- '是否政策性',
	         ,unguar_reg_dt         -- '解保登记日期',
             ,on_guared_dt          -- '计入在保日期',
	         ,proj_stt_cd           -- '项目状态',
	         ,proj_onguar_amt_totl  -- '项目在保余额',
	         ,year_guar_amt         -- '本年新增担保金额',
	         ,year_unguar_amt       -- '本年新增解保金额',
	         ,year_comp_amt         -- '本年新增代偿金额',
	         ,month_guar_amt	    -- '本月新增担保金额'
			 ,proj_blog_busntp_no_nacga  -- '项目所属行业代码（农担体系）'
	   from dw_tmp.tmp_ads_tjnd_guar_busi_dimension_stat_main 	      
     ) t2
group by proj_blog_busntp_no_nacga
;
commit;	 
	 
-- 3.按贷款期限划分
insert into dw_base.ads_tjnd_guar_busi_dimension_stat
( day_id            -- 数据日期
 ,divid_method      -- 划分方式
 ,class_type_code   -- 分类小项code
 ,class_type_name   -- 分类小项名称
 ,guar_amt          -- 在保余额（万元）
 ,guar_qty          -- 在保项目数
 ,year_guar_amt     -- 本年新增担保金额（万元）
 ,year_guar_qty     -- 本年新增担保项目数
 ,year_unguar_amt   -- 本年累计解保金额（万元）
 ,year_unguar_qty   -- 本年累计解保项目数
 ,year_comp_amt     -- 本年累计代偿金额（万元）
 ,year_comp_qty     -- 本年累计代偿项目数
 ,month_guar_amt    -- 本月新增担保金额（万元）
 ,month_guar_qty    -- 本月新增担保项目数
 )
select '${v_sdate}' as day_id
       ,'按贷款期限划分' as divid_method	 
	   ,loan_period  as class_type_code   -- 分类小项code                  
	   ,case when loan_period = '1' then '6个月以下'
             when loan_period = '2' then '6(含)-12个月(含)'  
             when loan_period = '3' then '12-36个月(含)'
             when loan_period = '4' then '36个月以上'             
			 end  as class_type_name   -- 分类小项名称
       ,sum(proj_onguar_amt_totl) / 10000                 as guar_amt          -- 在保余额（万元）
       ,count(if(proj_stt_cd in ('01','02','03'),1,null)) as guar_qty          -- 在保项目数
       ,sum(year_guar_amt) / 10000 as year_guar_amt     -- 本年新增担保金额（万元）
       ,count(if(substr('${v_sdate}',1,4) = year(on_guared_dt),1,null)) as year_guar_qty     -- 本年新增担保项目数                [计入在保日期在本年的业务的笔数累加]
       ,sum(year_unguar_amt) / 10000 as year_unguar_amt   -- 本年累计解保金额（万元）
       ,count(if(proj_stt_cd in ('04','05') and year_unguar_amt > 0,1,null)) as    year_unguar_qty   -- 本年累计解保项目数     [项目系统为正常解保/代偿解保且解保登记日期在本年的业务累加]
       ,sum(year_comp_amt) / 10000 as year_comp_amt     -- 本年累计代偿金额（万元）
       ,count(if(year_comp_amt > 0,1,null)) as year_comp_qty     -- 本年累计代偿项目数  [ 计数（代偿拨付日期在本年的代偿拨付金额>0的项目数）]
       ,sum(month_guar_amt) / 10000 as month_guar_amt    -- 本月新增担保金额（万元）
       ,count(if(substr('${v_sdate}',1,6) = date_format(on_guared_dt,'%Y%m'),1,null)) as month_guar_qty    -- 本月新增担保项目数	   [计入在保日期在本月的业务的笔数累加]
from (   
       select proj_no_prov          -- '项目编号',
             ,is_policy_biz         -- '是否政策性',
	         ,unguar_reg_dt         -- '解保登记日期',
             ,on_guared_dt          -- '计入在保日期',
	         ,proj_stt_cd           -- '项目状态',
	         ,proj_onguar_amt_totl  -- '项目在保余额',
	         ,year_guar_amt         -- '本年新增担保金额',
	         ,year_unguar_amt       -- '本年新增解保金额',
	         ,year_comp_amt         -- '本年新增代偿金额',
	         ,month_guar_amt	    -- '本月新增担保金额'
			 ,proj_blog_busntp_no_nacga  -- '项目所属行业代码（农担体系）'
			 ,case when loan_period < 6 then  '1'
	               when loan_period between 6 and 12 or loan_period is null then '2'         -- 为空默认为12个月
	               when loan_period > 12 and loan_period <= 36 then '3'
	               else    '4'
				   end as loan_period
	   from dw_tmp.tmp_ads_tjnd_guar_busi_dimension_stat_main 	       
     ) t3
group by loan_period	 
;
commit;

-- 4.本年新增实际担保期限6个月及以上的项目
insert into dw_base.ads_tjnd_guar_busi_dimension_stat
( day_id            -- 数据日期
 ,divid_method      -- 划分方式
 ,class_type_code   -- 分类小项code
 ,class_type_name   -- 分类小项名称
 ,guar_amt          -- 在保余额（万元）
 ,guar_qty          -- 在保项目数
 ,year_guar_amt     -- 本年新增担保金额（万元）
 ,year_guar_qty     -- 本年新增担保项目数
 ,year_unguar_amt   -- 本年累计解保金额（万元）
 ,year_unguar_qty   -- 本年累计解保项目数
 ,year_comp_amt     -- 本年累计代偿金额（万元）
 ,year_comp_qty     -- 本年累计代偿项目数
 ,month_guar_amt    -- 本月新增担保金额（万元）
 ,month_guar_qty    -- 本月新增担保项目数
 )
select '${v_sdate}' as day_id
       ,'本年新增实际担保期限6个月及以上的项目' as divid_method
       ,'1' as class_type_code
       ,'本年新增实际担保期限6个月及以上的项目' as class_type_name
       ,sum(proj_onguar_amt_totl) / 10000                 as guar_amt          -- 在保余额（万元）
       ,count(if(proj_stt_cd in ('01','02','03'),1,null)) as guar_qty          -- 在保项目数
       ,sum(year_guar_amt) / 10000 as year_guar_amt     -- 本年新增担保金额（万元）
       ,count(if(substr('${v_sdate}',1,4) = year(on_guared_dt),1,null)) as year_guar_qty     -- 本年新增担保项目数                [计入在保日期在本年的业务的笔数累加]
       ,sum(year_unguar_amt) / 10000 as year_unguar_amt   -- 本年累计解保金额（万元）
       ,count(if(proj_stt_cd in ('04','05') and year_unguar_amt > 0,1,null)) as    year_unguar_qty   -- 本年累计解保项目数     [项目系统为正常解保/代偿解保且解保登记日期在本年的业务累加]
       ,sum(year_comp_amt) / 10000 as year_comp_amt     -- 本年累计代偿金额（万元）
       ,count(if(year_comp_amt > 0,1,null)) as year_comp_qty     -- 本年累计代偿项目数  [ 计数（代偿拨付日期在本年的代偿拨付金额>0的项目数）]
       ,sum(month_guar_amt) / 10000 as month_guar_amt    -- 本月新增担保金额（万元）
       ,count(if(substr('${v_sdate}',1,6) = date_format(on_guared_dt,'%Y%m'),1,null)) as month_guar_qty    -- 本月新增担保项目数	   [计入在保日期在本月的业务的笔数累加]
from (   
       select proj_no_prov          -- '项目编号',
             ,is_policy_biz         -- '是否政策性',
	         ,unguar_reg_dt         -- '解保登记日期',
             ,on_guared_dt          -- '计入在保日期',
	         ,proj_stt_cd           -- '项目状态',
	         ,proj_onguar_amt_totl  -- '项目在保余额',
	         ,year_guar_amt         -- '本年新增担保金额',
	         ,year_unguar_amt       -- '本年新增解保金额',
	         ,year_comp_amt         -- '本年新增代偿金额',
	         ,month_guar_amt	    -- '本月新增担保金额'
			 ,proj_blog_busntp_no_nacga  -- '项目所属行业代码（农担体系）'
			 ,loan_period
	   from dw_tmp.tmp_ads_tjnd_guar_busi_dimension_stat_main 
       where loan_period >= 6 and substr('${v_sdate}',1,4) = year(on_guared_dt)	 	    -- [本年新增实际担保期限6个月及以上的项目]
     ) t4	 
;
commit;	 
	 
-- 5.按支持经营主题类型划分
insert into dw_base.ads_tjnd_guar_busi_dimension_stat
( day_id            -- 数据日期
 ,divid_method      -- 划分方式
 ,class_type_code   -- 分类小项code
 ,class_type_name   -- 分类小项名称
 ,guar_amt          -- 在保余额（万元）
 ,guar_qty          -- 在保项目数
 ,year_guar_amt     -- 本年新增担保金额（万元）
 ,year_guar_qty     -- 本年新增担保项目数
 ,year_unguar_amt   -- 本年累计解保金额（万元）
 ,year_unguar_qty   -- 本年累计解保项目数
 ,year_comp_amt     -- 本年累计代偿金额（万元）
 ,year_comp_qty     -- 本年累计代偿项目数
 ,month_guar_amt    -- 本月新增担保金额（万元）
 ,month_guar_qty    -- 本月新增担保项目数
 )
select '${v_sdate}' as day_id
       ,'按支持经营主体类型划分' as divid_method
	   ,case when proj_main_typ_cd = '01' then '1'
	         when proj_main_typ_cd = '02' then '2'
			 when proj_main_typ_cd = '03' then '3'
			 when proj_main_typ_cd = '04' then '4'
			 end as class_type_code   -- 分类小项code
	   ,case when proj_main_typ_cd = '01' then '家庭农场（种养大户）'
	         when proj_main_typ_cd = '02' then '家庭农场'
			 when proj_main_typ_cd = '03' then '农业企业'
			 when proj_main_typ_cd = '04' then '农民专业合作社'
			 end as class_type_name   -- 分类小项名称 
       ,sum(proj_onguar_amt_totl) / 10000                 as guar_amt          -- 在保余额（万元）
       ,count(if(proj_stt_cd in ('01','02','03'),1,null)) as guar_qty          -- 在保项目数
       ,sum(year_guar_amt) / 10000 as year_guar_amt     -- 本年新增担保金额（万元）
       ,count(if(substr('${v_sdate}',1,4) = year(on_guared_dt),1,null)) as year_guar_qty     -- 本年新增担保项目数                [计入在保日期在本年的业务的笔数累加]
       ,sum(year_unguar_amt) / 10000 as year_unguar_amt   -- 本年累计解保金额（万元）
       ,count(if(proj_stt_cd in ('04','05') and year_unguar_amt > 0,1,null)) as    year_unguar_qty   -- 本年累计解保项目数     [项目系统为正常解保/代偿解保且解保登记日期在本年的业务累加]
       ,sum(year_comp_amt) / 10000 as year_comp_amt     -- 本年累计代偿金额（万元）
       ,count(if(year_comp_amt > 0,1,null)) as year_comp_qty     -- 本年累计代偿项目数  [ 计数（代偿拨付日期在本年的代偿拨付金额>0的项目数）]
       ,sum(month_guar_amt) / 10000 as month_guar_amt    -- 本月新增担保金额（万元）
       ,count(if(substr('${v_sdate}',1,6) = date_format(on_guared_dt,'%Y%m'),1,null)) as month_guar_qty    -- 本月新增担保项目数	   [计入在保日期在本月的业务的笔数累加]
from (   
       select proj_no_prov          -- '项目编号',
             ,is_policy_biz         -- '是否政策性',
	         ,unguar_reg_dt         -- '解保登记日期',
             ,on_guared_dt          -- '计入在保日期',
	         ,proj_stt_cd           -- '项目状态',
	         ,proj_onguar_amt_totl  -- '项目在保余额',
	         ,year_guar_amt         -- '本年新增担保金额',
	         ,year_unguar_amt       -- '本年新增解保金额',
	         ,year_comp_amt         -- '本年新增代偿金额',
	         ,month_guar_amt	    -- '本月新增担保金额'
			 ,proj_blog_busntp_no_nacga  -- '项目所属行业代码（农担体系）'
			 ,loan_period
			 ,proj_main_typ_cd
	   from dw_tmp.tmp_ads_tjnd_guar_busi_dimension_stat_main 	      
     ) t4
group by proj_main_typ_cd
;
commit;






--    原来的旧逻辑

--  delete from dw_base.ads_tjnd_guar_busi_dimension_stat where day_id = '${v_sdate}';
--  commit;
--  
--  -- 1.按照政策性划分
--  insert into dw_base.ads_tjnd_guar_busi_dimension_stat
--  ( day_id            -- 数据日期
--   ,divid_method      -- 划分方式
--   ,class_type_code   -- 分类小项code
--   ,class_type_name   -- 分类小项名称
--   ,guar_amt          -- 在保余额（万元）
--   ,guar_qty          -- 在保项目数
--   ,year_guar_amt     -- 本年新增担保金额（万元）
--   ,year_guar_qty     -- 本年新增担保项目数
--   ,year_unguar_amt   -- 本年累计解保金额（万元）
--   ,year_unguar_qty   -- 本年累计解保项目数
--   ,year_comp_amt     -- 本年累计代偿金额（万元）
--   ,year_comp_qty     -- 本年累计代偿项目数
--   ,month_guar_amt    -- 本月新增担保金额（万元）
--   ,month_guar_qty    -- 本月新增担保项目数
--   )
--  select '${v_sdate}' as day_id
--         ,'按政策性划分' as divid_method
--         ,case when t1.policy_type = '政策性业务：[10-300]' then
--                 case when t1.is_add_curryear = '1' and t1.is_unguar_curryear = '1' and t1.loan_term_type <> '6个月以下' then '1'
--                 else '2' end
--               when t1.policy_type = '政策性业务-生猪养殖: (300,1000]' then
--                 case when t1.is_add_curryear = '1' and t1.is_unguar_curryear = '1' and t1.loan_term_type <> '6个月以下' then '3'
--                 else '4' end
--               when t1.policy_type = '政策外“双控”业务：<10 and (300,1000]' then
--                 case when t1.loan_amt < 10 then '5'
--                 else '6' end
--               when t1.policy_type = '“双控”外业务：>1000' then '7'
--             else '8' end as class_type_code
--         ,case when t1.policy_type = '政策性业务：[10-300]' then
--                 case when t1.is_add_curryear = '1' and t1.is_unguar_curryear = '1' and t1.loan_term_type <> '6个月以下' then '其中：1.本年新增当年解保且实际担保期限6个月以上的政策性业务'
--                 else '其中：2.其他政策性业务' end
--               when t1.policy_type = '政策性业务-生猪养殖: (300,1000]' then
--                 case when t1.is_add_curryear = '1' and t1.is_unguar_curryear = '1' and t1.loan_term_type <> '6个月以下' then '生猪养殖：其中：1.本年新增当年解保且实际担保期限6个月以上的政策性业务'
--                 else '生猪养殖：其中：2.其他' end
--               when t1.policy_type = '政策外“双控”业务：<10 and (300,1000]' then
--                 case when t1.loan_amt < 10 then '双控：其中：1.10万元以下'
--                 else '双控：其中：2.300-1000万元（不含生猪养殖）' end
--               when t1.policy_type = '“双控”外业务：>1000' then '双控外：其中：1.1000万元以上'
--             else '双控外：其中：2.非农项目' end as class_type_name
--         ,sum(case when t1.item_stt = '已放款' then t1.loan_amt else 0 end) as guar_amt
--         ,sum(case when t1.item_stt = '已放款' then 1 else 0 end) as guar_qty
--         ,sum(case when t1.is_add_curryear = '1' then t1.loan_amt else 0 end ) as year_guar_amt
--         ,sum(case when t1.is_add_curryear = '1' then 1 else 0 end ) as year_guar_qty
--         ,sum(case when t1.is_unguar_curryear = '1' then t1.loan_amt else 0 end ) as year_unguar_amt
--         ,sum(case when t1.is_unguar_curryear = '1' then 1 else 0 end ) as year_unguar_qty
--         ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then t1.compt_amt/10000 else '0' end) as year_comp_amt
--         ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then '1' else '0' end) as year_comp_qty
--         ,sum(case when t1.loan_reg_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then t1.loan_amt else 0 end ) as month_guar_amt
--         ,sum(case when t1.loan_reg_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then 1 else 0 end ) as month_guar_qty
--         
--    from dw_base.dwd_tjnd_data_report_guar_tag t1
--   where day_id = '${v_sdate}' and '${v_sdate}' = date_format(last_day('${v_sdate}'),'%Y%m%d') -- 月底跑批
--   group by case when t1.policy_type = '政策性业务：[10-300]' then
--                 case when t1.is_add_curryear = '1' and t1.is_unguar_curryear = '1' and t1.loan_term_type <> '6个月以下' then '1'
--                 else '2' end
--               when t1.policy_type = '政策性业务-生猪养殖: (300,1000]' then
--                 case when t1.is_add_curryear = '1' and t1.is_unguar_curryear = '1' and t1.loan_term_type <> '6个月以下' then '3'
--                 else '4' end
--               when t1.policy_type = '政策外“双控”业务：<10 and (300,1000]' then
--                 case when t1.loan_amt < 10 then '5'
--                 else '6' end
--               when t1.policy_type = '“双控”外业务：>1000' then '7'
--             else '8' end
--  ;
--  commit;
--  
--  -- 2.按行业划分
--  insert into dw_base.ads_tjnd_guar_busi_dimension_stat
--  ( day_id            -- 数据日期
--   ,divid_method      -- 划分方式
--   ,class_type_code   -- 分类小项code
--   ,class_type_name   -- 分类小项名称
--   ,guar_amt          -- 在保余额（万元）
--   ,guar_qty          -- 在保项目数
--   ,year_guar_amt     -- 本年新增担保金额（万元）
--   ,year_guar_qty     -- 本年新增担保项目数
--   ,year_unguar_amt   -- 本年累计解保金额（万元）
--   ,year_unguar_qty   -- 本年累计解保项目数
--   ,year_comp_amt     -- 本年累计代偿金额（万元）
--   ,year_comp_qty     -- 本年累计代偿项目数
--   ,month_guar_amt    -- 本月新增担保金额（万元）
--   ,month_guar_qty    -- 本月新增担保项目数
--   )
--  select '${v_sdate}' as day_id
--         ,'按行业划分' as divid_method
--         ,case t1.guar_class_type
--              when '非农项目' then '12'  -- 非农项目暂时归入其他农业项目里
--              when '粮食种植' then '2'
--              when '特色农产品种植' then '3'
--              when '生猪养殖' then '4'
--              when '其他畜牧业' then '5'
--              when '渔业生产' then '6'
--              when '农田建设' then '7'
--              when '农资、农机、农技等农业社会化服务' then '8'
--              when '农产品流通（含农产品收购、仓储保鲜、销售等）' then '9'
--              when '农产品初加工' then '10'
--              when '农业新业态' then '11'
--              when '其他农业项目' then '12'
--            end as class_type_code
--         ,case t1.guar_class_type
--  	        when '非农项目' then '其他农业项目'
--              when '粮食种植' then '农林业生产-粮食种植'
--              when '特色农产品种植' then '农林业生产-重要特色农产品种植'
--              when '生猪养殖' then '畜牧业生产-生猪养殖'
--              when '其他畜牧业' then '畜牧业生产-其他畜牧业'
--              else t1.guar_class_type
--            end  as class_type_name
--         ,sum(case when t1.item_stt = '已放款' then t1.loan_amt else 0 end) as guar_amt
--         ,sum(case when t1.item_stt = '已放款' then 1 else 0 end) as guar_qty
--         ,sum(case when t1.is_add_curryear = '1' then t1.loan_amt else 0 end ) as year_guar_amt
--         ,sum(case when t1.is_add_curryear = '1' then 1 else 0 end ) as year_guar_qty
--         ,sum(case when t1.is_unguar_curryear = '1' then t1.loan_amt else 0 end ) as year_unguar_amt
--         ,sum(case when t1.is_unguar_curryear = '1' then 1 else 0 end ) as year_unguar_qty
--         ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then t1.compt_amt/10000 else '0' end) as year_comp_amt
--         ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then '1' else '0' end) as year_comp_qty
--         ,sum(case when t1.loan_reg_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then t1.loan_amt else 0 end ) as month_guar_amt
--         ,sum(case when t1.loan_reg_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then 1 else 0 end ) as month_guar_qty
--  
--    from dw_base.dwd_tjnd_data_report_guar_tag t1
--   where day_id = '${v_sdate}' and '${v_sdate}' = date_format(last_day('${v_sdate}'),'%Y%m%d') -- 月底跑批
--   group by case t1.guar_class_type
--              when '非农项目' then '12'  -- 非农项目暂时归入其他农业项目里
--              when '粮食种植' then '2'
--              when '特色农产品种植' then '3'
--              when '生猪养殖' then '4'
--              when '其他畜牧业' then '5'
--              when '渔业生产' then '6'
--              when '农田建设' then '7'
--              when '农资、农机、农技等农业社会化服务' then '8'
--              when '农产品流通（含农产品收购、仓储保鲜、销售等）' then '9'
--              when '农产品初加工' then '10'
--              when '农业新业态' then '11'
--              when '其他农业项目' then '12'
--            end
--  ;
--  commit;
--  
--  -- 3.按贷款期限划分
--  insert into dw_base.ads_tjnd_guar_busi_dimension_stat
--  ( day_id            -- 数据日期
--   ,divid_method      -- 划分方式
--   ,class_type_code   -- 分类小项code
--   ,class_type_name   -- 分类小项名称
--   ,guar_amt          -- 在保余额（万元）
--   ,guar_qty          -- 在保项目数
--   ,year_guar_amt     -- 本年新增担保金额（万元）
--   ,year_guar_qty     -- 本年新增担保项目数
--   ,year_unguar_amt   -- 本年累计解保金额（万元）
--   ,year_unguar_qty   -- 本年累计解保项目数
--   ,year_comp_amt     -- 本年累计代偿金额（万元）
--   ,year_comp_qty     -- 本年累计代偿项目数
--   ,month_guar_amt    -- 本月新增担保金额（万元）
--   ,month_guar_qty    -- 本月新增担保项目数
--   )
--  select '${v_sdate}' as day_id
--         ,'按贷款期限划分' as divid_method
--         ,case t1.loan_term_type
--              when '6个月以下' then '1'
--              when '6(含)-12个月(含)' then '2'
--              when '12-36个月(含)' then '3'
--              when '36个月以上' then '4'
--            end as class_type_code
--         ,t1.loan_term_type as class_type_name
--         ,sum(case when t1.item_stt = '已放款' then t1.loan_amt else 0 end) as guar_amt
--         ,sum(case when t1.item_stt = '已放款' then 1 else 0 end) as guar_qty
--         ,sum(case when t1.is_add_curryear = '1' then t1.loan_amt else 0 end ) as year_guar_amt
--         ,sum(case when t1.is_add_curryear = '1' then 1 else 0 end ) as year_guar_qty
--         ,sum(case when t1.is_unguar_curryear = '1' then t1.loan_amt else 0 end ) as year_unguar_amt
--         ,sum(case when t1.is_unguar_curryear = '1' then 1 else 0 end ) as year_unguar_qty
--         ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then t1.compt_amt/10000 else '0' end) as year_comp_amt
--         ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then '1' else '0' end) as year_comp_qty
--         ,sum(case when t1.loan_reg_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then t1.loan_amt else 0 end ) as month_guar_amt
--         ,sum(case when t1.loan_reg_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then 1 else 0 end ) as month_guar_qty
--  
--    from dw_base.dwd_tjnd_data_report_guar_tag t1
--   where day_id = '${v_sdate}' and '${v_sdate}' = date_format(last_day('${v_sdate}'),'%Y%m%d') -- 月底跑批
--   group by case t1.loan_term_type
--              when '6个月以下' then '1'
--              when '6(含)-12个月(含)' then '2'
--              when '12-36个月(含)' then '3'
--              when '36个月以上' then '4'
--            end
--  ;
--  commit;
--  
--  -- 4.本年新增实际担保期限6个月及以上的项目
--  insert into dw_base.ads_tjnd_guar_busi_dimension_stat
--  ( day_id            -- 数据日期
--   ,divid_method      -- 划分方式
--   ,class_type_code   -- 分类小项code
--   ,class_type_name   -- 分类小项名称
--   ,guar_amt          -- 在保余额（万元）
--   ,guar_qty          -- 在保项目数
--   ,year_guar_amt     -- 本年新增担保金额（万元）
--   ,year_guar_qty     -- 本年新增担保项目数
--   ,year_unguar_amt   -- 本年累计解保金额（万元）
--   ,year_unguar_qty   -- 本年累计解保项目数
--   ,year_comp_amt     -- 本年累计代偿金额（万元）
--   ,year_comp_qty     -- 本年累计代偿项目数
--   ,month_guar_amt    -- 本月新增担保金额（万元）
--   ,month_guar_qty    -- 本月新增担保项目数
--   )
--  select '${v_sdate}' as day_id
--         ,'本年新增实际担保期限6个月及以上的项目' as divid_method
--         ,'1' as class_type_code
--         ,'本年新增实际担保期限6个月及以上的项目' as class_type_name
--         ,sum(case when t1.item_stt = '已放款' then t1.loan_amt else 0 end) as guar_amt
--         ,sum(case when t1.item_stt = '已放款' then 1 else 0 end) as guar_qty
--         ,sum(case when t1.is_add_curryear = '1' then t1.loan_amt else 0 end ) as year_guar_amt
--         ,sum(case when t1.is_add_curryear = '1' then 1 else 0 end ) as year_guar_qty
--         ,sum(case when t1.is_unguar_curryear = '1' then t1.loan_amt else 0 end ) as year_unguar_amt
--         ,sum(case when t1.is_unguar_curryear = '1' then 1 else 0 end ) as year_unguar_qty
--         ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then t1.compt_amt/10000 else '0' end) as year_comp_amt
--         ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then '1' else '0' end) as year_comp_qty
--         ,sum(case when t1.loan_reg_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then t1.loan_amt else 0 end ) as month_guar_amt
--         ,sum(case when t1.loan_reg_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then 1 else 0 end ) as month_guar_qty
--  
--    from dw_base.dwd_tjnd_data_report_guar_tag t1
--   where day_id = '${v_sdate}' and '${v_sdate}' = date_format(last_day('${v_sdate}'),'%Y%m%d') -- 月底跑批
--     and t1.is_add_curryear = '1' and t1.loan_term_type <> '6个月以下'
--  ;
--  commit;
--  
--  -- 5.按支持经营主题类型划分
--  insert into dw_base.ads_tjnd_guar_busi_dimension_stat
--  ( day_id            -- 数据日期
--   ,divid_method      -- 划分方式
--   ,class_type_code   -- 分类小项code
--   ,class_type_name   -- 分类小项名称
--   ,guar_amt          -- 在保余额（万元）
--   ,guar_qty          -- 在保项目数
--   ,year_guar_amt     -- 本年新增担保金额（万元）
--   ,year_guar_qty     -- 本年新增担保项目数
--   ,year_unguar_amt   -- 本年累计解保金额（万元）
--   ,year_unguar_qty   -- 本年累计解保项目数
--   ,year_comp_amt     -- 本年累计代偿金额（万元）
--   ,year_comp_qty     -- 本年累计代偿项目数
--   ,month_guar_amt    -- 本月新增担保金额（万元）
--   ,month_guar_qty    -- 本月新增担保项目数
--   )
--  select '${v_sdate}' as day_id
--         ,'按支持经营主体类型划分' as divid_method
--         ,case t1.cust_class_type
--              when '家庭农场（种养大户）' then '1'
--              when '家庭农场' then '2'
--              when '农民专业合作社' then '3'
--              when '农业企业' then '4'
--            end as class_type_code
--         ,t1.cust_class_type as class_type_name
--         ,sum(case when t1.item_stt = '已放款' then t1.loan_amt else 0 end) as guar_amt
--         ,sum(case when t1.item_stt = '已放款' then 1 else 0 end) as guar_qty
--         ,sum(case when t1.is_add_curryear = '1' then t1.loan_amt else 0 end ) as year_guar_amt
--         ,sum(case when t1.is_add_curryear = '1' then 1 else 0 end ) as year_guar_qty
--         ,sum(case when t1.is_unguar_curryear = '1' then t1.loan_amt else 0 end ) as year_unguar_amt
--         ,sum(case when t1.is_unguar_curryear = '1' then 1 else 0 end ) as year_unguar_qty
--         ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then t1.compt_amt/10000 else '0' end) as year_comp_amt
--         ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then '1' else '0' end) as year_comp_qty
--         ,sum(case when t1.loan_reg_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then t1.loan_amt else 0 end ) as month_guar_amt
--         ,sum(case when t1.loan_reg_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then 1 else 0 end ) as month_guar_qty
--  
--    from dw_base.dwd_tjnd_data_report_guar_tag t1
--   where day_id = '${v_sdate}' and '${v_sdate}' = date_format(last_day('${v_sdate}'),'%Y%m%d') -- 月底跑批
--   group by case t1.cust_class_type 
--              when '家庭农场（种养大户）' then '1'
--              when '家庭农场' then '2'
--              when '农民专业合作社' then '3'
--              when '农业企业' then '4'
--            end
--  ;
--  commit; 