-- 开发人   : dxl
-- ---------------------------------------
-- 开发时间 ：dw_base.dwd_guar_info_onguar   担保台账在保信息
-- 目标表   ：
-- 源表     ：dw_base.dwd_guar_info_all    担保台账信息
-- 变更记录: 20250505 将truncate修改为 delete
--           20250925 变更在保余额逻辑
-- ---------------------------------------
-- 重跑逻辑
delete
from dw_base.dwd_guar_info_onguar
where day_id = '${v_sdate}';
commit;
-- 插入数据
insert into dw_base.dwd_guar_info_onguar
( day_id
, guar_id -- 台账编号
, loan_amt -- 借款合同金额
, guar_amt -- 放款金额
, repayment_amt -- 还款总金额
, onguar_amt -- 在保余额
)
select '${v_sdate}'                                                as day_id,
       t1.guar_id,
       t1.loan_amt,
       t1.guar_amt,
       null                                                        as repayment_amt,
       coalesce(t1.guar_amt, 0) - coalesce(t4.repayment_amount, 0) as onguar_amt --  放款金额 - 还款金额            20250925
from dw_base.dwd_guar_info_all t1
         left join dw_base.dwd_guar_info_stat t2 on t1.guar_id = t2.guar_id -- [只为获取 project_id]
         left join
     (
         select project_id,
                sum(repayment_principal) / 10000 as repayment_amount -- 还款金额(万元)
         from (select *, row_number() over (partition by id order by db_update_time desc) rn
               from dw_nd.ods_t_biz_proj_repayment_detail) t1
         where rn = 1
         group by project_id
     ) t4 -- 还款信息
     on t2.project_id = t4.project_id
where item_stt = '已放款'
;
commit;