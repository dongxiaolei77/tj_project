-- ---------------------------------------
-- 开发人   : zhangfl
-- 开发时间 : 20230217
-- 目标表   : dw_base.dwd_guar_type_stat         业务结构统计分析明细
-- 源表     : dw_base.dwd_guar_info_all          担保台账信息
--            dw_base.dwd_guar_tag               担保客户标签表
--            dw_base.dwd_guar_cont_info_all     担保年度与合同明细数据

-- 备注     : 

-- 变更记录 : 
-- ---------------------------------------

delete from dw_base.dwd_guar_type_stat 
where day_id = '${v_sdate}' 
and '${v_sdate}' = date_format(last_day('${v_sdate}'),'%Y%m%d')
;
commit;

insert into dw_base.dwd_guar_type_stat
(
 day_id             -- 数据日期
 ,guar_id           -- 业务编号
 ,cust_name         -- 客户名称
 ,proj_status       -- 项目状态
 ,proj_type         -- 业务类型（首保、续支、续保)
 ,city_name         -- 地市
 ,country_name      -- 区县
 ,product_name      -- 产品名称
 ,product_type      -- 产品种类（普通贷款、自主循环贷、非自主循环贷）
 ,loan_amt          -- 贷款合同金额
 ,loan_start_dt     -- 贷款开始日
 ,loan_end_dt       -- 贷款结束日
 ,loan_reg_dt       -- 放款登记日
 ,guar_rate         -- 担保费率
 ,cust_type         -- 客户类型
 ,guar_class        -- 国担分类
)
select '${v_sdate}'       -- 数据日期
       ,t1.guar_id        -- 业务编号
       ,t1.cust_name      -- 客户名称
       ,t1.item_stt       -- 项目状态
       ,case when t2.is_first_guar = '0' and t2.is_xz = '0' then '首保'
          when t2.is_xz = '1' then '续支'
          when t2.is_first_guar = '1' and t2.is_xz = '0' then '续保' else null end as proj_type -- 业务类型（首保、续支、续保)
       ,t1.city_name      -- 地市
       ,t1.county_name    -- 区县
       ,coalesce(t1.guar_prod, '其他')      -- 担保产品
       ,case when t3.loan_type is null and t1.guar_prod = '农耕贷' then '线上农耕贷'
           when t3.loan_type is null and t1.guar_prod <> '农耕贷' then '未知' 
           else t3.loan_type end as product_type  -- 产品种类
       ,t1.loan_amt       -- 贷款合同金额
       ,t1.loan_begin_dt  -- 贷款开始日
       ,t1.loan_end_dt    -- 贷款结束日
       ,replace(t1.loan_reg_dt, '-', '')     -- 放款登记日
       ,t1.guar_rate      -- 担保费率
       ,t1.cust_type      -- 客户类型
       ,coalesce(t1.guar_class, '其他')     -- 国担分类
  from dw_base.dwd_guar_info_all t1
  left join dw_base.dwd_guar_tag t2
    on t1.guar_id = t2.guar_id
  left join (select guar_no, loan_type from dw_base.dwd_guar_cont_info_all group by guar_no ) t3  -- 目前表内存在11条重复 guar_no 去重处理
    on t1.guar_id = t3.guar_no
 where '${v_sdate}' = date_format(last_day('${v_sdate}'),'%Y%m%d')  -- 月末跑批
   and replace(t1.loan_reg_dt, '-', '') >= concat(substr('${v_sdate}',1,6),'01') 
   and replace(t1.loan_reg_dt, '-', '') <= '${v_sdate}'             -- 当月数据
   and t1.guar_id is not null
   and coalesce(t2.is_xz, '') <> ''
;
commit;
 