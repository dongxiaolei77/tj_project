-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220119
-- 目标表   ：dwd_evt_fee_doc 费用凭证信息
-- 源表     ： dwd_agmt_guar_info  担保信息-明细
			-- ods_t_sys_area  新业务中台地区表
			-- dim_prod_code  产品类型维表
			-- ods_gcredit_loan_ac_dxbillplanfee  费用还款计划信息文件
            -- dw_nd.ods_t_biz_proj_refund        退费项目表

-- 变更记录 ：20220119:统一变动    
--            20220319:如果应缴金额为空，也更新
-- 			  20220511:调整业务更新日期取值逻辑 wyx
-- 			  20220525 新增字段'缴费方式'，并同步至 ads_evt_fee_doc
--            20221214 查找当日退费数据，更新正常缴费记录 wyx
--            202300301 增加风险化解，但是项目来源是迁移的数据
--            20230817  增加一个字段：自动计算退费金额
--            20231228 wyx 增加字段：deal_type -- 处理类型 0正常流程 1人工补录
-- ---------------------------------------

 -- 应还信息
drop table if exists dw_tmp.tmp_dwd_evt_fee_doc_yh ;
commit;

create table dw_tmp.tmp_dwd_evt_fee_doc_yh (
     guar_id varchar(100) comment '业务编号' ,
	 rbl_fee decimal(18,2)  COMMENT '应还费用',
     rbl_fee_person decimal(18,2)  COMMENT '个人应还费用',
     rbl_fee_policy decimal(18,2)  COMMENT '政策应还费用',
	 index idx_tmp_dwd_evt_fee_doc_yh_guar_id(guar_id)
)
;
commit ;

insert into dw_tmp.tmp_dwd_evt_fee_doc_yh
select drawndn_seqno
       ,schdu_fee
	   ,schdu_fee_person
	   ,schdu_fee_policy
from	   
(
	select drawndn_seqno
		   ,schdu_fee
		   ,schdu_fee_person
		   ,schdu_fee_policy
		   ,snapshot_date	   
	from dw_nd.ods_gcredit_loan_ac_dxbillplanfee a  -- 保费还款计划表
	where state ='1'  -- 0失效 1有效
	and date_format(update_time,'%Y%m%d') <='${v_sdate}'  -- mdy
	order by snapshot_date desc 
) t
group by drawndn_seqno 
;
commit ; 


-- 最新日期省份信息 -- mdy 20211201
drop table if exists dw_tmp.tmp_dwd_evt_fee_doc_area ;
commit;

create  table dw_tmp.tmp_dwd_evt_fee_doc_area (
     area_id varchar(64) comment '地域ID（UUID）' ,
	 area_name varchar(32) comment '省份' ,
	 index idx_tmp_dwd_evt_fee_doc_area_area_id(area_id)
)
;
commit ;

insert into dw_tmp.tmp_dwd_evt_fee_doc_area
select distinct area_id
      ,area_name
from (
       select
       t1.area_id
       ,t1.area_name 
       from(
       	select
       	area_id
       	,area_name 
       	from  dw_nd.ods_t_sys_area 
       	where   date_format(update_time,'%Y%m%d') <='${v_sdate}'  -- mdy
       	order by update_time desc
       ) t1
       group by t1.area_id
	union all 
    select area_cd as area_id,area_name from dw_base.dim_area_info where area_lvl = '3' 
    union all 
	select area_cd as area_id,area_name from dw_base.dim_area_info where area_lvl = '2' 
	) a
;
commit;


 -- 台账信息
drop table if exists dw_tmp.tmp_dwd_evt_fee_doc_guar ;
commit;

create  table dw_tmp.tmp_dwd_evt_fee_doc_guar (
     guar_id varchar(100) comment '业务编号' ,
	 cust_id varchar(100) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '客户号',
	 cust_name varchar(100) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '客户名称',
     cert_no varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '身份证号',
	 city_name varchar(20) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '城市',
     county_name varchar(100) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '区县',
	 guar_stt varchar(20) comment '业务状态' ,
	 guar_upt_dt date comment '业务更新日期' ,
	 guar_prod varchar(100) comment '担保产品' ,
	 rbl_fee decimal(18,2)  COMMENT '应还费用',
     rbl_fee_person decimal(18,2)  COMMENT '个人应还费用',
     rbl_fee_policy decimal(18,2)  COMMENT '政策应还费用',
	 index(guar_id)
)
;
commit ;

insert into dw_tmp.tmp_dwd_evt_fee_doc_guar
 select 
 proj_dtl_no
 ,cust_id
 ,cust_name
 ,cert_no
 ,t2.area_name 
 ,t3.area_name 
 ,case when rcd_type ='3' and proj_dtl_stt = '50' then '已确认'
       when proj_dtl_stt = '00' then '提报中'
	   when proj_dtl_stt = '10' then '审批中'
	   when proj_dtl_stt = '20' then '待签约'
       when proj_dtl_stt = '30' then '待出函' 
       when proj_dtl_stt = '40' then '待放款' 
	   when proj_dtl_stt = '50' then '已放款'
	   when proj_dtl_stt = '97' then '已作废'
	   when proj_dtl_stt = '98' then '已终止'
	   when proj_dtl_stt = '99' then '已否决'
	   when proj_dtl_stt = '91' then '不受理'
	   when proj_dtl_stt = '90' then '已解保'
		 when proj_dtl_stt = '92' then '超期终止'
		 when proj_dtl_stt = '93' then '已代偿'
  end	   
 ,update_dt
 ,t4.value
 ,t5.rbl_fee 
 ,t5.rbl_fee_person 
 ,t5.rbl_fee_policy 
 from dw_base.dwd_agmt_guar_info t1
left join dw_tmp.tmp_dwd_evt_fee_doc_area t2 -- mdy 20211201
on t1.city_cd = t2.area_id
left join dw_tmp.tmp_dwd_evt_fee_doc_area t3 -- mdy 20211201
on t1.district_cd = t3.area_id
left join dw_base.dim_prod_code t4
on t1.guar_prod_cd = t4.code
left join dw_tmp.tmp_dwd_evt_fee_doc_yh t5  -- 应还信息
on t1.proj_dtl_no=t5.guar_id
where proj_dtl_stt is not null  -- -- 00-提报中10-审批中20-待签约30-待出函40-待放款50-已放款97-已作废98-已终止99-已否决91-不受理90-已解保
and rbl_fee is not null 
-- and proj_dtl_orig <> '02' -- 数据迁移
 ;
 
 commit ;

-- 普通循环贷缴保费
insert into dw_tmp.tmp_dwd_evt_fee_doc_guar
 select 
 proj_dtl_no
 ,cust_id
 ,cust_name
 ,cert_no
 ,t2.area_name 
 ,t3.area_name 
 ,case when proj_dtl_stt = '20' then '待签约'
       when proj_dtl_stt = '30' then '待出函' 
       when proj_dtl_stt = '40' then '待放款' 
	   when proj_dtl_stt = '50' then '已确认'
  end	   
 ,update_dt
 ,t4.value
 ,t5.rbl_fee 
 ,t5.rbl_fee_person 
 ,t5.rbl_fee_policy 
 from dw_base.dwd_agmt_guar_comm_info t1
left join dw_tmp.tmp_dwd_evt_fee_doc_area t2 -- mdy 20211201
on t1.city_cd = t2.area_id
left join dw_tmp.tmp_dwd_evt_fee_doc_area t3 -- mdy 20211201
on t1.district_cd = t3.area_id
left join dw_base.dim_prod_code t4
on t1.guar_prod_cd = t4.code
left join dw_tmp.tmp_dwd_evt_fee_doc_yh t5
on t1.proj_dtl_no=t5.guar_id
 where proj_dtl_stt = '50'  -- -- 00-提报中10-审批中20-待签约30-待出函40-待放款50-已放款97-已作废98-已终止99-已否决91-不受理90-已解保
 
 ;
 commit ;


 -- 插入数据
 -- 删除数据
 
 delete from dw_base.dwd_evt_fee_doc where day_id = '${v_sdate}';  -- DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d')  mdy
 commit ;
 
 -- 1.存在更新 更新项目状态
 update dw_base.dwd_evt_fee_doc t1 ,
        dw_tmp.tmp_dwd_evt_fee_doc_guar t2 
    set t1.day_id = '${v_sdate}' ,  -- DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d') ,   mdy
	    t1.guar_stt = t2.guar_stt , -- 业务状态
		-- t1.guar_upt_dt = t2.guar_upt_dt , -- 业务更新日期
		t1.guar_upt_dt = '${v_sdate}' , -- 业务更新日期 -- mdy 20220511
		t1.rbl_fee = t2.rbl_fee ,
		t1.guar_prod = t2.guar_prod ,
        t1.rbl_fee_person = t2.rbl_fee_person ,
        t1.rbl_fee_policy = t2.rbl_fee_policy 
  where	t1.guar_id = t2.guar_id
    and t1.guar_stt <> t2.guar_stt
	and t1.guar_stt <> '已退费' 
		;
 commit ;
 
  -- 1.存在更新 更新缴费金额，不更新日期  mdy 20220319
 update dw_base.dwd_evt_fee_doc t1 ,
        dw_tmp.tmp_dwd_evt_fee_doc_guar t2 
    set t1.rbl_fee = t2.rbl_fee ,
        t1.rbl_fee_person = t2.rbl_fee_person ,
        t1.rbl_fee_policy = t2.rbl_fee_policy 
  where	t1.guar_id = t2.guar_id
	and t1.rbl_fee is null 
	and t2.rbl_fee is not null
		;
 commit ;

-- 金额不一致更新 mdy 20220513
 update dw_base.dwd_evt_fee_doc t1 ,
        dw_tmp.tmp_dwd_evt_fee_doc_guar t2 
    set t1.rbl_fee = t2.rbl_fee ,
        t1.rbl_fee_person = t2.rbl_fee_person ,
        t1.rbl_fee_policy = t2.rbl_fee_policy 
  where	t1.guar_id = t2.guar_id
	and t1.rbl_fee <> t2.rbl_fee 
		;
 commit ; 
 
 -- 2.没有直接插入  
 
 insert into dw_base.dwd_evt_fee_doc
 (
     day_id  -- 数据日期',
     ,guar_id  -- 业务编号' ,
	 ,cust_id    -- 客户号',
	 ,cust_name  -- 客户名称',
     ,cert_no    -- 身份证号',
	 ,city_name  -- 城市',
     ,county_name -- 区县',
	 ,guar_stt    -- 业务状态' ,
	 ,guar_upt_dt -- 业务更新日期' ,
	 ,guar_prod   -- 担保产品' 
	 ,pay_stt     -- 缴费状态 1--缴费 0 未缴费 ,
	 ,rbl_fee
	 ,rbl_fee_person
	 ,rbl_fee_policy
 )
 select
 '${v_sdate}'  -- DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d')  mdy
 ,guar_id     -- 业务编号' ,
 ,cust_id     -- 客户号',
 ,cust_name   -- 客户名称',
 ,cert_no     -- 身份证号',
 ,city_name   -- 城市',
 ,county_name  -- 区县',
 ,guar_stt    -- 业务状态' ,
 ,guar_upt_dt -- 业务更新日期' ,
 ,guar_prod   -- 担保产品' 
 ,'0'
 ,rbl_fee
 ,rbl_fee_person
 ,rbl_fee_policy
 from dw_tmp.tmp_dwd_evt_fee_doc_guar t1
 where not exists(
 select 1 from dw_base.dwd_evt_fee_doc t2 
 where t1.guar_id = t2.guar_id and t2.day_id <='${v_sdate}'  -- DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d')
 )
 ;
 commit ;
 

 
-- 流水信息

drop table if exists dw_tmp.tmp_dwd_evt_fee_doc_evt ;

commit;

create  table dw_tmp.tmp_dwd_evt_fee_doc_evt (
     guar_id varchar(100) comment '业务编号' ,
	 pay_no varchar(50) comment '缴费流水号' ,
	 guar_fee decimal(18,2) comment '保费' ,
	 pay_type varchar(2) comment '缴费方式', -- mdy 20220525
	 pay_channel varchar(2) comment '缴费平台', -- mdy 20211117
	 pay_dt date comment '缴费日期' ,
	 index(guar_id)
	 )
	 ;
commit ;

insert into dw_tmp.tmp_dwd_evt_fee_doc_evt  	 
select
drawndn_seqno
,repay_seqno  -- 缴费流水号
,repay_fee    -- 保费
,pay_type     -- 缴费方式
,pay_channel  -- 缴费平台
,trade_date
from
(
	select 
	drawndn_seqno
	,repay_seqno  -- 缴费流水号
	,repay_fee    -- 保费
	,pay_type     -- 缴费方式
	,pay_channel  -- 缴费平台
	,date_format(trade_date,'%Y-%m-%d') trade_date
	from dw_nd.ods_gcredit_loan_ac_dxloanbookfee t1
	where t1.repay_mode='01' -- 缴费 -- mdy 20211119
	and date_format(trade_date,'%Y-%m-%d') <=  '${v_sdate}'  -- mdy

-- DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y-%m-%d')
) t
group by drawndn_seqno
;
commit ;  
 
 
-- 3.更新缴费信息
	
 update dw_base.dwd_evt_fee_doc t1 ,
        dw_tmp.tmp_dwd_evt_fee_doc_evt t2 
    set t1.day_id = '${v_sdate}',
	-- DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d') , 
	    t1.pay_stt = '1' , -- 缴费状态 1--缴费 0 未缴费 ,
		t1.pay_no = t2.pay_no , -- 缴费流水号
		t1.guar_fee = t2.guar_fee , -- 保费
		t1.pay_type = t2.pay_type ,-- 缴费方式 -- mdy 20220525
		t1.pay_channel = t2.pay_channel ,-- 缴费平台 -- mdy 20211117
		t1.pay_dt = t2.pay_dt -- 缴费日期
  where	t1.guar_id = t2.guar_id
    and coalesce(t1.pay_dt,'19000101') <> t2.pay_dt
	and t1.guar_stt <> '已退费'
		;

 commit ;
 

-- 创建临时表，获取当日退费信息 -- mdy 20221214 wyx

drop table if exists dw_tmp.tmp_dwd_evt_fee_doc_chg ;
commit;

CREATE TABLE dw_tmp.tmp_dwd_evt_fee_doc_chg (
  guar_id varchar(100) COMMENT '业务编号',
  change_type varchar(2) COMMENT '变化状态',
  difference_fee decimal(18,2) COMMENT '变动差额',
  index idx_tmp_dwd_evt_fee_doc_chg (guar_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='关联索引表';
commit; 

insert into dw_tmp.tmp_dwd_evt_fee_doc_chg
(
 guar_id
,change_type
,difference_fee
)
select
 drawndn_seqno
,change_type
,sum(difference_fee) as difference_fee
from
dw_nd.ods_gcredit_loan_ac_dxretustatfee 
where change_type = '1' -- 退费
and date_format(update_time,'%Y%m%d') = '${v_sdate}' -- 当日退费
group by drawndn_seqno
;
commit;
 
 
-- 更新正常缴费记录 -- mdy 20221214 wyx
 
update dw_base.dwd_evt_fee_doc t1 ,
       dw_tmp.tmp_dwd_evt_fee_doc_chg t2 
   set t1.day_id = '${v_sdate}' ,
	   t1.difference_fee = t2.difference_fee ,
   	   t1.change_type = t2.change_type
 where t1.guar_id = t2.guar_id
   and t1.pay_stt = '1'   -- 已缴费  	
	;
commit ; 

-- 4.增加字段：自动计算退费金额 20230817
drop table if exists dw_tmp.tmp_dwd_evt_fee_doc_refund ;
commit;

create table dw_tmp.tmp_dwd_evt_fee_doc_refund (
  guar_id            varchar(100)  comment '业务编号',
  refund_aply_amount decimal(18,6) comment '自动计算退费金额',
  index idx_tmp_dwd_evt_fee_doc_refund_id (guar_id)
) engine=innodb default charset=utf8mb4 collate=utf8mb4_bin comment='自动退费计算金额';
commit; 

insert into dw_tmp.tmp_dwd_evt_fee_doc_refund
( guar_id
 ,refund_aply_amount
)
select origin_code as guar_id
      ,refund_aply_amount
  from (
        select id, origin_code, refund_aply_amount
          from ( select id, origin_code, refund_aply_amount
                   from dw_nd.ods_t_biz_proj_refund 
                  where date_format(update_time, '%Y%m%d') <= '${v_sdate}'
                  order by update_time desc ) a 
         group by origin_code
        ) b 
 where coalesce(refund_aply_amount, 0) > 0
;
commit;

-- 更新 自动计算退费金额 20230817
update dw_base.dwd_evt_fee_doc t1 ,
       dw_tmp.tmp_dwd_evt_fee_doc_refund t2 
   set t1.day_id = '${v_sdate}' ,
	   t1.refund_aply_amount = t2.refund_aply_amount
 where t1.guar_id = t2.guar_id
   and coalesce(t1.refund_aply_amount, 0) <> t2.refund_aply_amount
;
commit;

-- 插入退费 和还保费

insert into dw_base.dwd_evt_fee_doc (
   day_id -- 数据日期',
   ,guar_id -- 业务编号',
   ,cust_id -- 客户号',
   ,cust_name -- 客户名称',
   ,cert_no -- 身份证号',
   ,city_name -- 城市',
   ,county_name -- 区县',
   ,guar_stt -- 业务状态',
   ,guar_upt_dt -- 业务更新日期',
   ,guar_prod -- 担保产品',
   ,pay_no -- 缴费流水号',
   ,guar_fee -- 保费',
   ,pay_stt -- 缴费状态',
   ,pay_type -- 缴费方式
	 ,pay_channel -- 缴费平台 1-农行平台,2-招行平台
   ,pay_dt -- 缴费日期',
   ,rbl_fee
   ,rbl_fee_person
   ,rbl_fee_policy
   ,refund_aply_amount
   ,deal_type -- 处理类型 0正常流程 1人工补录 -- mdy 20231228 wyx
	 ) 
 select 
 '${v_sdate}'
 -- DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d')
 ,t1.drawndn_seqno
 ,coalesce(t2.cust_id,t0.cust_id)
 ,coalesce(t2.cust_name,t0.cust_name)
 ,coalesce(t2.cert_no,t0.cust_identity_no)
 ,coalesce(t3.area_name,t7.area_name)     as    city_name -- 城市',
 ,coalesce(t4.area_name,t8.area_name)     as    county_name -- 区县', 
 ,'已退费' as repay_mode  -- mdy 20230201
 ,'${v_sdate}'     -- DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d')
 ,t5.value
 ,t1.repay_seqno
 ,t1.repay_fee
 ,'1'
 ,t1.pay_type -- mdy 20220525
 ,t1.pay_channel -- mdy 20211119
 ,date_format(t1.trade_date,'%Y-%m-%d') trade_date
 ,t6.rbl_fee 
 ,t6.rbl_fee_person 
 ,t6.rbl_fee_policy
 ,t9.refund_aply_amount
 ,null as deal_type -- mdy 20231228 wyx
 from dw_nd.ods_gcredit_loan_ac_dxloanbookfee t1 -- mdy 20211119
 left join dw_base.dwd_agmt_guar_info t2
 on t1.drawndn_seqno = t2.proj_dtl_no
 left join (
 select t.code,t1.cust_id,t1.code as origin_code,t1.city,t1.district,t1.cust_name,t1.cust_identity_no from (
		select project_id,code,id from (
		select project_id,code,id from dw_nd.ods_t_biz_proj_loan_check 
		where type = '01'
		and code is not null 
		order by db_update_time desc,update_time desc
		)t
		group by id
 )t
 inner join (
		select id,code,city,district,cust_name,cust_identity_no,cust_id from (
		select id,code,city,district,cust_name,cust_identity_no,cust_id from dw_nd.ods_t_biz_project_main
		order by db_update_time desc,update_time desc
		)t
		group by id
 )t1
 on t.project_id = t1.id
)t0
on t1.drawndn_seqno = t0.code
 left join dw_tmp.tmp_dwd_evt_fee_doc_area t3 -- mdy 20211201
 on t2.city_cd = t3.area_id
left join dw_tmp.tmp_dwd_evt_fee_doc_area t4 -- mdy 20211201
on t2.district_cd = t4.area_id
left join dw_tmp.tmp_dwd_evt_fee_doc_area t7 -- mdy 20211201
 on t0.city = t7.area_id
left join dw_tmp.tmp_dwd_evt_fee_doc_area t8 -- mdy 20211201
on t0.district = t8.area_id
left join dw_base.dim_prod_code t5
on t2.guar_prod_cd = t5.code
left join dw_tmp.tmp_dwd_evt_fee_doc_yh t6
on t1.drawndn_seqno=t6.guar_id
left join  dw_tmp.tmp_dwd_evt_fee_doc_refund t9 -- add 20230817
on t1.drawndn_seqno = t9.guar_id
where DATE_FORMAT(t1.update_time,'%Y%m%d')= '${v_sdate}'
and t1.repay_mode = '02'
;
commit ;

-- 更新deal_type字段
drop table if exists dw_tmp.tmp_dwd_evt_fee_doc_deal_type;commit;

create table dw_tmp.tmp_dwd_evt_fee_doc_deal_type (
     `code` varchar(100) comment '业务编号' ,
	   `deal_type` char(2) comment '处理类型 0正常流程 1人工补录',
	 index idx_tmp_dwd_evt_fee_doc_code(code)
)
;
commit ;

insert into dw_tmp.tmp_dwd_evt_fee_doc_deal_type
select distinct code,deal_type
from
(
	select id,code,deal_type from (
	select project_id,code,id,deal_type from dw_nd.ods_t_biz_proj_loan_check 
	where code is not null 
	order by db_update_time desc,update_time desc
	)t
	group by id
)t 
where deal_type is not null;
commit;

update dw_base.dwd_evt_fee_doc t1,
	dw_tmp.tmp_dwd_evt_fee_doc_deal_type t2
set t1.deal_type = t2.deal_type
where t1.guar_id = t2.code 
;
commit;