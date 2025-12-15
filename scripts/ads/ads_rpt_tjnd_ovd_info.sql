-- ---------------------------------------
-- 开发人   : zzy
-- 开发时间 ：20251120
-- 目标表   ：dw_base.ads_rpt_tjnd_ovd_info 报表-逾期台账表
-- 源表     ：dw_nd.ods_t_loan_after_task 保后任务详情表
--            dw_nd.ods_t_biz_project_main
--            dw_base.dim_bank_info
--            dw_base.dim_cust_type
--            dw_base.dim_cust_class
--            dw_base.dim_guar_class
--            dw_base.dim_area_info
--            dw_nd.ods_t_biz_proj_sign   -- 项目签约表
--            dw_nd.ods_t_biz_proj_loan   -- 项目放款表
--            dw_nd.ods_t_biz_proj_appr   -- 批复信息表
--            dw_nd.ods_t_ct_en_guar      -- 委保合同先关信息
--            dw_nd.ods_t_loan_after_check  -- 保后检查表
--            dw_nd.ods_t_biz_proj_repayment_detail
--            dw_nd.ods_t_biz_proj_repayment
--            dw_nd.ods_t_proj_extension   -- 延期申请信息
--
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 重跑策略

drop table if exists dw_nd.tmp_ads_rpt_tjnd_ovd_info_code_value;
commit;

create table dw_nd.tmp_ads_rpt_tjnd_ovd_info_code_value
(
    code    varchar(40) comment '码值',
    value    varchar(64) comment '字典值',
    key tmp_ads_rpt_tjnd_ovd_info_code_value (code) comment '业务编号索引'
) engine = InnoDB
  default charset = utf8mb4
  collate = utf8mb4_bin;
commit;

insert into dw_nd.tmp_ads_rpt_tjnd_ovd_info_code_value (code,value) values
('000000'	,'不存在客观风险'                                                   ),
('010101'	,'自然风险-气象灾害-热带风暴'                                       ),
('010102'	,'自然风险-气象灾害-龙卷风'                                         ),
('010103'	,'自然风险-气象灾害-雷暴大风'                                       ),
('010104'	,'自然风险-气象灾害-干热风'                                         ),
('010105'	,'自然风险-气象灾害-干风'                                           ),
('010106'	,'自然风险-气象灾害-黑风'                                           ),
('010107'	,'自然风险-气象灾害-暴风雪'                                         ),
('010108'	,'自然风险-气象灾害-暴雨'                                           ),
('010109'	,'自然风险-气象灾害-寒潮'                                           ),
('010110'	,'自然风险-气象灾害-霜冻'                                           ),
('010111'	,'自然风险-气象灾害-水旱灾'                                         ),
('010112'	,'自然风险-气象灾害-其他'                                           ),
('010200'	,'自然风险-地震灾害'                                                ),
('010301'	,'自然风险-地质灾害-崩塌'                                           ),
('010302'	,'自然风险-地质灾害-滑坡'                                           ),
('010303'	,'自然风险-地质灾害-泥石流'                                         ),
('010304'	,'自然风险-地质灾害-塌陷'                                           ),
('010305'	,'自然风险-地质灾害-火山'                                           ),
('010306'	,'自然风险-地质灾害-冻融'                                           ),
('010307'	,'自然风险-地质灾害-地面沉降'                                       ),
('010308'	,'自然风险-地质灾害-土地沙漠化'                                     ),
('010309'	,'自然风险-地质灾害-水土流失'                                       ),
('010310'	,'自然风险-地质灾害-土地盐碱化'                                     ),
('010311'	,'自然风险-地质灾害-其他'                                           ),
('010401'	,'自然风险-海洋灾害-风暴潮'                                         ),
('010402'	,'自然风险-海洋灾害-海啸'                                           ),
('010403'	,'自然风险-海洋灾害-潮灾'                                           ),
('010404'	,'自然风险-海洋灾害-海浪'                                           ),
('010405'	,'自然风险-海洋灾害-赤潮'                                           ),
('010406'	,'自然风险-海洋灾害-海冰'                                           ),
('010407'	,'自然风险-海洋灾害-海水侵入'                                       ),
('010408'	,'自然风险-海洋灾害-海平面上升'                                     ),
('010409'	,'自然风险-海洋灾害-海水回灌'                                       ),
('010410'	,'自然风险-海洋灾害-其他'                                           ),
('010501'	,'自然风险-生物灾害-病害'                                           ),
('010502'	,'自然风险-生物灾害-虫害'                                           ),
('010503'	,'自然风险-生物灾害-草害'                                           ),
('010504'	,'自然风险-生物灾害-鼠害'                                           ),
('010505'	,'自然风险-生物灾害-其他'                                           ),
('010600'	,'自然风险-森林草原火灾'                                            ),
('010700'	,'自然风险-其他自然灾害'                                            ),
('010801'	,'自然风险-传染病疫情-甲类'                                         ),
('010802'	,'自然风险-传染病疫情-乙类'                                         ),
('010803'	,'自然风险-传染病疫情-丙类'                                         ),
('010900'	,'自然风险-群体性不明原因疾病'                                      ),
('011000'	,'自然风险-动物疫情'                                                ),
('011100'	,'自然风险-其他严重影响公众健康和生命安全的事件'                    ),
('020100'	,'担保客户生命健康风险-借款人或项目实际控制人死亡'                  ),
('020200'	,'担保客户生命健康风险-借款人或项目实际控制人突发重大疾病'          ),
('030100'	,'政策风险-征收、征用、封锁'                                        ),
('030201'	,'政策风险-其他重要政策变动-产业政策'                               ),
('030202'	,'政策风险-其他重要政策变动-金融政策'                               ),
('030203'	,'政策风险-其他重要政策变动-财政补贴政策'                           ),
('030204'	,'政策风险-其他重要政策变动-其他'                                   ),
('040100'	,'其他不可抗力-战争'                                                ),
('040200'	,'其他不可抗力-武装冲突'                                            ),
('040300'	,'其他不可抗力-罢工'                                                ),
('040400'	,'其他不可抗力-骚乱'                                                ),
('040500'	,'其他不可抗力-暴动'                                                ),
('060000'	,'市场价格波动'                                                     ),
('999999'	,'其他不能预见、不能避免并不能克服的客观情况'                       ),
('00'	,'不存在主观风险'        ),  
('01'	,'经营能力不足'          ),
('02'	,'贷款资金挪用'          ),
('03'	,'隐性负债'              ),
('04'	,'违法/违规/涉诉'        ),
('06'	,'逃废债/失联'           ),
('07'	,'不良嗜好'              ),
('08'	,'产品设计不合理'        ),
('09'	,'银行抽贷'              ),
('10'	,'信用意识不足'          ),
('99'	,'其他主观原因'          )
;
commit;


delete from dw_base.ads_rpt_tjnd_ovd_info where day_id = '${v_sdate}';
commit;

-- 老系统逻辑
insert into dw_base.ads_rpt_tjnd_ovd_info
(
 day_id             -- '数据日期'
,guar_id	        -- '业务编号'
,cust_name	        -- '客户名称'
,cert_no	        -- '证件号码'
,cust_source        -- '客户来源'
,tel_no	            -- '联系方式'
,loan_bank	        -- '贷款银行'
,cust_type	        -- '主体类型'
,cust_class	        -- '客户类型'
,indus_class	    -- '行业归类'
,province	        -- '所属省份'
,city	            -- '所属地市'
,district	        -- '所属区县'
,office_address     -- '经营地址'
,guar_cont_amt      -- '担保合同金额（万元）'
,fk_cont_amt        -- '放款金额（万元）'       
,rpmt_prin_amt      -- '还款本金总额（元）' 
,overdue_principal  -- '逾期本金（元）'
,overdue_int        -- '逾期利息（元）'
,is_receive         -- '是否收到履行代偿责任通知书'
,receive_date       -- '收到通知书日期'
,obj_risk_type      -- '客观风险类型'
,subj_risk_type     -- '主观风险类型'
,last_rpmt_dt       -- '最新还款日期'
,loan_term          -- '担保期限(月)'
,loan_dt            -- '放款日期'
,loan_beg_dt        -- '担保起始日期'
,loan_ent_dt        -- '担保到期日期'
,product            -- '产品'
,product_system     -- '产品体系'
,guar_state         -- '担保状态'
,project_manage     -- '项目经理'
,branch_office      -- '办事处'
,def_ext_end_dt     -- '延期/展期到期日'
,loan_amt_end_dt    -- '贷款到期日期'
,ovd_dt             -- '逾期日期'
,overdue_principal_wan  -- '逾期本金金额（万元）'
,onguar_amt         -- '在保余额（万元）'
)
select 
 '${v_sdate}' as day_id             -- '数据日期'
,t2.guar_id	        -- '业务编号'
,t2.cust_name	        -- '客户名称'
,t2.cert_no	        -- '证件号码'
,t2.cust_source        -- '客户来源'
,t2.tel_no	            -- '联系方式'
,t2.loan_bank	        -- '贷款银行'
,t2.cust_type	        -- '主体类型'
,t2.cust_class	        -- '客户类型'
,t2.indus_class	    -- '行业归类'
,t2.province	        -- '所属省份'
,t2.city	            -- '所属地市'
,t2.district	        -- '所属区县'
,t6.part_b_addr     as office_address     -- '经营地址'
,t3.jk_contr_amount as guar_cont_amt      -- '担保合同金额（万元）'
,t5.reply_amount    as fk_cont_amt        -- '放款金额（万元）'       
,t8.repayment_principal as rpmt_prin_amt                                                         -- '还款本金总额（元）' 
,t99.overdue_principal  -- '逾期本金（元）'
,t99.overdue_int        -- '逾期利息（元）'
,t99.is_receive         -- '是否收到履行代偿责任通知书'
,t99.receive_date       -- '收到通知书日期'
,coalesce(t99.objective_risk_type,t99.objective_risk_type_relation,t10.claim_cause) as obj_risk_type      -- '客观风险类型'
,coalesce(t99.subjective_risk_type,t10.claim_cause_detail) as subj_risk_type     -- '主观风险类型'
,t8.last_rpmt_dt                               -- '最新还款日期'
,t5.reply_period as loan_term          -- '担保期限(月)'
,t4.fk_date as loan_dt            -- '放款日期'
,t3.jk_ctrct_start_date as loan_beg_dt        -- '担保起始日期'
,t3.jk_ctrct_end_date   as loan_ent_dt        -- '担保到期日期'
,t2.product            -- '产品'
,t2.product_system     -- '产品体系'
,t2.guar_state         -- '担保状态'
,t2.project_manage     -- '项目经理'
,t2.branch_office      -- '办事处'
,t9.extension_date    as def_ext_end_dt                                                        -- '延期/展期到期日'
,t3.jk_ctrct_end_date as loan_amt_end_dt    -- '贷款到期日期'
,coalesce(t99.overdue_date,t10.ovd_dt)      as ovd_dt             -- '逾期日期'
,t99.overdue_principal / 10000 as overdue_principal_wan  -- '逾期本金金额（万元）'
,coalesce(t11.onguar_amt,0) as  onguar_amt        -- '在保余额（万元）'
from      (
            select project_id
			      ,overdue_principal
				  ,overdue_int
				  ,date_format(overdue_date,'%Y-%m-%d') as overdue_date
				  ,g2.value as objective_risk_type
				  ,g3.value as objective_risk_type_relation
				  ,g4.value as subjective_risk_type
				  ,case when is_receive = '1' then '是'
				        when is_receive = '0' then '否'
						end as is_receive
				  ,receive_date
			from ( 
                    select project_id
                          ,sum(overdue_principal)   as overdue_principal            --  逾期本金
	     	        	  ,sum(overdue_int)         as overdue_int                  --  逾期利息（元）
	     	        	  ,max(overdue_date)        as overdue_date                 --  逾期日期
	     	        	  ,max(objective_risk_type) as objective_risk_type          -- 客观风险类型
	     	        	  ,max(substring_index(regexp_replace(objective_risk_type_relation, '"|\\[|\\]', ''), ',', 1)) as objective_risk_type_relation -- 客观风险类型
	     	        	  ,max(subjective_risk_type) as subjective_risk_type         -- 主观风险类型
	     	        	  ,max(risk_resolution_measures) as risk_resolution_measures     -- 风险化解措施
			        	  ,max(is_receive) as is_receive   -- 是否收到履行代偿责任通知书  [1-是，0-否]
			        	  ,date_format(max(receive_date),'%Y-%m-%d') as receive_date -- 收到通知书日期
                    from (select *,row_number() over (partition by project_id order by db_update_time desc,update_time desc) rn from dw_nd.ods_t_loan_after_check where is_delete = '0') g  -- 保后检查表
	                where g.rn = 1 
	                  and is_debt_overdue != '0'    -- 本次贷款是否逾期  [判断这笔项目为逾期；0-未逾期，1-本息逾期，2-利息逾期，3-本金逾期]  
    	     	      and warn_status = '1'           -- 项目状态 [0-正常，1-预警]				 				 
				  --    and overdue_date is not null  -- [判断这笔项目为逾期]
			          group by project_id
				 ) g1
			left join dw_nd.tmp_ads_rpt_tjnd_ovd_info_code_value g2
			on g1.objective_risk_type = g2.code 
			left join dw_nd.tmp_ads_rpt_tjnd_ovd_info_code_value g3
			on g1.objective_risk_type_relation = g3.code
			left join dw_nd.tmp_ads_rpt_tjnd_ovd_info_code_value g4
			on g1.subjective_risk_type = g4.code
	      ) t99
inner join (
             select distinct a2.project_id
		     from       (
			               select  a1.pool_id
                                  ,a1.project_id
			 	          from (select *,row_number() over (partition by id order by db_update_time desc,update_time desc) rn from dw_nd.ods_t_loan_after_task) a1 -- 保后任务详情表	
			 	          where a1.rn = 1 and a1.task_status != '10'       -- [不是待确认的：10-待确认 20-提报中 30-审核中 40-正常 50-风险]
                        ) a2				  
		     inner join (
                           select id      -- 主键id
			               from (select *,row_number() over (partition by id order by db_update_time desc,update_time desc) rn from dw_nd.ods_t_loan_after_task_pool) a3  -- 保后任务池           [在保后检查完成的页面才能提报，用这个表判断]
			               where a3.rn = 1
		                 ) a4 
             on a2.pool_id = a4.id
	       ) t1
on t1.project_id = t99.project_id      
left join(
           select  b1.id
		          ,b1.code as guar_id	    -- '业务编号'
                  ,cust_name	            -- '客户名称'
                  ,cust_identity_no as cert_no	        -- '证件号码'
                  ,case when source = '02' then '银行直报' 
                        when source = '03' then '客户直通' 
		    			when source = '04' then '合作核心企业推介' 
		    			when source = '05' then '政府推介' 
                        when source = '06' then '信贷直通车' 
                        when source = '07' then '其他' 
                        end  as cust_source        -- '客户来源'
                  ,cust_mobile  as tel_no	            -- '联系方式'
                  ,b2.bank_name as loan_bank	        -- '贷款银行'
                  ,b3.value     as cust_type	        -- '主体类型'
                  ,b4.value     as cust_class	        -- '客户类型'
                  ,b5.value     as  indus_class	        -- '行业归类'
                  ,b6.sup_area_name as province	        -- '所属省份'
                  ,b6.area_name     as city	            -- '所属地市'
                  ,b7.area_name     as district	        -- '所属区县'
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
                        end     as product            -- '产品'
                  ,case when guar_product = '01' then '津沽担' 
				        end     as product_system     -- '产品体系'
                  ,case when proj_status = '50' then '在保'
                        when proj_status = '90' then '解保'
                        when proj_status = '93' then '解保'
                        end     as guar_state         -- '担保状态'
                  ,branch_manager_name as project_manage     -- '项目经理'
                  ,branch as branch_office      -- '办事处'
	       from (select *,row_number() over (partition by code order by db_update_time desc,update_time desc) rn from dw_nd.ods_t_biz_project_main) b1 
		   left join dw_base.dim_bank_info b2
		   on b1.loans_bank = b2.bank_id
		   left join dw_base.dim_cust_class b3
           on b1.cust_type = b3.code	
           left join dw_base.dim_cust_type b4
           on b1.main_type = b4.code		   
		   left join dw_base.dim_guar_class b5
           on b1.national_guar_type_one = b5.code
           left join dw_base.dim_area_info b6
		   on b1.city = b6.area_cd and b6.area_lvl = '2'
           left join dw_base.dim_area_info b7
		   on b1.district = b7.area_cd and b7.area_lvl = '3'
           where b1.rn = 1 and b1.is_delete = 0	   
	      ) t2
on t1.project_id = t2.id
left join (
            select project_id
			      ,jk_contr_amount
				  ,date_format(jk_ctrct_start_date,'%Y-%m-%d') as jk_ctrct_start_date
                  ,date_format(jk_ctrct_end_date,'%Y-%m-%d') as	jk_ctrct_end_date  
			from (select *,row_number()over(partition by project_id order by db_update_time desc) rn from dw_nd.ods_t_biz_proj_sign) c   -- 项目签约表
			where c.rn = 1
		  ) t3
on t1.project_id = t3.project_id
left join (
            select project_id
			      ,date_format(fk_date,'%Y-%m-%d') as fk_date
			from (select *,row_number()over(partition by id order by db_update_time desc ) rn from dw_nd.ods_t_biz_proj_loan) d  -- 项目放款表
			where d.rn = 1
		  ) t4
on t1.project_id = t4.project_id
left join (
            select project_id
			      ,reply_amount  -- 批复金额
				  ,reply_period  -- 批复期限(月)
				  ,guar_rate     -- 担保费率
			from (select *,row_number()over(partition by project_id order by db_update_time desc ) rn from dw_nd.ods_t_biz_proj_appr) e       -- 批复信息表
			where e.rn = 1
		  ) t5
on t1.project_id = t5.project_id
left join (
            select project_id
			      ,part_b_addr
			from (select *,row_number()over(partition by project_id order by db_update_time desc ) rn from dw_nd.ods_t_ct_en_guar) f     -- 委保合同先关信息
			where f.rn = 1
		  ) t6
on t1.project_id = t6.project_id
left join (
            select h1.project_id
			      ,sum(h1.repayment_principal) / 10000 as repayment_principal
				  ,date_format(max(h1.create_time),'%Y-%m-%d') as last_rpmt_dt
			from (select *, row_number() over (partition by id order by db_update_time desc) rn from dw_nd.ods_t_biz_proj_repayment_detail) h1             -- 还款详情
			inner join (select *,row_number() over (partition by project_id order by db_update_time desc) rn from dw_nd.ods_t_biz_proj_repayment) h2       -- 还款流程
			on h1.project_id = h2.project_id and h2.rn = 1 and h2.status = '02' 
			where h1.rn = 1 and h1.status = '20'
			group by  h1.project_id
		  ) t8
on t1.project_id = t8.project_id
left join (
            select project_id
			      ,date_format(extension_date,'%Y-%m-%d') as extension_date
			from (select *,row_number() over (partition by project_id order by db_update_time desc) rn from dw_nd.ods_t_proj_extension) i   -- 延期申请信息
			where i.rn = 1
		  ) t9
on t1.project_id = t9.project_id
         left join
     (
         select project_id,
                overdue_totl                         as ovd_amt,           -- 逾期合计
                overdue_totl * (1 - risk_shar_ratio/100) as ovd_ucompt_amt,    -- 逾期未代偿金额(不含银担分险)
                TRIM(TRAILING '0' FROM FORMAT(risk_shar_ratio/ 100, 2)) as bank_ratio,        -- 银行分险比例   [去除多余的0]
                apply_comp_amount                    as shod_compt_amt,    -- 申请代偿金额
                date_format(overdue_date,'%Y-%m-%d')                         as ovd_dt,            -- 逾期日期
                str_to_date(act_disburse_date,'%Y%m%d') as compt_dt,          -- 代偿款实际拨付日期
               b.value as claim_cause,              -- 客观风险成因
			   c.value as claim_cause_detail        -- 主观风险成因
         from (
                  select a1.project_id,
                         case when a4.value not in ('已代偿', '已否决', '已终止') then a1.overdue_totl end as overdue_totl,
                         a1.risk_shar_ratio,
                         a1.apply_comp_amount,
                         a1.overdue_date,
                         a3.risk_reason,
                         a2.act_disburse_date, 
						 coalesce(substring_index(regexp_replace(a3.objective_over_reason, '"|\\[|\\]', ''), ',', 1),'999999') as objective_over_reason,  -- 客观原因  110
					     coalesce(substring_index(regexp_replace(a3.subjective_over_reason,'"|\\[|\\]', ''), ',', 1),'99') as subjective_over_reason, -- 主观原因      130
                         row_number() over (partition by project_id order by a1.db_update_time desc) rn
                  from dw_nd.ods_t_proj_comp_aply a1 -- 代偿申请信息
                           left join dw_nd.ods_t_proj_comp_appropriation a2 -- 拨付信息
                                     on a1.id = a2.comp_id
                           left join (select comp_id,risk_reason,objective_over_reason,subjective_over_reason
						              from (select *,row_number() over(partition by comp_id order by db_update_time desc,update_time desc) as rn from dw_nd.ods_t_proj_comp_reason where is_delete = '0') z 
                                      where z.rn = 1) a3 -- 代偿原因
                                     on a1.id = a3.comp_id
                           left join
                       (
                           select * from dw_nd.ods_t_sys_data_dict_value_v2 where dict_code = 'bhProjectStatus'
                       ) a4 on a1.status = a4.code
              ) a  
		left join dw_nd.tmp_ads_rpt_tjnd_ovd_info_code_value b 
		on a.objective_over_reason = b.code
		left join dw_nd.tmp_ads_rpt_tjnd_ovd_info_code_value c 
		on a.subjective_over_reason = c.code
         where rn = 1
     ) t10 on t1.project_id = t10.project_id
left join (select guar_id,onguar_amt from  dw_base.dwd_guar_info_onguar where day_id = '${v_sdate}') t11
on t2.guar_id = t11.guar_id
;
commit;

	   
