-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250320
-- 目标表   ：dw_base.ads_tjnd_loan_society_info   国担上报-天津农担社会效应
-- 源表     ：
--
-- 备注     ：
-- 变更记录 ： 
-- ---------------------------------------

delete
from dw_base.ads_tjnd_loan_society_info
where day_id = '${v_sdate}';
insert into dw_base.ads_tjnd_loan_society_info(
day_id                     -- 数据日期
,first_guar_qty             -- 全年新增首贷担保项目数
,first_guar_qty_rate        -- 全年新增首贷担保项目数占比
,first_guar_amt             -- 全年新增首贷担保项目金额
,first_guar_amt_rate        -- 全年新增首贷担保项目金额占比
,oper_guar_qty              -- 经营性贷款额度担保项目数
,oper_guar_qty_rate         -- 经营性贷款额度担保项目数占比
,oper_guar_amt              -- 经营性贷款额度担保项目金额
,oper_guar_amt_rate         -- 经营性贷款额度担保项目金额占比
,oper_incr_amt              -- 经营性贷款额度增加金额
)
select '${v_sdate}'                                                                 as day_id
      ,t1.first_guar_qty           -- 全年新增首贷担保项目数
      ,t1.first_guar_qty/t1.first_guar_qty_all*100 as first_guar_qty_rate        -- 全年新增首贷担保项目数占比
      ,t1.first_guar_amt            -- 全年新增首贷担保项目金额
      ,t1.first_guar_amt/t1.first_guar_amt_all*100 as first_guar_amt_rate        -- 全年新增首贷担保项目金额占比
      ,t3.oper_guar_qty              -- 经营性贷款额度担保项目数
	  ,t3.oper_guar_qty/t1.first_guar_qty_all*100 as oper_guar_qty_rate         -- 经营性贷款额度担保项目数占比
      ,t3.oper_guar_amt              -- 经营性贷款额度担保项目金额
      ,t3.oper_guar_amt/t1.first_guar_amt_all*100 as oper_guar_amt_rate         -- 经营性贷款额度担保项目金额占比
      ,t3.oper_incr_amt              -- 经营性贷款额度增加金额
from (
     select  
		sum(case when DATE_FORMAT(t.on_guared_dt,'%Y') = left('${v_sdate}',4) and t.is_frst_guar = '1' then 1 else 0 end) as first_guar_qty
		,sum(case when DATE_FORMAT(t.on_guared_dt,'%Y') = left('${v_sdate}',4) then 1 else 0 end) as first_guar_qty_all                          
		,sum(case when DATE_FORMAT(t.on_guared_dt,'%Y') = left('${v_sdate}',4)and t.is_frst_guar = '1' then t.proj_onguar_amt_totl else 0 end) as first_guar_amt                                              
		,sum(case when DATE_FORMAT(t.on_guared_dt,'%Y') = left('${v_sdate}',4) then t.proj_onguar_amt_totl else 0 end) as first_guar_amt_all
        from dw_base.dwd_tjnd_report_proj_base_info t
        where t.day_id = '${v_sdate}'    
		and '${v_sdate}' = date_format(last_day(makedate(extract(year from '${v_sdate}'), 1) + interval quarter('${v_sdate}') * 3 - 1 month),'%Y%m%d')		
    ) t1
left join ( 
            select count(if(guar_up_amt > 0,guar_id,null))                  as oper_guar_qty              -- 经营性贷款额度担保项目数
                  
                  ,sum(if(guar_up_amt > 0,a_guarantee_amount,0)) / 10000    as oper_guar_amt              -- 经营性贷款额度担保项目金额
                  ,sum(if(guar_up_amt > 0,a_guarantee_amount,0)) / sum(a_guarantee_amount)*100 as oper_guar_amt_rate         -- 经营性贷款额度担保项目金额占比
                  ,sum(guar_up_amt) / 10000                                                as oper_incr_amt              -- 经营性贷款额度增加金额
			from (                                                                                  -- 【社会效应表_额度增加数据】
                    select a.guar_id
                          ,a.guarantee_amount as a_guarantee_amount
                    	  ,ifnull(b.guarantee_amount,0) as b_guarantee_amount -- 担保金额
                    	  ,a.id_num         -- 证件号码  
                    	  ,a.guarantee_amount - ifnull(b.guarantee_amount,0) as  guar_up_amt    -- 担保增加额 
                    from (
                           select guar_id           --  业务id
                    		     ,guarantee_amount  -- 担保金额
                    		     ,id_num            -- 证件号码  
                    	   from dw_nd.ods_tjnd_yw_business_book_new
                    	   where create_year_month = left('${v_sdate}',6)  -- 年月
                    	     and DATE_FORMAT(loan_entry_date,'%Y') = left('${v_sdate}',4) --  放款录入日期
                         ) a
                    left join (
                               select t.guar_id           --  业务id
                    		         ,t.guarantee_amount  -- 担保金额
                    				 ,t.id_num            -- 证件号码 
                    		   from (
                    		         select * from dw_nd.ods_tjnd_yw_business_book_new
                    				 where create_year_month = left('${v_sdate}',6)  -- 年月
                    				   and DATE_FORMAT(loan_entry_date,'%Y' )< left('${v_sdate}',4)  -- 放款录入日期
                    				  order by guar_start_date  desc  -- 担保开始日期
                    				) t
                               group by id_num
                    		  ) b
                    on a.id_num=b.id_num -- 证件号码       
                    
                 )b 
			where '${v_sdate}' =
              date_format(last_day(makedate(extract(year from '${v_sdate}'), 1) + interval quarter('${v_sdate}') * 3 - 1 month),
                          '%Y%m%d')		 
           ) t3	
on 1= 1		   
;
commit;