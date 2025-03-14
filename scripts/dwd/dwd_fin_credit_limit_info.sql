-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_fin_credit_limit_info  额度信息表
-- 源表     ：dw_nd.ods_gcredit_credit_limit_info  额度信息表
-- 变更记录 ： 20220117:统一变动  
--             20220516 日志变量注释  xgm     
-- ---------------------------------------


-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_fin_credit_limit_info';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;  


 -- 客户额度信息   

 
 truncate table dw_base.dwd_fin_credit_limit_info;

 insert into dw_base.dwd_fin_credit_limit_info
 (
   seq_id , -- 序列号
   cust_id , -- 客户编号
   cert_no , --  证件号码
   prod_id , --  产品编号
   prod_code , --  产品代码
   limit_amt , --  授信额度
   loan_limit_amt , --  贷款余额
   unavailable_limit_amt , --  不可用额度
   due_day , --  到期日
   status , --  状态
   interest_type , --  计息方式
   fee_rate , --  费率
   repay_type , --  还款方式
   loop_flag , --  循环标识
   create_time , --  创建时间
   update_time , --  更新时间
   out_biz_id  --  外部业务id
 )
 select   seq_id ,
   customer_id ,
   id_no ,
   product_id ,
   product_code ,
   limit_amt/10000 ,
   loan_limit_amt/10000 ,
   unavailable_limit_amt/1000 ,
   due_day ,
   status ,
   interest_type ,
   fee_rate ,
   repay_type ,
   loop_flag ,
   create_time ,
   update_time ,
   out_biz_id 
 from 
	(select  
			seq_id ,
			customer_id ,
			id_no ,
			product_id ,
			product_code ,
			limit_amt ,
			loan_limit_amt,
			unavailable_limit_amt,
			due_day ,
			status ,
			interest_type ,
			fee_rate ,
			repay_type ,
			loop_flag ,
			create_time ,
			update_time ,
			out_biz_id
			,row_number() over(partition by seq_id order by  update_time desc) as rk
	from  dw_nd.ods_gcredit_credit_limit_info 
	where date_format(FROM_UNIXTIME(update_time/1000),'%Y%m%d') <= '${v_sdate}'
	) a  -- 字段为13位数字
 where rk = 1  ;
-- select row_count() into @rowcnt;
commit;

-- insert into dw_base.pub_etl_log -- values (@etl_date,@pro_name,@table_name,@sorting,concat('客户额度信息表加载完成,共插入',@rowcnt,'条'),@time,now());commit;
