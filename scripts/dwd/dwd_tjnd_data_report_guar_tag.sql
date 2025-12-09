-- ---------------------------------------
-- 备注     ：国担上报-数据上报底层数据
-- 变更记录 ：
-- ---------------------------------------

delete from dw_base.dwd_tjnd_data_report_guar_tag where day_id = '${v_sdate}';
commit;

insert into dw_base.dwd_tjnd_data_report_guar_tag
( day_id            -- '数据日期'
,project_no         -- '项目编号'
,guar_id            -- '业务编号'
,item_stt           -- '业务状态'
,city_name          -- '城市'
,county_name        -- '区县'
,cust_name          -- '客户名称'
,cert_no            -- '证件号'
,cust_type          -- '客户类型'
,cust_class         -- '客户分类'
,cust_class_type    -- '客户分类划分(上报分类）'
,loan_bank          -- '贷款银行'
,bank_class         -- '银行分类(上报分类)'
,loan_no            -- '借款合同编号'
,loan_amt           -- '借款合同金额'
,loan_cont_beg_dt   -- '借款合同开始日'
,loan_cont_end_dt   -- '借款合同结束日'
,loan_term          -- '担保期限'
,loan_term_type     -- '担保期限划分(上报分类）'
,guar_rate          -- '担保费率'
,loan_rate          -- '贷款利率'
,guar_class         -- '国担分类'
,guar_class_type    -- '国担分类(上报分类）'
,policy_type        -- '按照政策划分(上报分类）'
,bank_duty_rate     -- '担保责任比例'
,guar_cont_no       -- '保证合同编号'
,guar_beg_dt        -- '放款日'
,guar_end_dt        -- '到期日'
,loan_reg_dt        -- '放款登记日'
,is_first_guar      -- '是否首担'
,is_add_curryear    -- '是否本年新增业务'
,is_unguar          -- '是否解保'
,is_unguar_curryear -- '是否今年解保'
,unguar_dt          -- '解保日期'
,is_compt           -- '是否代偿'
,compt_aply_stt     -- '申请代偿状态'
,overdue_days       -- '逾期天数'
,compt_amt          -- '代偿金额'
,compt_dt           -- '代偿日期'
,compt_aply_dt      -- '代偿申请日期'
,origin_code        -- '原业务编号'
,is_fxhj            -- '是否展期业务'
)
select distinct '${v_sdate}' as day_id
       ,t1.project_no
       ,t1.guar_id
       ,t2.item_stt
       ,t2.city_name
       ,t2.county_name
       ,t2.cust_name
       ,t2.cert_no
       ,t2.cust_type
       ,t2.cust_class
       ,t2.cust_class as cust_class_type -- 需要细化维度到4个
       ,t8.loans_bank
       ,t8.gnd_dept_name
       ,t2.loan_no
       ,t2.loan_amt
       ,coalesce(t3.loan_beg_dt,  t2.loan_begin_dt)  as loan_cont_beg_dt -- 借款合同开始/结束时间为空,则取担保年度开始/结束时间
       ,coalesce(t3.loan_end_dt,  t2.loan_end_dt  )  as loan_cont_end_dt
       ,t2.loan_term
       ,case when t2.loan_term < 6 then '6个月以下'
             when t2.loan_term between 6 and 12 or t2.loan_term is null then '6(含)-12个月(含)' -- 为空默认为12个月
             when t2.loan_term > 12 and t2.loan_term <= 36 then '12-36个月(含)'
           else '36个月以上' end as loan_term_type
       ,t2.guar_rate
       ,t2.loan_rate
       ,t2.guar_class
       ,case when t2.guar_class regexp '农产品流通' then '农产品流通（含农产品收购、仓储保鲜、销售等）'
             when t2.guar_class in ('重要特色农产品种植','重要、特色农产品种植') then '特色农产品种植'
			 when t2.guar_class = '农资、农机、农技等社会化服务' then '农资、农机、农技等农业社会化服务'
             when t2.guar_class in ('非农项目','粮食种植','生猪养殖','其他畜牧业','渔业生产','农田建设','农产品初加工','农业新业态', '其他农业项目') then t2.guar_class
             when t2.guar_class is null then '其他农业项目' end as guar_class_type

       ,case when t2.loan_amt between 10 and 300 then '政策性业务：[10-300]'
             when t2.guar_class = '生猪养殖' and t2.loan_amt > 300 and t2.loan_amt <= 1000 then '政策性业务-生猪养殖: (300,1000]'
             when t2.loan_amt < 10 or (t2.guar_class <> '生猪养殖' and t2.loan_amt > 300 and t2.loan_amt <= 1000) then '政策外“双控”业务：<10 and (300,1000]'
             when t2.loan_amt > 1000 then '“双控”外业务：>1000' end as policy_type
       ,t8.bank_risk
       ,t2.guar_cnot_no
       ,t2.loan_begin_dt  as guar_beg_dt
       ,t2.loan_end_dt    as guar_end_dt
       ,t1.loan_reg_dt
       ,case when t4.is_first_guar = '0' and is_xz = '0' then '是' 
			else '否' end as is_first_guar -- wyx 20231017
       ,case when t1.loan_reg_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then '1' else '0' end as is_add_curryear
       ,case when t1.item_stt_code = '11' then '1' else '0' end as is_unguar
       ,case when t1.item_stt_code = '11' and (t5.item_stt <> '已解保' or t5.item_stt is null ) then '1' else '0' end as is_unguar_curryear
       ,t1.unguar_dt
       ,case when t6.status = '50' then '1' else '0' end as is_compt
       ,case t6.status when '00' then '申请中'
                       when '10' then '审核中'
                       when '20' then '拨付申请中'
                       when '30' then '拨付审核中'
                       when '40' then '待拨付'
                       when '50' then '已代偿'
                       when '98' then '已终止'
                       when '99' then '已否决' end as compt_aply_stt
        ,timestampdiff(day, t6.overdue_date, '${v_sdate}') as overdue_days
        ,coalesce(t10.compt_amt, t6.overdue_totl) as compt_amt -- “已代偿”外的数据，取逾期合计金额
        ,t10.compt_dt
        ,date_format(t6.submit_time, '%Y%m%d') as compt_aply_dt
        ,t7.origin_code
        ,case when t7.is_fxhj = '1' then '1' else '0' end as is_fxhj
  from dw_base.dwd_guar_info_stat t1
 inner join dw_base.dwd_guar_info_all t2
    on t1.guar_id = t2.guar_id
  left join (select guar_no, loan_beg_dt, loan_end_dt from dw_base.dwd_guar_cont_info_all group by guar_no ) t3
    on t1.guar_id = t3.guar_no
  left join dw_base.dwd_guar_tag t4
    on t1.guar_id = t4.guar_id
  left join (select guar_id, item_stt from dw_base.dwd_guar_info_all_his where day_id = '20231231') t5
    on t1.guar_id = t5.guar_id
  left join (select proj_code, status, submit_time, overdue_date, overdue_totl
               from (select proj_code, status, submit_time, overdue_date, overdue_totl
                       from dw_nd.ods_t_proj_comp_aply
                      where date_format( db_update_time, '%Y%m%d') <= '${v_sdate}'
                      order by db_update_time desc, update_time desc) a
              group by proj_code ) t6
    on t1.guar_id = t6.proj_code
  left join (select code, origin_code, is_fxhj
               from (select code, origin_code, is_fxhj
                       from dw_nd.ods_t_biz_project_main
                      where date_format( db_update_time, '%Y%m%d') <= '${v_sdate}'
                      order by db_update_time desc, update_time desc) a 
              group by code ) t7
    on t1.guar_id = t7.code
  left join dw_base.dwd_tjnd_report_biz_loan_bank t8
    on t1.guar_id = t8.biz_no
 left join 
 (
    -- 这个表的代偿数据才是准的
	select guar_id,compt_amt *10000 as compt_amt,compt_time as compt_dt
	from dw_base.dwd_guar_compt_info
	where day_id = '${v_sdate}' and compt_time <= '${v_sdate}'
 )t10 on t10.guar_id = t2.guar_id
 where t2.item_stt in ('已解保','已放款','已代偿') and t2.day_id = '${v_sdate}' and t1.day_id = '${v_sdate}'
   and '${v_sdate}' = date_format(last_day('${v_sdate}'),'%Y%m%d') -- 月底跑批
;
commit;
