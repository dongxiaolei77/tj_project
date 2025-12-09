-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250327
-- 目标表   ：dw_base.ads_rpt_tjnd_finance_refund_detail    财务部-退费
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_afg_refund_details        退费申请详情表
--          dw_nd.ods_tjnd_yw_afg_business_infomation   业务申请表
--          dw_nd.ods_tjnd_yw_afg_business_approval     审批
--          dw_nd.ods_tjnd_yw_afg_voucher_infomation    放款凭证信息
--          dw_nd.ods_tjnd_yw_base_product_management   BO,产品管理,NEW
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 重跑策略

delete from dw_base.ads_rpt_tjnd_finance_refund_detail where day_id = '${v_sdate}';
commit;
-- 旧业务系统逻辑
 insert into dw_base.ads_rpt_tjnd_finance_refund_detail
 (day_id, -- 数据日期
  guar_id, -- 业务id(可能多笔)
  cust_name, -- 客户姓名
  cert_num, -- 证件号码
  weibao_cont_no, -- 委托保证合同编号
  product_name, -- 产品
  product_system, -- 产品体系
  refund_amt, -- 审批金额
  loan_cont_amt, -- 合同金额
  apply_term, -- 申请期限
  loan_start_date, -- 合同起始日期
  loan_end_date, -- 合同到期日期
  clear_date, -- 结清日期
  nd_proj_mgr -- 项目经理
 )
 select '${v_sdate}'               as day_id,
        t1.ID_BUSINESS_INFORMATION as guar_id,
        cust_name,
        cert_num,
        weibao_cont_no,
        product_name,
        product_system,
        refund_amt,
        loan_cont_amt * 10000 as loan_cont_amt,  -- 合同金额
        apply_term,
        loan_start_date,
        loan_end_date,
        clear_date,
        nd_proj_mgr
 from (
          select ID_BUSINESS_INFORMATION,         -- 业务id
                 CUSTOMER_NAME     as cust_name,  -- 客户姓名
                 ID_NUMBER         as cert_num,   -- 证件号码
                 REFUNDABLE_AMOUNT as refund_amt, -- 应退费金额
                 CLEAR_DATE        as clear_date, -- 结清日期
                 TRANSFEROR,                      -- 用户id
                 PRODUCT_CODE                     -- 产品编码
--          from dw_nd.ods_tjnd_yw_afg_refund_details
		  from dw_nd.ods_creditmid_v2_z_migrate_afg_refund_details -- 退费申请详情表
          where DELETE_FLAG = 1
      ) t1
          left join
      (
          select ID,                              -- 业务id
                 BUSI_MODE_NAME as product_system -- 业务模式名称
--          from dw_nd.ods_tjnd_yw_afg_business_infomation
		  from dw_nd.ods_tjnd_yw_afg_business_infomation -- 业务申请表
      ) t2 on t1.ID_BUSINESS_INFORMATION = t2.ID
          left join
      (
          select ID_BUSINESS_INFORMATION,                -- 业务id
                 WTBZHT_NO            as weibao_cont_no, -- 委托保证合同编号
                 LOAN_CONTRACT_AMOUNT as loan_cont_amt,  -- 借款合同金额
                 APPROVED_TERM        as apply_term      -- 本次审批期限
--          from dw_nd.ods_tjnd_yw_afg_business_approval
		  from dw_nd.ods_creditmid_v2_z_migrate_afg_business_approval -- 审批
      ) t3 on t1.ID_BUSINESS_INFORMATION = t3.ID_BUSINESS_INFORMATION
          left join
      (
          select ID_BUSINESS_INFORMATION,                 -- 业务id
                 min(loan_start_date) as loan_start_date, -- 贷款起始日期
                 max(loan_end_date)   as loan_end_date    -- 贷款结束日期
--          from dw_nd.ods_tjnd_yw_afg_voucher_infomation
		  from dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_infomation -- 放款凭证信息
          where DELETE_FLAG = 1
          group by ID_BUSINESS_INFORMATION
      ) t4 on t1.ID_BUSINESS_INFORMATION = t4.ID_BUSINESS_INFORMATION
          left join
      (
          select fieldcode,   -- 产品编码
                 product_name -- 产品名称
--          from dw_nd.ods_tjnd_yw_base_product_management
		  from dw_nd.ods_creditmid_v2_z_migrate_base_product_management -- BO,产品管理,NEW
      ) t5 on t1.PRODUCT_CODE = t5.fieldcode
          left join
      (
          select userid,                 -- 项目经理id
                 username as nd_proj_mgr -- 项目经理姓名
--          from dw_nd.ods_tjnd_yw_base_operator
		  from dw_nd.ods_creditmid_v2_base_operator -- 用户信息表
      ) t6 on t1.TRANSFEROR = t6.userid;
 commit;

-- --------------------------------------------------
-- 新业务系统逻辑
insert into dw_base.ads_rpt_tjnd_finance_refund_detail
(day_id, -- 数据日期
 guar_id, -- 业务id(可能多笔)
 cust_name, -- 客户姓名
 cert_num, -- 证件号码
 weibao_cont_no, -- 委托保证合同编号
 product_name, -- 产品
 product_system, -- 产品体系
 refund_amt, -- 退费金额
 loan_cont_amt, -- 合同金额
 apply_term, -- 申请期限
 loan_start_date, -- 合同起始日期
 loan_end_date, -- 合同到期日期
 clear_date, -- 结清日期
 nd_proj_mgr, -- 项目经理
 branch_manager_name, -- 农担分支机构项目经理名称
 refund_date -- 退费日期
)
select '${v_sdate}'                                 as day_id,
       t1.guar_id,
       cust_name,
       cert_num,
       weibao_cont_no,
       product_type                                 as product_name,
       case when guar_product = '01' then '津沽担' end as product_system,
       refund_amt,
       loan_cont_amt,
       apply_term,
       loan_start_date,
       loan_end_date,
       clear_date,
       nd_proj_mgr,
       branch_manager_name,
       refund_date                                  as refund_date
from (
         select guar_id       as guar_id,         -- 项目编号
                cust_name     as cust_name,       -- 客户姓名
                cert_no       as cert_num,        -- 身份证号
                trust_cont_no as weibao_cont_no,  -- 委保合同编号
                loan_amt      as loan_cont_amt,   -- 贷款合同金额
                aprv_term     as apply_term,      -- 批复期限
                loan_begin_dt as loan_start_date, -- 贷款开始时间
                loan_end_dt   as loan_end_date    -- 贷款结束时间
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
     ) t1
         left join
     (
         select guar_id,   -- 项目编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         inner join
     (
         select project_id,                  -- 项目id
                refund_amount as refund_amt, -- 退费金额
                pay_date      as clear_date, -- 结清日期
                refund_date
         from (
                  select *, row_number() over (partition by id order by update_time desc) as rn
                  from dw_nd.ods_t_biz_proj_refund) t1
         where rn = 1
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select code,                       -- 项目id
                create_name as nd_proj_mgr, -- 创建者
                branch_manager_name,        -- 分支机构项目经理
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main) t1
         where rn = 1
     ) t4 on t1.guar_id = t4.code
         left join
     (
         select project_id,
                guar_product,
                aggregate_scheme
         from (
                  select *, row_number() over (partition by id order by update_time desc) as rn
                  from dw_nd.ods_t_risk_check_opinion
              ) t1
         where rn = 1
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select code, value as product_type
         from (
                  select *, row_number() over (partition by id order by update_time desc) as rn
                  from dw_nd.ods_t_sys_data_dict_value_v2
                  where dict_code = 'aggregateScheme'
              ) t1
         where rn = 1
     ) t6 on t5.aggregate_scheme = t6.code
;
commit;

