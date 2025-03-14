-- ---------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20221130
-- 目标表   ：dwd_cust_list_plant_land_transfer_dtl
-- 源表     ：dw_nd.ods_coll_v_ods_jcny_tdlz    dw_nd.ods_customer_acquisition_yidao_cj_zzy_lszzl_zl    dw_base.dim_area_info
-- 备注     ：小麦玉米种植的土地流转数据加工
-- 修改记录 ：20230111 zhangfl ①增加字段联系电话 tel_no；②修改数据源 ods_customer_acquisition_yidao_cj_zzy_lszzl_zl 对应的字段data_source_name值为“2022年种植类采集数据”
--            20230317 zhangfl 增加字段，是否担保客户 is_guar_cust
--            20230504 zhangfl 2022年种植采集数据源,相同年度/种植种类/相同证件号去重处理；所有数据个人客户证件号校验处理
--            20230601 zhangfl 优化历史数据的插入逻辑，只保留推送给名单管理系统的数据，where 条件同 ETL 推送脚本
--            20231218 wangyj 证件号转大写
-- ---------------------------------------
-- 农业厅--基层农业土地流转数据
truncate table dw_base.dwd_cust_list_plant_land_transfer_dtl ;
COMMIT;
INSERT INTO dw_base.dwd_cust_list_plant_land_transfer_dtl
( day_id
,cust_name
,cert_no
,cust_type
,legal_name
,legal_cert_no
,data_col_year
,province_name
,province_code
,city_name
,city_code
,conty_name
,county_code
,transfer_area_num
,update_time
,data_source
,data_source_name
,is_usable
,is_guar_cust
,tel_no)
SELECT  '${v_sdate}' as day_id
       ,CASE WHEN t4.dw IN ('个人','单位') THEN REPLACE(REPLACE(REPLACE(TRIM(t4.frdb),char(9),''),char(10),''),char(13),'') 
             ELSE REPLACE(REPLACE(REPLACE(TRIM(t4.dw),char(9),''),char(10),''),char(13),'')  END AS cust_name
       ,upper(t4.sfzh_tyshxydm) AS cert_no
       ,CASE WHEN t4.dw = '个人' THEN '1' WHEN t4.dw = '单位' THEN '2' 
             WHEN upper(LEFT(t4.sfzh_tyshxydm,1)) IN ('9', 'N') THEN '2' ELSE '1' END AS cust_type
       ,CASE WHEN t4.dw = '单位' THEN null WHEN upper(LEFT(t4.sfzh_tyshxydm,1)) IN ('9', 'N') THEN t4.frdb ELSE '' END AS legal_name
       ,CASE WHEN t4.dw = '单位' THEN null WHEN upper(LEFT(t4.sfzh_tyshxydm,1)) IN ('9', 'N') THEN t4.frdb_sfzh ELSE '' END AS legal_cert_no
       ,t4.nd AS sjsjnd
       ,t4.sheng
       ,t6.area_cd AS sheng_qhdm
       ,t4.shi
       ,t5.sup_area_cd AS shi_qhdm
       ,t4.qx AS xian
       ,t5.area_cd as xian_qhdm
       ,LEAST(CASE WHEN COALESCE(t4.zzmj_m,0) = 0 THEN 999999999 ELSE t4.zzmj_m END, 
              CASE WHEN COALESCE(t4.lztdmj,0) = 0 THEN 999999999 ELSE t4.lztdmj END, 
              CASE WHEN COALESCE(t4.jyqbzmj,0)= 0 THEN 999999999 ELSE t4.jyqbzmj END) AS lzmj
       ,t4.update_time
       ,'ods_coll_v_ods_jcny_tdlz' AS data_source
	   ,'农业厅--基层农业土地流转数据' as data_source_name
	   ,'1'
       ,case when t7.cert_no is not null then '1' else '0' end as is_guar_cust
       ,tel_no
  FROM(
  
     SELECT * FROM(
            SELECT t1.dw, t1.sfzh_tyshxydm, t1.frdb, t1.frdb_sfzh, t1.nd, t1.qx, t1.zzmj_m, t1.lztdmj, t1.jyqbzmj, t1.update_time,
                   t1.sheng, t1.shi, trim(t1.tel) as tel_no
				   ,row_number() over(partition by CASE WHEN t1.dw IN ('个人','单位') THEN t1.frdb ELSE t1.dw END, t1.sfzh_tyshxydm, t1.nd, t1.qx ORDER BY t1.update_time DESC) as rk
              FROM dw_nd.ods_coll_v_ods_jcny_tdlz t1
			  left join(
					select sfzh_tyshxydm 
					from dw_nd.ods_coll_v_ods_jcny_tdlz tt2
					group by tt2.sfzh_tyshxydm
					having count(distinct case when tt2.dw IN ('个人','单位') THEN tt2.frdb ELSE tt2.dw END)>1
				) t2 on t1.sfzh_tyshxydm=t2.sfzh_tyshxydm
             WHERE t1.qx is not null
               AND COALESCE(t1.zzmj_m,0)+COALESCE(t1.lztdmj,0)+COALESCE(t1.jyqbzmj,0) > 0
               AND LENGTH(t1.sfzh_tyshxydm) = 18
               AND TRIM(COALESCE(t1.dw, t1.frdb, '')) <> ''
			   -- 20240617 新增条件 0<=当前年度-数据收集年度<=1
			   and year(now())-t1.nd>=0
			   and year(now())-t1.nd<=1
			   and t2.sfzh_tyshxydm is null -- 去掉所有一个证件号对应多个名字的记录
			 ) t3
      where t3.rk = 1 ) t4

 INNER JOIN (SELECT area_cd, area_name, sup_area_cd, sup_area_name FROM dw_base.dim_area_info WHERE LENGTH(area_cd) = 6) t5
    ON t4.qx = t5.area_name and t4.shi = t5.sup_area_name
 INNER JOIN (SELECT area_cd, area_name FROM dw_base.dim_area_info WHERE LENGTH(area_cd) = 6) t6
    ON t4.sheng = t6.area_name
 LEFT JOIN (SELECT cert_no FROM dw_base.dwd_guar_info_all GROUP BY cert_no) t7
   ON t4.sfzh_tyshxydm = t7.cert_no
 GROUP BY CASE WHEN t4.dw IN ('个人','单位') THEN t4.frdb ELSE t4.dw END, t4.sfzh_tyshxydm, t4.nd, t4.qx
 ;
COMMIT;
 
-- 粮食种植类数据
DROP TABLE IF EXISTS dw_tmp.tmp_dwd_cust_list_plant_land_transfer_dtl_lszzl;
COMMIT;
CREATE TABLE IF NOT EXISTS dw_tmp.`tmp_dwd_cust_list_plant_land_transfer_dtl_lszzl` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='种植类数据';

-- 建立重复数据临时表,用来优化查询
-- 去除同一身份证对应多个姓名
-- 去除同一纳税人识别号对应多个企业名称
drop table if exists dw_tmp.tmp_yidao_cj_zzy_lszzl_zl_duplicate;
CREATE TABLE dw_tmp.tmp_yidao_cj_zzy_lszzl_zl_duplicate (
  `qymc` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '企业名称',
  `nsrsbh` varchar(100) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '纳税人识别号',
  `xm` varchar(100) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '姓名',
  `sfzh` varchar(100) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '身份证号',
  `duplicate_type` varchar(100) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '重复类型',
  KEY `inx_tmp_yidao_cj_zzy_lszzl_zl_duplicate_sfzh` (`sfzh`) USING BTREE,
  KEY `inx_tmp_yidao_cj_zzy_lszzl_zl_duplicate_nsrsbh` (`nsrsbh`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='种植类数据重复数据临时表';

insert into dw_tmp.tmp_yidao_cj_zzy_lszzl_zl_duplicate
select qymc,nsrsbh,xm,sfzh,'姓名重复'
FROM dw_nd.ods_customer_acquisition_yidao_cj_zzy_lszzl_zl
group by sfzh
having count(distinct trim(xm))>1
union all
select qymc,nsrsbh,xm,sfzh,'企业名称重复'
FROM dw_nd.ods_customer_acquisition_yidao_cj_zzy_lszzl_zl
group by nsrsbh
having count(distinct trim(qymc))>1;

INSERT INTO dw_tmp.tmp_dwd_cust_list_plant_land_transfer_dtl_lszzl
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
,t1.qymc
,t1.nsrsbh
,t1.xm
,t1.sfzh
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
             ,t1.qymc
             ,t1.nsrsbh
             ,t1.xm
             ,t1.sfzh
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
			 ,row_number() over(partition by t1.qymc, t1.nsrsbh, t1.xm, t1.sfzh, zzzl, year(update_time),xian ORDER BY t1.update_time DESC, t1.create_time desc) as rk
         FROM dw_nd.ods_customer_acquisition_yidao_cj_zzy_lszzl_zl t1
		 left join dw_tmp.tmp_yidao_cj_zzy_lszzl_zl_duplicate t3 on t1.sfzh=t3.sfzh and t3.duplicate_type='姓名重复'
         left join dw_tmp.tmp_yidao_cj_zzy_lszzl_zl_duplicate t4 on t1.nsrsbh=t4.nsrsbh and t4.duplicate_type='企业名称重复'
        INNER JOIN (SELECT DISTINCT area_name FROM dw_base.dim_area_info WHERE length(area_cd) = 6) t2
           ON t1.xian = t2.area_name
        WHERE trim(coalesce(t1.qymc, t1.nsrsbh, t1.xm, t1.sfzh, '')) <> '' -- 4个字段有一个有值就取出
		   -- REPLACE(REPLACE(REPLACE(TRIM(COALESCE(t1.qymc, t1.xm, '')),char(9),''),char(10),''),char(13),'') <> '' AND LENGTH(COALESCE(t1.nsrsbh, t1.sfzh))=18
          AND coalesce(t1.mj,t1.lzmj) > 0
          AND t1.zzzl REGEXP '小麦|玉米|稻谷|水稻|大豆|毛豆|土豆|马铃薯|地瓜|甘薯|红薯|山药|蚕豆|豌豆|绿豆|小豆|豆类|谷子|高粱|大麦|燕麦'
          AND t1.zzzl not REGEXP '购销|加工|收购|销售'
		  -- 20240617 新增条件 0<=当前年度-数据收集年度<=1
		  and year(now())-year(update_time)>=0
		  and year(now())-year(update_time)<=1
		  and t3.sfzh is null -- 20240521 去掉所有一个证件号对应多个名字的记录
          and t4.nsrsbh is null
        ) t1
 where rk = 1
;
COMMIT;

-- 临时表数据落地
drop table if exists dw_tmp.tmp_dwd_cust_list_plant_land_transferdtl_lszzl_cust;
commit;
create table if not exists dw_tmp.tmp_dwd_cust_list_plant_land_transferdtl_lszzl_cust(
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
  index idx_tmp_dwd_cust_list_plant_land_transferdtl_lszzl_cust_sheng(sheng),
  index idx_tmp_dwd_cust_list_plant_land_transferdtl_lszzl_cust_shi(shi)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='种植品类为小麦玉米的客户数据';

insert into dw_tmp.tmp_dwd_cust_list_plant_land_transferdtl_lszzl_cust
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
 tel_no)
 select REPLACE(REPLACE(REPLACE(TRIM(qymc),char(9),''),char(10),''),char(13),'') AS cust_name, -- 数据清洗放在临时表处理|法人名称脏字符清洗2022.12.26,
        TRIM(nsrsbh) AS cert_no,
        REPLACE(REPLACE(REPLACE(TRIM(xm),char(9),''),char(10),''),char(13),'') AS legal_name,
        TRIM(sfzh) AS legal_cert_no,
        zzzl, sjsjnd, sheng,shi,xian, mj, lzmj, cynx, update_time, trim(tel) as tel_no
   from (
SELECT qymc, nsrsbh, xm, sfzh, '小麦种植' AS zzzl, year(update_time) as sjsjnd, sheng, shi, xian, mj, lzmj, cynx, update_time, tel
         FROM dw_tmp.tmp_dwd_cust_list_plant_land_transfer_dtl_lszzl
        WHERE zzzl LIKE '%小麦%'
          and REPLACE(REPLACE(REPLACE(TRIM(coalesce(qymc,nsrsbh)),char(9),''),char(10),''),char(13),'') <> '' and coalesce(qymc, nsrsbh) is not null -- 企业名称/纳税人识别号不为空
        UNION ALL
       SELECT qymc, nsrsbh, xm, sfzh, '玉米种植' AS zzzl, year(update_time) as sjsjnd, sheng, shi, xian, mj, lzmj, cynx, update_time, tel
         FROM dw_tmp.tmp_dwd_cust_list_plant_land_transfer_dtl_lszzl
        WHERE zzzl LIKE '%玉米%'
          and REPLACE(REPLACE(REPLACE(TRIM(coalesce(qymc,nsrsbh)),char(9),''),char(10),''),char(13),'') <> '' and coalesce(qymc, nsrsbh) is not null
				UNION ALL
       SELECT qymc, nsrsbh, xm, sfzh, '稻谷种植' AS zzzl, year(update_time) as sjsjnd, sheng, shi, xian, mj, lzmj, cynx, update_time, tel
         FROM dw_tmp.tmp_dwd_cust_list_plant_land_transfer_dtl_lszzl
        WHERE (zzzl LIKE '%稻谷%' or zzzl LIKE '%水稻%')
          and REPLACE(REPLACE(REPLACE(TRIM(coalesce(qymc,nsrsbh)),char(9),''),char(10),''),char(13),'') <> '' and coalesce(qymc, nsrsbh) is not null
				UNION ALL
       SELECT qymc, nsrsbh, xm, sfzh, '大豆种植' AS zzzl, year(update_time) as sjsjnd, sheng, shi, xian, mj, lzmj, cynx, update_time, tel
         FROM dw_tmp.tmp_dwd_cust_list_plant_land_transfer_dtl_lszzl
        WHERE (zzzl LIKE '%大豆%' or zzzl LIKE '%毛豆%')
          and REPLACE(REPLACE(REPLACE(TRIM(coalesce(qymc,nsrsbh)),char(9),''),char(10),''),char(13),'') <> '' and coalesce(qymc, nsrsbh) is not null
				UNION ALL
       SELECT qymc, nsrsbh, xm, sfzh, '马铃薯种植' AS zzzl, year(update_time) as sjsjnd, sheng, shi, xian, mj, lzmj, cynx, update_time, tel
         FROM dw_tmp.tmp_dwd_cust_list_plant_land_transfer_dtl_lszzl
        WHERE (zzzl LIKE '%土豆%' or zzzl LIKE '%马铃薯%')
          and REPLACE(REPLACE(REPLACE(TRIM(coalesce(qymc,nsrsbh)),char(9),''),char(10),''),char(13),'') <> '' and coalesce(qymc, nsrsbh) is not null
				UNION ALL
       SELECT qymc, nsrsbh, xm, sfzh, '甘薯种植' AS zzzl, year(update_time) as sjsjnd, sheng, shi, xian, mj, lzmj, cynx, update_time, tel
         FROM dw_tmp.tmp_dwd_cust_list_plant_land_transfer_dtl_lszzl
        WHERE (zzzl LIKE '%地瓜%' or zzzl LIKE '%甘薯%' or zzzl LIKE '%红薯%')
          and REPLACE(REPLACE(REPLACE(TRIM(coalesce(qymc,nsrsbh)),char(9),''),char(10),''),char(13),'') <> '' and coalesce(qymc, nsrsbh) is not null
				UNION ALL
       SELECT qymc, nsrsbh, xm, sfzh, '山药种植' AS zzzl, year(update_time) as sjsjnd, sheng, shi, xian, mj, lzmj, cynx, update_time, tel
         FROM dw_tmp.tmp_dwd_cust_list_plant_land_transfer_dtl_lszzl
        WHERE zzzl LIKE '%山药%'
          and REPLACE(REPLACE(REPLACE(TRIM(coalesce(qymc,nsrsbh)),char(9),''),char(10),''),char(13),'') <> '' and coalesce(qymc, nsrsbh) is not null
				UNION ALL
       SELECT qymc, nsrsbh, xm, sfzh, '其他豆类种植' AS zzzl, year(update_time) as sjsjnd, sheng, shi, xian, mj, lzmj, cynx, update_time, tel
         FROM dw_tmp.tmp_dwd_cust_list_plant_land_transfer_dtl_lszzl
        WHERE (zzzl LIKE '%蚕豆%' or zzzl LIKE '%豌豆%' or zzzl LIKE '%绿豆%' or zzzl LIKE '%小豆%' or zzzl LIKE '%豆类%')
          and REPLACE(REPLACE(REPLACE(TRIM(coalesce(qymc,nsrsbh)),char(9),''),char(10),''),char(13),'') <> '' and coalesce(qymc, nsrsbh) is not null
				UNION ALL
       SELECT qymc, nsrsbh, xm, sfzh, '其他谷物种植' AS zzzl, year(update_time) as sjsjnd, sheng, shi, xian, mj, lzmj, cynx, update_time, tel
         FROM dw_tmp.tmp_dwd_cust_list_plant_land_transfer_dtl_lszzl
        WHERE (zzzl LIKE '%谷子%' or zzzl LIKE '%高粱%' or zzzl LIKE '%大麦%' or zzzl LIKE '%燕麦%')
          and REPLACE(REPLACE(REPLACE(TRIM(coalesce(qymc,nsrsbh)),char(9),''),char(10),''),char(13),'') <> '' and coalesce(qymc, nsrsbh) is not null
        
       UNION ALL
       SELECT xm, sfzh, null, null, '小麦种植' AS zzzl, year(update_time) as sjsjnd, sheng, shi, xian, mj, lzmj, cynx, update_time, tel
         FROM dw_tmp.tmp_dwd_cust_list_plant_land_transfer_dtl_lszzl
        WHERE zzzl LIKE '%小麦%'
          and REPLACE(REPLACE(REPLACE(TRIM(xm),char(9),''),char(10),''),char(13),'') <> '' and coalesce(qymc, nsrsbh) is null -- 企业名称/纳税人识别号为空
        UNION ALL
       SELECT xm, sfzh, null, null, '玉米种植' AS zzzl, year(update_time) as sjsjnd, sheng, shi, xian, mj, lzmj, cynx, update_time, tel
         FROM dw_tmp.tmp_dwd_cust_list_plant_land_transfer_dtl_lszzl
        WHERE zzzl LIKE '%玉米%'
          and REPLACE(REPLACE(REPLACE(TRIM(xm),char(9),''),char(10),''),char(13),'') <> '' and coalesce(qymc, nsrsbh) is null
        UNION ALL
       SELECT xm, sfzh, null, null, '稻谷种植' AS zzzl, year(update_time) as sjsjnd, sheng, shi, xian, mj, lzmj, cynx, update_time, tel
         FROM dw_tmp.tmp_dwd_cust_list_plant_land_transfer_dtl_lszzl
        WHERE (zzzl LIKE '%稻谷%' or zzzl LIKE '%水稻%')
          and REPLACE(REPLACE(REPLACE(TRIM(xm),char(9),''),char(10),''),char(13),'') <> '' and coalesce(qymc, nsrsbh) is null
				UNION ALL
       SELECT xm, sfzh, null, null, '大豆种植' AS zzzl, year(update_time) as sjsjnd, sheng, shi, xian, mj, lzmj, cynx, update_time, tel
         FROM dw_tmp.tmp_dwd_cust_list_plant_land_transfer_dtl_lszzl
        WHERE (zzzl LIKE '%大豆%' or zzzl LIKE '%毛豆%')
          and REPLACE(REPLACE(REPLACE(TRIM(xm),char(9),''),char(10),''),char(13),'') <> '' and coalesce(qymc, nsrsbh) is null
				UNION ALL
       SELECT xm, sfzh, null, null, '马铃薯种植' AS zzzl, year(update_time) as sjsjnd, sheng, shi, xian, mj, lzmj, cynx, update_time, tel
         FROM dw_tmp.tmp_dwd_cust_list_plant_land_transfer_dtl_lszzl
        WHERE (zzzl LIKE '%土豆%' or zzzl LIKE '%马铃薯%')
          and REPLACE(REPLACE(REPLACE(TRIM(xm),char(9),''),char(10),''),char(13),'') <> '' and coalesce(qymc, nsrsbh) is null
				UNION ALL
       SELECT xm, sfzh, null, null, '甘薯种植' AS zzzl, year(update_time) as sjsjnd, sheng, shi, xian, mj, lzmj, cynx, update_time, tel
         FROM dw_tmp.tmp_dwd_cust_list_plant_land_transfer_dtl_lszzl
        WHERE (zzzl LIKE '%地瓜%' or zzzl LIKE '%甘薯%' or zzzl LIKE '%红薯%')
          and REPLACE(REPLACE(REPLACE(TRIM(xm),char(9),''),char(10),''),char(13),'') <> '' and coalesce(qymc, nsrsbh) is null
				UNION ALL
       SELECT xm, sfzh, null, null, '山药种植' AS zzzl, year(update_time) as sjsjnd, sheng, shi, xian, mj, lzmj, cynx, update_time, tel
         FROM dw_tmp.tmp_dwd_cust_list_plant_land_transfer_dtl_lszzl
        WHERE zzzl LIKE '%山药%'
          and REPLACE(REPLACE(REPLACE(TRIM(xm),char(9),''),char(10),''),char(13),'') <> '' and coalesce(qymc, nsrsbh) is null
				UNION ALL
       SELECT xm, sfzh, null, null, '其他豆类种植' AS zzzl, year(update_time) as sjsjnd, sheng, shi, xian, mj, lzmj, cynx, update_time, tel
         FROM dw_tmp.tmp_dwd_cust_list_plant_land_transfer_dtl_lszzl
        WHERE (zzzl LIKE '%蚕豆%' or zzzl LIKE '%豌豆%' or zzzl LIKE '%绿豆%' or zzzl LIKE '%小豆%' or zzzl LIKE '%豆类%')
          and REPLACE(REPLACE(REPLACE(TRIM(xm),char(9),''),char(10),''),char(13),'') <> '' and coalesce(qymc, nsrsbh) is null
				UNION ALL
       SELECT xm, sfzh, null, null, '其他谷物种植' AS zzzl, year(update_time) as sjsjnd, sheng, shi, xian, mj, lzmj, cynx, update_time, tel
         FROM dw_tmp.tmp_dwd_cust_list_plant_land_transfer_dtl_lszzl
        WHERE (zzzl LIKE '%谷子%' or zzzl LIKE '%高粱%' or zzzl LIKE '%大麦%' or zzzl LIKE '%燕麦%')
          and REPLACE(REPLACE(REPLACE(TRIM(xm),char(9),''),char(10),''),char(13),'') <> '' and coalesce(qymc, nsrsbh) is null
		  
		  ) t
;
commit;



-- 数据落地
INSERT INTO dw_base.dwd_cust_list_plant_land_transfer_dtl
( day_id
,cust_name
,cert_no
,cust_type
,legal_name
,legal_cert_no
,data_col_year
,province_name
,province_code
,city_name
,city_code
,conty_name
,county_code
,transfer_area_num
,plant_type
,update_time
,data_source
,data_source_name
,is_usable
,is_guar_cust
,tel_no
)
SELECT  day_id
       ,cust_name
       ,upper(cert_no) as cert_no
       ,cust_type
       ,legal_name
       ,legal_cert_no
       ,data_col_year
       ,province_name
       ,province_code
       ,city_name
       ,city_code
       ,conty_name
       ,county_code
       ,transfer_area_num
       ,plant_type
       ,update_time
       ,data_source
       ,data_source_name
       ,is_usable
       ,is_guar_cust
       ,tel_no
  from (
         SELECT  '${v_sdate}' AS day_id
                ,t1.cust_name
                ,t1.cert_no
                ,CASE WHEN upper(LEFT(trim(t1.cert_no),1)) IN ('9', 'N') THEN '2' ELSE '1' END AS cust_type
                ,t1.legal_name
                ,t1.legal_cert_no
                ,t1.sjsjnd as data_col_year
                ,t1.sheng as province_name
                ,t3.area_cd AS province_code
                ,t1.shi as city_name
                ,t2.sup_area_cd AS city_code
                ,t1.xian as conty_name
                ,t2.area_cd AS county_code
                ,coalesce(t1.mj,t1.lzmj) as transfer_area_num
                ,t1.zzzl AS plant_type
                ,t1.update_time
                ,'ods_customer_acquisition_yidao_cj_zzy_lszzl_zl' AS data_source
                ,'2022年种植类采集数据' as data_source_name
         	   ,'1' as is_usable
                ,case when t4.cert_no is not null then '1' else '0' end as is_guar_cust
                ,t1.tel_no
				,row_number() over(partition by t1.cert_no,t1.zzzl,t1.sjsjnd order by update_time desc) as rk
           FROM dw_tmp.tmp_dwd_cust_list_plant_land_transferdtl_lszzl_cust t1
          INNER JOIN (SELECT area_cd, area_name, sup_area_cd, sup_area_name FROM dw_base.dim_area_info WHERE LENGTH(area_cd) = 6) t2
             ON t1.xian = t2.area_name and t1.shi = t2.sup_area_name
          INNER JOIN (SELECT area_cd, area_name FROM dw_base.dim_area_info WHERE LENGTH(area_cd) = 6) t3
             ON t1.sheng = t3.area_name
          LEFT JOIN (SELECT cert_no FROM dw_base.dwd_guar_info_all GROUP BY cert_no) t4
            ON t1.cert_no = t4.cert_no
          GROUP BY t1.cust_name, t1.cert_no, t1.zzzl, t1.sjsjnd, t1.xian
           ) t
where rk = 1
;
COMMIT;

-- 20230504 add 个人客户身份证校验
delete from dw_base.dwd_cust_list_plant_land_transfer_dtl
where cust_type = '1' and
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

-- 更新数据的是否可用
-- 主体名称或者主体证件号码为空/不为18位的不可用
update dw_base.dwd_cust_list_plant_land_transfer_dtl set is_usable = '0' 
where cust_name is null or cert_no is null or length(cert_no) <> 18;
commit;
-- 客户类型为 2-企业的，法人证件号为企业统一社会信用代码的不可用
update dw_base.dwd_cust_list_plant_land_transfer_dtl set is_usable = '0' 
where cust_type = '2' and upper(left(legal_cert_no,1)) in ('9','N');
commit;
-- 电话号码不为11位的更新为null -- 2023.01.11
update dw_base.dwd_cust_list_plant_land_transfer_dtl set tel_no = null
where length(tel_no) <> 11;
commit; 


-- 保存历史
delete from dw_base.dwd_cust_list_plant_land_transfer_dtl_his where day_id='${v_sdate}';
commit;
insert into dw_base.dwd_cust_list_plant_land_transfer_dtl_his
(
day_id
,cust_name
,cert_no
,cust_type
,legal_name
,legal_cert_no
,data_col_year
,province_name
,province_code
,city_name
,city_code
,conty_name
,county_code
,transfer_area_num
,plant_type
,update_time
,data_source
,data_source_name
,is_usable
,is_guar_cust
,tel_no
)
select 
day_id
,cust_name
,cert_no
,cust_type
,legal_name
,legal_cert_no
,data_col_year
,province_name
,province_code
,city_name
,city_code
,conty_name
,county_code
,transfer_area_num
,plant_type
,update_time
,data_source
,data_source_name
,is_usable
,is_guar_cust
,tel_no
from  dw_base.dwd_cust_list_plant_land_transfer_dtl
WHERE is_usable = 1 -- 数据可用
  AND ((cust_type = 1 and length(cust_name)<=12) or (cust_type = 2 and length(cust_name) > 12)) -- 自然人名称不超过4个汉字/企业名称超过4个汉字
  AND year(now()) - data_col_year <= 1 -- 数据收集年度与当前年度相差不超过1年
GROUP BY cert_no, cust_name, data_col_year, data_source, plant_type 
HAVING SUM(transfer_area_num) >= 70 -- 按照客户、数据收集年度、数据来源、种植品类4个字段分组对土地流转面积求和 >70亩
;
commit;