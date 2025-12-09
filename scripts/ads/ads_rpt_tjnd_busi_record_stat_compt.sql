-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250417
-- 目标表   ：dw_base.ads_rpt_tjnd_busi_record_stat_compt 业务状况-代偿
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_afg_business_infomation                   业务申请表
--          dw_nd.ods_tjnd_yw_base_customers_history                    BO,客户信息历史表,NEW
--          dw_nd.ods_tjnd_yw_base_product_management                   BO,产品管理,NEW
--          dw_nd.ods_tjnd_yw_bh_compensatory                           代偿表
--          dw_nd.ods_tjnd_yw_bh_recovery_tracking                      追偿跟踪表
--          dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail               追偿跟踪详情表
--          新业务系统
--
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 重跑逻辑
delete
from dw_base.ads_rpt_tjnd_busi_record_stat_compt
where day_id = '${v_sdate}';
commit;

-- 创建临时表存储
drop table if exists dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt;
create table dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt
(
    day_id           varchar(8) comment '数据日期',
    report_type      varchar(50) null comment '报表类型',
    group_type       varchar(50) comment '统计类型',
    group_name       varchar(100) comment '分组名称',
    start_balance    decimal(36, 6) comment '期初余额(万元)',
    start_cnt        int comment '期初笔数',
    now_compt_amt    decimal(36, 6) comment '当期代偿金额(万元)',
    now_compt_cnt    int comment '当期代偿笔数',
    now_recovery_amt decimal(36, 6) comment '当期收回金额(万元)',
    now_recovery_cnt int comment '当期收回笔数',
    end_balance      decimal(36, 6) comment '期末余额(万元)',
    end_cnt          int comment '期末笔数'
) comment '临时-业务部-业务状况-代偿' collate = utf8mb4_bin;
commit;

-- 旧数据-分类
drop table if exists dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main;
commit;
create table if not exists dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
(
    id               varchar(20)   comment 'id',
	compt_date       date          comment '代偿日期(取最近一天)',
    compt_amt        decimal(18,6) comment '代偿金额(万元)',
    recovery_date    date          comment '追偿登记日期(取最近一天)',
    recovery_amt     decimal(18,6) comment '追偿金额(万元)',
	
    now_compt_amt_day  decimal(18,6) comment '当期放款金额(万元)（日报）',           
    now_compt_amt_xun  decimal(18,6) comment '当期放款金额(万元)（旬报）',           
    now_compt_amt_mon  decimal(18,6) comment '当期放款金额(万元)（月报）',           
    now_compt_amt_qua  decimal(18,6) comment '当期放款金额(万元)（季报）',           
    now_compt_amt_hyr  decimal(18,6) comment '当期放款金额(万元)（半年报）',         
    now_compt_amt_tyr  decimal(18,6) comment '当期放款金额(万元)（年报）',           
	
    now_compt_cnt_day  int           comment '当期放款笔数（日报）',  
    now_compt_cnt_xun  int           comment '当期放款笔数（旬报）',  
    now_compt_cnt_mon  int           comment '当期放款笔数（月报）',  
    now_compt_cnt_qua  int           comment '当期放款笔数（季报）',  
    now_compt_cnt_hyr  int           comment '当期放款笔数（半年报）',
    now_compt_cnt_tyr  int           comment '当期放款笔数（年报）',  
	
    now_recovery_amt_day  decimal(18,6) comment '当期还款金额(万元)（日报）',  
	now_recovery_amt_xun  decimal(18,6) comment '当期还款金额(万元)（旬报）',  
    now_recovery_amt_mon  decimal(18,6) comment '当期还款金额(万元)（月报）',  	
    now_recovery_amt_qua  decimal(18,6) comment '当期还款金额(万元)（季报）',  	
    now_recovery_amt_hyr  decimal(18,6) comment '当期还款金额(万元)（半年报）',	
    now_recovery_amt_tyr  decimal(18,6) comment '当期还款金额(万元)（年报）',  	  	
					    	
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

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
 select t1.id 		
	   ,t2.compt_date     -- 代偿日期
	   ,t2.compt_amt      -- 代偿金额
	   ,t3.recovery_date  -- 追偿登记日期
	   ,t3.recovery_amt   -- 追偿金额
	   
       ,t4.now_compt_amt_day           --    当期代偿金额 （日报）
	   ,t4.now_compt_amt_xun           --                 （旬报）
	   ,t4.now_compt_amt_mon           --                 （月报）
	   ,t4.now_compt_amt_qua           --                 （季报）
	   ,t4.now_compt_amt_hyr           --                 （半年报）
	   ,t4.now_compt_amt_tyr           --                 （年报）
       ,t4.now_compt_cnt_day           --    当期代偿笔数 （日报）
	   ,t4.now_compt_cnt_xun           --                 （旬报）
	   ,t4.now_compt_cnt_mon           --                 （月报）
	   ,t4.now_compt_cnt_qua           --                 （季报）
	   ,t4.now_compt_cnt_hyr           --                 （半年报）
	   ,t4.now_compt_cnt_tyr           --                 （年报）
	   ,t5.now_recovery_amt_day        --    当期收回金额 （日报）
	   ,t5.now_recovery_amt_xun        --                 （旬报）
	   ,t5.now_recovery_amt_mon        --                 （月报）
	   ,t5.now_recovery_amt_qua        --                 （季报）
	   ,t5.now_recovery_amt_hyr        --                 （半年报）
	   ,t5.now_recovery_amt_tyr        --                 （年报）
	   	   
	   ,t6.bank_name                  as    type1 -- 按银行
	   ,t7.PRODUCT_NAME               as    type2 -- 按产品
	   ,t8.INDUSTRY_CATEGORY_COMPANY  as    type3 -- 按行业归类
	   ,t1.branch_off                 as    type4 -- 按办事处
	   ,case when left(coalesce(t9.area_cd,t11.area_cd),3) = '110' then concat('北京市',coalesce(t9.sup_area_name,t11.sup_area_name),coalesce(t9.area_name,t11.area_name))
	         when left(coalesce(t9.area_cd,t11.area_cd),3) = '130' then concat('河北省',coalesce(t9.sup_area_name,t11.sup_area_name),coalesce(t9.area_name,t11.area_name))
	         else coalesce(t9.area_name,t11.area_name)   
			 end                      as    type5 -- 按区域
	   ,t12.bank_name                 as    type6 -- 按一级支行
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
          where GUR_STATE in ('90','93')     -- [排掉在保的]
		  and guarantee_code not in ('TJRD-2021-5S93-979U','TJRD-2021-5Z85-959X')        -- [这两笔在进件业务]
      ) t1
          left join
      (
          select ID_CFBIZ_UNDERWRITING,                   -- 业务id
                 TOTAL_COMPENSATION         as compt_amt, -- 代偿金额             / 10000
                 PAYMENT_DATE               as compt_date -- 代偿日期
--          from dw_nd.ods_tjnd_yw_bh_compensatory
		  from dw_nd.ods_creditmid_v2_z_migrate_bh_compensatory -- 代偿表
          where status = 1
            and over_tag = 'BJ'
            and DELETED_BY is null
			and CUSTOMER_NAME != '刘志强'
      ) t2 on t1.id = t2.ID_CFBIZ_UNDERWRITING
          left join
      (
          select t1.ID_CFBIZ_UNDERWRITING,                  -- 业务id
                 sum(CUR_RECOVERY)         as recovery_amt, -- 追偿金额          / 10000
                 max(t2.CREATED_TIME)      as recovery_date -- 追偿登记日期
--          from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
		  from dw_nd.ods_creditmid_v2_z_migrate_bh_recovery_tracking t1  -- 追偿跟踪表
--          left join dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail t2  
		  left join dw_nd.ods_creditmid_v2_z_migrate_bh_recovery_tracking_detail t2 	   -- 追偿跟踪详情表
                             on ifnull(t1.id = t2.ID_RECOVERY_TRACKING , t1.RELATED_ITEM_NO = t2.GUARANTEE_CODE) and t1.STATUS = 1 and t2.STATUS = 1
          group by t1.ID_CFBIZ_UNDERWRITING
      ) t3 on t1.id = t3.ID_CFBIZ_UNDERWRITING
          left join
      (                                                                                             --    t4【当期代偿】
          select ID_CFBIZ_UNDERWRITING,                      -- 业务id 当期代偿笔数
                 sum(case when date_format(PAYMENT_DATE, '%Y%m%d') = '${v_sdate}'
				          then TOTAL_COMPENSATION
						  else 0 end
					)                                                                     as now_compt_amt_day -- 当期代偿金额(日报) / 10000
				,sum(case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                     , date_format(PAYMENT_DATE, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                                 , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
				                     , date_format(PAYMENT_DATE, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                     , date_format(PAYMENT_DATE, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
					                 )
                                 )
						  then TOTAL_COMPENSATION
						  else 0 end
					)                                                                     as now_compt_amt_xun -- 当期代偿金额(旬报)
				,sum(case when date_format(PAYMENT_DATE, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}' 
						  then TOTAL_COMPENSATION 
						  else 0 end 
					)                                                                     as now_compt_amt_mon -- 当期代偿金额(月报)
				,sum(case when if(quarter('${v_sdate}') = 1
				                 , date_format(PAYMENT_DATE, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                                 , if(quarter('${v_sdate}') = 2
								     , date_format(PAYMENT_DATE, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                     , if(quarter('${v_sdate}') = 3
									     , date_format(PAYMENT_DATE, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                         , if(quarter('${v_sdate}') = 4
										     , date_format(PAYMENT_DATE, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
										     , ''
											 )
                                         )
									 )
								 )
						  then TOTAL_COMPENSATION 
						  else 0 end				    
					)                                                                     as now_compt_amt_qua -- 当期代偿金额(季报)
				,sum(case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
				                 , date_format(PAYMENT_DATE, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                                 , date_format(PAYMENT_DATE, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
								 )				
						  then TOTAL_COMPENSATION 
						  else 0 end				    
					)                                                                     as now_compt_amt_hyr -- 当期代偿金额(半年报)
				,sum(case when left(date_format(PAYMENT_DATE, '%Y%m%d'), 4) = left('${v_sdate}', 4)
						  then TOTAL_COMPENSATION 
						  else 0 end				    
					)                                                                     as now_compt_amt_tyr -- 当期代偿金额(年报)					
                ,max(case when date_format(PAYMENT_DATE, '%Y%m%d') = '${v_sdate}'
				          then 1
						  else 0 end
					)                                                                     as now_compt_cnt_day -- 当期代偿笔数(日报) 
				,max(case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                     , date_format(PAYMENT_DATE, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                                 , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
				                     , date_format(PAYMENT_DATE, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                     , date_format(PAYMENT_DATE, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
					                 )
                                 )
						  then 1
						  else 0 end
					)                                                                     as now_compt_cnt_xun -- 当期代偿笔数(旬报)
				,max(case when date_format(PAYMENT_DATE, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}' 
						  then 1 
						  else 0 end 
					)                                                                     as now_compt_cnt_mon -- 当期代偿笔数(月报)
				,max(case when if(quarter('${v_sdate}') = 1
				                 , date_format(PAYMENT_DATE, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                                 , if(quarter('${v_sdate}') = 2
								     , date_format(PAYMENT_DATE, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                     , if(quarter('${v_sdate}') = 3
									     , date_format(PAYMENT_DATE, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                         , if(quarter('${v_sdate}') = 4
										     , date_format(PAYMENT_DATE, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
										     , ''
											 )
                                         )
									 )
								 )
						  then 1 
						  else 0 end				    
					)                                                                     as now_compt_cnt_qua -- 当期代偿笔数(季报)
				,max(case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
				                 , date_format(PAYMENT_DATE, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                                 , date_format(PAYMENT_DATE, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
								 )				
						  then 1 
						  else 0 end				    
					)                                                                     as now_compt_cnt_hyr -- 当期代偿笔数(半年报)
				,max(case when left(date_format(PAYMENT_DATE, '%Y%m%d'), 4) = left('${v_sdate}', 4)
						  then 1 
						  else 0 end				    
					)                                                                     as now_compt_cnt_tyr -- 当期代偿笔数(年报)
					
--          from dw_nd.ods_tjnd_yw_bh_compensatory
		  from dw_nd.ods_creditmid_v2_z_migrate_bh_compensatory -- 代偿表
          where status = 1
            and over_tag = 'BJ'
            and DELETED_BY is null
			and CUSTOMER_NAME != '刘志强'
		  group by ID_CFBIZ_UNDERWRITING
      ) t4 on t1.ID = t4.ID_CFBIZ_UNDERWRITING
          left join
      (                                                                                             --    t5 【当期追偿】
          select t1.ID_CFBIZ_UNDERWRITING,                     -- 业务id
                 sum(case when date_format(t2.CREATED_TIME, '%Y%m%d') = '${v_sdate}'
				          then CUR_RECOVERY
						  else 0 end
					)                                                                     as now_recovery_amt_day -- 当期收回金额(日报) / 10000
				,sum(case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                     , date_format(t2.CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                                 , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
				                     , date_format(t2.CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                     , date_format(t2.CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
					                 )
                                 )
						  then CUR_RECOVERY
						  else 0 end
					)                                                                     as now_recovery_amt_xun -- 当期收回金额(旬报)
				,sum(case when date_format(t2.CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}' 
						  then CUR_RECOVERY 
						  else 0 end 
					)                                                                     as now_recovery_amt_mon -- 当期收回金额(月报)
				,sum(case when if(quarter('${v_sdate}') = 1
				                 , date_format(t2.CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                                 , if(quarter('${v_sdate}') = 2
								     , date_format(t2.CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                     , if(quarter('${v_sdate}') = 3
									     , date_format(t2.CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                         , if(quarter('${v_sdate}') = 4
										     , date_format(t2.CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
										     , ''
											 )
                                         )
									 )
								 )
						  then CUR_RECOVERY 
						  else 0 end				    
					)                                                                     as now_recovery_amt_qua -- 当期收回金额(季报)
				,sum(case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
				                 , date_format(t2.CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                                 , date_format(t2.CREATED_TIME, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
								 )				
						  then CUR_RECOVERY 
						  else 0 end				    
					)                                                                     as now_recovery_amt_hyr -- 当期收回金额(半年报)
				,sum(case when left(date_format(t2.CREATED_TIME, '%Y%m%d'), 4) = left('${v_sdate}', 4)
						  then CUR_RECOVERY 
						  else 0 end				    
					)                                                                     as now_recovery_amt_tyr -- 当期收回金额(年报)	
				 
--          from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
		  from dw_nd.ods_creditmid_v2_z_migrate_bh_recovery_tracking t1  -- 追偿跟踪表
--          left join dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail t2  
		  left join dw_nd.ods_creditmid_v2_z_migrate_bh_recovery_tracking_detail t2 	   -- 追偿跟踪详情表
                             on ifnull(t1.id = t2.ID_RECOVERY_TRACKING , t1.RELATED_ITEM_NO = t2.GUARANTEE_CODE)
							 and t1.STATUS = 1 and t2.STATUS = 1
          group by t1.ID_CFBIZ_UNDERWRITING
      ) t5 on t1.ID = t5.ID_CFBIZ_UNDERWRITING
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
          from dw_nd.ods_tjnd_yw_base_enterprise   -- 部门表
          where parentid = 200 and delete_flag = '0'
      ) t6 on t1.COOPERATIVE_BANK_FIRST = t6.fieldcode
          left join
      (
          select fieldcode,   -- 产品编码
                 PRODUCT_NAME -- 产品名称
--          from dw_nd.ods_tjnd_yw_base_product_management
		  from dw_nd.ods_creditmid_v2_z_migrate_base_product_management -- BO,产品管理,NEW
      ) t7 on t1.PRODUCT_GRADE = t7.fieldcode
          left join
      (
          select id,                       -- 客户id
                 INDUSTRY_CATEGORY_COMPANY -- 行业分类（公司）
				 ,JSON_UNQUOTE(JSON_EXTRACT(area, '$[1]'))  as area
--          from dw_nd.ods_tjnd_yw_base_customers_history
		  from dw_nd.ods_creditmid_v2_z_migrate_base_customers_history -- BO,客户信息历史表,NEW
      ) t8 on t1.ID_CUSTOMER = t8.ID
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
	   from dw_base.dim_area_info) t9 on t1.area = t9.area_cd
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
	   from dw_base.dim_area_info) t11 on t8.area = t11.area_cd
	   left join
      (
          select t1.fieldcode,
                 concat(t2.enterfullname, t1.enterfullname) as bank_name
          from dw_nd.ods_tjnd_yw_base_enterprise t1
          left join dw_nd.ods_tjnd_yw_base_enterprise t2 on t1.parentid = t2.enterid and t2.delete_flag = '0'
		  where t1.delete_flag = '0'
      ) t10 on t1.COOPERATIVE_BANK_SECOND = t10.fieldcode
      left join (
	              select dept_id 
				        ,dept_name as bank_name
                  from (select *, row_number() over (partition by dept_id order by update_time desc) as rn from dw_nd.ods_t_sys_dept where del_flag = 0) a  -- 新系统部门表 
                  where rn = 1
				) t12
      on t1.COOPERATIVE_BANK_ID = t12.dept_id	
where coalesce(t9.area_name,t11.area_name) is not null	              -- 区域为空的不统计，老系统已删除
 ;
 commit;
  
-- 旧系统逻辑
 -- 日报
 insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt 
(
 day_id           --   '数据日期',
,report_type      --   '报表类型', (日报、旬报、月报、季报、半年报、年报)
,group_type       --   '统计类型',
,group_name       --   '分组名称',
,start_balance    --   '期初余额(万元)',
,start_cnt        --   '期初笔数',
,now_compt_amt    --   '当期代偿金额(万元)',
,now_compt_cnt    --   '当期代偿笔数',
,now_recovery_amt --   '当期收回金额(万元)',
,now_recovery_cnt --   '当期收回笔数',
,end_balance      --   '期末余额(万元)',
,end_cnt          --   '期末笔数'
)
select '${v_sdate}'          as day_id,
       '日报'                as report_type,
       '银行'                as group_type,
       type1                 as group_name,        
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt else 0 end)   as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)                 as start_cnt,      -- 期初笔数
       sum(now_compt_amt_day)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_day)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_day)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type1             -- '按银行',
union all 
select '${v_sdate}'          as day_id,
       '日报'                as report_type,
       '产品'                as group_type,
       type2                 as group_name,        
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt else 0 end)   as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)                 as start_cnt,      -- 期初笔数
       sum(now_compt_amt_day)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_day)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_day)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
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
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt else 0 end)   as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)                 as start_cnt,      -- 期初笔数
       sum(now_compt_amt_day)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_day)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_day)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
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
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt else 0 end)   as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)                 as start_cnt,      -- 期初笔数
       sum(now_compt_amt_day)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_day)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_day)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type4             -- '按办事处',
union all 
select '${v_sdate}'          as day_id,
       '日报'                as report_type,
       '区域'                as group_type,
       type5                 as group_name,      	   
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt else 0 end)   as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)                 as start_cnt,      -- 期初笔数
       sum(now_compt_amt_day)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_day)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_day)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type5             -- '按区域',
union all 
select '${v_sdate}'          as day_id,
       '日报'                as report_type,
       '银行一级支行'        as group_type,
       type6                 as group_name,      	   
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt else 0 end)   as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)                 as start_cnt,      -- 期初笔数
       sum(now_compt_amt_day)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_day)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_day)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type6             -- '按一级支行',
union all 
select '${v_sdate}'          as day_id,
       '日报'                as report_type,
       '项目经理'            as group_type,
       type7                 as group_name,      	   
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt else 0 end)   as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)                 as start_cnt,      -- 期初笔数
       sum(now_compt_amt_day)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_day)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_day)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type7             -- '按项目经理',
;
commit;

 -- 旬报
 insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt 
(
 day_id           --   '数据日期',
,report_type      --   '报表类型', (日报、旬报、月报、季报、半年报、年报)
,group_type       --   '统计类型',
,group_name       --   '分组名称',
,start_balance    --   '期初余额(万元)',
,start_cnt        --   '期初笔数',
,now_compt_amt    --   '当期代偿金额(万元)',
,now_compt_cnt    --   '当期代偿笔数',
,now_recovery_amt --   '当期收回金额(万元)',
,now_recovery_cnt --   '当期收回笔数',
,end_balance      --   '期末余额(万元)',
,end_cnt          --   '期末笔数'
)
select '${v_sdate}'          as day_id,
       '旬报'                as report_type,
       '银行'                as group_type,
       type1                 as group_name,        
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号	  
	   sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
					 then compt_amt else 0 end) -					 
       sum(case when date_format(recovery_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
	                then recovery_amt else 0 end)                                                        as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 ) 
	                then 1 else 0 end)                                                                   as start_cnt,      -- 期初笔数	   
       sum(now_compt_amt_xun)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_xun)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_xun)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -	   
			  (case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                              , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
			                      , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
			  	                  )
                              )
			  		  then recovery_amt
			  		  else 0 end
			  	 )             
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type1             -- '按银行',
union all 
select '${v_sdate}'          as day_id,
       '旬报'                as report_type,
       '产品'                as group_type,
       type2                 as group_name,        
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号	        
	   sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
					 then compt_amt else 0 end) -					 
       sum(case when date_format(recovery_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
	                then recovery_amt else 0 end)                                                        as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 ) 
	                then 1 else 0 end)                                                                   as start_cnt,      -- 期初笔数	   
       sum(now_compt_amt_xun)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_xun)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_xun)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -	   
			  (case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                              , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
			                      , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
			  	                  )
                              )
			  		  then recovery_amt
			  		  else 0 end
			  	 )             
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
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
	   sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
					 then compt_amt else 0 end) -					 
       sum(case when date_format(recovery_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
	                then recovery_amt else 0 end)                                                        as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 ) 
	                then 1 else 0 end)                                                                   as start_cnt,      -- 期初笔数	   
       sum(now_compt_amt_xun)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_xun)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_xun)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -	   
			  (case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                              , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
			                      , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
			  	                  )
                              )
			  		  then recovery_amt
			  		  else 0 end
			  	 )             
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
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
	   sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
					 then compt_amt else 0 end) -					 
       sum(case when date_format(recovery_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
	                then recovery_amt else 0 end)                                                        as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 ) 
	                then 1 else 0 end)                                                                   as start_cnt,      -- 期初笔数	   
       sum(now_compt_amt_xun)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_xun)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_xun)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -	   
			  (case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                              , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
			                      , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
			  	                  )
                              )
			  		  then recovery_amt
			  		  else 0 end
			  	 )             
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type4             -- '按办事处',
union all 
select '${v_sdate}'          as day_id,
       '旬报'                as report_type,
       '区域'                as group_type,
       type5                 as group_name,      	   
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号	      	   
	   sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
					 then compt_amt else 0 end) -					 
       sum(case when date_format(recovery_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
	                then recovery_amt else 0 end)                                                        as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 ) 
	                then 1 else 0 end)                                                                   as start_cnt,      -- 期初笔数	   
       sum(now_compt_amt_xun)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_xun)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_xun)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -	   
			  (case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                              , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
			                      , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
			  	                  )
                              )
			  		  then recovery_amt
			  		  else 0 end
			  	 )             
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type5             -- '按区域',
union all 
select '${v_sdate}'          as day_id,
       '旬报'                as report_type,
       '银行一级支行'        as group_type,
       type6                 as group_name,      	   
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号      	   
	   sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
					 then compt_amt else 0 end) -					 
       sum(case when date_format(recovery_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
	                then recovery_amt else 0 end)                                                        as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 ) 
	                then 1 else 0 end)                                                                   as start_cnt,      -- 期初笔数	   
       sum(now_compt_amt_xun)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_xun)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_xun)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -	   
			  (case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                              , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
			                      , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
			  	                  )
                              )
			  		  then recovery_amt
			  		  else 0 end
			  	 )             
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type6             -- '按一级支行',
union all 
select '${v_sdate}'          as day_id,
       '旬报'                as report_type,
       '项目经理'            as group_type,
       type7                 as group_name,      	   
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号     	   
	   sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
					 then compt_amt else 0 end) -					 
       sum(case when date_format(recovery_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
	                then recovery_amt else 0 end)                                                        as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 ) 
	                then 1 else 0 end)                                                                   as start_cnt,      -- 期初笔数	   
       sum(now_compt_amt_xun)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_xun)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_xun)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -	   
			  (case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                              , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
			                      , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
			  	                  )
                              )
			  		  then recovery_amt
			  		  else 0 end
			  	 )             
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type7             -- '按项目经理',
;
commit;

 -- 月报
 insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt 
(
 day_id           --   '数据日期',
,report_type      --   '报表类型', (日报、旬报、月报、季报、半年报、年报)
,group_type       --   '统计类型',
,group_name       --   '分组名称',
,start_balance    --   '期初余额(万元)',
,start_cnt        --   '期初笔数',
,now_compt_amt    --   '当期代偿金额(万元)',
,now_compt_cnt    --   '当期代偿笔数',
,now_recovery_amt --   '当期收回金额(万元)',
,now_recovery_cnt --   '当期收回笔数',
,end_balance      --   '期末余额(万元)',
,end_cnt          --   '期末笔数'
)
select '${v_sdate}'          as day_id,
       '月报'                as report_type,
       '银行'                as group_type,
       type1                 as group_name,  
       sum(case when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') 
	            then compt_amt 
				else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01')
	            then recovery_amt 
				else 0 end)                             as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                              as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_mon)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_mon)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_mon)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m01') = date_format('${v_sdate}', '%Y%m01')
	                   then recovery_amt 
	          		else 0 end)              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type1             -- '按银行',
union all 
select '${v_sdate}'          as day_id,
       '月报'                as report_type,
       '产品'                as group_type,
       type2                 as group_name,        
       sum(case when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') 
	            then compt_amt 
				else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01')
	            then recovery_amt 
				else 0 end)                             as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                              as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_mon)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_mon)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_mon)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m01') = date_format('${v_sdate}', '%Y%m01')
	                   then recovery_amt 
	          		else 0 end)              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
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
       sum(case when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') 
	            then compt_amt 
				else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01')
	            then recovery_amt 
				else 0 end)                             as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                              as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_mon)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_mon)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_mon)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m01') = date_format('${v_sdate}', '%Y%m01')
	                   then recovery_amt 
	          		else 0 end)              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
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
       sum(case when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') 
	            then compt_amt 
				else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01')
	            then recovery_amt 
				else 0 end)                             as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                              as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_mon)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_mon)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_mon)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m01') = date_format('${v_sdate}', '%Y%m01')
	                   then recovery_amt 
	          		else 0 end)              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type4             -- '按办事处',
union all 
select '${v_sdate}'          as day_id,
       '月报'                as report_type,
       '区域'                as group_type,
       type5                 as group_name,      	   
       sum(case when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') 
	            then compt_amt 
				else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01')
	            then recovery_amt 
				else 0 end)                             as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                              as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_mon)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_mon)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_mon)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m01') = date_format('${v_sdate}', '%Y%m01')
	                   then recovery_amt 
	          		else 0 end)              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type5             -- '按区域',
union all 
select '${v_sdate}'          as day_id,
       '月报'                as report_type,
       '银行一级支行'        as group_type,
       type6                 as group_name,      	   
       sum(case when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') 
	            then compt_amt 
				else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01')
	            then recovery_amt 
				else 0 end)                             as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                              as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_mon)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_mon)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_mon)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m01') = date_format('${v_sdate}', '%Y%m01')
	                   then recovery_amt 
	          		else 0 end)              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type6             -- '按一级支行',
union all 
select '${v_sdate}'          as day_id,
       '月报'                as report_type,
       '项目经理'            as group_type,
       type7                 as group_name,      	   
       sum(case when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') 
	            then compt_amt 
				else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01')
	            then recovery_amt 
				else 0 end)                             as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                              as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_mon)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_mon)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_mon)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m01') = date_format('${v_sdate}', '%Y%m01')
	                   then recovery_amt 
	          		else 0 end)              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type7             -- '按项目经理',
;
commit;

 -- 季报
 insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt 
(
 day_id           --   '数据日期',
,report_type      --   '报表类型', (日报、旬报、月报、季报、半年报、年报)
,group_type       --   '统计类型',
,group_name       --   '分组名称',
,start_balance    --   '期初余额(万元)',
,start_cnt        --   '期初笔数',
,now_compt_amt    --   '当期代偿金额(万元)',
,now_compt_cnt    --   '当期代偿笔数',
,now_recovery_amt --   '当期收回金额(万元)',
,now_recovery_cnt --   '当期收回笔数',
,end_balance      --   '期末余额(万元)',
,end_cnt          --   '期末笔数'
)
select '${v_sdate}'          as day_id,
       '季报'                as report_type,
       '银行'                as group_type,
       type1                 as group_name,  	   
       sum(case
               when date_format(compt_date, '%Y%m%d')
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
               then compt_amt
               else 0 end) -
       sum(case
               when date_format(recovery_date, '%Y%m%d')
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
               then recovery_amt
               else 0 end)
                                                         as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                              as start_cnt,                -- 期初笔数	       	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if(quarter('${v_sdate}') = 1
		       		          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                              , if(quarter('${v_sdate}') = 2
		       			          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                  , if(quarter('${v_sdate}') = 3
		       				          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                      , if(quarter('${v_sdate}') = 4
		       					          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
		       						      , ''
		       						      )
                                      )
		       					  )
		       				  )
                       then recovery_amt
                       else 0 end)   
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type1             -- '按银行',
union all 
select '${v_sdate}'          as day_id,
       '季报'                as report_type,
       '产品'                as group_type,
       type2                 as group_name,        
       sum(case
               when date_format(compt_date, '%Y%m%d')
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
               then compt_amt
               else 0 end) -
       sum(case
               when date_format(recovery_date, '%Y%m%d')
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
               then recovery_amt
               else 0 end)
                                                         as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                              as start_cnt,                -- 期初笔数	       	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if(quarter('${v_sdate}') = 1
		       		          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                              , if(quarter('${v_sdate}') = 2
		       			          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                  , if(quarter('${v_sdate}') = 3
		       				          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                      , if(quarter('${v_sdate}') = 4
		       					          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
		       						      , ''
		       						      )
                                      )
		       					  )
		       				  )
                       then recovery_amt
                       else 0 end)   
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
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
               when date_format(compt_date, '%Y%m%d')
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
               then compt_amt
               else 0 end) -
       sum(case
               when date_format(recovery_date, '%Y%m%d')
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
               then recovery_amt
               else 0 end)
                                                         as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                              as start_cnt,                -- 期初笔数	       	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if(quarter('${v_sdate}') = 1
		       		          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                              , if(quarter('${v_sdate}') = 2
		       			          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                  , if(quarter('${v_sdate}') = 3
		       				          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                      , if(quarter('${v_sdate}') = 4
		       					          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
		       						      , ''
		       						      )
                                      )
		       					  )
		       				  )
                       then recovery_amt
                       else 0 end)   
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
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
               when date_format(compt_date, '%Y%m%d')
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
               then compt_amt
               else 0 end) -
       sum(case
               when date_format(recovery_date, '%Y%m%d')
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
               then recovery_amt
               else 0 end)
                                                         as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                              as start_cnt,                -- 期初笔数	       	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if(quarter('${v_sdate}') = 1
		       		          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                              , if(quarter('${v_sdate}') = 2
		       			          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                  , if(quarter('${v_sdate}') = 3
		       				          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                      , if(quarter('${v_sdate}') = 4
		       					          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
		       						      , ''
		       						      )
                                      )
		       					  )
		       				  )
                       then recovery_amt
                       else 0 end)   
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type4             -- '按办事处',
union all 
select '${v_sdate}'          as day_id,
       '季报'                as report_type,
       '区域'                as group_type,
       type5                 as group_name,      	   
       sum(case
               when date_format(compt_date, '%Y%m%d')
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
               then compt_amt
               else 0 end) -
       sum(case
               when date_format(recovery_date, '%Y%m%d')
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
               then recovery_amt
               else 0 end)
                                                         as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                              as start_cnt,                -- 期初笔数	       	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if(quarter('${v_sdate}') = 1
		       		          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                              , if(quarter('${v_sdate}') = 2
		       			          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                  , if(quarter('${v_sdate}') = 3
		       				          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                      , if(quarter('${v_sdate}') = 4
		       					          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
		       						      , ''
		       						      )
                                      )
		       					  )
		       				  )
                       then recovery_amt
                       else 0 end)   
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type5             -- '按区域',
union all 
select '${v_sdate}'          as day_id,
       '季报'                as report_type,
       '银行一级支行'        as group_type,
       type6                 as group_name,      	   
       sum(case
               when date_format(compt_date, '%Y%m%d')
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
               then compt_amt
               else 0 end) -
       sum(case
               when date_format(recovery_date, '%Y%m%d')
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
               then recovery_amt
               else 0 end)
                                                         as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                              as start_cnt,                -- 期初笔数	       	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if(quarter('${v_sdate}') = 1
		       		          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                              , if(quarter('${v_sdate}') = 2
		       			          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                  , if(quarter('${v_sdate}') = 3
		       				          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                      , if(quarter('${v_sdate}') = 4
		       					          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
		       						      , ''
		       						      )
                                      )
		       					  )
		       				  )
                       then recovery_amt
                       else 0 end)   
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type6             -- '按一级支行',
union all 
select '${v_sdate}'          as day_id,
       '季报'                as report_type,
       '项目经理'            as group_type,
       type7                 as group_name,      	   
       sum(case
               when date_format(compt_date, '%Y%m%d')
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
               then compt_amt
               else 0 end) -
       sum(case
               when date_format(recovery_date, '%Y%m%d')
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
               then recovery_amt
               else 0 end)
                                                         as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                              as start_cnt,                -- 期初笔数	       	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if(quarter('${v_sdate}') = 1
		       		          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                              , if(quarter('${v_sdate}') = 2
		       			          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                  , if(quarter('${v_sdate}') = 3
		       				          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                      , if(quarter('${v_sdate}') = 4
		       					          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
		       						      , ''
		       						      )
                                      )
		       					  )
		       				  )
                       then recovery_amt
                       else 0 end)   
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type7             -- '按项目经理',
;
commit;

 -- 半年报
 insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt 
(
 day_id           --   '数据日期',
,report_type      --   '报表类型', (日报、旬报、月报、季报、半年报、年报)
,group_type       --   '统计类型',
,group_name       --   '分组名称',
,start_balance    --   '期初余额(万元)',
,start_cnt        --   '期初笔数',
,now_compt_amt    --   '当期代偿金额(万元)',
,now_compt_cnt    --   '当期代偿笔数',
,now_recovery_amt --   '当期收回金额(万元)',
,now_recovery_cnt --   '当期收回笔数',
,end_balance      --   '期末余额(万元)',
,end_cnt          --   '期末笔数'
)
select '${v_sdate}'          as day_id,
       '半年报'                as report_type,
       '银行'                as group_type,
       type1                 as group_name,  
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), recovery_amt, 0)
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
			                  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
							  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
							  )
			           then recovery_amt
					   else 0 end
				 )              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type1             -- '按银行',
union all 
select '${v_sdate}'          as day_id,
       '半年报'                as report_type,
       '产品'                as group_type,
       type2                 as group_name,        
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), recovery_amt, 0)
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
			                  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
							  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
							  )
			           then recovery_amt
					   else 0 end
				 )              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
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
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), recovery_amt, 0)
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
			                  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
							  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
							  )
			           then recovery_amt
					   else 0 end
				 )              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
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
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), recovery_amt, 0)
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
			                  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
							  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
							  )
			           then recovery_amt
					   else 0 end
				 )              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type4             -- '按办事处',
union all 
select '${v_sdate}'          as day_id,
       '半年报'                as report_type,
       '区域'                as group_type,
       type5                 as group_name,      	   
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), recovery_amt, 0)
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
			                  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
							  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
							  )
			           then recovery_amt
					   else 0 end
				 )              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type5             -- '按区域',
union all 
select '${v_sdate}'          as day_id,
       '半年报'                as report_type,
       '银行一级支行'        as group_type,
       type6                 as group_name,      	   
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), recovery_amt, 0)
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
			                  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
							  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
							  )
			           then recovery_amt
					   else 0 end
				 )              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type6             -- '按一级支行',
union all 
select '${v_sdate}'          as day_id,
       '半年报'                as report_type,
       '项目经理'            as group_type,
       type7                 as group_name,      	   
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), recovery_amt, 0)
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
			                  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
							  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
							  )
			           then recovery_amt
					   else 0 end
				 )              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type7             -- '按项目经理',
;
commit;

  -- 年报
 insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt 
(
 day_id           --   '数据日期',
,report_type      --   '报表类型', (日报、旬报、月报、季报、半年报、年报)
,group_type       --   '统计类型',
,group_name       --   '分组名称',
,start_balance    --   '期初余额(万元)',
,start_cnt        --   '期初笔数',
,now_compt_amt    --   '当期代偿金额(万元)',
,now_compt_cnt    --   '当期代偿笔数',
,now_recovery_amt --   '当期收回金额(万元)',
,now_recovery_cnt --   '当期收回笔数',
,end_balance      --   '期末余额(万元)',
,end_cnt          --   '期末笔数'
)
select '${v_sdate}'          as day_id,
       '年报'                as report_type,
       '银行'                as group_type,
       type1                 as group_name,  
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)   
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数          	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (
                         if(date_format(recovery_date, '%Y0101') = date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)   
                  )               
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type1             -- '按银行',
union all 
select '${v_sdate}'          as day_id,
       '年报'                as report_type,
       '产品'                as group_type,
       type2                 as group_name,        
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)   
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数          	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (
                         if(date_format(recovery_date, '%Y0101') = date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)   
                  )               
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
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
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)   
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数          	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (
                         if(date_format(recovery_date, '%Y0101') = date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)  
                  )               
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
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
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)   
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数          	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (
                         if(date_format(recovery_date, '%Y0101') = date_format('${v_sdate}', '%Y0101'), recovery_amt, 0) 
                  )               
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type4             -- '按办事处',
union all 
select '${v_sdate}'          as day_id,
       '年报'                as report_type,
       '区域'                as group_type,
       type5                 as group_name,      	   
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)   
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数          	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (
                         if(date_format(recovery_date, '%Y0101') = date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)  
                  )               
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type5             -- '按区域',
union all 
select '${v_sdate}'          as day_id,
       '年报'                as report_type,
       '银行一级支行'        as group_type,
       type6                 as group_name,      	   
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)   
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数          	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (
                         if(date_format(recovery_date, '%Y0101') = date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)  
                  )               
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type6             -- '按一级支行',
union all 
select '${v_sdate}'          as day_id,
       '年报'                as report_type,
       '项目经理'            as group_type,
       type7                 as group_name,      	   
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)   
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数          	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (
                         if(date_format(recovery_date, '%Y0101') = date_format('${v_sdate}', '%Y0101'), recovery_amt, 0) 
                  )               
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_old_data_main
group by type7             -- '按项目经理',
;
commit;

-- 新数据-分类
drop table if exists dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main;
commit;
create table if not exists dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
(
    id               varchar(20)   comment 'id',
	compt_date       date          comment '代偿日期(取最近一天)',
    compt_amt        decimal(18,6) comment '代偿金额(万元)',
    recovery_date    date          comment '追偿登记日期(取最近一天)',
    recovery_amt     decimal(18,6) comment '追偿金额(万元)',
	
    now_compt_amt_day  decimal(18,6) comment '当期放款金额(万元)（日报）',           
    now_compt_amt_xun  decimal(18,6) comment '当期放款金额(万元)（旬报）',           
    now_compt_amt_mon  decimal(18,6) comment '当期放款金额(万元)（月报）',           
    now_compt_amt_qua  decimal(18,6) comment '当期放款金额(万元)（季报）',           
    now_compt_amt_hyr  decimal(18,6) comment '当期放款金额(万元)（半年报）',         
    now_compt_amt_tyr  decimal(18,6) comment '当期放款金额(万元)（年报）',           
	
    now_compt_cnt_day  int           comment '当期放款笔数（日报）',  
    now_compt_cnt_xun  int           comment '当期放款笔数（旬报）',  
    now_compt_cnt_mon  int           comment '当期放款笔数（月报）',  
    now_compt_cnt_qua  int           comment '当期放款笔数（季报）',  
    now_compt_cnt_hyr  int           comment '当期放款笔数（半年报）',
    now_compt_cnt_tyr  int           comment '当期放款笔数（年报）',  
	
    now_recovery_amt_day  decimal(18,6) comment '当期还款金额(万元)（日报）',  
	now_recovery_amt_xun  decimal(18,6) comment '当期还款金额(万元)（旬报）',  
    now_recovery_amt_mon  decimal(18,6) comment '当期还款金额(万元)（月报）',  	
    now_recovery_amt_qua  decimal(18,6) comment '当期还款金额(万元)（季报）',  	
    now_recovery_amt_hyr  decimal(18,6) comment '当期还款金额(万元)（半年报）',	
    now_recovery_amt_tyr  decimal(18,6) comment '当期还款金额(万元)（年报）',  	  	
					    	
    type1             varchar(50)   comment '按银行',
    type2             varchar(50)   comment '按产品',
    type3             varchar(50)   comment '按行业归类',
    type4             varchar(50)   comment '按办事处',
	type5             varchar(50)	comment '按区域',					   
	type6             varchar(50)	comment '按一级支行',					   
	type7             varchar(50)	comment '按项目经理核算'				   													   
)  ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC
 comment '临时-业务部-业务状况-新系统-日报-分类表';
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
 select t1.guar_id as id 		
	   ,t3.compt_date     -- 代偿日期
	   ,t3.compt_amt      -- 代偿金额
	   ,t4.recovery_date  -- 追偿登记日期
	   ,t4.recovery_amt   -- 追偿金额
	   
       ,t5.now_compt_amt_day           --    当期代偿金额 （日报）
	   ,t5.now_compt_amt_xun           --                 （旬报）
	   ,t5.now_compt_amt_mon           --                 （月报）
	   ,t5.now_compt_amt_qua           --                 （季报）
	   ,t5.now_compt_amt_hyr           --                 （半年报）
	   ,t5.now_compt_amt_tyr           --                 （年报）
       ,t5.now_compt_cnt_day           --    当期代偿笔数 （日报）
	   ,t5.now_compt_cnt_xun           --                 （旬报）
	   ,t5.now_compt_cnt_mon           --                 （月报）
	   ,t5.now_compt_cnt_qua           --                 （季报）
	   ,t5.now_compt_cnt_hyr           --                 （半年报）
	   ,t5.now_compt_cnt_tyr           --                 （年报）
	   ,t6.now_recovery_amt_day        --    当期收回金额 （日报）
	   ,t6.now_recovery_amt_xun        --                 （旬报）
	   ,t6.now_recovery_amt_mon        --                 （月报）
	   ,t6.now_recovery_amt_qua        --                 （季报）
	   ,t6.now_recovery_amt_hyr        --                 （半年报）
	   ,t6.now_recovery_amt_tyr        --                 （年报）
	   	   
	   ,t7.gnd_dept_name                  as    type1 -- 按银行
	   ,coalesce(t9.product_type,t12.PRODUCT_NAME)                   as    type2 -- 按产品
	   ,t1.guar_class                     as    type3 -- 按行业归类
	   ,t10.branch_off                    as    type4 -- 按办事处
	   ,t1.area                           as    type5 -- 按区域
	   ,t1.loan_bank                      as    type6 -- 按一级支行
	   ,t11.nd_proj_mgr_name              as    type7 -- 按项目经理核算	   
from (
         select guar_id -- 业务id
		       ,guar_class -- 国担分类
			   ,country_code as area_code -- 区县编码
			   ,county_name as area -- 区县
               ,loan_bank -- 贷款银行
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
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select guar_id,
                compt_amt  as compt_amt, -- 代偿金额
                compt_time as compt_date -- 代偿拨付日期
         from dw_base.dwd_guar_compt_info
     ) t3 on t1.guar_id = t3.guar_id
         left join
     (
         select t1.project_id,
                sum(t2.shou_comp_amt) / 10000 as recovery_amt, -- 追偿金额
                max(real_repay_date)          as recovery_date -- 追偿实际还款时间
         from dw_nd.ods_t_biz_proj_recovery_record t1
                  left join dw_nd.ods_t_biz_proj_recovery_repay_detail_record t2 on t1.reco_id = t2.record_id
         group by project_id
     ) t4 on t2.project_id = t4.project_id
         left join
     (                                                                                              -- t5【当期代偿金额】
         select guar_id,                   -- 当期代偿笔数
                 sum(case when date_format(compt_time, '%Y%m%d') = '${v_sdate}'
				          then compt_amt
						  else 0 end
					)                                                                     as now_compt_amt_day -- 当期代偿金额(日报) / 10000
				,sum(case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                     , date_format(compt_time, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                                 , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
				                     , date_format(compt_time, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                     , date_format(compt_time, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
					                 )
                                 )
						  then compt_amt
						  else 0 end
					)                                                                     as now_compt_amt_xun -- 当期代偿金额(旬报)
				,sum(case when date_format(compt_time, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}' 
						  then compt_amt 
						  else 0 end 
					)                                                                     as now_compt_amt_mon -- 当期代偿金额(月报)
				,sum(case when if(quarter('${v_sdate}') = 1
				                 , date_format(compt_time, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                                 , if(quarter('${v_sdate}') = 2
								     , date_format(compt_time, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                     , if(quarter('${v_sdate}') = 3
									     , date_format(compt_time, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                         , if(quarter('${v_sdate}') = 4
										     , date_format(compt_time, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
										     , ''
											 )
                                         )
									 )
								 )
						  then compt_amt 
						  else 0 end				    
					)                                                                     as now_compt_amt_qua -- 当期代偿金额(季报)
				,sum(case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
				                 , date_format(compt_time, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                                 , date_format(compt_time, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
								 )				
						  then compt_amt 
						  else 0 end				    
					)                                                                     as now_compt_amt_hyr -- 当期代偿金额(半年报)
				,sum(case when left(date_format(compt_time, '%Y%m%d'), 4) = left('${v_sdate}', 4)
						  then compt_amt 
						  else 0 end				    
					)                                                                     as now_compt_amt_tyr -- 当期代偿金额(年报)					
                ,max(case when date_format(compt_time, '%Y%m%d') = '${v_sdate}'
				          then 1
						  else 0 end
					)                                                                     as now_compt_cnt_day -- 当期代偿笔数(日报) 
				,max(case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                     , date_format(compt_time, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                                 , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
				                     , date_format(compt_time, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                     , date_format(compt_time, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
					                 )
                                 )
						  then 1
						  else 0 end
					)                                                                     as now_compt_cnt_xun -- 当期代偿笔数(旬报)
				,max(case when date_format(compt_time, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}' 
						  then 1 
						  else 0 end 
					)                                                                     as now_compt_cnt_mon -- 当期代偿笔数(月报)
				,max(case when if(quarter('${v_sdate}') = 1
				                 , date_format(compt_time, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                                 , if(quarter('${v_sdate}') = 2
								     , date_format(compt_time, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                     , if(quarter('${v_sdate}') = 3
									     , date_format(compt_time, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                         , if(quarter('${v_sdate}') = 4
										     , date_format(compt_time, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
										     , ''
											 )
                                         )
									 )
								 )
						  then 1 
						  else 0 end				    
					)                                                                     as now_compt_cnt_qua -- 当期代偿笔数(季报)
				,max(case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
				                 , date_format(compt_time, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                                 , date_format(compt_time, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
								 )				
						  then 1 
						  else 0 end				    
					)                                                                     as now_compt_cnt_hyr -- 当期代偿笔数(半年报)
				,max(case when left(date_format(compt_time, '%Y%m%d'), 4) = left('${v_sdate}', 4)
						  then 1 
						  else 0 end				    
					)                                                                     as now_compt_cnt_tyr -- 当期代偿笔数(年报)								
         from dw_base.dwd_guar_compt_info
		 group by project_id
     ) t5 on t1.guar_id = t5.guar_id
         left join
     (                                                                                              -- t6【当期追偿金额】
         select t1.project_id,		 
                 sum(case when date_format(real_repay_date, '%Y%m%d') = '${v_sdate}'
				          then t2.shou_comp_amt / 10000
						  else 0 end
					)                                                                     as now_recovery_amt_day -- 当期收回金额(日报) / 10000
				,sum(case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                     , date_format(real_repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                                 , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
				                     , date_format(real_repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                     , date_format(real_repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
					                 )
                                 )
						  then t2.shou_comp_amt / 10000
						  else 0 end
					)                                                                     as now_recovery_amt_xun -- 当期收回金额(旬报)
				,sum(case when date_format(real_repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and '${v_sdate}' 
						  then t2.shou_comp_amt / 10000 
						  else 0 end 
					)                                                                     as now_recovery_amt_mon -- 当期收回金额(月报)
				,sum(case when if(quarter('${v_sdate}') = 1
				                 , date_format(real_repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                                 , if(quarter('${v_sdate}') = 2
								     , date_format(real_repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                     , if(quarter('${v_sdate}') = 3
									     , date_format(real_repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                         , if(quarter('${v_sdate}') = 4
										     , date_format(real_repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
										     , ''
											 )
                                         )
									 )
								 )
						  then t2.shou_comp_amt / 10000 
						  else 0 end				    
					)                                                                     as now_recovery_amt_qua -- 当期收回金额(季报)
				,sum(case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
				                 , date_format(real_repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                                 , date_format(real_repay_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
								 )				
						  then t2.shou_comp_amt / 10000 
						  else 0 end				    
					)                                                                     as now_recovery_amt_hyr -- 当期收回金额(半年报)
				,sum(case when left(date_format(real_repay_date, '%Y%m%d'), 4) = left('${v_sdate}', 4)
						  then t2.shou_comp_amt / 10000 
						  else 0 end				    
					)                                                                     as now_recovery_amt_tyr -- 当期收回金额(年报)			 
         from dw_nd.ods_t_biz_proj_recovery_record t1
                  left join dw_nd.ods_t_biz_proj_recovery_repay_detail_record t2 on t1.reco_id = t2.record_id
         group by project_id
     ) t6 on t2.project_id = t6.project_id
         left join
     (
         select biz_no,
                gnd_dept_name
         from dw_base.dwd_tjnd_report_biz_loan_bank
         where day_id = '${v_sdate}'
     ) t7 on t1.guar_id = t7.biz_no
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
     ) t8 on t2.project_id = t8.project_id
         left join
     (
         select code, value as product_type
         from (
                  select *, row_number() over (partition by id order by update_time desc) as rn
                  from dw_nd.ods_t_sys_data_dict_value_v2
                  where dict_code = 'aggregateScheme'
              ) t1
         where rn = 1
     ) t9 on t8.aggregate_scheme = t9.code
         left join
     (
         select CITY_CODE_,              -- 区县编码
                ROLE_CODE_ as branch_off -- 办事处编码
         from dw_base.dwd_imp_area_branch
     ) t10 on t1.area_code = t10.CITY_CODE_
         left join
     (
         select code,                            -- 项目id
                fk_manager_name as nd_proj_mgr_name, -- 创建者
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main) t1
         where rn = 1
     ) t11 on t1.guar_id = t11.code
	 left join 
	 (                                                    -- 【在保转进件项目产品名称】
	   select a.GUARANTEE_CODE, -- 业务编码
		      b.fieldcode,   -- 产品编码
              b.PRODUCT_NAME -- 产品名称
       from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation a -- 业务申请表
	   left join dw_nd.ods_creditmid_v2_z_migrate_base_product_management b -- BO,产品管理,NEW
	   on a.PRODUCT_GRADE = b.fieldcode
	 ) t12 on t1.guar_id = t12.GUARANTEE_CODE
;
commit;


-- 旧系统逻辑
 -- 日报
 insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt 
(
 day_id           --   '数据日期',
,report_type      --   '报表类型', (日报、旬报、月报、季报、半年报、年报)
,group_type       --   '统计类型',
,group_name       --   '分组名称',
,start_balance    --   '期初余额(万元)',
,start_cnt        --   '期初笔数',
,now_compt_amt    --   '当期代偿金额(万元)',
,now_compt_cnt    --   '当期代偿笔数',
,now_recovery_amt --   '当期收回金额(万元)',
,now_recovery_cnt --   '当期收回笔数',
,end_balance      --   '期末余额(万元)',
,end_cnt          --   '期末笔数'
)
select '${v_sdate}'          as day_id,
       '日报'                as report_type,
       '银行'                as group_type,
       type1                 as group_name,        
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt else 0 end)   as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)                 as start_cnt,      -- 期初笔数
       sum(now_compt_amt_day)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_day)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_day)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type1             -- '按银行',
union all 
select '${v_sdate}'          as day_id,
       '日报'                as report_type,
       '产品'                as group_type,
       type2                 as group_name,        
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt else 0 end)   as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)                 as start_cnt,      -- 期初笔数
       sum(now_compt_amt_day)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_day)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_day)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type2             -- '按产品',
union all 
select '${v_sdate}'          as day_id,
       '日报'                as report_type,
       '行业归类'                as group_type,
       type3                    as group_name,      	   
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt else 0 end)   as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)                 as start_cnt,      -- 期初笔数
       sum(now_compt_amt_day)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_day)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_day)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type3             -- '行业归类',
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
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt else 0 end)   as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)                 as start_cnt,      -- 期初笔数
       sum(now_compt_amt_day)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_day)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_day)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type4             -- '按办事处',
union all 
select '${v_sdate}'          as day_id,
       '日报'                as report_type,
       '区域'                as group_type,
       type5                 as group_name,      	   
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt else 0 end)   as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)                 as start_cnt,      -- 期初笔数
       sum(now_compt_amt_day)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_day)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_day)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type5             -- '按区域',
union all 
select '${v_sdate}'          as day_id,
       '日报'                as report_type,
       '银行一级支行'        as group_type,
       type6                 as group_name,      	   
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt else 0 end)   as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)                 as start_cnt,      -- 期初笔数
       sum(now_compt_amt_day)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_day)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_day)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type6             -- '按一级支行',
union all 
select '${v_sdate}'          as day_id,
       '日报'                as report_type,
       '项目经理'            as group_type,
       type7                 as group_name,      	   
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt else 0 end)   as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)                 as start_cnt,      -- 期初笔数
       sum(now_compt_amt_day)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_day)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_day)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type7             -- '按项目经理',
;
commit;

 -- 旬报
 insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt 
(
 day_id           --   '数据日期',
,report_type      --   '报表类型', (日报、旬报、月报、季报、半年报、年报)
,group_type       --   '统计类型',
,group_name       --   '分组名称',
,start_balance    --   '期初余额(万元)',
,start_cnt        --   '期初笔数',
,now_compt_amt    --   '当期代偿金额(万元)',
,now_compt_cnt    --   '当期代偿笔数',
,now_recovery_amt --   '当期收回金额(万元)',
,now_recovery_cnt --   '当期收回笔数',
,end_balance      --   '期末余额(万元)',
,end_cnt          --   '期末笔数'
)
select '${v_sdate}'          as day_id,
       '旬报'                as report_type,
       '银行'                as group_type,
       type1                 as group_name,        
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号	  
	   sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
					 then compt_amt else 0 end) -					 
       sum(case when date_format(recovery_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
	                then recovery_amt else 0 end)                                                        as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 ) 
	                then 1 else 0 end)                                                                   as start_cnt,      -- 期初笔数	   
       sum(now_compt_amt_xun)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_xun)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_xun)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -	   
			  (case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                              , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
			                      , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
			  	                  )
                              )
			  		  then recovery_amt
			  		  else 0 end
			  	 )             
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type1             -- '按银行',
union all 
select '${v_sdate}'          as day_id,
       '旬报'                as report_type,
       '产品'                as group_type,
       type2                 as group_name,        
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号	        
	   sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
					 then compt_amt else 0 end) -					 
       sum(case when date_format(recovery_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
	                then recovery_amt else 0 end)                                                        as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 ) 
	                then 1 else 0 end)                                                                   as start_cnt,      -- 期初笔数	   
       sum(now_compt_amt_xun)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_xun)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_xun)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -	   
			  (case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                              , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
			                      , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
			  	                  )
                              )
			  		  then recovery_amt
			  		  else 0 end
			  	 )             
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type2             -- '按产品',
union all 
select '${v_sdate}'          as day_id,
       '旬报'                as report_type,
       '行业归类'                as group_type,
       type3                    as group_name,      	   
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号	       	   
	   sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
					 then compt_amt else 0 end) -					 
       sum(case when date_format(recovery_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
	                then recovery_amt else 0 end)                                                        as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 ) 
	                then 1 else 0 end)                                                                   as start_cnt,      -- 期初笔数	   
       sum(now_compt_amt_xun)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_xun)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_xun)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -	   
			  (case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                              , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
			                      , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
			  	                  )
                              )
			  		  then recovery_amt
			  		  else 0 end
			  	 )             
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type3             -- '行业归类',
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
	   sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
					 then compt_amt else 0 end) -					 
       sum(case when date_format(recovery_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
	                then recovery_amt else 0 end)                                                        as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 ) 
	                then 1 else 0 end)                                                                   as start_cnt,      -- 期初笔数	   
       sum(now_compt_amt_xun)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_xun)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_xun)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -	   
			  (case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                              , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
			                      , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
			  	                  )
                              )
			  		  then recovery_amt
			  		  else 0 end
			  	 )             
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type4             -- '按办事处',
union all 
select '${v_sdate}'          as day_id,
       '旬报'                as report_type,
       '区域'                as group_type,
       type5                 as group_name,      	   
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号	      	   
	   sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
					 then compt_amt else 0 end) -					 
       sum(case when date_format(recovery_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
	                then recovery_amt else 0 end)                                                        as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 ) 
	                then 1 else 0 end)                                                                   as start_cnt,      -- 期初笔数	   
       sum(now_compt_amt_xun)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_xun)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_xun)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -	   
			  (case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                              , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
			                      , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
			  	                  )
                              )
			  		  then recovery_amt
			  		  else 0 end
			  	 )             
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type5             -- '按区域',
union all 
select '${v_sdate}'          as day_id,
       '旬报'                as report_type,
       '银行一级支行'        as group_type,
       type6                 as group_name,      	   
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号      	   
	   sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
					 then compt_amt else 0 end) -					 
       sum(case when date_format(recovery_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
	                then recovery_amt else 0 end)                                                        as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 ) 
	                then 1 else 0 end)                                                                   as start_cnt,      -- 期初笔数	   
       sum(now_compt_amt_xun)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_xun)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_xun)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -	   
			  (case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                              , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
			                      , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
			  	                  )
                              )
			  		  then recovery_amt
			  		  else 0 end
			  	 )             
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type6             -- '按一级支行',
union all 
select '${v_sdate}'          as day_id,
       '旬报'                as report_type,
       '项目经理'            as group_type,
       type7                 as group_name,      	   
       -- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号     	   
	   sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
					 then compt_amt else 0 end) -					 
       sum(case when date_format(recovery_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 )
	                then recovery_amt else 0 end)                                                        as start_balance,  -- 期初余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') 
	                 < if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
					     , date_format('${v_sdate}', '%Y%m01') 
					     , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
						      , date_format('${v_sdate}', '%Y%m10')
						      , date_format('${v_sdate}', '%Y%m20')
							 )
						 ) 
	                then 1 else 0 end)                                                                   as start_cnt,      -- 期初笔数	   
       sum(now_compt_amt_xun)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_xun)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_xun)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -	   
			  (case when if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m10')
			                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m01') and date_format('${v_sdate}', '%Y%m10')
                              , if('${v_sdate}' <= date_format('${v_sdate}', '%Y%m20')
			                      , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m10') and date_format('${v_sdate}', '%Y%m20')
                                  , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y%m20') and '${v_sdate}'
			  	                  )
                              )
			  		  then recovery_amt
			  		  else 0 end
			  	 )             
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type7             -- '按项目经理',
;
commit;

 -- 月报
 insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt 
(
 day_id           --   '数据日期',
,report_type      --   '报表类型', (日报、旬报、月报、季报、半年报、年报)
,group_type       --   '统计类型',
,group_name       --   '分组名称',
,start_balance    --   '期初余额(万元)',
,start_cnt        --   '期初笔数',
,now_compt_amt    --   '当期代偿金额(万元)',
,now_compt_cnt    --   '当期代偿笔数',
,now_recovery_amt --   '当期收回金额(万元)',
,now_recovery_cnt --   '当期收回笔数',
,end_balance      --   '期末余额(万元)',
,end_cnt          --   '期末笔数'
)
select '${v_sdate}'          as day_id,
       '月报'                as report_type,
       '银行'                as group_type,
       type1                 as group_name,  
       sum(case when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') 
	            then compt_amt 
				else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01')
	            then recovery_amt 
				else 0 end)                             as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                              as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_mon)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_mon)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_mon)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m01') = date_format('${v_sdate}', '%Y%m01')
	                   then recovery_amt 
	          		else 0 end)              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type1             -- '按银行',
union all 
select '${v_sdate}'          as day_id,
       '月报'                as report_type,
       '产品'                as group_type,
       type2                 as group_name,        
       sum(case when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') 
	            then compt_amt 
				else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01')
	            then recovery_amt 
				else 0 end)                             as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                              as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_mon)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_mon)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_mon)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m01') = date_format('${v_sdate}', '%Y%m01')
	                   then recovery_amt 
	          		else 0 end)              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type2             -- '按产品',
union all 
select '${v_sdate}'          as day_id,
       '月报'                as report_type,
       '行业归类'                as group_type,
       type3                    as group_name,      	   
       sum(case when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') 
	            then compt_amt 
				else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01')
	            then recovery_amt 
				else 0 end)                             as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                              as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_mon)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_mon)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_mon)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m01') = date_format('${v_sdate}', '%Y%m01')
	                   then recovery_amt 
	          		else 0 end)              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type3             -- '行业归类',
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
       sum(case when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') 
	            then compt_amt 
				else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01')
	            then recovery_amt 
				else 0 end)                             as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                              as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_mon)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_mon)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_mon)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m01') = date_format('${v_sdate}', '%Y%m01')
	                   then recovery_amt 
	          		else 0 end)              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type4             -- '按办事处',
union all 
select '${v_sdate}'          as day_id,
       '月报'                as report_type,
       '区域'                as group_type,
       type5                 as group_name,      	   
       sum(case when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') 
	            then compt_amt 
				else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01')
	            then recovery_amt 
				else 0 end)                             as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                              as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_mon)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_mon)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_mon)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m01') = date_format('${v_sdate}', '%Y%m01')
	                   then recovery_amt 
	          		else 0 end)              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type5             -- '按区域',
union all 
select '${v_sdate}'          as day_id,
       '月报'                as report_type,
       '银行一级支行'        as group_type,
       type6                 as group_name,      	   
       sum(case when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') 
	            then compt_amt 
				else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01')
	            then recovery_amt 
				else 0 end)                             as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                              as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_mon)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_mon)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_mon)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m01') = date_format('${v_sdate}', '%Y%m01')
	                   then recovery_amt 
	          		else 0 end)              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type6             -- '按一级支行',
union all 
select '${v_sdate}'          as day_id,
       '月报'                as report_type,
       '项目经理'            as group_type,
       type7                 as group_name,      	   
       sum(case when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') 
	            then compt_amt 
				else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01')
	            then recovery_amt 
				else 0 end)                             as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y%m01') then 1
               else 0 end)                              as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_mon)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_mon)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_mon)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m01') = date_format('${v_sdate}', '%Y%m01')
	                   then recovery_amt 
	          		else 0 end)              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type7             -- '按项目经理',
;
commit;

 -- 季报
 insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt 
(
 day_id           --   '数据日期',
,report_type      --   '报表类型', (日报、旬报、月报、季报、半年报、年报)
,group_type       --   '统计类型',
,group_name       --   '分组名称',
,start_balance    --   '期初余额(万元)',
,start_cnt        --   '期初笔数',
,now_compt_amt    --   '当期代偿金额(万元)',
,now_compt_cnt    --   '当期代偿笔数',
,now_recovery_amt --   '当期收回金额(万元)',
,now_recovery_cnt --   '当期收回笔数',
,end_balance      --   '期末余额(万元)',
,end_cnt          --   '期末笔数'
)
select '${v_sdate}'          as day_id,
       '季报'                as report_type,
       '银行'                as group_type,
       type1                 as group_name,  	   
       sum(case
               when date_format(compt_date, '%Y%m%d')
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
               then compt_amt
               else 0 end) -
       sum(case
               when date_format(recovery_date, '%Y%m%d')
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
               then recovery_amt
               else 0 end)
                                                         as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                              as start_cnt,                -- 期初笔数	       	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if(quarter('${v_sdate}') = 1
		       		          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                              , if(quarter('${v_sdate}') = 2
		       			          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                  , if(quarter('${v_sdate}') = 3
		       				          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                      , if(quarter('${v_sdate}') = 4
		       					          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
		       						      , ''
		       						      )
                                      )
		       					  )
		       				  )
                       then recovery_amt
                       else 0 end)   
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type1             -- '按银行',
union all 
select '${v_sdate}'          as day_id,
       '季报'                as report_type,
       '产品'                as group_type,
       type2                 as group_name,        
       sum(case
               when date_format(compt_date, '%Y%m%d')
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
               then compt_amt
               else 0 end) -
       sum(case
               when date_format(recovery_date, '%Y%m%d')
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
               then recovery_amt
               else 0 end)
                                                         as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                              as start_cnt,                -- 期初笔数	       	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if(quarter('${v_sdate}') = 1
		       		          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                              , if(quarter('${v_sdate}') = 2
		       			          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                  , if(quarter('${v_sdate}') = 3
		       				          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                      , if(quarter('${v_sdate}') = 4
		       					          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
		       						      , ''
		       						      )
                                      )
		       					  )
		       				  )
                       then recovery_amt
                       else 0 end)   
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type2             -- '按产品',
union all 
select '${v_sdate}'          as day_id,
       '季报'                as report_type,
       '行业归类'                as group_type,
       type3                    as group_name,      	   
       sum(case
               when date_format(compt_date, '%Y%m%d')
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
               then compt_amt
               else 0 end) -
       sum(case
               when date_format(recovery_date, '%Y%m%d')
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
               then recovery_amt
               else 0 end)
                                                         as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                              as start_cnt,                -- 期初笔数	       	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if(quarter('${v_sdate}') = 1
		       		          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                              , if(quarter('${v_sdate}') = 2
		       			          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                  , if(quarter('${v_sdate}') = 3
		       				          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                      , if(quarter('${v_sdate}') = 4
		       					          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
		       						      , ''
		       						      )
                                      )
		       					  )
		       				  )
                       then recovery_amt
                       else 0 end)   
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type3             -- '行业归类',
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
               when date_format(compt_date, '%Y%m%d')
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
               then compt_amt
               else 0 end) -
       sum(case
               when date_format(recovery_date, '%Y%m%d')
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
               then recovery_amt
               else 0 end)
                                                         as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                              as start_cnt,                -- 期初笔数	       	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if(quarter('${v_sdate}') = 1
		       		          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                              , if(quarter('${v_sdate}') = 2
		       			          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                  , if(quarter('${v_sdate}') = 3
		       				          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                      , if(quarter('${v_sdate}') = 4
		       					          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
		       						      , ''
		       						      )
                                      )
		       					  )
		       				  )
                       then recovery_amt
                       else 0 end)   
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type4             -- '按办事处',
union all 
select '${v_sdate}'          as day_id,
       '季报'                as report_type,
       '区域'                as group_type,
       type5                 as group_name,      	   
       sum(case
               when date_format(compt_date, '%Y%m%d')
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
               then compt_amt
               else 0 end) -
       sum(case
               when date_format(recovery_date, '%Y%m%d')
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
               then recovery_amt
               else 0 end)
                                                         as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                              as start_cnt,                -- 期初笔数	       	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if(quarter('${v_sdate}') = 1
		       		          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                              , if(quarter('${v_sdate}') = 2
		       			          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                  , if(quarter('${v_sdate}') = 3
		       				          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                      , if(quarter('${v_sdate}') = 4
		       					          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
		       						      , ''
		       						      )
                                      )
		       					  )
		       				  )
                       then recovery_amt
                       else 0 end)   
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type5             -- '按区域',
union all 
select '${v_sdate}'          as day_id,
       '季报'                as report_type,
       '银行一级支行'        as group_type,
       type6                 as group_name,      	   
       sum(case
               when date_format(compt_date, '%Y%m%d')
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
               then compt_amt
               else 0 end) -
       sum(case
               when date_format(recovery_date, '%Y%m%d')
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
               then recovery_amt
               else 0 end)
                                                         as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                              as start_cnt,                -- 期初笔数	       	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if(quarter('${v_sdate}') = 1
		       		          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                              , if(quarter('${v_sdate}') = 2
		       			          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                  , if(quarter('${v_sdate}') = 3
		       				          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                      , if(quarter('${v_sdate}') = 4
		       					          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
		       						      , ''
		       						      )
                                      )
		       					  )
		       				  )
                       then recovery_amt
                       else 0 end)   
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type6             -- '按一级支行',
union all 
select '${v_sdate}'          as day_id,
       '季报'                as report_type,
       '项目经理'            as group_type,
       type7                 as group_name,      	   
       sum(case
               when date_format(compt_date, '%Y%m%d')
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
               then compt_amt
               else 0 end) -
       sum(case
               when date_format(recovery_date, '%Y%m%d')
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
               then recovery_amt
               else 0 end)
                                                         as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if(quarter('${v_sdate}') = 1, date_format('${v_sdate}', '%Y0101')
                        , if(quarter('${v_sdate}') = 2, date_format('${v_sdate}', '%Y0401')
                            , if(quarter('${v_sdate}') = 3, date_format('${v_sdate}', '%Y0701')
                                 , if(quarter('${v_sdate}') = 4, date_format('${v_sdate}', '%Y1001'), '')
                                 )))
                   then 1
               else 0 end)                              as start_cnt,                -- 期初笔数	       	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if(quarter('${v_sdate}') = 1
		       		          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
                              , if(quarter('${v_sdate}') = 2
		       			          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0401') and '${v_sdate}'
                                  , if(quarter('${v_sdate}') = 3
		       				          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
                                      , if(quarter('${v_sdate}') = 4
		       					          , date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y1001') and '${v_sdate}'
		       						      , ''
		       						      )
                                      )
		       					  )
		       				  )
                       then recovery_amt
                       else 0 end)   
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type7             -- '按项目经理',
;
commit;

 -- 半年报
 insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt 
(
 day_id           --   '数据日期',
,report_type      --   '报表类型', (日报、旬报、月报、季报、半年报、年报)
,group_type       --   '统计类型',
,group_name       --   '分组名称',
,start_balance    --   '期初余额(万元)',
,start_cnt        --   '期初笔数',
,now_compt_amt    --   '当期代偿金额(万元)',
,now_compt_cnt    --   '当期代偿笔数',
,now_recovery_amt --   '当期收回金额(万元)',
,now_recovery_cnt --   '当期收回笔数',
,end_balance      --   '期末余额(万元)',
,end_cnt          --   '期末笔数'
)
select '${v_sdate}'          as day_id,
       '半年报'                as report_type,
       '银行'                as group_type,
       type1                 as group_name,  
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), recovery_amt, 0)
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
			                  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
							  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
							  )
			           then recovery_amt
					   else 0 end
				 )              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type1             -- '按银行',
union all 
select '${v_sdate}'          as day_id,
       '半年报'                as report_type,
       '产品'                as group_type,
       type2                 as group_name,        
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), recovery_amt, 0)
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
			                  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
							  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
							  )
			           then recovery_amt
					   else 0 end
				 )              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type2             -- '按产品',
union all 
select '${v_sdate}'          as day_id,
       '半年报'                as report_type,
       '行业归类'                as group_type,
       type3                    as group_name,      	   
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), recovery_amt, 0)
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
			                  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
							  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
							  )
			           then recovery_amt
					   else 0 end
				 )              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type3             -- '行业归类',
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
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), recovery_amt, 0)
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
			                  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
							  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
							  )
			           then recovery_amt
					   else 0 end
				 )              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type4             -- '按办事处',
union all 
select '${v_sdate}'          as day_id,
       '半年报'                as report_type,
       '区域'                as group_type,
       type5                 as group_name,      	   
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), recovery_amt, 0)
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
			                  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
							  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
							  )
			           then recovery_amt
					   else 0 end
				 )              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type5             -- '按区域',
union all 
select '${v_sdate}'          as day_id,
       '半年报'                as report_type,
       '银行一级支行'        as group_type,
       type6                 as group_name,      	   
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), recovery_amt, 0)
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
			                  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
							  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
							  )
			           then recovery_amt
					   else 0 end
				 )              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type6             -- '按一级支行',
union all 
select '${v_sdate}'          as day_id,
       '半年报'                as report_type,
       '项目经理'            as group_type,
       type7                 as group_name,      	   
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d')
                         < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                              date_format('${v_sdate}', '%Y0701')), recovery_amt, 0)
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d')
                   < if('${v_sdate}' < date_format('${v_sdate}', '%Y0701'), date_format('${v_sdate}', '%Y0101'),
                        date_format('${v_sdate}', '%Y0701'))
                   then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数        	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (case when if('${v_sdate}' < date_format('${v_sdate}', '%Y0701')
			                  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0101') and '${v_sdate}'
							  ,date_format(recovery_date, '%Y%m%d') between date_format('${v_sdate}', '%Y0701') and '${v_sdate}'
							  )
			           then recovery_amt
					   else 0 end
				 )              
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type7             -- '按项目经理',
;
commit;

  -- 年报
 insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt 
(
 day_id           --   '数据日期',
,report_type      --   '报表类型', (日报、旬报、月报、季报、半年报、年报)
,group_type       --   '统计类型',
,group_name       --   '分组名称',
,start_balance    --   '期初余额(万元)',
,start_cnt        --   '期初笔数',
,now_compt_amt    --   '当期代偿金额(万元)',
,now_compt_cnt    --   '当期代偿笔数',
,now_recovery_amt --   '当期收回金额(万元)',
,now_recovery_cnt --   '当期收回笔数',
,end_balance      --   '期末余额(万元)',
,end_cnt          --   '期末笔数'
)
select '${v_sdate}'          as day_id,
       '年报'                as report_type,
       '银行'                as group_type,
       type1                 as group_name,  
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)   
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数          	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (
                         if(date_format(recovery_date, '%Y0101') = date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)   
                  )               
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type1             -- '按银行',
union all 
select '${v_sdate}'          as day_id,
       '年报'                as report_type,
       '产品'                as group_type,
       type2                 as group_name,        
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)   
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数          	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (
                         if(date_format(recovery_date, '%Y0101') = date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)   
                  )               
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0 end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end)  as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type2             -- '按产品',
union all 
select '${v_sdate}'          as day_id,
       '年报'                as report_type,
       '行业归类'                as group_type,
       type3                    as group_name,      	   
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)   
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数          	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (
                         if(date_format(recovery_date, '%Y0101') = date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)  
                  )               
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type3             -- '行业归类',
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
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)   
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数          	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (
                         if(date_format(recovery_date, '%Y0101') = date_format('${v_sdate}', '%Y0101'), recovery_amt, 0) 
                  )               
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type4             -- '按办事处',
union all 
select '${v_sdate}'          as day_id,
       '年报'                as report_type,
       '区域'                as group_type,
       type5                 as group_name,      	   
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)   
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数          	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (
                         if(date_format(recovery_date, '%Y0101') = date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)  
                  )               
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type5             -- '按区域',
union all 
select '${v_sdate}'          as day_id,
       '年报'                as report_type,
       '银行一级支行'        as group_type,
       type6                 as group_name,      	   
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)   
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数          	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (
                         if(date_format(recovery_date, '%Y0101') = date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)  
                  )               
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type6             -- '按一级支行',
union all 
select '${v_sdate}'          as day_id,
       '年报'                as report_type,
       '项目经理'            as group_type,
       type7                 as group_name,      	   
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then compt_amt
               else 0 end) -
       sum(
                  if(date_format(recovery_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101'), recovery_amt, 0)   
           )                                               as start_balance,            -- 期初余额(万元)
       sum(case
               when date_format(compt_date, '%Y%m%d') < date_format('${v_sdate}', '%Y0101') then 1
               else 0 end)                                 as start_cnt,                -- 期初笔数          	   
       sum(now_compt_amt_qua)                                                                            as now_compt_amt,        -- 当期放款金额(万元)
       sum(now_compt_cnt_qua)                                                                            as now_compt_cnt,        -- 当期放款笔数
       sum(now_recovery_amt_qua)                                                                         as now_recovery_amt,         -- 当期还款金额(万元)
       sum(if(compt_amt -
              (
                         if(date_format(recovery_date, '%Y0101') = date_format('${v_sdate}', '%Y0101'), recovery_amt, 0) 
                  )               
                  <= 0, 1, 0))                                                                           as now_recovery_cnt,         -- 当期还款笔数
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt else 0  end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt else 0 end) as end_balance, -- 期末余额(万元)
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)                  as end_cnt      -- 期末笔数
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt_new_data_main
group by type7             -- '按项目经理',
;
commit;




-- 新旧系统数据合并
insert into dw_base.ads_rpt_tjnd_busi_record_stat_compt
(day_id, -- 数据日期
 report_type,
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_compt_amt, -- 当期代偿金额(万元)
 now_compt_cnt, -- 当期代偿笔数
 now_recovery_amt, -- 当期收回金额(万元)
 now_recovery_cnt, -- 当期收回笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
       report_type,
       group_type,
       group_name,
       sum(start_balance),
       sum(start_cnt),
       sum(now_compt_amt),
       sum(now_compt_cnt),
       sum(now_recovery_amt),
       sum(now_recovery_cnt),
       sum(end_balance),
       sum(end_cnt)
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt
where day_id = '${v_sdate}'
group by report_type, group_type, group_name;
commit;

-- 删掉期末余额为0的项目经理，判定其已不在岗
delete from dw_base.ads_rpt_tjnd_busi_record_stat_compt
where day_id = '${v_sdate}'
  and group_type = '项目经理'
  and start_balance = 0
  and start_cnt = 0
;
commit;