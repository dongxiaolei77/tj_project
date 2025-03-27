-- ----------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250310
-- 目标表   ：dw_base.dwd_tjnd_report_biz_loan_bank       国农担上报--银行信息
-- 源表     ：dw_base.dwd_guar_info                      担保台账信息
--            dw_nd.ods_org_manage_bank_info            银行信息表
--            dw_nd.ods_org_manage_contract_info        合同基础信息表
--            dw_nd.ods_org_manage_comp_info            分险比例详情表
-- 备注     ：
-- 变更记录 ：
-- ----------------------------------------
-- step0:重跑策略
truncate table dw_base.dwd_tjnd_report_biz_loan_bank;
commit;

-- step1:插入数据
insert into dw_base.dwd_tjnd_report_biz_loan_bank
(day_id, -- 数据日期
 biz_id, -- 业务id
 biz_no, -- 业务编号
 loans_bank, -- 经办行
 dept_id, -- 省端银行机构id
 dept_name, -- 省端银行机构名称
 bank_id, -- 银行分支机构id
 bank_name, -- 银行分支机构名称
 ancestors, -- 层级机构id列表
 gnd_dept_id, -- 国担贷款银行代码key
 gnd_dept_name, -- 国担贷款银行名称
 bank_class, -- 银行分类
 bank_risk, -- 银行分险
 tjnd_risk, -- 农担分险
 gov_risk, -- 政府分险
 gov_risk_amt, -- 政府应收分险金额
 IS_COMP_LIMIT_RATE, -- 是否限率代偿
 LIMIT_RATE -- 限率
)
select '${v_sdate}'                                                           as day_id,
       null                                                                   as biz_id,
       t1.guar_id                                                             as biz_no,
       t1.loan_bank                                                           as loans_bank,
       t2.dept_id                                                             as dept_id,
       t2.dept_name                                                           as dept_name,
       t2.dept_id                                                             as bank_id,
       t2.dept_name                                                           as bank_name,
       t2.ancestors                                                           as ancestors,
       t4.序号                                                                  as gnd_dept_id,
       t4.中文全称                                                                as gnd_dept_name,
       t1.bank_class                                                          as bank_class,
       t3.fin_org_risk_share_ratio                                            as bank_risk,
       t3.gov_risk_share_ratio                                                as tjnd_risk,
       0                                                                      as gov_risk,
       null                                                                   as gov_risk_amt,
       if(t3.comp_rd is not null or t3.comp_limit_rate is not null, '1', '0') as IS_COMP_LIMIT_RATE,
       if(t3.comp_rd is null, comp_limit_rate, comp_rd)                       as LIMIT_RATE

from (
         select *
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}' -- 担保台账信息
     ) t1
         left join (select *
                    from (select *, row_number() over (partition by dept_id order by update_time desc) as rn
                          from dw_nd.ods_t_sys_dept
                          where del_flag = 0) t1
                    where rn = 1) t2 -- 部门表
                   on t1.loan_bank = t2.dept_name
         left join
     (
         select t1.dept_id,
                t2.bank_name,
                t2.fin_org_risk_share_ratio,
                t2.gov_risk_share_ratio,
                t2.comp_rd,
                t2.comp_limit_rate
         from (select *
               from (select *, row_number() over (partition by dept_id order by update_time desc) as rn
                     from dw_nd.ods_t_sys_dept
                     where del_flag = 0) t1
               where rn = 1) t1
                  join dw_nd.ods_imp_tjnd_bank_credit_detail t2 on t1.dept_name = t2.bank_name
     ) t3
         -- 祖籍列表包含银行表 或者 部门表id等于银行id
     on FIND_IN_SET(t3.dept_id, t2.ancestors) > 0 or t2.dept_id = t3.dept_id
         left join
     (
         select t1.dept_id,
                t2.序号,
                t2.中文全称
         from dw_nd.ods_t_sys_dept t1 -- 部门表
                  join dw_base.dwd_imp_tjnd_report_bank_financial_institution t2 -- 国农担机构表
                       on t2.中文全称 = if(t1.dept_name like '中国农业发展银行%', '中国农业发展银行', t1.dept_name)
     ) t4 on FIND_IN_SET(t4.dept_id, t2.ancestors) > 0 or t2.dept_id = t4.dept_id
;
commit;
