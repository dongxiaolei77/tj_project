-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250421
-- 目标表   ：dw_base.ads_rpt_tjnd_imd_guar_financing_direction_stat    综合部-融资担保公司主要业务融资投向统计表
-- 源表     ：
--          新业务系统
--          dw_base.dwd_guar_info_all           担保台账信息
--          dw_base.dwd_guar_info_onguar        担保台账在保信息
--          dw_nd.ods_t_biz_project_main        主项目表
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 重跑策略
delete
from dw_base.ads_rpt_tjnd_imd_guar_financing_direction_stat
where day_id = '${v_sdate}';
commit;

-- 1.插入融资担保业务总计数据
insert into dw_base.ads_rpt_tjnd_imd_guar_financing_direction_stat
(day_id, -- 数据日期
 stat_type, -- 统计类型
 all_onguar_amt, -- 合计-在保余额(万元)
 big_corp_onguar_amt, -- 大型企业-在保余额(万元)
 medium_corp_onguar_amt, -- 中型企业-在保余额(万元)
 small_corp_onguar_amt, -- 小型企业-在保余额(万元)
 micro_corp_onguar_amt, -- 微型企业-在保余额(万元)
 other_onguar_amt -- 其他(住户,广义政府和境外)-在保余额(万元)
)
select '${v_sdate}'                                                       as day_id,
       '融资担保业务总计'                                                         as stat_type,
       sum(onguar_amt)                                                    as all_onguar_amt,
       sum(case when enterprise_scale = '01' then onguar_amt else 0 end)  as big_corp_onguar_amt,
       sum(case when enterprise_scale = '02' then onguar_amt else 0 end)  as medium_corp_onguar_amt,
       sum(case when enterprise_scale = '03' then onguar_amt else 0 end)  as small_corp_onguar_amt,
       sum(case when enterprise_scale = '04' then onguar_amt else 0 end)  as micro_corp_onguar_amt,
       sum(case when enterprise_scale is null then onguar_amt else 0 end) as other_onguar_amt
from (
         select guar_id
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
     ) t1
         left join
     (
         select guar_id,
                onguar_amt -- 在保余额(万元)
         from dw_base.dwd_guar_info_onguar
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select code,             -- 项目id
                enterprise_scale, -- 企业规模
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main) t1
         where rn = 1
     ) t3 on t1.guar_id = t3.code;
commit;

-- 2.插入农、林、牧、渔业合计数据
insert into dw_base.ads_rpt_tjnd_imd_guar_financing_direction_stat
(day_id, -- 数据日期
 stat_type, -- 统计类型
 all_onguar_amt, -- 合计-在保余额(万元)
 big_corp_onguar_amt, -- 大型企业-在保余额(万元)
 medium_corp_onguar_amt, -- 中型企业-在保余额(万元)
 small_corp_onguar_amt, -- 小型企业-在保余额(万元)
 micro_corp_onguar_amt, -- 微型企业-在保余额(万元)
 other_onguar_amt -- 其他(住户,广义政府和境外)-在保余额(万元)
)
select '${v_sdate}'                                                       as day_id,
       '农、林、牧、渔业合计'                                                         as stat_type,
       sum(onguar_amt)                                                    as all_onguar_amt,
       sum(case when enterprise_scale = '01' then onguar_amt else 0 end)  as big_corp_onguar_amt,
       sum(case when enterprise_scale = '02' then onguar_amt else 0 end)  as medium_corp_onguar_amt,
       sum(case when enterprise_scale = '03' then onguar_amt else 0 end)  as small_corp_onguar_amt,
       sum(case when enterprise_scale = '04' then onguar_amt else 0 end)  as micro_corp_onguar_amt,
       sum(case when enterprise_scale is null then onguar_amt else 0 end) as other_onguar_amt
from (
         select guar_id
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
     ) t1
         left join
     (
         select guar_id,
                onguar_amt -- 在保余额(万元)
         from dw_base.dwd_guar_info_onguar
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select code,             -- 项目id
                enterprise_scale, -- 企业规模
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main) t1
         where rn = 1
     ) t3 on t1.guar_id = t3.code;
commit;