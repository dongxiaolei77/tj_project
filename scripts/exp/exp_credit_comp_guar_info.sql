-- 改 --            20251014 授权关联在保转件

-- 1.还款责任人信息（还款责任人段使用）
-- 2.获取授权客户   （登录信息    签定使用授权书   获取授权）
-- 3.获取所有放款日期小于等于当天的担保数据（结合第五项）
-- 4.企业代偿信息表
-- 5.全量 tmp_exp_credit_comp_guar_info_ready
-- 6.与昨日数据对比获取余额变动日期、五级分类变动日期、其他信息变动
		-- 当天增量exp_credit_comp_guar_info_ready
-- 存放当天各数据
  -- 1.获取当天开户台账
  -- 2.获取当天解保台账
  -- 3.获取当天余额变动台账
  -- 4.获取当天五级分类变动台账
  -- 5.获取当天其他信息变动数据
-- 所有上报客户
  -- 插入 10-新开户/首次上报
  -- 插入20-账户关闭
  -- 插入 30-在保责任变化
  -- 插入40-五级分类调整
  -- 插入50-其他信息变化
-- 按段更正内容
-- 同步集市

-- 授权客户
drop table if exists dw_tmp.tmp_exp_credit_comp_cust_info_id_sq;commit;
CREATE TABLE dw_tmp.tmp_exp_credit_comp_cust_info_id_sq (
  `cust_id` varchar(60) COLLATE utf8mb4_bin DEFAULT NULL,
  `name` varchar(500) COLLATE utf8mb4_bin DEFAULT NULL,
  `id_type` varchar(2) COLLATE utf8mb4_bin DEFAULT NULL,
  `id_num` varchar(32) COLLATE utf8mb4_bin DEFAULT NULL,
  KEY `idx_tmp_exp_credit_comp_cust_info_id_sq_cust_id` (`cust_id`),
  KEY `idx_tmp_exp_credit_comp_cust_info_id_sq_id_num` (`id_num`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit;

insert into dw_tmp.tmp_exp_credit_comp_cust_info_id_sq
select t.cust_id
	   ,t.name
	   ,t.id_type
	   ,coalesce(t1.id_num,t2.zhongzheng_code)
from (
       select cust_id
			 ,name
			 ,id_type
			 ,id_num
	   from (
	          select cust_id
			        ,name
					,id_type
					,id_num
					,row_number()over (partition by id_num order by dict_flag) rn             -- [优先取原表里的证件号码、客户id，再取main表中在保转进件项目的]
			  from (
	                 select customer_id as cust_id
	                 	   ,main_name as name
	                 	   ,case when main_id_type = '21' then '10'  end as id_type   -- 10-中征码
	                 	   ,main_id_no as id_num
						   ,'0' as dict_flag
	                 from (
	                 	    select login_no
	                 	    	     ,customer_id
	                 	    	     ,main_name
	                 	    	     ,main_id_type  -- 主体证件类型
	                 	    	     ,main_id_no
	                 	    	     ,update_time
	                 	    	     ,row_number() over (partition by main_id_no order by update_time desc) as rn
	                 	    from dw_nd.ods_wxapp_cust_login_info   -- 登陆账号信息表 20230112由dw_nd.ods_gcredit_customer_login_info 切源到 dw_nd.ods_wxapp_cust_login_info
	                 	    where login_type = '2'  -- 企业
	                 	    and main_id_type = '21' -- 企业  21企业 10个人 22迁移数据，算作个人
	                 	    and status = '10' -- 已授权
	                 	    and customer_id is not null
	                      ) t
	                 where rn = 1
					 union all 
					 select distinct cust_id 
			               ,cust_name        as name
					       ,'10'             as id_type
			               ,cust_identity_no as id_num                                                 
			               ,'1' as dict_flag
			         from (select code
			                     ,cust_id
						         ,cust_name
                                 ,cust_identity_no
                                 ,row_number()over (partition by code order by db_update_time desc,update_time desc) rn
                           from dw_nd.ods_t_biz_project_main                                        -- 20251014  
			  		       where code like 'TJ%' 
					       and main_type = '02') a              -- 主体类型：02 法人
			         where a.rn = 1 
				   ) b
			) c 
       where c.rn = 1			
     )t
left join dw_nd.ods_imp_comp_zzm t1 -- 手动录入中征码
on t.id_num = t1.cert_no
left join (
	select cust_identity_no,zhongzheng_code
	from (
		select id,cust_identity_no,zhongzheng_code,row_number() over (partition by id order by db_update_time desc,update_time desc) as rn
		from dw_nd.ods_t_biz_project_main
	)t
	where rn = 1
) t2  -- 市管中心录入中征码
on t.id_num = t2.cust_identity_no
;
commit;

-- 项目取最后一次【其他状态】->【90】(或首行=90)的更新时间作为账户关闭日期
drop table if exists dw_tmp.tmp_exp_credit_comp_guar_info_close_date;commit;
create table dw_tmp.tmp_exp_credit_comp_guar_info_close_date (
code varchar(50) comment '业务编号',
project_id varchar(50) comment 'project_id',
close_date varchar(20) comment '关户日期',
index idx_per_guar_info_close_date(project_id)
);
commit;


insert into dw_tmp.tmp_exp_credit_comp_guar_info_close_date
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
		,(select @diff_rw:=0,@proj_status :='',@project_id :='') t
		order by id,db_update_time asc,update_time asc
		) a
where diff_rw=1
group by id
;
commit;

-- 2.获取所有放款日期小于等于当天的担保数据
-- 担保信息
drop table if exists dw_tmp.tmp_exp_credit_comp_guar_info_id;
commit;

create table dw_tmp.tmp_exp_credit_comp_guar_info_id (
	day_id          varchar(8)   comment '数据日期',
	name            varchar(80)  comment '客户姓名',
	guar_id         varchar(60)  comment '担保id',
	cust_id         varchar(60)  comment '客户号',
	cert_no         varchar(20)  comment '客户证件号码',
	loan_begin_dt   varchar(20)  comment '贷款开始时间',
	loan_amt        int          comment '担保金额',
	loan_end_dt     varchar(20)  comment '到期日期',
	protect_guar    varchar(20)  comment '0-信用/免担保 1-保证 2-质押 3-抵押 4-组合',
	ctrct_txt_cd    varchar(20)  comment '担保合同文本编号',
	acct_status     varchar(1)   comment '账户状态账户状态  1-正常 2-关闭',
	loan_bal        int          comment '在保余额',
	five_cate       varchar(1)   comment '五级分类',
	ri_ex           varchar(15)  comment '风险敞口',
	comp_adv_flag   varchar(1)   comment '代偿(垫款)标志',
	close_date 		varchar(20)  comment '账户关闭日期',
	data_source 	varchar(20)  comment '数据来源',
	key  (guar_id)
) engine=innodb default charset=utf8mb4 collate=utf8mb4_bin row_format=dynamic comment='企业担保信息数据准备'
;

insert into dw_tmp.tmp_exp_credit_comp_guar_info_id
select '${v_sdate}' AS day_id
	   ,cust_name              -- 姓名
	   ,proj_no                -- 项目id
	   ,a.cust_id              -- 客户号
	   ,cert_no                -- 客户证件号码',
	   ,loan_cont_beg_dt       -- 借款合同开始日',
	   ,loan_cont_amt * 10000  -- 借款合同金额',
	   ,loan_cont_end_dt       -- 到期日期',
	   ,case when length(oppos_guar_cd) > 6 then '4'    -- 申保反担保措施
			 when oppos_guar_cd like '%02%' then '3'
			 when oppos_guar_cd like '%03%' then '2'
			 when oppos_guar_cd like '%04%' then '1'
			 else '0'
		end oppos_guar_cd -- 0-信用/免担保 1-保证 2-质押 3-抵押 4-组合    -- 00	其他 01	无 02	抵押 03	质押 04	保证 05	以物抵债
	   ,'' AS ctrct_txt_cd -- 担保合同文本编号',
	   ,case when  proj_stt = '50' then '1' when  proj_stt = '90' then '2'  end	AS acct_status	 -- 账户状态账户状态  1-正常 2-关闭',
	   ,loan_cont_amt * 10000 -- 在保余额'
	   ,'1' AS five_cate      -- 五级分类'
	   ,''  AS ri_ex          -- 风险敞口'
	   ,'0' AS comp_adv_flag  -- 代偿(垫款)标志'
	   ,case when proj_stt='90'  then t3.close_date  else '' end as close_date-- 账户关闭日期'
	   ,'新担保业务平台2' AS data_source  -- 数据来源'
from dw_base.dwd_agmt_guar_proj_info a
inner join dw_tmp.tmp_exp_credit_comp_cust_info_id_sq  b  -- 20220413
on a.cust_id = b.cust_id  -- 【存疑】 换成 a.id_num = b.id_num 关联，结果如何
left join dw_tmp.tmp_exp_credit_comp_guar_info_close_date t3
on a.proj_id=t3.project_id
where a.proj_stt in ('50','90')  -- 50-已放款 90-已解保
and a.main_type_cd = '02'  -- 法人
and length(cust_name) > 9  -- 【存疑】这里为什么要限制客户名称长度？
and a.cert_no not like '37%'
and length(a.cert_no) = 18 -- 证件号满足报送要求
and loan_cont_beg_dt <= date_format('${v_sdate}','%Y-%m-%d')  -- 借款合同开始日
and loan_cont_beg_dt is not null
-- and loan_cont_beg_dt <> ''
and loan_cont_end_dt is not null  -- -- 借款合同开始日
-- and loan_cont_end_dt <> ''
and loan_cont_beg_dt < loan_cont_end_dt  -- 到期日期大于开始日期
group by proj_no; -- 20220413
commit ;


-- 企业代偿信息表
drop table if exists dw_tmp.tmp_imp_comp_compt_cust_info_compt ;
commit ;

create table dw_tmp.tmp_imp_comp_compt_cust_info_compt
(
	guar_id         varchar(50)    comment '业务编号',
	item_stt        varchar(20)    comment '项目状态',
	risk_stt        varchar(20)    comment '风险状态',
	city_name       varchar(20)    comment '城市',
	county_name     varchar(20)    comment '区县',
	area_name       varchar(20)    comment '行政区划',
	cust_name       varchar(255)   comment '客户名称',
	cert_no         varchar(50)    comment '身份证号',
	guar_class      varchar(255)   comment '国担分类',
	ind_type        varchar(255)   comment '国标行业',
	loan_bank       varchar(255)   comment '合作银行',
	bank_brev       varchar(255)   comment '合作银行简称',
	loan_cont_id    varchar(255)   comment '借款合同号',
	guar_cont_id    varchar(255)   comment '保证合同编号',
	loan_amt        int            comment '借款合同金额',
	prov_amt        int            comment '放款金额',
	rate            decimal(8,4)   comment '利率',
	loan_beg_dt     varchar(20)    comment '放款起始日',
	loan_end_dt     varchar(20)    comment '放款到期日',
	compt_amt       decimal(18,4)  comment '代偿金额',
	compt_dt        varchar(20)    comment '代偿日期',
	repay_acct_bank varchar(20)    comment '出款账户',
	cust_type       varchar(20)    comment '客户类型',
	repay_stt       varchar(20)    comment '代偿时还款状态',
	is_repay        varchar(1)     comment '是否归还1：是0否',
	repay_dt        varchar(20)    comment '归还日期',
	key(guar_id)
) engine=innodb default charset=utf8mb4 collate=utf8mb4_bin row_format=dynamic comment='企业代偿信息表'
;

insert into dw_tmp.tmp_imp_comp_compt_cust_info_compt
select t1.proj_code
	   ,'已解保' AS item_stt
	   ,'已代偿' AS risk_stt
	   ,t1.city             -- 城市
	   ,t1.district         -- 区县
	   ,t1.district         -- 行政区划
	   ,t1.cust_name        -- 客户名称 key
	   ,coalesce(t5.id_num,t4.zhongzheng_code) -- 中征码 key
	   ,null                -- 国担分类
	   ,null                -- 国标行业
	   ,coalesce(t3.dept_name,t1.loans_bank)     -- 合作银行 key
	   ,null                -- 合作银行简称 key
	   ,t1.jk_contr_code    -- 借款合同号
	   ,null                -- 保证合同编号
	   ,null                -- 借款合同金额
	   ,null                -- 放款金额
	   ,null                -- 利率
	   ,t1.fk_start_date    -- 放款起始日
	   ,t1.fk_end_date      -- 放款到期日
	   ,t2.approp_totl      -- 代偿金额 key
	   ,t2.approp_date      -- 代偿日期 key
	   ,'' AS repay_acct_bank   -- 出款账户
	   ,'1' AS cust_type        -- 客户类型 key
	   ,null                -- 代偿时还款状态
	   ,0 AS is_repay       -- 是否归还1：是0否 key
	   ,null                -- 归还日期
from (
	select id,
		   proj_code,
		   project_id,
		   city,
		   district ,
		   cust_name ,
		   cust_identity_no,
		   loans_bank ,
		   jk_contr_code ,
		   fk_start_date ,
		   fk_end_date ,
		   status
	from (
		select id
			   ,proj_code
			   ,project_id
			   ,city     -- 城市
			   ,district -- 区县
			   ,cust_name -- 客户名称 key
			   ,cust_identity_no -- 身份证号 key
			   ,loans_bank -- 合作银行 key
			   ,jk_contr_code -- 借款合同号
			   ,fk_start_date -- 放款起始日
			   ,fk_end_date -- 放款到期日
			   ,status
			   ,db_update_time
			   ,row_number() over (partition by id order by db_update_time desc) as rn
		from dw_nd.ods_t_proj_comp_aply  -- 代偿申请信息
		where date_format(db_update_time,'%Y%m%d') <= '${v_sdate}'
	) t
	where rn = 1
) t1
inner join (
	select comp_id,
		   approp_date,
		   approp_totl
	from(
		select comp_id
			   ,approp_date
			   ,approp_totl
			   ,db_update_time
			   ,row_number() over (partition by comp_id order by db_update_time desc) rn
		from dw_nd.ods_t_proj_comp_appropriation  -- 拨付信息
		where date_format(db_update_time,'%Y%m%d') <= '${v_sdate}'
	) t
	where rn = 1
) t2
on t1.id = t2.comp_id
left join
	(
	select
		dept_id,
		dept_name
	from
		(
		select
			dept_id
			,dept_name
			,update_time
			,row_number() over (partition by dept_id order by update_time desc) as rn
		from dw_nd.ods_t_sys_dept   -- 部门表
		where date_format(update_time,'%Y%m%d') <= '${v_sdate}'
		) t
	where rn = 1
	) t3
on t1.loans_bank = t3.dept_id
inner join (
	select code,cust_identity_no,zhongzheng_code
	from (
		select id,code,cust_identity_no,zhongzheng_code
		from dw_nd.ods_t_biz_project_main   -- 主项目表
		where main_type = '02' -- 企业
						   and code is not null
	)t
	group by id
)t4
on t1.proj_code = t4.code
left join dw_nd.ods_imp_comp_zzm t5
on t4.code = t5.guar_id
where t1.status = '50' -- 已代偿
and coalesce(t5.id_num,t4.zhongzheng_code) is not null -- 债务人身份标识号码不能为空
;

commit;

-- 道一云
-- 1.当日数据  tmp_exp_credit_comp_guar_info_ready
-- 2.生成当日与昨日数据的对比 exp_credit_comp_guar_info_ready
-- insert into       dw_base.tmp_exp_credit_per_guar_info_all
-- 所有截止到当天


drop table if exists dw_tmp.tmp_exp_credit_comp_guar_info_ready ;commit;
create table dw_tmp.tmp_exp_credit_comp_guar_info_ready (
	day_id             varchar(8)    comment '数据日期',
	guar_id            varchar(60)   comment 'guar_id',
	cust_id            varchar(60)   comment '客户号',
	acct_type          varchar(2)    comment '账户类型',
	acct_code          varchar(60)   comment '账户标识码',
	rpt_date           varchar(20)   comment '信息报告日期',
	rpt_date_code      varchar(2)    comment '报告时点说明代码',
	name               varchar(80)   comment '债务人名称',
	id_type            varchar(2)    comment '债务人身份标识类型',
	id_num             varchar(40)   comment '债务人身份标识号码',
	mngmt_org_code     varchar(14)   comment '业务管理机构代码',
	busi_lines         varchar(1)    comment '担保业务大类',
	busi_dtil_lines    varchar(2)    comment '担保业务种类细分',
	open_date          varchar(20)   comment '开户日期',
	guar_amt           int           comment '担保金额',
	cy                 varchar(3)    comment '币种',
	due_date           varchar(20)   comment '到期日期',
	guar_mode          varchar(1)    comment '反担保方式',
	oth_repy_guar_way  varchar(1)    comment '其他还款保证方式',
	sec_dep            varchar(3)    comment '保证金比例',
	ctrct_txt_code     varchar(60)   comment '担保合同文本编号',
	acct_status        varchar(1)    comment '账户状态',
	loan_amt           int           comment '在保余额',
	repay_prd          varchar(20)   comment '余额变化日期',
	five_cate          varchar(1)    comment '五级分类',
	five_cate_adj_date varchar(20)   comment '五级分类认定日期',
	ri_ex              varchar(20)   comment '风险敞口',
	comp_adv_flag      varchar(1)    comment '代偿(垫款)标志',
	close_date         varchar(20)   comment '账户关闭日期',
	data_source        varchar(20)   comment '数据来源' ,
	key(guar_id)
) engine=innodb default charset=utf8mb4 collate=utf8mb4_bin row_format=dynamic comment='担保临时表'
;
commit;

insert into dw_tmp.tmp_exp_credit_comp_guar_info_ready
select
	'${v_sdate}' as day_id
	,t1.guar_id                                             -- 担保id
	,t1.cust_id                                             -- 客户号
	,'G1' as acct_type                                      -- 账户类型  G1-融资担保账户
	-- ,concat('X3701010000337',replace(t1.guar_id,'-','')) as acct_code    -- 账户标识码
	,replace(t1.guar_id,'-','') as acct_code    -- 账户标识码
	,'${v_sdate}' as rpt_date                                            -- 信息报告日期
	,case when t1.acct_status = '1' then '10' else '20' end as rpt_date_code -- 报告时点说明代码
	,t1.name          -- 债务人姓名
	,'10' as id_type  -- 债务人证件类型   10-中征码
	,t.id_num       -- 债务人中征码
	-- ,'X3701010000337' as mngmt_org_code -- 业务管理机构代码
	,'9999999' as mngmt_org_code -- 业务管理机构代码
	,'1' as busi_lines                  -- 担保业务大类      1-融资担保
	,'01' as busi_dtil_lines            -- 担保业务种类细分  01-贷款担保
	,date_format(loan_begin_dt,'%Y-%m-%d') as open_date -- 开户日期
	,t1.loan_amt as guar_amt -- 担保金额
	,'CNY' as cy       -- 币种
	,date_format(t1.loan_end_dt,'%Y-%m-%d') as due_date -- 到期日期
	,protect_guar -- 反担保方式
	,'0' as oth_repy_guar_way         -- 其他还款保证方式
	,0   as sec_dep                   -- 保证金比例
	,''  as ctrct_txt_code            -- 担保合同文本编号
	,case when t2.guar_id is not null then '2' -- 有代偿 则代 关闭
		  when t1.close_date = '' then '1'
		  when t1.close_date <= date_format('${v_sdate}','%Y-%m-%d') then '2'
		  else '1'
	 end  acct_status   -- 账户状态
	,case when t1.close_date = '' then  t1.loan_amt
		  when t1.close_date <= date_format('${v_sdate}','%Y-%m-%d') then 0
		  else t1.loan_amt
	 end loan_amt       -- 在保余额
	,repay_prd          -- 余额变化日期
	,t1.five_cate       -- 五级分类
	,five_cate_adj_date -- 五级分类认定日期
	,t1.ri_ex           -- 风险敞口
	,case when t2.guar_id is not null then 1 else 0 end -- 代偿(垫款)标志
	,case when t2.guar_id is not null then case when date_format(t2.compt_dt,'%Y-%m-%d') > t1.close_date
												then date_format(t2.compt_dt,'%Y-%m-%d')
												else t1.close_date end   -- 有代偿则代偿日期为关闭日期
		  when t1.close_date = '' then ''
		  when t1.close_date <= date_format('${v_sdate}','%Y-%m-%d') then t1.close_date
		  else ''
	end as close_date -- 账户关闭日期
	,'dyy' -- 数据来源
from(
	select cust_id
		   ,guar_id        -- 账号
		   ,cert_no        -- 证件号码
		   ,loan_begin_dt  -- 贷款开始时间   开户日期
		   ,loan_amt       -- 担保金额
		   ,loan_end_dt    -- 到期日期
		   ,protect_guar   -- 0-信用/免担保 1-保证 2-质押 3-抵押 4-组合
		   ,ctrct_txt_cd   -- 担保合同文本编号
		   ,acct_status    -- 账户状态  1-正常 2-关闭
		   ,name           -- 债务人姓名
		   ,loan_bal       -- 在保余额
		   ,date_format('${v_sdate}','%Y-%m-%d') repay_prd  -- 余额变化日期【后面对这个字段做了处理】
		   ,'1' five_cate   -- 五级分类
		   ,date_format('${v_sdate}','%Y-%m-%d') five_cate_adj_date -- 五级分类认定日期【后面对这个字段做了处理】
		   ,'' ri_ex -- 风险敞口
		   ,'0' comp_adv_flag -- 代偿标志
		   ,close_date -- 关闭日期
	from dw_tmp.tmp_exp_credit_comp_guar_info_id t1   -- 已经限制企业
	where loan_end_dt is not null  -- 贷款结束时间
	and loan_begin_dt is not null  -- 贷款开始时间
	-- and loan_end_dt <> ''
	-- and loan_begin_dt <> ''
	and loan_begin_dt < loan_end_dt  -- 到期日期大于开始日期
	and  length(cert_no) = 18
) t1
inner join (
	select guar_id,id_num
	from dw_nd.ods_imp_comp_zzm  -- 手工录入中征码
	where cust_type = '01' -- 借款人
	and guar_id not in (
		select code
		from (
			select code,zhongzheng_code
			from (
				select id,code,zhongzheng_code,row_number() over (partition by id order by db_update_time desc,update_time desc) as rn
				from dw_nd.ods_t_biz_project_main
			)t
			where rn = 1
		)t
		where zhongzheng_code is not null
	)
	union all
	select code,zhongzheng_code from(
		select code,zhongzheng_code
		from (
			select id,code,zhongzheng_code,row_number() over (partition by id order by db_update_time desc,update_time desc) as rn
			from dw_nd.ods_t_biz_project_main
		)t
		where rn = 1
	)t
	where zhongzheng_code is not null
) t  -- 市管中心录入中征码
on t1.guar_id = t.guar_id
left join dw_tmp.tmp_imp_comp_compt_cust_info_compt t2 -- 代偿信息表
on t1.guar_id = t2.guar_id
and t2.compt_dt <=  date_format('${v_sdate}','%Y-%m-%d')  -- 代偿日期
where date_format(t1.loan_begin_dt,'%Y-%m-%d') <= date_format('${v_sdate}','%Y-%m-%d')
and (t1.close_date  <=  date_format('${v_sdate}','%Y-%m-%d') or t1.close_date = '' ) -- 前面已经对未关户账户的关户时间变成了''
;
commit;


-- 3.与昨日数据对比获取余额变动日期、五级分类变动日期、其他信息变动
-- 存放当天数据
delete from dw_base.exp_credit_comp_guar_info_ready where day_id ='${v_sdate}' ;
commit;

insert into dw_base.exp_credit_comp_guar_info_ready
select distinct
	t1.day_id              -- 数据日期
	,t1.guar_id            -- 担保id
	,t1.cust_id            -- 客户号
	,t1.acct_type          -- 账户类型
	,t1.acct_code          -- 账户标识码
	,t1.rpt_date           -- 信息报告日期
	,t1.rpt_date_code      -- 报告时点说明代码
	,t1.name               -- 债务人姓名
	,t1.id_type            -- 债务人证件类型
	,t1.id_num		       -- 债务人证件号码
	,t1.mngmt_org_code     -- 业务管理机构代码
	,t1.busi_lines         -- 担保业务大类
	,t1.busi_dtil_lines    -- 担保业务种类细分
	,t1.open_date          -- 开户日期
	,t1.guar_amt           -- 担保金额
	,t1.cy                 -- 币种
	,t1.due_date           -- 到期日期
	,t1.guar_mode          -- 反担保方式
	,t1.oth_repy_guar_way  -- 其他还款保证方式
	,t1.sec_dep            -- 保证金比例
	,t1.ctrct_txt_code     -- 担保合同文本编号
	,t1.acct_status        -- 账户状态
	,t1.loan_amt           -- 在保余额
	,case when t2.guar_id is null then t1.open_date   -- 昨天不存在的，则是当天新开户的，余额变动日取开户日
		  when abs(t1.loan_amt - t2.loan_amt) > 0 then date_format('${v_sdate}','%Y-%m-%d')  -- 跑批日和 跑批前一日余额不同，则取跑批日作为变动日
		  else t2.open_date end    -- 余额变化日期    昨天有，且没有变化 取昨天开户日期
	,t1.five_cate    -- 五级分类
	,case when t2.guar_id is null then t1.open_date  -- -- 昨天不存在的，则是当天新开户的，变动日取开户日
		  else t2.open_date end    -- 五级分类认定日期  昨天有，取昨天开户日期
		  -- “五级分类认定日期”与库中相邻两条记录的“五级分类认定日期” 必须满足日期由远及近或相等的关系。
	,t1.ri_ex  -- 风险敞口
	,t1.comp_adv_flag  -- 代偿(垫款)标志
	,t1.close_date     -- 账户关闭日期
	,t1.data_source    -- 数据来源
from dw_tmp.tmp_exp_credit_comp_guar_info_ready t1    -- 企业担保信息
left join dw_base.exp_credit_comp_guar_info_ready t2
on t1.guar_id = t2.guar_id
and t2.day_id = '${v_yesterday}'
left join (select guar_id,open_date from dw_base.exp_credit_comp_guar_info where rpt_date_code = '10') t3
on t1.guar_id = t3.guar_id
where t1.day_id = '${v_sdate}'
;
commit;


-- 1.当天新增
-- create  table dw_base.exp_credit_comp_guar_info_open (
--  guar_id	    varchar(60)	comment '账号'
--  ,day_id 	varchar(8)	comment '日期'
--  ,open_date	varchar(20)	comment '开户日期'
--  ,close_date varchar(20)	comment '关户日期'
--  ,key(guar_id)
--  ) engine=innodb  default charset=utf8mb4 collate=utf8mb4_bin row_format=dynamic ;

delete  from dw_base.exp_credit_comp_guar_info_open where day_id = '${v_sdate}' ;
commit;
insert into dw_base.exp_credit_comp_guar_info_open
select guar_id
	   ,day_id
	   ,open_date
	   ,close_date
from dw_base.exp_credit_comp_guar_info_ready t1
where t1.day_id = '${v_sdate}'
and t1.open_date <= date_format('${v_sdate}' ,'%Y-%m-%d')     -- 放款日期为当天即新增,且保证首次上报时该表里有除已关户的所有客户
-- and t1.close_date = ''    --首次上报时若关户 也上报，算在首次上报里,所以去掉了这个条件20220818修改
 and DATEDIFF(DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d'),t1.open_date) <= 30 -- 开户30天以上的无法通过校验
and not exists (         -- 第一次上报
	select 1
	from dw_base.exp_credit_comp_guar_info_open t2
	where t2.day_id < '${v_sdate}'
	and t1.guar_id = t2.guar_id
)
;
commit;


-- 2.获取当天解保台账
-- create  table dw_base.exp_credit_comp_guar_info_close (
--  guar_id	varchar(60)	comment '账号'
--  ,day_id 	varchar(8)	comment '日期'
--  ,close_date	date	comment '解保日期'
--  ,key(guar_id)
--  ) engine=innodb  default charset=utf8mb4 collate=utf8mb4_bin row_format=dynamic ;

delete from dw_base.exp_credit_comp_guar_info_close where day_id = '${v_sdate}' ;
commit;
insert into dw_base.exp_credit_comp_guar_info_close
select guar_id
	   ,day_id
	   ,close_date
from dw_base.exp_credit_comp_guar_info_ready t1
where t1.day_id = '${v_sdate}'
and t1.close_date <= date_format('${v_sdate}' ,'%Y-%m-%d')  -- 关闭日期为当天
and t1.open_date < date_format('${v_sdate}' ,'%Y-%m-%d')  -- 开户日期（当天开户的算在开户时点）
-- and t1.close_date <> ''
and t1.close_date is not null
and length(t1.close_date) >0
and not exists (         -- 新增 关闭账户
	select 1
	from dw_base.exp_credit_comp_guar_info_close t2
	where t2.day_id < '${v_sdate}'
	and t1.guar_id = t2.guar_id
)
and  exists (
	select 1 from dw_base.exp_credit_comp_guar_info_open t2 --   之前开户且首次上报未关户
	where t2.day_id <= '${v_sdate}'
	and t2.close_date = ''
	and t1.guar_id = t2.guar_id
)
;
commit;

-- 3.获取当天余额变动台账
-- create  table dw_base.exp_credit_comp_guar_info_bal_change (
--  guar_id	varchar(60)	comment '账号'
--  ,day_id 	varchar(8)	comment '日期'
--  ,repay_prd	date	comment '解保日期'
--  ,key(guar_id)
--  ) engine=innodb  default charset=utf8mb4 collate=utf8mb4_bin row_format=dynamic ;

delete from dw_base.exp_credit_comp_guar_info_bal_change where day_id = '${v_sdate}' ;
commit;
insert into dw_base.exp_credit_comp_guar_info_bal_change
select guar_id
	   ,day_id
	   ,repay_prd   -- 余额变化日期
from dw_base.exp_credit_comp_guar_info_ready t1
where t1.day_id = '${v_sdate}'
and t1.repay_prd = date_format('${v_sdate}' ,'%Y-%m-%d')
and not exists (
	select 1 from dw_base.exp_credit_comp_guar_info_open t2 -- 余额变动 不能同时存在当天开户
	where t2.day_id = '${v_sdate}'
	and t1.guar_id = t2.guar_id
)
and not exists (
	select 1 from dw_base.exp_credit_comp_guar_info_close t2 -- 余额变动 不能有关闭【首次上报关户的不在这里面】
	where t2.day_id <= '${v_sdate}'
	and t1.guar_id = t2.guar_id
)
-- 首次上报里关户的
and not exists (
	select 1 from dw_base.exp_credit_comp_guar_info_open t2
	where t2.day_id < '${v_sdate}'
	-- and t2.close_date <> ''
	and t2.close_date is not null
	and length(t2.close_date) >0
	and t1.guar_id = t2.guar_id
)
and  exists (
	select 1 from dw_base.exp_credit_comp_guar_info_open t2 --   且是之前开户未关户客户
	where t2.day_id < '${v_sdate}'
	and t2.close_date = ''
	and t1.guar_id = t2.guar_id
)
;
commit;

-- 4.获取当天五级分类变动台账

--   create  table dw_base.exp_credit_comp_guar_info_risk_change (
--  guar_id	varchar(60)	comment '账号'
--  ,day_id 	varchar(8)	comment '日期'
--  ,five_cate_adj_date	date	comment '五级分类认定日期'
--  ,key(guar_id)
--  ) engine=innodb  default charset=utf8mb4 collate=utf8mb4_bin row_format=dynamic ;

delete from dw_base.exp_credit_comp_guar_info_risk_change where day_id = '${v_sdate}' ;
commit;

insert into dw_base.exp_credit_comp_guar_info_risk_change
select t1.guar_id
	   ,'${v_sdate}'
	   ,five_cate_adj_date  -- 五级分类认定日期
from dw_base.exp_credit_comp_guar_info_ready t1
where t1.day_id = '${v_sdate}'
and t1.five_cate_adj_date = date_format('${v_sdate}' ,'%Y-%m-%d')
and not exists (
	select 1 from dw_base.exp_credit_comp_guar_info_open t2 --   不能同时当天开户
	where t2.day_id = '${v_sdate}'
	and t1.guar_id = t2.guar_id
)
and not exists (
	select 1 from dw_base.exp_credit_comp_guar_info_bal_change t2 --   不能同时余额
	where t2.day_id = '${v_sdate}'
	and t1.guar_id = t2.guar_id
)
and not exists (
	select 1 from dw_base.exp_credit_comp_guar_info_close t2 --   不能关闭
	where t2.day_id <= '${v_sdate}'
	and t1.guar_id = t2.guar_id
)
-- 首次上报里关户的
and not exists (
	select 1 from dw_base.exp_credit_comp_guar_info_open t2
	where t2.day_id < '${v_sdate}'
	-- and t2.close_date <> ''
	and t2.close_date is not null
	and length(t2.close_date) >0
	and t1.guar_id = t2.guar_id
)
and  exists (
	select 1 from dw_base.exp_credit_comp_guar_info_open t2 --   且是之前开户未关户客户
	where t2.day_id < '${v_sdate}'
	and t2.close_date = ''
	and t1.guar_id = t2.guar_id
)
;
commit ;

-- 5.获取当天其他信息变动数据

-- create table if not exists dw_base.exp_credit_comp_guar_info_oth_change(
-- guar_id	varchar(60)	comment '账号'
-- ,day_id varchar(8) comment '日期'
-- ,change_date varchar(20) comment '日期'
-- ,key(guar_id)
-- ) engine=innodb  default charset=utf8mb4 collate=utf8mb4_bin row_format=dynamic
-- ;
--
-- commit ;

delete from dw_base.exp_credit_comp_guar_info_oth_change where day_id = '${v_sdate}'  ;
commit ;
--
insert into dw_base.exp_credit_comp_guar_info_oth_change
select t1.guar_id
	   ,'${v_sdate}'
	   ,date_format('${v_sdate}' ,'%Y-%m-%d') -- 变化日期
from dw_tmp.tmp_exp_credit_comp_guar_info_ready t1
inner join dw_base.exp_credit_comp_guar_info_ready t2
on t1.guar_id = t2.guar_id
and t2.day_id = '${v_yesterday}'
and t2.guar_id is not null
and (
	t1.busi_lines <> t2.busi_lines  -- 担保业务大类
	or t1.busi_dtil_lines <> t2.busi_dtil_lines  -- 担保业务种类细分
	or t1.open_date <> t2.open_date     -- 开户日期
	or t1.guar_amt <> t2.guar_amt  -- 担保金额
	or t1.cy <> t2.cy  -- 币种
	or t1.due_date <> t2.due_date  -- 到期日期
	or t1.guar_mode  <> t2.guar_mode  -- 反担保方式
	or t1.oth_repy_guar_way <> t2.oth_repy_guar_way  -- 其他还款保证方式
	or t1.sec_dep <> t2.sec_dep  -- 保证金比例
)
where t1.day_id = '${v_sdate}'
and not exists (
	select 1 from dw_base.exp_credit_comp_guar_info_open t2 --   不能同时当天开户
	where t2.day_id = '${v_sdate}'
	and t1.guar_id = t2.guar_id
)
and not exists (
		select 1 from dw_base.exp_credit_comp_guar_info_bal_change t2 --   不能同时余额
		where t2.day_id = '${v_sdate}'
		and t1.guar_id = t2.guar_id
		)
and not exists (
	select 1 from dw_base.exp_credit_comp_guar_info_risk_change t2 --   不能风险变动
	where t2.day_id = '${v_sdate}'
	and t1.guar_id = t2.guar_id
)
and not exists (
	select 1 from dw_base.exp_credit_comp_guar_info_close t2 --   不能关闭
	where t2.day_id <= '${v_sdate}'
	and t1.guar_id = t2.guar_id
)
-- 首次上报里关户的
and not exists (
	select 1 from dw_base.exp_credit_comp_guar_info_open t2
	where t2.day_id < '${v_sdate}'
	-- and t2.close_date <> ''
	and t2.close_date is not null
	and length(t2.close_date) >0
	and t1.guar_id = t2.guar_id
)
and  exists (
	select 1 from dw_base.exp_credit_comp_guar_info_open t2 --   且是之前开户未关户客户
	where t2.day_id < '${v_sdate}'
	and t2.close_date = ''
	and t1.guar_id = t2.guar_id
)
;
commit ;


-- 所有上报客户
drop table if exists dw_tmp.tmp_exp_credit_comp_cust_info_sb ;

commit;

create table dw_tmp.tmp_exp_credit_comp_cust_info_sb (
	cust_id  varchar(60) -- 客户编号
	,name    varchar(30) -- 客户名称
	,id_type varchar(2)  -- 证件类型
	,id_num  varchar(20) -- 证件号
	,key(cust_id)
) engine=innodb default charset=utf8mb4 collate=utf8mb4_bin row_format=dynamic ;

commit;

insert into dw_tmp.tmp_exp_credit_comp_cust_info_sb
select a.cust_id,
	   a.name,
	   a.id_type,
	   a.id_num
from dw_tmp.tmp_exp_credit_comp_guar_info_ready a
group by a.cust_id
;
commit;

-- 数据生成后开始组装报文

delete from dw_base.exp_credit_comp_guar_info where day_id = '${v_sdate}' ;
commit;
-- 插入 10账户开立   昨天没有，今天有，10账户开立
insert into dw_base.exp_credit_comp_guar_info
select
	t1.day_id		            -- 数据日期
	,t1.guar_id		            -- guar_id
	,t1.cust_id		            -- 客户号
	,t1.acct_type		        -- 账户类型
	,t1.acct_code		        -- 账户标识码
	,t1.rpt_date		        -- 信息报告日期
	,'10'	                    -- 报告时点说明代码
	,t1.name		            -- 债务人名称
	,t1.id_type		            -- 债务人身份标识类型
	,t1.id_num		            -- 债务人身份标识号码
	,t1.mngmt_org_code	        -- 业务管理机构代码
	,t1.busi_lines		        -- 担保业务大类
	,t1.busi_dtil_lines	        -- 担保业务种类细分
	,t1.open_date		        -- 开户日期
	,t1.guar_amt		        -- 担保金额
	,t1.cy		                -- 币种
	,t1.due_date		        -- 到期日期
	,t1.guar_mode		        -- 反担保方式
	,t1.oth_repy_guar_way		-- 其他还款保证方式
	,t1.sec_dep		            -- 保证金比例
	,t1.ctrct_txt_code		    -- 担保合同文本编号
	,t1.acct_status		        -- 账户状态
	,t1.loan_amt		        -- 在保余额
	,t1.repay_prd		        -- 余额变化日期
	,t1.five_cate		        -- 五级分类
	,t1.five_cate_adj_date		-- 五级分类认定日期
	,t1.ri_ex		            -- 风险敞口
	,t1.comp_adv_flag		    -- 代偿(垫款)标志
	,t1.close_date		        -- 账户关闭日期
	,t1.data_source		        -- 数据来源
from dw_base.exp_credit_comp_guar_info_ready t1
inner join dw_base.exp_credit_comp_guar_info_open t2
on t1.guar_id = t2.guar_id
and t2.day_id = '${v_sdate}'
where t1.day_id =  '${v_sdate}'
;
commit ;


-- 插入 20 账户关闭 账户关闭时间判断   昨天有，今天有，且状态由正常变为关闭
insert into dw_base.exp_credit_comp_guar_info
select
	t1.day_id		            -- 数据日期
	,t1.guar_id		            -- guar_id
	,t1.cust_id		            -- 客户号
	,t1.acct_type		        -- 账户类型
	,t1.acct_code		        -- 账户标识码
	,t1.rpt_date		        -- 信息报告日期
	,'20'	                    -- 报告时点说明代码
	,t1.name		            -- 债务人名称
	,t1.id_type		            -- 债务人身份标识类型
	,t1.id_num		            -- 债务人身份标识号码
	,t1.mngmt_org_code	        -- 业务管理机构代码
	,t1.busi_lines		        -- 担保业务大类
	,t1.busi_dtil_lines	        -- 担保业务种类细分
	,t1.open_date		        -- 开户日期
	,t1.guar_amt		        -- 担保金额
	,t1.cy		                -- 币种
	,t1.due_date		        -- 到期日期
	,t1.guar_mode		        -- 反担保方式
	,t1.oth_repy_guar_way		-- 其他还款保证方式
	,t1.sec_dep		            -- 保证金比例
	,t1.ctrct_txt_code		    -- 担保合同文本编号
	,t1.acct_status		        -- 账户状态
	,t1.loan_amt		        -- 在保余额
	,case when t1.repay_prd	> t1.close_date then t1.close_date
		  else t1.repay_prd end  repay_prd        -- 余额变动日期   -- 取账户关闭日期
	,t1.five_cate	         -- 五级分类
	,case when t1.five_cate_adj_date > t1.close_date then t1.close_date
		  else t1.five_cate_adj_date end five_cate_adj_date	 -- 五级分类认定日期 -- 取账户关闭日期
	,t1.ri_ex		            -- 风险敞口
	,t1.comp_adv_flag		    -- 代偿(垫款)标志
	,t1.close_date		        -- 账户关闭日期
	,t1.data_source		        -- 数据来源
from dw_base.exp_credit_comp_guar_info_ready t1
inner join dw_base.exp_credit_comp_guar_info_close t2
on t1.guar_id = t2.guar_id
and t2.day_id = '${v_sdate}'
where t1.day_id = '${v_sdate}'
;
commit ;


-- 插入 30 在保责任变化    昨天有，今天有，且 在保余额发生变化
insert into dw_base.exp_credit_comp_guar_info
select
	t1.day_id		            -- 数据日期
	,t1.guar_id		            -- guar_id
	,t1.cust_id		            -- 客户号
	,t1.acct_type		        -- 账户类型
	,t1.acct_code		        -- 账户标识码
	,t1.rpt_date		        -- 信息报告日期
	,'30'	                    -- 报告时点说明代码
	,t1.name		            -- 债务人名称
	,t1.id_type		            -- 债务人身份标识类型
	,t1.id_num		            -- 债务人身份标识号码
	,t1.mngmt_org_code	        -- 业务管理机构代码
	,t1.busi_lines		        -- 担保业务大类
	,t1.busi_dtil_lines	        -- 担保业务种类细分
	,t1.open_date		        -- 开户日期
	,t1.guar_amt		        -- 担保金额
	,t1.cy		                -- 币种
	,t1.due_date		        -- 到期日期
	,t1.guar_mode		        -- 反担保方式
	,t1.oth_repy_guar_way		-- 其他还款保证方式
	,t1.sec_dep		            -- 保证金比例
	,t1.ctrct_txt_code		    -- 担保合同文本编号
	,t1.acct_status		        -- 账户状态
	,t1.loan_amt		        -- 在保余额
	,date_format('${v_sdate}' ,'%Y-%m-%d')            -- 余额变化日期
	,t1.five_cate	         -- 五级分类
	,t1.five_cate_adj_date	 -- 五级分类认定日期
	,t1.ri_ex		            -- 风险敞口
	,t1.comp_adv_flag		    -- 代偿(垫款)标志
	,t1.close_date		        -- 账户关闭日期
	,t1.data_source		        -- 数据来源
from dw_base.exp_credit_comp_guar_info_ready t1
inner join dw_base.exp_credit_comp_guar_info_bal_change t2
on t1.guar_id = t2.guar_id
and t2.day_id = '${v_sdate}'
where t1.day_id = '${v_sdate}'
;
commit ;


-- 插入 40 五级分类调整    昨天有，今天有，且 五级分类发生变化
insert into dw_base.exp_credit_comp_guar_info
select
	t1.day_id		            -- 数据日期
	,t1.guar_id		            -- guar_id
	,t1.cust_id		            -- 客户号
	,t1.acct_type		        -- 账户类型
	,t1.acct_code		        -- 账户标识码
	,t1.rpt_date		        -- 信息报告日期
	,'40'	                    -- 报告时点说明代码
	,t1.name		            -- 债务人名称
	,t1.id_type		            -- 债务人身份标识类型
	,t1.id_num		            -- 债务人身份标识号码
	,t1.mngmt_org_code	        -- 业务管理机构代码
	,t1.busi_lines		        -- 担保业务大类
	,t1.busi_dtil_lines	        -- 担保业务种类细分
	,t1.open_date		        -- 开户日期
	,t1.guar_amt		        -- 担保金额
	,t1.cy		                -- 币种
	,t1.due_date		        -- 到期日期
	,t1.guar_mode		        -- 反担保方式
	,t1.oth_repy_guar_way		-- 其他还款保证方式
	,t1.sec_dep		            -- 保证金比例
	,t1.ctrct_txt_code		    -- 担保合同文本编号
	,t1.acct_status		        -- 账户状态
	,t1.loan_amt		        -- 在保余额
	,t1.repay_prd            -- 余额变化日期
	,t1.five_cate	         -- 五级分类
	,date_format('${v_sdate}' ,'%Y-%m-%d')	 -- 五级分类认定日期
	,t1.ri_ex		            -- 风险敞口
	,t1.comp_adv_flag		    -- 代偿(垫款)标志
	,t1.close_date		        -- 账户关闭日期
	,t1.data_source		        -- 数据来源
from dw_base.exp_credit_comp_guar_info_ready t1
inner join dw_base.exp_credit_comp_guar_info_risk_change t2
on t1.guar_id = t2.guar_id
and t2.day_id = '${v_sdate}'
where t1.day_id = '${v_sdate}'
;
commit ;


-- 插入 50 其他信息变化
insert into dw_base.exp_credit_comp_guar_info
select
	t1.day_id		            -- 数据日期
	,t1.guar_id		            -- guar_id
	,t1.cust_id		            -- 客户号
	,t1.acct_type		        -- 账户类型
	,t1.acct_code		        -- 账户标识码
	,t1.rpt_date		        -- 信息报告日期
	,'50'	                    -- 报告时点说明代码
	,t1.name		            -- 债务人名称
	,t1.id_type		            -- 债务人身份标识类型
	,t1.id_num		            -- 债务人身份标识号码
	,t1.mngmt_org_code	        -- 业务管理机构代码
	,t1.busi_lines		        -- 担保业务大类
	,t1.busi_dtil_lines	        -- 担保业务种类细分
	,t1.open_date		        -- 开户日期
	,t1.guar_amt		        -- 担保金额
	,t1.cy		                -- 币种
	,t1.due_date		        -- 到期日期
	,t1.guar_mode		        -- 反担保方式
	,t1.oth_repy_guar_way		-- 其他还款保证方式
	,t1.sec_dep		            -- 保证金比例
	,t1.ctrct_txt_code		    -- 担保合同文本编号
	,t1.acct_status		        -- 账户状态
	,t1.loan_amt		        -- 在保余额
	,t1.repay_prd               -- 余额变化日期
	,t1.five_cate	            -- 五级分类
	,t1.five_cate_adj_date	    -- 五级分类认定日期
	,t1.ri_ex		            -- 风险敞口
	,t1.comp_adv_flag		    -- 代偿(垫款)标志
	,t1.close_date		        -- 账户关闭日期
	,t1.data_source		        -- 数据来源
from dw_base.exp_credit_comp_guar_info_ready t1
inner join dw_base.exp_credit_comp_guar_info_oth_change t2
on t1.guar_id = t2.guar_id
and t2.day_id = '${v_sdate}'
where t1.day_id = '${v_sdate}'
;
commit ;


-- 10-新开户/首次上报 指担保关系开始生效的日期
-- 20-账户关闭     指担保关系解除/失效的日期，包括两种情况：1.债务人如约履行还款义务时，第三方或有负债责任自动解除；
														-- 2.债务人未履约还款，第三方代偿全部债务，担保关系转成借贷关系。
-- 30-在保责任变化    在保责任信息段数据项说明 指在保余额等相关信息发生变化日期
-- 40-五级分类调整    在保责任信息段数据项说明 指相对于上一认定日期，五级分类状态发生了调整的日期。此时需要在该认定日期报送担保账户信息
-- 50-其他信息变化（包括相关还款责任人、抵（质）押合同等信息发生变化） 指在保余额、五级分类等信息之外的其他信息发生变化的日期 其他信息包括：相关还款责任人信息、账户基本信息、抵（质）押物信息。


-- 相关还款责任人（只在账户开立的时候上报）

-- 每笔业务对应的反担保人信息,共同借款人信息
drop table if exists dw_tmp.tmp_exp_credit_comp_guar_info_xz_counter ;
commit;

create table dw_tmp.tmp_exp_credit_comp_guar_info_xz_counter (
	duty_type          varchar(60),
	apply_code         varchar(60),
	project_id         varchar(60),
	counter_name       varchar(60),
	id_type            varchar(4),
	id_no              varchar(40),
	index idx_tmp_exp_credit_comp_guar_info_xz_counter_project_id(project_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC
;
commit;

insert into dw_tmp.tmp_exp_credit_comp_guar_info_xz_counter
select distinct
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
					row_number() over (partition by apply_code order by update_time desc ) as rn
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
		coalesce(id_type,ident_type) id_type,
		id_no
	from
		(
			select
				apply_code,
				counter_name,
				id_type,  -- 10 证件号  20 企业信用代码
				case when id_no like '9%' then '20' else '10' end ident_type,
				id_no,
				row_number() over (partition by apply_code,id_no,counter_name order by update_time desc ) as rn
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
					row_number() over (partition by apply_code order by update_time desc) as rn
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
				upper(id_no)id_no,
				row_number() over (partition by apply_code,upper(id_no) order by update_time desc) as rn
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
		select id,code,spouse_co_borrower,row_number() over (partition by id order by db_update_time desc,update_time desc) as rn
		from dw_nd.ods_t_biz_project_main
	)t
	where rn = 1
) t3
on t1.guar_id = t3.id and t3.spouse_co_borrower is true
;
commit;


-- 授权的反担保人
drop table if exists dw_tmp.tmp_exp_credit_comp_guar_info_xz_counter_sq ;
commit;

create table dw_tmp.tmp_exp_credit_comp_guar_info_xz_counter_sq (
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

insert into dw_tmp.tmp_exp_credit_comp_guar_info_xz_counter_sq
select
	   t.duty_type, -- 1-共同债务人 2-反担保人 9-其他
	   t.apply_code,
	   t.project_id,   -- 担保业务系统ID
	   t.counter_name,  -- 反担保人/共同借款人名称
	   coalesce(t.id_type,t2.cust_type),  -- 反担保人/共同借款人证件类型
	   coalesce(t.id_no,t2.id_no), -- 反担保人/共同借款人证件号
	   t2.cust_code  -- 反担保人/共同借款人客户号
from dw_tmp.tmp_exp_credit_comp_guar_info_xz_counter t -- 每笔申请记录对应的反担保人/共同借款人信息
inner join
(
  select customer_id
		,main_name
		,main_id_type
		,main_id_no
  from
  (
	select customer_id,main_name,main_id_type,main_id_no,row_number() over (partition by main_id_no order by update_time desc) as rn
	from dw_nd.ods_wxapp_cust_login_info     -- 用户注册信息
	where status = '10'  -- 已授权   授权的客户证件号都不为空，去掉了 customer_id is not null and main_id_no is null 这个条件
  ) t
	where rn = 1
)t1
on t.id_no = t1.main_id_no
left join (
	select cust_code,id_no,cust_type
	from (
		select cust_code,id_no,cust_type,row_number() over (partition by cust_code order by update_time desc) as rn
		from dw_nd.ods_crm_cust_info
	)t
	where rn = 1
)t2    -- mdy 20240911，之前是按照id_No取最新，但是会存在一个证件号对应多个客户号的情况，漏掉客户号，导致后面关联不到合同
on t.id_no = t2.id_no
;
commit;

-- 反担保合同

drop table if exists dw_tmp.tmp_exp_credit_comp_guar_info_xz_counter_contract ;
commit;

create table dw_tmp.tmp_exp_credit_comp_guar_info_xz_counter_contract (
	biz_id                varchar(64),
	contract_id           varchar(128),
	customer_id           varchar(64),
	contract_template_id  varchar(64),
	-- AUTHORIZED_CUSTOMER_ID varchar(64),
	index idx_tmp_exp_credit_comp_guar_info_xz_counter_contract_biz_id(biz_id),
	index tmp_exp_credit_comp_guar_info_xz_counter_contract_customer_id(customer_id)
	-- index tmp_exp_credit_comp_guar_info_xz_counter_contract_AUTHORIZED_id(AUTHORIZED_CUSTOMER_ID)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC
;
commit;

insert into dw_tmp.tmp_exp_credit_comp_guar_info_xz_counter_contract
select biz_id
	   ,contract_id  -- 合同编号
	   ,customer_id  -- 签署人客户号
	   ,contract_template_id -- 合同模板id
from (
select biz_id
	   ,contract_id  -- 合同编号
	   ,customer_id  -- 签署人客户号
	   -- ,concat('X3701010000337',contract_template_id) as contract_template_id -- 合同模板id
	   ,contract_template_id as contract_template_id -- 合同模板id
	   -- ,AUTHORIZED_CUSTOMER_ID
	   ,status
from
(
	select biz_id
		   ,contract_id  -- 合同编号
		   ,coalesce(AUTHORIZED_CUSTOMER_ID,customer_id)customer_id  -- 签署人客户号
		   ,contract_template_id  -- 合同模板id
		   ,AUTHORIZED_CUSTOMER_ID
		   ,status
		   ,row_number() over (partition by biz_id,customer_id,AUTHORIZED_CUSTOMER_ID order by update_time desc) as rn -- mdy 20240920 之前是按照biz_id和contract_id去重取最新，但电子签章历史bug导致一个客户有多个已签约合同，所以修改为biz_id,customer_id,AUTHORIZED_CUSTOMER_ID去重取最新
	from dw_nd.ods_comm_cont_comm_contract_info
	where contract_name like '%反担保%'
		and contract_name not like '%反担保抵押%'
		and contract_name not like '%反担保质押%'
)a
where rn = 1
)t
where status = '2' -- 已签约

;
commit;



 -- 补充反担保合同（线下签约）[合同号带‘线下’字样的属于线下签约]
drop table if exists dw_tmp.tmp_exp_credit_comp_guar_info_xz_counter_contract_xx ;
commit;

create table dw_tmp.tmp_exp_credit_comp_guar_info_xz_counter_contract_xx (
	project_id                varchar(64),
	ct_guar_person_name       varchar(128),
	ct_guar_person_id_no      varchar(64),
	count_cont_code           varchar(64),
	index idx_tmp_xz_counter_contract_xx_project_id(project_id),
	index idx_tmp_xz_counter_contract_xx_ct_guar_person_id_no(ct_guar_person_id_no)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC
;
commit;

insert into dw_tmp.tmp_exp_credit_comp_guar_info_xz_counter_contract_xx

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
		   ,row_number() over (partition by id order by db_update_time desc ,update_time desc) as rn
	from dw_nd.ods_t_ct_guar_person
	where count_cont_code like '%线下%'
)t
where rn = 1
;
commit;

-- 担保业务系统id 和项目编号转换
drop table if exists dw_tmp.tmp_exp_credit_comp_guar_info_xz_counter_main;
commit;

create table dw_tmp.tmp_exp_credit_comp_guar_info_xz_counter_main (
	project_id         varchar(60),
	guar_id            varchar(60),
	index credit_per_guar_info_xz_counter_main_project_id(project_id),
	index credit_per_guar_info_xz_counter_main_ct_guar_person_id_no(guar_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC
;
commit;

insert into dw_tmp.tmp_exp_credit_comp_guar_info_xz_counter_main
select id,
	   code
from (
select id,
	   code,
	   row_number() over (partition by id order by db_update_time desc,update_time desc) as rn
from dw_nd.ods_t_biz_project_main
)a
where rn = 1
;
commit;

-- 从风险检查表中拿产业集群信息
drop table if exists dw_tmp.tmp_exp_credit_comp_guar_info_check;
commit;

create table dw_tmp.tmp_exp_credit_comp_guar_info_check (
	project_id         varchar(60),
	aggregate_scheme   varchar(60),
	index tmp_exp_credit_comp_guar_info_checkproject_id(project_id),
	index tmp_exp_credit_comp_guar_info_check_aggregate_scheme(aggregate_scheme)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC
;
commit;

insert into dw_tmp.tmp_exp_credit_comp_guar_info_check
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
drop table if exists dw_tmp.tmp_exp_credit_comp_guar_info_risk_comp;commit;
create table if not exists dw_tmp.tmp_exp_credit_comp_guar_info_risk_comp(
company_name varchar(200) comment'企业名称',
unified_social_credit_code varchar(50) comment '统一社会信用代码',
counter_guar_contract_number varchar(50) comment '反担保合同',
risk_grade varchar(255) comment'分险比例',
dictionaries_code varchar(50) comment '产业集群'
);
commit;

insert into dw_tmp.tmp_exp_credit_comp_guar_info_risk_comp
select t1.company_name,t1.unified_social_credit_code,t2.counter_guar_contract_number,t2.risk_grade,t2.dictionaries_code
from (
	select * from (
		select *,row_number() over (partition by id order by update_time desc) as rn from dw_nd.ods_cem_company_base -- 核心企业基本表
	)t
	where rn = 1
)t1
inner join (
	select * from (
		select *,row_number() over (partition by id order by update_time) as rn from dw_nd.ods_cem_dictionaries  -- 企业产业集群关系
	)t
	where rn = 1
)t2
on t1.id = t2.cem_base_id -- 核心企业id    【经沟通，ods_cem_company_base的分险比例字段废弃，企业的分险比例用关系表中的】
;
commit;

-- 核心企业管理中自然人分险
drop table if exists dw_tmp.tmp_exp_credit_comp_guar_info_risk_natural;commit;
create table if not exists dw_tmp.tmp_exp_credit_comp_guar_info_risk_natural(
person_name varchar(200) comment'自然人名称',
person_identity varchar(50) comment '证件号',
counter_guar_contract_number varchar(50) comment '反担保合同',
risk_grade varchar(255) comment'分险比例',
dictionaries_code varchar(50) comment '产业集群'
);
commit;

insert into dw_tmp.tmp_exp_credit_comp_guar_info_risk_natural
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
			select *,row_number() over (partition by id order by update_time desc) as rn from dw_nd.ods_cem_dictionaries  -- 企业产业集群关系
		)t
		where rn = 1
	)t2
on t1.cem_dictionaries_id = t2.id
;
commit;

-- 还款责任人信息
DELETE FROM dw_base.exp_credit_comp_repay_duty_info where day_id = '${v_sdate}' ;
commit;

insert into dw_base.exp_credit_comp_repay_duty_info
select * from (
select t.day_id,
	   t.guar_id,
	   t.cust_id,
	   t.info_id_type,
	   t.duty_name,
	   t.duty_cert_type,
	   t.duty_cert_no,
	   t.duty_type,
	   case when t.duty_type='2' and t1.company_name is not null and t1.risk_grade <> '' and t1.risk_grade is not null then t.duty_amt*t1.risk_grade
			when t.duty_type='2' and t2.person_name is not null and t2.risk_grade <> '' and t2.risk_grade is not null then t.duty_amt*t2.risk_grade
			when t.duty_type='2' then t.duty_amt
			else null
		end as duty_amt,
	   case when t.duty_type='2' and t1.company_name is not null then concat(t1.counter_guar_contract_number,t.guar_id)
			when t.duty_type='2' and t2.person_name is not null then concat(t2.counter_guar_contract_number,t.guar_id)
			when t.duty_type='2' then t.guar_cont_no
			else null
		end as guar_cont_no  -- 反担保合同
from (
	select distinct '${v_sdate}' as day_id,
		t.guar_id,  -- 担保ID
		t.cust_id,  -- 客户号
		case when t2.id_type in ('01','10') then '1' when t2.id_type in ('02','20') then '2' else null end as info_id_type,  -- 身份类别  1-自然人  2-组织机构
		t2.counter_name as duty_name, -- 责任人名称
		'10' as duty_cert_type,  -- 责任人身份标识类型  10:居民身份证及其他以公民身份证号为标识的证件 20-统一社会信用代码 10-中征码（原贷款卡编码）
		case when t2.id_type in ('01','10')  then t2.id_no when t2.id_type in ('02','20') then coalesce(t6.id_num,t7.zhongzheng_code) else null end as duty_cert_no,  -- 责任人身份标识号码
		t2.duty_type, -- 1-共同债务人 2-反担保人 9-其他
		case when t2.duty_type='2' then t.loan_amt else null end as duty_amt, -- 还款责任金额(担保金额)
		-- case when t2.duty_type='2' then coalesce(t10.contract_id,t11.contract_id,t8.count_cont_code,t5.contract_id,t4.contract_id)
		-- 	 else null
		-- 	 end as guar_cont_no, -- 反担保合同
		case when t2.duty_type='2' then coalesce(t8.count_cont_code,t5.contract_id,t4.contract_id)
			 else null
			 end as guar_cont_no, -- 反担保合同
		t7.ct_guar_person_id_no, -- 企业统一社会编码
		t9.aggregate_scheme
	from (
		select guar_id,cust_id,loan_amt from dw_base.exp_credit_comp_guar_info_ready
		where day_id = '${v_sdate}'
	) t
	inner join dw_tmp.tmp_exp_credit_comp_guar_info_xz_counter_main t1  -- 担保业务系统id 和项目编号转换
	on t.guar_id = t1.guar_id
	inner join dw_tmp.tmp_exp_credit_comp_guar_info_xz_counter_sq t2  -- 授权的反担保人信息
	on t1.project_id = t2.project_id
	left join dw_tmp.tmp_exp_credit_comp_guar_info_xz_counter_contract t4
	on t2.apply_code = t4.biz_id
	and t2.cust_code = t4.customer_id  -- 客户号
	-- and t4.AUTHORIZED_CUSTOMER_ID is null
	and t2.duty_type='2'
	left join dw_tmp.tmp_exp_credit_comp_guar_info_xz_counter_contract t5
	on t2.apply_code = t5.biz_id
	and t2.id_no = t5.customer_id  -- 证件号
	-- and t5.AUTHORIZED_CUSTOMER_ID is null
	and t2.duty_type='2'
	left join dw_nd.ods_imp_comp_zzm t6
	on t.guar_id = t6.guar_id
	and t6.cust_type = '02' -- 反担保人
	and t2.duty_type='2'
	left join (
		select project_id,ct_guar_person_name,zhongzheng_code,ct_guar_person_id_no
		from (
			select id,project_id,ct_guar_person_name,zhongzheng_code,ct_guar_person_id_no,row_number() over (partition by id order by db_update_time desc,update_time desc) as rn
			from dw_nd.ods_t_ct_guar_person
						where data_type = '7' -- 出具批复最终定的担保人
		)t
		where rn = 1
	)t7
	on t1.project_Id = t7.project_Id
		and t2.counter_name = t7.ct_guar_person_name
		and t2.duty_type='2'
	left join dw_tmp.tmp_exp_credit_comp_guar_info_xz_counter_contract_xx t8
	on t1.project_Id = t8.project_Id
	and t2.id_no = t8.ct_guar_person_id_no
	and t8.count_cont_code is not null
	and t2.duty_type='2'
	left join dw_tmp.tmp_exp_credit_comp_guar_info_check t9
	on t1.project_id = t9.project_id
	-- left join dw_tmp.tmp_exp_credit_comp_guar_info_xz_counter_contract t10
	-- on t2.apply_code = t10.biz_id
	-- and t2.id_no = t10.AUTHORIZED_CUSTOMER_ID  -- 证件号
	-- and t2.duty_type='2'
	-- left join dw_tmp.tmp_exp_credit_comp_guar_info_xz_counter_contract t11
	-- on t2.apply_code = t11.biz_id
	-- and t2.cust_code = t11.AUTHORIZED_CUSTOMER_ID  -- 证件号
	-- and t2.duty_type='2'
)t
left join dw_tmp.tmp_exp_credit_comp_guar_info_risk_comp t1  -- 20231023优化，核心企业的集群方案与担保业务一致时，作为反担保人时，责任金额用合同金额*分险比例，反担保合同用协议合同+业务编号
on t.ct_guar_person_id_no = t1.unified_social_credit_code
and t.aggregate_scheme = t1.dictionaries_code
left join dw_tmp.tmp_exp_credit_comp_guar_info_risk_natural t2
on t.duty_cert_no = t2.person_identity
and t.aggregate_scheme = t2.dictionaries_code
where t.duty_cert_no is not null
)t
where t.guar_cont_no is not null  -- 反担保合同编号不为空

;
commit;



-- 主要组成人员表（因客户基本信息中必须上报主要组成人员段，且客户担保信息里的客户都必须在客户基本信息中存在，且客户担保信息脚本跑完以后再跑基本信息脚本，所以这一块放在客户担保信息脚本）
drop table if exists dw_tmp.tmp_exp_credit_comp_sen_info;commit;
CREATE TABLE dw_tmp.tmp_exp_credit_comp_sen_info (
  `cust_id` varchar(60) COLLATE utf8mb4_bin DEFAULT NULL,
  `MMB_ALIAS` varchar(30) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '组成人员姓名',
  `MMB_ID_TYPE` varchar(2) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '组成人员证件类型',
  `MMB_ID_NUM` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '组成人员证件号码',
  `MMB_PSTN` varchar(1) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '组成人员职位',
  KEY `inx_cust_id` (`cust_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC COMMENT='企业主要组成人员表';
commit;

insert into dw_tmp.tmp_exp_credit_comp_sen_info
select
	t1.customer_id
	,t1.legal_name
	,t1.mmb_id_type
	,t1.mmb_id_num
	,t1.mmb_pstn
from(
	select
		customer_id,
		legal_name,
		mmb_id_type,
		mmb_id_num,
		mmb_pstn
	from(
		select
			customer_id -- 客户号
			,legal_name  -- 组成人员姓名（法人）
			,'10' mmb_id_type -- 组成人员证件类型
			,legal_id_no as mmb_id_num -- 组成人员证件号码 -居民身份证及其他以公民身份证号为标识的证件
			,'1' mmb_pstn -- 组成人员职位  -- 1-法定代表人/非法人组织负责人
			,row_number() over (partition by CUSTOMER_ID order by UPDATE_TIME desc) as rn
		from dw_nd.ods_wxapp_cust_login_info  -- 登录账号信息表
		where legal_id_no is not null  -- 法人证件号不为空
	) t
	where rn = 1
) t1
;
commit ;



-- 按段更正类 b-基础段 c-基本信息段 d-在保责任信息段 e-相关还款责任人段 f-抵质押物信息段 g-授信额度信息段

drop table if exists dw_base.exp_credit_comp_guar_info_sep_cust ;

commit;

create  table dw_base.exp_credit_comp_guar_info_sep_cust (
	`guar_id` varchar(60) COLLATE utf8mb4_bin DEFAULT NULL,
	`day_id` varchar(60) COLLATE utf8mb4_bin DEFAULT NULL,
  KEY `guar_id` (`guar_id`)
) engine=innodb  default charset=utf8mb4 collate=utf8mb4_bin row_format=dynamic ;

commit;

insert into dw_base.exp_credit_comp_guar_info_sep_cust
select
	guar_id
	,day_id
from dw_base.exp_credit_comp_guar_info_open t1
where t1.day_id < '${v_sdate}'
and not exists
		(
		select 1 from dw_base.exp_credit_comp_guar_info_close t2
		where t2.day_id <= '${v_sdate}'
		and t1.guar_id = t2.guar_id
		)
;

commit ;
--
-- -- 2.获取变更数据
--
-- -- create table dw_base.exp_credit_comp_guar_info_change_b (
-- --    `day_id` varchar(8) default null,
-- --    `guar_id` varchar(60) default null,
-- --    `cust_id` varchar(60) default null,
-- --    `inf_rec_type` varchar(3) not null   comment '信息记录类型 ',
-- --    `acct_code` varchar(60) default null comment '账户标识码',
-- --    `name` varchar(80) default null comment '债务人名称',
-- --    `id_type` varchar(3) default null comment '债务人身份标识类型',
-- --    `id_num` varchar(40) default null comment '债务人身份标识号码',
-- --    `mngmt_org_code` varchar(14) default null comment '业务管理机构代码',
-- --     field_type varchar(10)  comment '修改类型add：新增,mdy：修改',
-- --     key (guar_id) ,
-- --     key (day_id)
-- --  ) engine=innodb default charset=utf8mb4 comment='企业担保-基础段按段更正'
-- -- ;
--

-- b-基础段 更正基础段时，更正请求记录的信息报告日期应等于相应信息段最晚的信息报告日期
delete from dw_base.exp_credit_comp_guar_info_change_b where day_id = '${v_sdate}' ;
commit;

insert into dw_base.exp_credit_comp_guar_info_change_b
select
	'${v_sdate}'
	,t1.guar_id
	,t2.cust_id
	,t2.acct_code
	,t2.name
	,t2.id_type
	,t2.id_num
	,t2.mngmt_org_code  -- 业务管理机构代码
	,'mdy'
	-- ,t3.name
	-- ,t3.id_num
	-- ,t4.guar_id,t4.name,t4.id_num
from dw_base.exp_credit_comp_guar_info_sep_cust t1  -- 开户未关户
inner join dw_base.exp_credit_comp_guar_info_ready t2 -- 拿最新的中征码信息
on t1.guar_id = t2.guar_id
and t2.day_id = '${v_sdate}'
inner join (
	select t1.* from dw_base.exp_credit_comp_guar_info t1
	inner join (
			select guar_id,max(day_Id)day_Id from dw_base.exp_credit_comp_guar_info group by guar_Id
	)t2
	on t1.guar_id = t2.guar_id
	and t1.day_id = t2.day_id
)t3
on t1.guar_id = t3.guar_id
-- 如果和最近一次修正过的信息完全一致，则不重复生成变更
left join (
	select t1.* from dw_base.exp_credit_comp_guar_info_change_b t1
	inner join (
		select guar_id,max(day_Id)day_Id from dw_base.exp_credit_comp_guar_info_change_b group by guar_Id
		)t2
	on t1.guar_id = t2.guar_id
	and t1.day_id = t2.day_id
)t4
on t2.guar_id = t4.guar_id
and t2.name = t4.name
and t2.id_num = t4.id_num
where t2.name = t3.name
and t2.id_num <> t3.id_num  -- 历史有报送，且比较最近一次报送中征码有修改
-- and t1.guar_id in (
-- '202310270014',
-- '202310270016',
-- '202310300022',
-- '202407290019'
-- )
and t4.guar_id is null
;
commit;

-- -- c-基本信息段 d-在保责任信息段 e-相关还款责任人段 f-抵质押物信息段 g-授信额度信息段
-- -- c-基本信息段 50其他信息段中已经包括，需要排除
-- delete from dw_base.exp_credit_comp_guar_info_change_c where day_id = '${v_sdate}' ;
-- commit;
-- insert into dw_base.exp_credit_comp_guar_info_change_c
-- select
-- 	'${v_sdate}'
-- 	,t2.guar_id
-- 	,t2.cust_id
-- 	,t2.acct_code
-- 	,t2.busi_lines -- 担保业务大类
-- 	,t2.busi_dtil_lines -- 担保业务种类细分
-- 	,t2.open_date -- 开户日期
-- 	,t2.guar_amt -- 担保金额
-- 	,t2.cy -- 币种
-- 	,t2.due_date -- 到期日期
-- 	,t2.guar_mode -- 反担保方式
-- 	,t2.oth_repy_guar_way -- 其他还款保证方式
-- 	,t2.sec_dep -- 保证金比例
-- 	,t2.ctrct_txt_code -- 担保合同文本编号
-- 	,'mdy'
-- from dw_base.exp_credit_comp_guar_info_sep_cust t1
-- inner join dw_base.exp_credit_comp_guar_info_ready t2
-- on t1.guar_id = t2.guar_id
-- 	and t2.day_id = '${v_sdate}'
-- inner join dw_base.exp_credit_comp_guar_info_ready t3
-- on t1.guar_id = t3.guar_id
-- 	and t3.day_id = '${v_yesterday}'
-- where (t2.open_date <> t3.open_date  -- 开户日期
-- 	-- or t2.guar_amt <> t3.guar_amt  跟在保余额取数一致，在保余额变动时报送
-- 	-- or t2.due_date <> t3.due_date
-- 		or t2.guar_mode <>  t3.guar_mode  -- 反担保方式
-- 		)
-- and not exists
-- 		(
-- 		select 1 from dw_base.exp_credit_comp_guar_info t4  -- 不能通过 10 20 30 40 50 上报
-- 		where t4.day_id = '${v_sdate}'
-- 		and t1.guar_id = t4.guar_id
-- 		)
-- 		;
-- commit ;
--
-- -- d-在保责任信息段  需要排除 40 五级分类调整 30 在保责任变化
--
-- delete from dw_base.exp_credit_comp_guar_info_change_d where day_id = '${v_sdate}' ;
-- commit;
-- insert into dw_base.exp_credit_comp_guar_info_change_d
-- select
-- 	'${v_sdate}'
-- 	,t2.guar_id
-- 	,t2.cust_id
-- 	,t2.acct_code
-- 	,t2.acct_status -- 账户状态
-- 	,t2.loan_amt -- 在保余额
-- 	,t2.repay_prd -- 余额变化日期
-- 	,t2.five_cate -- 五级分类
-- 	,t2.five_cate_adj_date -- 五级分类认定日期
-- 	,t2.ri_ex -- 风险敞口
-- 	,t2.comp_adv_flag -- 代偿(垫款)标志
-- 	,t2.close_date -- 账户关闭日期
-- 	,'mdy'
-- from dw_base.exp_credit_comp_guar_info_sep_cust t1
-- inner join dw_base.exp_credit_comp_guar_info_ready t2
-- on t1.guar_id = t2.guar_id
-- 	and t2.day_id = '${v_sdate}'
-- inner join dw_base.exp_credit_comp_guar_info_ready t3
-- on t1.guar_id = t3.guar_id
-- 	and t3.day_id = '${v_yesterday}'
-- where
-- -- t2.acct_status <> t3.acct_status
-- -- or t2.loan_amt <> t3.loan_amt
-- -- or t2.repay_prd <> t3.repay_prd
-- -- or t2.five_cate <>  t3.five_cate
-- -- or t2.five_cate_adj_date <>  t3.five_cate_adj_date
-- -- or t2.comp_adv_flag <>  t3.comp_adv_flag
-- -- or t2.close_date <>  t3.close_date
-- 	t2.ri_ex <> t3.ri_ex
-- and not exists
-- 		(
-- 		select 1 from dw_base.exp_credit_comp_guar_info t4  -- 不能通过 10 20 30 40 50 上报
-- 		where t4.day_id = '${v_sdate}'
-- 		and t1.guar_id = t4.guar_id
-- 		)
-- ;
-- commit;



-- 按段更正 E--还款责任人段(有新增反担保人 或 反担保人中征码发生变化）
DELETE FROM dw_base.exp_credit_comp_guar_info_change_e where day_id = '${v_sdate}' ;
commit;
insert into dw_base.exp_credit_comp_guar_info_change_e


-- 拿最新的相关还款责任人信息（且未关户）

select distinct
'${v_sdate}'
,t1.`guar_id`
,t3.`cust_id` -- '客户号'
,t3.info_id_type -- '身份类别'
,t3.duty_name-- '责任人名称'
,t3.duty_cert_type -- '责任人身份标识类型'
,t3.`duty_cert_no`-- '责任人身份标识号码'
,t3.duty_type-- '还款责任人类型：1-共同债务人2-反担保人9-其他'
,t3.duty_amt -- '还款责任金额'
,t3.guar_cont_no -- '保证合同编号'
,'mdy'
-- ,t2.guar_id
from dw_base.exp_credit_comp_guar_info_sep_cust t1 -- 今天上报前已开户，但是未关闭。
inner join dw_base.exp_credit_comp_repay_duty_info t3
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
	from dw_base.exp_credit_comp_guar_info_sep_cust t1 -- 今天上报前已开户，但是未关闭。
	inner join dw_base.exp_credit_comp_repay_duty_info t3 -- 拿当天最新的相关还款人信息
	on t1.guar_id = t3.guar_id
	and t3.day_id = '${v_sdate}'
	left join (
		select t1.* from dw_pbc.t_en_rlt_repymt_inf_sgmt_el t1
		inner join (
			select guar_id,max(day_id)day_id from dw_pbc.t_en_rlt_repymt_inf_sgmt_el
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

-- dw_pbc.exp_credit_comp_guar_info_change_c 和 exp_credit_comp_guar_info_change_d 表在切到星环之前就被注释掉了

-- delete from  dw_pbc.exp_credit_comp_guar_info_change_c where day_id = '${v_sdate}' ;
-- commit ;
-- insert into dw_pbc.exp_credit_comp_guar_info_change_c
-- select
-- 	day_id,
-- 	guar_id,
-- 	cust_id,
-- 	acct_code,
-- 	busi_lines,
-- 	busi_dtil_lines,
-- 	open_date,
-- 	guar_amt,
-- 	cy,
-- 	due_date,
-- 	guar_mode,
-- 	oth_repy_guar_way,
-- 	sec_dep,
-- 	ctrct_txt_code,
-- 	field_type
-- from dw_base.exp_credit_comp_guar_info_change_c
-- where day_id = '${v_sdate}' ;
-- commit;
--
-- delete from  dw_pbc.exp_credit_comp_guar_info_change_d where day_id = '${v_sdate}' ;
-- commit ;
-- insert into dw_pbc.exp_credit_comp_guar_info_change_d
-- select
-- 	day_id,
-- 	guar_id,
-- 	cust_id,
-- 	acct_code,
-- 	acct_status,
-- 	loan_amt,
-- 	repay_prd,
-- 	five_cate,
-- 	five_cate_adj_date,
-- 	ri_ex,
-- 	comp_adv_flag,
-- 	close_date,
-- 	field_type
-- from dw_base.exp_credit_comp_guar_info_change_d
-- where day_id = '${v_sdate}' ;
-- commit;


-- 考虑到推送任务已切换到星环，未避免mysql和星环同步运行期间产生 同时推送，现注释改脚本推送内容 20241012

-- 同步集市

delete from  dw_pbc.exp_credit_comp_guar_info where day_id = '${v_sdate}' ;
commit ;

insert into dw_pbc.exp_credit_comp_guar_info
select t.day_id,
	   t.guar_id,
	   t.cust_id,
	   t.acct_type,
	   t.acct_code,
	   t.rpt_date,
	   t.rpt_date_code,
	   t.name,
	   t.id_type,
	   t.id_num,
	   t.mngmt_org_code,
	   t.busi_lines,
	   t.busi_dtil_lines,
	   t.open_date,
	   t.guar_amt,
	   t.cy,
	   t.due_date,
	   t.guar_mode,
	   t.oth_repy_guar_way,
	   t.sec_dep,
	   t.ctrct_txt_code,
	   t.acct_status,
	   t.loan_amt,
	   t.repay_prd,
	   t.five_cate,
	   t.five_cate_adj_date,
	   t.ri_ex,
	   t.comp_adv_flag,
	   t.close_date,
	   t.data_source
from dw_base.exp_credit_comp_guar_info t
inner join dw_tmp.tmp_exp_credit_comp_sen_info t1
on t.cust_id = t1.cust_id  -- 有主要组成人员信息的才上报
where day_id = '${v_sdate}'
;
commit ;


-- -- 还款责任人信息 推送集市
delete from dw_pbc.exp_credit_comp_repay_duty_info  where day_id = '${v_sdate}' ;
commit ;
insert into dw_pbc.exp_credit_comp_repay_duty_info
select
	day_id
	,guar_id
	,cust_id
	,info_id_type         -- 身份类别
	,duty_name            -- 责任人名称
	,duty_cert_type       -- 责任人身份标识类型
	,duty_cert_no         -- 责任人身份标识号码
	,duty_type            -- 还款责任人类型
	,duty_amt             -- 还款责任金额
	,guar_cont_no         -- 保证合同编号
from dw_base.exp_credit_comp_repay_duty_info
where day_id = '${v_sdate}'
;
commit ;


delete from  dw_pbc.exp_credit_comp_guar_info_change_b where day_id = '${v_sdate}' ;
commit ;
insert into dw_pbc.exp_credit_comp_guar_info_change_b
select *
from dw_base.exp_credit_comp_guar_info_change_b
where day_id = '${v_sdate}' ;
commit ;

delete from  dw_pbc.exp_credit_comp_guar_info_change_e where day_id = '${v_sdate}' ;
commit ;
insert into dw_pbc.exp_credit_comp_guar_info_change_e
select *
from dw_base.exp_credit_comp_guar_info_change_e
where day_id = '${v_sdate}' ;
commit;

-- delete
-- from dw_pbc.exp_credit_comp_guar_info
-- where day_id = '${v_sdate}'
--   and guar_id in ('TJRD-2021-5Z85-959X', 'TJRD-2021-5S93-979U');
-- commit;
