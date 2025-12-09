-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250320
-- 目标表   ：dw_base.ads_rpt_tjnd_busi_record_detail   业务部-业务明细
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_afg_business_infomation   业务申请表
--          dw_nd.ods_tjnd_yw_afg_business_approval     审批
--          dw_nd.ods_tjnd_yw_afg_voucher_infomation    放款凭证信息
--          dw_nd.ods_tjnd_yw_base_customers_history    BO,客户信息历史表,NEW
--          dw_nd.ods_tjnd_yw_base_product_management   BO,产品管理,NEW
--          dw_nd.ods_tjnd_yw_afg_voucher_repayment     还款凭证信息
--          dw_nd.ods_tjnd_yw_bh_compensatory           代偿表
--          dw_nd.ods_tjnd_yw_bh_overdue_plan           逾期登记表
--          新业务系统
--          dw_base.dwd_guar_info_all                           担保台账信息
--          dw_base.dwd_guar_info_stat                          担保台账星型表
--          dw_nd.ods_t_biz_project_main                        主项目表
--          dw_nd.ods_t_biz_proj_recovery_record                追偿记录表
--          dw_nd.ods_t_biz_proj_recovery_repay_detail_record   登记还款记录
--          dw_nd.ods_t_biz_proj_repayment_detail
--          dw_base.dwd_guar_info_onguar                        担保台账在保信息
-- 备注     ：
-- 变更记录 ： 20250505 修改了新系统关联 区域映射办事处表 关联字段
--             20251030 农担解保日期
--             20251111 修改：放款日期、担保日期 逻辑
-- ---------------------------------------
-- 临时表
drop table if exists dw_tmp.tmp_ads_rpt_tjnd_busi_record_detail_unguar_reg_dt ;
commit;
create  table dw_tmp.tmp_ads_rpt_tjnd_busi_record_detail_unguar_reg_dt (
ID_BUSINESS_INFORMATION          varchar(50)
,unguar_reg_dt   varchar(10)
,index(ID_BUSINESS_INFORMATION)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit;
insert into dw_tmp.tmp_ads_rpt_tjnd_busi_record_detail_unguar_reg_dt
select ID_BUSINESS_INFORMATION,
       date_format(max(created_time), '%Y-%m-%d')   as unguar_reg_dt
from dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_repayment
where REPAYMENT_PRINCIPAL > 0
  and DELETE_FLAG = 1
group by id_business_information
;
commit;

-- 重跑逻辑
delete from dw_base.ads_rpt_tjnd_busi_record_detail where day_id = '${v_sdate}';
commit;
-- 旧业务系统逻辑
 insert into dw_base.ads_rpt_tjnd_busi_record_detail
 (day_id, -- 数据日期
  guar_id, -- 业务id
  cust_name, -- 客户名称
  cust_type, -- 客户性质
  guar_approved_amt, -- 担保审批金额（万元）
  loan_cont_amt, -- 借款合同金额（万元）
  guar_amt, -- 担保金额（万元）
  in_force_balance, -- 在保余额（万元）
  is_first_guar, -- 是否首担
  loan_date,       -- 放款日期
  guar_start_date, -- 担保开始日期
  guar_end_date,   -- 担保到期日期
  guar_date,       -- 担保日期 -- 放款录入日期
  main_biz, -- 主营业务
  unguar_type, -- 反担保方式
  loan_bank_name, -- 放款银行全称
  guar_approved_rate, -- 担保审批费率(%)
  loan_rate, -- 年贷款利率(%)
  overall_cost, -- 综合成本(%)
  nd_proj_mgr_name, -- 农担项目经理姓名
  prod_type, -- 产品类型
  guar_approved_period, -- 担保审批期限(月）
  gnd_indus_class, -- 行业归类国农担标准
  phone_no, -- 联系方式
  is_guar_sight, -- 是否为见贷即保
  is_micro_company, -- 是否小微企业
  is_support_snzt, -- 是否支持三农主体
  is_support_scsf, -- 是否支持双创双服主体
  is_support_emerging_industry, -- 是否支持战略性新兴产业
  weibao_cont_no, -- 委托保证合同编号
  cert_type, -- 证件类型
  cert_num, -- 证件号码
  warr_cont_no, -- 保证合同编号
  area, -- 区县
  branch_off, -- 办事处
  guar_status, -- 担保状态
  corp_type, -- 企业类型
  repayment_amt, -- 还款本金金额(元)
  repayment_date, -- 还款日期
  is_compt, -- 是否代偿
  is_ovd, -- 是否逾期
   main_type, -- 主体类型
 business_address, -- 经营地址
 id_address, -- 户籍地址
 loan_use, -- 贷款用途
 biz_unguar_dt, -- 解保日期
 nacga_unguar_dt -- 农担解保日期         20251030
 )
 select '${v_sdate}'                                                                 as day_id,
        t1.GUARANTEE_CODE                                                                        as guar_id,
        cust_name,
        case
            when cust_type = '02' then '企业'
            when cust_type = '01' then '个人'
            end                                                                      as cust_type,
        COALESCE(guar_approved_amt,0) / 10000                                                    as guar_approved_amt,
        COALESCE(loan_cont_amt,0) / 10000                                                        as loan_cont_amt,
        COALESCE(guar_amt,0) / 10000                                                             as guar_amt,
        (COALESCE(guar_amt,0) - COALESCE(repayment_amt,0)) / 10000                                           as in_force_balance,
        if(is_first_guar is not null,
           case
               when is_first_guar = '0' then '否'
               when is_first_guar = '1' then '是' end,
           if(t9.CUSTOMER_NAME is null, '是', '否'))                                   as is_first_guar,
        date_format(t3.loan_date, '%Y-%m-%d')            as loan_date,                              -- 放款日期                  20251111 :老系统取afg_voucher_infomation.LOAN_START_DATE, 新系统取本次支取起始日
        date_format(t2.CONTRACR_START_DATE, '%Y-%m-%d')  as guar_start_date,                        -- 担保开始日期              20251111 :担保开始日期取借款合同开始日期, 老系统在afg_business_approval.CONTRACR_START_DATE
        date_format(t2.CONTRACR_END_DATE, '%Y-%m-%d')    as guar_end_date,                          -- 担保到期日期              20251111 :/担保到期日期取/借款合同结束日期 老系统在afg_business_approval./CONTRACR_END_DATE
        date_format(t3.guar_date, '%Y-%m-%d')            as guar_date,                              -- 担保日期 -- 放款录入日期  20251111 ：老系统取afg_voucher_infomation.CREATED_TIME
        main_biz,
        case
            when unguar_type = '["01"]' then '信用/免担保'                                          -- []
            when unguar_type = '["04"]' then '保证'                                                 -- ["counterGuarantor"]
            when unguar_type = '["02"]' then '抵押'                                                 -- ["gage"]
            when unguar_type = '["03"]' then '质押'                                                 -- ["collateral"]
            when unguar_type is not null then '组合'
            end                                                                      as unguar_type,
        loan_bank_name,
        guar_approved_rate * 100                                                     as guar_approved_rate,      -- 担保审批费率(%)
        loan_rate * 100                                                              as loan_rate,               -- 年贷款利率(%)
        coalesce(guar_approved_rate * 100,0) + coalesce(loan_rate * 100,0)           as overall_cost,            -- 综合成本(%)
        nd_proj_mgr_name,
 --       prod_type,               -- 产品类型
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
		     end as prod_type,               -- 产品类型
        guar_approved_period,
        case
            when gnd_indus_class = '08' then '农产品初加工'                                           -- 0
            when gnd_indus_class = '01' then '粮食种植'                                              -- 1
            when gnd_indus_class = '02' then '重要、特色农产品种植'                                     -- 2
            when gnd_indus_class = '04' then '其他畜牧业'                                            -- 3
            when gnd_indus_class = '03' then '生猪养殖'                                              -- 4
            when gnd_indus_class = '07' then '农产品流通'                                            -- 5
            when gnd_indus_class = '05' then '渔业生产'                                              -- 6
            when gnd_indus_class = '12' then '农资、农机、农技等农业社会化服务'                           -- 7
            when gnd_indus_class = '09' then '农业新业态'                                            -- 8
            when gnd_indus_class = '06' then '农田建设'                                              -- 9
            when gnd_indus_class = '10' then '其他农业项目'                                          -- 10
            end                                                                      as gnd_indus_class, 
        phone_no,
        case when is_guar_sight = '见贷即保' then '是'
		     else '否'
             end as                 is_guar_sight,          -- 是否为见贷即保
        case
            when is_micro_company = '0' then '否'
            when is_micro_company = '1' then '是'
            end                                                                      as is_micro_company,
        case
            when is_support_snzt = '0' then '否'
            when is_support_snzt = '1' then '是'
            end                                                                      as is_support_snzt,
        case
            when is_support_scsf = '0' then '否'
            when is_support_scsf = '1' then '是'
            end                                                                      as is_support_scsf,
        case
            when is_support_emerging_industry = '0' then '否'
            when is_support_emerging_industry = '1' then '是'
            end                                                                      as is_support_emerging_industry,
        weibao_cont_no,
        case
            when cert_type = '1' then '身份证'                                                        -- 0
            when cert_type = '2' then '统一社会信用代码'                                               -- b
            end                                                                      as cert_type,
        cert_num,
        guar_cont_no,
--        JSON_UNQUOTE(JSON_EXTRACT(area, '$[1]'))                                     as area,
        coalesce(t11.area_name,t12.area_name)                                       as area,
        case
            when branch_off = 'NHDLBranch'   then '宁河东丽办事处'                                   -- 'YW_NHDLBSC'   
            when branch_off = 'JNBHBranch'   then '津南滨海新区办事处'                               -- 'YW_JNBHXQBSC'  
            when branch_off = 'BCWQBranch'   then '武清北辰办事处'                                   -- 'YW_WQBCBSC'   
            when branch_off = 'XQJHBranch'   then '西青静海办事处'                                   -- 'YW_XQJHBSC'   
            when branch_off = 'JZBranch'     then '蓟州办事处'                                       -- 'YW_JZBSC'     
            when branch_off = 'BDBranch'     then '宝坻办事处'                                       -- 'YW_BDBSC'     
            end                                                                      as branch_off,
        case
            when guar_status = '50' then '在保'                                                       --  guar_status = 'GT'
            when guar_status in ('93','90') then '已解保'                                             --  guar_status = 'ED'
			when guar_status = 'ZZ' then '已终止'
			when guar_status = 'DFK' then '待放款'
            end                                                                      as guar_status,
        case
            when corp_type = '1' then '大型'
            when corp_type = '2' then '中型'
            when corp_type = '3' then '小型'
            when corp_type = '4' then '微型'
            end                                                                      as corp_type,
        COALESCE(repayment_amt,0)                                                    as repayment_amt,   -- 还款本金金额（元）
        date_format(repayment_date, '%Y-%m-%d')                                      as repayment_date,
        if(t7.ID_CFBIZ_UNDERWRITING is not null, '是', '否')                           as is_compt,
        if(t8.ID_CFBIZ_UNDERWRITING is not null, '是', '否')                           as is_ovd,
        case when t4.main_type = '01' then '家庭农场（种养大户）'
             when t4.main_type = '02' then '家庭农场'
             when t4.main_type = '03' then '农业企业'
             when t4.main_type = '04' then '农民专业合作社'
             end as  main_type, -- 主体类型
 t4.business_address, -- 经营地址
 t4.id_address, -- 户籍地址
 t2.loan_use, -- 贷款用途
 date_format(t10.DATE_OF_SET,'%Y%m%d') as biz_unguar_dt, -- 解保日期
 date_format(t13.unguar_reg_dt,'%Y-%m-%d') as nacga_unguar_dt -- 农担解保日期         20251030
 from (
          select ID,                                        -- 业务id
		         GUARANTEE_CODE,                            -- 项目编号       
                 CUSTOMER_NAME         as cust_name,        -- 客户名称
                 CUSTOMER_NATURE       as cust_type,        -- 客户性质
                 COUNTER_GUR_METHOD    as unguar_type,      -- 反担保方式
                 BUSINESS_SP_USER_NAME as nd_proj_mgr_name, -- 农担经理姓名
                 BUSI_MODE_NAME        as is_guar_sight,    -- 是否为见贷即保
                 CERT_TYPE             as cert_type,        -- 证件类型
                 ID_NUMBER             as cert_num,         -- 证件号码
                 AREA                  as area,             -- 区县
                 enter_code            as branch_off,       -- 办事处
                 GUR_STATE             as guar_status,      -- 担保状态
                 FIRST_GUARANTEE       as is_first_guar,    -- 是否首担
                 ID_CUSTOMER,                               -- 客户id
                 PRODUCT_GRADE ,                             -- 产品编码
				 MAINBODY_TYPE_CORP as main_type -- 主体类型    
--          from dw_nd.ods_tjnd_yw_afg_business_infomation
		    from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation
			where gur_state != '50'                    -- [排除在保转进件]
			  and guarantee_code not in ('TJRD-2021-5S93-979U','TJRD-2021-5Z85-959X')        -- [这两笔在进件业务]
      ) t1
          left join
      (
          select ID_BUSINESS_INFORMATION,                      -- 业务id
                 APPROVAL_TOTAL * 10000  as guar_approved_amt,    -- 本次审批金额
                 LOAN_CONTRACT_AMOUNT * 10000 as loan_cont_amt,        -- 借款合同金额
                 FULL_BANK_NAME       as loan_bank_name,       -- 合作银行全称
                 GUARANTEE_TATE       as guar_approved_rate,   -- 担保费率
                 YEAR_LOAN_RATE       as loan_rate,            -- 年贷款利率
                 APPROVED_TERM        as guar_approved_period, -- 本次审批期限
                 WTBZHT_NO            as weibao_cont_no,       -- 委托保证合同编号
                 GUARANTY_CONTRACT_NO as guar_cont_no,          -- 保证合同编号
				 LOAN_PURPOSE          as loan_use, -- 贷款用途
				 CONTRACR_START_DATE,     -- 担保起始日
				 CONTRACR_END_DATE        -- 担保结束日
--      from dw_nd.ods_tjnd_yw_afg_business_approval
		from dw_nd.ods_creditmid_v2_z_migrate_afg_business_approval                -- 审批表
      ) t2 on t1.ID = t2.ID_BUSINESS_INFORMATION
          left join
      (
          select ID_BUSINESS_INFORMATION,                 -- 业务id
                 sum(RECEIPT_AMOUNT) * 10000  as guar_amt,        -- 凭证金额
                 min(LOAN_START_DATE) as loan_date,       -- 贷款起始日期
                 min(LOAN_START_DATE) as guar_start_date, -- 贷款起始日期                           20251111    
                 max(LOAN_END_DATE)   as guar_end_date,   -- 贷款结束日期
				 max(CREATED_TIME)    as guar_date        -- 担保日期 -- 放款录入日期
--          from dw_nd.ods_tjnd_yw_afg_voucher_infomation
            from dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_infomation           -- 放款凭证信息表
          where DELETE_FLAG = 1
          group by ID_BUSINESS_INFORMATION
      ) t3 on t1.id = t3.ID_BUSINESS_INFORMATION
          left join
      (
          select ID,                                                           -- 客户id
                 BUSINESS_ITEM                as main_biz,                     -- 主营业务
                 INDUSTRY_CATEGORY_COMPANY    as gnd_indus_class,              -- 行业分类(公司)
                 TEL                          as phone_no,                     -- 联系电话
                 IS_MICRO_COMPANY             as is_micro_company,             -- 是否小微企业
                 IS_SUPPORT_SNZT              as is_support_snzt,              -- 是否支持三农主题
                 IS_SUPPORT_SCSF              as is_support_scsf,              -- 是否支持双创双服主体
                 IS_SUPPORT_EMERGING_INDUSTRY as is_support_emerging_industry, -- 是否支持战略性新兴产业
                 ENTERPISE_TYPE               as corp_type,                     -- 企业规模
				 OFFICE_ADDRESS               as  business_address, -- 经营地址
				 ADDRESS                 as id_address,  -- 户籍地址
				 MAINBODY_TYPE_CORP  as main_type, -- 主体类型  
				 JSON_UNQUOTE(JSON_EXTRACT(area, '$[1]'))  as area
--          from dw_nd.ods_tjnd_yw_base_customers_history
            from dw_nd.ods_creditmid_v2_z_migrate_base_customers_history         -- 客户表
      ) t4 on t1.ID_CUSTOMER = t4.ID
          left join
      (
          select fieldcode,                -- 产品编码
                 PRODUCT_NAME as prod_type -- 产品名称
--          from dw_nd.ods_tjnd_yw_base_product_management
            from dw_nd.ods_creditmid_v2_z_migrate_base_product_management        -- 产品表
      ) t5 on t1.PRODUCT_GRADE = t5.fieldcode
          left join
      (
          select ID_BUSINESS_INFORMATION,                   -- 业务id
                 sum(REPAYMENT_PRINCIPAL) * 10000 as repayment_amt, -- 还款金额
                 max(REPAYMENT_TIME)      as repayment_date -- 还款时间
--          from dw_nd.ods_tjnd_yw_afg_voucher_repayment
            from dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_repayment          -- 还款凭证信息表
          where DELETE_FLAG = 1
          group by ID_BUSINESS_INFORMATION
      ) t6 on t1.ID = t6.ID_BUSINESS_INFORMATION
          left join
      (
          select ID_CFBIZ_UNDERWRITING -- 业务id
--          from dw_nd.ods_tjnd_yw_bh_compensatory
            from dw_nd.ods_creditmid_v2_z_migrate_bh_compensatory                -- 代偿表
          where status = 1
            and over_tag = 'BJ'
            and DELETED_BY is null
      ) t7 on t1.ID = t7.ID_CFBIZ_UNDERWRITING
          left join
      (
          select ID_CFBIZ_UNDERWRITING -- 业务id
          from (select *, row_number() over (partition by ID_CFBIZ_UNDERWRITING order by CREATED_TIME desc) rn
--                from dw_nd.ods_tjnd_yw_bh_overdue_plan
                  from dw_nd.ods_creditmid_v2_z_migrate_bh_overdue_plan          -- 逾期登记表
                where STATUS = '1') t1
          where rn = 1
      ) t8 on t1.ID = t8.ID_CFBIZ_UNDERWRITING
          left join
      (
          select distinct CUSTOMER_NAME
--          from dw_nd.ods_tjnd_yw_afg_business_infomation
		    from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation
          where GUR_STATE = 'ED' -- 判断是否首担 逻辑
      ) t9 on t1.cust_name = t9.CUSTOMER_NAME
          left join
      (
          select ID_BUSINESS_INFORMATION, -- 业务id
                 DATE_OF_SET              -- 解保日期
--          from dw_nd.ods_tjnd_yw_afg_guarantee_relieve
            from dw_nd.ods_creditmid_v2_z_migrate_afg_guarantee_relieve         -- 担保解除
          where DELETED_FLAG = '1'
            and IS_RELIEVE_FLAG = '0'
      ) t10 on t1.ID = t10.ID_BUSINESS_INFORMATION
	     left join 
	 (
       select area_cd,area_name  from dw_base.dim_area_info where area_lvl = 3 and day_id = '${v_sdate}'		 
	  ) t11 on JSON_UNQUOTE(JSON_EXTRACT(t1.area, '$[1]')) = t11.area_cd
	  left join 
	  (
       select area_cd,area_name  from dw_base.dim_area_info where area_lvl = 3 and day_id = '${v_sdate}'		 
	  ) t12 on t4.area = t12.area_cd
	  left join dw_tmp.tmp_ads_rpt_tjnd_busi_record_detail_unguar_reg_dt t13
	 on t1.ID = t13.ID_BUSINESS_INFORMATION
;
 commit;

-- ------------------------------------
-- 新业务系统逻辑
insert into dw_base.ads_rpt_tjnd_busi_record_detail
(day_id, -- 数据日期
 guar_id, -- 业务id
 cust_name, -- 客户名称
 cust_type, -- 客户性质
 guar_approved_amt, -- 担保审批金额（万元）
 loan_cont_amt, -- 借款合同金额（万元）
 guar_amt, -- 担保金额（万元）
 in_force_balance, -- 在保余额（万元）
 is_first_guar, -- 是否首担
 loan_date, -- 放款日期
 guar_start_date, -- 担保开始日期
 guar_end_date, -- 担保到期日期
 guar_date, -- 担保日期
 main_biz, -- 主营业务
 unguar_type, -- 反担保方式
 loan_bank_name, -- 放款银行全称
 guar_approved_rate, -- 担保审批费率(%)
 loan_rate, -- 年贷款利率(%)
 overall_cost, -- 综合成本(%)
 nd_proj_mgr_name, -- 农担项目经理姓名
 prod_type, -- 产品类型
 guar_approved_period, -- 担保审批期限(月）
 gnd_indus_class, -- 行业归类国农担标准
 phone_no, -- 联系方式
 is_guar_sight, -- 是否为见贷即保
 is_micro_company, -- 是否小微企业
 is_support_snzt, -- 是否支持三农主体
 is_support_scsf, -- 是否支持双创双服主体
 is_support_emerging_industry, -- 是否支持战略性新兴产业
 weibao_cont_no, -- 委托保证合同编号
 cert_type, -- 证件类型
 cert_num, -- 证件号码
 warr_cont_no, -- 保证合同编号
 area, -- 区县
 branch_off, -- 办事处
 guar_status, -- 担保状态
 corp_type, -- 企业类型
 repayment_amt, -- 还款本金金额(元)
 repayment_date, -- 还款日期
 is_compt, -- 是否代偿
 is_ovd, -- 是否逾期
 main_type, -- 主体类型
 business_address, -- 经营地址
 id_address, -- 户籍地址
 loan_use, -- 贷款用途
 biz_unguar_dt, -- 解保日期
 nacga_unguar_dt -- 农担解保日期         20251030
)
select '${v_sdate}'                                                       as day_id,
       t1.guar_id,
       cust_name,
       cust_type,
       guar_approved_amt,
       loan_cont_amt,
       COALESCE(guar_amt,0)                                               as guar_amt,
--       (coalesce(guar_amt,0) - coalesce(repayment_amt,0))                as in_force_balance,
	    if(t1.guar_status = '已放款',
                   if(t1.guar_id like 'TJ%', coalesce(t1.guar_amt, 0) - coalesce(repayment_amt, 0),
                      t1.guar_amt),                                       
			0)                                                           as in_force_balance,
       is_first_guar,
       date_format(t1.loan_date, '%Y-%m-%d')       as loan_date,                                    -- 放款日期         20251111
       date_format(t2.guar_start_date, '%Y-%m-%d') as guar_start_date,                              -- 担保开始日期     20251111    
       date_format(t2.guar_end_date, '%Y-%m-%d')   as guar_end_date,                                -- 担保结束日期     20251111     
       coalesce(date_format(t11.complete_time, '%Y-%m-%d'),date_format(t12.guar_date, '%Y-%m-%d'))  as guar_date,        -- 担保日期 -- 放款录入日期        20251111
       main_biz,
       replace(replace(replace(replace(replace(replace(
                                                       replace(replace(replace(unguar_type, '"', ''), '[', ''), ']', ''),
                                                       '01', '无'),
                                               '02', '抵押'), '03', '质押'), '04', '保证'), '05', '以物抵债'), '00',
               '其他')                                                      as unguar_type,
       loan_bank_name,
       guar_approved_rate,
       loan_rate,
       round(guar_approved_rate + loan_rate, 6)                           as overall_cost,
       nd_proj_mgr_name,
--       prod_type,
       t3.aggregate_scheme                                                as prod_type, -- 产品类型
       guar_approved_period,
       gnd_indus_class,
       phone_no,
       '否'                                                                as is_guar_sight,
       case when corp_type in ('03', '04') then '是' else '否' end          as is_micro_company,
       is_support_snzt,
       case
           when cust_main_label like '%02%' or
                cust_main_label like '%03%' or
                cust_main_label like '%04%' or
                cust_main_label like '%05%' then '是'
           else '否' end                                                   as is_support_scsf,
       case
           when cust_main_label like '%06%' then '是'
           else '否' end                                                   as is_support_emerging_industry,
       coalesce(t1.weibao_cont_no,t9.weibao_cont_no)                       as weibao_cont_no,
       cert_type,
       cert_num,
       warr_cont_no,
       area,
--       case
--           when coalesce(t7.branch_off, t6.branch_off) = 'NHDLBranch' then '宁河东丽办事处'
--           when coalesce(t7.branch_off, t6.branch_off) = 'JNBHBranch' then '津南滨海新区办事处'
--           when coalesce(t7.branch_off, t6.branch_off) = 'BCWQBranch' then '武清北辰办事处'
--           when coalesce(t7.branch_off, t6.branch_off) = 'XQJHBranch' then '西青静海办事处'
--           when coalesce(t7.branch_off, t6.branch_off) = 'JZBranch' then '蓟州办事处'
--           when coalesce(t7.branch_off, t6.branch_off) = 'BDBranch' then '宝坻办事处'
--           end                                                            as branch_off,
       t3.branch                                                            as branch_off,       -- 20250905
       guar_status,
       case
           when corp_type = '01' then '大型企业'
           when corp_type = '02' then '中型企业'
           when corp_type = '03' then '小型企业'
           when corp_type = '04' then '微型企业'
           end                                                            as corp_type,
       case when guar_status = '已解保' then  COALESCE(guar_amt,0) * 10000                                               -- [新系统解保的还款本金金额就取放款金额]
	        else COALESCE(repayment_amt,0) * 10000                                                                       -- [其他状态取还款表的还款本金金额]
            end 			as repayment_amt,             -- 还款本金金额(元)
       repayment_date,
       case when is_compt = '0' then '否' when is_compt = '1' then '是' end as is_compt,
       case when is_ovd = '0' then '否' when is_ovd = '1' then '是' end     as is_ovd,
       main_type,
       business_address,
       id_address,
       loan_use,
       date_format(t8.biz_unguar_dt, '%Y%m%d')                          as biz_unguar_dt,
	   date_format(t10.unguar_reg_dt, '%Y-%m-%d')                         as nacga_unguar_dt -- 农担解保日期         20251030
from (
         select guar_id        as guar_id,              -- 台账编号
                cust_name      as cust_name,            -- 客户名称
                cust_type      as cust_type,            -- 客户类型
                appl_amt       as guar_approved_amt,    -- 申报金额(万元)
                loan_amt       as loan_cont_amt,        -- 贷款合同金额
                guar_amt       as guar_amt,             -- 放款金额
                is_first_guar  as is_first_guar,        -- 是否首保
                grant_dt       as loan_date,            -- 放款时间  （原：loan_notify_dt 放款通知日期） --  20251111  [放款页面上-本次直取起始日]
                loan_reg_dt    as guar_date,            -- 放款登记日期
                loan_bank      as loan_bank_name,       -- 贷款银行
                guar_prod      as prod_type,            -- 担保产品
                aprv_term      as guar_approved_period, -- 批复期限
                guar_class     as gnd_indus_class,      -- 国担分类
                tel_no         as phone_no,             -- 联系电话
                trust_cont_no  as weibao_cont_no,       -- 委保合同编号
                cust_type      as cert_type,            -- 客户类型
                cert_no        as cert_num,             -- 身份证号
                guar_cnot_no   as warr_cont_no,         -- 保证合同编号
                county_name    as area,                 -- 区县
                country_code,                           -- 区县编码
                town_name,                              -- 乡镇/街道
                item_stt       as guar_status,          -- 项目状态
                is_compensate  as is_compt,             -- 是否代偿
                is_ovd         as is_ovd,               -- 是否逾期
                cust_class     as main_type,            -- 主体类型
                loan_use       as loan_use              -- 贷款用途
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
     ) t1
         left join
     (
         select proj_no as guar_id,                 -- 业务编号
                proj_id as project_id,              -- 项目id
                loan_cont_beg_dt as guar_start_date,     -- 贷款开始时间   借款合同开始日
                loan_cont_end_dt  as guar_end_date,      -- 贷款结束时间   借款合同到期日
                guar_rate    as guar_approved_rate, -- 担保利率
                loan_cont_rate    as loan_rate           -- 贷款利率
         from dw_base.dwd_agmt_guar_info
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select code,                                        -- 项目id
                main_business_one       as main_biz,         -- 经营主业
                enterprise_scale        as corp_type,        -- 企业规模
                case when is_farmer = '1' then '是'
                     when is_farmer = '0' then '否'				
					 end as is_support_snzt,  -- 是否支持三农主体
                cust_main_label,                             -- 客户主体标签
                cust_addr               as business_address, -- 经营地址
                ID_ADDRESS              as id_address,       -- 户籍地址
                apply_counter_guar_meas as unguar_type,      -- 反担保方式
                wf_inst_id,
                fk_manager_name         as nd_proj_mgr_name, -- 农担项目经理
                rn,
				case when t1.branch like '%宁河%' then '宁河东丽办事处'
			         when t1.branch like '%津南%' then '津南滨海新区办事处' 
					 when t1.branch like '%武清%' then '武清北辰办事处'
					 when t1.branch like '%静海%' then '西青静海办事处'
					 when t1.branch like '%蓟州%' then '蓟州办事处'
					 when t1.branch like '%宝坻%' then '宝坻办事处'
                     end                as    branch,   -- 分支机构                               20250905 		
				case when product_code = 'PA00805021'  then '津沽担（线上签约）'
                     when product_code = 'PA0080503P'  then '客户直通'
                     when product_code = 'PA0080503'   then '客户直通'
                     when product_code = 'PA0080502'   then '津沽担'
					 end as   prod_type -- 产品类型
					 ,t1.product_name
			   ,case when aggregate_scheme = '01' then '种粮担'
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
                     end   as aggregate_scheme   -- 产业集群
         from (
                  select t1.*,
                         t2.ID_ADDRESS,
						 t3.product_name,
                         row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main t1
                           left join dw_nd.ods_wxapp_cust_login_info t2
                                     on t1.cust_id = t2.CUSTOMER_ID
						   left join (select apply_code,product_name from (select *,row_number() over (partition by apply_code order by update_time desc) as rn from dw_nd.ods_bizhall_guar_apply) a where a.rn = 1) t3 
						             on t1.apply_id = t3.apply_code
              ) t1
         where rn = 1
     ) t3 on t1.guar_id = t3.code
         left join
     (
         select project_id,                                    -- 项目id
            --    sum(actual_repayment_amount) as repayment_amt, -- 还款金额
			    sum(repayment_principal) / 10000     as repayment_amt, -- 还款金额    还款本金金额     20250905
                max(repay_date)              as repayment_date -- 还款日期
         from (
		        select *,row_number() over (partition by id order by db_update_time desc) as rn  from dw_nd.ods_t_biz_proj_repayment_detail
			  ) a
		 where a.rn = 1
         group by project_id
     ) t4 on t2.project_id = t4.project_id
         left join
     (
         select guar_id,
                onguar_amt as in_force_balance -- 在保余额
         from dw_base.dwd_guar_info_onguar
         where day_id = '${v_sdate}'
     ) t5 on t1.guar_id = t5.guar_id
         left join
     (
         select CITY_CODE_,              -- 区县编码
                ROLE_CODE_ as branch_off -- 办事处编码
         from dw_base.dwd_imp_area_branch
     ) t6 on t1.country_code = t6.CITY_CODE_
         left join
     (
         select CITY_NAME_,              -- 区县编码
                ROLE_CODE_ as branch_off -- 办事处编码
         from dw_base.dwd_imp_area_branch
     ) t7 on t1.town_name = t7.CITY_NAME_
         left join
     (
         select biz_no, biz_unguar_dt
         from dw_base.dwd_guar_biz_unguar_info
     ) t8 on t1.guar_id = t8.biz_no
	 left join (
	            select ID_BUSINESS_INFORMATION,                      -- 业务id
                       WTBZHT_NO            as weibao_cont_no       -- 委托保证合同编号
--      from dw_nd.ods_tjnd_yw_afg_business_approval
		        from dw_nd.ods_creditmid_v2_z_migrate_afg_business_approval
			   ) t9
	 on t2.project_id = t9.ID_BUSINESS_INFORMATION
	 left join (
	            select proj_no_prov                                                     -- 农担体系担保项目编号
					  ,max(unguar_dt)     as unguar_dt                                      -- 解保日期             [多条记录分组取最近日期]
					  ,max(unguar_reg_dt) as unguar_reg_dt                                  -- 解保登记日期         [多条记录分组取最近日期]
                      ,sum(case when year(unguar_reg_dt) = left('${v_sdate}',4) then unguar_amt else 0 end) as  year_unguar_amt       --	本年新增解保金额     [sum(解保金额) where 解保登记日期=本年]
                from dw_base.dwd_tjnd_report_proj_unguar_info           --  解保记录表
                where day_id = '${v_sdate}'                                                              
                group by proj_no_prov
			   ) t10
	 on t1.guar_id = t10.proj_no_prov
	 left join (
	             select code
				       ,complete_time     -- 流程完成时间
				 from (select *,row_number()over(partition by code order by db_update_time desc) rn from dw_nd.ods_t_biz_project_main) b
				 where b.rn = 1
			   ) t11
	 on t1.guar_id = t11.code
	 left join
      (
          select c1.GUARANTEE_CODE,                 -- 项目编号
				 max(c2.CREATED_TIME)    as guar_date        -- 担保日期 -- 放款录入日期
--          from dw_nd.ods_tjnd_yw_afg_voucher_infomation
            from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation c1 
			left join dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_infomation c2          -- 放款凭证信息表
			on c1.id = c2.ID_BUSINESS_INFORMATION
          where c2.DELETE_FLAG = 1
          group by c1.GUARANTEE_CODE
      ) t12 
	 on  t1.guar_id = t12.GUARANTEE_CODE
;
commit;



