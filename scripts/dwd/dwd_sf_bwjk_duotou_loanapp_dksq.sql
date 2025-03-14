-- ---------------------------------------
-- 开发人   : 
-- 开发时间 ：
-- 目标表   :dwd_sf_bwjk_duotou_loanapp_dksq
-- 源表     ：dw_nd.ods_extdata_bwfintech_duotou_loanapp 多头借贷--贷款申请详情
    --        dw_base.dwd_sf_to_msg_log 三方报文日志表--外部请求数据引擎
-- 变更记录 ：  20220117统一修改
--              20220516 日志变量注释  xgm   
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_sf_bwjk_duotou_loanapp_dksq';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;


truncate table dw_base.dwd_sf_bwjk_duotou_loanapp_dksq ; 
insert into dw_base.dwd_sf_bwjk_duotou_loanapp_dksq
(
     day_id	, -- 数据日期
     seq_num	, -- 查询批次号
     cust_id	, -- 客户号
     cust_name	, -- 客户姓名
	 
     last_app_time	, -- 
     earliest_app_time	, -- 
     app_times	, -- 
     app_notbank_1y_insit_num	, -- 
	 
     bw_appl_cnt	, -- 
	 bw_appl_cnt_bank ,
     bw_appl_cnt_nonbank	, -- 
     bw_appl_cnt_7d	, -- 
     bw_appl_cnt_14d	, -- 
     bw_appl_cnt_30d	, -- 
     bw_appl_cnt_60d	, -- 
     bw_appl_cnt_180d	, -- 
     bw_appl_cnt_360d	, -- 
     bw_appl_cnt_bank_7d	, -- 
     bw_appl_cnt_bank_14d	, -- 
     bw_appl_cnt_bank_30d	, -- 
     bw_appl_cnt_bank_60d	, -- 
     bw_appl_cnt_bank_180d	, -- 
     bw_appl_cnt_bank_360d	, -- 
     bw_appl_cnt_nonbank_7d	, -- 
     bw_appl_cnt_nonbank_14d	, -- 
     bw_appl_cnt_nonbank_30d	, -- 
     bw_appl_cnt_nonbank_60d	, -- 
     bw_appl_cnt_nonbank_180d	, -- 
     bw_appl_cnt_nonbank_360d	, -- 
     bw_appl_cnt_02W	, -- 
     bw_appl_cnt_05W	, -- 
     bw_appl_cnt_1W	, -- 
     bw_appl_cnt_3W	, -- 
     bw_appl_cnt_5W	, -- 
     bw_appl_cnt_10W	, -- 
     bw_appl_cnt_10W_plus	, -- 
     bw_appl_cnt_m00	, -- 
     bw_appl_cnt_m01	, -- 
     bw_appl_cnt_m02	, -- 
     bw_appl_cnt_m03	, -- 
     bw_appl_cnt_m04	, -- 
     bw_appl_cnt_m05	, -- 
     bw_appl_cnt_m06	, -- 
     bw_appl_cnt_m07	, -- 
     bw_appl_cnt_m08	, -- 
     bw_appl_cnt_m09	, -- 
     bw_appl_cnt_m10	, -- 
     bw_appl_cnt_m11	, -- 
     bw_appl_cnt_m12	, -- 
     dw_ins_dt	  -- 数仓插入日期
)


select 
'${v_sdate}' as day_id,
seqNum,
c.cust_id	, -- 客户号
c.cust_name	, -- 客户姓名
max(application_time) last_app_time,
min(application_time) earliest_app_time,
count(distinct application_time) app_times,
sum(case when datediff(current_date, application_time)<360 and platform = 2 then 1 else 0 end) app_notbank_1y_insit_num,
count(*) as bw_appl_cnt,
sum(case when platform=1   then 1 else 0 end) as 'bw_appl_cnt_bank' ,
sum(case when platform<>1   then 1 else 0 end) as 'bw_appl_cnt_nonbank' ,
sum(case when datediff(createDate,application_time)<=7   then 1 else 0 end) as 'bw_appl_cnt_7d' ,
sum(case when datediff(createDate,application_time)<=14   then 1 else 0 end) as 'bw_appl_cnt_14d' ,
sum(case when datediff(createDate,application_time)<=30   then 1 else 0 end) as 'bw_appl_cnt_30d' ,
sum(case when datediff(createDate,application_time)<=60  then 1 else 0 end) as 'bw_appl_cnt_60d' ,
sum(case when datediff(createDate,application_time)<=180   then 1 else 0 end) as 'bw_appl_cnt_180d' ,
sum(case when datediff(createDate,application_time)<=360   then 1 else 0 end) as 'bw_appl_cnt_360d' ,

sum(case when platform=1 and datediff(createDate,application_time)<=7     then 1 else 0 end) as 'bw_appl_cnt_bank_7d' ,
sum(case when platform=1 and datediff(createDate,application_time)<=14    then 1 else 0 end) as 'bw_appl_cnt_bank_14d' ,
sum(case when platform=1 and datediff(createDate,application_time)<=30    then 1 else 0 end) as 'bw_appl_cnt_bank_30d' ,
sum(case when platform=1 and datediff(createDate,application_time)<=60    then 1 else 0 end) as 'bw_appl_cnt_bank_60d' ,
sum(case when platform=1 and datediff(createDate,application_time)<=180   then 1 else 0 end) as 'bw_appl_cnt_bank_180d' ,
sum(case when platform=1 and datediff(createDate,application_time)<=360   then 1 else 0 end) as 'bw_appl_cnt_bank_360d' ,

sum(case when platform<>1 and datediff(createDate,application_time)<=7    then 1 else 0 end) as 'bw_appl_cnt_nonbank_7d' ,
sum(case when platform<>1 and datediff(createDate,application_time)<=14    then 1 else 0 end) as 'bw_appl_cnt_nonbank_14d' ,
sum(case when platform<>1 and datediff(createDate,application_time)<=30    then 1 else 0 end) as 'bw_appl_cnt_nonbank_30d' ,
sum(case when platform<>1 and datediff(createDate,application_time)<=60    then 1 else 0 end) as 'bw_appl_cnt_nonbank_60d' ,
sum(case when platform<>1 and datediff(createDate,application_time)<=180   then 1 else 0 end) as 'bw_appl_cnt_nonbank_180d' ,
sum(case when platform<>1 and datediff(createDate,application_time)<=360   then 1 else 0 end) as 'bw_appl_cnt_nonbank_360d' ,

sum(case when application_money='1. 0W-0.2W' then 1 else 0 end) as 'bw_appl_cnt_0.2W',
sum(case when application_money='2. 0.2W-0.5W' then 1 else 0 end) as 'bw_appl_cnt_0.5W' ,
sum(case when application_money='3. 0.5W-1W'  then 1 else 0 end) as 'bw_appl_cnt_1W' ,
sum(case when application_money='4. 1W-3W'    then 1 else 0 end) as 'bw_appl_cnt_3W' ,
sum(case when application_money='5. 3W-5W'    then 1 else 0 end) as 'bw_appl_cnt_5W' ,
sum(case when application_money='6. 5W-10W'   then 1 else 0 end) as 'bw_appl_cnt_10W' ,
sum(case when application_money='7. 10W以上'   then 1 else 0 end) as 'bw_appl_cnt_10W_plus' ,
sum(case when TIMESTAMPDIFF(MONTH,application_time,createDate)=0   then 1 else 0 end) as 'bw_appl_cnt_m00' ,
sum(case when TIMESTAMPDIFF(MONTH,application_time,createDate)=1   then 1 else 0 end) as 'bw_appl_cnt_m01' ,
sum(case when TIMESTAMPDIFF(MONTH,application_time,createDate)=2   then 1 else 0 end) as 'bw_appl_cnt_m02' ,
sum(case when TIMESTAMPDIFF(MONTH,application_time,createDate)=3   then 1 else 0 end) as 'bw_appl_cnt_m03' ,
sum(case when TIMESTAMPDIFF(MONTH,application_time,createDate)=4   then 1 else 0 end) as 'bw_appl_cnt_m04' ,
sum(case when TIMESTAMPDIFF(MONTH,application_time,createDate)=5   then 1 else 0 end) as 'bw_appl_cnt_m05' ,
sum(case when TIMESTAMPDIFF(MONTH,application_time,createDate)=6   then 1 else 0 end) as 'bw_appl_cnt_m06' ,
sum(case when TIMESTAMPDIFF(MONTH,application_time,createDate)=7   then 1 else 0 end) as 'bw_appl_cnt_m07' ,
sum(case when TIMESTAMPDIFF(MONTH,application_time,createDate)=8   then 1 else 0 end) as 'bw_appl_cnt_m08' ,
sum(case when TIMESTAMPDIFF(MONTH,application_time,createDate)=9   then 1 else 0 end) as 'bw_appl_cnt_m09' ,
sum(case when TIMESTAMPDIFF(MONTH,application_time,createDate)=10   then 1 else 0 end) as 'bw_appl_cnt_m10' ,
sum(case when TIMESTAMPDIFF(MONTH,application_time,createDate)=11   then 1 else 0 end) as 'bw_appl_cnt_m11' ,
sum(case when TIMESTAMPDIFF(MONTH,application_time,createDate)=12   then 1 else 0 end) as 'bw_appl_cnt_m12' ,
now()  as dw_ins_dt -- 数仓插入日期
from  
(select platform_code,application_result,application_time,
platform,application_money,seqNum,createDate
from dw_nd.ods_extdata_bwfintech_duotou_loanapp
where date_format(createDate,'%Y%m%d') <= '${v_sdate}') a
left join dw_base.dwd_sf_to_msg_log  c  on a.seqNum=c.seq_num  
group by seqNum ;
-- select row_count() into @rowcnt;
commit; 
-- insert into dw_base.pub_etl_log values (@etl_date,@pro_name,@table_name,@sorting,concat('多头借贷-贷款申请-风险-数据加工完成,共插入',@rowcnt,'条'),@time,now());commit;
