-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250409
-- 目标表   ：dw_base.ads_rpt_tjnd_busi_record_stat_loan 业务状况-放款
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_afg_business_infomation                   业务申请表
--          dw_nd.ods_tjnd_yw_base_customers_history                    BO,客户信息历史表,NEW
--          dw_nd.ods_tjnd_yw_afg_voucher_infomation                    放款凭证信息
--          dw_nd.ods_tjnd_yw_afg_voucher_repayment                     还款凭证信息
--          dw_nd.ods_tjnd_yw_base_product_management                   BO,产品管理,NEW
--          新业务系统
--
-- 备注     ：需要统一成累计放款, 比如19号的日报, 期初是截止18号的累计放款笔数和金额, 当期放款就是19号的放款笔数和金额, 期末就是截止19号的累计放款笔数和金额, 然后当期还款那列去掉吧
-- 变更记录 ：
-- ---------------------------------------
-- 重跑逻辑
delete
from dw_base.ads_rpt_tjnd_busi_record_stat_loan
where day_id = '${v_sdate}';
commit;

-- 创建临时表存储
drop table if exists dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan;
create table if not exists dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(
    day_id            varchar(8)     null comment '数据日期',
    report_type       varchar(50)    null comment '报表类型',
    group_type        varchar(50)    null comment '统计类型',
    group_name        varchar(100)   null comment '分组名称',
    start_balance     decimal(36, 6) null comment '期初余额(万元)',
    start_cnt         int            null comment '期初笔数',
    now_guar_amt      decimal(36, 6) null comment '当期放款金额(万元)',
    now_guar_cnt      int            null comment '当期放款笔数',
    now_repayment_amt decimal(36, 6) null comment '当期还款金额(万元)',
    now_repayment_cnt int            null comment '当期还款笔数',
    end_balance       decimal(36, 6) null comment '期末余额(万元)',
    end_cnt           int            null comment '期末笔数'
) comment '临时-业务部-业务状况-放款' collate = utf8mb4_bin;

-- 旧数据-分类
drop table if exists dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main;
commit;
create table if not exists dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
(
    id                varchar(20)   comment 'id',
	guar_date         date          comment '放款日期(取最近一天)',
    guar_amt          decimal(18,6) comment '放款金额(万元)',
    repayment_date    date          comment '还款日期(取最近一天)',
    repayment_amt     decimal(18,6) comment '还款金额(万元)',
	
    now_guar_amt_day  decimal(18,6) comment '当期放款金额(万元)（日报）',           
    now_guar_amt_xun  decimal(18,6) comment '当期放款金额(万元)（旬报）',           
    now_guar_amt_mon  decimal(18,6) comment '当期放款金额(万元)（月报）',           
    now_guar_amt_qua  decimal(18,6) comment '当期放款金额(万元)（季报）',           
    now_guar_amt_hyr  decimal(18,6) comment '当期放款金额(万元)（半年报）',         
    now_guar_amt_tyr  decimal(18,6) comment '当期放款金额(万元)（年报）',           
	
    now_guar_cnt_day  int           comment '当期放款笔数（日报）',  
    now_guar_cnt_xun  int           comment '当期放款笔数（旬报）',  
    now_guar_cnt_mon  int           comment '当期放款笔数（月报）',  
    now_guar_cnt_qua  int           comment '当期放款笔数（季报）',  
    now_guar_cnt_hyr  int           comment '当期放款笔数（半年报）',
    now_guar_cnt_tyr  int           comment '当期放款笔数（年报）',  
	
    now_repayment_amt_day  decimal(18,6) comment '当期还款金额(万元)（日报）',  
	now_repayment_amt_xun  decimal(18,6) comment '当期还款金额(万元)（旬报）',  
    now_repayment_amt_mon  decimal(18,6) comment '当期还款金额(万元)（月报）',  	
    now_repayment_amt_qua  decimal(18,6) comment '当期还款金额(万元)（季报）',  	
    now_repayment_amt_hyr  decimal(18,6) comment '当期还款金额(万元)（半年报）',	
    now_repayment_amt_tyr  decimal(18,6) comment '当期还款金额(万元)（年报）',  	
	
    now_repayment_cnt_day  int           comment '当期还款笔数（日报）',  
    now_repayment_cnt_xun  int           comment '当期还款笔数（旬报）',  	
    now_repayment_cnt_mon  int           comment '当期还款笔数（月报）',  	
    now_repayment_cnt_qua  int           comment '当期还款笔数（季报）',  	
    now_repayment_cnt_hyr  int           comment '当期还款笔数（半年报）',	
    now_repayment_cnt_tyr  int           comment '当期还款笔数（年报）',  	
					    	
    type1             varchar(50)   comment '按银行',
    type2             varchar(50)   comment '按产品',
    type3             varchar(50)   comment '按行业归类',
    type4             varchar(50)   comment '按办事处',
	type5             varchar(50)	comment '按区域',					   
	type6             varchar(50)	comment '按一级支行',					   
	type7             varchar(50)	comment '按项目经理核算'				   													   
)  ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC
 comment '临时-业务部-业务状况-旧系统-日报-分类表';
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
 select t1.id 
       ,t2.guar_date
       ,t2.guar_amt
	   ,t3.repayment_date
--	   ,t3.repayment_amt
       ,0 as repayment_amt                                              -- [需要统一成累计放款, 比如19号的日报, 期初是截止18号的累计放款笔数和金额, 当期放款就是19号的放款笔数和金额, 期末就是截止19号的累计放款笔数和金额, ]
	   ,t4.now_guar_amt_day           --    当期放款金额 （日报）
	   ,t4.now_guar_amt_xun           --                 （旬报）
	   ,t4.now_guar_amt_mon           --                 （月报）
	   ,t4.now_guar_amt_qua           --                 （季报）
	   ,t4.now_guar_amt_hyr           --                 （半年报）
	   ,t4.now_guar_amt_tyr           --                 （年报）
       ,t4.now_guar_cnt_day           --    当期放款笔数 （日报）
	   ,t4.now_guar_cnt_xun           --                 （旬报）
	   ,t4.now_guar_cnt_mon           --                 （月报）
	   ,t4.now_guar_cnt_qua           --                 （季报）
	   ,t4.now_guar_cnt_hyr           --                 （半年报）
	   ,t4.now_guar_cnt_tyr           --                 （年报）
	   ,t5.now_repayment_amt_day      --    当期还款金额 （日报）
	   ,t5.now_repayment_amt_xun      --                 （旬报）
	   ,t5.now_repayment_amt_mon      --                 （月报）
	   ,t5.now_repayment_amt_qua      --                 （季报）
	   ,t5.now_repayment_amt_hyr      --                 （半年报）
	   ,t5.now_repayment_amt_tyr      --                 （年报）
	   ,t6.now_repayment_cnt_day      --    当期还款笔数 （日报）
	   ,t6.now_repayment_cnt_xun      --                 （旬报）
	   ,t6.now_repayment_cnt_mon      --                 （月报）
	   ,t6.now_repayment_cnt_qua      --                 （季报）
	   ,t6.now_repayment_cnt_hyr      --                 （半年报）
	   ,t6.now_repayment_cnt_tyr      --                 （年报）
	   ,t7.bank_name                  as    type1 -- 按银行
	   ,t8.PRODUCT_NAME               as    type2 -- 按产品
	   ,t9.INDUSTRY_CATEGORY_COMPANY  as    type3 -- 按行业归类
	   ,t1.branch_off                 as    type4 -- 按办事处
	   ,case when left(coalesce(t10.area_cd,t12.area_cd),3) = '110' then concat('北京市',coalesce(t10.sup_area_name,t12.sup_area_name),coalesce(t10.area_name,t12.area_name))
	         when left(coalesce(t10.area_cd,t12.area_cd),3) = '130' then concat('河北省',coalesce(t10.sup_area_name,t12.sup_area_name),coalesce(t10.area_name,t12.area_name))
	         else coalesce(t10.area_name,t12.area_name)   
			 end                      as type5 -- 按区域
	   ,t13.bank_name                 as    type6 -- 按一级支行
	   ,t1.BUSINESS_SP_USER_NAME      as    type7 -- 按项目经理核算
 from (
          select ID,                    -- 业务id
                 COOPERATIVE_BANK_FIRST -- 银行对应编码
				,PRODUCT_GRADE -- 产品对应编码
				,ID_CUSTOMER -- 客户对应id
				,enter_code as branch_off -- 部门编码
				,case when id in ('81043','82301','82383','88728','91752') then JSON_UNQUOTE(JSON_EXTRACT(area, '$[2]'))
				      else JSON_UNQUOTE(JSON_EXTRACT(area, '$[1]')) 
					  end as area -- 转换为区县
				,COOPERATIVE_BANK_SECOND -- 二级支行编码
				,BUSINESS_SP_USER_NAME -- 项目经理
				,COOPERATIVE_BANK_ID 
--          from dw_nd.ods_tjnd_yw_afg_business_infomation  
		  from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation -- 业务申请表 
--          where GUR_STATE in ('GT', 'ED')
          where GUR_STATE in ('90','93')     -- [排掉在保的]
		  and guarantee_code not in ('TJRD-2021-5S93-979U','TJRD-2021-5Z85-959X')        -- [这两笔在进件业务]
      ) t1
          left join
      (
          select ID_BUSINESS_INFORMATION,                 -- 业务id
                 sum(RECEIPT_AMOUNT)         as guar_amt, -- 放款金额                 / 10000
                 max(CREATED_TIME)           as guar_date -- 放款日期(取最近一天)
          -- from dw_nd.ods_tjnd_yw_afg_voucher_infomation
          from dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_infomation		  -- 放款凭证信息
          where DELETE_FLAG = 1
          group by ID_BUSINESS_INFORMATION
      ) t2 on t1.ID = t2.ID_BUSINESS_INFORMATION
          left join
      (
          select ID_BUSINESS_INFORMATION,                           -- 业务id
                 sum(REPAYMENT_PRINCIPAL)         as repayment_amt, -- 还款金额       / 10000
                 max(CREATED_TIME)                as repayment_date -- 还款日期(取最近一天)
          -- from dw_nd.ods_tjnd_yw_afg_voucher_repayment
		  from dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_repayment -- 还款凭证信息
          where DELETE_FLAG = 1
          group by ID_BUSINESS_INFORMATION
      ) t3 on t1.ID = t3.ID_BUSINESS_INFORMATION
          left join
      (
          select ID_BUSINESS_INFORMATION,                    -- 业务id
                 sum(case when date_format(CREATED_TIME, '%Y%m%d') = '${v_sdate}'
				          then RECEIPT_AMOUNT
						  else 0 end
					)                                                                     as now_guar_amt_day -- 当期放款金额(日报) / 10000
				,sum(case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                     , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                                 , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
				                     , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                     , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
					                 )
                                 )
						  then RECEIPT_AMOUNT
						  else 0 end
					)                                                                     as now_guar_amt_xun -- 当期放款金额(旬报)
				,sum(case when date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}' 
						  then RECEIPT_AMOUNT 
						  else 0 end 
					)                                                                     as now_guar_amt_mon -- 当期放款金额(月报)
				,sum(case when if(quarter('${v_sdate}') = 1
				                 , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                                 , if(quarter('${v_sdate}') = 2
								     , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                     , if(quarter('${v_sdate}') = 3
									     , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                         , if(quarter('${v_sdate}') = 4
										     , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
										     , ''
											 )
                                         )
									 )
								 )
						  then RECEIPT_AMOUNT 
						  else 0 end				    
					)                                                                     as now_guar_amt_qua -- 当期放款金额(季报)
				,sum(case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
				                 , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                                 , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
								 )				
						  then RECEIPT_AMOUNT 
						  else 0 end				    
					)                                                                     as now_guar_amt_hyr -- 当期放款金额(半年报)
				,sum(case when left(date_format(CREATED_TIME, '%Y%m%d'), 4) = left('${v_sdate}', 4)
						  then RECEIPT_AMOUNT 
						  else 0 end				    
					)                                                                     as now_guar_amt_tyr -- 当期放款金额(年报)
                ,max(case when date_format(CREATED_TIME, '%Y%m%d') = '${v_sdate}'
				          then 1
						  else 0 end
					)                                                                     as now_guar_cnt_day -- 当期放款笔数(日报) 
				,max(case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                     , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                                 , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
				                     , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                     , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
					                 )
                                 )
						  then 1
						  else 0 end
					)                                                                     as now_guar_cnt_xun -- 当期放款笔数(旬报)
				,max(case when date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}' 
						  then 1 
						  else 0 end 
					)                                                                     as now_guar_cnt_mon -- 当期放款笔数(月报)
				,max(case when if(quarter('${v_sdate}') = 1
				                 , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                                 , if(quarter('${v_sdate}') = 2
								     , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                     , if(quarter('${v_sdate}') = 3
									     , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                         , if(quarter('${v_sdate}') = 4
										     , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
										     , ''
											 )
                                         )
									 )
								 )
						  then 1 
						  else 0 end				    
					)                                                                     as now_guar_cnt_qua -- 当期放款笔数(季报)
				,max(case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
				                 , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                                 , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
								 )				
						  then 1 
						  else 0 end				    
					)                                                                     as now_guar_cnt_hyr -- 当期放款笔数(半年报)
				,max(case when left(date_format(CREATED_TIME, '%Y%m%d'), 4) = left('${v_sdate}', 4)
						  then 1 
						  else 0 end				    
					)                                                                     as now_guar_cnt_tyr -- 当期放款笔数(年报)
          -- from dw_nd.ods_tjnd_yw_afg_voucher_infomation
		  from dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_infomation		  -- 放款凭证信息
          where DELETE_FLAG = 1
          group by ID_BUSINESS_INFORMATION
      ) t4 on t1.ID = t4.ID_BUSINESS_INFORMATION
          left join
      (
          select ID_BUSINESS_INFORMATION,                              -- 业务id
                 sum(case when date_format(CREATED_TIME, '%Y%m%d') = '${v_sdate}'
				          then REPAYMENT_PRINCIPAL
						  else 0 end
					)                                                                     as now_repayment_amt_day -- 当期还款金额(日报) / 10000
				,sum(case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                     , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                                 , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
				                     , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                     , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
					                 )
                                 )
						  then REPAYMENT_PRINCIPAL
						  else 0 end
					)                                                                     as now_repayment_amt_xun -- 当期还款金额(旬报)
				,sum(case when date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}' 
						  then REPAYMENT_PRINCIPAL 
						  else 0 end 
					)                                                                     as now_repayment_amt_mon -- 当期还款金额(月报)
				,sum(case when if(quarter('${v_sdate}') = 1
				                 , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                                 , if(quarter('${v_sdate}') = 2
								     , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                     , if(quarter('${v_sdate}') = 3
									     , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                         , if(quarter('${v_sdate}') = 4
										     , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
										     , ''
											 )
                                         )
									 )
								 )
						  then REPAYMENT_PRINCIPAL 
						  else 0 end				    
					)                                                                     as now_repayment_amt_qua -- 当期还款金额(季报)
				,sum(case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
				                 , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                                 , date_format(CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
								 )				
						  then REPAYMENT_PRINCIPAL 
						  else 0 end				    
					)                                                                     as now_repayment_amt_hyr -- 当期还款金额(半年报)
				,sum(case when left(date_format(CREATED_TIME, '%Y%m%d'), 4) = left('${v_sdate}', 4)
						  then REPAYMENT_PRINCIPAL 
						  else 0 end				    
					)                                                                     as now_repayment_amt_tyr -- 当期还款金额(年报)
          -- from dw_nd.ods_tjnd_yw_afg_voucher_repayment
		  from dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_repayment -- 还款凭证信息
          where DELETE_FLAG = 1
          group by ID_BUSINESS_INFORMATION
      ) t5 on t1.ID = t5.ID_BUSINESS_INFORMATION
          left join
      (
          select ID_BUSINESS_INFORMATION -- 业务id  解保日期为当天的业务
                ,    case when date_format(DATE_OF_SET, '%Y%m%d') = '${v_sdate}'
				          then 1
						  else 0 end                                                                    as now_repayment_cnt_day -- 当期还款笔数(日报) 
				,    case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                     , date_format(DATE_OF_SET, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                                 , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
				                     , date_format(DATE_OF_SET, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                     , date_format(DATE_OF_SET, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
					                 )
                                 )
						  then 1
						  else 0 end                                                                     as now_repayment_cnt_xun -- 当期还款笔数(旬报)
				,    case when date_format(DATE_OF_SET, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}' 
						  then 1 
						  else 0 end                                                                     as now_repayment_cnt_mon -- 当期还款笔数(月报)
				,    case when if(quarter('${v_sdate}') = 1
				                 , date_format(DATE_OF_SET, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                                 , if(quarter('${v_sdate}') = 2
								     , date_format(DATE_OF_SET, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                     , if(quarter('${v_sdate}') = 3
									     , date_format(DATE_OF_SET, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                         , if(quarter('${v_sdate}') = 4
										     , date_format(DATE_OF_SET, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
										     , ''
											 )
                                         )
									 )
								 )
						  then 1 
						  else 0 end				                                                      as now_repayment_cnt_qua -- 当期还款笔数(季报)
				,    case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
				                 , date_format(DATE_OF_SET, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                                 , date_format(DATE_OF_SET, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
								 )				
						  then 1 
						  else 0 end				                                                      as now_repayment_cnt_hyr -- 当期还款笔数(半年报)
				,    case when left(date_format(DATE_OF_SET, '%Y%m%d'), 4) = left('${v_sdate}', 4)
						  then 1 
						  else 0 end				                                                      as now_repayment_cnt_tyr -- 当期还款笔数(年报)
          -- from dw_nd.ods_tjnd_yw_afg_guarantee_relieve
		  from dw_nd.ods_creditmid_v2_z_migrate_afg_guarantee_relieve -- 担保解除
          where DELETED_FLAG = '1'
            and IS_RELIEVE_FLAG = '0'
      ) t6 on t1.ID = t6.ID_BUSINESS_INFORMATION
	      left join
      (
          select fieldcode,                 -- 银行对应编码
				 case when enterfullname = '北京银行股份有限公司天津分行'     then '北京银行股份有限公司'
					  when enterfullname = '中国光大银行股份有限公司天津分行' then '中国光大银行股份有限公司'
					  when enterfullname = '中国工商银行股份有限公司天津'     then '中国工商银行股份有限公司'
					  when enterfullname = '宁夏银行股份有限公司天津'         then '宁夏银行股份有限公司'
					  when enterfullname = '兴业银行股份有限公司天津分行'     then '兴业银行股份有限公司'
					  when enterfullname = '中国建设银行股份有限公司天津'     then '中国建设银行股份有限公司'					  
					  when enterfullname = '中国邮政储蓄银行股份有限公司天津' then '中国邮政储蓄银行股份有限公司'
					  when enterfullname = '中国农业银行股份有限公司天津'     then '中国农业银行股份有限公司'
					  when enterfullname = '交通银行股份有限公司天津'         then '交通银行股份有限公司'
				      else enterfullname end  as bank_name -- 银行名称                            -- [与新系统的银行进行合并]
          from dw_nd.ods_tjnd_yw_base_enterprise           -- 部门表
          where parentid = 200 and delete_flag = '0'
      ) t7 on t1.COOPERATIVE_BANK_FIRST = t7.fieldcode
	      left join 
      (
          select fieldcode,   -- 产品编码
                 PRODUCT_NAME -- 产品名称
          -- from dw_nd.ods_tjnd_yw_base_product_management
		  from dw_nd.ods_creditmid_v2_z_migrate_base_product_management -- BO,产品管理,NEW
      ) t8 on t1.PRODUCT_GRADE = t8.fieldcode	
          left join
      (
          select id,                       -- 客户id
                 INDUSTRY_CATEGORY_COMPANY -- 行业分类（公司）
				,JSON_UNQUOTE(JSON_EXTRACT(area, '$[1]'))  as area
          -- from dw_nd.ods_tjnd_yw_base_customers_history
		  from dw_nd.ods_creditmid_v2_z_migrate_base_customers_history -- BO,客户信息历史表,NEW
      ) t9 on t1.ID_CUSTOMER = t9.ID	
         left join
      (select area_cd
	         ,case when area_cd = '130171'	then '高新技术产业开发区'                         -- 石家庄高新技术产业开发区
                   when area_cd = '130172'	then '循环化工园区'                               -- 石家庄循环化工园区
                   when area_cd = '130271'	then '芦台经济开发区'                             -- 河北唐山芦台经济开发区
                   when area_cd = '130272'	then '汉沽管理区'                                 -- 唐山市汉沽管理区
                   when area_cd = '130273'	then '高新技术产业开发区'                         -- 唐山高新技术产业开发区
                   when area_cd = '130274'	then '海港经济开发区'                             -- 河北唐山海港经济开发区
                   when area_cd = '130371'	then '经济技术开发区'                             -- 秦皇岛市经济技术开发区
                   when area_cd = '130471'	then '经济技术开发区'                             -- 邯郸经济技术开发区
                   when area_cd = '130473'	then '冀南新区'                                   -- 邯郸冀南新区
                   when area_cd = '130571'	then '经济开发区'                                 -- 河北邢台经济开发区
                   when area_cd = '130671'	then '高新技术产业开发区'                         -- 保定高新技术产业开发区
                   when area_cd = '130672'	then '白沟新城'                                   -- 保定白沟新城
                   when area_cd = '130771'	then '经济开发区'                                 -- 张家口经济开发区
                   when area_cd = '130772'	then '察北管理区'                                 -- 张家口市察北管理区
                   when area_cd = '130773'	then '塞北管理区'                                 -- 张家口市塞北管理区
                   when area_cd = '130871'	then '高新技术产业开发区'                         -- 承德高新技术产业开发区
                   when area_cd = '130971'	then '经济开发区'                                 -- 河北沧州经济开发区
                   when area_cd = '130972'	then '高新技术产业开发区'                         -- 沧州高新技术产业开发区
                   when area_cd = '130973'	then '渤海新区'                                   -- 沧州渤海新区
                   when area_cd = '131071'	then '经济技术开发区'                             -- 廊坊经济技术开发区
                   when area_cd = '131171'	then '高新技术产业开发区'                         -- 河北衡水高新技术产业开发区
                   when area_cd = '131172'	then '滨湖新区'                                   -- 衡水滨湖新区
				   else area_name 
				   end               as area_name
			 ,sup_area_cd
			 ,sup_area_name
	   from dw_base.dim_area_info) t10 on t1.area = t10.area_cd	 
	  left join 
	  (select area_cd
	         ,case when area_cd = '130171'	then '高新技术产业开发区'                         -- 石家庄高新技术产业开发区
                   when area_cd = '130172'	then '循环化工园区'                               -- 石家庄循环化工园区
                   when area_cd = '130271'	then '芦台经济开发区'                             -- 河北唐山芦台经济开发区
                   when area_cd = '130272'	then '汉沽管理区'                                 -- 唐山市汉沽管理区
                   when area_cd = '130273'	then '高新技术产业开发区'                         -- 唐山高新技术产业开发区
                   when area_cd = '130274'	then '海港经济开发区'                             -- 河北唐山海港经济开发区
                   when area_cd = '130371'	then '经济技术开发区'                             -- 秦皇岛市经济技术开发区
                   when area_cd = '130471'	then '经济技术开发区'                             -- 邯郸经济技术开发区
                   when area_cd = '130473'	then '冀南新区'                                   -- 邯郸冀南新区
                   when area_cd = '130571'	then '经济开发区'                                 -- 河北邢台经济开发区
                   when area_cd = '130671'	then '高新技术产业开发区'                         -- 保定高新技术产业开发区
                   when area_cd = '130672'	then '白沟新城'                                   -- 保定白沟新城
                   when area_cd = '130771'	then '经济开发区'                                 -- 张家口经济开发区
                   when area_cd = '130772'	then '察北管理区'                                 -- 张家口市察北管理区
                   when area_cd = '130773'	then '塞北管理区'                                 -- 张家口市塞北管理区
                   when area_cd = '130871'	then '高新技术产业开发区'                         -- 承德高新技术产业开发区
                   when area_cd = '130971'	then '经济开发区'                                 -- 河北沧州经济开发区
                   when area_cd = '130972'	then '高新技术产业开发区'                         -- 沧州高新技术产业开发区
                   when area_cd = '130973'	then '渤海新区'                                   -- 沧州渤海新区
                   when area_cd = '131071'	then '经济技术开发区'                             -- 廊坊经济技术开发区
                   when area_cd = '131171'	then '高新技术产业开发区'                         -- 河北衡水高新技术产业开发区
                   when area_cd = '131172'	then '滨湖新区'                                   -- 衡水滨湖新区
				   else area_name 
				   end               as area_name
			 ,sup_area_cd
			 ,sup_area_name
	   from dw_base.dim_area_info) t12 on t9.area = t12.area_cd
          left join
      (
          select t1.fieldcode,
                 concat(t2.enterfullname, t1.enterfullname) as bank_name
          from dw_nd.ods_tjnd_yw_base_enterprise      t1     -- 部门表 
                   left join dw_nd.ods_tjnd_yw_base_enterprise t2 on t1.parentid = t2.enterid and t2.delete_flag = '0'
		  where t1.delete_flag = '0'
      ) t11 on t1.COOPERATIVE_BANK_SECOND = t11.fieldcode	
      left join (
	              select dept_id 
				        ,dept_name as bank_name
                  from (select *, row_number() over (partition by dept_id order by update_time desc) as rn from dw_nd.ods_t_sys_dept where del_flag = 0) a  -- 新系统部门表 
                  where rn = 1
				) t13
      on t1.COOPERATIVE_BANK_ID = t13.dept_id	
where coalesce(t10.area_name,t12.area_name) is not null	              -- 区域为空的不统计，老系统已删除
;
commit;

 -- 旧系统逻辑
 -- 日报
 insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
 (day_id, -- 数据日期
  report_type,-- 报表类型 (日报、旬报、月报、季报、半年报、年报)
  group_type, -- 统计类型
  group_name, -- 分组名称
  start_balance, -- 期初余额(万元)
  start_cnt, -- 期初笔数
  now_guar_amt, -- 当期放款金额(万元)
  now_guar_cnt, -- 当期放款笔数
  now_repayment_amt, -- 当期还款金额(万元)
  now_repayment_cnt, -- 当期还款笔数
  end_balance, -- 期末余额(万元)
  end_cnt -- 期末笔数
 )
select '${v_sdate}'          as day_id,
       '日报'                as report_type,
       '银行'                as group_type,
       type1                 as group_name,        
	   sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
       sum(case when date_format(repayment_date, '%Y%m%d') < '${v_sdate}' then repayment_amt else 0 end)  as start_balance,  -- 期初余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)                   as start_cnt,      -- 期初笔数
       sum(if(now_guar_amt_day is null,0,now_guar_amt_day))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_day)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_day is null,0,now_repayment_amt_day))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_day)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type1             -- '按银行',
union all 
select '${v_sdate}'          as day_id,
       '日报'                as report_type,
       '产品'                as group_type,
       type2                 as group_name,        
	   sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
       sum(case when date_format(repayment_date, '%Y%m%d') < '${v_sdate}' then repayment_amt else 0 end)  as start_balance,  -- 期初余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)                   as start_cnt,      -- 期初笔数
       sum(if(now_guar_amt_day is null,0,now_guar_amt_day))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_day)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_day is null,0,now_repayment_amt_day))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_day)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type2             -- '按产品',
union all 
select '${v_sdate}'          as day_id,
       '日报'                as report_type,
       '行业归类'                as group_type,
       case
            when type3 = '08' then '农产品初加工'                                           -- 0
            when type3 = '01' then '粮食种植'                                              -- 1
            when type3 = '02' then '重要、特色农产品种植'                                     -- 2
            when type3 = '04' then '其他畜牧业'                                            -- 3
            when type3 = '03' then '生猪养殖'                                              -- 4
            when type3 = '07' then '农产品流通'                                            -- 5
            when type3 = '05' then '渔业生产'                                              -- 6
            when type3 = '12' then '农资、农机、农技等农业社会化服务'                           -- 7
            when type3 = '09' then '农业新业态'                                            -- 8
            when type3 = '06' then '农田建设'                                              -- 9
            when type3 = '10' then '其他农业项目'                                          -- 10
			when type3 = '99' then '其他'
            end                    as group_name,      	   
	   sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
       sum(case when date_format(repayment_date, '%Y%m%d') < '${v_sdate}' then repayment_amt else 0 end)  as start_balance,  -- 期初余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)                   as start_cnt,      -- 期初笔数
       sum(if(now_guar_amt_day is null,0,now_guar_amt_day))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_day)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_day is null,0,now_repayment_amt_day))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_day)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type3             -- '按产品',
union all 
select '${v_sdate}'          as day_id,
       '日报'                as report_type,
       '办事处'                as group_type,
       case
            when type4 = 'NHDLBranch'   then '宁河东丽办事处'                                   -- 'YW_NHDLBSC'   
            when type4 = 'JNBHBranch'   then '津南滨海新区办事处'                               --  'YW_JNBHXQBSC'  
            when type4 = 'BCWQBranch'   then '武清北辰办事处'                                   -- 'YW_WQBCBSC'   
            when type4 = 'XQJHBranch'   then '西青静海办事处'                                   -- 'YW_XQJHBSC'   
            when type4 = 'JZBranch'     then '蓟州办事处'                                       -- 'YW_JZBSC'     
            when type4 = 'BDBranch'     then '宝坻办事处'                                       -- 'YW_BDBSC'     
            end                                          as group_name,      	   
	   sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
       sum(case when date_format(repayment_date, '%Y%m%d') < '${v_sdate}' then repayment_amt else 0 end)  as start_balance,  -- 期初余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)                   as start_cnt,      -- 期初笔数
       sum(if(now_guar_amt_day is null,0,now_guar_amt_day))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_day)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_day is null,0,now_repayment_amt_day))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_day)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type4             -- '按办事处',
union all 
select '${v_sdate}'          as day_id,
       '日报'                as report_type,
       '区域'                as group_type,
       type5                 as group_name,      	   
	   sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
       sum(case when date_format(repayment_date, '%Y%m%d') < '${v_sdate}' then repayment_amt else 0 end)  as start_balance,  -- 期初余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)                   as start_cnt,      -- 期初笔数
       sum(if(now_guar_amt_day is null,0,now_guar_amt_day))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_day)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_day is null,0,now_repayment_amt_day))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_day)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type5             -- '按区域',
union all 
select '${v_sdate}'          as day_id,
       '日报'                as report_type,
       '银行一级支行'        as group_type,
       type6                 as group_name,      	   
	   sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
       sum(case when date_format(repayment_date, '%Y%m%d') < '${v_sdate}' then repayment_amt else 0 end)  as start_balance,  -- 期初余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)                   as start_cnt,      -- 期初笔数
       sum(if(now_guar_amt_day is null,0,now_guar_amt_day))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_day)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_day is null,0,now_repayment_amt_day))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_day)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type6             -- '按一级支行',
union all 
select '${v_sdate}'          as day_id,
       '日报'                as report_type,
       '项目经理'            as group_type,
       type7                 as group_name,      	   
	   sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
       sum(case when date_format(repayment_date, '%Y%m%d') < '${v_sdate}' then repayment_amt else 0 end)  as start_balance,  -- 期初余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)                   as start_cnt,      -- 期初笔数
       sum(if(now_guar_amt_day is null,0,now_guar_amt_day))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_day)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_day is null,0,now_repayment_amt_day))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_day)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type7             -- '按项目经理',
;
commit;

 -- 旬报
 insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
 (day_id, -- 数据日期
  report_type,-- 报表类型 (日报、旬报、月报、季报、半年报、年报)
  group_type, -- 统计类型
  group_name, -- 分组名称
  start_balance, -- 期初余额(万元)
  start_cnt, -- 期初笔数
  now_guar_amt, -- 当期放款金额(万元)
  now_guar_cnt, -- 当期放款笔数
  now_repayment_amt, -- 当期还款金额(万元)
  now_repayment_cnt, -- 当期还款笔数
  end_balance, -- 期末余额(万元)
  end_cnt -- 期末笔数
 )
select '${v_sdate}'          as day_id,
       '旬报'                as report_type,
       '银行'                as group_type,
       type1                 as group_name,        
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号	   
	   sum(case when date_format(guar_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
					 then guar_amt else 0 end) -					 
       sum(case when date_format(repayment_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
	                then repayment_amt else 0 end)                                                        as start_balance,  -- 期初余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 ) 
	                then 1 else 0 end)                                                                    as start_cnt,      -- 期初笔数
       sum(if(now_guar_amt_xun is null,0,now_guar_amt_xun))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_xun)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_xun is null,0,now_repayment_amt_xun))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_xun)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type1             -- '按银行',
union all 
select '${v_sdate}'          as day_id,
       '旬报'                as report_type,
       '产品'                as group_type,
       type2                 as group_name,        
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号	   
	   sum(case when date_format(guar_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
					 then guar_amt else 0 end) -					 
       sum(case when date_format(repayment_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
	                then repayment_amt else 0 end)                                                        as start_balance,  -- 期初余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 ) 
	                then 1 else 0 end)                                                                    as start_cnt,      -- 期初笔数
       sum(if(now_guar_amt_xun is null,0,now_guar_amt_xun))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_xun)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_xun is null,0,now_repayment_amt_xun))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_xun)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type2             -- '按产品',
union all 
select '${v_sdate}'          as day_id,
       '旬报'                as report_type,
       '行业归类'                as group_type,
       case
            when type3 = '08' then '农产品初加工'                                           -- 0
            when type3 = '01' then '粮食种植'                                              -- 1
            when type3 = '02' then '重要、特色农产品种植'                                     -- 2
            when type3 = '04' then '其他畜牧业'                                            -- 3
            when type3 = '03' then '生猪养殖'                                              -- 4
            when type3 = '07' then '农产品流通'                                            -- 5
            when type3 = '05' then '渔业生产'                                              -- 6
            when type3 = '12' then '农资、农机、农技等农业社会化服务'                           -- 7
            when type3 = '09' then '农业新业态'                                            -- 8
            when type3 = '06' then '农田建设'                                              -- 9
            when type3 = '10' then '其他农业项目'                                          -- 10
			when type3 = '99' then '其他'
            end                    as group_name,      	   
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号	   
	   sum(case when date_format(guar_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
					 then guar_amt else 0 end) -					 
       sum(case when date_format(repayment_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
	                then repayment_amt else 0 end)                                                        as start_balance,  -- 期初余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 ) 
	                then 1 else 0 end)                                                                    as start_cnt,      -- 期初笔数
       sum(if(now_guar_amt_xun is null,0,now_guar_amt_xun))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_xun)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_xun is null,0,now_repayment_amt_xun))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_xun)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type3             -- '按产品',
union all 
select '${v_sdate}'          as day_id,
       '旬报'                as report_type,
       '办事处'                as group_type,
       case
            when type4 = 'NHDLBranch'   then '宁河东丽办事处'                                   -- 'YW_NHDLBSC'   
            when type4 = 'JNBHBranch'   then '津南滨海新区办事处'                               --  'YW_JNBHXQBSC'  
            when type4 = 'BCWQBranch'   then '武清北辰办事处'                                   -- 'YW_WQBCBSC'   
            when type4 = 'XQJHBranch'   then '西青静海办事处'                                   -- 'YW_XQJHBSC'   
            when type4 = 'JZBranch'     then '蓟州办事处'                                       -- 'YW_JZBSC'     
            when type4 = 'BDBranch'     then '宝坻办事处'                                       -- 'YW_BDBSC'     
            end                                          as group_name,      	   
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号	   
	   sum(case when date_format(guar_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
					 then guar_amt else 0 end) -					 
       sum(case when date_format(repayment_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
	                then repayment_amt else 0 end)                                                        as start_balance,  -- 期初余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 ) 
	                then 1 else 0 end)                                                                    as start_cnt,      -- 期初笔数
       sum(if(now_guar_amt_xun is null,0,now_guar_amt_xun))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_xun)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_xun is null,0,now_repayment_amt_xun))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_xun)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type4             -- '按办事处',
union all 
select '${v_sdate}'          as day_id,
       '旬报'                as report_type,
       '区域'                as group_type,
       type5                 as group_name,      	   
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号	   
	   sum(case when date_format(guar_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
					 then guar_amt else 0 end) -					 
       sum(case when date_format(repayment_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
	                then repayment_amt else 0 end)                                                        as start_balance,  -- 期初余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 ) 
	                then 1 else 0 end)                                                                    as start_cnt,      -- 期初笔数
       sum(if(now_guar_amt_xun is null,0,now_guar_amt_xun))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_xun)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_xun is null,0,now_repayment_amt_xun))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_xun)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type5             -- '按区域',
union all 
select '${v_sdate}'          as day_id,
       '旬报'                as report_type,
       '银行一级支行'        as group_type,
       type6                 as group_name,      	   
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号	   
	   sum(case when date_format(guar_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
					 then guar_amt else 0 end) -					 
       sum(case when date_format(repayment_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
	                then repayment_amt else 0 end)                                                        as start_balance,  -- 期初余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 ) 
	                then 1 else 0 end)                                                                    as start_cnt,      -- 期初笔数
       sum(if(now_guar_amt_xun is null,0,now_guar_amt_xun))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_xun)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_xun is null,0,now_repayment_amt_xun))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_xun)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type6             -- '按一级支行',
union all 
select '${v_sdate}'          as day_id,
       '旬报'                as report_type,
       '项目经理'            as group_type,
       type7                 as group_name,      	   
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号	   
	   sum(case when date_format(guar_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
					 then guar_amt else 0 end) -					 
       sum(case when date_format(repayment_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
	                then repayment_amt else 0 end)                                                        as start_balance,  -- 期初余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 ) 
	                then 1 else 0 end)                                                                    as start_cnt,      -- 期初笔数
       sum(if(now_guar_amt_xun is null,0,now_guar_amt_xun))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_xun)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_xun is null,0,now_repayment_amt_xun))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_xun)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type7             -- '按项目经理',
;
commit;

 -- 月报
 insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
 (day_id, -- 数据日期
  report_type,-- 报表类型 (日报、旬报、月报、季报、半年报、年报)
  group_type, -- 统计类型
  group_name, -- 分组名称
  start_balance, -- 期初余额(万元)
  start_cnt, -- 期初笔数
  now_guar_amt, -- 当期放款金额(万元)
  now_guar_cnt, -- 当期放款笔数
  now_repayment_amt, -- 当期还款金额(万元)
  now_repayment_cnt, -- 当期还款笔数
  end_balance, -- 期末余额(万元)
  end_cnt -- 期末笔数
 )
select '${v_sdate}'          as day_id,
       '月报'                as report_type,
       '银行'                as group_type,
       type1                 as group_name,  
       sum(case when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') 
	            then guar_amt 
				else 0 end) -
       sum(case when date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01')
	            then repayment_amt 
				else 0 end)                             as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                              as start_cnt,                -- 期初笔数
       sum(if(now_guar_amt_mon is null,0,now_guar_amt_mon))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_mon)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_mon is null,0,now_repayment_amt_mon))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_mon)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type1             -- '按银行',
union all 
select '${v_sdate}'          as day_id,
       '月报'                as report_type,
       '产品'                as group_type,
       type2                 as group_name,        
       sum(case when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') 
	            then guar_amt 
				else 0 end) -
       sum(case when date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01')
	            then repayment_amt 
				else 0 end)                             as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                              as start_cnt,                -- 期初笔数
       sum(if(now_guar_amt_mon is null,0,now_guar_amt_mon))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_mon)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_mon is null,0,now_repayment_amt_mon))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_mon)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type2             -- '按产品',
union all 
select '${v_sdate}'          as day_id,
       '月报'                as report_type,
       '行业归类'                as group_type,
       case
            when type3 = '08' then '农产品初加工'                                           -- 0
            when type3 = '01' then '粮食种植'                                              -- 1
            when type3 = '02' then '重要、特色农产品种植'                                     -- 2
            when type3 = '04' then '其他畜牧业'                                            -- 3
            when type3 = '03' then '生猪养殖'                                              -- 4
            when type3 = '07' then '农产品流通'                                            -- 5
            when type3 = '05' then '渔业生产'                                              -- 6
            when type3 = '12' then '农资、农机、农技等农业社会化服务'                           -- 7
            when type3 = '09' then '农业新业态'                                            -- 8
            when type3 = '06' then '农田建设'                                              -- 9
            when type3 = '10' then '其他农业项目'                                          -- 10
			when type3 = '99' then '其他'
            end                    as group_name,      	   
       sum(case when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') 
	            then guar_amt 
				else 0 end) -
       sum(case when date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01')
	            then repayment_amt 
				else 0 end)                             as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                              as start_cnt,                -- 期初笔数
       sum(if(now_guar_amt_mon is null,0,now_guar_amt_mon))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_mon)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_mon is null,0,now_repayment_amt_mon))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_mon)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type3             -- '按产品',
union all 
select '${v_sdate}'          as day_id,
       '月报'                as report_type,
       '办事处'                as group_type,
       case
            when type4 = 'NHDLBranch'   then '宁河东丽办事处'                                   -- 'YW_NHDLBSC'   
            when type4 = 'JNBHBranch'   then '津南滨海新区办事处'                               --  'YW_JNBHXQBSC'  
            when type4 = 'BCWQBranch'   then '武清北辰办事处'                                   -- 'YW_WQBCBSC'   
            when type4 = 'XQJHBranch'   then '西青静海办事处'                                   -- 'YW_XQJHBSC'   
            when type4 = 'JZBranch'     then '蓟州办事处'                                       -- 'YW_JZBSC'     
            when type4 = 'BDBranch'     then '宝坻办事处'                                       -- 'YW_BDBSC'     
            end                                          as group_name,      	   
       sum(case when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') 
	            then guar_amt 
				else 0 end) -
       sum(case when date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01')
	            then repayment_amt 
				else 0 end)                             as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                              as start_cnt,                -- 期初笔数
       sum(if(now_guar_amt_mon is null,0,now_guar_amt_mon))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_mon)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_mon is null,0,now_repayment_amt_mon))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_mon)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type4             -- '按办事处',
union all 
select '${v_sdate}'          as day_id,
       '月报'                as report_type,
       '区域'                as group_type,
       type5                 as group_name,      	   
       sum(case when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') 
	            then guar_amt 
				else 0 end) -
       sum(case when date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01')
	            then repayment_amt 
				else 0 end)                             as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                              as start_cnt,                -- 期初笔数
       sum(if(now_guar_amt_mon is null,0,now_guar_amt_mon))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_mon)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_mon is null,0,now_repayment_amt_mon))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_mon)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type5             -- '按区域',
union all 
select '${v_sdate}'          as day_id,
       '月报'                as report_type,
       '银行一级支行'        as group_type,
       type6                 as group_name,      	   
       sum(case when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') 
	            then guar_amt 
				else 0 end) -
       sum(case when date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01')
	            then repayment_amt 
				else 0 end)                             as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                              as start_cnt,                -- 期初笔数
       sum(if(now_guar_amt_mon is null,0,now_guar_amt_mon))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_mon)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_mon is null,0,now_repayment_amt_mon))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_mon)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type6             -- '按一级支行',
union all 
select '${v_sdate}'          as day_id,
       '月报'                as report_type,
       '项目经理'            as group_type,
       type7                 as group_name,      	   
       sum(case when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') 
	            then guar_amt 
				else 0 end) -
       sum(case when date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01')
	            then repayment_amt 
				else 0 end)                             as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                              as start_cnt,                -- 期初笔数
       sum(if(now_guar_amt_mon is null,0,now_guar_amt_mon))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_mon)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_mon is null,0,now_repayment_amt_mon))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_mon)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type7             -- '按项目经理',
;
commit;

 -- 季报
 insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
 (day_id, -- 数据日期
  report_type,-- 报表类型 (日报、旬报、月报、季报、半年报、年报)
  group_type, -- 统计类型
  group_name, -- 分组名称
  start_balance, -- 期初余额(万元)
  start_cnt, -- 期初笔数
  now_guar_amt, -- 当期放款金额(万元)
  now_guar_cnt, -- 当期放款笔数
  now_repayment_amt, -- 当期还款金额(万元)
  now_repayment_cnt, -- 当期还款笔数
  end_balance, -- 期末余额(万元)
  end_cnt -- 期末笔数
 )
select '${v_sdate}'          as day_id,
       '季报'                as report_type,
       '银行'                as group_type,
       type1                 as group_name,  
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1
				       , date_format('${v_sdate}', '%Y0101')
                       , if(quarter('${v_sdate}') = 2
					       , date_format('${v_sdate}', '%Y0401')
                           , if(quarter('${v_sdate}') = 3
							   , date_format('${v_sdate}', '%Y0701')
                               , if(quarter('${v_sdate}') = 4
								   , date_format('${v_sdate}', '%Y1001')
								   , ''
								   )
                                )
						   )
					   )
               then guar_amt
               else 0 end) -
       sum(case
               when date_format(repayment_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1
				       , date_format('${v_sdate}', '%Y0101')
                       , if(quarter('${v_sdate}') = 2
					       , date_format('${v_sdate}', '%Y0401')
                           , if(quarter('${v_sdate}') = 3
						       , date_format('${v_sdate}', '%Y0701')
                               , if(quarter('${v_sdate}') = 4
							       , date_format('${v_sdate}', '%Y1001')
								   , ''
								   )
                                )
							)
						)
               then repayment_amt
               else 0 end)
                                                         as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                              as start_cnt,                -- 期初笔数	   
       sum(if(now_guar_amt_qua is null,0,now_guar_amt_qua))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_qua)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_qua is null,0,now_repayment_amt_qua))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_qua)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type1             -- '按银行',
union all 
select '${v_sdate}'          as day_id,
       '季报'                as report_type,
       '产品'                as group_type,
       type2                 as group_name,        
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1
				       , date_format('${v_sdate}', '%Y0101')
                       , if(quarter('${v_sdate}') = 2
					       , date_format('${v_sdate}', '%Y0401')
                           , if(quarter('${v_sdate}') = 3
							   , date_format('${v_sdate}', '%Y0701')
                               , if(quarter('${v_sdate}') = 4
								   , date_format('${v_sdate}', '%Y1001')
								   , ''
								   )
                                )
						   )
					   )
               then guar_amt
               else 0 end) -
       sum(case
               when date_format(repayment_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1
				       , date_format('${v_sdate}', '%Y0101')
                       , if(quarter('${v_sdate}') = 2
					       , date_format('${v_sdate}', '%Y0401')
                           , if(quarter('${v_sdate}') = 3
						       , date_format('${v_sdate}', '%Y0701')
                               , if(quarter('${v_sdate}') = 4
							       , date_format('${v_sdate}', '%Y1001')
								   , ''
								   )
                                )
							)
						)
               then repayment_amt
               else 0 end)
                                                         as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                              as start_cnt,                -- 期初笔数	   
       sum(if(now_guar_amt_qua is null,0,now_guar_amt_qua))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_qua)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_qua is null,0,now_repayment_amt_qua))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_qua)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type2             -- '按产品',
union all 
select '${v_sdate}'          as day_id,
       '季报'                as report_type,
       '行业归类'                as group_type,
       case
            when type3 = '08' then '农产品初加工'                                           -- 0
            when type3 = '01' then '粮食种植'                                              -- 1
            when type3 = '02' then '重要、特色农产品种植'                                     -- 2
            when type3 = '04' then '其他畜牧业'                                            -- 3
            when type3 = '03' then '生猪养殖'                                              -- 4
            when type3 = '07' then '农产品流通'                                            -- 5
            when type3 = '05' then '渔业生产'                                              -- 6
            when type3 = '12' then '农资、农机、农技等农业社会化服务'                           -- 7
            when type3 = '09' then '农业新业态'                                            -- 8
            when type3 = '06' then '农田建设'                                              -- 9
            when type3 = '10' then '其他农业项目'                                          -- 10
			when type3 = '99' then '其他'
            end                    as group_name,      	   
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1
				       , date_format('${v_sdate}', '%Y0101')
                       , if(quarter('${v_sdate}') = 2
					       , date_format('${v_sdate}', '%Y0401')
                           , if(quarter('${v_sdate}') = 3
							   , date_format('${v_sdate}', '%Y0701')
                               , if(quarter('${v_sdate}') = 4
								   , date_format('${v_sdate}', '%Y1001')
								   , ''
								   )
                                )
						   )
					   )
               then guar_amt
               else 0 end) -
       sum(case
               when date_format(repayment_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1
				       , date_format('${v_sdate}', '%Y0101')
                       , if(quarter('${v_sdate}') = 2
					       , date_format('${v_sdate}', '%Y0401')
                           , if(quarter('${v_sdate}') = 3
						       , date_format('${v_sdate}', '%Y0701')
                               , if(quarter('${v_sdate}') = 4
							       , date_format('${v_sdate}', '%Y1001')
								   , ''
								   )
                                )
							)
						)
               then repayment_amt
               else 0 end)
                                                         as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                              as start_cnt,                -- 期初笔数	   
       sum(if(now_guar_amt_qua is null,0,now_guar_amt_qua))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_qua)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_qua is null,0,now_repayment_amt_qua))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_qua)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type3             -- '按产品',
union all 
select '${v_sdate}'          as day_id,
       '季报'                as report_type,
       '办事处'                as group_type,
       case
            when type4 = 'NHDLBranch'   then '宁河东丽办事处'                                   -- 'YW_NHDLBSC'   
            when type4 = 'JNBHBranch'   then '津南滨海新区办事处'                               --  'YW_JNBHXQBSC'  
            when type4 = 'BCWQBranch'   then '武清北辰办事处'                                   -- 'YW_WQBCBSC'   
            when type4 = 'XQJHBranch'   then '西青静海办事处'                                   -- 'YW_XQJHBSC'   
            when type4 = 'JZBranch'     then '蓟州办事处'                                       -- 'YW_JZBSC'     
            when type4 = 'BDBranch'     then '宝坻办事处'                                       -- 'YW_BDBSC'     
            end                                          as group_name,      	   
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1
				       , date_format('${v_sdate}', '%Y0101')
                       , if(quarter('${v_sdate}') = 2
					       , date_format('${v_sdate}', '%Y0401')
                           , if(quarter('${v_sdate}') = 3
							   , date_format('${v_sdate}', '%Y0701')
                               , if(quarter('${v_sdate}') = 4
								   , date_format('${v_sdate}', '%Y1001')
								   , ''
								   )
                                )
						   )
					   )
               then guar_amt
               else 0 end) -
       sum(case
               when date_format(repayment_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1
				       , date_format('${v_sdate}', '%Y0101')
                       , if(quarter('${v_sdate}') = 2
					       , date_format('${v_sdate}', '%Y0401')
                           , if(quarter('${v_sdate}') = 3
						       , date_format('${v_sdate}', '%Y0701')
                               , if(quarter('${v_sdate}') = 4
							       , date_format('${v_sdate}', '%Y1001')
								   , ''
								   )
                                )
							)
						)
               then repayment_amt
               else 0 end)
                                                         as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                              as start_cnt,                -- 期初笔数	   
       sum(if(now_guar_amt_qua is null,0,now_guar_amt_qua))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_qua)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_qua is null,0,now_repayment_amt_qua))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_qua)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type4             -- '按办事处',
union all 
select '${v_sdate}'          as day_id,
       '季报'                as report_type,
       '区域'                as group_type,
       type5                 as group_name,      	   
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1
				       , date_format('${v_sdate}', '%Y0101')
                       , if(quarter('${v_sdate}') = 2
					       , date_format('${v_sdate}', '%Y0401')
                           , if(quarter('${v_sdate}') = 3
							   , date_format('${v_sdate}', '%Y0701')
                               , if(quarter('${v_sdate}') = 4
								   , date_format('${v_sdate}', '%Y1001')
								   , ''
								   )
                                )
						   )
					   )
               then guar_amt
               else 0 end) -
       sum(case
               when date_format(repayment_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1
				       , date_format('${v_sdate}', '%Y0101')
                       , if(quarter('${v_sdate}') = 2
					       , date_format('${v_sdate}', '%Y0401')
                           , if(quarter('${v_sdate}') = 3
						       , date_format('${v_sdate}', '%Y0701')
                               , if(quarter('${v_sdate}') = 4
							       , date_format('${v_sdate}', '%Y1001')
								   , ''
								   )
                                )
							)
						)
               then repayment_amt
               else 0 end)
                                                         as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                              as start_cnt,                -- 期初笔数	   
       sum(if(now_guar_amt_qua is null,0,now_guar_amt_qua))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_qua)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_qua is null,0,now_repayment_amt_qua))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_qua)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type5             -- '按区域',
union all 
select '${v_sdate}'          as day_id,
       '季报'                as report_type,
       '银行一级支行'        as group_type,
       type6                 as group_name,      	   
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1
				       , date_format('${v_sdate}', '%Y0101')
                       , if(quarter('${v_sdate}') = 2
					       , date_format('${v_sdate}', '%Y0401')
                           , if(quarter('${v_sdate}') = 3
							   , date_format('${v_sdate}', '%Y0701')
                               , if(quarter('${v_sdate}') = 4
								   , date_format('${v_sdate}', '%Y1001')
								   , ''
								   )
                                )
						   )
					   )
               then guar_amt
               else 0 end) -
       sum(case
               when date_format(repayment_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1
				       , date_format('${v_sdate}', '%Y0101')
                       , if(quarter('${v_sdate}') = 2
					       , date_format('${v_sdate}', '%Y0401')
                           , if(quarter('${v_sdate}') = 3
						       , date_format('${v_sdate}', '%Y0701')
                               , if(quarter('${v_sdate}') = 4
							       , date_format('${v_sdate}', '%Y1001')
								   , ''
								   )
                                )
							)
						)
               then repayment_amt
               else 0 end)
                                                         as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                              as start_cnt,                -- 期初笔数	   
       sum(if(now_guar_amt_qua is null,0,now_guar_amt_qua))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_qua)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_qua is null,0,now_repayment_amt_qua))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_qua)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type6             -- '按一级支行',
union all 
select '${v_sdate}'          as day_id,
       '季报'                as report_type,
       '项目经理'            as group_type,
       type7                 as group_name,      	   
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1
				       , date_format('${v_sdate}', '%Y0101')
                       , if(quarter('${v_sdate}') = 2
					       , date_format('${v_sdate}', '%Y0401')
                           , if(quarter('${v_sdate}') = 3
							   , date_format('${v_sdate}', '%Y0701')
                               , if(quarter('${v_sdate}') = 4
								   , date_format('${v_sdate}', '%Y1001')
								   , ''
								   )
                                )
						   )
					   )
               then guar_amt
               else 0 end) -
       sum(case
               when date_format(repayment_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1
				       , date_format('${v_sdate}', '%Y0101')
                       , if(quarter('${v_sdate}') = 2
					       , date_format('${v_sdate}', '%Y0401')
                           , if(quarter('${v_sdate}') = 3
						       , date_format('${v_sdate}', '%Y0701')
                               , if(quarter('${v_sdate}') = 4
							       , date_format('${v_sdate}', '%Y1001')
								   , ''
								   )
                                )
							)
						)
               then repayment_amt
               else 0 end)
                                                         as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                              as start_cnt,                -- 期初笔数	   
       sum(if(now_guar_amt_qua is null,0,now_guar_amt_qua))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_qua)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_qua is null,0,now_repayment_amt_qua))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_qua)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type7             -- '按项目经理',
;
commit;

 -- 半年报
 insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
 (day_id, -- 数据日期
  report_type,-- 报表类型 (日报、旬报、月报、季报、半年报、年报)
  group_type, -- 统计类型
  group_name, -- 分组名称
  start_balance, -- 期初余额(万元)
  start_cnt, -- 期初笔数
  now_guar_amt, -- 当期放款金额(万元)
  now_guar_cnt, -- 当期放款笔数
  now_repayment_amt, -- 当期还款金额(万元)
  now_repayment_cnt, -- 当期还款笔数
  end_balance, -- 期末余额(万元)
  end_cnt -- 期末笔数
 )
select '${v_sdate}'          as day_id,
       '半年报'                as report_type,
       '银行'                as group_type,
       type1                 as group_name,  	   
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then guar_amt
               else 0 end) -
       sum(
                  if(date_format(repayment_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), repayment_amt, 0)
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数   
       sum(if(now_guar_amt_hyr is null,0,now_guar_amt_hyr))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_hyr)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_hyr is null,0,now_repayment_amt_hyr))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_hyr)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type1             -- '按银行',
union all 
select '${v_sdate}'          as day_id,
       '半年报'                as report_type,
       '产品'                as group_type,
       type2                 as group_name,        
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then guar_amt
               else 0 end) -
       sum(
                  if(date_format(repayment_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), repayment_amt, 0)
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数   
       sum(if(now_guar_amt_hyr is null,0,now_guar_amt_hyr))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_hyr)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_hyr is null,0,now_repayment_amt_hyr))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_hyr)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type2             -- '按产品',
union all 
select '${v_sdate}'          as day_id,
       '半年报'                as report_type,
       '行业归类'                as group_type,
       case
            when type3 = '08' then '农产品初加工'                                           -- 0
            when type3 = '01' then '粮食种植'                                              -- 1
            when type3 = '02' then '重要、特色农产品种植'                                     -- 2
            when type3 = '04' then '其他畜牧业'                                            -- 3
            when type3 = '03' then '生猪养殖'                                              -- 4
            when type3 = '07' then '农产品流通'                                            -- 5
            when type3 = '05' then '渔业生产'                                              -- 6
            when type3 = '12' then '农资、农机、农技等农业社会化服务'                           -- 7
            when type3 = '09' then '农业新业态'                                            -- 8
            when type3 = '06' then '农田建设'                                              -- 9
            when type3 = '10' then '其他农业项目'                                          -- 10
			when type3 = '99' then '其他'
            end                    as group_name,      	   
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then guar_amt
               else 0 end) -
       sum(
                  if(date_format(repayment_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), repayment_amt, 0)
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数   
       sum(if(now_guar_amt_hyr is null,0,now_guar_amt_hyr))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_hyr)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_hyr is null,0,now_repayment_amt_hyr))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_hyr)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type3             -- '按产品',
union all 
select '${v_sdate}'          as day_id,
       '半年报'                as report_type,
       '办事处'                as group_type,
       case
            when type4 = 'NHDLBranch'   then '宁河东丽办事处'                                   -- 'YW_NHDLBSC'   
            when type4 = 'JNBHBranch'   then '津南滨海新区办事处'                               --  'YW_JNBHXQBSC'  
            when type4 = 'BCWQBranch'   then '武清北辰办事处'                                   -- 'YW_WQBCBSC'   
            when type4 = 'XQJHBranch'   then '西青静海办事处'                                   -- 'YW_XQJHBSC'   
            when type4 = 'JZBranch'     then '蓟州办事处'                                       -- 'YW_JZBSC'     
            when type4 = 'BDBranch'     then '宝坻办事处'                                       -- 'YW_BDBSC'     
            end                                          as group_name,      	   
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then guar_amt
               else 0 end) -
       sum(
                  if(date_format(repayment_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), repayment_amt, 0)
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数   
       sum(if(now_guar_amt_hyr is null,0,now_guar_amt_hyr))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_hyr)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_hyr is null,0,now_repayment_amt_hyr))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_hyr)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type4             -- '按办事处',
union all 
select '${v_sdate}'          as day_id,
       '半年报'                as report_type,
       '区域'                as group_type,
       type5                 as group_name,      	   
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then guar_amt
               else 0 end) -
       sum(
                  if(date_format(repayment_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), repayment_amt, 0)
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数   
       sum(if(now_guar_amt_hyr is null,0,now_guar_amt_hyr))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_hyr)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_hyr is null,0,now_repayment_amt_hyr))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_hyr)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type5             -- '按区域',
union all 
select '${v_sdate}'          as day_id,
       '半年报'                as report_type,
       '银行一级支行'        as group_type,
       type6                 as group_name,      	   
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then guar_amt
               else 0 end) -
       sum(
                  if(date_format(repayment_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), repayment_amt, 0)
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数   
       sum(if(now_guar_amt_hyr is null,0,now_guar_amt_hyr))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_hyr)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_hyr is null,0,now_repayment_amt_hyr))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_hyr)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type6             -- '按一级支行',
union all 
select '${v_sdate}'          as day_id,
       '半年报'                as report_type,
       '项目经理'            as group_type,
       type7                 as group_name,      	   
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then guar_amt
               else 0 end) -
       sum(
                  if(date_format(repayment_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), repayment_amt, 0)
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数   
       sum(if(now_guar_amt_hyr is null,0,now_guar_amt_hyr))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_hyr)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_hyr is null,0,now_repayment_amt_hyr))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_hyr)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type7             -- '按项目经理',
;
commit;

 -- 年报
 insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
 (day_id, -- 数据日期
  report_type,-- 报表类型 (日报、旬报、月报、季报、半年报、年报)
  group_type, -- 统计类型
  group_name, -- 分组名称
  start_balance, -- 期初余额(万元)
  start_cnt, -- 期初笔数
  now_guar_amt, -- 当期放款金额(万元)
  now_guar_cnt, -- 当期放款笔数
  now_repayment_amt, -- 当期还款金额(万元)
  now_repayment_cnt, -- 当期还款笔数
  end_balance, -- 期末余额(万元)
  end_cnt -- 期末笔数
 )
select '${v_sdate}'          as day_id,
       '年报'                as report_type,
       '银行'                as group_type,
       type1                 as group_name,  
       sum(case
               when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then guar_amt
               else 0 end) -
       sum(
                  if(date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), repayment_amt, 0)   
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数    
       sum(if(now_guar_amt_tyr is null,0,now_guar_amt_tyr))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_tyr)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_tyr is null,0,now_repayment_amt_tyr))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_tyr)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type1             -- '按银行',
union all 
select '${v_sdate}'          as day_id,
       '年报'                as report_type,
       '产品'                as group_type,
       type2                 as group_name,        
       sum(case
               when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then guar_amt
               else 0 end) -
       sum(
                  if(date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), repayment_amt, 0)   
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数    
       sum(if(now_guar_amt_tyr is null,0,now_guar_amt_tyr))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_tyr)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_tyr is null,0,now_repayment_amt_tyr))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_tyr)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type2             -- '按产品',
union all 
select '${v_sdate}'          as day_id,
       '年报'                as report_type,
       '行业归类'                as group_type,
       case
            when type3 = '08' then '农产品初加工'                                           -- 0
            when type3 = '01' then '粮食种植'                                              -- 1
            when type3 = '02' then '重要、特色农产品种植'                                     -- 2
            when type3 = '04' then '其他畜牧业'                                            -- 3
            when type3 = '03' then '生猪养殖'                                              -- 4
            when type3 = '07' then '农产品流通'                                            -- 5
            when type3 = '05' then '渔业生产'                                              -- 6
            when type3 = '12' then '农资、农机、农技等农业社会化服务'                           -- 7
            when type3 = '09' then '农业新业态'                                            -- 8
            when type3 = '06' then '农田建设'                                              -- 9
            when type3 = '10' then '其他农业项目'                                          -- 10
			when type3 = '99' then '其他'
            end                    as group_name,      	   
       sum(case
               when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then guar_amt
               else 0 end) -
       sum(
                  if(date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), repayment_amt, 0)   
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数    
       sum(if(now_guar_amt_tyr is null,0,now_guar_amt_tyr))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_tyr)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_tyr is null,0,now_repayment_amt_tyr))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_tyr)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type3             -- '按产品',
union all 
select '${v_sdate}'          as day_id,
       '年报'                as report_type,
       '办事处'                as group_type,
       case
            when type4 = 'NHDLBranch'   then '宁河东丽办事处'                                   -- 'YW_NHDLBSC'   
            when type4 = 'JNBHBranch'   then '津南滨海新区办事处'                               --  'YW_JNBHXQBSC'  
            when type4 = 'BCWQBranch'   then '武清北辰办事处'                                   -- 'YW_WQBCBSC'   
            when type4 = 'XQJHBranch'   then '西青静海办事处'                                   -- 'YW_XQJHBSC'   
            when type4 = 'JZBranch'     then '蓟州办事处'                                       -- 'YW_JZBSC'     
            when type4 = 'BDBranch'     then '宝坻办事处'                                       -- 'YW_BDBSC'     
            end                                          as group_name,      	   
       sum(case
               when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then guar_amt
               else 0 end) -
       sum(
                  if(date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), repayment_amt, 0)   
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数    
       sum(if(now_guar_amt_tyr is null,0,now_guar_amt_tyr))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_tyr)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_tyr is null,0,now_repayment_amt_tyr))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_tyr)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type4             -- '按办事处',
union all 
select '${v_sdate}'          as day_id,
       '年报'                as report_type,
       '区域'                as group_type,
       type5                 as group_name,      	   
       sum(case
               when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then guar_amt
               else 0 end) -
       sum(
                  if(date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), repayment_amt, 0)   
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数    
       sum(if(now_guar_amt_tyr is null,0,now_guar_amt_tyr))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_tyr)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_tyr is null,0,now_repayment_amt_tyr))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_tyr)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type5             -- '按区域',
union all 
select '${v_sdate}'          as day_id,
       '年报'                as report_type,
       '银行一级支行'        as group_type,
       type6                 as group_name,      	   
       sum(case
               when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then guar_amt
               else 0 end) -
       sum(
                  if(date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), repayment_amt, 0)   
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数    
       sum(if(now_guar_amt_tyr is null,0,now_guar_amt_tyr))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_tyr)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_tyr is null,0,now_repayment_amt_tyr))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_tyr)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type6             -- '按一级支行',
union all 
select '${v_sdate}'          as day_id,
       '年报'                as report_type,
       '项目经理'            as group_type,
       type7                 as group_name,      	   
       sum(case
               when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then guar_amt
               else 0 end) -
       sum(
                  if(date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), repayment_amt, 0)   
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(guar_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数    
       sum(if(now_guar_amt_tyr is null,0,now_guar_amt_tyr))                                               as now_guar_amt,         -- 当期放款金额(万元)
       sum(now_guar_cnt_tyr)                                                                              as now_guar_cnt,         -- 当期放款笔数
       sum(if(now_repayment_amt_tyr is null,0,now_repayment_amt_tyr))                                     as now_repayment_amt,         -- 当期还款金额(万元)
       sum(now_repayment_cnt_tyr)                                                                         as now_repayment_cnt,         -- 当期还款笔数
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
       sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_old_data_main
group by type7             -- '按项目经理',
;
commit;


-- -----------------------------------------------
-- 新业务系统逻辑
-- 补充在保转进件业务缺失数据
drop table if exists dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_new_lose_data;
commit;

create table dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_new_lose_data(
 guar_id varchar(50) comment '项目编号'
,PRODUCT_NAME varchar(50) comment '产品名称'
,key tmp_ads_rpt_tjnd_busi_record_stat_loan_new_lose_data (guar_id) comment '业务编号索引'
) engine = InnoDB
  default charset = utf8mb4
  collate = utf8mb4_bin;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_new_lose_data
select t1.GUARANTEE_CODE as guar_id
      ,t2.PRODUCT_NAME
from (
          select ID,                    -- 业务id
                 COOPERATIVE_BANK_FIRST -- 银行对应编码
				,PRODUCT_GRADE -- 产品对应编码
				,ID_CUSTOMER -- 客户对应id
				,enter_code as branch_off -- 部门编码
				,JSON_UNQUOTE(JSON_EXTRACT(area, '$[1]')) as area -- 转换为区县
				,COOPERATIVE_BANK_SECOND -- 二级支行编码
				,BUSINESS_SP_USER_NAME -- 项目经理
				,GUARANTEE_CODE
--          from dw_nd.ods_tjnd_yw_afg_business_infomation  
		  from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation -- 业务申请表 
--          where GUR_STATE in ('GT', 'ED')
        --  where GUR_STATE in ('90','93')     -- [排掉在保的]
      ) t1
      left join 
      (
          select fieldcode,   -- 产品编码
                 PRODUCT_NAME -- 产品名称
          -- from dw_nd.ods_tjnd_yw_base_product_management
		  from dw_nd.ods_creditmid_v2_z_migrate_base_product_management -- BO,产品管理,NEW
      ) t2 on t1.PRODUCT_GRADE = t2.fieldcode
;
commit;


-- 按银行
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '日报'                                                                                 as report_type,
       '银行'                                                                                 as group_type,
       gnd_dept_name,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') < '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') < '${v_sdate}', repayment_amt, 0)))  as start_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)   as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank    -- 合作银行
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id

         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3
     on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt = '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') = '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,
                gnd_dept_name
         from dw_base.dwd_tjnd_report_biz_loan_bank
         where day_id = '${v_sdate}'
     ) t6 on t1.guar_id = t6.biz_no
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and biz_unguar_dt = '${v_sdate}'
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by gnd_dept_name;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '旬报'                                                                                 as report_type,
       '银行'                                                                                 as group_type,
       gnd_dept_name,
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                        , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                             date_format('${v_sdate}', '%Y%m20'))
                        )
                   then guar_amt
               else 0 end)
           -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d')
                         < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                         , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                              date_format('${v_sdate}', '%Y%m20'))
                         ), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d')
                         < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                         , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                              date_format('${v_sdate}', '%Y%m20'))
                         ), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                        , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                             date_format('${v_sdate}', '%Y%m20'))
                        )
                   then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank    -- 合作银行
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'),
                  loan_reg_dt between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
             , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'),
                  loan_reg_dt between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                      , loan_reg_dt between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}')
             )
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'),
                  date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                   , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'),
                        date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                      , date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}')
                   )
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,
                gnd_dept_name
         from dw_base.dwd_tjnd_report_biz_loan_bank
         where day_id = '${v_sdate}'
     ) t6 on t1.guar_id = t6.biz_no
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'),
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10'),
                  if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'),
                     date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20'),
                     date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}')
             )
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by gnd_dept_name;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '月报'                                                                                 as report_type,
       '银行'                                                                                 as group_type,
       gnd_dept_name,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01'), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01'), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank    -- 合作银行
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,
                gnd_dept_name
         from dw_base.dwd_tjnd_report_biz_loan_bank
         where day_id = '${v_sdate}'
     ) t6 on t1.guar_id = t6.biz_no
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}'
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by gnd_dept_name;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '季报'                                                                                 as report_type,
       '银行'                                                                                 as group_type,
       gnd_dept_name,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d')
                         < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                         , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                                  , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                  , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                  ))), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d')
                         < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                         , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                                  , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                  , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                  ))), repayment_amt, 0)
                   )
           )
                                                                                            as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank    -- 合作银行
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if(quarter('${v_sdate}') = 1, loan_reg_dt between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , if(quarter('${v_sdate}') = 2, loan_reg_dt between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                      ,
                  if(quarter('${v_sdate}') = 3, loan_reg_dt between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 4,
                           loan_reg_dt between date_format('${v_sdate}', '%Y1001') and '${v_sdate}', '')
                      )))
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if(quarter('${v_sdate}') = 1,
                  date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                   , if(quarter('${v_sdate}') = 2,
                        date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 3,
                           date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                            , if(quarter('${v_sdate}') = 4,
                                 date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}',
                                 '')
                            )))
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,
                gnd_dept_name
         from dw_base.dwd_tjnd_report_biz_loan_bank
         where day_id = '${v_sdate}'
     ) t6 on t1.guar_id = t6.biz_no
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and if(quarter('${v_sdate}') = 1,
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , if(quarter('${v_sdate}') = 2,
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 3,
                           date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 4,
                           date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}',
                           '')
                      )))
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by gnd_dept_name;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '半年报'                                                                                as report_type,
       '银行'                                                                                 as group_type,
       gnd_dept_name,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank    -- 合作银行
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'),
                  loan_reg_dt between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , loan_reg_dt between date_format('${v_sdate}', '%Y0701') and '${v_sdate}')
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'),
                  date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                   , date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}')
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,
                gnd_dept_name
         from dw_base.dwd_tjnd_report_biz_loan_bank
         where day_id = '${v_sdate}'
     ) t6 on t1.guar_id = t6.biz_no
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'),
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}')
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by gnd_dept_name;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '年报'                                                                                 as report_type,
       '银行'                                                                                 as group_type,
       gnd_dept_name,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank    -- 合作银行
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and left(loan_reg_dt, 4) = left('${v_sdate}', 4)
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where left(repay_date, 4) = left('${v_sdate}', 4)
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,
                gnd_dept_name
         from dw_base.dwd_tjnd_report_biz_loan_bank
         where day_id = '${v_sdate}'
     ) t6 on t1.guar_id = t6.biz_no
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and left(biz_unguar_dt, 4) = left('${v_sdate}', 4)
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by gnd_dept_name;
commit;

-- 按产品
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '日报'                                                                                 as report_type,
       '产品'                                                                                 as group_type,
       coalesce(product_type,t8.PRODUCT_NAME) as product_type,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') < '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') < '${v_sdate}', repayment_amt, 0)))  as start_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)   as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank    -- 合作银行
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id

         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3
     on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt = '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') = '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
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
     ) t6 on t2.project_id = t6.project_id
         left join
     (
         select code, value as product_type
         from (
                  select *, row_number() over (partition by id order by update_time desc) as rn
                  from dw_nd.ods_t_sys_data_dict_value_v2
                  where dict_code = 'aggregateScheme'
              ) t1
         where rn = 1
     ) t7 on t6.aggregate_scheme = t7.code
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and biz_unguar_dt = '${v_sdate}'
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
left join dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_new_lose_data t8
on t1.guar_id = t8.guar_id 	 
group by coalesce(product_type,t8.PRODUCT_NAME);
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '旬报'                                                                                 as report_type,
       '产品'                                                                                 as group_type,
       coalesce(product_type,t8.PRODUCT_NAME) as product_type,
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                        , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                             date_format('${v_sdate}', '%Y%m20'))
                        )
                   then guar_amt
               else 0 end)
           -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d')
                         < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                         , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                              date_format('${v_sdate}', '%Y%m20'))
                         ), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d')
                         < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                         , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                              date_format('${v_sdate}', '%Y%m20'))
                         ), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                        , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                             date_format('${v_sdate}', '%Y%m20'))
                        )
                   then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank    -- 合作银行
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'),
                  loan_reg_dt between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
             , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'),
                  loan_reg_dt between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                      , loan_reg_dt between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}')
             )
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'),
                  date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                   , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'),
                        date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                      , date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}')
                   )
         group by project_id
     ) t5 on t2.project_id = t5.project_id
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
     ) t6 on t2.project_id = t6.project_id
         left join
     (
         select code, value as product_type
         from (
                  select *, row_number() over (partition by id order by update_time desc) as rn
                  from dw_nd.ods_t_sys_data_dict_value_v2
                  where dict_code = 'aggregateScheme'
              ) t1
         where rn = 1
     ) t7 on t6.aggregate_scheme = t7.code
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'),
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10'),
                  if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'),
                     date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20'),
                     date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}')
             )
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
left join dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_new_lose_data t8
on t1.guar_id = t8.guar_id 	 
group by coalesce(product_type,t8.PRODUCT_NAME);
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '月报'                                                                                 as report_type,
       '产品'                                                                                 as group_type,
       coalesce(product_type,t8.PRODUCT_NAME) as product_type,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01'), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01'), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank    -- 合作银行
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
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
     ) t6 on t2.project_id = t6.project_id
         left join
     (
         select code, value as product_type
         from (
                  select *, row_number() over (partition by id order by update_time desc) as rn
                  from dw_nd.ods_t_sys_data_dict_value_v2
                  where dict_code = 'aggregateScheme'
              ) t1
         where rn = 1
     ) t7 on t6.aggregate_scheme = t7.code
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}'
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
left join dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_new_lose_data t8
on t1.guar_id = t8.guar_id 	 
group by coalesce(product_type,t8.PRODUCT_NAME);
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '季报'                                                                                 as report_type,
       '产品'                                                                                 as group_type,
       coalesce(product_type,t8.PRODUCT_NAME) as product_type,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d')
                         < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                         , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                                  , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                  , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                  ))), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d')
                         < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                         , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                                  , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                  , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                  ))), repayment_amt, 0)
                   )
           )
                                                                                            as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank    -- 合作银行
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if(quarter('${v_sdate}') = 1, loan_reg_dt between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , if(quarter('${v_sdate}') = 2, loan_reg_dt between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                      ,
                  if(quarter('${v_sdate}') = 3, loan_reg_dt between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 4,
                           loan_reg_dt between date_format('${v_sdate}', '%Y1001') and '${v_sdate}', '')
                      )))
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if(quarter('${v_sdate}') = 1,
                  date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                   , if(quarter('${v_sdate}') = 2,
                        date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 3,
                           date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                            , if(quarter('${v_sdate}') = 4,
                                 date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}',
                                 '')
                            )))
         group by project_id
     ) t5 on t2.project_id = t5.project_id
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
     ) t6 on t2.project_id = t6.project_id
         left join
     (
         select code, value as product_type
         from (
                  select *, row_number() over (partition by id order by update_time desc) as rn
                  from dw_nd.ods_t_sys_data_dict_value_v2
                  where dict_code = 'aggregateScheme'
              ) t1
         where rn = 1
     ) t7 on t6.aggregate_scheme = t7.code
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and if(quarter('${v_sdate}') = 1,
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , if(quarter('${v_sdate}') = 2,
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 3,
                           date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 4,
                           date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}',
                           '')
                      )))
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
left join dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_new_lose_data t8
on t1.guar_id = t8.guar_id 	 
group by coalesce(product_type,t8.PRODUCT_NAME);
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '半年报'                                                                                as report_type,
       '产品'                                                                                 as group_type,
       coalesce(product_type,t8.PRODUCT_NAME) as product_type,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank    -- 合作银行
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'),
                  loan_reg_dt between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , loan_reg_dt between date_format('${v_sdate}', '%Y0701') and '${v_sdate}')
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'),
                  date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                   , date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}')
         group by project_id
     ) t5 on t2.project_id = t5.project_id
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
     ) t6 on t2.project_id = t6.project_id
         left join
     (
         select code, value as product_type
         from (
                  select *, row_number() over (partition by id order by update_time desc) as rn
                  from dw_nd.ods_t_sys_data_dict_value_v2
                  where dict_code = 'aggregateScheme'
              ) t1
         where rn = 1
     ) t7 on t6.aggregate_scheme = t7.code
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'),
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}')
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
left join dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_new_lose_data t8
on t1.guar_id = t8.guar_id 	 
group by coalesce(product_type,t8.PRODUCT_NAME);
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '年报'                                                                                 as report_type,
       '产品'                                                                                 as group_type,
       coalesce(product_type,t8.PRODUCT_NAME) as product_type,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank    -- 合作银行
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and left(loan_reg_dt, 4) = left('${v_sdate}', 4)
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where left(repay_date, 4) = left('${v_sdate}', 4)
         group by project_id
     ) t5 on t2.project_id = t5.project_id
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
     ) t6 on t2.project_id = t6.project_id
         left join
     (
         select code, value as product_type
         from (
                  select *, row_number() over (partition by id order by update_time desc) as rn
                  from dw_nd.ods_t_sys_data_dict_value_v2
                  where dict_code = 'aggregateScheme'
              ) t1
         where rn = 1
     ) t7 on t6.aggregate_scheme = t7.code
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and left(biz_unguar_dt, 4) = left('${v_sdate}', 4)
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
left join dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan_new_lose_data t8
on t1.guar_id = t8.guar_id 	 
group by coalesce(product_type,t8.PRODUCT_NAME);
commit;

-- 按行业归类
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '日报'                                                                                 as report_type,
       '行业归类'                                                                               as group_type,
       guar_class,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') < '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') < '${v_sdate}', repayment_amt, 0)))  as start_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)   as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                guar_class
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id

         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3
     on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt = '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') = '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and biz_unguar_dt = '${v_sdate}'
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by guar_class;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '旬报'                                                                                 as report_type,
       '行业归类'                                                                               as group_type,
       guar_class,
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                        , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                             date_format('${v_sdate}', '%Y%m20'))
                        )
                   then guar_amt
               else 0 end)
           -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d')
                         < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                         , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                              date_format('${v_sdate}', '%Y%m20'))
                         ), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d')
                         < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                         , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                              date_format('${v_sdate}', '%Y%m20'))
                         ), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                        , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                             date_format('${v_sdate}', '%Y%m20'))
                        )
                   then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                guar_class
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'),
                  loan_reg_dt between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
             , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'),
                  loan_reg_dt between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                      , loan_reg_dt between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}')
             )
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'),
                  date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                   , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'),
                        date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                      , date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}')
                   )
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'),
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10'),
                  if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'),
                     date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20'),
                     date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}')
             )
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by guar_class;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '月报'                                                                                 as report_type,
       '行业归类'                                                                               as group_type,
       guar_class,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01'), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01'), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                guar_class
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}'
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by guar_class;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '季报'                                                                                 as report_type,
       '行业归类'                                                                               as group_type,
       guar_class,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d')
                         < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                         , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                                  , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                  , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                  ))), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d')
                         < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                         , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                                  , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                  , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                  ))), repayment_amt, 0)
                   )
           )
                                                                                            as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                guar_class
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if(quarter('${v_sdate}') = 1, loan_reg_dt between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , if(quarter('${v_sdate}') = 2, loan_reg_dt between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                      ,
                  if(quarter('${v_sdate}') = 3, loan_reg_dt between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 4,
                           loan_reg_dt between date_format('${v_sdate}', '%Y1001') and '${v_sdate}', '')
                      )))
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if(quarter('${v_sdate}') = 1,
                  date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                   , if(quarter('${v_sdate}') = 2,
                        date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 3,
                           date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                            , if(quarter('${v_sdate}') = 4,
                                 date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}',
                                 '')
                            )))
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and if(quarter('${v_sdate}') = 1,
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , if(quarter('${v_sdate}') = 2,
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 3,
                           date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 4,
                           date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}',
                           '')
                      )))
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by guar_class;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '半年报'                                                                                as report_type,
       '行业归类'                                                                               as group_type,
       guar_class,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                guar_class
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'),
                  loan_reg_dt between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , loan_reg_dt between date_format('${v_sdate}', '%Y0701') and '${v_sdate}')
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'),
                  date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                   , date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}')
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'),
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}')
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by guar_class;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '年报'                                                                                 as report_type,
       '行业归类'                                                                               as group_type,
       guar_class,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                guar_class
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and left(loan_reg_dt, 4) = left('${v_sdate}', 4)
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where left(repay_date, 4) = left('${v_sdate}', 4)
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and left(biz_unguar_dt, 4) = left('${v_sdate}', 4)
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by guar_class;
commit;

-- 按办事处
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '日报'                                                                                 as report_type,
       '办事处'                                                                                as group_type,
       case
           when coalesce(t7.branch_off, t6.branch_off) = 'NHDLBranch' then '宁河东丽办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'JNBHBranch' then '津南滨海新区办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'BCWQBranch' then '武清北辰办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'XQJHBranch' then '西青静海办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'JZBranch' then '蓟州办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'BDBranch' then '宝坻办事处'
           end                                                                              as branch_off,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') < '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') < '${v_sdate}', repayment_amt, 0)))  as start_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)   as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,      -- 业务id
                guar_amt,     -- 放款金额(万元)
                loan_reg_dt,  -- 放款登记日期
                country_code, -- 区县编码
                town_name     -- 乡镇/街道
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id

         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3
     on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt = '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') = '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
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
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and biz_unguar_dt = '${v_sdate}'
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by coalesce(t7.branch_off, t6.branch_off);
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '旬报'                                                                                 as report_type,
       '办事处'                                                                                as group_type,
       case
           when coalesce(t7.branch_off, t6.branch_off) = 'NHDLBranch' then '宁河东丽办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'JNBHBranch' then '津南滨海新区办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'BCWQBranch' then '武清北辰办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'XQJHBranch' then '西青静海办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'JZBranch' then '蓟州办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'BDBranch' then '宝坻办事处'
           end                                                                              as branch_off,
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                        , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                             date_format('${v_sdate}', '%Y%m20'))
                        )
                   then guar_amt
               else 0 end)
           -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d')
                         < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                         , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                              date_format('${v_sdate}', '%Y%m20'))
                         ), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d')
                         < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                         , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                              date_format('${v_sdate}', '%Y%m20'))
                         ), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                        , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                             date_format('${v_sdate}', '%Y%m20'))
                        )
                   then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,      -- 业务id
                guar_amt,     -- 放款金额(万元)
                loan_reg_dt,  -- 放款登记日期
                country_code, -- 区县编码
                town_name     -- 乡镇/街道
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'),
                  loan_reg_dt between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
             , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'),
                  loan_reg_dt between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                      , loan_reg_dt between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}')
             )
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'),
                  date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                   , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'),
                        date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                      , date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}')
                   )
         group by project_id
     ) t5 on t2.project_id = t5.project_id
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
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'),
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10'),
                  if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'),
                     date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20'),
                     date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}')
             )
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by coalesce(t7.branch_off, t6.branch_off);
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '月报'                                                                                 as report_type,
       '办事处'                                                                                as group_type,
       case
           when coalesce(t7.branch_off, t6.branch_off) = 'NHDLBranch' then '宁河东丽办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'JNBHBranch' then '津南滨海新区办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'BCWQBranch' then '武清北辰办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'XQJHBranch' then '西青静海办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'JZBranch' then '蓟州办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'BDBranch' then '宝坻办事处'
           end                                                                              as branch_off,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01'), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01'), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,      -- 业务id
                guar_amt,     -- 放款金额(万元)
                loan_reg_dt,  -- 放款登记日期
                country_code, -- 区县编码
                town_name     -- 乡镇/街道
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
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
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}'
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by coalesce(t7.branch_off, t6.branch_off);
commit;
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '季报'                                                                                 as report_type,
       '办事处'                                                                                as group_type,
       case
           when coalesce(t7.branch_off, t6.branch_off) = 'NHDLBranch' then '宁河东丽办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'JNBHBranch' then '津南滨海新区办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'BCWQBranch' then '武清北辰办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'XQJHBranch' then '西青静海办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'JZBranch' then '蓟州办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'BDBranch' then '宝坻办事处'
           end                                                                              as branch_off,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d')
                         < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                         , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                                  , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                  , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                  ))), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d')
                         < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                         , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                                  , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                  , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                  ))), repayment_amt, 0)
                   )
           )
                                                                                            as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,      -- 业务id
                guar_amt,     -- 放款金额(万元)
                loan_reg_dt,  -- 放款登记日期
                country_code, -- 区县编码
                town_name     -- 乡镇/街道
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if(quarter('${v_sdate}') = 1, loan_reg_dt between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , if(quarter('${v_sdate}') = 2, loan_reg_dt between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                      ,
                  if(quarter('${v_sdate}') = 3, loan_reg_dt between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 4,
                           loan_reg_dt between date_format('${v_sdate}', '%Y1001') and '${v_sdate}', '')
                      )))
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if(quarter('${v_sdate}') = 1,
                  date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                   , if(quarter('${v_sdate}') = 2,
                        date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 3,
                           date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                            , if(quarter('${v_sdate}') = 4,
                                 date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}',
                                 '')
                            )))
         group by project_id
     ) t5 on t2.project_id = t5.project_id
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
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and if(quarter('${v_sdate}') = 1,
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , if(quarter('${v_sdate}') = 2,
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 3,
                           date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 4,
                           date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}',
                           '')
                      )))
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by coalesce(t7.branch_off, t6.branch_off);
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '半年报'                                                                                as report_type,
       '办事处'                                                                                as group_type,
       case
           when coalesce(t7.branch_off, t6.branch_off) = 'NHDLBranch' then '宁河东丽办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'JNBHBranch' then '津南滨海新区办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'BCWQBranch' then '武清北辰办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'XQJHBranch' then '西青静海办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'JZBranch' then '蓟州办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'BDBranch' then '宝坻办事处'
           end                                                                              as branch_off,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,      -- 业务id
                guar_amt,     -- 放款金额(万元)
                loan_reg_dt,  -- 放款登记日期
                country_code, -- 区县编码
                town_name     -- 乡镇/街道
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'),
                  loan_reg_dt between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , loan_reg_dt between date_format('${v_sdate}', '%Y0701') and '${v_sdate}')
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'),
                  date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                   , date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}')
         group by project_id
     ) t5 on t2.project_id = t5.project_id
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
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'),
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}')
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by coalesce(t7.branch_off, t6.branch_off);
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '年报'                                                                                 as report_type,
       '办事处'                                                                                as group_type,
       case
           when coalesce(t7.branch_off, t6.branch_off) = 'NHDLBranch' then '宁河东丽办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'JNBHBranch' then '津南滨海新区办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'BCWQBranch' then '武清北辰办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'XQJHBranch' then '西青静海办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'JZBranch' then '蓟州办事处'
           when coalesce(t7.branch_off, t6.branch_off) = 'BDBranch' then '宝坻办事处'
           end                                                                              as branch_off,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,      -- 业务id
                guar_amt,     -- 放款金额(万元)
                loan_reg_dt,  -- 放款登记日期
                country_code, -- 区县编码
                town_name     -- 乡镇/街道
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and left(loan_reg_dt, 4) = left('${v_sdate}', 4)
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where left(repay_date, 4) = left('${v_sdate}', 4)
         group by project_id
     ) t5 on t2.project_id = t5.project_id
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
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and left(biz_unguar_dt, 4) = left('${v_sdate}', 4)
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by coalesce(t7.branch_off, t6.branch_off);
commit;

-- 按区域
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '日报'                                                                                 as report_type,
       '区域'                                                                                 as group_type,
       area,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') < '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') < '${v_sdate}', repayment_amt, 0)))  as start_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)   as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                county_name as area
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id

         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3
     on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt = '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') = '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and biz_unguar_dt = '${v_sdate}'
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by area;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '旬报'                                                                                 as report_type,
       '区域'                                                                                 as group_type,
       area,
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                        , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                             date_format('${v_sdate}', '%Y%m20'))
                        )
                   then guar_amt
               else 0 end)
           -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d')
                         < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                         , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                              date_format('${v_sdate}', '%Y%m20'))
                         ), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d')
                         < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                         , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                              date_format('${v_sdate}', '%Y%m20'))
                         ), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                        , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                             date_format('${v_sdate}', '%Y%m20'))
                        )
                   then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                county_name as area
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'),
                  loan_reg_dt between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
             , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'),
                  loan_reg_dt between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                      , loan_reg_dt between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}')
             )
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'),
                  date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                   , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'),
                        date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                      , date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}')
                   )
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'),
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10'),
                  if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'),
                     date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20'),
                     date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}')
             )
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by area;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '月报'                                                                                 as report_type,
       '区域'                                                                                 as group_type,
       area,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01'), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01'), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                county_name as area
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}'
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by area;
commit;
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '季报'                                                                                 as report_type,
       '区域'                                                                                 as group_type,
       area,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d')
                         < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                         , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                                  , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                  , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                  ))), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d')
                         < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                         , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                                  , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                  , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                  ))), repayment_amt, 0)
                   )
           )
                                                                                            as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                county_name as area
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if(quarter('${v_sdate}') = 1, loan_reg_dt between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , if(quarter('${v_sdate}') = 2, loan_reg_dt between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                      ,
                  if(quarter('${v_sdate}') = 3, loan_reg_dt between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 4,
                           loan_reg_dt between date_format('${v_sdate}', '%Y1001') and '${v_sdate}', '')
                      )))
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if(quarter('${v_sdate}') = 1,
                  date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                   , if(quarter('${v_sdate}') = 2,
                        date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 3,
                           date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                            , if(quarter('${v_sdate}') = 4,
                                 date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}',
                                 '')
                            )))
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and if(quarter('${v_sdate}') = 1,
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , if(quarter('${v_sdate}') = 2,
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 3,
                           date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 4,
                           date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}',
                           '')
                      )))
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by area;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '半年报'                                                                                as report_type,
       '区域'                                                                                 as group_type,
       area,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                county_name as area
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'),
                  loan_reg_dt between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , loan_reg_dt between date_format('${v_sdate}', '%Y0701') and '${v_sdate}')
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'),
                  date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                   , date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}')
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'),
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}')
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by area;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '年报'                                                                                 as report_type,
       '区域'                                                                                 as group_type,
       area,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                county_name as area
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and left(loan_reg_dt, 4) = left('${v_sdate}', 4)
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where left(repay_date, 4) = left('${v_sdate}', 4)
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and left(biz_unguar_dt, 4) = left('${v_sdate}', 4)
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by area;
commit;

-- 按银行一级支行
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '日报'                                                                                 as report_type,
       '银行一级支行'                                                                             as group_type,
       loan_bank,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') < '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') < '${v_sdate}', repayment_amt, 0)))  as start_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)   as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id

         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3
     on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt = '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') = '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and biz_unguar_dt = '${v_sdate}'
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by loan_bank;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '旬报'                                                                                 as report_type,
       '银行一级支行'                                                                             as group_type,
       loan_bank,
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                        , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                             date_format('${v_sdate}', '%Y%m20'))
                        )
                   then guar_amt
               else 0 end)
           -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d')
                         < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                         , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                              date_format('${v_sdate}', '%Y%m20'))
                         ), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d')
                         < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                         , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                              date_format('${v_sdate}', '%Y%m20'))
                         ), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                        , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                             date_format('${v_sdate}', '%Y%m20'))
                        )
                   then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'),
                  loan_reg_dt between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
             , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'),
                  loan_reg_dt between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                      , loan_reg_dt between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}')
             )
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'),
                  date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                   , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'),
                        date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                      , date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}')
                   )
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'),
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10'),
                  if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'),
                     date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20'),
                     date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}')
             )
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by loan_bank;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '月报'                                                                                 as report_type,
       '银行一级支行'                                                                             as group_type,
       loan_bank,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01'), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01'), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}'
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by loan_bank;
commit;
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '季报'                                                                                 as report_type,
       '银行一级支行'                                                                             as group_type,
       loan_bank,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d')
                         < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                         , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                                  , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                  , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                  ))), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d')
                         < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                         , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                                  , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                  , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                  ))), repayment_amt, 0)
                   )
           )
                                                                                            as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if(quarter('${v_sdate}') = 1, loan_reg_dt between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , if(quarter('${v_sdate}') = 2, loan_reg_dt between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                      ,
                  if(quarter('${v_sdate}') = 3, loan_reg_dt between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 4,
                           loan_reg_dt between date_format('${v_sdate}', '%Y1001') and '${v_sdate}', '')
                      )))
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if(quarter('${v_sdate}') = 1,
                  date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                   , if(quarter('${v_sdate}') = 2,
                        date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 3,
                           date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                            , if(quarter('${v_sdate}') = 4,
                                 date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}',
                                 '')
                            )))
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and if(quarter('${v_sdate}') = 1,
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , if(quarter('${v_sdate}') = 2,
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 3,
                           date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 4,
                           date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}',
                           '')
                      )))
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by loan_bank;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '半年报'                                                                                as report_type,
       '银行一级支行'                                                                             as group_type,
       loan_bank,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'),
                  loan_reg_dt between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , loan_reg_dt between date_format('${v_sdate}', '%Y0701') and '${v_sdate}')
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'),
                  date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                   , date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}')
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'),
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}')
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by loan_bank;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '年报'                                                                                 as report_type,
       '银行一级支行'                                                                             as group_type,
       loan_bank,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and left(loan_reg_dt, 4) = left('${v_sdate}', 4)
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where left(repay_date, 4) = left('${v_sdate}', 4)
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and left(biz_unguar_dt, 4) = left('${v_sdate}', 4)
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by loan_bank;
commit;

-- 按项目经理
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '日报'                                                                                 as report_type,
       '项目经理'                                                                               as group_type,
       nd_proj_mgr_name,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') < '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') < '${v_sdate}', repayment_amt, 0)))  as start_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)   as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,    -- 业务id
                guar_amt,   -- 放款金额(万元)
                loan_reg_dt -- 放款登记日期
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id

         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3
     on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt = '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') = '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select code,                                -- 项目id
                fk_manager_name as nd_proj_mgr_name, -- 创建者
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main) t1
         where rn = 1
     ) t6 on t1.guar_id = t6.code
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and biz_unguar_dt = '${v_sdate}'
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by nd_proj_mgr_name;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '旬报'                                                                                 as report_type,
       '项目经理'                                                                               as group_type,
       nd_proj_mgr_name,
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                        , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                             date_format('${v_sdate}', '%Y%m20'))
                        )
                   then guar_amt
               else 0 end)
           -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d')
                         < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                         , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                              date_format('${v_sdate}', '%Y%m20'))
                         ), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d')
                         < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                         , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                              date_format('${v_sdate}', '%Y%m20'))
                         ), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'), date_format('${v_sdate}', '%Y%m01')
                        , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'), date_format('${v_sdate}', '%Y%m10'),
                             date_format('${v_sdate}', '%Y%m20'))
                        )
                   then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,    -- 业务id
                guar_amt,   -- 放款金额(万元)
                loan_reg_dt -- 放款登记日期
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'),
                  loan_reg_dt between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
             , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'),
                  loan_reg_dt between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                      , loan_reg_dt between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}')
             )
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'),
                  date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                   , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'),
                        date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                      , date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}')
                   )
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select code,                                -- 项目id
                fk_manager_name as nd_proj_mgr_name, -- 创建者
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main) t1
         where rn = 1
     ) t6 on t1.guar_id = t6.code
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10'),
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10'),
                  if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20'),
                     date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20'),
                     date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}')
             )
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by nd_proj_mgr_name;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '月报'                                                                                 as report_type,
       '项目经理'                                                                               as group_type,
       nd_proj_mgr_name,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01'), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01'), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,    -- 业务id
                guar_amt,   -- 放款金额(万元)
                loan_reg_dt -- 放款登记日期
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select code,                                -- 项目id
                fk_manager_name as nd_proj_mgr_name, -- 创建者
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main) t1
         where rn = 1
     ) t6 on t1.guar_id = t6.code
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}'
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by nd_proj_mgr_name;
commit;
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '季报'                                                                                 as report_type,
       '项目经理'                                                                               as group_type,
       nd_proj_mgr_name,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d')
                         < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                         , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                                  , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                  , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                  ))), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d')
                         < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                         , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                                  , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                  , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                  ))), repayment_amt, 0)
                   )
           )
                                                                                            as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,    -- 业务id
                guar_amt,   -- 放款金额(万元)
                loan_reg_dt -- 放款登记日期
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if(quarter('${v_sdate}') = 1, loan_reg_dt between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , if(quarter('${v_sdate}') = 2, loan_reg_dt between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                      ,
                  if(quarter('${v_sdate}') = 3, loan_reg_dt between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 4,
                           loan_reg_dt between date_format('${v_sdate}', '%Y1001') and '${v_sdate}', '')
                      )))
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if(quarter('${v_sdate}') = 1,
                  date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                   , if(quarter('${v_sdate}') = 2,
                        date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 3,
                           date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                            , if(quarter('${v_sdate}') = 4,
                                 date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}',
                                 '')
                            )))
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select code,                                -- 项目id
                fk_manager_name as nd_proj_mgr_name, -- 创建者
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main) t1
         where rn = 1
     ) t6 on t1.guar_id = t6.code
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and if(quarter('${v_sdate}') = 1,
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , if(quarter('${v_sdate}') = 2,
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 3,
                           date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                      , if(quarter('${v_sdate}') = 4,
                           date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}',
                           '')
                      )))
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by nd_proj_mgr_name;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '半年报'                                                                                as report_type,
       '项目经理'                                                                               as group_type,
       nd_proj_mgr_name,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,    -- 业务id
                guar_amt,   -- 放款金额(万元)
                loan_reg_dt -- 放款登记日期
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'),
                  loan_reg_dt between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , loan_reg_dt between date_format('${v_sdate}', '%Y0701') and '${v_sdate}')
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'),
                  date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                   , date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}')
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select code,                                -- 项目id
                fk_manager_name as nd_proj_mgr_name, -- 创建者
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main) t1
         where rn = 1
     ) t6 on t1.guar_id = t6.code
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'),
                  date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
             , date_format(biz_unguar_dt, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}')
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by nd_proj_mgr_name;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                         as day_id,
       '年报'                                                                                 as report_type,
       '项目经理'                                                                               as group_type,
       nd_proj_mgr_name,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then guar_amt
               else 0 end) -
       sum(
               if(ug_tb.biz_no is not null,
                  if(date_format(biz_unguar_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), t1.guar_amt, 0),
                  if(date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), repayment_amt, 0)
                   )
           )                                                                                as start_balance,
       sum(case
               when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                                                  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                       as now_guar_amt,
       count(t4.guar_id)                                                                    as now_guar_cnt,
       sum(if(now_ug_tb.biz_no is not null, coalesce(t1.guar_amt, 0),
              coalesce(t5.now_repayment_amt, 0)))                                           as now_repayment_amt,
       count(now_ug_tb.biz_no)                                                              as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(if(ug_tb.biz_no is not null, if(date_format(ug_tb.biz_unguar_dt, '%Y%m%d') <= '${v_sdate}', t1.guar_amt, 0),
              if(date_format(repayment_date, '%Y%m%d') <= '${v_sdate}', repayment_amt, 0))) as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)  as end_cnt
from (
         select guar_id,    -- 业务id
                guar_amt,   -- 放款金额(万元)
                loan_reg_dt -- 放款登记日期
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat 
         where 1 = 1
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all_his
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and left(loan_reg_dt, 4) = left('${v_sdate}', 4)
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where left(repay_date, 4) = left('${v_sdate}', 4)
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select code,                                -- 项目id
                fk_manager_name as nd_proj_mgr_name, -- 创建者
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main) t1
         where rn = 1
     ) t6 on t1.guar_id = t6.code
         left join
     (
         select biz_no,       -- 业务编号
                biz_unguar_dt -- 解保日期
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
     ) ug_tb on t1.guar_id = ug_tb.biz_no
         left join
     (
         select biz_no -- 业务编号
         from dw_base.dwd_guar_biz_unguar_info 
         where 1 = 1
           and biz_unguar_reason = '合同解保'
           and left(biz_unguar_dt, 4) = left('${v_sdate}', 4)
     ) now_ug_tb on t1.guar_id = now_ug_tb.biz_no
group by nd_proj_mgr_name;
commit;


-- 新旧业务系统合并
insert into dw_base.ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
       report_type,
       group_type,
       group_name,
       sum(start_balance),
       sum(start_cnt),
       sum(if(now_guar_amt is null, 0, now_guar_amt)),
       sum(now_guar_cnt),
       sum(if(now_repayment_amt is null, 0, now_repayment_amt)),
       sum(now_repayment_cnt),
       sum(end_balance),
       sum(end_cnt)
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
where day_id = '${v_sdate}'
group by report_type, group_type, group_name;
commit;

-- 删掉期末余额为0的项目经理，判定其已不在岗
delete from dw_base.ads_rpt_tjnd_busi_record_stat_loan
where day_id = '${v_sdate}'
  and group_type = '项目经理'
  and end_balance = 0
;
commit;