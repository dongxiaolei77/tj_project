-- ---------------------------------------
-- 开发人   :  
-- 开发时间 ： 
-- 目标表   ： 
-- 源表     ：
-- 变更记录 ：20230421 增加 '中银保信' 接口代码
-- ---------------------------------------

delete from dw_base.dim_third_qry_prod ;
commit;

insert into dw_base.dim_third_qry_prod values('${v_sdate}','ST001','idnumber_verification','ST','商汤');
insert into dw_base.dim_third_qry_prod values('${v_sdate}','ST002','身份证识别模块','ST','商汤');
insert into dw_base.dim_third_qry_prod values('${v_sdate}','ST003','活体检测模块','ST','商汤');

insert into dw_base.dim_third_qry_prod values('${v_sdate}','HXZS_001','二要素认证','HX','海鑫');
insert into dw_base.dim_third_qry_prod values('${v_sdate}','HXZS_002','身份证识别模块','HX','海鑫');
insert into dw_base.dim_third_qry_prod values('${v_sdate}','HXZS_003','活体检测模块','HX','海鑫');
insert into dw_base.dim_third_qry_prod values('${v_sdate}','HXZS_004','人像身份核验','HX','海鑫');

insert into dw_base.dim_third_qry_prod 
select
day_id
,product_code
,product_name
,third_code
,third_code_name
from
(
select
'${v_sdate}' day_id -- 日期
,product_code -- 接口代码
,product_name -- 接口名称
,third_code  -- 接口大类
,case when third_code='BD' then '大数据局'
      when third_code='BH' then '百行征信'
	  when third_code='BWJK' then '百维金科'
	  when third_code='FB' then '风报'
	  when third_code='HF' then '汇法'
	  when third_code='TD' then '同盾'
	  when third_code='YL' then '银联智策'
	  when third_code='YS' then '有数'
	  when third_code='ZYBX' then '中银保信'  -- mdy 20230421 wyx
	  when third_code='PdBWJK' then '朴道百维金科'   -- mdy 20230802 kongb
          when third_code='PdHF' then '朴道汇法'   -- mdy 20230802 kongb
          when third_code='PdTD' then '朴道同盾'   -- mdy 20230802 kongb
          when third_code='PdYL' then '朴道银联智策'   -- mdy 20230802 kongb
	  END third_code_name -- 接口大类名称
,row_number()over(partition by product_code order by update_time desc) rn
from dw_nd.ods_de_t_product third_code 
where third_code IN ('BD','BH','BWJK','FB','HF','TD','YL','YS','ZYBX','PdBWJK','PdHF','PdTD','PdYL')
)t
where t.rn = 1
;
commit;


