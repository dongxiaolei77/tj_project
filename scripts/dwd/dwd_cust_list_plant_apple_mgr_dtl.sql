-- ---------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20230423
-- 目标表   ：dwd_cust_list_plant_apple_mgr_dtl
-- 源表     ：dw_nd.ods_imp_ag_info_apple_yt_caas_standard  -- 烟台农科院大数据平台_苹果数据
--            dw_nd.ods_customer_acquisition_yidao_cj_zzy_lszzl_zl -- 市管理中心收集-种植类数据
--            dw_base.dim_area_info  -- 地区维表
--            
-- 备注     ：烟台苹果种植类数据加工
-- 修改记录 ：YYYYMMDD 因XXX原因修改     修改人

-- ---------------------------------------


-- 1.临时表_烟台农科院大数据平台_苹果数据
drop table if exists dw_tmp.tmp_dwd_cust_list_plant_apple_mgr_dtl_caas_standard;
commit;
create table if not exists dw_tmp.tmp_dwd_cust_list_plant_apple_mgr_dtl_caas_standard
( name       varchar(100)    comment '姓名'
 ,tel_no     varchar(100)    comment '联系电话'
 ,cert_no    varchar(50)     comment '身份证号'
 ,gender     varchar(10)     comment '性别'
 ,addr       varchar(300)    comment '详细地址'
 ,area_num   double          comment '种植亩数'
 ,province   varchar(100)    comment '省'
 ,city       varchar(100)    comment '市'
 ,country    varchar(100)    comment '区县'
 ,town       varchar(100)    comment '乡镇街道'
 ,village    varchar(100)    comment '村'
 ,index ind_tmp_dwd_cust_list_plant_apple_mgr_dtl_caas_standard_cert_no(cert_no)
 ,index ind_ind_tmp_dwd_cust_list_plant_apple_mgr_dtl_caas_standard_city(province,city,country)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='临时表_烟台农科院大数据平台_苹果数据';
 commit;
 
 insert into dw_tmp.tmp_dwd_cust_list_plant_apple_mgr_dtl_caas_standard
 ( name    
  ,tel_no  
  ,cert_no 
  ,gender  
  ,addr    
  ,area_num
  ,province
  ,city    
  ,country 
  ,town    
  ,village
 )
select name
      ,tel_no
      ,cert_no
      ,gender
      ,addr
      ,area_num
      ,province
      ,city
      ,country
      ,town
      ,village
  from dw_nd.ods_imp_ag_info_apple_yt_caas_standard -- 烟台苹果名单数据
 where length(name) >= 6 and length(name) <= 12 -- 姓名长度6-12个字符（2.4个汉字）
   and coalesce(area_num, 0) > 0                -- 面积非空，大于0

   -- 以下为指定的身份证号码校验规则
   and cert_no is not null    -- 身份证非空
   and length(replace(cert_no,' ',''))=18
   and substr(cert_no,1,17) REGEXP '[0-9]'      -- 身份证前17位只有数字
   -- and date(substr(cert_no,7,8)) is not null    -- 生日字段填写正确
   -- and TIMESTAMPDIFF(year,date(substr(cert_no,7,8)),now())>=18   -- 年龄大于等于18周岁
   -- and TIMESTAMPDIFF(year,date(substr(cert_no,7,8)),now())<=65   -- 年龄小于等于65周岁
   and (substr(cert_no,1,2)+0>=11 and substr(cert_no,1,2)+0<=82)   -- 身份证省份字段需要在11-82之间
   and mod(substr(cert_no,1,1)*7+
       substr(cert_no,2,1)*9+
       substr(cert_no,3,1)*10+
       substr(cert_no,4,1)*5+
       substr(cert_no,5,1)*8+
       substr(cert_no,6,1)*4+
       substr(cert_no,7,1)*2+
       substr(cert_no,8,1)*1+
       substr(cert_no,9,1)*6+
       substr(cert_no,10,1)*3+
       substr(cert_no,11,1)*7+
       substr(cert_no,12,1)*9+
       substr(cert_no,13,1)*10+
       substr(cert_no,14,1)*5+
       substr(cert_no,15,1)*8+
       substr(cert_no,16,1)*4+
       substr(cert_no,17,1)*2
       ,11)=
       (case 
       when substr(cert_no,18,1)='1' then '0'
       when substr(cert_no,18,1)='0' then '1'
       when substr(cert_no,18,1) in ('X','x') then '2'
       when substr(cert_no,18,1)='9' then '3'
       when substr(cert_no,18,1)='8' then '4'
       when substr(cert_no,18,1)='7' then '5'
       when substr(cert_no,18,1)='6' then '6'
       when substr(cert_no,18,1)='5' then '7'
       when substr(cert_no,18,1)='4' then '8'
       when substr(cert_no,18,1)='3' then '9'
       when substr(cert_no,18,1)='2' then '10'
       else -99 end)
;
commit;

-- 删除不符合条件的身份证号码，以下条件直接insert 时会报错
delete from dw_tmp.tmp_dwd_cust_list_plant_apple_mgr_dtl_caas_standard
where date(substr(cert_no,7,8)) is null    -- 生日字段填写不正确
   or TIMESTAMPDIFF(year,date(substr(cert_no,7,8)),now())<18   -- 年龄<18周岁
   or TIMESTAMPDIFF(year,date(substr(cert_no,7,8)),now())>65   -- 年龄>65周岁
;
commit;

-- 2.临时表_苹果种植类数据
DROP TABLE IF EXISTS dw_tmp.tmp_dwd_cust_list_plant_apple_mgr_dtl_lszzl;
COMMIT;
CREATE TABLE IF NOT EXISTS dw_tmp.`tmp_dwd_cust_list_plant_apple_mgr_dtl_lszzl` (
  `id` varchar(20) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '主键',
  `sjyid` int(11) DEFAULT NULL COMMENT '所属采集表id',
  `sjymc` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '所属采集表名',
  `pici` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '批次',
  `sheng` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '省',
  `shi` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '市',
  `xian` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '区县',
  `xiang` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '乡镇',
  `cun` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '村庄',
  `xzqhdm` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '行政区划代码',
  `qymc` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '企业名称',
  `nsrsbh` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '纳税人识别号',
  `xm` varchar(100) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '姓名',
  `sfzh` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '身份证号',
  `tel` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '联系电话',
  `ztlx` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '主体类型',
  `zzpz` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '种植种类',
  `zzzl` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '种植品种',
  `cynx` decimal(18,4) DEFAULT NULL COMMENT '从业年限_年',
  `poy_jyr_xm` varchar(100) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '配偶外共同经营人姓名',
  `poy_jyr_sfzh` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '共同经营人身份证号',
  `tdlz` varchar(20) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '土地类型',
  `mj` decimal(18,4) DEFAULT NULL COMMENT '面积',
  `zymj` decimal(18,4) DEFAULT NULL COMMENT '其中：自有面积（亩）',
  `lzmj` decimal(18,4) DEFAULT NULL COMMENT '流转面积（亩）',
  `crf` varchar(100) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '出让方',
  `nd_lzje` decimal(18,4) DEFAULT NULL COMMENT '年度总流转费用（元）',
  `lzhtba` varchar(100) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '流转合同备案',
  `xmkssj` datetime DEFAULT NULL COMMENT '项目开始时间',
  `xmjssj` datetime DEFAULT NULL COMMENT '项目结束时间',
  `mark` varchar(4000) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '备注',
  `sjly` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '数据来源',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `create_user` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '创建用户',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `update_user` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '更新用户',
  `is_delete` int(11) DEFAULT NULL COMMENT '是否删除（1 删除）',
  `is_sfzh_flag` int(11) DEFAULT NULL COMMENT '是否为有效身份证号（1 有效）',
  `xzqh_pp_flag` int(11) DEFAULT NULL COMMENT '行政区划二次匹配标识',
  `is_bl` int(11) DEFAULT NULL,
  `is_hhjy` int(11) DEFAULT NULL COMMENT '是否混合经营(0 否 默认0)',
  `ejpl` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '二级品类',
  KEY `idx_ods_customer_acquisition_yidao_cj_zzy_lszzl_zl_id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='苹果种植类数据';

INSERT INTO dw_tmp.tmp_dwd_cust_list_plant_apple_mgr_dtl_lszzl
(   id
    ,sjyid
    ,sjymc
    ,pici
    ,sheng
    ,shi
    ,xian
    ,xiang
    ,cun
    ,xzqhdm
    ,qymc
    ,nsrsbh
    ,xm
    ,sfzh
    ,tel
    ,ztlx
    ,zzpz
    ,zzzl
    ,cynx
    ,poy_jyr_xm
    ,poy_jyr_sfzh
    ,tdlz
    ,mj
    ,zymj
    ,lzmj
    ,crf
    ,nd_lzje
    ,lzhtba
    ,xmkssj
    ,xmjssj
    ,mark
    ,sjly
    ,create_time
    ,create_user
    ,update_time
    ,update_user
    ,is_delete
    ,is_sfzh_flag
    ,xzqh_pp_flag
    ,is_bl
    ,is_hhjy
    ,ejpl
)
SELECT
id
,sjyid
,sjymc
,pici
,sheng
,shi
,xian
,xiang
,cun
,xzqhdm
,qymc 
,nsrsbh
,xm
,sfzh
,tel
,ztlx
,zzpz
,zzzl
,cynx
,poy_jyr_xm
,poy_jyr_sfzh
,tdlz
,mj
,zymj
,lzmj
,crf
,nd_lzje
,lzhtba
,xmkssj
,xmjssj
,mark
,sjly
,create_time
,create_user
,update_time
,update_user
,is_delete
,is_sfzh_flag
,xzqh_pp_flag
,is_bl
,is_hhjy
,ejpl
FROM(
       SELECT id
             ,sjyid
             ,sjymc
             ,pici
             ,sheng
             ,shi
             ,xian
             ,xiang
             ,cun
             ,xzqhdm
             ,qymc 
             ,nsrsbh
             ,xm
             ,sfzh
             ,tel
             ,ztlx
             ,zzpz
             ,zzzl
             ,cynx
             ,poy_jyr_xm
             ,poy_jyr_sfzh
             ,tdlz
             ,mj
             ,zymj
             ,lzmj
             ,crf
             ,nd_lzje
             ,lzhtba
             ,xmkssj
             ,xmjssj
             ,mark
             ,sjly
             ,create_time
             ,create_user
             ,update_time
             ,update_user
             ,is_delete
             ,is_sfzh_flag
             ,xzqh_pp_flag
             ,is_bl
             ,is_hhjy
             ,ejpl
			 ,row_number() over(partition by qymc, nsrsbh, xm, sfzh, zzzl, year(update_time), sheng, shi, xian ORDER BY t1.update_time DESC, t1.create_time desc) as rk
         FROM dw_nd.ods_customer_acquisition_yidao_cj_zzy_lszzl_zl t1
        INNER JOIN (SELECT DISTINCT area_name FROM dw_base.dim_area_info WHERE length(area_cd) = 6) t2
           ON t1.xian = t2.area_name
        WHERE trim(coalesce(nullif(t1.qymc,''), nullif(t1.nsrsbh,''), nullif(t1.xm,''), t1.sfzh, '')) <> '' -- 4个字段有一个有值就取出
          AND coalesce(t1.mj, t1.lzmj) is not null
          AND t1.zzzl REGEXP '苹果'
		) t3
 where rk = 1
;
COMMIT;

-- 临时表数据落地
drop table if exists dw_tmp.tmp_dwd_cust_list_plant_apple_mgr_dtl_lszzll_cust;
commit;
create table if not exists dw_tmp.tmp_dwd_cust_list_plant_apple_mgr_dtl_lszzll_cust(
  `cust_name` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '姓名',
  `cert_no` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '证件号码',
  `cust_type` varchar(2) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '客户类型1-自然人|2-法人',
  `legal_name` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '法人名称',
  `legal_cert_no` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '法人身份证号',
  `zzzl` varchar(50) DEFAULT NULL COMMENT '种植品类',
  `sjsjnd` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '数据收集年度',
  `sheng` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '省',
  `shi` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '市',
  `xian` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '县',
  `cynx` decimal(18,4) DEFAULT NULL COMMENT '从业年限',
  `mj` decimal(18,4) DEFAULT NULL COMMENT '土地面积(亩)',
  `lzmj` decimal(18,4) DEFAULT NULL COMMENT '土地流转面积(亩)',
  `update_time` datetime DEFAULT NULL COMMENT '数据更新时间',
  `tel_no` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '联系电话',
  `cust_addr` VARCHAR(300) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '详细地址',
  index idx_tmp_dwd_cust_list_plant_apple_mgr_dtl_lszzll_cust_sheng(sheng),
  index idx_tmp_dwd_cust_list_plant_apple_mgr_dtl_lszzll_cust_shi(xian,shi)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='种植品类为苹果的客户数据';

insert into dw_tmp.tmp_dwd_cust_list_plant_apple_mgr_dtl_lszzll_cust
(cust_name,
 cert_no,
 legal_name,
 legal_cert_no,
 zzzl,
 sjsjnd,
 sheng,
 shi,
 xian,
 mj,
 lzmj,
 cynx,
 update_time,
 tel_no,
 cust_addr)
 select REPLACE(REPLACE(REPLACE(TRIM(qymc),char(9),''),char(10),''),char(13),'') AS cust_name, -- 数据清洗放在临时表处理|法人名称脏字符清洗2022.12.26,
        TRIM(nsrsbh) AS cert_no,
        REPLACE(REPLACE(REPLACE(TRIM(xm),char(9),''),char(10),''),char(13),'') AS legal_name,
        TRIM(sfzh) AS legal_cert_no,
        zzzl, sjsjnd, sheng,shi,xian, mj, lzmj, cynx, update_time, trim(tel) as tel_no,
        concat_ws('',sheng, shi, xian, xiang, cun) as cust_addr
   from (
       SELECT qymc, nsrsbh, xm, sfzh, '苹果' AS zzzl, year(update_time) as sjsjnd, sheng, shi, xian, xiang, cun, mj, lzmj, cynx, update_time, tel
         FROM dw_tmp.tmp_dwd_cust_list_plant_apple_mgr_dtl_lszzl
        WHERE REPLACE(REPLACE(REPLACE(TRIM(coalesce(qymc,nsrsbh)),char(9),''),char(10),''),char(13),'') <> '' and coalesce(qymc, nsrsbh) is not null -- 企业名称/纳税人识别号不为空

       UNION ALL
       SELECT xm, sfzh, null, null, '苹果' AS zzzl, year(update_time) as sjsjnd, sheng, shi, xian, xiang, cun, mj, lzmj, cynx, update_time, tel
         FROM dw_tmp.tmp_dwd_cust_list_plant_apple_mgr_dtl_lszzl
        WHERE REPLACE(REPLACE(REPLACE(TRIM(xm),char(9),''),char(10),''),char(13),'') <> '' and coalesce(qymc, nsrsbh) is null -- 企业名称/纳税人识别号为空
        ) t1
;
commit;


-- 3.数据落地
truncate table dw_base.dwd_cust_list_plant_apple_mgr_dtl;
commit;


-- 市管理中心-种植类数据
insert into dw_base.dwd_cust_list_plant_apple_mgr_dtl
(day_id              -- 数据日期'
 ,cust_name          -- 姓名'
 ,cert_no            -- 证件号码'
 ,cust_type          -- 客户类型1-自然人|2-法人'
 ,legal_name         -- 法人名称'
 ,legal_cert_no      -- 法人身份证号'
 ,tel_no             -- 手机号
 ,data_coll_year     -- 数据收集年度'
 ,province_name      -- 省'
 ,province_code      -- 省_行政区划代码'
 ,city_name          -- 市'
 ,city_code          -- 市_行政区划代码'
 ,county_name        -- 县'
 ,county_code        -- 县_行政区划代码'
 ,cust_addr          -- 详细地址
 ,plant_act_period   -- 从业年限
 ,plant_area_num     -- 种植面积
 ,plant_type         -- 种植品类
 ,update_time        -- 数据更新时间
 ,data_source        -- 数据来源'
 ,data_source_name   -- 数据来源中文释义'
 ,is_usable          -- 数据是否可用0-不可用|1-可用'
 )
select day_id           
      ,cust_name       
      ,upper(cert_no) as cert_no     
      ,cust_type       
      ,legal_name      
      ,legal_cert_no   
      ,tel_no          
      ,data_coll_year  
      ,province_name   
      ,province_code   
      ,city_name       
      ,city_code       
      ,county_name     
      ,county_code     
      ,cust_addr       
      ,plant_act_period
      ,plant_area_num  
      ,plant_type      
      ,update_time     
      ,data_source     
      ,data_source_name
      ,is_usable       
 from (
        select '${v_sdate}' AS day_id
               ,t1.cust_name
               ,t1.cert_no
               ,CASE WHEN upper(LEFT(t1.cert_no,1)) IN ('9', 'N') THEN '2' ELSE '1' END AS cust_type
               ,t1.legal_name
               ,t1.legal_cert_no
               ,t1.tel_no
               ,t1.sjsjnd as data_coll_year
               ,t1.sheng  as province_name
               ,t3.area_cd AS province_code
               ,t1.shi  as city_name
               ,t2.sup_area_cd AS city_code
               ,t1.xian as county_name
               ,t2.area_cd AS county_code
               ,t1.cust_addr
               ,max(t1.cynx) as plant_act_period
               ,sum(coalesce(t1.mj,t1.lzmj)) as plant_area_num
               ,'苹果' as plant_type
               ,t1.update_time
               ,'ods_customer_acquisition_yidao_cj_zzy_lszzl_zl' as data_source
               ,'2022年种植类采集数据' as data_source_name
               ,'1' as is_usable
			   ,row_number() over(partition by t1.cert_no, t1.sjsjnd order by update_time desc) as rk
          from dw_tmp.tmp_dwd_cust_list_plant_apple_mgr_dtl_lszzll_cust t1
         INNER JOIN (SELECT area_cd, area_name, sup_area_cd, sup_area_name FROM dw_base.dim_area_info WHERE LENGTH(area_cd) = 6) t2
            ON t1.xian = t2.area_name and t1.shi = t2.sup_area_name
         INNER JOIN (SELECT area_cd, area_name FROM dw_base.dim_area_info WHERE LENGTH(area_cd) = 6) t3
            ON t1.sheng = t3.area_name
         GROUP BY t1.cust_name, t1.cert_no, t1.zzzl, t1.sjsjnd, t1.sheng, t1.shi, t1.xian
          ) t
 where rk = 1
 ;
commit;


delete from dw_base.dwd_cust_list_plant_apple_mgr_dtl
where cust_type = '1' and data_source = 'ods_customer_acquisition_yidao_cj_zzy_lszzl_zl' and
( 
cert_no is  null    -- 身份证空
or length(replace(cert_no,' ',''))<>18
or substr(cert_no,1,17) not REGEXP '[0-9]'  -- 身份证前17位不只有数字
or date(substr(cert_no,7,8)) is null    -- 生日字段填写不正确
or TIMESTAMPDIFF(year,date(substr(cert_no,7,8)),now()) is null 
or TIMESTAMPDIFF(year,date(substr(cert_no,7,8)),now())<18   -- 年龄<18周岁
or TIMESTAMPDIFF(year,date(substr(cert_no,7,8)),now())>65   -- 年龄>65周岁
or (substr(cert_no,1,2)+0<11 or substr(cert_no,1,2)+0>82)   -- 身份证省份字段不在11-82之间
or 
mod(substr(cert_no,1,1)*7+
substr(cert_no,2,1)*9+
substr(cert_no,3,1)*10+
substr(cert_no,4,1)*5+
substr(cert_no,5,1)*8+
substr(cert_no,6,1)*4+
substr(cert_no,7,1)*2+
substr(cert_no,8,1)*1+
substr(cert_no,9,1)*6+
substr(cert_no,10,1)*3+
substr(cert_no,11,1)*7+
substr(cert_no,12,1)*9+
substr(cert_no,13,1)*10+
substr(cert_no,14,1)*5+
substr(cert_no,15,1)*8+
substr(cert_no,16,1)*4+
substr(cert_no,17,1)*2
,11)<>
(case 
when substr(cert_no,18,1)='1' then '0'
when substr(cert_no,18,1)='0' then '1'
when substr(cert_no,18,1) in ('X','x') then '2'
when substr(cert_no,18,1)='9' then '3'
when substr(cert_no,18,1)='8' then '4'
when substr(cert_no,18,1)='7' then '5'
when substr(cert_no,18,1)='6' then '6'
when substr(cert_no,18,1)='5' then '7'
when substr(cert_no,18,1)='4' then '8'
when substr(cert_no,18,1)='3' then '9'
when substr(cert_no,18,1)='2' then '10'
else -99 end)

);
commit;
  
  

-- 烟台农科院大数据平台数据
insert into dw_base.dwd_cust_list_plant_apple_mgr_dtl
(day_id              -- 数据日期'
 ,cust_name          -- 姓名'
 ,cert_no            -- 证件号码'
 ,cust_type          -- 客户类型1-自然人|2-法人'
 ,legal_name         -- 法人名称'
 ,legal_cert_no      -- 法人身份证号'
 ,tel_no             -- 手机号
 ,data_coll_year     -- 数据收集年度'
 ,province_name      -- 省'
 ,province_code      -- 省_行政区划代码'
 ,city_name          -- 市'
 ,city_code          -- 市_行政区划代码'
 ,county_name        -- 县'
 ,county_code        -- 县_行政区划代码'
 ,cust_addr          -- 详细地址
 ,plant_act_period   -- 从业年限
 ,plant_area_num     -- 种植面积
 ,plant_type         -- 种植品类
 ,update_time        -- 数据更新时间
 ,data_source        -- 数据来源'
 ,data_source_name   -- 数据来源中文释义'
 ,is_usable          -- 数据是否可用0-不可用|1-可用'
 )
select '${v_sdate}' AS day_id
       ,t1.name as cust_name
       ,upper(t1.cert_no) as cert_no
       ,'1'
       ,null
       ,null
       ,tel_no
       ,'2022'
       ,t1.province as province_name
       ,t2.area_cd as province_code
       ,t1.city as city_name
       ,coalesce(t3.area_cd, '379900') as city_code
       ,t1.country as county_name
       ,coalesce(t4.area_cd,concat(left(t3.area_cd,4),'99'), '379999') as county_code
       ,t1.addr as cust_addr
       ,null
       ,case when count(distinct addr) = 1 then min(area_num) else sum(area_num) end as plant_area_num -- 证件号、地址相同，取小；证件号相同，地址不同，求和
       ,'苹果'
       ,str_to_date('2022-11-08 00:00:00', '%Y-%m-%d %H:%i:%s') as update_time
       ,'ods_imp_ag_info_apple_yt_caas_standard'
       ,'烟台农科院大数据平台'
       ,'1'
  from dw_tmp.tmp_dwd_cust_list_plant_apple_mgr_dtl_caas_standard t1
  left join dw_base.dim_area_info t2
    on t1.province = t2.area_name
  left join dw_base.dim_area_info t3
    on t1.city = t3.area_name
  left join dw_base.dim_area_info t4
    on t1.country = t4.area_name
 where coalesce(province, '') <> '' and coalesce(city, '') <> '' and coalesce(country, '')<> ''     -- 省/城市/区县不为空
 group by cert_no
having count(distinct name ) = 1 -- 剔除证件号相同名字不同的客户
;
commit;


