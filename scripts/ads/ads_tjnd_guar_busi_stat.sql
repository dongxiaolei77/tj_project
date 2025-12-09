-- ---------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20230820
-- 目标表   ：ads_tjnd_guar_busi_stat
-- 源表     ：dw_base.dwd_tjnd_report_proj_base_info         -- 项目信息汇总表
--            dw_base.dwd_tjnd_report_proj_unguar_info           --  解保记录表
--            dw_base.dwd_tjnd_report_proj_comp_info         -- 代偿
--           dw_base.dwd_tjnd_report_proj_loan_rec_info      -- 放款
-- 备注     ：zzy 由原来的根据dw_base.dwd_tjnd_data_report_guar_tag开发，改成根据国农担上报项目表开发   ； 原来的旧逻辑   放到最底下了
-- 变更记录 ：20250505 修改了被除数逻辑 避免报错

-- ---------------------------------------

delete from dw_base.ads_tjnd_guar_busi_stat where day_id = '${v_sdate}';
commit;
insert into dw_base.ads_tjnd_guar_busi_stat
( day_id                -- 数据日期
 ,avg_guar_rate         -- 平均担保费率(%)
 ,avg_bank_rate         -- 平均贷款利率(%)
 ,finance_rate          -- 综合融资成本(%)
 ,guar_amt              -- 在保金额（万元）
 ,guar_qty              -- 在保项目数
 ,year_guar_amt         -- 本年新增担保金额（万元）
 ,year_guar_qty         -- 本年新增担保项目数
 ,year_unguar_amt       -- 本年累计解保金额（万元）
 ,year_unguar_qty       -- 本年累计解保项目数
 ,month_comp_amt        -- 本月新增代偿金额（万元）
 ,month_comp_qty        -- 本月新增代偿项目数
 ,year_comp_amt         -- 本年累计代偿金额（万元）
 ,year_comp_qty         -- 本年累计代偿项目数
 ,accum_comp_amt        -- 自成立以来累计代偿金额（万元）
 ,accum_comp_qty        -- 自成立以来累计代偿项目数
 ,accum_unguar_amt      -- 自成立以来累计解保金额（万元）
 ,accum_unguar_qty      -- 自成立以来累计解保项目数
 ,uncomp_amt            -- 逾期未代偿金额（万元）
 ,uncomp_qty            -- 逾期未代偿项目数
 ,month_uncomp_amt      -- 本月新增逾期未代偿金额（万元）
 ,month_uncomp_qty      -- 本月新增逾期未代偿项目数
 ,underway_comp_amt     -- 期末在保且逾期3个月以上的未代偿金额（万元）
 ,underway_comp_qty     -- 期末在保且逾期3个月以上的未代偿项目数
 ,year_comp_rate        -- 本年代偿率(%)
 ,comp_rate             -- 累计代偿率(%)
)
select t5.day_id                -- 数据日期
      ,t5.avg_guar_rate         -- 平均担保费率(%)
      ,t5.avg_bank_rate         -- 平均贷款利率(%)
      ,t5.finance_rate          -- 综合融资成本(%)
      ,t5.guar_amt              -- 在保金额（万元）
      ,t5.guar_qty              -- 在保项目数
      ,t5.year_guar_amt         -- 本年新增担保金额（万元）
      ,t5.year_guar_qty         -- 本年新增担保项目数
      ,t5.year_unguar_amt       -- 本年累计解保金额（万元）
      ,t5.year_unguar_qty       -- 本年累计解保项目数
      ,t5.month_comp_amt        -- 本月新增代偿金额（万元）
      ,t5.month_comp_qty        -- 本月新增代偿项目数
      ,t5.year_comp_amt         -- 本年累计代偿金额（万元）
      ,t5.year_comp_qty         -- 本年累计代偿项目数
      ,t6.accum_comp_amt        -- 自成立以来累计代偿金额（万元）
      ,t6.accum_comp_qty        -- 自成立以来累计代偿项目数
      ,t7.accum_unguar_amt      -- 自成立以来累计解保金额（万元）
      ,t7.accum_unguar_qty      -- 自成立以来累计解保项目数
      ,t5.uncomp_amt            -- 逾期未代偿金额（万元）
      ,t5.uncomp_qty            -- 逾期未代偿项目数
      ,t5.month_uncomp_amt      -- 本月新增逾期未代偿金额（万元）
      ,t5.month_uncomp_qty      -- 本月新增逾期未代偿项目数
      ,t5.underway_comp_amt     -- 期末在保且逾期3个月以上的未代偿金额（万元）
      ,t5.underway_comp_qty     -- 期末在保且逾期3个月以上的未代偿项目数
      ,t5.year_comp_rate * 100 as year_comp_rate        -- 本年代偿率(%)
      ,(t6.accum_comp_amt / nullif(t7.accum_unguar_amt,0)) * 100 as comp_rate             -- 累计代偿率(%)   [成立以来代偿/成立以来解保]
from 
(
select '${v_sdate}' as day_id
       ,avg(guar_fee_rate) * 100  as avg_guar_rate         -- 平均担保费率(%)    [国担项目表avg(贷款利率)]
       ,avg(loan_cont_intr) * 100 as avg_bank_rate         -- 平均贷款利率(%)    [(担保费率+贷款利率)求平均值]
       ,coalesce(avg(guar_fee_rate) * 100,0) + coalesce(avg(loan_cont_intr) * 100,0) as finance_rate          -- 综合融资成本(%)  [sum(国担项目表.在保余额)]
       ,sum(proj_onguar_amt_totl) / 10000                 as guar_amt              -- 在保金额（万元） [sum(国担项目表.在保余额)]
       ,count(if(proj_stt_cd in ('01','02','03'),1,null)) as guar_qty              -- 在保项目数       [项目状态是在保的]
       ,sum(year_guar_amt) / 10000 as year_guar_amt         -- 本年新增担保金额（万元） [计入在保日期在本年的业务的放款金额累加]
       ,count(if(substr('${v_sdate}',1,4) = year(on_guared_dt),1,null)) as year_guar_qty         -- 本年新增担保项目数     [计入在保日期在本年的业务的笔数累加]
       ,sum(year_unguar_amt) / 10000 as year_unguar_amt       -- 本年累计解保金额（万元）  [解保登记日期在本年的解保金额累加] 
       ,count(if(proj_stt_cd in ('04','05') and year_unguar_amt > 0,1,null)) as year_unguar_qty       -- 本年累计解保项目数   [项目系统为正常解保/代偿解保且解保登记日期在本年的业务累加]
       ,sum(month_comp_amt) / 10000 as month_comp_amt        -- 本月新增代偿金额（万元） [代偿拨付日期在本月代偿拨付金额求和]
       ,count(if(month_comp_amt > 0,1,null)) as month_comp_qty        -- 本月新增代偿项目数   [计数（代偿拨付日期在本月的代偿拨付金额>0的项目数）]
       ,sum(year_comp_amt) / 10000 as year_comp_amt         -- 本年累计代偿金额（万元）    [代偿拨付日期在本年代偿拨付金额求和]
       ,count(if(year_comp_amt > 0,1,null)) as year_comp_qty         -- 本年累计代偿项目数 [计数（代偿拨付日期在本年的代偿拨付金额>0的项目数）]
--       ,sum(if(proj_stt_cd = '05',comp_pmt_amt,0)) / 10000 as accum_comp_amt        -- 自成立以来累计代偿金额（万元）       [取所有已完成代偿业务的代偿拨付金额求和]
--       ,count(if(proj_stt_cd = '05',1,null)) as accum_comp_qty        -- 自成立以来累计代偿项目数      [取所有已完成代偿业务的笔数求和]  
--       ,(coalesce(sum(loan_amt),0) - coalesce(sum(proj_onguar_amt_totl),0)) / 10000 as accum_unguar_amt      -- 自成立以来累计解保金额（万元）     [累计放款-在保余额]
--       ,count(if(proj_stt_cd in ('04','05'),1,null)) as accum_unguar_qty      -- 自成立以来累计解保项目数  [项目状态为解保的业务累加]
       ,sum(uncomp_amt) / 10000 as uncomp_amt            -- 逾期未代偿金额（万元）
       ,count(if(uncomp_amt > 0,1,null)) as uncomp_qty            -- 逾期未代偿项目数
       ,sum(month_uncomp_amt) / 10000   as month_uncomp_amt      -- 本月新增逾期未代偿金额（万元）
       ,count(if(month_uncomp_amt > 0,1,null)) as month_uncomp_qty      -- 本月新增逾期未代偿项目数
       ,sum(if(proj_stt_cd in ('01','02','03'),ovd_prin_rmv_bank_rk_seg_bal_3,0)) / 10000 as underway_comp_amt     -- 期末在保且逾期3个月以上的未代偿金额（万元）
       ,count(if(proj_stt_cd in ('01','02','03') and ovd_prin_rmv_bank_rk_seg_bal_3 > 0,1,null)) as underway_comp_qty     -- 期末在保且逾期3个月以上的未代偿项目数
       ,sum(year_comp_amt) / nullif(sum(year_unguar_amt),0) as year_comp_rate        -- 本年代偿率(%)  [本年代偿/本年解保]
  --     ,sum(if(proj_stt_cd = '05',comp_pmt_amt,0)) / nullif((coalesce(sum(loan_amt),0) - coalesce(sum(proj_onguar_amt_totl),0)),0) as comp_rate             -- 累计代偿率(%)  [成立以来代偿/成立以来解保]
from (
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
						 ,t3.month_comp_amt	                        -- 本月新增代偿金额
						 ,t3.comp_pmt_amt                   -- 累计代偿金额
						 ,t4.loan_amt                       -- 累计放款金额
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
						 ,guar_fee_rate  -- 担保费率
						 ,loan_cont_intr -- 借款合同利率
						 ,t6.uncomp_amt                     -- 逾期未代偿金额（元）
						 ,t6.month_uncomp_amt               -- 本月新增逾期未代偿金额（元）
						 ,t1.ovd_prin_rmv_bank_rk_seg_bal_3 -- 逾期三个月未代偿余额（扣除银行分险）(元)
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
							         ,sum(comp_pmt_amt) as comp_pmt_amt     -- 累计代偿金额
                                     ,sum(case when year(comp_pmt_dt) = left('${v_sdate}',4) then comp_pmt_amt else 0 end) as year_comp_amt	  -- 本年新增代偿金额        [sum(代偿拨付金额)  where 代偿拨付日期=本年]
									 ,sum(case when date_format(comp_pmt_dt,'%Y%m') = left('${v_sdate}',6) then comp_pmt_amt else 0 end) as month_comp_amt	  -- 本月新增代偿金额        [sum(代偿拨付金额)  where 代偿拨付日期=本月]
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
                   left join (
				               select proj_no_prov
							         ,sum(ovd_amt) as  uncomp_amt            -- 逾期未代偿金额（元）
									 ,sum(case when date_format(ovd_dt,'%Y%m') = left('${v_sdate}',6) then ovd_amt else 0 end) as month_uncomp_amt      -- 本月新增逾期未代偿金额（元）
							   from dw_base.dwd_tjnd_report_proj_ovd_info
							   where day_id = '${v_sdate}'                                                              
                               group by proj_no_prov							   
							 )	                                t6          --      【逾期】	
                    on t1.proj_no_prov = t6.proj_no_prov		 							 
                    where t1.day_id = '${v_sdate}'
					  
      ) t
) t5
cross join (
             select sum(comp_amt) as accum_comp_amt -- 自成立以来累计代偿金额（万元）  
                   ,sum(comp_cnt) as accum_comp_qty -- 自成立以来累计代偿项目数   
             from (                 
                    select sum(compt_amt) as comp_amt -- 新系统发生的代偿金额
				          ,count(*) as comp_cnt
                    from dw_base.dwd_guar_compt_info_his
                    where day_id = '${v_sdate}'
                    union all
                    select sum(total_compensation) as comp_amt  
				          ,count(*) as comp_cnt
                    from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation t1 -- 申请表
                             inner join dw_nd.ods_creditmid_v2_z_migrate_bh_compensatory t2 -- 代偿表
                                        on t1.id = t2.id_cfbiz_underwriting
                    where t1.gur_state != '50' -- [排除在保转进件]
                      and t2.over_tag = 'BJ'
                      and t2.status = 1
                 ) a
		   ) t6
cross join (
             select sum(unguar_amt) as accum_unguar_amt      -- 自成立以来累计解保金额（万元）
                   ,sum(unguar_cnt) as accum_unguar_qty      -- 自成立以来累计解保项目数
             from (  
        		    select sum(t1.loan_amt)        as unguar_amt      -- 自成立以来累计解保金额（万元）
				          ,count(*)                as unguar_cnt      -- 自成立以来累计解保项目数
                    from dw_base.dwd_guar_info_all_his t1 -- 业务信息宽表--项目域
                    left join dw_base.dwd_guar_biz_unguar_info t2 -- 担保年度业务解保信息表--项目域
				    on t2.biz_no = t1.guar_id and t2.day_id = '${v_sdate}'				  
                    where t1.day_id = '${v_sdate}'
				      and t1.item_stt in ('已解保', '已代偿')
                      and t1.data_source <> '迁移台账' -- 排除来源迁移台账数据
                    union all
                    select sum(unguar_amt)   as unguar_amt
				          ,count(*)          as unguar_cnt
                    from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation t1 -- 申请表
                    inner join (select ID_BUSINESS_INFORMATION,
                                       sum(REPAYMENT_PRINCIPAL)                     as unguar_amt,
                                       date_format(max(REPAYMENT_TIME), '%Y-%m-%d') as unguar_dt,
                                       date_format(max(created_time), '%Y-%m-%d')   as unguar_reg_dt
                                from dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_repayment
                                where REPAYMENT_PRINCIPAL > 0
                                  and DELETE_FLAG = 1
                                group by id_business_information
				 	           ) t2 -- 还款凭证信息
				    on t1.id = t2.ID_BUSINESS_INFORMATION
				    where t1.gur_state != '50' -- [排除在保转进件]
				 ) b
		   ) t7
where  '${v_sdate}' = date_format(last_day('${v_sdate}'),'%Y%m%d') -- 月底跑批
;
commit;	

-- 原逻辑				   
				   
--   select  day_id
--         ,round(coalesce(year_guar_rate/nullif(year_guar_qty,0), 0), 4) as avg_guar_rate  -- 平均担保费率 = 本年担保费率的和/业务笔数
--         ,round(coalesce(year_loan_rate/nullif(year_guar_qty,0), 0), 4) as avg_bank_rate  -- 平均贷款利率 = 本年贷款利率的和/业务笔数
--         ,round(coalesce((year_guar_rate + year_loan_rate)/nullif(year_guar_qty,0), 0), 4) as finance_rate   -- 平均担保费率+平均贷款利率
--         ,guar_amt                                                      -- 在保金额（万元）
--         ,guar_qty                                                      -- 在保项目数
--         ,year_guar_amt                                                 -- 本年新增担保金额（万元）
--         ,year_guar_qty                                                 -- 本年新增担保项目数
--         ,year_unguar_amt                                               -- 本年累计解保金额（万元）       old
--         ,year_unguar_qty                                               -- 本年累计解保项目数             old
--         ,month_comp_amt                                                -- 本月新增代偿金额（万元）        old
--         ,month_comp_qty                                                -- 本月新增代偿项目数              old
--         ,year_comp_amt                                                 -- 本年累计代偿金额（万元）        old
--         ,year_comp_qty                                                 -- 本年累计代偿项目数              old
--         ,accum_comp_amt                                                -- 自成立以来累计代偿金额（万元）   old
--         ,accum_comp_qty                                                -- 自成立以来累计代偿项目数         old
--         ,accum_unguar_amt                                              -- 自成立以来累计解保金额（万元）    old
--         ,accum_unguar_qty                                              -- 自成立以来累计解保项目数         old
--         ,uncomp_amt                                                    -- 逾期未代偿金额（万元）
--         ,uncomp_qty                                                    -- 逾期未代偿项目数
--         ,month_uncomp_amt                                              -- 本月新增逾期未代偿金额（万元）
--         ,month_uncomp_qty                                              -- 本月新增逾期未代偿项目数
--         ,underway_comp_amt                                             -- 期末在保且逾期3个月以上的未代偿金额（万元）
--         ,underway_comp_qty                                             -- 期末在保且逾期3个月以上的未代偿项目数
--         ,round(coalesce(year_comp_amt/nullif(year_unguar_amt,0)*100, 0), 2) as year_comp_rate   -- 本年代偿率 = 本年代偿金额/本年累计解保金额
--         ,round(coalesce(accum_comp_amt/nullif(accum_unguar_amt,0)*100, 0), 2) as comp_rate      -- 累计代偿率 = 累计代偿金额/累计累计解保金额
--    from(
--          select '${v_sdate}' as day_id
--                 ,sum(case when t1.is_add_curryear = '1' then t1.guar_rate else 0 end) as year_guar_rate  -- 当年累保业务的担保费率和
--                 ,sum(case when t1.is_add_curryear = '1' then t1.loan_rate else 0 end) as year_loan_rate  -- 当年累保业务的贷款利率和
--                 ,sum(case when t1.item_stt = '已放款' then t1.loan_amt else 0 end) as guar_amt           -- 当年在保金额
--                 ,sum(case when t1.item_stt = '已放款' then 1 else 0 end) as guar_qty                     -- 当年在保项目数
--                 ,sum(case when t1.is_add_curryear = '1' then t1.loan_amt else 0 end) as year_guar_amt    -- 当年累保金额
--                 ,sum(case when t1.is_add_curryear = '1' then 1 else 0 end) as year_guar_qty              -- 当年累保项目数
--                 ,sum(case when t1.is_unguar_curryear = '1' then t1.loan_amt else 0 end) as year_unguar_amt
--                 ,sum(case when t1.is_unguar_curryear = '1' then 1 else 0 end) as year_unguar_qty
--                 ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then t1.compt_amt/10000 else 0 end) as month_comp_amt
--                 ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then 1 else 0 end) as month_comp_qty
--                 ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101' ) and '${v_sdate}' then t1.compt_amt/10000 else 0 end) as year_comp_amt
--                 ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101' ) and '${v_sdate}' then 1 else 0 end) as year_comp_qty
--                 ,sum(case when t1.is_compt = '1' then t1.compt_amt/10000 else 0 end) as accum_comp_amt
--                 ,sum(case when t1.is_compt = '1' then 1 else 0 end) as accum_comp_qty
--                 ,sum(case when t1.is_unguar = '1' then t1.loan_amt else 0 end) as accum_unguar_amt
--                 ,sum(case when t1.is_unguar = '1' then 1 else 0 end) as accum_unguar_qty
--                 ,sum(case when t1.compt_aply_stt in ('申请中', '审核中', '拨付申请中', '拨付审核中', '待拨付') then t1.compt_amt/10000 else 0 end) as uncomp_amt -- 代偿中流程，代偿金额为逾期合计金额
--                 ,sum(case when t1.compt_aply_stt in ('申请中', '审核中', '拨付申请中', '拨付审核中', '待拨付') then 1 else 0 end) as uncomp_qty
--                 ,sum(case when t1.compt_aply_stt in ('申请中', '审核中', '拨付申请中', '拨付审核中', '待拨付')
--                         and t1.compt_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then t1.compt_amt/10000 else 0 end) as month_uncomp_amt
--                 ,sum(case when t1.compt_aply_stt in ('申请中', '审核中', '拨付申请中', '拨付审核中', '待拨付')
--                         and t1.compt_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then 1 else 0 end) as month_uncomp_qty
--                 ,sum(case when t1.item_stt = '已放款' and t1.compt_aply_stt in ('申请中', '审核中', '拨付申请中', '拨付审核中', '待拨付') and t1.overdue_days > 90 then t1.compt_amt/10000 else 0 end) as underway_comp_amt
--                 ,sum(case when t1.item_stt = '已放款' and t1.compt_aply_stt in ('申请中', '审核中', '拨付申请中', '拨付审核中', '待拨付') and t1.overdue_days > 90 then 1 else 0 end) as underway_comp_qty
--            from dw_base.dwd_tjnd_data_report_guar_tag t1
--  		  where day_id = '${v_sdate}'
--  
--    ) t1
--   where '${v_sdate}' = date_format(last_day('${v_sdate}'),'%Y%m%d') -- 月底跑批
--  
--  ;
--  commit;	 			   
				   
				   