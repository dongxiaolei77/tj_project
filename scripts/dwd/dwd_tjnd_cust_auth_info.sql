 -- 中间表  2025-01-01之后最早业务申请日期
delete from dw_tmp.tmp_tjnd_cust_auth_info where day_id ='${v_sdate}';
insert into dw_tmp.tmp_tjnd_cust_auth_info
select   '${v_sdate}' as day_id
  ,a.cert_no
  ,a.cust_name
  ,a.coup_cert_no
  ,a.coup_name
  ,min(b.apply_dt) as apply_dt
from 
(
	-- 个人及配偶
	select cert_no
	  ,cust_name
	  ,coup_cert_no
	  ,coup_name
	  ,null as proj_no_prov
	from dw_base.dwd_tjnd_report_cust_per_base_info
	where day_id ='${v_sdate}'
	
	union all 
	-- 企业及法人
	select corp_cert_no 
	  ,corp_name 
	  ,lgpr_cert_no
	  ,lgpr_name
	  ,null
	from dw_base.dwd_tjnd_report_cust_corp_base_info
	where day_id ='${v_sdate}'
	
	union all 
	-- 反担保人
	select main_signer_cert_no
	  ,main_signer_name
	  ,null 
	  ,NULL
	  ,proj_no_prov
	from dw_base.dwd_tjnd_report_proj_cntr_agmt_info
	where day_id ='${v_sdate}'
) a 
left join 
(
  select cert_no
	,proj_no_prov
	,apply_dt
  from dw_base.dwd_tjnd_report_proj_base_info 
  where day_id ='${v_sdate}' 
  and apply_dt >='2025-01-01'
)b on if(a.proj_no_prov is null,a.cert_no,a.proj_no_prov) = if(a.proj_no_prov is null,b.cert_no,b.proj_no_prov)
where b.apply_dt is not null
group by a.cert_no
  ,a.cust_name
  ,a.coup_cert_no
  ,a.coup_name
;

delete from dw_tmp.tmp_tjnd_cust_sign_auth_info  where day_id ='${v_sdate}';
insert into dw_tmp.tmp_tjnd_cust_sign_auth_info 
-- 新系统信息使用授权书签署日期
select '${v_sdate}' as day_id
	,a.cert_no
	,a.cust_name
	,min(b.sign_time) as sign_time
from 
(
	-- 个人及配偶
	select cert_no
	  ,cust_name
	from dw_base.dwd_tjnd_report_cust_per_base_info
	where day_id ='${v_sdate}'
	
	union all
	select coup_cert_no
	  ,coup_name
	from dw_base.dwd_tjnd_report_cust_per_base_info
	where day_id ='${v_sdate}'
	
	union all 
	-- 企业及法人
	select corp_cert_no 
	  ,corp_name 
	from dw_base.dwd_tjnd_report_cust_corp_base_info
	where day_id ='${v_sdate}'
	
	union all 
	select lgpr_cert_no
	  ,lgpr_name
	from dw_base.dwd_tjnd_report_cust_corp_base_info
	where day_id ='${v_sdate}'
	
	union all 
	-- 反担保人
	select main_signer_cert_no
	  ,main_signer_name
	from dw_base.dwd_tjnd_report_proj_cntr_agmt_info
	where day_id ='${v_sdate}'
	
)a
join 
(
   select b.main_id_no
    ,min(date_format(a.sign_time,'%Y-%m-%d')) as sign_time
   from 
   (
      select cust_code
        ,sign_time 
      from 
      (
        select *
          ,row_number()over(partition by id order by update_time desc) as rk
        from dw_nd.ods_comm_cont_auth_letter_contract_info
      )a 
      where rk = 1 
   )a
   left join 
   (
      select main_id_no
        ,main_name
        ,customer_id
      from 
      (
          select * 
          ,row_number()over(partition by seq_id order by update_time desc) as rk
          from dw_nd.ods_wxapp_cust_login_info
      )a 
      where rk = 1 
   )b on a.cust_code = b.customer_id
   group by b.main_id_no
)b on a.cert_no = b.main_id_no
group by a.cert_no
,a.cust_name
;


-- 目标表
delete from dw_base.dwd_tjnd_cust_auth_info where day_id ='${v_sdate}';
insert into dw_base.dwd_tjnd_cust_auth_info
select '${v_sdate}' as day_id
  ,cert_no
  ,min(sign_dt) as sign_dt
  ,'2099-12-31' as end_dt
from 
(
  select cert_no
    ,cust_name
    ,sign_dt
  from dw_tmp.tmp_tjnd_cust_auth_info
  where day_id ='${v_sdate}'

  union all 
  select coup_cert_no
    ,coup_name
    ,sign_dt
  from dw_tmp.tmp_tjnd_cust_auth_info 
  where coup_cert_no is not null and day_id ='${v_sdate}'
  
  union all 
  select cert_no
    ,cust_name
    ,sign_dt
  from dw_tmp.tmp_tjnd_cust_sign_auth_info
  where day_id ='${v_sdate}'
)a
group by cert_no;
commit;