-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250325
-- 目标表   ：dw_base.ads_rpt_tjnd_risk_compt_recovery_year 代偿追偿年度台账详情
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_afg_business_infomation       业务申请表
--          dw_nd.ods_tjnd_yw_bh_compensatory               代偿表
--          dw_nd.ods_tjnd_yw_afg_business_approval         审批
--          dw_nd.ods_tjnd_yw_base_customers_history        BO,客户信息历史表,NEW
--          dw_nd.ods_tjnd_yw_bh_recovery_tracking          追偿跟踪表
--          dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail   追偿跟踪详情表
--
--          新业务系统
--          dw_base.dwd_guar_info_all                           担保台账信息
--          dw_base.dwd_guar_info_stat                          担保台账星型表
--          dw_nd.ods_t_biz_project_main                        主项目表
--          dw_nd.ods_t_biz_proj_recovery_record                追偿记录表
--          dw_nd.ods_t_biz_proj_recovery_repay_detail_record   登记还款记录
--          dw_base.dwd_guar_compt_info                         代偿信息汇总表
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 重跑逻辑
truncate table dw_base.ads_rpt_tjnd_risk_compt_recovery_year;
commit;

 -- group_concat 防止字段长度过长 自动截断操作
set session group_concat_max_len = 102400;
-- 旧业务系统逻辑
 insert into dw_base.ads_rpt_tjnd_risk_compt_recovery_year
 (day_id, -- 数据日期
  guar_id, -- 业务id
  cust_name, -- 担保申请人名称
  cust_type, -- 类别
  full_bank, -- 贷款银行
  gnd_indus_class, -- 行业
  main_biz, -- 主营业务
  loan_amt, -- 贷款本金(万元)
  ovd_amt, -- 逾期余额（万元）
  compt_amt, -- 代偿金额(万元)
  compt_date, -- 代偿日
  recovery_amt, -- 收回金额(万元)
  compt_balance, -- 代偿余额(万元)
  province, -- 所属省市
  city, -- 所属地市
  area, -- 所属区县
  remark -- 备注
 )
 select '${v_sdate}'                            as day_id,
        t1.id                                   as guar_id,
        cust_name,
        case
            when cust_type = '02' then '企业'
            when cust_type = '01' then '个人'
            end                                 as cust_type,
        full_bank,
        case
            when gnd_indus_class = '01' then '粮食种植'
            when gnd_indus_class = '02' then '重要特色农产品种植'
            when gnd_indus_class = '03' then '生猪养殖'
            when gnd_indus_class = '04' then '其他畜牧业'
            when gnd_indus_class = '05' then '渔业生产'
            when gnd_indus_class = '06' then '农田建设'
            when gnd_indus_class = '07' then '农产品流通'
            when gnd_indus_class = '08' then '农产品初加工'
            when gnd_indus_class = '09' then '农业新业态'
            when gnd_indus_class = '10' then '其他农业项目'
            when gnd_indus_class = '11' then '非农项目'
            when gnd_indus_class = '12' then '农资、农机、农技等农业社会化服务'
            end                                 as gnd_indus_class,
        main_biz,
        loan_amt                                as loan_amt,
        null                                    as ovd_amt,
        compt_amt                               as compt_amt,
        compt_date,
        coalesce(recovery_amt,0)                            as recovery_amt,
		coalesce(
        case
            when (compt_amt - recovery_amt) < 0 then 0
            else (compt_amt - recovery_amt) end 
			,0)                                             as compt_balance,
        t7.sup_area_name as province,
        t6.sup_area_name as city,
        t6.area_name as  area,
        case
            when compt_remark is not null then compt_remark
            when recovery_remark is not null then recovery_remark
            end                                 as remark
 from (
          select ID,                                                    -- 业务id
                 CUSTOMER_NAME                            as cust_name, -- 客户姓名
                 CUSTOMER_NATURE                          as cust_type, -- 客户性质
                 FULL_BANK_NAME                           as full_bank, -- 合作银行全称
                 JSON_UNQUOTE(JSON_EXTRACT(area, '$[0]')) as province,  -- 所属省市
                 JSON_UNQUOTE(JSON_EXTRACT(area, '$[0]')) as city,      -- 所属地市
                 JSON_UNQUOTE(JSON_EXTRACT(area, '$[1]')) as area,      -- 所属区县
                 ID_CUSTOMER                                            -- 客户id
          from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation
		   where GUARANTEE_CODE != 'TJRD-2021-5S93-979U'
      ) t1
          inner join
      (
          select ID_CFBIZ_UNDERWRITING,             -- 业务id
                 TOTAL_COMPENSATION as compt_amt,   -- 代偿金额
                 PAYMENT_DATE       as compt_date,  -- 代偿日期
                 REMARK             as compt_remark -- 代偿备注
          from dw_nd.ods_creditmid_v2_z_migrate_bh_compensatory
          where status = 1
            and over_tag = 'BJ'
            and DELETED_BY is null
      ) t2 on t1.id = t2.ID_CFBIZ_UNDERWRITING
          left join
      (
          select ID_BUSINESS_INFORMATION,         -- 业务id
                 LOAN_CONTRACT_AMOUNT as loan_amt -- 借款合同金额
          from dw_nd.ods_creditmid_v2_z_migrate_afg_business_approval
      ) t3 on t1.id = t3.ID_BUSINESS_INFORMATION
          left join
      (
          select ID,                                           -- 客户id
                 INDUSTRY_CATEGORY_COMPANY as gnd_indus_class, -- 行业分类(公司)
                 BUSINESS_ITEM             as main_biz         -- 主营业务
				,JSON_UNQUOTE(JSON_EXTRACT(area, '$[1]'))  as area
          from dw_nd.ods_creditmid_v2_z_migrate_base_customers_history
      ) t4 on t1.ID_CUSTOMER = t4.id
          left join
      (
          select t1.ID_CFBIZ_UNDERWRITING,                                      -- 业务id
                 sum(CUR_RECOVERY)                           as recovery_amt,   -- 追偿金额
                 group_concat(distinct REMARK separator '；') as recovery_remark -- 追偿备注
          from dw_nd.ods_creditmid_v2_z_migrate_bh_recovery_tracking t1
                   left join dw_nd.ods_creditmid_v2_z_migrate_bh_recovery_tracking_detail t2
 --                            on t1.id = t2.ID_RECOVERY_TRACKING and t1.STATUS = 1 and t2.STATUS = 1
                   on  ifnull(t2.ID_RECOVERY_TRACKING = t1.ID,t2.GUARANTEE_CODE = t1.RELATED_ITEM_NO) and t1.STATUS = 1 and t2.STATUS = 1
          group by t1.ID_CFBIZ_UNDERWRITING
      ) t5 on t1.id = t5.ID_CFBIZ_UNDERWRITING		
left join (select area_cd,area_name,sup_area_cd,sup_area_name from dw_base.dim_area_info where area_lvl = '3' and day_id = '${v_sdate}') t6 
on ifnull(t1.area = t6.area_cd,t4.area = t6.area_cd) 
left join (select area_cd,area_name,sup_area_cd,sup_area_name from dw_base.dim_area_info where area_lvl = '2' and day_id = '${v_sdate}') t7
on t6.sup_area_cd = t7.area_cd 	  
;
 commit;

-- --------------------------------------------------------
-- 新业务系统逻辑
insert into dw_base.ads_rpt_tjnd_risk_compt_recovery_year
(day_id, -- 数据日期
 guar_id, -- 业务id
 cust_name, -- 担保申请人名称
 cust_type, -- 类别
 full_bank, -- 贷款银行
 gnd_indus_class, -- 行业
 main_biz, -- 主营业务
 loan_amt, -- 贷款本金(万元)
 ovd_amt, -- 逾期余额（万元）
 compt_amt, -- 代偿金额(万元)
 compt_date, -- 代偿日
 recovery_amt, -- 收回金额(万元)
 compt_balance, -- 代偿余额(万元)
 province, -- 所属省市
 city, -- 所属地市
 area, -- 所属区县
 remark -- 备注
)
select '${v_sdate}'             as day_id,
       t1.guar_id,
       cust_name,
       cust_type,
       full_bank,
       gnd_indus_class,
       main_biz,
       loan_amt,
       null                     as ovd_amt,
       compt_amt,
       t7.approp_date           as compt_date,
       coalesce(recovery_amt,0) as recovery_amt,
       coalesce(compt_amt - recovery_amt,0) as compt_balance,
       province,
       city,
       area,
       null                     as remark
from (
         select guar_id     as guar_id,         -- 台账编号
                cust_name   as cust_name,       -- 客户姓名
                cust_type   as cust_type,       -- 客户类型
                loan_bank   as full_bank,       -- 贷款银行
                guar_class  as gnd_indus_class, -- 国担分类
                loan_amt    as loan_amt,        -- 放款金额(万元)
                city_name   as city,            -- 所属地市
                county_name as area             -- 所属区县
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
     ) t1
         inner join
     (
         select guar_id,
                compt_amt  as compt_amt, -- 代偿金额(万元)
                compt_time as compt_date -- 代偿日期
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
         select code,
                main_business_one as main_biz, -- 主营业务
                a.area_name as  province,                      -- 所属省市
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main) t1
		 left join (select area_cd,area_name,sup_area_cd,sup_area_name from dw_base.dim_area_info where area_lvl = '1' and day_id = '${v_sdate}') a
		 on t1.province = a.area_cd
		 where rn = 1
     ) t4 on t1.guar_id = t4.code
         left join
     (
         select t1.project_id,
                sum(t2.shou_comp_amt) / 10000 as recovery_amt -- 追偿收回金额(万元)
         from (
                  select *, row_number() over (partition by id order by db_update_time desc) rn
                  from dw_nd.ods_t_biz_proj_recovery_record
              ) t1
                  left join
              (
                  select *, row_number() over (partition by id order by db_update_time desc) rn
                  from dw_nd.ods_t_biz_proj_recovery_repay_detail_record
              ) t2 on t1.reco_id = t2.record_id and t1.rn = 1 and t2.id = 1
         group by project_id
     ) t5 on t3.project_id = t5.project_id
left join (
            select id
			     , proj_code
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
		  ) t6
on t1.guar_id = t6.proj_code
left join (
            select comp_id
                  ,date_format(approp_date,'%Y-%m-%d') as approp_date  -- 代偿款拨付申请日
            from(select *,row_number()over(partition by comp_id order by db_update_time desc,update_time desc ) rn from dw_nd.ods_t_proj_comp_appropriation) e
            where e.rn = 1
		  ) t7
on t6.id = t7.comp_id
;
commit;

