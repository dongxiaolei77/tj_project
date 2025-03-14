-- ----------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20241212
-- 目标表   ：dwd_tjnd_report_proj_loan_rec_info       放款记录
-- 源表     ：dw_base.dwd_nacga_report_guar_info_base_info               国担上报范围表
--            dw_nd.ods_tjnd_yw_z_report_afg_business_infomation                  业务申请表
--            dw_nd.ods_tjnd_yw_z_report_afg_voucher_infomation                   放款凭证信息
-- 备注     ：天津农担历史数据迁移，上报国农担，数据逻辑组装
-- 变更记录 ：
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
)
select distinct '${v_sdate}'                                as day_id
              , t1.biz_no                                   as proj_no_prov
              , t3.receipt_no                               as loan_doc_no
              , t2.cooperative_bank_first                   as loan_bank_no
              , t2.full_bank_name                           as loan_bank_br_name
              , t3.receipt_amount / 10000                   as loan_amt
              , t3.interest_rate                            as loan_rate
              , date_format(t3.loan_start_date, '%Y-%m-%d') as loan_strt_dt
              , date_format(t3.loan_end_date, '%Y-%m-%d')   as loan_end_dt
              , date_format(t3.created_time, '%Y-%m-%d')    as loan_reg_dt
              , t3.id                                       as afg_voucher_id
from dw_base.dwd_nacga_report_guar_info_base_info t1 -- 国担上报范围表
         inner join dw_nd.ods_tjnd_yw_z_report_afg_business_infomation t2 -- 业务申请表
                    on t1.biz_id = t2.id
         inner join dw_nd.ods_tjnd_yw_z_report_afg_voucher_infomation t3 -- 放款凭证信息
                    on t1.biz_id = t3.id_business_information
where t1.day_id = '${v_sdate}'
and t3.DELETE_FLAG = 1
;
commit;
