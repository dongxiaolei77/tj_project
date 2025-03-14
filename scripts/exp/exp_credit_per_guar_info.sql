-- ---------------------------------------
-- 开发人   : liyy
-- 开发时间 ：
-- 目标表   ： 
-- 源表     ：
-- 变更记录 ：20211116 切换代偿数据为业务关联系统数据
--            20220111  dw_nd.ods_gcredit_customer_login_info 替换为 dw_nd.ods_wxapp_cust_login_info          
--                      dw_nd.ods_gcredit_contract_info       替换为 dw_nd.ods_comm_cont_comm_contract_info zzy
-- 			  20220523  ods_t_sys_dept替换为dim_bank_info
-- 			  			补充银行名称
--            20220913 逻辑调整，是否信息使用授权书条件放到t1表内
-- ---------------------------------------


-- exp_credit_per_guar_info 个人担保信息

-- 1.获取授权客户
-- 2.获取所有放款日期小于等于当天的担保数据
-- 3.与昨日数据对比获取余额变动日期、五级分类变动日期、其他信息变动
-- 4.整合当日需要上报的数据 开户日期、关闭日期、余额变动日期、五级分类变动日期为当天、当天有其他信息变动
-- 分别对应 账户开立  账户关闭 在保责任变化 五级分类调整 其他信息变化

drop table dw_nd.`ods_imp_compt_cust_info`; commit;

CREATE TABLE dw_nd.`ods_imp_compt_cust_info` (
  `seq_id` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '流水号id',
  `item_stt` varchar(20) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '项目状态',
  `risk_stt` varchar(20) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '风险状态',
  `city_name` varchar(20) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '城市',
  `county_name` varchar(20) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '区县',
  `area_name` varchar(20) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '行政区划',
  `cust_name` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '客户名称',
  `cert_no` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '身份证号',
  `guar_class` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '国担分类',
  `ind_type` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '国标行业',
  loan_bank_id varchar(100) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '合作银行id',
  `loan_bank` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '合作银行名称',
  `bank_brev` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '合作银行简称',
  `loan_cont_id` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '借款合同号',
  `guar_cont_id` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '保证合同编号',
  `loan_amt` int(11) DEFAULT NULL COMMENT '借款合同金额',
  `prov_amt` int(11) DEFAULT NULL COMMENT '放款金额',
  `rate` decimal(8,4) DEFAULT NULL COMMENT '利率',
  `loan_beg_dt` varchar(20) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '放款起始日',
  `loan_end_dt` varchar(20) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '放款到期日',
  `compt_amt` decimal(18,4) DEFAULT NULL,
  `compt_dt` varchar(20) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '代偿日期',
  `repay_acct_bank` varchar(20) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '出款账户',
  `cust_type` varchar(20) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '客户类型',
  `repay_stt` varchar(20) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '代偿时还款状态',
  `is_repay` varchar(1) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '是否归还1：是0否',
  `repay_dt` varchar(20) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '归还日期',
  KEY `idx_ods_imp_compt_cust_info_cert` (`cert_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC COMMENT='代偿客户信息';

commit;
-- 代偿  20211116
 
insert into dw_nd.ods_imp_compt_cust_info 
select 
   t1.proj_code
   ,'已解保'
   ,'已代偿'   
   ,t1.city     -- 城市
   ,t1.district -- 区县
   ,t1.district -- 行政区划
   ,t1.cust_name -- 客户名称 KEY
   ,t1.cust_identity_no -- 身份证号 KEY
   ,null-- 国担分类
   ,null-- 国标行业
   ,t1.loans_bank -- 合作银行id
   ,coalesce(t3.bank_name,t1.loans_bank) -- 合作银行 KEY -- mdy 20220523 wyx
   ,null -- 合作银行简称 KEY
   ,t1.jk_contr_code -- 借款合同号
   ,null -- 保证合同编号
   ,null -- 借款合同金额
   ,null -- 放款金额
   ,null -- 利率
   ,t1.fk_start_date -- 放款起始日
   ,t1.fk_end_date -- 放款到期日
   ,t2.approp_totl -- 代偿金额 KEY
   ,t2.approp_date -- 代偿日期 KEY
   ,'' -- 出款账户
   ,'1' -- 客户类型 KEY
   ,null -- 代偿时还款状态
   ,0 -- 是否归还1：是0否 KEY
   ,null -- 归还日期
from
(  
   select
   id
   ,proj_code   
   ,city     -- 城市
   ,district -- 区县
   ,cust_name -- 客户名称 KEY
   ,cust_identity_no -- 身份证号 KEY
   ,loans_bank -- 合作银行 KEY
   ,jk_contr_code -- 借款合同号
   ,fk_start_date -- 放款起始日
   ,fk_end_date -- 放款到期日
   ,status
   from
   (select 
   id
   ,proj_code   
   ,city     -- 城市
   ,district -- 区县
    
   ,cust_name -- 客户名称 KEY
   ,cust_identity_no -- 身份证号 KEY
    
   ,loans_bank -- 合作银行 KEY
   
   ,jk_contr_code -- 借款合同号
    
   ,fk_start_date -- 放款起始日
   ,fk_end_date -- 放款到期日
	 ,status
   ,db_update_time
   ,row_number() over (partition by id order by db_update_time desc) rn
   from dw_nd.ods_t_proj_comp_aply
   where date_format(db_update_time,'%Y%m%d') <= '${v_sdate}'
   ) t
   where rn = 1
) t1
inner join 
(
   select 
   comp_id
   ,approp_date
   ,approp_totl
	 from
   (
   select
   comp_id
   ,approp_date
   ,approp_totl
   ,db_update_time
   ,row_number() over (partition by comp_id order by db_update_time desc) rn
   from dw_nd.ods_t_proj_comp_appropriation
   where date_format(db_update_time,'%Y%m%d') <= '${v_sdate}'
   ) t
   where rn = 1
) t2
on t1.id = t2.comp_id
left join dw_base.dim_bank_info t3 -- mdy 20220523 wyx
on t1.loans_bank = t3.bank_id
inner join 
(
select distinct code from dw_nd.ods_t_biz_project_main where main_type='01'
) t4 
on t1.proj_code = t4.code
where t1.status = '50' -- 已代偿
;

commit;




-- insert into dw_nd.ods_imp_compt_cust_info --20211116 切换数据源
-- select 
--  t1.seq_id -- 流水号id
-- ,'已解保' -- 项目状态
-- ,'已代偿' -- 风险状态
-- ,t1.city_name -- 城市
-- ,t1.county_name -- 区县
-- ,t1.city_name -- 行政区划
-- ,t1.cust_name -- 客户名称
-- ,t1.id_number -- 身份证号
-- ,t1.guarantee_class -- 国担分类
-- ,t1.operation_business -- 国标行业
-- ,t1.loan_bank -- 合作银行
-- ,t1.loan_bank -- 合作银行简称
-- ,t1.loan_conteact_id -- 借款合同号
-- ,t1.counter_guarantee_id -- 保证合同编号
-- ,t1.loan_conteact_amount -- 借款合同金额
-- ,t1.loan_conteact_amount -- 放款金额
-- ,t1.loan_conteact_rate -- 利率
-- ,t1.loan_begin_date -- 放款起始日
-- ,t1.loan_end_date -- 放款到期日
-- ,t1.s_compt_amt -- 代偿金额
-- ,t1.s_compt_dt -- 代偿日期
-- ,'' -- 出款账户
-- ,'1' -- 客户类型
-- ,null -- 代偿时还款状态
-- ,0 -- 是否归还1：是0否
-- ,null -- 归还日期
-- -- from dw_nd.ods_imp_portrait_info_new t1 
-- from dw_base.tmp_exp_credit_per_cust_compt t1
-- 
-- ;
-- commit;

-- 1.获取授权客户
-- 登录信息
drop table if exists dw_base.tmp_exp_credit_per_cust_info_login ;

commit;

create  table dw_base.tmp_exp_credit_per_cust_info_login (
cust_id varchar(60) -- 客户编号                                   -- 原表通过 login_no 登陆编号关联，新表没有该字段，现通过cust_id关联    20220111
,name varchar(30) -- 客户名称
,id_type    varchar(2)  -- 证件类型 
,id_num      varchar(20) -- 证件号
,key(cust_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;

commit;

insert into dw_base.tmp_exp_credit_per_cust_info_login
select  customer_id
		,main_name
		,main_id_type
		,main_id_no    
from
(
select customer_id,main_name,main_id_type,main_id_no,update_time,row_number() over (partition by MAIN_ID_NO order by UPDATE_TIME desc) rn
from dw_nd.ods_wxapp_cust_login_info                                -- 关联新表 (原表：dw_nd.ods_gcredit_customer_login_info)                  20220111
where login_type = '1'  -- 个人                                     
and customer_id is not null 
and main_id_no is not null
) t
where rn = 1
;
commit ;

-- 签定使用授权书

  
drop table if exists dw_base.tmp_exp_credit_per_cust_info_sq ;

commit;

create  table dw_base.tmp_exp_credit_per_cust_info_sq (
cust_id varchar(60) -- 客户编号
,key(cust_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;

commit;

insert into dw_base.tmp_exp_credit_per_cust_info_sq
select t1.cust_code 
from (
	select cust_code,auth_letter_valid_status
	from (
		select cust_code,             -- 客户号
               auth_letter_valid_status,
		       row_number() over (partition by cust_code order by update_time desc) rn
		from dw_nd.ods_comm_cont_auth_letter_contract_info   -- 客户授权书信息表
		where type = '0' -- 信息使用授权书
	) a  
	where rn = 1
) t1
where auth_letter_valid_status = 'valid' -- 有效 
;
commit;


drop table if exists dw_base.tmp_exp_credit_per_cust_info_id ;

commit;

create  table dw_base.tmp_exp_credit_per_cust_info_id (
cust_id varchar(60) -- 客户编号
,name varchar(30) -- 客户名称
,id_type    varchar(2)  -- 证件类型 
,id_num      varchar(20) -- 证件号
,key(cust_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;

commit;


-- 客户信息 获取授权
insert into dw_base.tmp_exp_credit_per_cust_info_id
select 
t1.cust_id
,t1.name
,t1.id_type
,t1.id_num
from dw_base.tmp_exp_credit_per_cust_info_login  t1  -- 登录信息
inner join dw_base.tmp_exp_credit_per_cust_info_sq t2 -- 授权信息
on t1.cust_id = t2.cust_id                       -- 修改关联条件   20220111   原为登陆账号关联
group by t1.id_num
;

commit;

-- 2.获取所有放款日期小于等于当天的担保数据
-- 担保信息
drop table if exists dw_base.tmp_exp_credit_per_guar_info_guar ;

commit ;

create  table dw_base.tmp_exp_credit_per_guar_info_guar (
guar_id	varchar(60)	comment '账号'
,cust_id	varchar(60)	comment '客户号'
,open_date	date	comment '开户日期'
,acct_cred_line	int	comment '担保金额'
,due_date	date	comment '到期日期'
,ctrct_txt_cd	varchar(60)	comment '担保合同文本编号'
,acct_status	varchar(1)	comment '账户状态'
,loan_amt	int	comment '在保余额'
,repay_prd	date	comment '余额变化日期'
,five_cate	varchar(1)	comment '五级分类'
,five_cate_adj_date	date	comment '五级分类认定日期'
,ri_ex	varchar(15)	comment '风险敞口'
,comp_adv_flag	varchar(1)	comment '代偿标志'
,close_date	varchar(20)	comment '关闭日期'
,key(guar_id)
) ;

commit ;


-- 取账户关闭日期
-- 项目取最后一次【其他状态】->【90】(或首行=90)的更新时间作为账户关闭日期
drop table if exists dw_tmp.tmp_exp_credit_per_guar_info_close_date; commit;
create table dw_tmp.tmp_exp_credit_per_guar_info_close_date (
code varchar(50) comment '业务编号',
project_id varchar(50) comment 'project_id',
close_date varchar(20) comment '关户日期',
index idx_per_guar_info_close_date(project_id)
);
commit;

insert into dw_tmp.tmp_exp_credit_per_guar_info_close_date
select code,id,max(db_update_time) as db_update_time
from (
		select 
		id
		,code
		,proj_status
		,date_format(db_update_time,'%Y-%m-%d')  db_update_time
		,update_time
		,create_time
		,@diff_rw := case when @project_id=id and @proj_status!='90' and proj_status='90' then 1 -- 同一项目,从其他状态变为90(解保)所在行
						  when @project_id!=id and proj_status='90' then 1 -- 项目首行就是90所在行
						  else 0 
						  end as diff_rw
		,@proj_status := proj_status
		,@project_id := id
		from dw_nd.ods_t_biz_project_main
		,(select @diff_rw:=0,@proj_status := '',@project_id := '') t
		order by id,db_update_time asc,update_time asc
		) a
where diff_rw=1
group by id
;
commit;	


-- 准备担保数据

drop table if exists dw_base.tmp_exp_credit_per_guar_info_all ;
CREATE TABLE dw_base.tmp_exp_credit_per_guar_info_all (
   day_id varchar(8)  comment '数据日期',
   guar_id varchar(60)  comment '担保id',
   cust_id varchar(60)  comment '客户号',
   cert_no varchar(20)  comment '债务人证件号码',
   loan_begin_dt date  comment '贷款开始时间',
   loan_amt int(11)  comment '担保金额',
   loan_end_dt date  comment '到期日期',
   protect_guar varchar(20)  comment '0-信用/免担保 1-保证 2-质押 3-抵押 4-组合',
   ctrct_txt_cd varchar(20)  comment '担保合同文本编号',
   acct_status varchar(1)  comment '账户状态账户状态  1-正常 2-关闭',  
   loan_bal int(11)  comment '在保余额',
   repay_prd date  comment '余额变化日期',
   five_cate varchar(1)  comment '五级分类',
   five_cate_adj_date date  comment '五级分类认定日期',
   ri_ex varchar(15)  comment '风险敞口',
   comp_adv_flag varchar(1)  comment '代偿(垫款)标志',
   close_date varchar(20)  comment '账户关闭日期',
   data_source varchar(20)  comment '数据来源',
   key  (guar_id)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC COMMENT='个人担保信息数据准备'
 ;
 
-- 插入进件数据
insert into dw_base.tmp_exp_credit_per_guar_info_all
select
   DATE_FORMAT('${v_sdate}','%Y%m%d') as day_id
   ,t1.proj_no as guar_id -- 担保id 
   ,t1.cust_id as cust_id -- 客户号
   ,t1.cert_no as cert_no -- 债务人证件号码
   ,t1.loan_cont_beg_dt as loan_begin_dt -- 贷款开始时间
   ,t1.loan_cont_amt*10000 as loan_amt -- 担保金额
   ,t1.loan_cont_end_dt as loan_end_dt -- 到期日期
   ,case when length(t1.oppos_guar_cd) > 6 then '4'
         when t1.oppos_guar_cd like '%02%' then '3' 
		 when t1.oppos_guar_cd like '%03%' then '2' 
		 when t1.oppos_guar_cd like '%04%' then '1' 
		 else '0' 
		 end protect_guar -- 0-信用/免担保 1-保证 2-质押 3-抵押 4-组合    00	其他 01	无 02	抵押 03	质押 04	保证 05	以物抵债
   ,t2.fk_letter_code as ctrct_txt_cd -- 担保合同文本编号  mdy 202408 由空值报送改为放款通知书
   ,case when  t1.proj_stt = '50' then '1' 
         when  t1.proj_stt = '90' then '2' 
         end acct_status	 -- 账户状态账户状态  1-正常 2-关闭
   ,t1.loan_cont_amt*10000 as loan_bal -- 在保余额',
   ,DATE_FORMAT('${v_sdate}','%Y-%m-%d') as repay_prd -- 余额变化日期
   ,'1' as five_cate -- 五级分类' 1-正常
   ,DATE_FORMAT('${v_sdate}','%Y-%m-%d') as five_cate_adj_date -- 五级分类认定日期
   ,t1.loan_cont_amt*10000 as ri_ex -- 风险敞口 mdy 202408 由空值报送改为合同金额
   ,'0' as comp_adv_flag -- 代偿(垫款)标志
   ,case when t1.proj_stt='90'  then t3.close_date
	  else '' end as close_date -- 账户关闭日期    mdy 202408 由合同到期日报送改为状态变为 解保的日期
   ,'新担保业务平台2' as data_source -- 数据来源
from dw_base.dwd_agmt_guar_proj_info t1
left join 
(
	select 
	project_id,fk_letter_code
	from(
		 select 
		 project_id,fk_letter_code,row_number() over (partition by project_id order by db_update_time desc,update_time desc) rn
		 from dw_nd.ods_t_biz_proj_loan
		 ) a
	where rn = 1
 )t2 
 on t1.proj_id=t2.project_id
left join dw_tmp.tmp_exp_credit_per_guar_info_close_date t3 
on t1.proj_id=t3.project_id
where proj_stt in ('50','90')  -- 50-已放款 90-已解保
and main_type_cd = '01'  -- 自然人
and loan_cont_beg_dt <= DATE_FORMAT('${v_sdate}','%Y-%m-%d')
and loan_cont_end_dt is not null 
and loan_cont_beg_dt is not null
-- and loan_cont_end_dt <> ''
-- and loan_cont_beg_dt <> ''
and loan_cont_beg_dt < loan_cont_end_dt  -- 到期日期大于开始日期
-- and loan_cont_beg_dt >= '20201201'  -- 发版修改
and proj_orig  <> '02'  -- 01-担保业务系统，02-迁移数据（企业微信、潍坊V贷等历史数据）, 03-潍坊对接，04-重构后数据迁移
;

commit ;


-- 	存放当天个人担保账户信息临时数据
drop table if exists dw_base.tmp_exp_credit_per_guar_info_ready ;
CREATE TABLE dw_base.tmp_exp_credit_per_guar_info_ready (
   day_id varchar(8)  comment '数据日期',
   guar_id varchar(60)  comment '担保id',
   cust_id varchar(60)  comment '客户号',
   acct_type varchar(2)  comment '账户类型',
   acct_code varchar(60)  comment '账户标识码',
   rpt_date date  comment '信息报告日期',
   rpt_date_code varchar(2)  comment '报告时点说明代码',
   name varchar(30)  comment '债务人姓名',
   id_type varchar(2)  comment '债务人证件类型',
   id_num varchar(20)  comment '债务人证件号码',
   mngmt_org_code varchar(14)  comment '业务管理机构代码',
   busi_lines varchar(1)  comment '担保业务大类',
   busi_dtil_lines varchar(2)  comment '担保业务种类细分',
   open_date date  comment '开户日期',
   acct_cred_line int(11)  comment '担保金额',
   cy varchar(3)  comment '币种',
   due_date date  comment '到期日期',
   guar_mode varchar(1)  comment '反担保方式',
   oth_repy_guar_way varchar(1)  comment '其他还款保证方式',
   sec_dep int(11)  comment '保证金比例',
   ctrct_txt_cd varchar(60)  comment '担保合同文本编号',
   acct_status varchar(1)  comment '账户状态',
   loan_amt int(11)  comment '在保余额',
   repay_prd date  comment '余额变化日期',
   five_cate varchar(1)  comment '五级分类',
   five_cate_adj_date date  comment '五级分类认定日期',
   ri_ex varchar(15)  comment '风险敞口',
   comp_adv_flag varchar(1)  comment '代偿(垫款)标志',
   close_date varchar(20)  comment '账户关闭日期',
   data_source varchar(20)  comment '数据来源',
   key  (guar_id)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC COMMENT='个人担保信息临时表'
 
 ;
commit ;

-- 道一云 新担保业务中台
insert into dw_base.tmp_exp_credit_per_guar_info_ready

select 
'${v_sdate}'
,t1.guar_id -- 担保ID
,t1.cust_id -- 客户号
,'G1' -- 账户类型
,CONCAT('X3701010000337',replace(t1.guar_id,'-','')) -- 账户标识码
,DATE_FORMAT('${v_sdate}','%Y-%m-%d') -- 信息报告日期
-- ,case when acct_status = '1' then '10' else '20' end -- 报告时点说明代码
,''
,t2.name -- 债务人姓名
,t2.id_type -- 债务人证件类型
,t2.id_num -- 债务人证件号码
,'X3701010000337' -- 业务管理机构代码
,'1' -- 担保业务大类
,'01' -- 担保业务种类细分
,DATE_FORMAT(t1.open_date,'%Y-%m-%d') -- 开户日期
,t1.acct_cred_line -- 担保金额
,'CNY' -- 币种
,t1.due_date   -- 到期日期
,protect_guar -- 反担保方式
,'0' -- 其他还款保证方式
,0 -- 保证金比例
,t1.ctrct_txt_cd -- 担保合同文本编号
,case when t3.seq_id is not null then '2' -- 有代偿 则代 关闭
      when t1.close_date = '' then '1'
      when t1.close_date <= DATE_FORMAT('${v_sdate}','%Y-%m-%d') then '2'
	  else '1'
      end   -- 账户状态  如果 关闭日期 >= 跑批日期，则为 关闭，否则正常 1-正常 2-关闭
,case when t1.close_date = '' then  t1.loan_amt 
      when t1.close_date <= DATE_FORMAT('${v_sdate}','%Y-%m-%d') then 0
	  else t1.loan_amt
	  end -- 在保余额
,repay_prd -- 余额变化日期
,t1.five_cate -- 五级分类
,five_cate_adj_date -- 五级分类认定日期
,t1.ri_ex -- 风险敞口
,case when t3.seq_id is not null then 1 else 0 end -- 代偿(垫款)标志
,case when t3.seq_id is not null then case when t3.compt_dt > t1.close_date 
                                           then DATE_FORMAT(t3.compt_dt,'%Y-%m-%d') 
                                      else t1.close_date end  -- 有代偿则代偿日期为关闭日期
      when t1.close_date = '' then ''
      when t1.close_date <= DATE_FORMAT('${v_sdate}','%Y-%m-%d') then t1.close_date
	  else ''
      end	  -- 账户关闭日期 如果 跑批日期>=关闭日期  ，则为 关闭日期，否则正常
,data_source -- 数据来源
from
(
select 
cust_id
,guar_id  -- 账号
,cert_no id_num -- 证件号码
,loan_begin_dt   open_date -- 贷款开始时间   开户日期 
,loan_amt acct_cred_line -- 担保金额 
,loan_end_dt   due_date -- 到期日期
,protect_guar   -- 0-信用/免担保 1-保证 2-质押 3-抵押 4-组合
,ctrct_txt_cd -- 担保合同文本编号 
,acct_status -- 账户状态  1-正常 2-关闭
,loan_bal  loan_amt -- 在保余额
,repay_prd-- 余额变化日期
,five_cate -- 五级分类
,five_cate_adj_date -- 五级分类认定日期
,ri_ex -- 风险敞口
,comp_adv_flag -- 代偿标志
,close_date -- 关闭日期
,data_source	  
from  dw_base.tmp_exp_credit_per_guar_info_all
) t1
inner join dw_base.tmp_exp_credit_per_cust_info_id t2 
on t1.cust_id = t2.cust_id
-- left join dw_nd.ods_imp_compt_cust_info t3 -- 代偿信息表
left join dw_nd.ods_imp_compt_cust_info t3 -- 代偿信息表
on t1.guar_id = t3.seq_id
and t3.cust_type ='1' -- 个人
AND t3.compt_dt <=  DATE_FORMAT('${v_sdate}','%Y-%m-%d')
where  DATE_FORMAT(t1.open_date,'%Y-%m-%d') <= DATE_FORMAT('${v_sdate}','%Y-%m-%d')
and  (t1.close_date  <=  DATE_FORMAT('${v_sdate}','%Y-%m-%d') or t1.close_date = '' )  -- 当天解保
;

commit ;




--

-- 3.与昨日数据对比获取余额变动日期、五级分类变动日期、其他信息变动
-- 存放当天数据



DELETE FROM dw_base.exp_credit_per_guar_info_ready where day_id = '${v_sdate}' ;

commit;

insert into dw_base.exp_credit_per_guar_info_ready
select
t1.day_id    -- 数据日期
,t1.guar_id    -- 担保id
,t1.cust_id    -- 客户号
,t1.acct_type    -- 账户类型
,t1.acct_code    -- 账户标识码
,t1.rpt_date    -- 信息报告日期
,t1.rpt_date_code    -- 报告时点说明代码
,t1.name    -- 债务人姓名
,t1.id_type    -- 债务人证件类型
,t1.id_num    -- 债务人证件号码
,t1.mngmt_org_code    -- 业务管理机构代码
,t1.busi_lines    -- 担保业务大类
,t1.busi_dtil_lines    -- 担保业务种类细分
,t1.open_date    -- 开户日期
,t1.acct_cred_line    -- 担保金额
,t1.cy    -- 币种
,t1.due_date    -- 到期日期
,t1.guar_mode    -- 反担保方式
,t1.oth_repy_guar_way    -- 其他还款保证方式
,t1.sec_dep    -- 保证金比例
,t1.ctrct_txt_cd    -- 担保合同文本编号
,t1.acct_status    -- 账户状态
,t1.loan_amt    -- 在保余额
,case when t2.guar_id is null then t1.open_date   -- 昨天没有取 开户日期
      when abs(t1.loan_amt - t2.loan_amt) > 0 then t1.repay_prd  -- 发生变动取跑批日期
	  else t2.repay_prd end    -- 余额变化日期    昨天有，且没有变化 取昨天开户日期
,t1.five_cate    -- 五级分类
,case when t2.guar_id is null then t1.open_date  -- 昨天没有取 开户日期
      when t1.five_cate <> t2.five_cate then t1.five_cate_adj_date  -- 发生变动取跑批日期
	  when t1.open_date < t3.open_date then t3.open_date
	  else t2.five_cate_adj_date end    -- 五级分类认定日期  昨天有，且没有变化 取昨天开户日期
,t1.ri_ex    -- 风险敞口
,t1.comp_adv_flag    -- 代偿(垫款)标志
,t1.close_date    -- 账户关闭日期
,t1.data_source    -- 数据来源
from (
select * from dw_base.tmp_exp_credit_per_guar_info_ready
where day_id = '${v_sdate}'
) t1
left join dw_base.exp_credit_per_guar_info_ready t2
on t1.guar_id = t2.guar_id
and t2.day_id = '${v_yesterday}' 
left join (
	select t.guar_id,t.open_date 
	from dw_base.exp_credit_per_guar_info_ready t
	inner join (
	select guar_id,min(day_id) day_id
	from dw_base.exp_credit_per_guar_info_ready
	group by guar_id
	)t1
	on t.guar_id = t1.guar_id
	and t.day_id = t1.day_id
)t3
on t1.guar_id = t3.guar_id
;
commit;



-- 还款责任人信息

-- 相关还款责任人（只在账户开立的时候上报）

-- 每笔业务对应的反担保人信息,共同借款人信息
drop table if exists dw_tmp.tmp_exp_credit_per_guar_info_xz_counter ;
commit;

create table dw_tmp.tmp_exp_credit_per_guar_info_xz_counter (
	duty_type          varchar(60),
	apply_code         varchar(60),
	project_id         varchar(60),
	counter_name       varchar(60),
	id_type            varchar(4),
	id_no              varchar(40),
	index idx_tmp_exp_credit_per_guar_info_xz_counter_project_id(project_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC 
;
commit;

insert into dw_tmp.tmp_exp_credit_per_guar_info_xz_counter

select 
		'2' as duty_type, -- 1-共同债务人 2-反担保人 9-其他
        t1.apply_code,
		t1.guar_id,
 		t2.counter_name, -- 反担保人名称
		t2.id_type,   -- 反担保人证件类型
		t2.id_no      -- 反担保人证件号
from 
	(
	    select 
	    	guar_id,
	    	apply_code
	    from
	    	(
	    	    select 
	    	    	guar_id,
	    	    	apply_code,
	    	        row_number() over (partition by apply_code order by update_time desc) rn
	    	    from dw_nd.ods_bizhall_guar_apply  -- 客户申请表
	    	    where date_format(update_time,'%Y%m%d') <=  '${v_sdate}'
	    	    and guar_id is not null
	    	) t 
	    where rn = 1
	)t1
inner join 
(
    select 
    	apply_code,
    	counter_name,
    	coalesce(id_type,ident_type)id_type,
    	id_no
    from
    	(
    	    select 
    	    	apply_code,
    	    	counter_name,
    	    	id_type,  -- 10 证件号  20 企业信用代码
						case when id_no like '9%' then '20' else '10' end ident_type,
    	    	id_no,
    	        row_number() over (partition by apply_code,id_no,counter_name order by update_time desc) rn
    	    from dw_nd.ods_bizhall_guar_apply_counter -- 反担保关联表  status状态字段不用限制
    	    where date_format(update_time,'%Y%m%d') <=  '${v_sdate}'
    	) t
    where rn = 1
)t2
on t1.apply_code = t2.apply_code
union all
select distinct 
		'1' as duty_type, -- 1-共同债务人 2-反担保人 9-其他
        t1.apply_code,
		t1.guar_id,
 		coalesce(t1.bank_part_name,t2.part_name), -- 共同借款人名称
		t2.id_type,   -- 共同借款人证件类型
		coalesce(t1.bank_part_id_no,t2.id_no)      -- 共同借款人证件号
from 
	(
	    select 
	    	guar_id,
	    	apply_code,
	    	bank_part_name,
	    	bank_part_id_no
	    from
	    	(
	    	    select 
	    	    	guar_id,
	    	    	apply_code,
	    	    	bank_part_name, -- 共同借款人姓名
	    	    	bank_part_id_no, -- 共同借款人身份证号
	    	        row_number() over (partition by apply_code order by update_time desc) rn
	    	    from dw_nd.ods_bizhall_guar_apply  -- 客户申请表
	    	    where date_format(update_time,'%Y%m%d') <=  '${v_sdate}'
	    	    and guar_id is not null
	    	) t 
	    where rn = 1
	)t1
inner join	
(
    select 
    	apply_code,
    	part_name,
    	coalesce(id_type,ident_type)id_type,
    	id_no
    from
    	(
    	    select 
    	    	apply_code,
    	    	part_name,
    	    	id_type,  -- 10 证件号  20 企业信用代码
				case when id_no like '9%' then '20' else '10' end ident_type,
    	    	upper(id_no) id_no,
    	        row_number() over (partition by apply_code,upper(id_no) order by update_time desc) rn
    	    from dw_nd.ods_bizhall_guar_apply_part -- 共同申保人关联表
    	    where date_format(update_time,'%Y%m%d') <=  '${v_sdate}'
			and part_name is not null
    	) t
    where rn = 1
)t2
on t1.apply_code = t2.apply_code
inner join (
	select id,code,spouse_co_borrower
	from (
		select id,code,spouse_co_borrower,row_number() over (partition by id order by db_update_time desc,update_time desc) rn
		from dw_nd.ods_t_biz_project_main
	)t
	where rn = 1
) t3 
on t1.guar_id = t3.id and t3.spouse_co_borrower is true
;
commit;


-- 授权的反担保人/共同借款人
drop table if exists dw_tmp.tmp_exp_credit_per_guar_info_xz_counter_sq ;
commit;

create table dw_tmp.tmp_exp_credit_per_guar_info_xz_counter_sq (
    duty_type          varchar(60),
	apply_code         varchar(60),
	project_id         varchar(60),
	counter_name       varchar(60),
	id_type            varchar(4),
	id_no              varchar(40),
	cust_code          varchar(40),
	index credit_per_guar_info_xz_counter_sq_project_id(project_id),
	index credit_per_guar_info_xz_counter_sq_ct_guar_person_id_no(id_no),
	index credit_per_guar_info_xz_counter_sq_cust_code(cust_code)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC 
;
commit;

insert into dw_tmp.tmp_exp_credit_per_guar_info_xz_counter_sq
select distinct 
	   t.duty_type, -- 1-共同债务人 2-反担保人 9-其他
	   t.apply_code,
       t.project_id,   -- 担保业务系统ID
       replace(replace(trim(t.counter_name),char(9),''),char(13),''),  -- 反担保人/共同借款人名称
       t.id_type,  -- 反担保人/共同借款人证件类型
       t.id_no,  -- 反担保人/共同借款人证件号
	   t2.cust_code  -- 反担保人/共同借款人客户号
from dw_tmp.tmp_exp_credit_per_guar_info_xz_counter t -- 每笔申请记录对应的反担保人信息
inner join 
(
  select customer_id
  		,main_name
  		,coalesce(main_id_type,ident_type)main_id_type
  		,main_id_no    
  from
  (
    select customer_id,
		       main_name,
					 main_id_type,
					 case when main_id_no like '9%' then '20' else '10' end ident_type,
					 main_id_no,
               row_number() over (partition by MAIN_ID_NO order by UPDATE_TIME desc) rn
    from dw_nd.ods_wxapp_cust_login_info     -- 用户注册信息
    where status = '10'  -- 已授权   授权的客户证件号都不为空，去掉了 customer_id is not null and main_id_no is null 这个条件
  ) t
  where rn = 1
)t1
on t.id_no = t1.main_id_no   
left join (select cust_code,id_no from (select cust_code,id_no,row_number() over (partition by cust_code order by update_time desc) rn from dw_nd.ods_crm_cust_info)t where rn = 1)t2  -- mdy 20240911，之前是按照id_No取最新，但是会存在一个证件号对应多个客户号的情况，漏掉客户号，导致后面关联不到合同
on t.id_no = t2.id_no
;
commit;

-- 反担保合同
drop table if exists dw_tmp.tmp_exp_credit_per_guar_info_xz_counter_contract ;
commit;

create table dw_tmp.tmp_exp_credit_per_guar_info_xz_counter_contract (
	biz_id                varchar(64),
	contract_id           varchar(128),
	customer_id           varchar(64),
	contract_template_id  varchar(64),
	-- AUTHORIZED_CUSTOMER_ID varchar(64),
	index idx_tmp_exp_credit_per_guar_info_xz_counter_contract_biz_id(biz_id),
	index tmp_exp_credit_per_guar_info_xz_counter_contract_customer_id(customer_id)
	-- index tmp_exp_credit_per_guar_info_xz_counter_contract_AUTHORIZED_id(AUTHORIZED_CUSTOMER_ID)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC 
;
commit;

insert into dw_tmp.tmp_exp_credit_per_guar_info_xz_counter_contract
select biz_id
       ,contract_id  -- 合同编号
	   ,customer_id -- 签署人客户号
       ,contract_template_id -- 合同模板id
from (
select biz_id
       ,contract_id  -- 合同编号
	   ,customer_id -- 签署人客户号
	   ,concat('X3701010000337',contract_template_id) as contract_template_id -- 合同模板id
       ,status
from 
(
    select biz_id
           ,contract_id  -- 合同编号
    	   ,coalesce(AUTHORIZED_CUSTOMER_ID,customer_id )customer_id  -- 签署人客户号（自然人）
    	   ,contract_template_id  -- 合同模板id
		  --  ,AUTHORIZED_CUSTOMER_ID -- -- 签署人客户号（企业）
          ,status
          ,row_number() over (partition by BIZ_ID,CUSTOMER_ID order by UPDATE_TIME desc) rn
    from dw_nd.ods_comm_cont_comm_contract_info  -- 当反担保人是自然人，如果crm存在cust_code，customer_id填充cust_code，若无，填充证件号
    where contract_name like '%反担保%'          -- 当反担保人是企业，如果crm存在cust_code，customer_id填充法定代表人的cust_code，AUTHORIZED_CUSTOMER_ID填充企业的cust_code                                                                     -- 若无，customer_id填充法定代表人的证件号，AUTHORIZED_CUSTOMER_ID填充企业的统一社会编码
    and contract_name not like '%反担保抵押%'
    and contract_name not like '%反担保质押%'
)a
where rn = 1
)t
where status = '2' -- 已签约 
;
commit;

-- 补充反担保合同（线下签约）[合同号带‘线下’字样的属于线下签约]
drop table if exists dw_tmp.tmp_exp_credit_per_guar_info_xz_counter_contract_xx ;
commit;

create table dw_tmp.tmp_exp_credit_per_guar_info_xz_counter_contract_xx (
	project_id                varchar(64),
	ct_guar_person_name       varchar(128),
	ct_guar_person_id_no      varchar(64),
	count_cont_code           varchar(64),
	index idx_tmp_xz_counter_contract_xx_project_id(project_id),
	index idx_tmp_xz_counter_contract_xx_ct_guar_person_id_no(ct_guar_person_id_no)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC 
;
commit;

insert into dw_tmp.tmp_exp_credit_per_guar_info_xz_counter_contract_xx

select project_id
	  ,ct_guar_person_name  -- 反担保人姓名
	  ,ct_guar_person_id_no -- 反担保人证件号
	  ,replace(count_cont_code,'线下','XX')      -- 反担保合同
from (
	select id  
	       ,project_id
		   ,ct_guar_person_name
		   ,ct_guar_person_id_no
		   ,count_cont_code
	       ,row_number() over (partition by project_id ,ct_guar_person_name,ct_guar_person_id_no order by db_update_time desc,update_time desc) rn
	from dw_nd.ods_t_ct_guar_person
	where count_cont_code is not null
)t
where rn = 1
;
commit;

-- 担保业务系统id 和项目编号转换
drop table if exists dw_tmp.tmp_exp_credit_per_guar_info_xz_counter_main;
commit;

create table dw_tmp.tmp_exp_credit_per_guar_info_xz_counter_main (
    project_id         varchar(60),
	guar_id            varchar(60),
	index credit_per_guar_info_xz_counter_main_project_id(project_id),
	index credit_per_guar_info_xz_counter_main_ct_guar_person_id_no(guar_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC 
;
commit;

insert into dw_tmp.tmp_exp_credit_per_guar_info_xz_counter_main
select id,
	   code
from (
select id,
	   code,
       row_number() over (partition by id order by db_update_time desc,update_time desc) rn
from dw_nd.ods_t_biz_project_main
)a
where rn = 1
;
commit;



-- 从风险检查表中拿产业集群信息
drop table if exists dw_tmp.tmp_exp_credit_per_guar_info_check;
commit;

create table dw_tmp.tmp_exp_credit_per_guar_info_check (
    project_id         varchar(60),
	aggregate_scheme   varchar(60),
	index tmp_exp_credit_comp_guar_info_checkproject_id(project_id),
	index tmp_exp_credit_comp_guar_info_check_aggregate_scheme(aggregate_scheme)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC 
;
commit;

insert into dw_tmp.tmp_exp_credit_per_guar_info_check
select project_id,
	   aggregate_scheme
from (
select project_id,
	   aggregate_scheme,
       row_number() over (partition by project_id order by update_time desc) rn
from dw_nd.ods_t_risk_check_opinion
)a
where rn = 1
;
commit;

-- 核心企业管理中企业分险
drop table if exists dw_tmp.tmp_exp_credit_per_guar_info_risk_comp; commit;
create table if not exists dw_tmp.tmp_exp_credit_per_guar_info_risk_comp(
company_name varchar(200) comment'企业名称',
unified_social_credit_code varchar(50) comment '统一社会信用代码',
counter_guar_contract_number varchar(50) comment '反担保合同',
risk_grade varchar(255) comment'分险比例',
dictionaries_code varchar(50) comment '产业集群'
);
commit;

insert into dw_tmp.tmp_exp_credit_per_guar_info_risk_comp
select t1.company_name,t1.unified_social_credit_code,t2.counter_guar_contract_number,t2.risk_grade,t2.dictionaries_code
from (
	select * from (
		select *,row_number() over (partition by id order by update_time desc) rn from dw_nd.ods_cem_company_base -- 核心企业基本表
	)t
    where rn = 1
)t1
inner join (
	select * from (
		select *,row_number() over (partition by id order by  update_time desc) rn from dw_nd.ods_cem_dictionaries  -- 企业产业集群关系
	)t
	where rn = 1
)t2
on t1.id = t2.cem_base_id -- 核心企业id    【经沟通，ods_cem_company_base的分险比例字段废弃，企业的分险比例用关系表中的】
;
commit;

-- 核心企业管理中自然人分险
drop table if exists dw_tmp.tmp_exp_credit_per_guar_info_risk_natural; commit;
create table if not exists dw_tmp.tmp_exp_credit_per_guar_info_risk_natural(
person_name varchar(200) comment'自然人名称',
person_identity varchar(50) comment '证件号',
counter_guar_contract_number varchar(50) comment '反担保合同',
risk_grade varchar(255) comment'分险比例',
dictionaries_code varchar(50) comment '产业集群'
);
commit;

insert into dw_tmp.tmp_exp_credit_per_guar_info_risk_natural
select t1.person_name,t1.person_identity,t1.counter_guar_contract_number,t1.risk_grade,t2.dictionaries_code
	from (
		select id,person_name,person_identity,counter_guar_contract_number,risk_grade,cem_dictionaries_id
		from (
			select id,person_name,person_identity,counter_guar_contract_number,risk_grade,cem_dictionaries_id,row_number() over (partition by id order by update_time desc) rn
			from dw_nd.ods_cem_natural -- 自然人基本表
		)t
		where rn = 1
	)t1
	inner join (
		select * from (
			select *,row_number() over (partition by id order by update_time desc) rn from dw_nd.ods_cem_dictionaries  -- 企业产业集群关系
		)t
		where rn = 1
	)t2
on t1.cem_dictionaries_id = t2.id
;
commit;


-- create  table dw_base.exp_credit_per_repay_duty_info (
-- 	day_id varchar(8)  comment '数据日期',
-- 	guar_id varchar(60)  comment '担保id',
-- 	cust_id varchar(60)  comment '客户号',
-- 	duty_qty int      comment '责任人个数',  -- 之前的建表语句没有这个
-- 	info_id_type varchar(3)  comment '身份类别',
-- 	duty_name varchar(80)  comment '责任人名称',
-- 	duty_cert_type varchar(3)  comment '责任人身份标识类型',
-- 	duty_cert_no varchar(40)  comment '责任人身份标识号码',
-- 	duty_type varchar(3)  comment '还款责任人类型：1-共同债务人2-反担保人9-其他',
-- 	duty_amt int  comment '还款责任金额',
-- 	duty_flag varchar(3)  comment '联保标志：0-单人保证/多人分保（单人保证指该账户对应的担保交易仅有一个反担保人，多人分保指该账户对应的担保交易有多个反担保人，且每个反担保人独立分担一部分担保责任）1-联保（联保指该账户对应的担保交易有多个反担保人且共同承担担保责任）',  
-- 	guar_cont_no varchar(60)  comment '保证合同编号'
-- ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC 
-- ;
-- commit;

-- 还款责任人信息
DELETE FROM dw_base.exp_credit_per_repay_duty_info where day_id = '${v_sdate}' ;
commit;
insert into dw_base.exp_credit_per_repay_duty_info
select * from (
select distinct t.day_id
             ,t.guar_id
			 ,t.cust_id
			 ,t.info_id_type
			 ,trim(t.duty_name)
			 ,t.duty_cert_type
			 ,t.duty_cert_no
			 ,t.duty_type
			 ,case when t.duty_type='2' and t1.company_name is not null and t1.risk_grade <> '' and t1.risk_grade is not null then t.duty_amt*t1.risk_grade
				   when t.duty_type='2' and t2.person_name is not null and t2.risk_grade <> '' and t2.risk_grade is not null then t.duty_amt*t2.risk_grade
		           when t.duty_type='2' then t.duty_amt
				   else null
				   end as duty_amt
	         ,case when t.duty_type='2' and t1.company_name is not null then concat(t1.counter_guar_contract_number,t.guar_id)
				   when t.duty_type='2' and t2.person_name is not null then concat(t2.counter_guar_contract_number,t.guar_id)
		           when t.duty_type='2' then t.guar_cont_no
				   else null
				   end as guar_cont_no  -- 反担保合同
from (
select '${v_sdate}' as day_id,
       t.guar_id,  -- 担保ID
       t.cust_id,  -- 客户号
	   case when t2.id_type = '10' then '1' when t2.id_type = '20' then '2' else null end as info_id_type,  -- 身份类别  1-自然人  2-组织机构
	   -- t2.counter_name as duty_name, -- 责任人名称
	   case when replace(replace(trim(t2.counter_name),char(9),''),char(13),'')= '王 相美' then '王相美' 
		  when replace(replace(trim(t2.counter_name),char(9),''),char(13),'')= '山东香嗑来食品有限公司' then '山东香磕来食品有限公司' 
		  else replace(replace(trim(t2.counter_name),char(9),''),char(13),'') 
		  end duty_name,
	   '10' as duty_cert_type,  -- 责任人身份标识类型  10:居民身份证及其他以公民身份证号为标识的证件 20-统一社会信用代码 10--中征码
	   -- t2.id_no as duty_cert_no,  -- 责任人身份标识号码
	   case when t2.id_type = '10' then t2.id_no 
	        when t2.id_type = '20' then coalesce(t10.zhongzheng_code,t9.id_num) 
			else null 
	   end as duty_cert_no,  -- 责任人身份标识号码
	   t2.duty_type, -- 1-共同债务人 2-反担保人 9-其他
	   case when t2.duty_type='2' then t.acct_cred_line else null end as duty_amt, -- 还款责任金额(担保金额)
	   -- case when t2.duty_type='2' then coalesce(t5.contract_id,t4.contract_id,t7.contract_id,t8.contract_id,t6.count_cont_code) 
	   -- 		else null 
	   -- 		end as guar_cont_no, -- 反担保合同编号
                   case when t2.duty_type='2' then coalesce(t5.contract_id,t4.contract_id,t6.count_cont_code) 
			else null 
			end as guar_cont_no, -- 反担保合同编号
	   t10.ct_guar_person_id_no, -- 企业统一社会编码
	   t11.aggregate_scheme -- 产业集群
from (
select guar_id,cust_id,acct_cred_line 
from dw_base.exp_credit_per_guar_info_ready  
where day_id = '${v_sdate}' 
)t -- 与昨日数据对比获取余额变动日期、五级分类变动日期 存放当天变化后的数据以及变化日期
inner join dw_tmp.tmp_exp_credit_per_guar_info_xz_counter_main t1  -- -- 担保业务系统id 和项目编号转换
on t.guar_id = t1.guar_id
inner join dw_tmp.tmp_exp_credit_per_guar_info_xz_counter_sq t2  -- 授权的反担保人信息
on t1.project_id = t2.project_id
left join dw_tmp.tmp_exp_credit_per_guar_info_xz_counter_contract t4
on t2.apply_code = t4.biz_id
and t2.cust_code = t4.customer_id  -- 客户号
and t2.duty_type='2'
left join dw_tmp.tmp_exp_credit_per_guar_info_xz_counter_contract t5
on t2.apply_code = t5.biz_id
and t2.id_no = t5.customer_id  -- 证件号
and t2.duty_type='2'
left join dw_tmp.tmp_exp_credit_per_guar_info_xz_counter_contract_xx t6
on t1.project_Id = t6.project_Id
and t2.id_no = t6.ct_guar_person_id_no
and t6.count_cont_code is not null
and t2.duty_type='2'
-- left join dw_tmp.tmp_exp_credit_per_guar_info_xz_counter_contract t7
-- on t2.apply_code = t7.biz_id
-- and t2.id_no = t7.AUTHORIZED_CUSTOMER_ID  -- 证件号
-- and t2.duty_type='2'
-- left join dw_tmp.tmp_exp_credit_per_guar_info_xz_counter_contract t8
-- on t2.apply_code = t8.biz_id
-- and t2.cust_code = t8.AUTHORIZED_CUSTOMER_ID  -- 证件号
-- and t2.duty_type='2'
left join dw_nd.ods_imp_comp_zzm t9
on t.guar_id = t9.guar_id
and t2.id_no = t9.cert_no
and t9.cust_type = '02' -- 反担保人
and t2.duty_type='2'
left join (
		select project_id,zhongzheng_code,ct_guar_person_id_no
		from (
			select id,project_id,zhongzheng_code,ct_guar_person_id_no,row_number() over (partition by id order by db_update_time desc,update_time desc) rn
			from dw_nd.ods_t_ct_guar_person
                        where data_type = '7' -- 出具批复最终定的担保人
		)t
		where rn = 1
)t10
on t1.project_Id = t10.project_Id
and t2.id_no = t10.ct_guar_person_id_no
and t10.zhongzheng_code is not null 
and t2.duty_type='2'
left join dw_tmp.tmp_exp_credit_per_guar_info_check t11
on t1.project_id = t11.project_id
)t
left join dw_tmp.tmp_exp_credit_per_guar_info_risk_comp t1  -- 20231023优化，核心企业的集群方案与担保业务一致时，作为反担保人时，责任金额用合同金额*分险比例，反担保合同用协议合同+业务编号
on t.ct_guar_person_id_no = t1.unified_social_credit_code
and t.aggregate_scheme = t1.dictionaries_code
left join dw_tmp.tmp_exp_credit_per_guar_info_risk_natural t2 
on t.duty_cert_no = t2.person_identity
and t.aggregate_scheme = t2.dictionaries_code
where t.duty_cert_no is not null 
)t
where guar_cont_no is not null 
;
commit;


-- 1.获取当天开户台账
-- create  table dw_base.exp_credit_per_guar_info_open (
--  guar_id	varchar(60)	comment '账号'
--  ,day_id 	varchar(8)	comment '日期'
--  ,open_date	date	comment '开户日期'
--  ,key(guar_id)
--  ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;

delete from dw_base.exp_credit_per_guar_info_open where day_id = '${v_sdate}' ;
commit; 
insert into dw_base.exp_credit_per_guar_info_open
select 
guar_id     -- 
,day_id     
,open_date 
from dw_base.exp_credit_per_guar_info_ready t1
where t1.day_id = '${v_sdate}'  
and t1.open_date <= DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')     -- 放款日期为当天即新增
and DATEDIFF(DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d'),t1.open_date) <= 30 -- 开户30天以上的无法通过校验
and t1.close_date = '' 
and not exists (         -- 新开客户
select 1
from dw_base.exp_credit_per_guar_info_open t2
where t2.day_id < '${v_sdate}' 
and t1.guar_id = t2.guar_id
)
;
commit;
-- 2.获取当天解保台账
-- create  table dw_base.exp_credit_per_guar_info_close (
--  guar_id	varchar(60)	comment '账号'
--  ,day_id 	varchar(8)	comment '日期'
--  ,close_date	date	comment '解保日期'
--  ,key(guar_id)
--  ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;

delete from dw_base.exp_credit_per_guar_info_close where day_id = '${v_sdate}' ;
commit; 
insert into dw_base.exp_credit_per_guar_info_close
select 
guar_id     -- 
,day_id     
,close_date 
from dw_base.exp_credit_per_guar_info_ready t1
where t1.day_id = '${v_sdate}'  
-- and t1.close_date <> ''
and t1.close_date is not null
and t1.close_date <= DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')   
and t1.open_date < DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')
and t1.close_date > DATE_FORMAT(t1.open_date,'%Y-%m-%d')
and not exists (         -- 新增 关闭账户
select 1
from dw_base.exp_credit_per_guar_info_close t2
where t2.day_id < '${v_sdate}' 
and t1.guar_id = t2.guar_id
)
and  exists (
 select 1 from dw_base.exp_credit_per_guar_info_open t2 --   之前开户
 where t2.day_id < '${v_sdate}'
 and t1.guar_id = t2.guar_id
 )
;
commit;

-- 3.获取当天余额变动台账
-- insert into dw_base.exp_credit_per_guar_info_bal_change
-- select 
-- guar_id     -- 
-- ,day_id     
-- ,change_date 
-- from dw_base.ods_gcredit_loan_ac_dxloanbook t1
-- where DATE_FORMAT(t1.snapshot_date,'%Y-%m-%d') = DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')
-- and repay_prin > 0 -- 实还本金
-- ;

-- create  table dw_base.exp_credit_per_guar_info_bal_change (
--  guar_id	varchar(60)	comment '账号'
--  ,day_id 	varchar(8)	comment '日期'
--  ,repay_prd	date	comment '解保日期'
--  ,key(guar_id)
--  ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;

delete from dw_base.exp_credit_per_guar_info_bal_change where day_id = '${v_sdate}' ;
commit; 
insert into dw_base.exp_credit_per_guar_info_bal_change
select 
guar_id
,day_id
,repay_prd
from dw_base.exp_credit_per_guar_info_ready t1
where t1.day_id = '${v_sdate}'
and t1.repay_prd = DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')   
and not exists (
select 1 from dw_base.exp_credit_per_guar_info_open t2 -- 余额变动 不能同时当天开户
where t2.day_id = '${v_sdate}'
and t1.guar_id = t2.guar_id
)
and not exists (
select 1 from dw_base.exp_credit_per_guar_info_close t2 -- 余额变动 不能关闭
where t2.day_id <= '${v_sdate}'
and t1.guar_id = t2.guar_id
)
and  exists (
 select 1 from dw_base.exp_credit_per_guar_info_open t2 --   之前开户
 where t2.day_id < '${v_sdate}'
 and t1.guar_id = t2.guar_id
 )
;
commit;
-- 4.获取当天五级分类变动台账

--   create  table dw_base.exp_credit_per_guar_info_risk_change (
--  guar_id	varchar(60)	comment '账号'
--  ,day_id 	varchar(8)	comment '日期'
--  ,five_cate_adj_date	date	comment '五级分类认定日期'
--  ,key(guar_id)
--  ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
 
delete from dw_base.exp_credit_per_guar_info_risk_change where day_id = '${v_sdate}' ;
commit; 
 
 -- 
 insert into dw_base.exp_credit_per_guar_info_risk_change
 select 
 t1.guar_id 
 ,'${v_sdate}'
 ,five_cate_adj_date
 from dw_base.exp_credit_per_guar_info_ready t1
 where t1.day_id = '${v_sdate}'
 and t1.five_cate_adj_date = DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d') 
 and not exists (
 select 1 from dw_base.exp_credit_per_guar_info_open t2 --   不能同时当天开户
 where t2.day_id = '${v_sdate}'
 and t1.guar_id = t2.guar_id
 )
 and not exists (
 select 1 from dw_base.exp_credit_per_guar_info_bal_change t2 --   不能同时余额
 where t2.day_id = '${v_sdate}'
 and t1.guar_id = t2.guar_id
 )
 and not exists (
 select 1 from dw_base.exp_credit_per_guar_info_close t2 --   不能关闭
 where t2.day_id <= '${v_sdate}'
   and t1.guar_id = t2.guar_id
 )
 and  exists (
 select 1 from dw_base.exp_credit_per_guar_info_open t2 --   之前开户
 where t2.day_id < '${v_sdate}'
 and t1.guar_id = t2.guar_id
 )
 ;
 commit ;

-- 5.获取当天其他信息变动数据

-- create table IF NOT EXISTS dw_base.exp_credit_per_guar_info_oth_change(
-- guar_id	varchar(60)	comment '账号'
-- ,day_id varchar(8) comment '日期'
-- ,change_date varchar(20) comment '日期'
-- ,key(guar_id)
-- ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC 
-- ;
-- 
-- commit ;

delete from dw_base.exp_credit_per_guar_info_oth_change where day_id = '${v_sdate}'  ;
commit ;
-- 
insert into dw_base.exp_credit_per_guar_info_oth_change
select 
t1.guar_id
,'${v_sdate}'
,DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')
from dw_base.tmp_exp_credit_per_guar_info_ready t1
inner join dw_base.exp_credit_per_guar_info_ready t2
on t1.guar_id = t2.guar_id
and t2.day_id = '${v_yesterday}' 
and t2.guar_id is not null
and (
    t1.busi_lines <> t2.busi_lines
 or t1.busi_dtil_lines <> t2.busi_dtil_lines
 -- or t1.open_date <> t2.open_date   
 or t1.acct_cred_line <> t2.acct_cred_line
 or t1.cy <> t2.cy
 -- or t1.due_date <> t2.due_date
 -- or t1.guar_mode  <> t2.guar_mode
 -- or t1.oth_repy_guar_way <> t2.oth_repy_guar_way
 -- or t1.sec_dep <> t2.sec_dep
)
where t1.day_id = '${v_sdate}'
 and not exists (
 select 1 from dw_base.exp_credit_per_guar_info_open t2 --   不能同时当天开户
 where t2.day_id = '${v_sdate}'
 and t1.guar_id = t2.guar_id
 )
 and not exists (
 select 1 from dw_base.exp_credit_per_guar_info_bal_change t2 --   不能同时余额
 where t2.day_id = '${v_sdate}'
 and t1.guar_id = t2.guar_id
 )
 and not exists (
 select 1 from dw_base.exp_credit_per_guar_info_risk_change t2 --   不能风险变动
 where t2.day_id = '${v_sdate}'
 and t1.guar_id = t2.guar_id
 )
 and not exists (
 select 1 from dw_base.exp_credit_per_guar_info_close t2 --   不能关闭
 where t2.day_id <= '${v_sdate}'
   and t1.guar_id = t2.guar_id
 )
and  exists (
 select 1 from dw_base.exp_credit_per_guar_info_open t2 --   之前开户
 where t2.day_id < '${v_sdate}'
 and t1.guar_id = t2.guar_id
 )
;
commit ;


-- ------------------------------------------------------------------------------------------------
-- 所有上报客户 
drop table if exists dw_base.tmp_exp_credit_per_cust_info_sb ;

commit;

create  table dw_base.tmp_exp_credit_per_cust_info_sb (
cust_id varchar(60) -- 客户编号
,name varchar(30) -- 客户名称
,id_type    varchar(2)  -- 证件类型 
,id_num      varchar(20) -- 证件号
,key(cust_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;

commit;

insert into dw_base.tmp_exp_credit_per_cust_info_sb
select
cust_id
,name
,id_type
,id_num
from dw_base.tmp_exp_credit_per_guar_info_ready
group by cust_id
;
commit;

-- -----------------------------------------------------------------------------------------------


-- 昨天没有，今天有，10账户开立                         
-- 昨天有，今天有，且状态由正常变为关闭 20 账户关闭
-- 昨天有，今天有，且 在保余额发生变化 30 在保责任变化
-- 昨天有，今天有，且 五级分类发生变化 40 五级分类调整
-- 昨天有，今天有，且 状态  发生变化 50 其他信息变化

-- 10-新开户/首次上报 指担保关系开始生效的日期
-- 20-账户关闭     指担保关系解除/失效的日期，包括两种情况：1.债务人如约履行还款义务时，第三方或有负债责任自动解除；2.债务人未履约还款，第三方代偿全部债务，担保关系转成借贷关系。
-- 30-在保责任变化    在保责任信息段数据项说明 指在保余额等相关信息发生变化日期
-- 40-五级分类调整    在保责任信息段数据项说明 指相对于上一认定日期，五级分类状态发生了调整的日期。此时需要在该认定日期报送担保账户信息
-- 50-其他信息变化（包括相关还款责任人、抵（质）押合同等信息发生变化） 指在保余额、五级分类等信息之外的其他信息发生变化的日期 其他信息包括：相关还款责任人信息、账户基本信息、抵（质）押物信息。 

-- /**
-- -- 担保余额变动
--  
-- if not  exists create  table dw_base.exp_credit_per_guar_info_bal_change (
-- guar_id	varchar(60)	comment '账号'
-- ,day_id varchar(8)	comment '日期'
-- ,loan_amt_old	int	comment '老在保余额'
-- ,loan_amt_new	int	comment '新在保余额'
-- ,repay_prd_old	date	comment '老余额变化日期'
-- ,repay_prd_new	date	comment '新余额变化日期'
-- ,key(guar_id)
-- ) ;
-- 
-- commit ;
-- 
-- -- 
-- insert into dw_base.exp_credit_per_guar_info_bal_change
-- select 
-- t1.guar_id 
-- ,DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d') 
-- ,t2.loan_amt
-- ,t1.loan_amt
-- ,t2.repay_prd
-- ,DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y-%m-%d') 
-- from dw_base.exp_credit_per_guar_info_ready t1
-- left join dw_base.exp_credit_per_guar_info_ready t2
-- on t1.guar_id = t2.guar_id
-- and t2.day_id = DATE_FORMAT(date_sub(date(now()),interval 2 day),'%Y%m%d') 
-- and t2.guar_id is not null
-- where t1.day_id = DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d')
-- and t1.repay_prd =  DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d')
-- ;
-- commit ;
-- 
-- 
-- -- 
-- 


-- **/

-- /**
-- -- 存放各节点的状态
-- create  table if not  exists  dw_base.exp_credit_per_guar_info_node (
-- guar_id	varchar(60)	comment '账号'
-- ,day_id varchar(8) comment '日期'
-- ,rpt_date_code varchar(2) comment '报告时点说明代码'
-- ,key(guar_id)
-- ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;
-- 
-- commit ;
-- 
-- delete from dw_base.exp_credit_per_guar_info_node where day_id = '${v_sdate}';
-- commit ;
-- 
-- -- 10 账户开立
-- insert into dw_base.exp_credit_per_guar_info_node
-- select 
-- t1.guar_id
-- ,'${v_sdate}'
-- ,'10'  
-- from dw_base.exp_credit_per_guar_info_rpt t1
-- where day_id = '${v_sdate}'  
-- and open_date = DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')     -- 放款日期为当天即新增
-- and close_date = ''
-- ;
-- commit ;


-- 20 账户关闭
-- insert into dw_base.exp_credit_per_guar_info_node
-- select 
-- t1.guar_id
-- ,'${v_sdate}'
-- ,'20'   
-- from dw_base.exp_credit_per_guar_info_rpt t1
-- where t1.day_id =  '${v_sdate}' 
-- and t1.close_date = DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')
-- and t1.is_close_rpt = '1'
-- and t1.open_date <= DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')
-- and not exists (
-- select 1 from dw_base.exp_credit_per_guar_info_node t3 
-- where t3.day_id = '${v_sdate}'
-- and t1.guar_id = t3.guar_id
-- )      
-- ;
-- commit ;

-- 30 在保责任变化
-- insert into dw_base.exp_credit_per_guar_info_node
-- select 
-- t1.guar_id
-- ,'${v_sdate}'
-- ,'30'  
-- from dw_base.exp_credit_per_guar_info_ready t1
-- inner join dw_base.exp_credit_per_guar_info_rpt t2  -- 必须已上报,未关闭
-- on t1.guar_id = t2.guar_id
-- and t2.day_id = '${v_sdate}'
-- and t2.is_open_rpt = '1'
-- and t2.is_close_rpt <> '1'
-- where t1.day_id = '${v_sdate}'
-- and t1.repay_prd = DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')
-- and not exists (
-- select 1 from dw_base.exp_credit_per_guar_info_node t3 
-- where t3.day_id = '${v_sdate}'
-- and t1.guar_id = t3.guar_id
-- )   
-- ;
-- commit ;

-- 40 五级分类调整
-- insert into dw_base.exp_credit_per_guar_info_node
-- select 
-- t1.guar_id
-- ,'${v_sdate}'
-- ,'40'  
-- from dw_base.exp_credit_per_guar_info_ready t1
-- inner join dw_base.exp_credit_per_guar_info_rpt t2  -- 必须已上报,未关闭
-- on t1.guar_id = t2.guar_id
-- and t2.day_id = '${v_sdate}'
-- and t2.is_open_rpt = '1'
-- and t2.is_close_rpt <> '1'
-- where t1.day_id = '${v_sdate}'
-- and t1.five_cate_adj_date = DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')
-- and not exists (
-- select 1 from dw_base.exp_credit_per_guar_info_node t3 
-- where t3.day_id ='${v_sdate}'
-- and t1.guar_id = t3.guar_id
-- )   
-- ;
-- commit ;

-- 50 其他信息变化
-- insert into dw_base.exp_credit_per_guar_info_node
-- select 
-- t1.guar_id
-- ,'${v_sdate}'
-- ,'50'  
-- from dw_base.exp_credit_per_guar_info_oth_change t1
-- inner join dw_base.exp_credit_per_guar_info_rpt t2  -- 必须已上报,未关闭
-- on t1.guar_id = t2.guar_id
-- and t2.day_id = '${v_sdate}'
-- and t2.is_open_rpt = '1'
-- and t2.is_close_rpt <> '1'
-- where t1.day_id = '${v_sdate}'
-- and not exists (
-- select 1 from dw_base.exp_credit_per_guar_info_node t3 
-- where t3.day_id = '${v_sdate}'
-- and t1.guar_id = t2.guar_id
-- )   
-- ;
-- commit ;

-- **/



-- 组织担保报文

-- 
DELETE FROM dw_base.exp_credit_per_guar_info where day_id = '${v_sdate}' ;

commit ;

-- 插入 10账户开立  开户时间判断
insert into dw_base.exp_credit_per_guar_info
select
t1.DAY_ID	             -- 数据日期
,t1.guar_id	         -- 担保ID
,t1.CUST_ID	         -- 客户号
,t1.acct_type	         -- 账户类型
,t1.acct_code	         -- 账户标识码
,t1.rpt_date	         -- 信息报告日期
,'10'	     -- 报告时点说明代码
,t1.name	             -- 债务人姓名
,t1.id_type	         -- 债务人证件类型
,t1.id_num	             -- 债务人证件号码
,t1.mngmt_org_code	     -- 业务管理机构代码
,t1.busi_lines	         -- 担保业务大类
,t1.busi_dtil_lines	 -- 担保业务种类细分
,t1.open_date	         -- 开户日期
,t1.acct_cred_line	     -- 担保金额
,t1.cy	                 -- 币种
,t1.due_date	         -- 到期日期
,t1.guar_mode	         -- 反担保方式
,t1.oth_repy_guar_way	 -- 其他还款保证方式
,t1.sec_dep	         -- 保证金比例
,t1.ctrct_txt_cd	     -- 担保合同文本编号
,t1.acct_status	     -- 账户状态
,t1.loan_amt	         -- 在保余额
,t1.open_date	 -- 余额变化日期 首次开户 为余额变动时间
,t1.five_cate	         -- 五级分类
,t1.open_date	 -- 五级分类认定日期 首次开户 为余额变动时间
,t1.ri_ex	             -- 风险敞口
,t1.comp_adv_flag	     -- 代偿(垫款)标志
,t1.close_date	         -- 账户关闭日期
,t1.data_source	     -- 数据来源   
from dw_base.exp_credit_per_guar_info_ready t1
inner join dw_base.exp_credit_per_guar_info_open t2
on t1.guar_id = t2.guar_id
and t2.day_id = '${v_sdate}'
where t1.day_id =  '${v_sdate}'
-- and t1.open_date = DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')     -- 放款日期未为当天即新增
;

commit ;


-- 插入 20 账户关闭 账户关闭时间判断
insert into dw_base.exp_credit_per_guar_info
select
t1.DAY_ID	             -- 数据日期
,t1.guar_id	         -- 担保ID
,t1.CUST_ID	         -- 客户号
,t1.acct_type	         -- 账户类型
,t1.acct_code	         -- 账户标识码
,t1.rpt_date	         -- 信息报告日期
,'20'	             -- 报告时点说明代码
,t1.name	             -- 债务人姓名
,t1.id_type	         -- 债务人证件类型
,t1.id_num	             -- 债务人证件号码
,t1.mngmt_org_code	     -- 业务管理机构代码
,t1.busi_lines	         -- 担保业务大类
,t1.busi_dtil_lines	 -- 担保业务种类细分
,t1.open_date	         -- 开户日期
,t1.acct_cred_line	     -- 担保金额
,t1.cy	                 -- 币种
,t1.due_date	         -- 到期日期
,t1.guar_mode	         -- 反担保方式
,t1.oth_repy_guar_way	 -- 其他还款保证方式
,t1.sec_dep	         -- 保证金比例
,t1.ctrct_txt_cd	     -- 担保合同文本编号
,t1.acct_status	     -- 账户状态
,t1.loan_amt	         -- 在保余额
,case when t1.repay_prd	> t1.close_date then t1.close_date
      else t1.repay_prd end  repay_prd        -- 余额变化日期   -- 取账户关闭日期
,t1.five_cate	         -- 五级分类
,case when t1.five_cate_adj_date > t1.close_date then t1.close_date
      else t1.five_cate_adj_date end five_cate_adj_date	 -- 五级分类认定日期 -- 取账户关闭日期
,t1.ri_ex	             -- 风险敞口
,t1.comp_adv_flag	     -- 代偿(垫款)标志
,t1.close_date	         -- 账户关闭日期
,t1.data_source	     -- 数据来源   
from dw_base.exp_credit_per_guar_info_ready t1
inner join dw_base.exp_credit_per_guar_info_close t2
on t1.guar_id = t2.guar_id
and t2.day_id = '${v_sdate}'
where t1.day_id = '${v_sdate}'
-- and t1.close_date = DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')

;

commit ;


-- 插入 30 在保责任变化 
insert into dw_base.exp_credit_per_guar_info
select
t1.DAY_ID	             -- 数据日期
,t1.guar_id	         -- 担保ID
,t1.CUST_ID	         -- 客户号
,t1.acct_type	         -- 账户类型
,t1.acct_code	         -- 账户标识码
,t1.rpt_date	         -- 信息报告日期
,'30'	             -- 报告时点说明代码
,t1.name	             -- 债务人姓名
,t1.id_type	         -- 债务人证件类型
,t1.id_num	             -- 债务人证件号码
,t1.mngmt_org_code	     -- 业务管理机构代码
,t1.busi_lines	         -- 担保业务大类
,t1.busi_dtil_lines	 -- 担保业务种类细分
,t1.open_date	         -- 开户日期
,t1.acct_cred_line	     -- 担保金额
,t1.cy	                 -- 币种
,t1.due_date	         -- 到期日期
,t1.guar_mode	         -- 反担保方式
,t1.oth_repy_guar_way	 -- 其他还款保证方式
,t1.sec_dep	         -- 保证金比例
,t1.ctrct_txt_cd	     -- 担保合同文本编号
,t1.acct_status	     -- 账户状态
,t1.loan_amt	         -- 在保余额
,DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')	         -- 余额变化日期
,t1.five_cate	         -- 五级分类
,t1.five_cate_adj_date	 -- 五级分类认定日期
,t1.ri_ex	             -- 风险敞口
,t1.comp_adv_flag	     -- 代偿(垫款)标志
,t1.close_date	         -- 账户关闭日期
,t1.data_source	     -- 数据来源   
from dw_base.exp_credit_per_guar_info_ready t1
inner join dw_base.exp_credit_per_guar_info_bal_change t2
on t1.guar_id = t2.guar_id
and t2.day_id = '${v_sdate}'
where t1.day_id = '${v_sdate}'
;

commit ;

-- 插入 40 五级分类调整
insert into dw_base.exp_credit_per_guar_info
select
t1.DAY_ID	             -- 数据日期
,t1.guar_id	         -- 担保ID
,t1.CUST_ID	         -- 客户号
,t1.acct_type	         -- 账户类型
,t1.acct_code	         -- 账户标识码
,t1.rpt_date	         -- 信息报告日期
,'40'	             -- 报告时点说明代码
,t1.name	             -- 债务人姓名
,t1.id_type	         -- 债务人证件类型
,t1.id_num	             -- 债务人证件号码
,t1.mngmt_org_code	     -- 业务管理机构代码
,t1.busi_lines	         -- 担保业务大类
,t1.busi_dtil_lines	 -- 担保业务种类细分
,t1.open_date	         -- 开户日期
,t1.acct_cred_line	     -- 担保金额
,t1.cy	                 -- 币种
,t1.due_date	         -- 到期日期
,t1.guar_mode	         -- 反担保方式
,t1.oth_repy_guar_way	 -- 其他还款保证方式
,t1.sec_dep	         -- 保证金比例
,t1.ctrct_txt_cd	     -- 担保合同文本编号
,t1.acct_status	     -- 账户状态
,t1.loan_amt	         -- 在保余额
,t1.repay_prd	         -- 余额变化日期
,t1.five_cate	         -- 五级分类
,DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')	 -- 五级分类认定日期
,t1.ri_ex	             -- 风险敞口
,t1.comp_adv_flag	     -- 代偿(垫款)标志
,t1.close_date	         -- 账户关闭日期
,t1.data_source	     -- 数据来源   
from dw_base.exp_credit_per_guar_info_ready t1
inner join dw_base.exp_credit_per_guar_info_risk_change t2
on t1.guar_id = t2.guar_id
and t2.day_id = '${v_sdate}'
where t1.day_id = '${v_sdate}'

;

commit ;


-- 插入 50 其他信息变化
insert into dw_base.exp_credit_per_guar_info
select
t1.DAY_ID	             -- 数据日期
,t1.guar_id	         -- 担保ID
,t1.CUST_ID	         -- 客户号
,t1.acct_type	         -- 账户类型
,t1.acct_code	         -- 账户标识码
,t1.rpt_date	         -- 信息报告日期
,'50'	     -- 报告时点说明代码
,t1.name	             -- 债务人姓名
,t1.id_type	         -- 债务人证件类型
,t1.id_num	             -- 债务人证件号码
,t1.mngmt_org_code	     -- 业务管理机构代码
,t1.busi_lines	         -- 担保业务大类
,t1.busi_dtil_lines	 -- 担保业务种类细分
,t1.open_date	         -- 开户日期
,t1.acct_cred_line	     -- 担保金额
,t1.cy	                 -- 币种
,t1.due_date	         -- 到期日期
,t1.guar_mode	         -- 反担保方式
,t1.oth_repy_guar_way	 -- 其他还款保证方式
,t1.sec_dep	         -- 保证金比例
,t1.ctrct_txt_cd	     -- 担保合同文本编号
,t1.acct_status	     -- 账户状态
,t1.loan_amt	         -- 在保余额
,t1.repay_prd	         -- 余额变化日期
,t1.five_cate	         -- 五级分类
,t1.five_cate_adj_date	 -- 五级分类认定日期
,t1.ri_ex	             -- 风险敞口
,t1.comp_adv_flag	     -- 代偿(垫款)标志
,t1.close_date	         -- 账户关闭日期
,t1.data_source	     -- 数据来源   
from dw_base.exp_credit_per_guar_info_ready t1
inner join dw_base.exp_credit_per_guar_info_oth_change t2
on t1.guar_id = t2.guar_id
and t2.day_id = '${v_sdate}'
where t1.day_id = '${v_sdate}' 
;

commit ; 





-- 按段更正 暂不使用该功能

-- 1.定位客户群 今天上报前已开户，但是未关闭。

drop table if exists dw_base.exp_credit_per_guar_info_sep_cust ;

commit;

create  table dw_base.exp_credit_per_guar_info_sep_cust (
  `guar_id` varchar(60) COLLATE utf8mb4_bin DEFAULT NULL,
  `day_id` varchar(60) COLLATE utf8mb4_bin DEFAULT NULL,
  KEY `guar_id` (`guar_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;

commit;
   
insert into dw_base.exp_credit_per_guar_info_sep_cust
select 
guar_id   
,t1.day_id
from dw_base.exp_credit_per_guar_info_open t1 
where t1.day_id < '${v_sdate}' 
and not exists( 
select 1 from dw_base.exp_credit_per_guar_info_close t2 
where t2.day_id <= '${v_sdate}' 
and t1.guar_id = t2.guar_id
)
;

commit ;

-- 2.获取变更数据
   
--   DELETE FROM dw_base.exp_credit_per_guar_info_change_b where day_id = '${v_sdate}' ;
--   commit;
--   -- B-基础段 更正基础段时，更正请求记录的信息报告日期应等于相应信息段最晚的信息报告日期
--   insert into dw_base.exp_credit_per_guar_info_change_b
--   select 
--   '${v_sdate}'
--   ,t1.guar_id
--   ,t2.cust_id
--   ,t2.acct_code
--   ,t2.name
--   ,t2.id_type
--   ,t2.id_num
--   ,t2.mngmt_org_code
--   ,'mdy'
--   from dw_base.exp_credit_per_guar_info_sep_cust t1
--   inner join dw_base.exp_credit_per_guar_info_ready t2
--           on t1.guar_id = t2.guar_id
--          and t2.day_id = '${v_sdate}'
--   inner join dw_base.exp_credit_per_guar_info_ready t3
--           on t1.guar_id = t3.guar_id
--          and t3.day_id = '${v_yesterday}' 
--   where t2.name <> t3.name
--      or t2.id_type <> t3.id_type
--      or t2.id_num <> t3.id_num
--      or t2.mngmt_org_code <>  t3.mngmt_org_code
--   ;
--   commit;
--   -- C-基本信息段 50其他信息段中已经包括，需要排除
--   DELETE FROM dw_base.exp_credit_per_guar_info_change_c where day_id = '${v_sdate}' ;
--   commit;
--   insert into dw_base.exp_credit_per_guar_info_change_c
--   select 
--   '${v_sdate}'   
--   ,t2.guar_id
--   ,t2.cust_id
--   ,t2.acct_code
--   ,t2.busi_lines -- 担保业务大类
--   ,t2.busi_dtil_lines -- 担保业务种类细分
--   ,t2.open_date -- 开户日期
--   ,t2.acct_cred_line -- 担保金额
--   ,t2.cy -- 币种
--   ,t2.due_date -- 到期日期
--   ,t2.guar_mode -- 反担保方式
--   ,t2.oth_repy_guar_way -- 其他还款保证方式
--   ,t2.sec_dep -- 保证金比例
--   ,t2.ctrct_txt_cd -- 担保合同文本编号
--   ,'mdy'
--   from dw_base.exp_credit_per_guar_info_sep_cust t1
--   inner join dw_base.exp_credit_per_guar_info_ready t2
--           on t1.guar_id = t2.guar_id
--          and t2.day_id = '${v_sdate}'
--   inner join dw_base.exp_credit_per_guar_info_ready t3
--           on t1.guar_id = t3.guar_id
--          and t3.day_id = '${v_yesterday}' 
--   where (
--        t2.open_date <> t3.open_date
-- --      or t2.acct_cred_line <> t3.acct_cred_line  跟在保余额取数一致，在保余额变动时报送
-- --      or t2.due_date <> t3.due_date
--      or t2.guar_mode <>  t3.guar_mode
--	  ) 
--     and not exists
--	 (
--	 select 1 from dw_base.exp_credit_per_guar_info t4  -- 不能通过 10 20 30 40 50 上报
--	 where t4.day_id = '${v_sdate}'
--	   and t1.guar_id = t4.guar_id
--	 )
--	 
--   ;
--   commit ;
--   
--   -- D-在保责任信息段  需要排除 40 五级分类调整 30 在保责任变化 
--   
--   DELETE FROM dw_base.exp_credit_per_guar_info_change_d where day_id = '${v_sdate}' ;
--   commit;
--   insert into dw_base.exp_credit_per_guar_info_change_d
--   select
--   '${v_sdate}'
--   ,t2.guar_id
--   ,t2.cust_id
--   ,t2.acct_code
--   ,t2.acct_status -- 账户状态
--   ,t2.loan_amt -- 在保余额
--   ,t2.repay_prd -- 余额变化日期
--   ,t2.five_cate -- 五级分类
--   ,t2.five_cate_adj_date -- 五级分类认定日期
--   ,t2.ri_ex -- 风险敞口
--   ,t2.comp_adv_flag -- 代偿(垫款)标志
--   ,t2.close_date -- 账户关闭日期
--   ,'mdy'
--   from dw_base.exp_credit_per_guar_info_sep_cust t1
--   inner join dw_base.exp_credit_per_guar_info_ready t2
--           on t1.guar_id = t2.guar_id
--          and t2.day_id = '${v_sdate}'
--   inner join dw_base.exp_credit_per_guar_info_ready t3
--           on t1.guar_id = t3.guar_id
--          and t3.day_id = '${v_yesterday}' 
--   where 
-- --         t2.acct_status <> t3.acct_status
-- --      or t2.loan_amt <> t3.loan_amt
-- --      or t2.repay_prd <> t3.repay_prd
-- --      or t2.five_cate <>  t3.five_cate
-- --	    or t2.five_cate_adj_date <>  t3.five_cate_adj_date
-- --	    or t2.comp_adv_flag <>  t3.comp_adv_flag
-- --	    or t2.close_date <>  t3.close_date
--	       t2.ri_ex <> t3.ri_ex
--    and not exists
--	 (
--	 select 1 from dw_base.exp_credit_per_guar_info t4  -- 不能通过 10 20 30 40 50 上报
--	 where t4.day_id = '${v_sdate}'
--	   and t1.guar_id = t4.guar_id
--	 )
--    ;
--    commit;	

-- 按段更正 E--还款责任人段(有新增反担保人 或 反担保人中征码发生变化）
DELETE FROM dw_base.exp_credit_per_guar_info_change_e where day_id = '${v_sdate}' ;
commit;
insert into dw_base.exp_credit_per_guar_info_change_e


-- 拿最新的相关还款责任人信息（且未关户）
select distinct 
'${v_sdate}' 
,t1.`guar_id` 
,t3.`cust_id` -- '客户号'
,t3.info_id_type -- '身份类别'
,replace(replace(trim(t3.duty_name),char(9),''),char(13),'')duty_name  -- '责任人名称'
,t3.duty_cert_type -- '责任人身份标识类型'
,t3.`duty_cert_no`-- '责任人身份标识号码'
,t3.duty_type-- '还款责任人类型：1-共同债务人2-反担保人9-其他'
,t3.duty_amt -- '还款责任金额'
,t3.guar_cont_no -- '保证合同编号'
,'mdy'
-- ,t2.guar_id
from dw_base.exp_credit_per_guar_info_sep_cust t1 -- 今天上报前已开户，但是未关闭。
inner join dw_base.exp_credit_per_repay_duty_info t3
on t1.guar_id = t3.guar_id
and t3.day_id = '${v_sdate}' 
left join (

	select distinct 
	t1.`guar_id` 
	,t1.day_id
	,t3.duty_cert_no
	,t2.arlp_cert_num
	,replace(replace(trim(t3.duty_name),char(9),''),char(13),'')duty_name
	,replace(replace(trim(t2.arlp_name),char(9),''),char(13),'')arlp_name
	from dw_base.exp_credit_per_guar_info_sep_cust t1 -- 今天上报前已开户，但是未关闭。
	inner join dw_base.exp_credit_per_repay_duty_info t3 -- 拿当天最新的相关还款人信息
	on t1.guar_id = t3.guar_id
	and t3.day_id = '${v_sdate}' 
	left join (
		select t1.* from dw_pbc.t_in_rlt_repymt_inf_sgmt_el t1
		inner join (
			select guar_id,max(day_id)day_id from dw_pbc.t_in_rlt_repymt_inf_sgmt_el
			where day_id < '${v_sdate}' 
			group by guar_id
	)t2
	on t1.guar_id = t2.guar_id
	and t1.day_id = t2.day_id
	)t2
	on t1.guar_id = t2.guar_id
	-- 历史最新一天报送的相关还款人(包含正常报送和修正）和当天最新对比即可，不用管是哪个时点报送的
	and replace(replace(trim(t3.duty_name),char(9),''),char(13),'') = replace(replace(trim(t2.arlp_name),char(9),''),char(13),'')
	where t1.guar_id is not null  
	and t3.guar_id is not null 
	-- and t1.guar_id = '202309270041'
	and (t3.duty_cert_no <> t2.arlp_cert_num or  t2.arlp_name is null ) -- 自动捕获中征码变更 或 新增反担保人
	
)t2
on t1.guar_id = t2.guar_id
where t2.guar_id is not null 
;
commit;

-- 同步集市

delete from dw_pbc.exp_credit_per_guar_info where day_id = '${v_sdate}' ;
commit ;

insert into dw_pbc.exp_credit_per_guar_info
select
*
from dw_base.exp_credit_per_guar_info 
where day_id = '${v_sdate}' 
;
commit;


--  还款责任人信息
delete from dw_pbc.exp_credit_per_repay_duty_info  where day_id = '${v_sdate}' ;
commit ;
insert into dw_pbc.exp_credit_per_repay_duty_info 
select 
* 
from  dw_base.exp_credit_per_repay_duty_info 
where day_id = '${v_sdate}'
;
commit ;

delete from dw_pbc.exp_credit_per_guar_info_change_b where day_id = '${v_sdate}' ;
commit ;

insert into dw_pbc.exp_credit_per_guar_info_change_b
select
*
from dw_base.exp_credit_per_guar_info_change_b 
where day_id = '${v_sdate}' 
;
commit;


delete from dw_pbc.exp_credit_per_guar_info_change_c where day_id = '${v_sdate}' ;
commit ;

insert into dw_pbc.exp_credit_per_guar_info_change_c
select
*
from dw_base.exp_credit_per_guar_info_change_c 
where day_id = '${v_sdate}' 
;
commit;


delete from dw_pbc.exp_credit_per_guar_info_change_d where day_id = '${v_sdate}';
commit ;

insert into dw_pbc.exp_credit_per_guar_info_change_d
select
*
from dw_base.exp_credit_per_guar_info_change_d 
where day_id = '${v_sdate}' 
;
commit;

delete from dw_pbc.exp_credit_per_guar_info_change_e where day_id = '${v_sdate}' ;
commit ;

insert into dw_pbc.exp_credit_per_guar_info_change_e
select
*
from dw_base.exp_credit_per_guar_info_change_e 
where day_id = '${v_sdate}' 
;
commit;