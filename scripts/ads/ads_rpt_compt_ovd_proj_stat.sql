-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250212
-- 目标表   ：dw_base.ads_rpt_compt_ovd_proj_stat 省级农担公司逾期及代偿项目情况统计表
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
from dw_base.ads_rpt_compt_ovd_proj_stat
where day_id = '${v_sdate}';
commit;

-- step1 插入旧系统数据到 省级农担公司逾期及代偿项目情况统计表 中
insert into dw_base.ads_rpt_compt_ovd_proj_stat
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

-- step2 删除非月底和非近30天数据
delete
from dw_base.ads_rpt_compt_ovd_proj_stat
where day_id <> date_format(last_day(day_id), '%Y%m%d')
  and day_id <= date_format(date_sub('${v_sdate}', interval 30 day), '%Y%m%d');
commit;