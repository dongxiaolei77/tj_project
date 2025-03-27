-- ----------------------------------------
-- 开发人   : 
-- 开发时间 ：
-- 目标表   ：dwd_sdnd_report_proj_act_rk_shr_info     实收代偿分险记录
-- 源表     ：dw_nd.ods_t_proj_comp_risk_show t1 -- 分险信息台账数据展示
--           dw_base.dwd_sdnd_report_biz_no_base              国担上报范围表
-- 备注     ：
-- 变更记录 ：20240831 增加注释，代码结构优化 wangyx
--            20241201 脚本的统一变更，TDS转MySQL8.0 zhangfl
-- ----------------------------------------

-- 日增量加载
delete
from dw_base.dwd_tjnd_report_proj_act_rk_shr_info
where day_id = '${v_sdate}';
commit;

insert into dw_base.dwd_tjnd_report_proj_act_rk_shr_info
select distinct '${v_sdate}'        as day_id
              , t3.biz_no           as proj_no_prov   -- 省农担担保项目编号
              , '1'                 as act_rk_shr_typ -- 实收分险类型
              , t1.gov_risk_pay_amt as act_rk_shr_amt -- 实收分险金额
              , 1                   as dict_flag
from (
         select t1.project_id                   as proj_id
              , sum(t1.risk_shar_district_totl) as gov_risk_pay_amt
         from (
                  select t1.id
                       , t1.project_id
                       , t1.risk_shar_district_totl
                       , t1.is_delete
                       , row_number() over (partition by t1.id order by t1.db_update_time desc, t1.update_time desc) rn
                  from dw_nd.ods_t_proj_comp_risk_show t1 -- 分险信息台账数据展示
              ) t1
         where t1.rn = 1
           and t1.is_delete = 0
         group by t1.project_id
         having sum(t1.risk_shar_district_totl) > 0
     ) t1
         inner join dw_base.dwd_tjnd_report_biz_no_base t3 -- 国担上报范围表
                    on t1.proj_id = t3.biz_id
                        and t3.day_id = '${v_sdate}'
;
commit;