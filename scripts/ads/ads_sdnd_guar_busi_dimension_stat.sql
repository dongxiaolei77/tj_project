-- ---------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20230820
-- 目标表   ：ads_sdnd_guar_busi_dimension_stat
-- 源表     ：da_base.dwd_sdnd_data_report_guar_tag
--            
--            
-- 备注     ：国担上报-山东农担业务细分维度情况统计，基于国担上报数据底表数据开发
-- 变更记录 ：

-- ---------------------------------------

delete from dw_base.ads_sdnd_guar_busi_dimension_stat where day_id = '${v_sdate}';
commit;

-- 1.按照政策性划分
insert into dw_base.ads_sdnd_guar_busi_dimension_stat
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
       ,'按政策性划分' as divid_method
       ,case when t1.policy_type = '政策性业务：[10-300]' then
               case when t1.is_add_curryear = '1' and t1.is_unguar_curryear = '1' and t1.loan_term_type <> '6个月以下' then '1'
               else '2' end
             when t1.policy_type = '政策性业务-生猪养殖: (300,1000]' then
               case when t1.is_add_curryear = '1' and t1.is_unguar_curryear = '1' and t1.loan_term_type <> '6个月以下' then '3'
               else '4' end
             when t1.policy_type = '政策外“双控”业务：<10 and (300,1000]' then
               case when t1.loan_amt < 10 then '5'
               else '6' end
             when t1.policy_type = '“双控”外业务：>1000' then '7'
           else '8' end as class_type_code
       ,case when t1.policy_type = '政策性业务：[10-300]' then
               case when t1.is_add_curryear = '1' and t1.is_unguar_curryear = '1' and t1.loan_term_type <> '6个月以下' then '其中：1.本年新增当年解保且实际担保期限6个月以上的政策性业务'
               else '其中：2.其他政策性业务' end
             when t1.policy_type = '政策性业务-生猪养殖: (300,1000]' then
               case when t1.is_add_curryear = '1' and t1.is_unguar_curryear = '1' and t1.loan_term_type <> '6个月以下' then '生猪养殖：其中：1.本年新增当年解保且实际担保期限6个月以上的政策性业务'
               else '生猪养殖：其中：2.其他' end
             when t1.policy_type = '政策外“双控”业务：<10 and (300,1000]' then
               case when t1.loan_amt < 10 then '双控：其中：1.10万元以下'
               else '双控：其中：2.300-1000万元（不含生猪养殖）' end
             when t1.policy_type = '“双控”外业务：>1000' then '双控外：其中：1.1000万元以上'
           else '双控外：其中：2.非农项目' end as class_type_name
       ,sum(case when t1.item_stt = '已放款' then t1.loan_amt else 0 end) as guar_amt
       ,sum(case when t1.item_stt = '已放款' then 1 else 0 end) as guar_qty
       ,sum(case when t1.is_add_curryear = '1' then t1.loan_amt else 0 end ) as year_guar_amt
       ,sum(case when t1.is_add_curryear = '1' then 1 else 0 end ) as year_guar_qty
       ,sum(case when t1.is_unguar_curryear = '1' then t1.loan_amt else 0 end ) as year_unguar_amt
       ,sum(case when t1.is_unguar_curryear = '1' then 1 else 0 end ) as year_unguar_qty
       ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then t1.compt_amt/10000 else '0' end) as year_comp_amt
       ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then '1' else '0' end) as year_comp_qty
       ,sum(case when t1.loan_reg_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then t1.loan_amt else 0 end ) as month_guar_amt
       ,sum(case when t1.loan_reg_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then 1 else 0 end ) as month_guar_qty
       
  from dw_base.dwd_sdnd_data_report_guar_tag t1
 where day_id = '${v_sdate}' and '${v_sdate}' = date_format(last_day('${v_sdate}'),'%Y%m%d') -- 月底跑批
 group by case when t1.policy_type = '政策性业务：[10-300]' then
               case when t1.is_add_curryear = '1' and t1.is_unguar_curryear = '1' and t1.loan_term_type <> '6个月以下' then '1'
               else '2' end
             when t1.policy_type = '政策性业务-生猪养殖: (300,1000]' then
               case when t1.is_add_curryear = '1' and t1.is_unguar_curryear = '1' and t1.loan_term_type <> '6个月以下' then '3'
               else '4' end
             when t1.policy_type = '政策外“双控”业务：<10 and (300,1000]' then
               case when t1.loan_amt < 10 then '5'
               else '6' end
             when t1.policy_type = '“双控”外业务：>1000' then '7'
           else '8' end
;
commit;

-- 2.按行业划分
insert into dw_base.ads_sdnd_guar_busi_dimension_stat
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
       ,'按行业划分' as divid_method
       ,case t1.guar_class_type 
            when '非农项目' then '12'  -- 非农项目暂时归入其他农业项目里
            when '粮食种植' then '2'
            when '特色农产品种植' then '3'
            when '生猪养殖' then '4'
            when '其他畜牧业' then '5'
            when '渔业生产' then '6'
            when '农田建设' then '7'
            when '农资、农机、农技等农业社会化服务' then '8'
            when '农产品流通（含农产品收购、仓储保鲜、销售等）' then '9'
            when '农产品初加工' then '10'
            when '农业新业态' then '11'
            when '其他农业项目' then '12'
          end as class_type_code
       ,case t1.guar_class_type 
	        when '非农项目' then '其他农业项目'
            when '粮食种植' then '农林业生产-粮食种植'
            when '特色农产品种植' then '农林业生产-重要特色农产品种植'
            when '生猪养殖' then '畜牧业生产-生猪养殖'
            when '其他畜牧业' then '畜牧业生产-其他畜牧业'
            else t1.guar_class_type 
          end  as class_type_name
       ,sum(case when t1.item_stt = '已放款' then t1.loan_amt else 0 end) as guar_amt
       ,sum(case when t1.item_stt = '已放款' then 1 else 0 end) as guar_qty
       ,sum(case when t1.is_add_curryear = '1' then t1.loan_amt else 0 end ) as year_guar_amt
       ,sum(case when t1.is_add_curryear = '1' then 1 else 0 end ) as year_guar_qty
       ,sum(case when t1.is_unguar_curryear = '1' then t1.loan_amt else 0 end ) as year_unguar_amt
       ,sum(case when t1.is_unguar_curryear = '1' then 1 else 0 end ) as year_unguar_qty
       ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then t1.compt_amt/10000 else '0' end) as year_comp_amt
       ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then '1' else '0' end) as year_comp_qty
       ,sum(case when t1.loan_reg_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then t1.loan_amt else 0 end ) as month_guar_amt
       ,sum(case when t1.loan_reg_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then 1 else 0 end ) as month_guar_qty
       
  from dw_base.dwd_sdnd_data_report_guar_tag t1
 where day_id = '${v_sdate}' and '${v_sdate}' = date_format(last_day('${v_sdate}'),'%Y%m%d') -- 月底跑批
 group by case t1.guar_class_type 
            when '非农项目' then '12'  -- 非农项目暂时归入其他农业项目里
            when '粮食种植' then '2'
            when '特色农产品种植' then '3'
            when '生猪养殖' then '4'
            when '其他畜牧业' then '5'
            when '渔业生产' then '6'
            when '农田建设' then '7'
            when '农资、农机、农技等农业社会化服务' then '8'
            when '农产品流通（含农产品收购、仓储保鲜、销售等）' then '9'
            when '农产品初加工' then '10'
            when '农业新业态' then '11'
            when '其他农业项目' then '12'
          end
;
commit;

-- 3.按贷款期限划分
insert into dw_base.ads_sdnd_guar_busi_dimension_stat
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
       ,case t1.loan_term_type 
            when '6个月以下' then '1'
            when '6(含)-12个月(含)' then '2'
            when '12-36个月(含)' then '3'
            when '36个月以上' then '4'
          end as class_type_code
       ,t1.loan_term_type as class_type_name
       ,sum(case when t1.item_stt = '已放款' then t1.loan_amt else 0 end) as guar_amt
       ,sum(case when t1.item_stt = '已放款' then 1 else 0 end) as guar_qty
       ,sum(case when t1.is_add_curryear = '1' then t1.loan_amt else 0 end ) as year_guar_amt
       ,sum(case when t1.is_add_curryear = '1' then 1 else 0 end ) as year_guar_qty
       ,sum(case when t1.is_unguar_curryear = '1' then t1.loan_amt else 0 end ) as year_unguar_amt
       ,sum(case when t1.is_unguar_curryear = '1' then 1 else 0 end ) as year_unguar_qty
       ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then t1.compt_amt/10000 else '0' end) as year_comp_amt
       ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then '1' else '0' end) as year_comp_qty
       ,sum(case when t1.loan_reg_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then t1.loan_amt else 0 end ) as month_guar_amt
       ,sum(case when t1.loan_reg_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then 1 else 0 end ) as month_guar_qty
       
  from dw_base.dwd_sdnd_data_report_guar_tag t1
 where day_id = '${v_sdate}' and '${v_sdate}' = date_format(last_day('${v_sdate}'),'%Y%m%d') -- 月底跑批
 group by case t1.loan_term_type 
            when '6个月以下' then '1'
            when '6(含)-12个月(含)' then '2'
            when '12-36个月(含)' then '3'
            when '36个月以上' then '4'
          end
;
commit;

-- 4.本年新增实际担保期限6个月及以上的项目
insert into dw_base.ads_sdnd_guar_busi_dimension_stat
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
       ,sum(case when t1.item_stt = '已放款' then t1.loan_amt else 0 end) as guar_amt
       ,sum(case when t1.item_stt = '已放款' then 1 else 0 end) as guar_qty
       ,sum(case when t1.is_add_curryear = '1' then t1.loan_amt else 0 end ) as year_guar_amt
       ,sum(case when t1.is_add_curryear = '1' then 1 else 0 end ) as year_guar_qty
       ,sum(case when t1.is_unguar_curryear = '1' then t1.loan_amt else 0 end ) as year_unguar_amt
       ,sum(case when t1.is_unguar_curryear = '1' then 1 else 0 end ) as year_unguar_qty
       ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then t1.compt_amt/10000 else '0' end) as year_comp_amt
       ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then '1' else '0' end) as year_comp_qty
       ,sum(case when t1.loan_reg_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then t1.loan_amt else 0 end ) as month_guar_amt
       ,sum(case when t1.loan_reg_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then 1 else 0 end ) as month_guar_qty
       
  from dw_base.dwd_sdnd_data_report_guar_tag t1
 where day_id = '${v_sdate}' and '${v_sdate}' = date_format(last_day('${v_sdate}'),'%Y%m%d') -- 月底跑批
   and t1.is_add_curryear = '1' and t1.loan_term_type <> '6个月以下'
;
commit;

-- 5.按支持经营主题类型划分
insert into dw_base.ads_sdnd_guar_busi_dimension_stat
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
       ,case t1.cust_class_type 
            when '家庭农场（种养大户）' then '1'
            when '家庭农场' then '2'
            when '农民专业合作社' then '3'
            when '农业企业' then '4'
          end as class_type_code
       ,t1.cust_class_type as class_type_name
       ,sum(case when t1.item_stt = '已放款' then t1.loan_amt else 0 end) as guar_amt
       ,sum(case when t1.item_stt = '已放款' then 1 else 0 end) as guar_qty
       ,sum(case when t1.is_add_curryear = '1' then t1.loan_amt else 0 end ) as year_guar_amt
       ,sum(case when t1.is_add_curryear = '1' then 1 else 0 end ) as year_guar_qty
       ,sum(case when t1.is_unguar_curryear = '1' then t1.loan_amt else 0 end ) as year_unguar_amt
       ,sum(case when t1.is_unguar_curryear = '1' then 1 else 0 end ) as year_unguar_qty
       ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then t1.compt_amt/10000 else '0' end) as year_comp_amt
       ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then '1' else '0' end) as year_comp_qty
       ,sum(case when t1.loan_reg_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then t1.loan_amt else 0 end ) as month_guar_amt
       ,sum(case when t1.loan_reg_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then 1 else 0 end ) as month_guar_qty
       
  from dw_base.dwd_sdnd_data_report_guar_tag t1
 where day_id = '${v_sdate}' and '${v_sdate}' = date_format(last_day('${v_sdate}'),'%Y%m%d') -- 月底跑批
 group by case t1.cust_class_type 
            when '家庭农场（种养大户）' then '1'
            when '家庭农场' then '2'
            when '农民专业合作社' then '3'
            when '农业企业' then '4'
          end
;
commit;