 -- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_fin_credit_info   额度信息表
-- 源表     ：dw_base.dwd_fin_credit_apply 授信申请表-按产品
			-- dw_base.dwd_fin_credit_limit_info 额度信息表
			-- dw_base.dws_fin_loan_ac_dxloanbal_sum 客户支用汇总信息
			-- dw_base.dwd_cust_addr_info 地址信息表
			-- dw_base.dwd_cust_login_info 登录账号信息表

-- 变更记录 ： 20220117:统一变动 
--             20220516 日志变量注释  xgm    
--             20220822 客户模型重构：账号类型、证件类型代码还原 wyx
--             20220907 dwd_cust_addr_info重构，逻辑调整
--             20241201 脚本的统一变更，MySQL5.0转MySQL8.0 zhangfl 
-- ---------------------------------------
delete  from  dw_base.dwd_fin_credit_info  where  day_id='${v_sdate}';
commit; 
 
insert into  dw_base.dwd_fin_credit_info (
   day_id  , --  '数据日期',
   create_time , -- 创建时间
   login_no , --  '登录账号',
   login_type , --  '登录账号类型',
   cust_id , -- '客户编号',
   cert_no , -- '证件号',
   cert_type , --  '主体证件类型',
   cust_name , -- '主体名称',
   prod_id  , --  '产品编码',
   credit_status , --  '授信状态',
   limit_amt , --  '授信额度',
   amt  , -- '放款金额
   
   bal  , -- 本金余额 
   abal   , -- 正常本金
   aubal   , -- 待转逾期本金
   over_prin   , -- 拖欠本金
   over_int   , -- 拖欠利息
   over_fee  , --  拖欠保费 
   over_days  , -- 保费逾期天数    
   dx_cn , -- 支用笔数
   reject_code , --  '决策拒绝原因码'
   province_name , --  '省名称',
   city_name , -- '市名称',
   county_name  --  '县名称'   
 ) 
 select 
	   '${v_sdate}' as  day_id,
       a.create_time,
       a.login_no, 
       case when e.login_type = 'P' then '1' when e.login_type = 'C' then '2' else e.login_type end login_type, -- mdy 20220822
       a.cust_id,
       e.cert_no,
       e.cert_type,
       e.cust_name,
       a.prod_id,
       a.credit_status, 
       case when a.CREDIT_STATUS=2 then b.limit_amt else 0 end as limit_amt,   
       case when c.amt is null then 0 else c.amt end,
       case when c.bal is null then 0 else c.bal end,	   
       case when c.abal is null then 0 else c.abal end,
       case when c.aubal is null then 0 else c.aubal end,	   
       case when c.over_prin is null then 0 else c.over_prin end,
       case when c.over_int is null then 0 else c.over_int end,	
       case when c.over_fee is null then 0 else c.over_fee end,
       case when c.over_days is null then 0 else c.over_days end,	
       case when c.dx_cn is null then 0 else c.dx_cn end,
	     a.reject_code ,
       f.sup_area_name	, -- 省
			 f.area_name	, -- 地市
			 g.area_name	  -- 区县
from  dw_base.dwd_fin_credit_apply  a 
left join  dw_base.dwd_fin_credit_limit_info b  
		-- where date_format(FROM_UNIXTIME(update_time/1000),'%Y%m%d') <=  DATE_FORMAT('${v_sdate}','%Y%m%d') 		
on b.seq_id=a.credit_limit_id 
left join 
dw_base.dws_fin_loan_ac_dxloanbal_sum c 
on a.cust_id=c.cust_id
left join  dw_base.dwd_cust_addr_info d  -- mdy 20220907
on d.cust_id=a.cust_id 
left join  dw_base.dwd_cust_login_info e 
on e.login_no=a.login_no
left join dw_base.dim_area_info f
on d.city_cd = f.area_cd
left join dw_base.dim_area_info g
on d.country_cd = g.area_cd
;
 
commit;
