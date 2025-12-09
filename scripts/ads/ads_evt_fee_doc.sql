-- ---------------------------------------
-- 开发人   :  Wangyx
-- 开发时间 ： 20220922
-- 目标表   ： ads_evt_fee_doc 费用凭证信息
-- 源表     ： dwd_evt_fee_doc 费用凭证信息
-- 变更记录 ： 20231228 wyx 增加字段：deal_type -- 处理类型 0正常流程 1人工补录
-- ---------------------------------------


-- 同步服务层

delete from dw_base.ads_evt_fee_doc where day_id = '${v_sdate}'  ;
commit ;

insert into dw_base.ads_evt_fee_doc
(
day_id
,guar_id
,cust_id
,cust_name
,cert_no
,city_name
,county_name
,guar_stt
,guar_upt_dt
,guar_prod
,pay_no
,guar_fee
,pay_stt
,pay_channel
,pay_type
,pay_dt
,change_type
,difference_fee
,rbl_fee
,rbl_fee_person
,rbl_fee_policy
,refund_aply_amount
,deal_type   -- mdy 20231228 wyx
)
select 
day_id
,guar_id
,cust_id
,cust_name
,cert_no
,city_name
,county_name
,guar_stt
,guar_upt_dt
,guar_prod
,pay_no
,guar_fee
,pay_stt
,pay_channel
,pay_type
,pay_dt
,change_type
,difference_fee
,rbl_fee
,rbl_fee_person
,rbl_fee_policy
,refund_aply_amount
,deal_type   -- mdy 20231228 wyx
from dw_base.dwd_evt_fee_doc
;

commit ; 