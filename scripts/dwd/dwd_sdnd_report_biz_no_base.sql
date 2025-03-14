-- ----------------------------------------
-- 开发人   : WangYX
-- 开发时间 ：20240831
-- 目标表   ：dwd_sdnd_report_biz_no_base   国担上报范围表
-- 源表     ：dw_nd.ods_t_biz_project_main  主项目表（进件表）
--           dw_nd.ods_t_biz_proj_xz       续支项目表
--           dw_nd.ods_t_biz_proj_loan_check 贷后检查表（自主续支项目）
--           dw_nd.ods_bizhall_guar_apply  业务大厅申请表
--           dwd_guar_info_all             业务信息宽表--项目域
--           dwd_guar_info_all_his         历史宽表
--            
-- 备注     ：
-- 变更记录 ：20241201 脚本的统一变更，TDS转MySQL8.0 zhangfl
-- ----------------------------------------
-- 创建临时表，存业务编号，业务id，原业务编号，原业务id
drop table if exists dw_tmp.tmp_dwd_sdnd_report_biz_no_base_id;
create table if not exists dw_tmp.tmp_dwd_sdnd_report_biz_no_base_id(
 biz_no            varchar(50) comment '项目编号'
,biz_id            varchar(50) comment '项目id'
,proj_no           varchar(50) comment '原项目编号'
,proj_id           varchar(50) comment '原项目id'
,guar_type         varchar(10) comment '贷款方式'
,index ind_tmp_dwd_sdnd_report_bizno_base(biz_no)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin comment= '创建临时表，存业务编号，业务id，原业务编号，原业务id';

insert into dw_tmp.tmp_dwd_sdnd_report_biz_no_base_id
(
 biz_no
,biz_id
,proj_no
,proj_id
,guar_type
)
-- 1.进件项目
select	t1.code       as biz_no
		,t1.id        as biz_id
		,t1.code      as proj_no
		,t1.id        as proj_id
		,t1.loan_type as guar_type
from
(
	select t1.id, t1.code,t1.loan_type, row_number()over(partition by t1.id order by t1.db_update_time desc, t1.update_time desc) rn
	from dw_nd.ods_t_biz_project_main t1      -- 主项目表（进件表）
) t1
where t1.rn = 1

-- 2.续支项目
union all
select	t1.code       as biz_no
		,t1.id        as biz_id
		,t2.proj_no
		,t2.proj_id
		,t2.loan_type as guar_type
from
(
	select t1.id, t1.code, t1.project_id, row_number()over(partition by t1.id order by t1.db_update_time desc, t1.update_time desc) rn
	from dw_nd.ods_t_biz_proj_xz t1           -- 续支项目表
) t1
inner join
(
	select	t1.code as proj_no
			,t1.id  as proj_id
			,t1.loan_type
	from
	(
		select t1.id, t1.code, t1.loan_type, row_number()over(partition by t1.id order by t1.db_update_time desc, t1.update_time desc) rn
		from dw_nd.ods_t_biz_project_main t1  -- 主项目表（进件表）
	) t1
	where t1.rn = 1
) t2
on t1.project_id = t2.proj_id
where t1.rn = 1

-- 3.自主循环贷项目
union all
select	t1.code       as biz_no
		,t1.id        as biz_id
		,t2.proj_no
		,t2.proj_id
		,t2.loan_type as guar_type
from
(
	select t1.id, t1.code, t1.project_id,t1.type, row_number()over(partition by t1.id order by t1.db_update_time desc, t1.update_time desc) rn
	from dw_nd.ods_t_biz_proj_loan_check t1   -- 贷后检查表（自主续支项目）
) t1
inner join
(
	select	t1.code as proj_no
			,t1.id  as proj_id
			,t1.loan_type
	from
	(
		select t1.id, t1.code, t1.loan_type, row_number()over(partition by t1.id order by t1.db_update_time desc, t1.update_time desc) rn
		from dw_nd.ods_t_biz_project_main t1  -- 主项目表（进件表）
	) t1
	where t1.rn = 1
) t2
on t1.project_id = t2.proj_id
where t1.rn = 1
and t1.type = '02' -- 自主循环贷的数据

-- 4.线上产品数据
union all
select	t1.apply_code  as biz_no
		,t1.id         as biz_id
		,t1.apply_code as proj_no
		,t1.id         as proj_id
		,'0'           as guar_type
from
(
	select t1.id, t1.apply_code, row_number()over(partition by t1.id order by t1.update_time desc) rn
	from dw_nd.ods_bizhall_guar_apply t1   -- 业务大厅申请表
) t1
where t1.rn = 1
;
commit;


-- 日增量加载
delete from dw_base.dwd_sdnd_report_biz_no_base where day_id = '${v_sdate}' ;
commit;

insert into dw_base.dwd_sdnd_report_biz_no_base
(
 day_id
,biz_no
,biz_id
,proj_no
,proj_id
,source
)
select distinct '${v_sdate}' as day_id
	,t1.biz_no    -- 业务编号
	,t1.biz_id    -- 业务id
	,t1.proj_no   -- 项目编号
	,t1.proj_id   -- 项目id
	,t1.source    -- 数据来源
from(
	select distinct /*关联历史数据，取出当前业务状态为已放款、已解保的，但去年底业务状态非已放款、已解保的数据，为当年1月1日以来纳入在保数据*/
		t1.guar_id as biz_no
		,t2.biz_id
		,t2.proj_no
		,t2.proj_id
		,'当年1月1日以来纳入在保' as source
		,t1.loan_notify_no
		,t2.guar_type
	from dw_base.dwd_guar_info_all t1 -- 业务信息宽表--项目域
	left join dw_tmp.tmp_dwd_sdnd_report_biz_no_base_id t2
	on t1.guar_id = t2.biz_no
	where t1.item_stt in ('已放款','已解保')
	and t1.guar_id not in
		(
			select t1.guar_id
			from dw_base.dwd_guar_info_all t1
			inner join dw_base.dwd_guar_info_all_his t2 -- 老系统历史宽表
			on t1.guar_id = t2.guar_id
			where t2.item_stt in ('已放款','已解保')
			and t2.day_id = concat(year('${v_sdate}')-1,'1231')
		)
	union all 
	select distinct /*已代偿业务*/
		t1.guar_id as biz_no
		,t2.biz_id
		,t2.proj_no
		,t2.proj_id
		,'已代偿' as source
		,t1.loan_notify_no
		,t2.guar_type
	from dw_base.dwd_guar_info_all t1
	left join dw_tmp.tmp_dwd_sdnd_report_biz_no_base_id t2
	on t1.guar_id = t2.biz_no
	where t1.item_stt = '已代偿'
	and t1.guar_id not in
	(
		select	t1.guar_id
		from dw_base.dwd_guar_info_all t1
		inner join dw_base.dwd_guar_info_all_his t2
		on t1.guar_id = t2.guar_id
		where t2.item_stt = '已放款'
		and t2.day_id = concat(year('${v_sdate}')-1,'1231')
	)
	union all
	select distinct /*关联历史数据，取出当前业务状态为累保，去年低业务状态为在保的数据，为当年1月1日处于在保状态数据*/
	    t1.guar_id as biz_no
	    ,t3.biz_id
	    ,t3.proj_no
	    ,t3.proj_id
	    ,'当年1月1日处于在保状态' as source
		,t1.loan_notify_no
		,t3.guar_type
	from dw_base.dwd_guar_info_all t1
	inner join dw_base.dwd_guar_info_all_his t2
	on t1.guar_id = t2.guar_id
	left join dw_tmp.tmp_dwd_sdnd_report_biz_no_base_id t3
	on t1.guar_id = t3.biz_no
	where t2.item_stt = '已放款'
	and t1.item_stt in ('已放款','已解保','已代偿')
	and t2.day_id = concat(year('${v_sdate}')-1,'1231')

) t1

where /*剔除不符合上报校验规则的数据*/
1 = 1
and regexp_replace(trim(t1.loan_notify_no),'\\(|\\（|\\)|\\）','') is not null -- 放款通知书编号为空
and (t1.guar_type <> '3' or t1.guar_type is null) -- 非 3-商业票据的、 非空的
-- 不符合统一社会信用代码校验规则
-- 不符合证件号码规则校验/客户主体类型与证件号不一致
-- 手机号不符合规则校验
-- 项目来源代码为空/保证方式代码为空
-- 计入在保日期/不符合放款到期日大于放款日期校验
-- 借款合同号为空
-- 担保费率为空
-- 保证合同保证期间代码为空/保证责任生效日期不合规/不符合放款登记日期小于等于当前日期
-- 不符合校验规则：放款登记日期应大于等于借款合同生效日期
-- 企业对应法人信息为空
-- 首次代偿通知日期不合规
-- 不合规：逾期本金金额小于等于该项目放款金额总和
-- 剔除23笔业务，线上业务已解保，无放款信息
-- 剔除两笔业务，放款登记日期早于合同生效日期
-- 保后检查执行日期小于放款登记日期
-- 保后检查登记日期大于当前日期
-- 项目状态改变，关联不到bank取值
-- 没有保证责任失效日期
-- 该业务被终止
-- 政策性业务在保额超过300，剔除早期未解保业务
-- 政策性业务在保额超过300,在保业务
-- 证件号姓名不同，对比历史报送，剔除与历史20240828不同的
-- 借款合同编号与历史金额不同
-- 金融机构匹配不到国农担
-- 同一合同号对应多个证件好号，只取一笔，其余剔除
-- 剔除91笔业务，代偿记录表存在数据，逾期记录表没有
;
commit;