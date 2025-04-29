-- ---------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20230820
-- 目标表   ：ads_tjnd_guar_busi_stat
-- 源表     ：da_base.dwd_tjnd_data_report_guar_tag
--
--
-- 备注     ：国担上报-天津农担业务发展情况统计，基于国担上报数据底表数据开发
-- 变更记录 ：

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
select  day_id
       ,round(coalesce(year_guar_rate/year_guar_qty, 0), 4) as avg_guar_rate  -- 平均担保费率 = 本年担保费率的和/业务笔数
       ,round(coalesce(year_loan_rate/year_guar_qty, 0), 4) as avg_bank_rate  -- 平均贷款利率 = 本年贷款利率的和/业务笔数
       ,round(coalesce((year_guar_rate + year_loan_rate)/year_guar_qty, 0), 4) as finance_rate   -- 平均担保费率+平均贷款利率
       ,guar_amt
       ,guar_qty
       ,year_guar_amt
       ,year_guar_qty
       ,year_unguar_amt
       ,year_unguar_qty
       ,month_comp_amt
       ,month_comp_qty
       ,year_comp_amt
       ,year_comp_qty
       ,accum_comp_amt
       ,accum_comp_qty
       ,accum_unguar_amt
       ,accum_unguar_qty
       ,uncomp_amt
       ,uncomp_qty
       ,month_uncomp_amt
       ,month_uncomp_qty
       ,underway_comp_amt
       ,underway_comp_qty
       ,round(coalesce(year_comp_amt/year_unguar_amt*100, 0), 2) as year_comp_rate   -- 本年代偿率 = 本年代偿金额/本年累计解保金额
       ,round(coalesce(accum_comp_amt/accum_unguar_amt*100, 0), 2) as comp_rate      -- 累计代偿率 = 累计代偿金额/累计累计解保金额
  from(
        select '${v_sdate}' as day_id
               ,sum(case when t1.is_add_curryear = '1' then t1.guar_rate else 0 end) as year_guar_rate  -- 当年累保业务的担保费率和
               ,sum(case when t1.is_add_curryear = '1' then t1.loan_rate else 0 end) as year_loan_rate  -- 当年累保业务的贷款利率和
               ,sum(case when t1.item_stt = '已放款' then t1.loan_amt else 0 end) as guar_amt           -- 当年在保金额
               ,sum(case when t1.item_stt = '已放款' then 1 else 0 end) as guar_qty                     -- 当年在保项目数
               ,sum(case when t1.is_add_curryear = '1' then t1.loan_amt else 0 end) as year_guar_amt    -- 当年累保金额
               ,sum(case when t1.is_add_curryear = '1' then 1 else 0 end) as year_guar_qty              -- 当年累保项目数
               ,sum(case when t1.is_unguar_curryear = '1' then t1.loan_amt else 0 end) as year_unguar_amt
               ,sum(case when t1.is_unguar_curryear = '1' then 1 else 0 end) as year_unguar_qty
               ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then t1.compt_amt/10000 else 0 end) as month_comp_amt
               ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then 1 else 0 end) as month_comp_qty
               ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101' ) and '${v_sdate}' then t1.compt_amt/10000 else 0 end) as year_comp_amt
               ,sum(case when t1.is_compt = '1' and t1.compt_dt between concat(year('${v_sdate}'), '0101' ) and '${v_sdate}' then 1 else 0 end) as year_comp_qty
               ,sum(case when t1.is_compt = '1' then t1.compt_amt/10000 else 0 end) as accum_comp_amt
               ,sum(case when t1.is_compt = '1' then 1 else 0 end) as accum_comp_qty
               ,sum(case when t1.is_unguar = '1' then t1.loan_amt else 0 end) as accum_unguar_amt
               ,sum(case when t1.is_unguar = '1' then 1 else 0 end) as accum_unguar_qty
               ,sum(case when t1.compt_aply_stt in ('申请中', '审核中', '拨付申请中', '拨付审核中', '待拨付') then t1.compt_amt/10000 else 0 end) as uncomp_amt -- 代偿中流程，代偿金额为逾期合计金额
               ,sum(case when t1.compt_aply_stt in ('申请中', '审核中', '拨付申请中', '拨付审核中', '待拨付') then 1 else 0 end) as uncomp_qty
               ,sum(case when t1.compt_aply_stt in ('申请中', '审核中', '拨付申请中', '拨付审核中', '待拨付')
                       and t1.compt_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then t1.compt_amt/10000 else 0 end) as month_uncomp_amt
               ,sum(case when t1.compt_aply_stt in ('申请中', '审核中', '拨付申请中', '拨付审核中', '待拨付')
                       and t1.compt_dt between concat(date_format('${v_sdate}', '%Y%m'), '01') and '${v_sdate}' then 1 else 0 end) as month_uncomp_qty
               ,sum(case when t1.item_stt = '已放款' and t1.compt_aply_stt in ('申请中', '审核中', '拨付申请中', '拨付审核中', '待拨付') and t1.overdue_days > 90 then t1.compt_amt/10000 else 0 end) as underway_comp_amt
               ,sum(case when t1.item_stt = '已放款' and t1.compt_aply_stt in ('申请中', '审核中', '拨付申请中', '拨付审核中', '待拨付') and t1.overdue_days > 90 then 1 else 0 end) as underway_comp_qty
          from dw_base.dwd_tjnd_data_report_guar_tag t1
		  where day_id = '${v_sdate}'
  
  ) t1
 where '${v_sdate}' = date_format(last_day('${v_sdate}'),'%Y%m%d') -- 月底跑批

;
commit;
