-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250327
-- 目标表   ：dw_base.ads_rpt_tjnd_finance_record_stat_info 财务部-业务情况统计
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_afg_business_infomation   业务申请表
--          dw_nd.ods_tjnd_yw_afg_business_approval     审批
--          dw_nd.ods_tjnd_yw_afg_voucher_infomation    放款凭证信息
--          dw_nd.ods_tjnd_yw_base_customers_history    BO,客户信息历史表,NEW
--          dw_nd.ods_tjnd_yw_afg_refund_details        退费申请详情表
--          dw_nd.ods_tjnd_yw_afg_voucher_repayment     还款凭证信息
--          dw_nd.ods_tjnd_yw_base_product_management   BO,产品管理,NEW
--          新业务系统逻辑
--          dw_base.dwd_guar_info_all                   担保台账信息
--          dw_nd.ods_t_biz_project_main                主项目表
--          dw_nd.ods_gcredit_loan_ac_dxloanbookfee     费用交易流水信息文件
--          dw_base.dwd_guar_info_stat                  担保台账星型表
--          dw_nd.ods_t_biz_proj_refund                 退费项目表

-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 重跑逻辑

delete from dw_base.ads_rpt_tjnd_finance_record_stat_info where day_id = '${v_sdate}';
commit;

-- 旧业务系统逻辑
 insert into dw_base.ads_rpt_tjnd_finance_record_stat_info
 (day_id, -- 数据日期
  guar_id, -- 业务id
  cust_name, -- 客户(企业)名称
  cert_num, -- 证件号码
  weibao_cont_no, -- 委保合同编号
  gnd_indus_class, -- 企业行业类型
  guar_type, -- 担保类型
  unguar_type, -- 反担保方式
  guar_amt, -- 担保额
  guar_status, -- 担保状态
  loan_enter_date, -- 放款录入日期
  loan_date,       -- 实际放款日期
  in_force_balance, -- 担保余额
  guar_start_date, -- 担保期限（起）
  guar_end_date,   -- 担保期限（止）
  guar_term, -- 担保期限（月）
  loan_bank, -- 贷款银行
  year_guar_rate, -- 年保费比率
  guar_fee, -- 担保保费
  is_peasant_household, -- 是否农业户口
  is_micro_company, -- 是否小微企业
  received_date, -- 保费入账日
  refund_amt, -- 退费金额
  refund_date, -- 退费日期
  unmatured_liability_reserve, -- 未到期责任准备金
  guar_liability_reserve, -- 担保赔偿责任准备金
  extraction_month, -- 提取月份
  receiv_guar_amt,         -- 应收保费总金额(元), 
  disc_guar_amt,           -- 减免保费金额(元), 
  actual_guar_amt,         -- 实际应收保费金额(元), 
  cust_pay_amt             -- 客户缴费金额(元)
 )
 select '${v_sdate}'                             as day_id,
        t1.id                                    as guar_id,
        cust_name,
        cert_num,
        weibao_cont_no,	
		case
            when gnd_indus_class = '08' then '农产品初加工'                                                                           -- 0
            when gnd_indus_class = '01' then '粮食种植'                                                                               -- 1
            when gnd_indus_class = '02' then '重要、特色农产品种植'                                                                    -- 2
            when gnd_indus_class = '04' then '其他畜牧业'                                                                             -- 3
            when gnd_indus_class = '03' then '生猪养殖'                                                                               -- 4
            when gnd_indus_class = '07' then '农产品流通'                                                                             -- 5
            when gnd_indus_class = '05' then '渔业生产'                                                                               -- 6
            when gnd_indus_class = '12' then '农资、农机、农技等农业社会化服务'                                                         -- 7
            when gnd_indus_class = '09' then '农业新业态'                                                                             -- 8
            when gnd_indus_class = '06' then '农田建设'                                                                               -- 9
            when gnd_indus_class = '10' then '其他农业项目'                                                                           -- 10
            end                                  as gnd_indus_class,                                -- 企业行业类型
--        guar_type,
		case when t1.PRODUCT_GRADE = '10' then '供应链担保-饲料行业'
		     when t1.PRODUCT_GRADE = '11' then '农易担(废止)'
             when t1.PRODUCT_GRADE = '12' then '农融担(废止)'
             when t1.PRODUCT_GRADE = '13' then '强村保'
             when t1.PRODUCT_GRADE = '14' then '农担e贷(通用)(废止)'
             when t1.PRODUCT_GRADE = '15' then '津门富民贷(通用)(废止)'
             when t1.PRODUCT_GRADE = '16' then '种植担(废止)'
             when t1.PRODUCT_GRADE = '17' then '文旅保(废止)'
             when t1.PRODUCT_GRADE = '18' then '邮储易贷(通用)'
             when t1.PRODUCT_GRADE = '19' then '农担e贷(种植担)(废止)'
             when t1.PRODUCT_GRADE = '20' then '政银保(废止)'
             when t1.PRODUCT_GRADE = '21' then '农创保(废止)'
             when t1.PRODUCT_GRADE = '23' then '农担e贷(文旅保)(废止)'
             when t1.PRODUCT_GRADE = '24' then '津门富民贷(文旅保)(废止)'
             when t1.PRODUCT_GRADE = '25' then '津门富民贷(种植担)(废止)'
             when t1.PRODUCT_GRADE = '26' then '邮储易贷(文旅保)(废止)'
             when t1.PRODUCT_GRADE = '27' then '邮储易贷(种植担)(废止)'
             when t1.PRODUCT_GRADE = '29' then '种粮担'
			 when t1.PRODUCT_GRADE = '30' then '龙信保'
             when t1.PRODUCT_GRADE = '31' then '畜禽担'
             when t1.PRODUCT_GRADE = '32' then '果香担'
             when t1.PRODUCT_GRADE = '33' then '蔬菜担'
             when t1.PRODUCT_GRADE = '34' then '农贸担'
             when t1.PRODUCT_GRADE = '35' then '农担e贷(畜禽担)(废止)'
             when t1.PRODUCT_GRADE = '36' then '津门富民贷(畜禽担)(废止)'
             when t1.PRODUCT_GRADE = '37' then '津门富民贷(果香担)(废止)'
             when t1.PRODUCT_GRADE = '38' then '津门富民贷(蔬菜担)(废止)'
			 when t1.PRODUCT_GRADE = '40' then '农乐保'
             when t1.PRODUCT_GRADE = '41' then '津门富民贷(农贸担-海吉星)(废止)'
             when t1.PRODUCT_GRADE = '43' then '津门富民贷(其他)(废止)'
             when t1.PRODUCT_GRADE = '44' then '邮储易贷(畜禽担)'
             when t1.PRODUCT_GRADE = '47' then '邮储易贷(农贸担)'
             when t1.PRODUCT_GRADE = '48' then '邮储易贷(其他)'
             when t1.PRODUCT_GRADE = '49' then '农担e贷(种粮担)(废止)'
             when t1.PRODUCT_GRADE = '50' then '其他(废止)'
             when t1.PRODUCT_GRADE = '52' then '津门富民贷(种粮担)(废止)'
             when t1.PRODUCT_GRADE = '53' then '邮储易贷(种粮担)'	
             when t1.PRODUCT_GRADE = '60' then '春耕贷' 			 
		     end as guar_type,               -- 担保类型
		case
            when unguar_type = '["01"]' then '信用/免担保'                                                                            -- []
            when unguar_type = '["04"]' then '保证'                                                                                   -- ["counterGuarantor"]
            when unguar_type = '["02"]' then '抵押'                                                                                   -- ["gage"]
            when unguar_type = '["03"]' then '质押'                                                                                   -- ["collateral"]
            when unguar_type is not null then '组合'
            end                                 as unguar_type,                                     -- 反担保方式
        guar_amt                                as guar_amt,                                        -- 担保额  / 10000    
        case
            when guar_status = '50' then '在保'                                                                                        --  guar_status = 'GT'
            when guar_status in ('93','90') then '解保'                                                                                --  guar_status = 'ED'
            end                                  as guar_status,                                    -- 担保状态
        date_format(loan_enter_date, '%Y-%m-%d') as loan_enter_date,                                -- 放款录入日期 
        date_format(loan_date,'%Y-%m-%d')        as loan_date,                                      -- 实际放款日期
        coalesce(guar_amt,0) - coalesce(repayment_amt,0)        as in_force_balance,                -- 担保余额    / 10000    
        t3.contracr_start_date as guar_start_date,        -- 担保期限（起）
        t3.contracr_end_date   as guar_end_date,          -- 担保期限（止）
        guar_term,
        loan_bank,
        case when coalesce(t3.receiv_guar_amt,0) != coalesce(t3.disc_guar_amt,0) and coalesce(t3.disc_guar_amt,0) != 0 then 0.2           -- [如果应收保费总金额(元)和减免保费金额(元)不一致并且减免报废不为0, 前面的保费费率默认为0.2%]
             else year_guar_rate * 100
			 end                                 as year_guar_rate,    -- 年保费比率
        guar_fee,
        null                                     as is_peasant_household,
        case
            when is_micro_company = '0' then '否'
            when is_micro_company = '1' then '是'
            end                                  as is_micro_company,
        date_format(received_date, '%Y-%m-%d')   as received_date,
        refund_amt,
        refund_date,
        null                                     as unmatured_liability_reserve,
        null                                     as guar_liability_reserve,
        null                                     as extraction_month,
        coalesce(t3.receiv_guar_amt,0) as receiv_guar_amt,         -- 应收保费总金额(元), 
        coalesce(t3.disc_guar_amt,0)   as disc_guar_amt,           -- 减免保费金额(元), 
        coalesce(t3.actual_guar_amt,0) as actual_guar_amt,         -- 实际应收保费金额(元), 
        coalesce(t3.cust_pay_amt,0)    as cust_pay_amt             -- 客户缴费金额(元)
 from (
          select id,                                -- 业务id
                 CUSTOMER_NAME      as cust_name,   -- 客户姓名
                 ID_NUMBER          as cert_num,    -- 证件号码
                 COUNTER_GUR_METHOD as unguar_type, -- 反担保方式
                 GUR_STATE          as guar_status, -- 担保状态
                 ID_CUSTOMER,                       -- 客户id
                 PRODUCT_GRADE                      -- 产品编码
--        from dw_nd.ods_tjnd_yw_afg_business_infomation
		  from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation
--		  where gur_state != '50'                    -- [排除在保转进件]
          where gur_state in ('93','90')             -- 只要解保和代偿
      ) t1
          left join
      (
          select ID_BUSINESS_INFORMATION,                 -- 业务id
                 sum(RECEIPT_AMOUNT)  as guar_amt,        -- 担保额
                 min(LOAN_START_DATE) as loan_date,       -- 实际放款日期
                 min(LOAN_START_DATE) as guar_start_date, -- 贷款起始日期
                 max(LOAN_END_DATE)   as guar_end_date,   --  贷款结束日期
                 max(CREATED_TIME)    as loan_enter_date  -- 放款录入日期
--        from dw_nd.ods_tjnd_yw_afg_voucher_infomation         
          from dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_infomation   -- 放款凭证信息
          where DELETE_FLAG = 1
          group by ID_BUSINESS_INFORMATION
      ) t2 on t1.id = t2.ID_BUSINESS_INFORMATION
          left join
      (
          select ID_BUSINESS_INFORMATION,          -- 业务id
                 WTBZHT_NO      as weibao_cont_no, -- 委托保证合同编号
                 APPROVED_TERM  as guar_term,      -- 本次审批期限
                 FULL_BANK_NAME as loan_bank,      -- 合作银行全称
                 GUARANTEE_TATE as year_guar_rate, -- 担保费率
                 SHARE_FEE      as guar_fee,       -- 实际应收保费
                 RECEIVED_TIME  as received_date,   -- 收费日期
				 GUARANTEE_FEE  as receiv_guar_amt,    -- 应收保费总金额(元),            担保费
		         DISCOUNT_FEE   as disc_guar_amt,      -- 减免保费金额(元),              优惠减免保费金额
		         SHARE_FEE      as actual_guar_amt,    -- 实际应收保费金额(元),          实际应收保费
		         PAIED_IN_PRE   as cust_pay_amt,        -- 客户缴费金额(元)               实收保费
				 date_format(contracr_start_date,'%Y-%m-%d') as contracr_start_date,  -- 合同起始日期
				 date_format(contracr_end_date,'%Y-%m-%d')   as contracr_end_date     -- 合同结束日期
--        from dw_nd.ods_tjnd_yw_afg_business_approval
		  from dw_nd.ods_creditmid_v2_z_migrate_afg_business_approval    -- 审批
      ) t3 on t1.id = t3.ID_BUSINESS_INFORMATION
          left join
      (
          select ID,                                           -- 客户id
                 INDUSTRY_CATEGORY_COMPANY as gnd_indus_class, -- 行业分类(公司)
                 IS_MICRO_COMPANY          as is_micro_company -- 是否小微企业
--        from dw_nd.ods_tjnd_yw_base_customers_history
		  from  dw_nd.ods_creditmid_v2_z_migrate_base_customers_history -- BO,客户信息历史表,NEW
      ) t4 on t1.ID_CUSTOMER = t4.ID
          left join
      (
          select ID_BUSINESS_INFORMATION,                 -- 业务id
                 sum(ACTUAL_REFUND_AMOUNT) as refund_amt, -- 退费金额
                 max(REFUND_DATE)          as refund_date -- 退费日期
--        from dw_nd.ods_tjnd_yw_afg_refund_details
		  from dw_nd.ods_creditmid_v2_z_migrate_afg_refund_details       -- 退费申请详情表
          where DELETE_FLAG = 1
            and OVER_TAG = 'BJ'
          group by ID_BUSINESS_INFORMATION
      ) t5
      on t1.id = t5.ID_BUSINESS_INFORMATION
          left join
      (
          select ID_BUSINESS_INFORMATION,                  -- 业务id
                 sum(REPAYMENT_PRINCIPAL) as repayment_amt -- 还款金额
--        from dw_nd.ods_tjnd_yw_afg_voucher_repayment
		  from dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_repayment    -- 还款凭证信息
          where DELETE_FLAG = 1
          group by ID_BUSINESS_INFORMATION
      ) t6 on t1.ID = t6.ID_BUSINESS_INFORMATION
          left join
      (
          select fieldcode,                -- 产品编码
                 PRODUCT_NAME as guar_type -- 产品名称
--        from dw_nd.ods_tjnd_yw_base_product_management
		  from dw_nd.ods_creditmid_v2_z_migrate_base_product_management  -- BO,产品管理,NEW
      ) t7 on t1.PRODUCT_GRADE = t7.fieldcode;
 commit;


-- 新业务系统逻辑
insert into dw_base.ads_rpt_tjnd_finance_record_stat_info
(day_id, -- 数据日期
 guar_id, -- 业务id
 cust_name, -- 客户(企业)名称
 cert_num, -- 证件号码
 weibao_cont_no, -- 委保合同编号
 gnd_indus_class, -- 企业行业类型
 guar_type, -- 担保类型
 unguar_type, -- 反担保方式
 guar_amt, -- 担保额
 guar_status, -- 担保状态
 loan_enter_date, -- 放款录入日期
 loan_date, -- 实际放款日期
 in_force_balance, -- 担保余额
 guar_start_date, -- 担保期限（起）
 guar_end_date,   -- 担保期限（止）
 guar_term, -- 担保期限（月）
 loan_bank, -- 贷款银行
 year_guar_rate, -- 年保费比率
 guar_fee, -- 担保保费
 is_peasant_household, -- 是否农业户口
 is_micro_company, -- 是否小微企业
 received_date, -- 保费入账日
 refund_amt, -- 退费金额
 refund_date, -- 退费日期
 unmatured_liability_reserve, -- 未到期责任准备金
 guar_liability_reserve, -- 担保赔偿责任准备金
 extraction_month, -- 提取月份
 receiv_guar_amt,  -- 应收保费总金额(元), 
 disc_guar_amt,    -- 减免保费金额(元), 
 actual_guar_amt,  -- 实际应收保费金额(元), 
 cust_pay_amt      -- 客户缴费金额(元)
)
select '${v_sdate}' as day_id,
       t1.guar_id,
       cust_name,
       cert_num,
       coalesce(t1.weibao_cont_no,t9.weibao_cont_no) as weibao_cont_no,   -- 委保合同编号
       gnd_indus_class,
--       guar_type,
       t2.aggregate_scheme as guar_type,  -- 担保类型
       coalesce(t2.unguar_type,t9.unguar_type) as unguar_type,   -- 反担保方式
       guar_amt,
       guar_status,
       date_format(loan_enter_date,'%Y-%m-%d') as loan_enter_date,
       date_format(loan_date,'%Y-%m-%d') as loan_date,
       onguar_amt   as in_force_balance,
       t8.loan_cont_beg_dt  as guar_start_date, -- 担保期限（起）  [以借款合同开始日和借款合同到期日为依据]
       t8.loan_cont_end_dt  as guar_end_date,   -- 担保期限（止）
       guar_term,
       loan_bank,
       case when coalesce(t7.receiv_guar_amt,t9.receiv_guar_amt,0) != coalesce(t7.disc_guar_amt,t9.disc_guar_amt,0) and coalesce(t7.disc_guar_amt,t9.disc_guar_amt,0) != 0 then 0.2   -- [如果应收保费总金额(元)和减免保费金额(元)不一致并且减免报废不为0, 前面的保费费率默认为0.2%]
	        else year_guar_rate
			end     as year_guar_rate,
       guar_fee,
       is_farmer    as is_peasant_household,
       null         as is_micro_company,
       coalesce(t3.received_date,t9.received_date) as received_date,    -- 保费入账日
       refund_amt,
       refund_date,
       null         as unmatured_liability_reserve,
       null         as guar_liability_reserve,
       null         as extraction_month,
	   coalesce(t7.receiv_guar_amt,t9.receiv_guar_amt,0) as receiv_guar_amt,  -- 应收保费总金额(元), 
	   coalesce(t7.disc_guar_amt,t9.disc_guar_amt,0)     as disc_guar_amt,    -- 减免保费金额(元), 
	   coalesce(t1.guar_fee,t9.actual_guar_amt,0)        as actual_guar_amt,  -- 实际应收保费金额(元), [担保保费需要和实际应收保费金额(元)取值一样]
	   COALESCE(t3.cust_pay_amt,t9.cust_pay_amt,0)       as cust_pay_amt      -- 客户缴费金额(元)   承担金额
from (
         select guar_id       as guar_id,         -- 项目编号
                cust_name     as cust_name,       -- 客户名称
                cert_no       as cert_num,        -- 身份证号
                trust_cont_no as weibao_cont_no,  -- 委保合同编号
                guar_class    as gnd_indus_class, -- 行业类型
--                protect_guar  as unguar_type,     -- 反担保措施
                guar_amt      as guar_amt,        -- 放款金额
                item_stt      as guar_status,     -- 项目状态
                loan_reg_dt   as loan_enter_date, -- 放款登记日期
                grant_dt      as loan_date,       -- 放款日期
                loan_begin_dt as guar_start_date, -- 贷款开始时间
                loan_end_dt   as guar_end_date,   -- 贷款结束时间
                loan_term     as guar_term,       -- 贷款合同期限
                loan_bank     as loan_bank,       -- 贷款银行
                guar_rate     as year_guar_rate,  -- 担保费率
                guar_fee      as guar_fee         -- 保费金额
         from dw_base.dwd_guar_info_all_his 
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
     ) t1
         left join
     (
         select code,                 -- 项目编号
                case
                    when guar_type = '01' then '一般保证'
                    when guar_type = '02' then '连带责任保证'
                    end as guar_type, -- 担保类型
                case
                    when is_farmer = '0' then '否'
                    when is_farmer = '1' then '是'
                    end as is_farmer, -- 是否农业户口 0否1是
				case when aggregate_scheme = '01' then '种粮担'
			         when aggregate_scheme = '02' then '畜禽担'
			         when aggregate_scheme = '03' then '果香担'
			         when aggregate_scheme = '04' then '蔬菜担'
					 when aggregate_scheme = '05' then '农贸担' 
					 when aggregate_scheme = '06' then '强村保' 
					 when aggregate_scheme = '07' then '文旅保' 
					 when aggregate_scheme = '08' then '常规业务' 
					 when aggregate_scheme = '09' then '特殊业务' 
					 when aggregate_scheme = '10' then '农贸担-海吉星' 
					 when aggregate_scheme = '11' then '水产担' 
					 when aggregate_scheme = '12' then '鉴银担-宝坻' 
					 when aggregate_scheme = '13' then '王口炒货-邮储银行' 
					 when aggregate_scheme = 'CP202506160001' then '文旅担'
					 when aggregate_scheme = 'CP202504220001' then '"水产担"产品方案'
					 when aggregate_scheme = 'JQ202503050001' then '农贸担-海吉星担保服务方案'
					 when aggregate_scheme = 'CP202503050005' then '强村保"产品方案'
					 when aggregate_scheme = 'CP202503050004' then '"农贸担"产品方案'
					 when aggregate_scheme = 'CP202503050003' then '"蔬菜担"产品方案'
					 when aggregate_scheme = 'CP202503050002' then '"果香担"产品方案'
					 when aggregate_scheme = 'CP202503050001' then '"畜禽担"产品方案'
					 when aggregate_scheme = 'CP202503040001' then '"种粮担"产品方案'
					 else aggregate_scheme 
                     end   as aggregate_scheme,   -- 产业集群
				replace(replace(replace(replace(replace(replace(
                                                       replace(replace(replace(apply_counter_guar_meas, '"', ''), '[', ''), ']', ''),
                                                       '01', '无'),
                                               '02', '抵押'), '03', '质押'), '04', '保证'), '05', '以物抵债'), '00',
               '其他')                                                      as unguar_type,   -- 反担保方式
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main) t1
         where rn = 1
     ) t2 on t1.guar_id = t2.code
         left join
     (
         select drawndn_seqno,                   -- 项目编号
                max(date_format(trade_date,'%Y-%m-%d')) as received_date, -- 保费入账日
                sum(IFNULL(repay_fee_person,0)) as cust_pay_amt           -- 客户缴费金额(元)               
         from dw_nd.ods_gcredit_loan_ac_dxloanbookfee                 -- 费用交易流水信息文件	
         where repay_mode='01' 
         group by drawndn_seqno
     ) t3 on t1.guar_id = t3.drawndn_seqno
         left join
     (
         select guar_id,   -- 项目编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                       -- 项目id
                sum(refund_amount) as refund_amt, -- 退费金额(元)
                max(refund_date)      as refund_date -- 缴费日期
         from (
                  select *, row_number() over (partition by id order by update_time desc) as rn
                  from dw_nd.ods_t_biz_proj_refund
              ) t1
         where rn = 1
         group by project_id
     ) t5 on t4.project_id = t5.project_id
         left join
     (
         select guar_id,
                onguar_amt
         from dw_base.dwd_guar_info_onguar
         where day_id = '${v_sdate}'
     ) t6 on t1.guar_id = t6.guar_id
	 left join (
	            select a1.drawndn_seqno
				      ,sum(a1.schdu_fee) as receiv_guar_amt  -- 应收保费总金额(元), 
					  ,sum(a2.schdu_fee_policy) as disc_guar_amt -- 减免保费金额(元),
--					  ,sum(a2.schdu_fee_person) as actual_guar_amt -- 实际应收保费金额(元),
				from dw_nd.ods_gcredit_loan_ac_dxbillplanfee a1 
				left join (
				            select drawndn_seqno,schdu_fee_person,schdu_fee_policy
				            from (select *,row_number() over(partition by drawndn_seqno order by update_time desc) as rn from dw_nd.ods_gcredit_loan_ac_dxretustatfee) a
						    where a.rn = 1
						  ) a2
                on a1.drawndn_seqno = a2.drawndn_seqno
				where a1.state = '1'
				group by a1.drawndn_seqno
			   ) t7 
	on t1.guar_id = t7.drawndn_seqno
	left join (
	            select proj_no
	                  ,date_format(loan_cont_beg_dt,'%Y-%m-%d') as loan_cont_beg_dt
					  ,date_format(loan_cont_end_dt,'%Y-%m-%d') as loan_cont_end_dt 
			    from dw_base.dwd_agmt_guar_info
			  ) t8
	on t1.guar_id = t8.proj_no
left join (
            select a.GUARANTEE_CODE
				  ,case
                        when a.COUNTER_GUR_METHOD = '["01"]' then '信用/免担保'                                                                            -- []
                        when a.COUNTER_GUR_METHOD = '["04"]' then '保证'                                                                                   -- ["counterGuarantor"]
                        when a.COUNTER_GUR_METHOD = '["02"]' then '抵押'                                                                                   -- ["gage"]
                        when a.COUNTER_GUR_METHOD = '["03"]' then '质押'                                                                                   -- ["collateral"]
                        when a.COUNTER_GUR_METHOD is not null then '组合'
                        end         as unguar_type   -- 反担保方式
			      ,b.GUARANTEE_FEE  as receiv_guar_amt      -- 应收保费总金额(元),            担保费
		          ,b.DISCOUNT_FEE   as disc_guar_amt        -- 减免保费金额(元),              优惠减免保费金额
		          ,b.SHARE_FEE      as actual_guar_amt      -- 实际应收保费金额(元),          实际应收保费
		          ,b.PAIED_IN_PRE   as cust_pay_amt         -- 客户缴费金额(元)               实收保费
				  ,b.WTBZHT_NO      as weibao_cont_no  -- 委托保证合同编号
				  ,date_format(b.RECEIVED_TIME,'%Y-%m-%d')  as received_date   -- 收费日期
			from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation a 
			left join  dw_nd.ods_creditmid_v2_z_migrate_afg_business_approval b   -- 审批
			on a.id = b.ID_BUSINESS_INFORMATION
		  ) t9
on t1.guar_id = t9.GUARANTEE_CODE
;
commit;