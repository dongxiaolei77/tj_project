-- ----------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20241212
-- 目标表   ：dwd_tjnd_report_proj_loan_rec_info       放款记录
-- 源表     ：dw_base.dwd_nacga_report_guar_info_base_info               国担上报范围表
--            dw_nd.ods_tjnd_yw_z_report_afg_business_infomation                  业务申请表
--            dw_nd.ods_tjnd_yw_z_report_afg_voucher_infomation                   放款凭证信息
-- 备注     ：天津农担历史数据迁移，上报国农担，数据逻辑组装
-- 变更记录 ：zhangruwen 20250219  放款凭证信息id 增加 赋值1
-- ----------------------------------------
-- 日增量加载
delete
from dw_base.dwd_tjnd_report_proj_loan_rec_info
where day_id = '${v_sdate}';
commit;

insert into dw_base.dwd_tjnd_report_proj_loan_rec_info
( day_id
, proj_no_prov -- 省农担担保项目编号
, loan_doc_no -- 放款凭证编号
, loan_bank_no -- 放款金融机构代码
, loan_bank_br_name -- 放款金融机构（分支机构）
, loan_amt -- 放款金额
, loan_rate -- 放款利率
, loan_strt_dt -- 放款日期
, loan_end_dt -- 放款到期日期
, loan_reg_dt -- 放款登记日期
, afg_voucher_id -- 放款凭证信息id
, dict_flag)
select distinct '${v_sdate}'                                as day_id
              , t1.biz_no                                   as proj_no_prov
              , t3.receipt_no                               as loan_doc_no
              , t5.机构编码                                     as loan_bank_no
--              , t2.full_bank_name                           as loan_bank_br_name
              , t6.full_bank_name                           as loan_bank_br_name             -- [若项目已提交代偿补偿申请，该项目基础信息不可修改或删除（可以新增记录）]
              , t3.receipt_amount                           as loan_amt
              , t3.interest_rate                            as loan_rate
              , date_format(t3.loan_start_date, '%Y-%m-%d') as loan_strt_dt
              , date_format(t3.loan_end_date, '%Y-%m-%d')   as loan_end_dt
              , date_format(t3.created_time, '%Y-%m-%d')    as loan_reg_dt
              , t3.id                                       as afg_voucher_id
              , 0                                           as dict_flag
from dw_base.dwd_nacga_report_guar_info_base_info t1 -- 国担上报范围表
         inner join dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation t2 -- 业务申请表
                    on t1.biz_id = t2.id
         inner join dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_infomation t3 -- 放款凭证信息
                    on t1.biz_id = t3.id_business_information
         left join
     (
         select *
         from (select *, row_number() over (partition by dept_id order by update_time desc) as rn
               from dw_nd.ods_t_sys_dept
               where del_flag = 0) t1
         where rn = 1
     ) t4 -- 部门表
     on t2.COOPERATIVE_BANK_ID = t4.dept_id
         left join
     (
         select t1.dept_id,
                t2.机构编码,
                t2.中文全称
         from (select *
               from (select *, row_number() over (partition by dept_id order by update_time desc) as rn
                     from dw_nd.ods_t_sys_dept
                     where del_flag = 0) t1
               where rn = 1) t1 -- 部门表
                  join dw_base.dwd_imp_tjnd_report_bank_financial_institution t2 -- 国农担机构表
                       on t2.中文全称 = if(t1.dept_name like '中国农业发展银行%', '中国农业发展银行', t1.dept_name)
     ) t5 on FIND_IN_SET(t5.dept_id, t4.ancestors) > 0 or t4.dept_id = t5.dept_id
	     left join
     (
	   select guarantee_code -- 业务编号
	         ,date_format(created_time, '%Y-%m-%d') as  apply_dt  -- 申请日期
			 ,full_bank_name          -- 合作银行全称
	   from dw_nd.ods_tjnd_yw_z_report_afg_business_infomation -- 申请表
	 ) t6 on t2.guarantee_code  COLLATE utf8mb4_0900_ai_ci = t6.guarantee_code COLLATE utf8mb4_0900_ai_ci       -- [排序规则不一样，统一排序规则，否则关联不上]
where t1.day_id = '${v_sdate}'
  and t3.DELETE_FLAG = 1
;
commit;

-- 日增量加载
insert into dw_base.dwd_tjnd_report_proj_loan_rec_info
( day_id
, proj_no_prov -- 省农担担保项目编号
, loan_doc_no -- 放款凭证编号
, loan_bank_no -- 放款金融机构代码
, loan_bank_br_name -- 放款金融机构（分支机构）
, loan_amt -- 放款金额
, loan_rate -- 放款利率
, loan_strt_dt -- 放款日期
, loan_end_dt -- 放款到期日期
, loan_reg_dt -- 放款登记日期
, afg_voucher_id -- 放款凭证信息id
, dict_flag)
select distinct '${v_sdate}'                                          as day_id
              , t1.guar_id                                            as proj_no_prov      -- 省农担担保项目编号
              -- ,substring_index(substring_index(substring_index(substring_index(substring_index(substring_index(t3.debt_on_bond_code,',',1), '，',1),"",1), '；',1), '/',1), '、',1) as loan_doc_no -- 放款凭证编号 -- 非结构化数据，提取第一笔编号--
              , if(t1.guar_id like 'TJ%', t3.debt_on_bond_code, null) as loan_doc_no       -- mdy 20250107 暂不报送--
              , case
                    when t4.dept_name in ('农村商业银行', '村镇银行') or (t1.guar_prod = '农耕e贷' and t4.bank_name = '农村商业银行') or
                         t4.dept_id is null
                        then t1.guar_id -- 省端机构名称为农村商业银行、村镇银行，或者产品名称为农耕e贷且银行名称为农村商业银行，或者省端机构为空值的，将放款金融机构代码映射为业务编号--
                    else t4.gnd_dept_id
    end                                                               as loan_bank_no      -- 放款金融机构代码
              , coalesce(t4.bank_name, t4.dept_name)                  as loan_bank_br_name -- 放款金融机构（分支机构） -- 银行名称空值的，用省端机构名称补充--
              , case when t1.guar_id = 'TJRD-2021-5Z95-939W' then t5.receipt_amount  else t1.guar_amt  end             as loan_amt          -- 放款金额       -- [特殊处理]  这笔项目老系统有3条记录，新系统只有一条
              , if(t1.guar_id like 'TJ%',t5.interest_rate,t1.loan_rate / 100) as loan_rate         -- 放款利率      {判断在保转进件取老系统数据}  20250905
              , if(t1.guar_id like 'TJ%',date_format(t5.loan_start_date, '%Y-%m-%d'),date(t1.loan_begin_dt))      as loan_strt_dt      -- 放款日期
              , if(t1.guar_id like 'TJ%',date_format(t5.loan_end_date, '%Y-%m-%d'),date(t1.loan_end_dt))          as loan_end_dt       -- 放款到期日期
              , if(t1.guar_id like 'TJ%',date_format(t5.created_time, '%Y-%m-%d'),
			    case
                    when t1.data_source = '标准线上业务台账' then coalesce(date(t1.loan_begin_dt), date(t1.loan_reg_dt))
                    else date(t1.loan_reg_dt) -- 计入在保日期  mdy，改为与内部画像口径一致
    end)                                                              as loan_reg_dt       -- 放款登记日期
              , t5.id                                                 as afg_voucher_id    -- 放款凭证信息id
              , 1                                                     as dict_flag
from dw_base.dwd_guar_info_all t1 -- 业务信息宽表--项目域
         inner join dw_base.dwd_tjnd_report_biz_no_base t2 -- 国担上报范围表
                    on t1.guar_id = t2.biz_no
                        and t2.day_id = '${v_sdate}'
         left join
     (
         select t1.id
              , t1.project_id
              , t1.debt_on_bond_code
         from (
                  select t1.id,
                         t1.project_id,
                         t1.debt_on_bond_code,
                         row_number() over (partition by t1.id order by t1.db_update_time desc, t1.update_time desc) rn
                  from dw_nd.ods_t_biz_proj_loan t1 -- 项目放款表
              ) t1
         where t1.rn = 1
     ) t3
     on t2.biz_id = t3.project_id
         left join dw_base.dwd_tjnd_report_biz_loan_bank t4 -- 国担上报银行映射表
                   on t1.guar_id = t4.biz_no
				   and t4.day_id = '${v_sdate}'
         left join dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_infomation t5 -- 放款凭证信息
                   on t2.biz_id = t5.id_business_information and t5.DELETE_FLAG = 1
;
commit;