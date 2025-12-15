-- ---------------------------------------
-- 开发人   : zzy
-- 开发时间 ：20251120
-- 目标表   ：dw_base.ads_rpt_tjnd_unguar_info 报表-解保台账表
-- 旧源表     ：dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation
--              dw_nd.ods_creditmid_v2_z_migrate_base_customers_history  
--              dw_base.dim_area_info
--              dw_nd.ods_creditmid_v2_z_migrate_afg_business_approval
--              dw_nd.ods_creditmid_v2_z_migrate_afg_guarantee_relieve 
-- 新源表    ：dw_base.dwd_guar_info_all             
--             dw_base.dwd_guar_info_stat        
--             dw_nd.ods_t_biz_proj_unguar   
--              dw_nd.ods_t_biz_project_main
--             dw_nd.ods_creditmid_v2_z_migrate_afg_business_approval
--             dw_nd.ods_t_biz_proj_sign
--             dw_nd.ods_t_proj_comp_aply
--             dw_nd.ods_t_act_hi_taskinst_v2
--             dw_nd.ods_t_act_re_procdef_v2
--
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 重跑策略



delete from dw_base.ads_rpt_tjnd_unguar_info where day_id = '${v_sdate}';
commit;

-- 老系统逻辑
insert into dw_base.ads_rpt_tjnd_unguar_info
(
day_id 
,project_id	        --  原业务编号
,guar_id	        --  业务编号
,province	        --  所属省份
,city	            --  所属地市
,district	        --  所属区县
,cust_type	        --  主体类型
,cust_class	        --  客户类型
,cust_name	        --  客户名称
,cert_no	            --  证件号码
,loan_bank	        --  贷款银行
,loan_no	            --  借款合同编号
,loan_amt	        --  借款合同金额(万元)
,loan_term	        --  借款合同期限(月)
,loan_cont_beg_dt	--  借款合同开始日
,loan_cont_end_dt	--  借款合同到期日
,loan_rate	        --  借款合同利率	
,repay_date	        --  贷款结清日
,nacga_unguar_dt	--  农担解保日期
,unguar_type	        --  解保类型（正常解保, 提前解保, 免除担保责任, 代偿解保）
,unguar_stat	        --  解保状态
,guar_rate	        --  担保费率
,counter_guar_meas	--  反担保方式
,branch_manager_name	--  农担项目经理姓名
,prod_type	        --  产品类型
,gnd_indus_class	    --  行业归类国农担标准
,weibao_cont_no	    --  委托保证合同编号
,warr_cont_no	    --  保证合同编号
,branch_off	        --  办事处
,enterprise_scale	--  企业类型
,tel_no	            --  联系方式
,guar_amt           --  担保金额(万元)
,cyr_unguar_amt      --  本年解保金额(万元)
)
select  '${v_sdate}'  as day_id 
       ,ID as project_id	        --  原业务编号
       ,GUARANTEE_CODE as guar_id	        --  业务编号
       ,t3.sup_area_name as province	        --  所属省份
       ,t2.sup_area_name as city	            --  所属地市
       ,t2.area_name     as district	        --  所属区县
       , case
            when t1.cust_type = '02' then '企业'
            when t1.cust_type = '01' then '个人'
            end          as cust_type	        --  主体类型
       ,case when t1.main_type = '01' then '家庭农场（种养大户）'
             when t1.main_type = '02' then '家庭农场'
             when t1.main_type = '03' then '农业企业'
             when t1.main_type = '04' then '农民专业合作社'
             end         as cust_class	        --  客户类型
       ,t1.cust_name	        --  客户名称
       ,t1.cert_no	            --  证件号码
       ,t4.loan_bank_name as loan_bank	        --  贷款银行
       ,t4.loan_contract_no as loan_no	            --  借款合同编号
       ,coalesce(t4.loan_cont_amt,0) / 10000 as loan_amt	        --  借款合同金额(万元)
       ,t4.guarantee_period as loan_term	        --  借款合同期限(月)
       ,date_format(t4.CONTRACR_START_DATE,'%Y-%m-%d') as loan_cont_beg_dt	--  借款合同开始日
       ,date_format(t4.CONTRACR_END_DATE,'%Y-%m-%d')   as loan_cont_end_dt	--  借款合同到期日
       ,t4.loan_rate * 100                             as loan_rate	        --  借款合同利率	
       ,date_format(t5.date_of_set,'%Y-%m-%d')      as repay_date	    --  贷款结清日
       ,date_format(t7.unguar_reg_dt,'%Y-%m-%d')        as nacga_unguar_dt	--  农担解保日期
       ,case when t1.guar_status = '90' then '正常解保'
             when t1.guar_status = '93' then '代偿解保'
	         end           as unguar_type	        --  解保类型（正常解保, 提前解保, 免除担保责任, 代偿解保）
       ,case when t1.guar_status = '90' then '已解保'
             when t1.guar_status = '93' then '已代偿'
	         end           as unguar_stat	        --  解保状态
       ,t4.guar_approved_rate * 100 as guar_rate	        --  担保费率
       ,case when t1.counter_guar_meas = '01' then '信用/免担保'
	         when t1.counter_guar_meas = '02' then '抵押'
	         when t1.counter_guar_meas = '03' then '质押'
	         when t1.counter_guar_meas = '04' then '保证'
	         when t1.counter_guar_meas = '05' then '信用/免担保'
			 when t1.counter_guar_meas = '06' then '抵押'
			 when t1.counter_guar_meas = '9999' then '组合'
               end  counter_guar_meas	--  反担保方式              [国农担的码值]
       ,t1.nd_proj_mgr_name as branch_manager_name	--  农担项目经理姓名
       ,case when t1.PRODUCT_GRADE = '10' then '供应链担保-饲料行业'
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
		     end                 as prod_type               -- 产品类型
       ,case
            when t1.gnd_indus_class = '08' then '农产品初加工'                                           -- 0
            when t1.gnd_indus_class = '01' then '粮食种植'                                              -- 1
            when t1.gnd_indus_class = '02' then '重要、特色农产品种植'                                     -- 2
            when t1.gnd_indus_class = '04' then '其他畜牧业'                                            -- 3
            when t1.gnd_indus_class = '03' then '生猪养殖'                                              -- 4
            when t1.gnd_indus_class = '07' then '农产品流通'                                            -- 5
            when t1.gnd_indus_class = '05' then '渔业生产'                                              -- 6
            when t1.gnd_indus_class = '12' then '农资、农机、农技等农业社会化服务'                           -- 7
            when t1.gnd_indus_class = '09' then '农业新业态'                                            -- 8
            when t1.gnd_indus_class = '06' then '农田建设'                                              -- 9
            when t1.gnd_indus_class = '10' then '其他农业项目'                                          -- 10
            end                 as gnd_indus_class	    --  行业归类国农担标准
       ,t4.weibao_cont_no	--  委托保证合同编号
       ,t4.warr_cont_no	    --  保证合同编号
       ,case
            when t1.branch_off = 'NHDLBranch'   then '宁河东丽办事处'                                   -- 'YW_NHDLBSC'   
            when t1.branch_off = 'JNBHBranch'   then '津南滨海新区办事处'                               -- 'YW_JNBHXQBSC'  
            when t1.branch_off = 'BCWQBranch'   then '武清北辰办事处'                                   -- 'YW_WQBCBSC'   
            when t1.branch_off = 'XQJHBranch'   then '西青静海办事处'                                   -- 'YW_XQJHBSC'   
            when t1.branch_off = 'JZBranch'     then '蓟州办事处'                                       -- 'YW_JZBSC'     
            when t1.branch_off = 'BDBranch'     then '宝坻办事处'                                       -- 'YW_BDBSC'     
            end                  as branch_off	        --  办事处
       ,case
            when t1.corp_type = '1' then '大型'
            when t1.corp_type = '2' then '中型'
            when t1.corp_type = '3' then '小型'
            when t1.corp_type = '4' then '微型'
            end                  as enterprise_scale	--  企业类型（大中小微那种划分）
       ,t1.tel_no	                                    --  联系方式
	   ,t6.guar_amt
-- 老系统已经解保的业务
-- 1. 所有包含还款本金的还款记录都是在2025年录入的, 今年解保金额就是放款金额
-- 2. 部分包含还款本金的还款记录是在去年录入的, 今年解保金额就是放款金额-2025年之前录入的还款本金累加
	   ,case when t7.ID_BUSINESS_INFORMATION is not null and t7.last_accu_unguar_amt = 0 and t7.cyr_unguar_amt != 0 then t6.guar_amt
	         when t7.ID_BUSINESS_INFORMATION is not null and t7.last_accu_unguar_amt != 0 then coalesce(t6.guar_amt,0) - coalesce(t7.last_accu_unguar_amt,0)
			 else 0
	         end                 as cyr_unguar_amt      --  本年解保金额(万元)
from (
          select a.ID,                                        -- 业务id
		         a.GUARANTEE_CODE,                            -- 项目编号       
                 a.CUSTOMER_NAME         as cust_name,        -- 客户名称
                 a.CUSTOMER_NATURE       as cust_type,        -- 客户性质
				 case when a.COUNTER_GUR_METHOD like '%,%' then '9999' /*多个反担保方式代码的，置成组合*/
                      when regexp_replace(regexp_replace(a.COUNTER_GUR_METHOD, '\\[|\\]|null|\\"|', ''), '^(,*+)', '') = '00' then '01' /*剔除不规则数据*/
                      else coalesce(if(length(regexp_replace(regexp_replace(a.COUNTER_GUR_METHOD, '\\[|\\]|null|\\"|', ''), '^(,*+)', '')) = 0
					                   , '01'
									   ,regexp_replace(regexp_replace(a.COUNTER_GUR_METHOD, '\\[|\\]|null|\\"|', ''),'^(,*+)', ''))
									, '01') /*空值置成01*/
                      end                as counter_guar_meas, --  反担保方式
                 a.BUSINESS_SP_USER_NAME as nd_proj_mgr_name, -- 农担经理姓名
                 a.BUSI_MODE_NAME        as is_guar_sight,    -- 是否为见贷即保
                 a.CERT_TYPE             as cert_type,        -- 证件类型
                 a.ID_NUMBER             as cert_no,          -- 证件号码
                 coalesce(JSON_UNQUOTE(JSON_EXTRACT(a.area, '$[1]')),JSON_UNQUOTE(JSON_EXTRACT(b.area, '$[1]'))) as area,             -- 区县
                 a.enter_code            as branch_off,       -- 办事处
                 a.GUR_STATE             as guar_status,      -- 担保状态
                 a.ID_CUSTOMER,                               -- 客户id
                 a.PRODUCT_GRADE ,                            -- 产品编码
                 b.ID as cust_id,                                                -- 客户id 
                 b.BUSINESS_ITEM                as main_biz,                     -- 主营业务
                 b.INDUSTRY_CATEGORY_COMPANY    as gnd_indus_class,              -- 行业分类(公司)
                 b.TEL                          as tel_no,                     -- 联系电话
                 b.ENTERPISE_TYPE               as corp_type,                    -- 企业规模
                 b.OFFICE_ADDRESS               as  business_address, -- 经营地址 
                 b.ADDRESS                      as id_address,        -- 户籍地址
                 b.MAINBODY_TYPE_CORP           as main_type          -- 主体类型  			
		    from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation a             -- 申请表
			left join dw_nd.ods_creditmid_v2_z_migrate_base_customers_history b         -- 客户表
			on a.ID_CUSTOMER = b.ID
			where a.gur_state != '50'                    -- [排除在保转进件]
			  and a.guarantee_code not in ('TJRD-2021-5S93-979U','TJRD-2021-5Z85-959X')        -- [这两笔在进件业务]
			  and a.gur_state in ('90','93')
     ) t1
left join (select area_cd,area_name,sup_area_cd,sup_area_name from dw_base.dim_area_info where area_lvl = '3' ) t2 
on t1.area = t2.area_cd 
left join (select area_cd,area_name,sup_area_cd,sup_area_name from dw_base.dim_area_info where area_lvl = '2' ) t3
on t2.sup_area_cd = t3.area_cd 
left join(
           select ID_BUSINESS_INFORMATION,                      -- 业务id
                  APPROVAL_TOTAL * 10000  as guar_approved_amt,    -- 本次审批金额
                  LOAN_CONTRACT_AMOUNT * 10000 as loan_cont_amt,        -- 借款合同金额
                  FULL_BANK_NAME       as loan_bank_name,       -- 合作银行全称
                  GUARANTEE_TATE       as guar_approved_rate,   -- 担保费率
                  YEAR_LOAN_RATE       as loan_rate,            -- 年贷款利率
                  APPROVED_TERM        as guar_approved_period, -- 本次审批期限
                  WTBZHT_NO            as weibao_cont_no,       -- 委托保证合同编号
                  GUARANTY_CONTRACT_NO as warr_cont_no,          -- 保证合同编号
				  LOAN_PURPOSE          as loan_use, -- 贷款用途
				  CONTRACR_START_DATE,     -- 担保起始日
				  CONTRACR_END_DATE        -- 担保结束日
				, loan_contract_no        -- 借款合同编号
				, guarantee_period        -- 担保期限
		   from dw_nd.ods_creditmid_v2_z_migrate_afg_business_approval                -- 审批表
         ) t4 
on t1.ID = t4.ID_BUSINESS_INFORMATION
left join (
             select id_business_information
                  , max(date_of_set)          as date_of_set  -- 解保日期  （贷款结清日）
--				  , CREATED_TIME
             from dw_nd.ods_creditmid_v2_z_migrate_afg_guarantee_relieve -- 解保表
             where deleted_flag = 1
               and IF_RELIEVE_TYPE = 1
               and IS_RELIEVE_FLAG = 0      
             group by  id_business_information 			   
		  ) t5 
on t1.ID = t5.id_business_information
left join (
            select ID_BUSINESS_INFORMATION,                        -- 业务id
                   sum(RECEIPT_AMOUNT)  as guar_amt        -- 凭证金额
              from dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_infomation           -- 放款凭证信息表
            where DELETE_FLAG = 1
            group by ID_BUSINESS_INFORMATION
         ) t6 on t1.id = t6.ID_BUSINESS_INFORMATION
left join (
            select ID_BUSINESS_INFORMATION,
				   sum(case when left(created_time,4) = left('${v_sdate}',4) then REPAYMENT_PRINCIPAL else 0 end) as cyr_unguar_amt,     --  本年解保金额(万元)         还款时间 = 本年的  还款本金
				   sum(case when left(created_time,4) < left('${v_sdate}',4) then REPAYMENT_PRINCIPAL else 0 end) as last_accu_unguar_amt,     --  累计至上年末的解保金额(万元)     sum(还款本金)    还款时间 < 本年的       
                  date_format(max(created_time), '%Y-%m-%d')   as unguar_reg_dt -- 解保登记日期  [最后一次含本金的还款日期]
            from dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_repayment              -- 还款凭证信息
            where REPAYMENT_PRINCIPAL > 0
              and DELETE_FLAG = 1
            group by id_business_information
		  ) t7
on  t1.id = t7.ID_BUSINESS_INFORMATION
;
commit;

			  

-- 新系统逻辑
insert into dw_base.ads_rpt_tjnd_unguar_info
(
day_id 
,project_id	        --  原业务编号
,guar_id	        --  业务编号
,province	        --  所属省份
,city	            --  所属地市
,district	        --  所属区县
,cust_type	        --  主体类型
,cust_class	        --  客户类型
,cust_name	        --  客户名称
,cert_no	            --  证件号码
,loan_bank	        --  贷款银行
,loan_no	            --  借款合同编号
,loan_amt	        --  借款合同金额(万元)
,loan_term	        --  借款合同期限(月)
,loan_cont_beg_dt	--  借款合同开始日
,loan_cont_end_dt	--  借款合同到期日
,loan_rate	        --  借款合同利率	
,repay_date	        --  贷款结清日
,nacga_unguar_dt	--  农担解保日期
,unguar_type	        --  解保类型（正常解保, 提前解保, 免除担保责任, 代偿解保）
,unguar_stat	        --  解保状态
,guar_rate	        --  担保费率
,counter_guar_meas	--  反担保方式
,branch_manager_name	--  农担项目经理姓名
,prod_type	        --  产品类型
,gnd_indus_class	    --  行业归类国农担标准
,weibao_cont_no	    --  委托保证合同编号
,warr_cont_no	    --  保证合同编号
,branch_off	        --  办事处
,enterprise_scale	--  企业类型（大中小微那种划分）
,tel_no	            --  联系方式
,guar_amt           --  担保金额(万元)
,cyr_unguar_amt      --  本年解保金额(万元)         
)
select day_id 
      ,project_id	        --  原业务编号
      ,guar_id	        --  业务编号
      ,province	        --  所属省份
      ,city	            --  所属地市
      ,district	        --  所属区县
      ,cust_type	        --  主体类型
      ,cust_class	        --  客户类型
      ,cust_name	        --  客户名称
      ,cert_no	            --  证件号码
      ,loan_bank	        --  贷款银行
      ,loan_no	            --  借款合同编号
      ,loan_amt	            --  借款合同金额(万元)
      ,loan_term	        --  借款合同期限(月)
      ,loan_cont_beg_dt	--  借款合同开始日
      ,loan_cont_end_dt	--  借款合同到期日
      ,loan_rate	        --  借款合同利率	
      ,case when repay_date is null and unguar_stat = '已代偿' then nacga_unguar_dt
	        else repay_date
	        end             as repay_date	        --  贷款结清日
      ,nacga_unguar_dt	    --  农担解保日期
      ,unguar_type	        --  解保类型（正常解保, 提前解保, 免除担保责任, 代偿解保）
      ,unguar_stat	        --  解保状态
      ,guar_rate	        --  担保费率
      ,counter_guar_meas	--  反担保方式
      ,branch_manager_name	--  农担项目经理姓名
      ,prod_type	        --  产品类型
      ,gnd_indus_class	    --  行业归类国农担标准
      ,weibao_cont_no	    --  委托保证合同编号
      ,warr_cont_no	        --  保证合同编号
      ,branch_off	        --  办事处
      ,enterprise_scale	    --  企业类型（大中小微那种划分）
      ,tel_no	            --  联系方式
      ,guar_amt             --  担保金额(万元)
-- 在新系统解保的迁移业务
-- 1. 所有包含还款本金的还款记录都是在2025年录入的, 今年解保金额就是放款金额
-- 2. 部分包含还款本金的还款记录是在去年录入的, 今年解保金额就是放款金额-2025年之前录入的还款本金累加
-- 3. 不存在包含还款本金的还款记录, 今年解保金额就是放款金额
-- 新系统发生并解保的业务都是按照全额解保的方式, 解保日期在今年就算到今年解保金额里
      ,if(guar_id like 'TJ%' 
         ,case when left(nacga_unguar_dt,4) = left('${v_sdate}',4) and cyr_unguar_amt != 0 and last_accu_unguar_amt = 0 then coalesce(guar_amt,0)
	           when left(nacga_unguar_dt,4) = left('${v_sdate}',4) and last_accu_unguar_amt != 0 then coalesce(guar_amt,0) - coalesce(last_accu_unguar_amt,0) 
			   when left(nacga_unguar_dt,4) = left('${v_sdate}',4) and ID_BUSINESS_INFORMATION is null then coalesce(guar_amt,0)
	     	   else 0
	     	   end             
		 ,if(left(nacga_unguar_dt,4) = left('${v_sdate}',4),guar_amt,0)
		 )              as cyr_unguar_amt      --  本年解保金额	(万元)           
from (
select '${v_sdate}'     as day_id 
      ,case when t1.item_stt = '已解保' and t3.project_id is null then t11.code          -- [风险化解-自动解保]
	        when t1.item_stt = '已解保' then t3.code             
        	when t1.item_stt = '已代偿' then t8.code
            end			as project_id	        --  原业务编号
      ,t1.guar_id	                            --  业务编号
      ,t4.sup_area_name as province	            --  所属省份
      ,t1.city_name     as city	                --  所属地市
      ,t1.county_name   as district	            --  所属区县
      ,t1.cust_type	            --  主体类型
      ,t1.cust_class	        --  客户类型
      ,t1.cust_name	            --  客户名称
      ,t1.cert_no	            --  证件号码
      ,t1.loan_bank	            --  贷款银行
      ,t1.loan_no	            --  借款合同编号
      ,t1.loan_amt	            --  借款合同金额(万元)
      ,t1.loan_term	            --  借款合同期限(月)
      ,t5.jk_ctrct_start_date as loan_cont_beg_dt	    --  借款合同开始日
      ,t5.jk_ctrct_end_date   as loan_cont_end_dt	    --  借款合同到期日
      ,t1.loan_rate	            --  借款合同利率	
      ,case when t1.item_stt = '已解保' and t3.project_id is null then t10.end_time        -- [风险化解-自动解保]
	        else t3.repay_date
            end               as repay_date        --  贷款结清日
      ,case when t1.item_stt = '已解保' and t3.project_id is null then t10.end_time        -- [风险化解-自动解保]
	        else COALESCE(t9.end_time,t3.complete_time)  -- [如果都取不到取t_biz_proj_unguar.complete_time]            
			end               as nacga_unguar_dt	--  农担解保日期
      ,case when t1.item_stt = '已解保' and t3.project_id is null then '自动解保'          -- [风险化解-自动解保]
	        when t1.item_stt = '已解保' then t3.unguar_type	        
	        when t1.item_stt = '已代偿' then '代偿解保'
			end               as unguar_type           --  解保类型（自动解保，正常解保, 提前解保, 免除担保责任, 代偿解保）
      ,case when t1.item_stt = '已解保' and t3.project_id is null then t10.status          -- [风险化解-自动解保]
	        when t1.item_stt = '已解保' then t3.unguar_stat	        
	        when t1.item_stt = '已代偿' then t8.unguar_stat
		    end               as unguar_stat	       --  解保状态
      ,t1.guar_rate	            --  担保费率
      ,t6.counter_guar_meas	    --  反担保方式
      ,t6.branch_manager_name	--  农担项目经理姓名
      ,t6.prod_type	            --  产品类型
      ,t1.guar_class as gnd_indus_class	    --  行业归类国农担标准
      ,coalesce(t1.trust_cont_no,t7.weibao_cont_no) as weibao_cont_no	    --  委托保证合同编号  [在保转进件取不到的取老系统数据]
      ,t1.guar_cnot_no as warr_cont_no	        --  保证合同编号
      ,t6.branch as branch_off	        --  办事处
      ,t6.enterprise_scale   	        --  企业类型（大中小微那种划分）
      ,t1.tel_no 	                    --  联系方式
	  ,t1.guar_amt         
	  ,'new' as source
	  ,t12.ID_BUSINESS_INFORMATION
	  ,t12.cyr_unguar_amt              --  本年解保金额(万元) 
	  ,t12.last_accu_unguar_amt        --  累计至上年末的解保金额(万元)
from dw_base.dwd_guar_info_all_his t1 
left join dw_base.dwd_guar_info_stat t2
on t1.guar_id = t2.guar_id 
left join (
            select project_id
			      ,code        -- 解保编号
				  ,date_format(repay_date,'%Y-%m-%d') as repay_date  -- 贷款结清日
				  ,unguar_date -- 解保日期
				  ,case when unguar_type = '0' then '正常解保'
                        when unguar_type = '1' then '提前解保'
			            when unguar_type = '2' then '免除担保责任'
			            end  as unguar_type -- 解保类型：0-正常解保，1-提前解保，2-免除担保责任
				  ,status      -- 解保状态：00-申请中，10-审核中，20-已解保，98-已终止，99-已否决
				  ,case when status = '00' then '申请中'
	                    when status = '10' then '审核中'
			            when status = '20' then '已解保'
			            when status = '98' then '已终止'
			            when status = '99' then '已否决'
		                end  as unguar_stat
				  ,  wf_inst_id -- 工作流实例id
				  ,date_format(complete_time,'%Y-%m-%d') as complete_time   -- 流程完成时间
		    from (select *,row_number() over (partition by project_id order by update_time desc) rn from dw_nd.ods_t_biz_proj_unguar) a 
			where a.rn = 1
		  )	 t3
on t2.project_id = t3.project_id
left join dw_base.dim_area_info t4
on t2.city_code = t4.area_cd and t4.area_lvl = '2'	
left join (
            select project_id
			     , jk_contr_code         -- 借款合同编号
				 , jk_ctrct_term         -- 借款合同期限(月)  
                 , jk_ctrct_start_date   -- 借款合同开始日 
				 , jk_ctrct_end_date     -- 借款合同到期日 				
            from (select *,row_number() over (partition by project_id order by db_update_time desc,update_time desc) rn from dw_nd.ods_t_biz_proj_sign ) b -- 项目签约信息表                 
            where b.rn = 1
		  ) t5
on t2.project_id = t5.project_id
left join (
            select code
			      ,replace(replace(replace(replace(replace(replace(replace(
				    substring_index(regexp_replace(apply_counter_guar_meas, '"|\\[|\\]', ''), ',', 5)
				   ,'01','无'),'02','抵押'),'03','质押'),'03','质押'),'04','保证'),'05','以物抵债'),'00','其他') as counter_guar_meas -- 申保反担保方式
				  ,branch_manager_name -- 农担分支机构项目经理姓名
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
                        end                as    prod_type                           --  产品类型
				  ,case when branch like '%宁河%' then '宁河东丽办事处'
			            when branch like '%津南%' then '津南滨海新区办事处' 
					    when branch like '%武清%' then '武清北辰办事处'
					    when branch like '%静海%' then '西青静海办事处'
					    when branch like '%蓟州%' then '蓟州办事处'
					    when branch like '%宝坻%' then '宝坻办事处'
                        end                as    branch                           -- 办事处
				  ,case when enterprise_scale = '01' then '大型企业'
				        when enterprise_scale = '02' then '中型企业'
				        when enterprise_scale = '03' then '小型企业'
				        when enterprise_scale = '04' then '微型企业'
						end                as    enterprise_scale                 --  企业类型
			from (select *,row_number() over (partition by code order by db_update_time desc,update_time desc) rn from dw_nd.ods_t_biz_project_main) c 
			where c.rn = 1
		  ) t6
on t1.guar_id = t6.code  
left join (
	        select ID_BUSINESS_INFORMATION,                      -- 业务id
                   WTBZHT_NO            as weibao_cont_no       -- 委托保证合同编号
		    from dw_nd.ods_creditmid_v2_z_migrate_afg_business_approval
		  ) t7
on t2.project_id = t7.ID_BUSINESS_INFORMATION
left join (
            select proj_code
			     , code
                 , case when status = '00' then '申请中'
				        when status = '10' then '审核中'
						when status = '20' then '拨付申请中'
						when status = '30' then '拨付审核中'
						when status = '60' then '已拨付待确认'
						when status = '40' then '待拨付'
						when status = '50' then '已代偿'
						when status = '98' then '已终止'
						when status = '99' then '已否决'
						end as unguar_stat   --  代偿_业务流程状态
				 ,  wf_inst_id -- 工作流实例id
            from (select *,row_number() over (partition by proj_code order by db_update_time desc) rn from dw_nd.ods_t_proj_comp_aply) d
            where d.rn = 1
		  ) t8
on t1.guar_id = t8.proj_code
left join (
            select t1.wf_inst_id
	              ,max(end_time) as end_time  -- 代偿确认日期 
	        from (
			           
					 select e.proc_inst_id_  as wf_inst_id
                           ,e.proc_def_id_   as proc_def_id
                           ,e.name_          as task_name
                           ,date_format(end_time_,'%Y-%m-%d') as end_time
                     from (select * ,row_number()over(partition by proc_inst_id_,name_  order by last_updated_time_ desc ) rn from dw_nd.ods_t_act_hi_taskinst_v2 ) e -- 工作流审批表v2                         
                     where e.rn = 1  
                 ) t1  -- 工作流审批表
	        inner join dw_nd.ods_t_act_re_procdef_v2 t2
	           on t1.proc_def_id = t2.id_
	        where (t2.key_ = 'guarantee-dc'             -- 代偿流程
	               and t1.task_name in ('财务支付','计财部拨付','财务部拨付'))                 -- ,    '代偿确认'
			  or  (t2.key_ in ('guarantee-release','guarantee-release-sgzx')   -- 解保流程（不确定）
			       and t1.task_name in ('分支机构负责人','分支机构项目经理')) -- 	[银行发起的解保，没有分支机构负责人审批节点，这个得区分一下，如果是银行发起的，以分支机构审批节点的结束时间，如果是分支机构发起的，以分支机构负责人审批节点的结束时间]			   
	        group by t1.wf_inst_id
		  ) t9
on coalesce(t3.wf_inst_id,t8.wf_inst_id) = t9.wf_inst_id
left join (
            select project_id
			      ,new_main_id
			      ,case when wf_node_name = '完成化解' then date_format(db_update_time,'%Y-%m-%d') end as end_time        -- [保后管理-化解任务池-审批进度：完成化解算解保时间]
				  ,case when status = '10' then '申请中'
				        when status = '20' then '化解中'
						when status = '30' then '已化解'
						when status = '96' then '已过期'
						when status = '98' then '已终止'
						when status = '99' then '已否决'
                        end      as    status
			from (select *,row_number() over (partition by project_id order by db_update_time desc,update_time desc) rn from  dw_nd.ods_t_loan_after_relieve) f -- 风险化解申请表
			where f.rn = 1			
		  ) t10
on t2.project_id = t10.project_id
left join (
            select id
			      ,code
			from (select *,row_number() over (partition by code order by db_update_time desc,update_time desc) rn from dw_nd.ods_t_biz_project_main) g 
			where g.rn = 1
		  ) t11 
on t10.new_main_id = t11.id
left join (
            select ID_BUSINESS_INFORMATION,
                  sum(case when left(created_time,4) = left('${v_sdate}',4) then REPAYMENT_PRINCIPAL else 0 end) as cyr_unguar_amt,     --  本年解保金额(万元)         还款时间 = 本年的  还款本金
				  sum(case when left(created_time,4) < left('${v_sdate}',4) then REPAYMENT_PRINCIPAL else 0 end) as last_accu_unguar_amt     --  累计至上年末的解保金额(万元)     sum(还款本金)    还款时间 < 本年的  
            from dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_repayment              -- 还款凭证信息
            where REPAYMENT_PRINCIPAL > 0
              and DELETE_FLAG = 1
            group by id_business_information
		  ) t12
on t2.project_id = t12.ID_BUSINESS_INFORMATION
where t1.day_id = '${v_sdate}' 
  and t1.item_stt in ('已解保','已代偿')
) t_all
;
commit;








