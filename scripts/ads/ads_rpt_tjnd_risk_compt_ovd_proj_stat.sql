-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250212
-- 目标表   ：dw_base.ads_rpt_risk_compt_ovd_proj_stat 风险部-省级农担公司逾期及代偿项目情况统计表
-- 源表     ：dw_nd.ods_tjnd_yw_business_book_new 每月业务台账
--          dw_nd.ods_tjnd_yw_bh_compensatory 代偿表
--          dw_nd.ods_tjnd_yw_bh_recovery_tracking 追偿跟踪表
--          dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail 追偿跟踪详情表
--          dw_nd.ods_tjnd_yw_afg_business_infomation 业务申请表
--          dw_nd.ods_tjnd_yw_bh_overdue_plan 逾期登记表
--          dw_nd.ods_tjnd_yw_base_cooperative_institution_agreement BO,机构合作协议,NEW
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- step0 重跑策略
delete
from dw_base.ads_rpt_tjnd_risk_compt_ovd_proj_stat
where day_id = '${v_sdate}';
commit;

-- step1 插入旧系统数据到 省级农担公司逾期及代偿项目情况统计表 中
insert into dw_base.ads_rpt_tjnd_risk_compt_ovd_proj_stat
(day_id, -- 数据日期
 guar_id, -- 业务id
 cust_name, -- 客户名称
 proj_status, -- 项目状态
 ind_name, -- 行业
 main_biz, -- 主营业务
 ln_inst, -- 贷款机构
 prod_name, -- 产品名称
 loan_amt, -- 放款金额（万元）
 ovd_amt, -- 逾期金额（含银行分险）（万元）
 ovd_ucompt_amt, -- 逾期未代偿金额（不含银行分险）（万元）
 bank_cont, -- 银行分险内容
 bank_ratio, -- 银行分险比例
 gover_cont, -- 政府分险内容
 gover_ratio, -- 政府分险比例
 other_cont, -- 地方担保公司等其他机构分险内容
 other_ratio, -- 地方担保公司等其他机构分险比例
 shod_compt_amt, -- 应代偿额（不含银行、政府等其他机构分险部分）（万元）
 compt_amt, -- 截至本季度末累计已代偿额（万元）
 issue_dt, -- 发放日
 exp_dt, -- 到期日
 ovd_dt, -- 逾期日期
 compt_day, -- 代偿宽限期（天）
 compt_dt, -- 代偿日
 claim_cause, -- 出险原因
 claim_cause_detail, -- 出险原因详述
 un_guar_per, -- 反担保措施-反担保人
 un_guar_obj, -- 反担保措施-反担保物
 un_guar_remark, -- 反担保措施备注
 recovery_mode, -- 追偿措施
 risk_amt, -- 截至本季度末累计代偿回收金额
 recovery_risk_amt, -- 1）向客户或反担保人追偿金额（含处置反担保物）
 gover_risk_amt, -- 2）政府分险金额
 other_inst_risk_amt, -- 3）地方担保、再担保、保险等其他机构分险金额
 other_risk_amt, -- 4）其他情况
 remark -- 备注
)
select '${v_sdate}'                                     as day_id,
       -- 业务id
       zt.guar_id                                       as guar_id,
       -- 客户名称
       zt.cust_name                                     as cust_name,
       -- 项目状态
       zt.proj_status                                   as proj_status,
       -- 行业
       ind.FIELDNAME                                    as ind_name,
       -- 主营业务
       zt.main_biz                                      as main_biz,
       -- 贷款机构
       ywsqb.full_bank_name                             as ln_inst,
       -- 产品名称
       pd.PRODUCT_NAME                                  as prod_name,
       -- 放款金额（万元）
       zt.loan_amt                                      as loan_amt,
       -- 逾期金额（含银行分险）（万元）
       zt.ovd_amt                                       as ovd_amt,
       -- 逾期未代偿金额（不含银行分险）（万元）
       case
           when zt.proj_status = '逾期' then round(zt.ovd_amt / 10000, 2)
           else 0 end                                   as ovd_ucompt_amt,
       -- 银行分险内容
       '本息'                                             as bank_cont,
       -- 银行分险比例
       xy.yhfzbl                                        as bank_ratio,
       -- 政府分险内容
       xy.zffxnr                                        as gover_cont,
       -- 政府分险比例
       xy.zffxbl                                        as gover_ratio,
       -- 地方担保公司等其他机构分险内容
       '无'                                              as other_cont,
       -- 地方担保公司等其他机构分险比例
       0                                                as other_ratio,
       -- 应代偿额（不含银行、政府等其他机构分险部分）（万元）
       zt.shod_compt_amt                                as shod_compt_amt,
       -- 截至本季度末累计已代偿额（万元）
       zt.shod_compt_amt                                as compt_amt,
       -- 发放日
       zt.guar_start_date                               as issue_dt,
       -- 到期日
       zt.guar_end_date                                 as exp_dt,
       -- 逾期日期
       zt.ovd_date                                      as ovd_dt,
       -- 代偿宽限期（天）
       xy.dckxt                                         as compt_day,
       -- 代偿日
       zt.compt_date                                    as compt_dt,
       -- 出险原因
       yq.value_desc                                    as claim_cause,
       -- 出险原因详述
       null                                             as claim_cause_detail,
       -- 反担保措施-反担保人
       zt.un_guar_per                                   as un_guar_per,
       -- 反担保措施-反担保物
       zt.un_guar_obj                                   as un_guar_obj,
       -- 反担保措施备注
       concat_ws(',', (case
                           when zt.un_guar_per = '有' and zt.cert_type = 'b' then '企业连带'
                           when zt.un_guar_per = '有' and zt.cert_type = '0' then '个人连带' end),
                 if(zt.un_guar_obj = '有', '抵押物', null)) as un_guar_remark,
       -- 追偿措施
       '自主追偿'                                           as recovery_mode,
       -- 截至本季度末累计代偿回收金额
       zt.risk_amt                                      as risk_amt,
       -- 1）向客户或反担保人追偿金额（含处置反担保物）
       round(ifnull(zc.zhje, 0) / 10000, 6)             as recovery_risk_amt,
       -- 2）政府分险金额
       0                                                as gover_risk_amt,
       -- 3）地方担保、再担保、保险等其他机构分险金额
       0                                                as other_inst_risk_amt,
       -- 4）其他情况
       0                                                as other_risk_amt,
       -- 备注
       null                                             as remark
from (
         select bbn.guar_id,              -- 业务id
                bbn.related_agreement_id, -- 关联协议id
                bbn.cust_name,            -- 客户姓名
                bbn.cert_type,            -- 证件类型
                bbn.indus_gnd,            -- 行业分类国农担标准
                bbn.main_biz,             -- 主营业务
                -- bbn.guarantee_amount 担保金额
                round(bbn.guarantee_amount / 10000, 2)                                       as loan_amt,
                bbn.create_year_month,    -- 更新年月
                -- dc.total_compensation 代偿总额
                round(dc.total_compensation / 10000, 6)                                      as shod_compt_amt,
                -- bbn.ovd_principal 逾期本金
                -- bbn.ovd_interest 逾期利息
                round((if(bbn.ovd_principal is null, 0, bbn.ovd_principal) +
                       if(bbn.ovd_interest is null, 0, bbn.ovd_interest)) / 10000, 6)        as ovd_amt,
                bbn.guar_start_date,      -- 贷款起始日期
                bbn.guar_end_date,        -- 贷款结束日期
                bbn.compt_date,           -- 代偿日期
                bbn.ovd_date,             -- 逾期日期
                -- bbn.is_co_borrower 是否有共同还款人
                case when bbn.is_co_borrower is not null then '有' else '无' end               as un_guar_per,
                -- bbn.is_mortgage 是否有抵押
                -- bbn.is_pledge 是否有质押
                case when bbn.is_mortgage = '是' or bbn.is_pledge = '是' then '有' else '无' end as un_guar_obj,
                -- bbn.recovery_amount 追回金额
                round(bbn.recovery_amount / 10000, 6)                                        as risk_amt,
                bbn.is_compt,             -- 是否代偿
                bbn.is_ovd,               -- 是否逾期
                case
                    when bbn.is_compt is not null then '代偿'
                    when bbn.is_ovd is not null then '逾期'
                    end                                                                      as proj_status
         from dw_nd.ods_tjnd_yw_business_book_new bbn -- 每月最新业务表
                  left join dw_nd.ods_tjnd_yw_bh_compensatory dc -- 代偿表
         -- dc.id_cfbiz_underwriting 关联合同ID
         -- bbn.guar_id 业务id
         -- dc.status 状态
         -- dc.over_tag ??
                            on dc.id_cfbiz_underwriting = bbn.guar_id and dc.status = '1' and dc.over_tag = 'bj'
         where create_year_month = date_format('${v_sdate}', '%Y%m')
     ) zt
         left join
     (
         select t.id,                    -- 主键
                t.id_cfbiz_underwriting, -- 关联合同ID
                d.zhje
         from dw_nd.ods_tjnd_yw_bh_recovery_tracking t -- 追偿跟踪表
                  left join
              (
                  select -- cur_recovery（本次）追回金额
                         sum(cur_recovery) as zhje,
                         id_recovery_tracking -- 关联追偿跟踪ID
                  from dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail -- 追偿跟踪详情表
                  where status = 1
                    and date_format(entry_data, '%Y%m') <= date_format('${v_sdate}', '%Y%m')
                  group by id_recovery_tracking
              ) d
                  -- t.id 主键
                  -- d.id_recovery_tracking 关联追偿跟踪ID
              on t.id = d.id_recovery_tracking
         where t.status = 1 -- 状态
           and t.id_cfbiz_underwriting in -- 关联合同ID
               (select guar_id -- 业务id
                from dw_nd.ods_tjnd_yw_business_book_new -- 每月最新业务表
                where create_year_month = date_format('${v_sdate}', '%Y%m')
                  -- 是否代偿
                  and is_compt = '是')
     ) zc on zt.guar_id = zc.id_cfbiz_underwriting
         left join dw_nd.ods_tjnd_yw_afg_business_infomation ywsqb -- 业务申请表
                   on zt.guar_id = ywsqb.id
         left join (select id_cfbiz_underwriting,
                           if(overdue_reason is null, 13, overdue_reason)                                     as overdue_reason, -- 逾期主要原因 (码值)
                           t2.value_desc,                                                                                        -- 对应字典值
                           row_number() over (partition by ID_CFBIZ_UNDERWRITING order by CREATED_TIME desc ) as rn
                           -- 逾期登记表
                    from dw_nd.ods_tjnd_yw_bh_overdue_plan t1
                             left join (select FIELDCODE as value_code, FIELDNAME as value_desc
                                        from dw_nd.ods_tjnd_yw_base_basicdataselect
                                        where classcode = 'Overdue_reason') t2
                                       on t1.overdue_reason = t2.value_code
) yq on zt.guar_id = yq.id_cfbiz_underwriting and yq.rn = 1
         left join
     (
         select id,                                    -- 主键
                '本息'                    as yhfxnr,     -- 银行分险内容
                bank_org_rate           as yhfzbl,     -- 银行分险比例
                case
                    when gov_org_rate is not null then '本息'
                    else '无'
                    end                 as zffxnr,     -- 政府分险内容
                ifnull(gov_org_rate, 0) as zffxbl,     -- 政府分险比例
                '无'                     as dfdbjgfxnr, -- 地方担保机构分险内容
                '0'                     as dfdbjgfxbl, -- 地方担保机构分险比例
                '本息'                    as ndfxnr,     -- 农担分险内容
                risk_ratio              as ndfxbl,     -- 农担分险比例
                compensation_period     as dckxt       -- 代偿期限[天]
         from dw_nd.ods_tjnd_yw_base_cooperative_institution_agreement -- BO,机构合作协议,NEW
     ) xy on
         -- zt.related_agreement_id 关联协议id
         -- xy.id 主键
         zt.related_agreement_id = xy.id
         left join (select *
                    from dw_nd.ods_tjnd_yw_base_basicdataselect
                    where CLASSCODE = 'SSHY_ND'
                      and `STATUS` = 1) ind on zt.indus_gnd = ind.FIELDCODE
         left join dw_nd.ods_tjnd_yw_base_product_management pd on ywsqb.PRODUCT_GRADE = pd.fieldcode
where zt.proj_status is not null
order by zt.proj_status, guar_start_date desc;
commit;

-- ----------------------------------------------
-- 新业务系统逻辑
insert into dw_base.ads_rpt_tjnd_risk_compt_ovd_proj_stat
(day_id, -- 数据日期
 guar_id, -- 业务id
 cust_name, -- 客户名称
 proj_status, -- 项目状态
 ind_name, -- 行业
 main_biz, -- 主营业务
 ln_inst, -- 贷款机构
 prod_name, -- 产品名称
 loan_amt, -- 放款金额（万元）
 ovd_amt, -- 逾期金额（含银行分险）（万元）
 ovd_ucompt_amt, -- 逾期未代偿金额（不含银行分险）（万元）
 bank_cont, -- 银行分险内容
 bank_ratio, -- 银行分险比例
 gover_cont, -- 政府分险内容
 gover_ratio, -- 政府分险比例
 other_cont, -- 地方担保公司等其他机构分险内容
 other_ratio, -- 地方担保公司等其他机构分险比例
 shod_compt_amt, -- 应代偿额（不含银行、政府等其他机构分险部分）（万元）
 compt_amt, -- 截至本季度末累计已代偿额（万元）
 issue_dt, -- 发放日
 exp_dt, -- 到期日
 ovd_dt, -- 逾期日期
 compt_day, -- 代偿宽限期（天）
 compt_dt, -- 代偿日
 claim_cause, -- 出险原因
 claim_cause_detail, -- 出险原因详述
 un_guar_per, -- 反担保措施-反担保人
 un_guar_obj, -- 反担保措施-反担保物
 un_guar_remark, -- 反担保措施备注
 recovery_mode, -- 追偿措施
 risk_amt, -- 截至本季度末累计代偿回收金额
 recovery_risk_amt, -- 1）向客户或反担保人追偿金额（含处置反担保物）
 gover_risk_amt, -- 2）政府分险金额
 other_inst_risk_amt, -- 3）地方担保、再担保、保险等其他机构分险金额
 other_risk_amt, -- 4）其他情况
 remark -- 备注
)
select '${v_sdate}'                                              as day_id,
       t1.guar_id,
       cust_name,
       proj_status,
       ind_name,
       main_biz,
       ln_inst,
       prod_name,
       loan_amt / 10000,
       ovd_amt / 10000,
       ovd_ucompt_amt / 10000,
       null                                                      as bank_cont,
       bank_ratio,
       null                                                      as gover_cont,
       0                                                         as gover_ratio,
       other_cont,
       other_ratio,
       shod_compt_amt / 10000,
       compt_amt,
       issue_dt,
       exp_dt,
       ovd_dt,
       compt_day,
       compt_dt,
       claim_cause,
       claim_cause_detail,
       case when t7.project_id is not null then '是' else '否' end as un_guar_per,
       case when t8.project_id is not null then '是' else '否' end as un_guar_obj,
       un_guar_remark,
       recovery_mode,
       risk_amt / 10000,
       null                                                      as recovery_risk_amt,
       null                                                      as gover_risk_amt,
       null                                                      as other_inst_risk_amt,
       null                                                      as other_risk_amt,
       null                                                      as remark
from (
         select guar_id       as guar_id,     -- 台账编号
                cust_name     as cust_name,   -- 客户名称
                item_stt      as proj_status, -- 项目状态
                guar_class    as ind_name,    -- 国担行业分类
                loan_bank     as ln_inst,     -- 贷款银行
                guar_prod     as prod_name,   -- 产品名称
                guar_amt      as loan_amt,    -- 放款金额
                loan_begin_dt as issue_dt,    -- 贷款开始时间
                loan_end_dt   as exp_dt       -- 贷款结束时间
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt = '已代偿'
     ) t1
         left join
     (
         select guar_id,  -- 台账编号
                compt_amt -- 代偿金额(本息)(万元)
         from dw_base.dwd_guar_compt_info
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select guar_id,
                project_id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t3 on t1.guar_id = t3.guar_id
         left join
     (
         select code,                          -- 项目id
                main_business_one as main_biz, -- 经营主业
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main
              ) t1
         where rn = 1
     ) t4 on t1.guar_id = t4.code
         left join
     (
         select project_id,
                overdue_totl                         as ovd_amt,           -- 逾期合计
                overdue_totl * (1 - risk_shar_ratio) as ovd_ucompt_amt,    -- 逾期未代偿金额(不含银担分险)
                risk_shar_ratio                      as bank_ratio,        -- 银行分险比例
                apply_comp_amount                    as shod_compt_amt,    -- 申请代偿金额
                overdue_date                         as ovd_dt,            -- 逾期日期
                act_disburse_date                    as compt_dt,          -- 代偿款实际拨付日期
                objective_over_reason                as claim_cause,       -- 客观风险成因
                objective_over_reason_des            as claim_cause_detail -- 客观风险成因说明
         from (
                  select a1.project_id,
                         case when a4.value not in ('已代偿', '已否决', '已终止') then a1.overdue_totl end as overdue_totl,
                         a1.risk_shar_ratio,
                         a1.apply_comp_amount,
                         a1.overdue_date,
                         a1.objective_over_reason_des,
                         a2.act_disburse_date,
                         a3.objective_over_reason,
                         row_number() over (partition by project_id order by a1.db_update_time desc) rn
                  from dw_nd.ods_t_proj_comp_aply a1 -- 代偿申请信息
                           left join dw_nd.ods_t_proj_comp_appropriation a2 -- 拨付信息
                                     on a1.id = a2.comp_id
                           left join dw_nd.ods_t_proj_comp_reason a3 -- 代偿原因
                                     on a1.id = a3.comp_id
                           left join
                       (
                           select * from dw_nd.ods_t_sys_data_dict_value_v2 where dict_code = 'bhProjectStatus'
                       ) a4 on a1.status = a4.code
              ) t1
         where rn = 1
     ) t5 on t3.project_id = t5.project_id
         left join
     (
         select project_id,
                other_remark    as other_cont, -- 其他机构备注
                risk_shar_other as other_ratio -- 其他机构分险比例
         from (
                  select *, row_number() over (partition by project_id order by db_update_time desc) rn
                  from dw_nd.ods_t_proj_comp_risk_share
              ) t1
         where rn = 1
     ) t6 on t3.project_id = t6.project_id
         left join
     (
         select distinct project_id
         from dw_nd.ods_t_ct_guar_person -- 反担保保证信息表
     ) t7 on t3.project_id = t7.project_id
         left join
     (
         select distinct project_id
         from dw_nd.ods_t_ct_guar_pledge -- 质押反担保方式-结构化数据
         union
         select distinct project_id
         from dw_nd.ods_t_ct_guar_mortgage -- 抵押反担保措施所需结构化数据
     ) t8 on t3.project_id = t8.project_id
         left join
     (
         select project_id,
                reply_counter_guar_desc as un_guar_remark -- 反担保措施说明
         from (
                  select *, row_number() over (partition by project_id order by db_update_time desc) rn
                  from dw_nd.ods_t_biz_proj_appr
              ) t1
         where rn = 1
     ) t9 on t3.project_id = t9.project_id
         left join
     (
         select t1.project_id,                                                        -- 项目id
                group_concat(distinct t1.reco_method separator ',') as recovery_mode, -- 追偿措施
                sum(t2.shou_comp_amt)                               as risk_amt       -- 追偿还款金额
         from dw_nd.ods_t_biz_proj_recovery_record t1
                  left join dw_nd.ods_t_biz_proj_recovery_repay_detail_record t2 on t1.reco_id = t2.record_id
         group by t1.project_id
     ) t10 on t3.project_id = t10.project_id
         left join
     (
         select *
         from (select *, row_number() over (partition by dept_id order by update_time desc) as rn
               from dw_nd.ods_t_sys_dept -- 部门表
               where del_flag = 0) t1
         where rn = 1
     ) t11 on t1.ln_inst = t11.dept_name
         left join
     (
         select t1.dept_id,
                t2.bank_name,
                comp_duran as compt_day -- 代偿宽限期
         from (
                  select *
                  from (
                           select *, row_number() over (partition by dept_id order by update_time desc) as rn
                           from dw_nd.ods_t_sys_dept
                           where del_flag = 0
                       ) t1
                  where rn = 1
              ) t1
                  join dw_nd.ods_imp_tjnd_bank_credit_detail t2 on t1.dept_name = t2.bank_name
     ) t12
         -- 祖籍列表包含银行表 或者 部门表id等于银行id
     on FIND_IN_SET(t12.dept_id, t11.ancestors) > 0 or t11.dept_id = t12.dept_id;
commit;

