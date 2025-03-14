-- ---------------------------------------
-- 开发人   : liyy
-- 开发时间 ：20210311
-- 目标表   :  dwd_agmt_guar_contn_pay_succ_info
-- 源表     ：dw_base.dwd_agmt_guar_info  
-- 变更记录 ：20210422 业务系统放款信息表中只有 本次放款日、本次到期日, 放款日期 部分迁移后没有数据，需要取历史的数据 dwd_guar_info 放款时间、到期时间
--            20211011 1.增加保后检查已终止数据 2.自主续支        
--            20220211统一修改
-- ---------------------------------------
set interactive_timeout = 7200;
set wait_timeout = 7200;
 -- 续支成功数据,其他的状态为解保
 -- delete from dw_base.dwd_agmt_guar_contn_pay_succ_info ;
 truncate  table  dw_base.dwd_agmt_guar_contn_pay_succ_info;
 commit ;
 
 insert into dw_base.dwd_agmt_guar_contn_pay_succ_info
 select 
 distinct
 day_id
 ,proj_id 
 ,proj_no
 ,proj_dtl_no
 ,contn_pay_time
 from dw_base.dwd_agmt_guar_info
 where proj_dtl_stt = '50' -- 50-已放款
 and rcd_type='2'  -- 2续支放款
 ;
 commit ;
 