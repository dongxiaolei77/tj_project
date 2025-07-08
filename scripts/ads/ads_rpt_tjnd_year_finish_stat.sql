
-- ---------------------------------------

-- 1.临时表_主项目当年应续支情况
drop table if exists dw_tmp.tmp_ads_rpt_tjnd_year_finish_stat_main;
commit;
create Table if not exists dw_tmp.tmp_ads_rpt_tjnd_year_finish_stat_main(
guar_id             varchar(64) comment '项目编号'
,guar_beg_dt        varchar(8)  comment '当年应续支业务的担保年度开始时间'
,index ind_tmp_ads_rpt_tjnd_year_finish_stat_main_id(guar_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin comment= '临时表-存主项目在当年应续支业务的担保年度开始时间';

insert into dw_tmp.tmp_ads_rpt_tjnd_year_finish_stat_main
(
 guar_id
 ,guar_beg_dt
)
select	t1.guar_id
		,case -- 贷款类型是“循环贷”或者存在续支的数据 通过主项目首次放款时间计算当前担保年度(2024年)的数据，取之，目前最长期是10年
			when year(date_add(t1.first_loan_dt, interval 1 year)) = year('${v_sdate}') then date_format(date_add(t1.first_loan_dt, interval 1  year), '%Y%m%d')
			when year(date_add(t1.first_loan_dt, interval 2 year)) = year('${v_sdate}') then date_format(date_add(t1.first_loan_dt, interval 2  year), '%Y%m%d')
			when year(date_add(t1.first_loan_dt, interval 3 year)) = year('${v_sdate}') then date_format(date_add(t1.first_loan_dt, interval 3  year), '%Y%m%d')
			when year(date_add(t1.first_loan_dt, interval 4 year)) = year('${v_sdate}') then date_format(date_add(t1.first_loan_dt, interval 4  year), '%Y%m%d')
			when year(date_add(t1.first_loan_dt, interval 5 year)) = year('${v_sdate}') then date_format(date_add(t1.first_loan_dt, interval 5  year), '%Y%m%d')
			when year(date_add(t1.first_loan_dt, interval 6 year)) = year('${v_sdate}') then date_format(date_add(t1.first_loan_dt, interval 6  year), '%Y%m%d')
			when year(date_add(t1.first_loan_dt, interval 7 year)) = year('${v_sdate}') then date_format(date_add(t1.first_loan_dt, interval 7  year), '%Y%m%d')
			when year(date_add(t1.first_loan_dt, interval 8 year)) = year('${v_sdate}') then date_format(date_add(t1.first_loan_dt, interval 8  year), '%Y%m%d')
			when year(date_add(t1.first_loan_dt, interval 9 year)) = year('${v_sdate}') then date_format(date_add(t1.first_loan_dt, interval 9  year), '%Y%m%d')
			when year(date_add(t1.first_loan_dt, interval 10 year)) = year('${v_sdate}') then date_format(date_add(t1.first_loan_dt, interval 10 year), '%Y%m%d')
			else null
		 end as guar_beg_dt
from
(
	select	t1.guar_id
			,t1.project_id
			,t2.first_loan_dt
	from dw_base.dwd_guar_info_stat t1
	inner join dw_base.dwd_guar_info_all t2
	on t1.guar_id = t2.guar_id
	where t1.item_stt_code in ('06', '11', '12')                       -- 项目状态：06-已放款，11-已解保，12-已代偿
	and (t1.guar_id = t1.project_no or t1.guar_id like '%SDAGWF%XZ%')  -- 主项目业务数据
) t1
left join
(
	select guar_no, loan_beg_dt, loan_end_dt, loan_type
	from dw_base.dwd_guar_cont_info_all
	where loan_type regexp '循环贷'
	group by guar_no
) t2
on t1.guar_id = t2.guar_no
left join
(
	select	project_id
	from dw_nd.ods_t_biz_proj_xz
	group by project_id

	union
	select	project_id
	from dw_nd.ods_t_biz_proj_loan_check
	where type = '02' -- 自主续支数据
	group by project_id
) t3
on t1.project_id = t3.project_id

where t2.guar_no is not null or t3.project_id is not null -- "循环贷"的数据
;
commit;


-- 2.创建临时表，统计已放款、已解保、已代偿的项目数据
drop table if exists dw_tmp.tmp_ads_rpt_tjnd_year_finish_stat_guar;
commit;
create Table if not exists dw_tmp.tmp_ads_rpt_tjnd_year_finish_stat_guar(
guar_id          varchar(50) comment '担保ID'
,city_code       varchar(20) comment '地市代码'
,city_name       varchar(50) comment '地市名称'
,country_code    varchar(20) comment '区县代码'
,country_name    varchar(50) comment '区县名称'
,item_stt_code   varchar(20) comment '项目状态代码'
,guar_class      varchar(30)  comment '国担分类'           -- + 20230615
,guar_class_name varchar(100) comment '国担分类名称'       -- + 20230615
,econ_class      varchar(30)  comment '国民经济分类'       -- + 20230615
,econ_class_name varchar(100) comment '国民经济分类名称'   -- + 20230615
,bank_type       varchar(50)  comment '银行大类'           -- + 20230615
-- ,guar_end_dt     varchar(8)  comment '担保年度时间'     -- - 20240322
-- ,loan_beg_dt     varchar(8)  comment '贷款合同开始时间' -- - 20240322
-- ,loan_end_dt     varchar(8)  comment '贷款合同结束时间' -- - 20240322
,project_no      varchar(50) comment '原业务编号'
,project_id      varchar(64) comment '项目id'
,cert_no         varchar(50) comment '身份证号'
,index ind_tmp_ads_rpt_tjnd_year_finish_stat_guar_id(guar_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin comment= '临时表-存guar_info_stat数据';

insert into dw_tmp.tmp_ads_rpt_tjnd_year_finish_stat_guar
(
guar_id
,city_code
,city_name
,country_code
,country_name
,item_stt_code
,guar_class         -- +20230615
,guar_class_name    -- +20230615
,econ_class         -- +20230615
,econ_class_name    -- +20230615
,bank_type          -- +20230615
-- ,guar_end_dt     -- -20240322
-- ,loan_beg_dt     -- -20240322
-- ,loan_end_dt     -- -20240322
,project_no
,project_id
,cert_no
)
select t1.guar_id
       ,coalesce(t1.city_code, '379900') as city_code
       ,coalesce(t0.city_name, '其他城市') as city_name
       ,coalesce(t1.country_code, concat(left(t1.city_code,4), '99'),'379999') as country_code
       ,coalesce(t0.county_name, '其他区县') as country_name
       ,t1.item_stt_code
       ,t1.guar_code as guar_class
       ,coalesce(t0.guar_class, '其他') as guar_class_name
       ,t1.econ_code as econ_class
       ,case when t0.econ_class is null then '其他行业'
            when t0.econ_class regexp '/' then  substring_index(t0.econ_class, '/', -1)
           else t0.econ_class end  as econ_class_name
       ,case when t0.loan_bank like '%农行%' or t0.loan_bank like '%农业银行%' or t0.loan_bank like '%中国农业股份有限公司%' then '农业银行'
          when t0.loan_bank like '%农村商业%' or t0.loan_bank like '%农村信用合作社%' or t0.loan_bank like '%农村信用合作联社%' or t0.loan_bank like '%农商%' then '农商行'
          when t0.loan_bank like '%邮储%' or t0.loan_bank like '%邮政%' then '邮储银行'
         else '其他银行' end as bank_type
       -- ,case when t2.code is not null and t1.guar_id = t1.project_no and t5.loan_type in ('循环贷', '非自主循环贷(一年一支用)') -- 循环贷的进件项目
       --          then case when t2.is_exists_xz = '0' and date_format(date_add(t1.loan_star_dt, INTERVAL 1 YEAR),'%Y%m%d') < concat(year('${v_sdate}'), '0101') -- 不存在续支数据，且担保年度开始时间+1年在统计范围之前，则+2年
       --                 then date_format(date_add(t1.loan_star_dt, INTERVAL 2 YEAR),'%Y%m%d')  -- 担保年度结束时间=担保年度开始时间+1年
       --                   else date_format(date_add(t1.loan_star_dt, INTERVAL 1 YEAR),'%Y%m%d') end -- 进件项目，担保年度结束时间=担保年度开始时间+1年
       --       when t3.code is not null then date_format(t3.guar_annu_duedate, '%Y%m%d') -- 续支项目取 guar_annu_duedate 担保年度到期日
       --       when t4.code is not null then date_format(t4.guar_annu_duedate, '%Y%m%d') -- 自主续支项目取 guar_annu_duedate 担保年度到期日
       --       else null end as guar_end_dt  -- 担保年度结束日期
       -- ,t5.loan_beg_dt                     -- 贷款合同开始日期
       -- ,t5.loan_end_dt                     -- 贷款合同结束日期
       ,t1.project_no     -- 原项目编号
       ,t1.project_id
       ,t1.cert_no
  from dw_base.dwd_guar_info_stat t1
  inner join dw_base.dwd_guar_info_all t0
    on t0.guar_id = t1.guar_id
  -- left join dw_tmp.tmp_ads_rpt_tjnd_year_finish_stat_main t2  -- 进件数据
  --   on t2.code = t1.guar_id
  -- left join (
  --          -- 续支
  --          select id,code, guar_annu_duedate from ( select id,code, guar_annu_duedate from dw_nd.ods_t_biz_proj_xz order by db_update_time desc, update_time desc) a group by id
  --           ) t3
  --   on t3.code = t1.guar_id
  -- left join (
  --          -- 自主续支
  --          select id,code, guar_annu_duedate from ( select id,code, guar_annu_duedate from dw_nd.ods_t_biz_proj_loan_check order by db_update_time desc, update_time desc) a group by id
  --           ) t4
  --   on t4.code = t1.guar_id
  -- left join (select guar_no, loan_beg_dt, loan_end_dt, loan_type from dw_base.dwd_guar_cont_info_all group by guar_no ) t5  -- 担保年度合同信息 取贷款合同开始/结束日期/贷款类型
  --   on t1.guar_id = t5.guar_no
 where t1.item_stt_code in ('06','11','12')  -- 已放款、已解保、已代偿
   and t1.guar_id is not null
;
commit;

-- 3.创建临时表，保存合同到期笔数/金额（按照合同到期日统计） add 20230615
drop table if exists dw_tmp.tmp_ads_rpt_tjnd_year_finish_stat_cont;
commit;
create Table if not exists dw_tmp.tmp_ads_rpt_tjnd_year_finish_stat_cont(
 city_code             varchar(20)     comment '地市代码'
,country_code          varchar(20)     comment '区县代码'
,guar_class_name       varchar(30)     comment '国担分类名称'
,econ_class_name       varchar(30)     comment '国民经济分类名称'
,bank_type             varchar(30)     comment '银行大类'
,unguar_cnt_lastyear   int             comment '今年续保客户的上一笔解保项目的合同到期不在今年的笔数'
,unguar_amt_lastyear   decimal(18,2)   comment '今年续保客户的上一笔解保项目的合同到期不在今年的金额'

)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin comment= '临时表-今年续保客户的上一笔解保项目的合同到期不在今年笔数/金额';

insert into dw_tmp.tmp_ads_rpt_tjnd_year_finish_stat_cont
(
 city_code
,country_code
,guar_class_name
,econ_class_name
,bank_type
,unguar_cnt_lastyear
,unguar_amt_lastyear
)
-- tb 当年续保客户的上一笔解保项目
select coalesce(t1.city_code, '379900') as city_code
       ,coalesce(t1.country_code, concat(left(t1.city_code,4), '99'),'379999') as country_code
       ,coalesce(t2.guar_class, '其他') as guar_class_name
       ,case when t2.econ_class is null then '其他行业'
            when t2.econ_class regexp '/' then  substring_index(t2.econ_class, '/', -1)
           else t2.econ_class end  as econ_class_name
       ,case when t2.loan_bank like '%农行%' or t2.loan_bank like '%农业银行%' or t2.loan_bank like '%中国农业股份有限公司%' then '农业银行'
          when t2.loan_bank like '%农村商业%' or t2.loan_bank like '%农村信用合作社%' or t2.loan_bank like '%农村信用合作联社%' or t2.loan_bank like '%农商%' then '农商行'
          when t2.loan_bank like '%邮储%' or t2.loan_bank like '%邮政%' then '邮储银行'
         else '其他银行' end as bank_type
       ,sum(case when t3.loan_end_dt < concat(year('${v_sdate}'), '0101') then 1 else 0 end) as unguar_cnt_lastyear            -- 今年续保客户的上一笔解保项目的合同到期不在今年   笔数
       ,sum(case when t3.loan_end_dt < concat(year('${v_sdate}'), '0101') then t1.loan_amt else 0 end) as unguar_amt_lastyear  -- 今年续保客户的上一笔解保项目的合同到期不在今年   金额
  from (
         select * from (
         select * from dw_base.dwd_guar_tag t1 -- 标签表
         where exists (select * from dw_base.dwd_guar_tag  t2
                        where t2.is_first_guar = '1' and t2.is_xz = '0' and t2.loan_reg_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' -- 今年续保的数据
                          and t1.cert_no = t2.cert_no -- exists 续保客户的所有数据
                          and t1.guar_id <> t2.guar_id -- not exists 不是当前这一笔续保
                       )
         and t1.item_stt_code = '11' -- 当年续保客户的所有解保
         order by t1.loan_reg_dt desc
         ) a
         group by cert_no -- 证件号去重取最近一条解保数据
        ) t1

  inner join dw_base.dwd_guar_info_all t2 -- 担保业务台账表
  on t1.guar_id = t2.guar_id

  left join (select guar_no, loan_end_dt from dw_base.dwd_guar_cont_info_all group by guar_no )t3 -- 取项目合同到期日
  on t1.guar_id = t3.guar_no

  group by coalesce(t1.city_code, '379900')
           ,coalesce(t1.country_code, concat(left(t1.city_code,4), '99'),'379999')
           ,coalesce(t2.guar_class, '其他')
           ,case when t2.econ_class is null then '其他行业'
               when t2.econ_class regexp '/' then  substring_index(t2.econ_class, '/', -1)
              else t2.econ_class end
           ,case when t2.loan_bank like '%农行%' or t2.loan_bank like '%农业银行%' or t2.loan_bank like '%中国农业股份有限公司%' then '农业银行'
              when t2.loan_bank like '%农村商业%' or t2.loan_bank like '%农村信用合作社%' or t2.loan_bank like '%农村信用合作联社%' or t2.loan_bank like '%农商%' then '农商行'
              when t2.loan_bank like '%邮储%' or t2.loan_bank like '%邮政%' then '邮储银行'
             else '其他银行' end
;
commit;


-- 4.数据汇总进入目标表
delete from dw_base.ads_rpt_tjnd_year_finish_stat where day_id = '${v_sdate}' ;
commit ;

insert into dw_base.ads_rpt_tjnd_year_finish_stat
 (
   day_id               -- 数据日期
  ,city_code            -- 地市
  ,city_name            -- 地市名称
  ,country_code         -- 区县  +
  ,country_name         -- 区县名称  +
  -- ,guar_class           -- 国担分类          + 20230615 国民经济分类代码有null 不利于聚合，去掉该字段
  ,guar_class_name      -- 国担分类名称      + 20230615
  -- ,econ_class           -- 国民经济分类      + 20230615
  ,econ_class_name      -- 国民经济分类名称  + 20230615
  ,bank_type            -- 银行大类          + 20230615
  ,last_year_guar_amt   -- 上一年年底在保额
  ,first_cnt            -- 首保笔数
  ,first_amt            -- 首保金额
  ,conguar_cnt          -- 实际续保笔数
  ,conguar_amt          -- 实际续保金额
  ,conpay_cnt           -- 实际续支笔数
  ,conpay_amt           -- 实际续支金额
  ,sum_cnt              -- 合计笔数(首保+实际续保+实际续支）
  ,sum_amt              -- 合计金额(首保+实际续保+实际续支）
  ,unguar_first_cnt     -- 首保解保笔数  +
  ,unguar_first_amt     -- 首保解保金额  +
  ,unguar_conguar_cnt   -- 续保解保笔数  +
  ,unguar_conguar_amt   -- 续保解保金额  +
  ,unguar_conpay_cnt    -- 续支解保笔数  +
  ,unguar_conpay_amt    -- 续支解保金额  +
  ,unguar_cnt           -- 解保笔数
  ,unguar_amt           -- 解保金额
  ,plan_conpay_cnt      -- 应续支笔数 +
  ,plan_conpay_amt      -- 应续支金额 +
  ,contract_unguar_cnt  -- 合同解保笔数 +
  ,contract_unguar_amt  -- 合同解保金额 +
  ,contract_expire_cnt  -- 合同到期笔数（按照合同到期日统计） + 20230615
  ,contract_expire_amt  -- 合同到期金额（按照合同到期日统计） + 20230615
  ,last_guar_amt        -- 上一笔业务合同额                   + 20230615
  ,guar_amt             -- 当前在保金额
 )
select '${v_sdate}' as day_id
        ,t.city_code
        ,t.city_name
        ,t.country_code
        ,t.country_name
        -- ,t.guar_class
        ,t.guar_class_name
        -- ,t.econ_class
        ,t.econ_class_name
        ,t.bank_type
        ,t.last_year_guar_amt
        ,t.first_cnt
        ,t.first_amt
        ,t.conguar_cnt
        ,t.conguar_amt
        ,t.conpay_cnt
        ,t.conpay_amt
        ,(t.first_cnt + t.conguar_cnt + t.conpay_cnt) as sum_cnt
        ,(t.first_amt + t.conguar_amt + t.conpay_amt) as sum_amt
        ,t.unguar_first_cnt
        ,t.unguar_first_amt
        ,t.unguar_conguar_cnt
        ,t.unguar_conguar_amt
        ,t.unguar_conpay_cnt
        ,t.unguar_conpay_amt
        ,t.unguar_cnt
        ,t.unguar_amt
        ,t.plan_conpay_cnt
        ,t.plan_conpay_amt
        ,t.contract_unguar_cnt
        ,t.contract_unguar_amt
        ,t.contract_expire_cnt
        ,t.contract_expire_amt
        ,coalesce(t1.unguar_amt_lastyear, 0) as last_guar_amt
        ,t.guar_amt
from (
    select t.city_code
           ,t.city_name
           ,t.country_code
           ,t.country_name
           -- ,t.guar_class
           ,t.guar_class_name
           -- ,t.econ_class
           ,t.econ_class_name
           ,t.bank_type
           ,sum(case when t.item_stt = '已放款' then t.loan_amt else 0 end) as last_year_guar_amt -- 上一年年底在保额
           ,count(distinct case when t.is_first_guar = '0' and t.is_xz = '0' and t.loan_reg_dt >= concat(year('${v_sdate}'), '0101') then t.guar_id else null end ) as first_cnt -- 首保笔数
           ,sum(case when t.is_first_guar = '0' and t.is_xz = '0' and t.loan_reg_dt >= concat(year('${v_sdate}'), '0101') then t.loan_amt else 0 end) as first_amt -- 首保金额
           ,count(distinct case when t.is_first_guar = '1' and t.is_xz = '0' and t.loan_reg_dt >= concat(year('${v_sdate}'), '0101') then t.guar_id else null end ) as conguar_cnt -- 续保笔数
           ,sum(case when t.is_first_guar = '1' and t.is_xz = '0' and t.loan_reg_dt >= concat(year('${v_sdate}'), '0101') then t.loan_amt else 0 end) as conguar_amt -- 续保金额
           ,count(distinct case when t.is_xz = '1' and t.loan_reg_dt >= concat(year('${v_sdate}'), '0101') then t.guar_id else null end ) as conpay_cnt -- 实际续支笔数
           ,sum(case when t.is_xz = '1' and t.loan_reg_dt >= concat(year('${v_sdate}'), '0101') then t.loan_amt else 0 end) as conpay_amt -- 实际续支金额
           ,count(distinct case when t.is_first_guar = '0' and t.is_xz = '0'
                       and ((t.item_stt_code = '11' and t.item_stt <> '已解保') or (t.item_stt_code = '11' and guar_id_his is null)) then t.guar_id else null end ) as unguar_first_cnt -- 首保解保笔数
           ,sum(case when t.is_first_guar = '0' and t.is_xz = '0'
                       and ((t.item_stt_code = '11' and t.item_stt <> '已解保') or (t.item_stt_code = '11' and guar_id_his is null)) then t.loan_amt else 0 end) as unguar_first_amt -- 首保解保金额
           ,count(distinct case when t.is_first_guar = '1' and t.is_xz = '0'
                       and ((t.item_stt_code = '11' and t.item_stt <> '已解保') or (t.item_stt_code = '11' and guar_id_his is null)) then t.guar_id else null end ) as unguar_conguar_cnt -- 续保解保笔数
           ,sum(case when t.is_first_guar = '1' and t.is_xz = '0'
                       and ((t.item_stt_code = '11' and t.item_stt <> '已解保') or (t.item_stt_code = '11' and guar_id_his is null)) then t.loan_amt else 0 end) as unguar_conguar_amt -- 续保解保金额
           ,count(distinct case when (t.is_xz = '1' or (t.guar_id regexp 'XZ' and t.is_xz is null))  and ((t.item_stt_code = '11' and t.item_stt <> '已解保') or (t.item_stt_code = '11' and guar_id_his is null)) then t.guar_id else null end ) as unguar_conpay_cnt -- 续支解保笔数
           ,sum(case when (t.is_xz = '1' or (t.guar_id regexp 'XZ' and t.is_xz is null)) and ((t.item_stt_code = '11' and t.item_stt <> '已解保') or (t.item_stt_code = '11' and guar_id_his is null)) then t.loan_amt else 0 end) as unguar_conpay_amt -- 续支解保金额
           -- (t.guar_id regexp 'XZ' and t.is_xz is null))  加上这个条件是因为有一批续支业务没有放款登记日直接解保的，导致is_xz没有赋值上
           ,count(distinct case when (t.item_stt_code = '11' and t.item_stt <> '已解保') or (t.item_stt_code = '11' and guar_id_his is null) then t.guar_id else null end) as unguar_cnt -- 解保笔数
           ,sum(case when (t.item_stt_code = '11' and t.item_stt <> '已解保') or (t.item_stt_code = '11' and guar_id_his is null) then t.loan_amt else 0 end) as unguar_amt -- 解保金额
           ,count(distinct case when t.loan_end_dt > t.guar_beg_dt and t.guar_beg_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then t.guar_id else null end)            as  plan_conpay_cnt -- 应续支笔数
           ,sum(case when t.loan_end_dt > t.guar_beg_dt and t.guar_beg_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then t.loan_amt else 0 end)  as  plan_conpay_amt -- 应续支金额
           ,count(distinct case when t.unguar_date between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then t.project_no else null end) as contract_unguar_cnt  -- 合同解保笔数（按照解保日期统计）
           ,sum( case when t.unguar_date between concat(year('${v_sdate}'), '0101') and '${v_sdate}'
                       and (t.guar_id = t.project_no or t.guar_id like '%SDAGWF%XZ%')  then t.loan_amt else 0 end) as contract_unguar_amt  -- 合同解保金额（按照解保日期统计）
           ,sum(case when t.loan_end_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}'
                       and (t.guar_id = t.project_no or t.guar_id like '%SDAGWF%XZ%')  then 1 else 0 end) as contract_expire_cnt -- 合同到期笔数（按照合同到期日统计）
           ,sum(case when t.loan_end_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}'
                       and (t.guar_id = t.project_no or t.guar_id like '%SDAGWF%XZ%')  then t.loan_amt else 0 end) as contract_expire_amt  -- 合同到期金额（按照合同到期日统计）
           ,sum(case when t.item_stt_code = '06'  then t.loan_amt else 0 end) as guar_amt -- 在保金额
    FROM
    (
        select distinct t.guar_id
               ,t.project_no
               ,t.city_code
               ,t.city_name
               ,t.country_code
               ,t.country_name
               -- ,t.guar_class
               ,t.guar_class_name
               -- ,t.econ_class
               ,t.econ_class_name
               ,t.bank_type

               ,t2.item_stt
               ,t1.loan_amt
               ,t1.is_first_guar
               ,t1.is_xz
               ,t1.loan_reg_dt
               ,t1.item_stt_code
               ,t2.guar_id as guar_id_his
               ,t3.loan_end_dt
               ,t5.guar_beg_dt
               ,t4.unguar_date
        from dw_tmp.tmp_ads_rpt_tjnd_year_finish_stat_guar t
        left join dw_base.dwd_guar_tag t1
          on t.guar_id = t1.guar_id
        left join (select guar_id, item_stt from dw_base.dwd_guar_info_all_his where day_id = '20231231') t2
          on t.guar_id = t2.guar_id
        left join (select guar_no, loan_end_dt from dw_base.dwd_guar_cont_info_all group by guar_no ) t3 -- 取项目合同到期日
          on t.guar_id = t3.guar_no
        left join (select id, project_id, status, date_format(unguar_date, '%Y%m%d') as unguar_date
                     from (select id,project_id, unguar_date, status from dw_nd.ods_t_biz_proj_unguar order by update_time desc) a
                    group by project_id
                  ) t4 -- 解保项目表
        on t.project_id = t4.project_id and t4.status = '20' -- 已解保
        left join dw_tmp.tmp_ads_rpt_tjnd_year_finish_stat_main t5
        on t.guar_id = t5.guar_id
    )T
    group by t.city_code,t.city_name,t.country_code,t.country_name
                ,t.guar_class_name, t.econ_class_name, t.bank_type

) t
left join dw_tmp.tmp_ads_rpt_tjnd_year_finish_stat_cont t1
on t.city_code = t1.city_code and t.country_code = t1.country_code and t.guar_class_name = t1.guar_class_name and t.econ_class_name = t1.econ_class_name and t.bank_type = t1.bank_type

;
commit;
