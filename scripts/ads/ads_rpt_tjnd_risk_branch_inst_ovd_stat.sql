-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250514
-- 目标表   ：dw_base.ads_rpt_tjnd_risk_branch_inst_ovd_stat 风险部-省级农担公司分支机构逾期情况统计季报
-- 源表     ：
--          新业务系统
--          dw_base.dwd_guar_info_all       担保台账信息
--          dw_base.dwd_imp_area_branch     区划映射办事处
--          dw_base.dwd_guar_info_onguar    担保台账在保信息
--          dw_nd.ods_t_proj_comp_aply      代偿申请信息
--
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- step0 重跑策略
delete
from dw_base.ads_rpt_tjnd_risk_branch_inst_ovd_stat
where day_id = '${v_sdate}';
commit;

-- 旧系统逻辑


-- 新系统逻辑
insert into dw_base.ads_rpt_tjnd_risk_branch_inst_ovd_stat
(day_id, -- 数据日期
 inst_name, -- 分支机构名称
 inst_type, -- 分支机构类型
 off_staff_cnt, -- 专职人员数量
 ovd_un_compt_amt, -- 期末逾期未代偿金额（万元）
 ovd_un_compt_proj_cnt, -- 期末逾期未代偿项目数
 gt_amt, -- 在保余额（万元）
 gt_proj_cnt, -- 在保项目数
 ovd_chance -- 期末逾期率(%)
)
select '${v_sdate}'                                                 as day_id,
       case
           when branch_off = '宁河东丽' then '宁河东丽办事处'
           when branch_off = '津南滨海' then '津南滨海新区办事处'
           when branch_off = '北辰武清' then '武清北辰办事处'
           when branch_off = '西青静海' then '西青静海办事处'
           when branch_off = '蓟州'     then '蓟州办事处'
           when branch_off = '宝坻'     then '宝坻办事处'
           end                                                      as inst_name,
       '办事处'                                                        as inst_type,
       case
           when branch_off = '宁河东丽' then 4
           when branch_off = '津南滨海' then 4
           when branch_off = '北辰武清' then 4
           when branch_off = '西青静海' then 4
           when branch_off = '蓟州'     then 5
           when branch_off = '宝坻'     then 4
           end                                                      as off_staff_cnt,
         sum(t6.overdue_totl) / 10000                                 as ovd_un_compt_amt,      -- 期末逾期未代偿金额（万元）
         count(t6.proj_no_prov)                                         as ovd_un_compt_proj_cnt, -- 期末逾期未代偿项目数
       sum(gt_amt)                                                  as gt_amt,
       count(case when t1.item_stt = '已放款' then t1.guar_id end)     as gt_proj_cnt,           
       round((sum(t6.overdue_totl) / 10000) / sum(gt_amt) * 100, 2) as ovd_chance             -- 期末逾期率(%)
from (
         select guar_id,
                country_code,
                item_stt
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and '${v_sdate}' =
               date_format(last_day(makedate(extract(year from '${v_sdate}'), 1) +
                                    interval quarter('${v_sdate}') * 3 - 1 month),
                           '%Y%m%d')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select guar_id,
                onguar_amt as gt_amt -- 在保余额
         from dw_base.dwd_guar_info_onguar
         where day_id = '${v_sdate}'
     ) t3 on t1.guar_id = t3.guar_id
	 left join (
	             select proj_no_prov
				       ,sum(ovd_amt) as overdue_totl     -- 逾期本金金额
				 from dw_base.dwd_tjnd_report_proj_ovd_info
				 where day_id = '${v_sdate}'
				 group by proj_no_prov
			   ) t6 
    on t1.guar_id = t6.proj_no_prov
	left join (
	           select code
			         ,case when branch = '蓟州办事处' then '蓟州' else branch end as branch_off
	           from (select *,row_number() over (partition by code order by db_update_time desc) as rn from dw_nd.ods_t_biz_project_main) a 
               where a.rn = 1			   
			  ) t7
	on t1.guar_id = t7.code
group by branch_off
-- 逾期率在 1% 以上 (含1%)
having round((sum(t6.overdue_totl) / 10000) / sum(gt_amt) * 100, 2) >= 1
;
commit;



