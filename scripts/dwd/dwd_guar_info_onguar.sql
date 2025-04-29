-- 开发人   : dxl
-- ---------------------------------------
-- 开发时间 ：dw_base.dwd_guar_info_onguar   担保台账在保信息
-- 目标表   ：
-- 源表     ：dw_base.dwd_guar_info_all    担保台账信息
-- ---------------------------------------
-- 重跑逻辑
delete
from dw_base.dwd_guar_info_onguar
where day_id = '${v_sdate}';
commit;
-- 插入数据
insert into dw_base.dwd_guar_info_onguar
select '${v_sdate}'                                 as day_id,
       guar_id,
       loan_amt,
       guar_amt,
       null                                         as repayment_amt,
       case when item_stt = '已放款' then guar_amt end as onguar_amt
from dw_base.dwd_guar_info_all;
commit;
