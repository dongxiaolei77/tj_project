-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250212
-- 目标表   ：dw_base.ads_rpt_tjnd_risk_compt_ovd_proj_stat 风险部-省级农担公司逾期及代偿项目情况统计表
-- 源表     ：dw_nd.ods_tjnd_yw_business_book_new 每月业务台账
--          dw_nd.ods_tjnd_yw_bh_compensatory 代偿表
--          dw_nd.ods_tjnd_yw_bh_recovery_tracking 追偿跟踪表
--          dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail 追偿跟踪详情表
--          dw_nd.ods_tjnd_yw_afg_business_infomation 业务申请表
--          dw_nd.ods_tjnd_yw_bh_overdue_plan 逾期登记表
--          dw_nd.ods_tjnd_yw_base_cooperative_institution_agreement BO,机构合作协议,NEW
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 建个码值临时表
drop table if exists dw_nd.tmp_ads_rpt_tjnd_risk_compt_ovd_proj_stat_code_value;
commit;

create table dw_nd.tmp_ads_rpt_tjnd_risk_compt_ovd_proj_stat_code_value
(
    code    varchar(40) comment '码值',
    value    varchar(64) comment '字典值',
    key tmp_ads_rpt_tjnd_risk_compt_ovd_proj_stat_code_value (code) comment '业务编号索引'
) engine = InnoDB
  default charset = utf8mb4
  collate = utf8mb4_bin;
commit;

insert into dw_nd.tmp_ads_rpt_tjnd_risk_compt_ovd_proj_stat_code_value (code,value) values
('000000'	,'不存在客观风险'                                                   ),
('010101'	,'自然风险-气象灾害-热带风暴'                                       ),
('010102'	,'自然风险-气象灾害-龙卷风'                                         ),
('010103'	,'自然风险-气象灾害-雷暴大风'                                       ),
('010104'	,'自然风险-气象灾害-干热风'                                         ),
('010105'	,'自然风险-气象灾害-干风'                                           ),
('010106'	,'自然风险-气象灾害-黑风'                                           ),
('010107'	,'自然风险-气象灾害-暴风雪'                                         ),
('010108'	,'自然风险-气象灾害-暴雨'                                           ),
('010109'	,'自然风险-气象灾害-寒潮'                                           ),
('010110'	,'自然风险-气象灾害-霜冻'                                           ),
('010111'	,'自然风险-气象灾害-水旱灾'                                         ),
('010112'	,'自然风险-气象灾害-其他'                                           ),
('010200'	,'自然风险-地震灾害'                                                ),
('010301'	,'自然风险-地质灾害-崩塌'                                           ),
('010302'	,'自然风险-地质灾害-滑坡'                                           ),
('010303'	,'自然风险-地质灾害-泥石流'                                         ),
('010304'	,'自然风险-地质灾害-塌陷'                                           ),
('010305'	,'自然风险-地质灾害-火山'                                           ),
('010306'	,'自然风险-地质灾害-冻融'                                           ),
('010307'	,'自然风险-地质灾害-地面沉降'                                       ),
('010308'	,'自然风险-地质灾害-土地沙漠化'                                     ),
('010309'	,'自然风险-地质灾害-水土流失'                                       ),
('010310'	,'自然风险-地质灾害-土地盐碱化'                                     ),
('010311'	,'自然风险-地质灾害-其他'                                           ),
('010401'	,'自然风险-海洋灾害-风暴潮'                                         ),
('010402'	,'自然风险-海洋灾害-海啸'                                           ),
('010403'	,'自然风险-海洋灾害-潮灾'                                           ),
('010404'	,'自然风险-海洋灾害-海浪'                                           ),
('010405'	,'自然风险-海洋灾害-赤潮'                                           ),
('010406'	,'自然风险-海洋灾害-海冰'                                           ),
('010407'	,'自然风险-海洋灾害-海水侵入'                                       ),
('010408'	,'自然风险-海洋灾害-海平面上升'                                     ),
('010409'	,'自然风险-海洋灾害-海水回灌'                                       ),
('010410'	,'自然风险-海洋灾害-其他'                                           ),
('010501'	,'自然风险-生物灾害-病害'                                           ),
('010502'	,'自然风险-生物灾害-虫害'                                           ),
('010503'	,'自然风险-生物灾害-草害'                                           ),
('010504'	,'自然风险-生物灾害-鼠害'                                           ),
('010505'	,'自然风险-生物灾害-其他'                                           ),
('010600'	,'自然风险-森林草原火灾'                                            ),
('010700'	,'自然风险-其他自然灾害'                                            ),
('010801'	,'自然风险-传染病疫情-甲类'                                         ),
('010802'	,'自然风险-传染病疫情-乙类'                                         ),
('010803'	,'自然风险-传染病疫情-丙类'                                         ),
('010900'	,'自然风险-群体性不明原因疾病'                                      ),
('011000'	,'自然风险-动物疫情'                                                ),
('011100'	,'自然风险-其他严重影响公众健康和生命安全的事件'                    ),
('020100'	,'担保客户生命健康风险-借款人或项目实际控制人死亡'                  ),
('020200'	,'担保客户生命健康风险-借款人或项目实际控制人突发重大疾病'          ),
('030100'	,'政策风险-征收、征用、封锁'                                        ),
('030201'	,'政策风险-其他重要政策变动-产业政策'                               ),
('030202'	,'政策风险-其他重要政策变动-金融政策'                               ),
('030203'	,'政策风险-其他重要政策变动-财政补贴政策'                           ),
('030204'	,'政策风险-其他重要政策变动-其他'                                   ),
('040100'	,'其他不可抗力-战争'                                                ),
('040200'	,'其他不可抗力-武装冲突'                                            ),
('040300'	,'其他不可抗力-罢工'                                                ),
('040400'	,'其他不可抗力-骚乱'                                                ),
('040500'	,'其他不可抗力-暴动'                                                ),
('060000'	,'市场价格波动'                                                     ),
('999999'	,'其他不能预见、不能避免并不能克服的客观情况'                       ),
('00'	,'不存在主观风险'        ),  
('01'	,'经营能力不足'          ),
('02'	,'贷款资金挪用'          ),
('03'	,'隐性负债'              ),
('04'	,'违法/违规/涉诉'        ),
('06'	,'逃废债/失联'           ),
('07'	,'不良嗜好'              ),
('08'	,'产品设计不合理'        ),
('09'	,'银行抽贷'              ),
('10'	,'信用意识不足'          ),
('99'	,'其他主观原因'          )
;
commit;

-- step0 重跑策略
delete
from dw_base.ads_rpt_tjnd_risk_compt_ovd_proj_stat
where day_id = '${v_sdate}';
commit;

-- step1 插入旧系统数据到 省级农担公司逾期及代偿项目情况统计表 中
insert into dw_base.ads_rpt_tjnd_risk_compt_ovd_proj_stat
(day_id, -- 数据日期
 guar_id, -- 业务id
 cust_name, -- 客户名称
 proj_status, -- 项目状态
 ind_name, -- 行业
 main_biz, -- 主营业务
 ln_inst, -- 贷款机构
 prod_name, -- 产品名称
 loan_amt, -- 放款金额（万元）
 ovd_amt, -- 逾期金额（含银行分险）（万元）
 ovd_ucompt_amt, -- 逾期未代偿金额（不含银行分险）（万元）
 bank_cont, -- 银行分险内容
 bank_ratio, -- 银行分险比例
 gover_cont, -- 政府分险内容
 gover_ratio, -- 政府分险比例
 other_cont, -- 地方担保公司等其他机构分险内容
 other_ratio, -- 地方担保公司等其他机构分险比例
 shod_compt_amt, -- 应代偿额（不含银行、政府等其他机构分险部分）（万元）
 compt_amt, -- 截至本季度末累计已代偿额（万元）
 issue_dt, -- 发放日
 exp_dt, -- 到期日
 ovd_dt, -- 逾期日期
 compt_day, -- 代偿宽限期（天）
 compt_dt, -- 代偿日
 claim_cause, -- 出险原因
 claim_cause_detail, -- 出险原因详述
 un_guar_per, -- 反担保措施-反担保人
 un_guar_obj, -- 反担保措施-反担保物
 un_guar_remark, -- 反担保措施备注
 recovery_mode, -- 追偿措施
 risk_amt, -- 截至本季度末累计代偿回收金额
 recovery_risk_amt, -- 1）向客户或反担保人追偿金额（含处置反担保物）
 gover_risk_amt, -- 2）政府分险金额
 other_inst_risk_amt, -- 3）地方担保、再担保、保险等其他机构分险金额
 other_risk_amt, -- 4）其他情况
 remark -- 备注
)
select '${v_sdate}'                                     as day_id,
       -- 业务id
       zt.guar_id                                       as guar_id,
       -- 客户名称
       zt.cust_name                                     as cust_name,
       -- 项目状态
       zt.proj_status                                   as proj_status,
       -- 行业
       ind.FIELDNAME                                    as ind_name,
       -- 主营业务
       zt.main_biz                                      as main_biz,
       -- 贷款机构
       ywsqb.full_bank_name                             as ln_inst,
       -- 产品名称
       pd.PRODUCT_NAME                                  as prod_name,
       -- 放款金额（万元）
       zt.loan_amt                                      as loan_amt,
       -- 逾期金额（含银行分险）（万元）
       zt.ovd_amt                                       as ovd_amt,
       -- 逾期未代偿金额（不含银行分险）（万元）
       case
           when zt.proj_status = '逾期' then round(zt.ovd_amt, 2)
           else 0 end                                   as ovd_ucompt_amt,
       -- 银行分险内容
       '本息'                                             as bank_cont,
       -- 银行分险比例
       xy.yhfzbl                                        as bank_ratio,
       -- 政府分险内容
       xy.zffxnr                                        as gover_cont,
       -- 政府分险比例
       xy.zffxbl                                        as gover_ratio,
       -- 地方担保公司等其他机构分险内容
       '无'                                              as other_cont,
       -- 地方担保公司等其他机构分险比例
       0                                                as other_ratio,
       -- 应代偿额（不含银行、政府等其他机构分险部分）（万元）
       coalesce(zt.shod_compt_amt,0)                                as shod_compt_amt,
       -- 截至本季度末累计已代偿额（万元）
       coalesce(zt.shod_compt_amt,0)                                as compt_amt,
       -- 发放日
       zt.guar_start_date                               as issue_dt,
       -- 到期日
       zt.guar_end_date                                 as exp_dt,
       -- 逾期日期
       date_format(zt.ovd_date,'%Y-%m-%d')              as ovd_dt,                               -- 逾期日期
       -- 代偿宽限期（天）
       xy.dckxt                                         as compt_day,
       -- 代偿日
       zt.compt_date                                    as compt_dt,
       -- 出险原因
       case when zt.subj_comp_rsn_cd = '不存在客观风险' then zt.obj_comp_rsn_cd else zt.subj_comp_rsn_cd end as claim_cause,        -- yq.value_desc     -- 出险原因 
       -- 出险原因详述
       yq.value_desc                                    as claim_cause_detail,                       -- 出险原因详述[与出险原因交换一下位置]
       -- 反担保措施-反担保人
       zt.un_guar_per                                   as un_guar_per,
       -- 反担保措施-反担保物
       zt.un_guar_obj                                   as un_guar_obj,
       -- 反担保措施备注
       concat_ws(',', (case
                           when zt.un_guar_per = '有' and zt.cert_type = 'b' then '企业连带'
                           when zt.un_guar_per = '有' and zt.cert_type = '0' then '个人连带' end),
                 if(zt.un_guar_obj = '有', '抵押物', null)) as un_guar_remark,
       -- 追偿措施
       '自主追偿'                                           as recovery_mode,
       -- 截至本季度末累计代偿回收金额
       coalesce(zt.risk_amt,0)                          as risk_amt,
       -- 1）向客户或反担保人追偿金额（含处置反担保物）
       round(ifnull(zc.zhje, 0) / 10000, 6)             as recovery_risk_amt,
       -- 2）政府分险金额
       0                                                as gover_risk_amt,
       -- 3）地方担保、再担保、保险等其他机构分险金额
       0                                                as other_inst_risk_amt,
       -- 4）其他情况
       0                                                as other_risk_amt,
       -- 备注
       null                                             as remark   
from (
         select bbn.guar_id,              -- 业务id
                bbn.related_agreement_id, -- 关联协议id
                bbn.cust_name,            -- 客户姓名
                bbn.cert_type,            -- 证件类型
				bbn.id_num,                -- 证件号
				bbn.nd_proj_manager_name,          -- 农担项目经理名称
				case when bbn.assigned_office = 'YW_NHDLBSC'                  then '宁河东丽办事处'    
				     when bbn.assigned_office = 'YW_JNBHXQBSC'                then '津南滨海新区办事处'
					 when bbn.assigned_office = 'YW_WQBCBSC'                  then '武清北辰办事处'    
					 when bbn.assigned_office = 'YW_XQJHBSC'                  then '西青静海办事处'    
					 when bbn.assigned_office = 'YW_JZBSC'                    then '蓟州办事处'        
					 when bbn.assigned_office = 'YW_BDBSC'                    then '宝坻办事处'        
                     end as 	 assigned_office,  -- 经办机构
				bbn.loan_contract_no,              -- 借款合同号
                bbn.indus_gnd,            -- 行业分类国农担标准
                bbn.main_biz,             -- 主营业务
                -- bbn.guarantee_amount 担保金额
                round(bbn.guarantee_amount / 10000, 2)                                       as loan_amt,
                bbn.create_year_month,    -- 更新年月
                -- dc.total_compensation 代偿总额
                round(dc.total_compensation, 6)                                      as shod_compt_amt,
                -- bbn.ovd_principal 逾期本金
                -- bbn.ovd_interest 逾期利息
                round((if(bbn.ovd_principal is null, 0, bbn.ovd_principal) +
                       if(bbn.ovd_interest is null, 0, bbn.ovd_interest)) / 10000, 6)        as ovd_amt,
                bbn.guar_start_date,      -- 贷款起始日期
                bbn.guar_end_date,        -- 贷款结束日期
                bbn.compt_date,           -- 代偿日期
                coalesce(bbn.ovd_date,dc.OVERDUE_TIME)             as ovd_date,             -- 逾期日期
                -- bbn.is_co_borrower 是否有共同还款人
                case when bbn.is_co_borrower is not null then '有' else '无' end               as un_guar_per,
                -- bbn.is_mortgage 是否有抵押
                -- bbn.is_pledge 是否有质押
                case when bbn.is_mortgage = '是' or bbn.is_pledge = '是' then '有' else '无' end as un_guar_obj,
                -- bbn.recovery_amount 追回金额
                round(bbn.recovery_amount / 10000, 6)                                        as risk_amt,
                bbn.is_compt,             -- 是否代偿
                bbn.is_ovd,               -- 是否逾期
                case
                    when bbn.is_compt is not null then '已代偿'
                    when bbn.is_ovd is not null then '逾期'
                    end                                                                      as proj_status
			  , case
                    when dc.overdue_reason = '1'  then '自然风险-其他自然灾害'       -- '010700'
                    when dc.overdue_reason = '2'  then '自然风险-其他自然灾害'       -- '010700'
                    when dc.overdue_reason = '3'  then '担保客户生命健康风险-借款人或项目实际控制人突发重大疾病'       -- '020200'
                    when dc.overdue_reason = '4'  then '不存在客观风险'       -- '000000'
                    when dc.overdue_reason = '5'  then '不存在客观风险'       -- '000000'
                    when dc.overdue_reason = '6'  then '不存在客观风险'       -- '000000'
                    when dc.overdue_reason = '7'  then '不存在客观风险'       -- '000000'
                    when dc.overdue_reason = '8'  then '不存在客观风险'       -- '000000'
                    when dc.overdue_reason = '9'  then '不存在客观风险'       -- '000000'
                    when dc.overdue_reason = '10' then '政策风险-其他重要政策变动-其他'       -- '030204'
                    when dc.overdue_reason = '11' then '不存在客观风险'       -- '000000'
                    when dc.overdue_reason = '12' then '不存在客观风险'       -- '000000'
                    when dc.overdue_reason = '13' then '其他不能预见、不能避免并不能克服的客观情况'       -- '999999'
                    when dc.overdue_reason = '14' then '自然风险-其他严重影响公众健康和生命安全的事件'       -- '011100'
                    else '不存在客观风险'                       -- '000000'
                                end                                                       as subj_comp_rsn_cd   -- 项目代偿客观原因
              , case
                    when dc.overdue_sub_reason = '1'  then '不存在主观风险'     -- '00'
                    when dc.overdue_sub_reason = '2'  then '不存在主观风险'     -- '00'
                    when dc.overdue_sub_reason = '3'  then '不存在主观风险'     -- '00'
                    when dc.overdue_sub_reason = '4'  then '经营能力不足'       -- '01'
                    when dc.overdue_sub_reason = '5'  then '经营能力不足'       -- '01'
                    when dc.overdue_sub_reason = '6'  then '贷款资金挪用'       -- '02'
                    when dc.overdue_sub_reason = '7'  then '逃废债/失联'        -- '06'
                    when dc.overdue_sub_reason = '8'  then '违法/违规/涉诉'     -- '04'
                    when dc.overdue_sub_reason = '9'  then '经营能力不足'       -- '01'
                    when dc.overdue_sub_reason = '10' then '不存在主观风险'     -- '00'
                    when dc.overdue_sub_reason = '11' then '违法/违规/涉诉'     -- '04'
                    when dc.overdue_sub_reason = '12' then '信用意识不足'       -- '10'
                    when dc.overdue_sub_reason = '13' then '其他主观原因'       -- '99'
                    when dc.overdue_sub_reason = '14' then '不存在主观风险'     -- '00'
                    else '不存在主观风险'                                       -- '00'
                                end                                                       as obj_comp_rsn_cd  -- 项目代偿主管原因
         from (select *,row_number() over(partition by guar_id order by create_year_month desc) as rn from dw_nd.ods_tjnd_yw_business_book_new) bbn -- 每月最新业务表
            --      left join dw_nd.ods_tjnd_yw_bh_compensatory dc -- 代偿表
			left join dw_nd.ods_creditmid_v2_z_migrate_bh_compensatory  dc -- 代偿表
         -- dc.id_cfbiz_underwriting 关联合同ID
         -- bbn.guar_id 业务id
         -- dc.status 状态
         -- dc.over_tag ??
		 
        on dc.id_cfbiz_underwriting = bbn.guar_id and dc.status = '1' and dc.over_tag = 'BJ'
         where bbn.rn = 1
		 
     ) zt
         left join
     (
         select t.id,                    -- 主键
                t.id_cfbiz_underwriting, -- 关联合同ID
                d.zhje
         from dw_nd.ods_tjnd_yw_bh_recovery_tracking t -- 追偿跟踪表
                  left join
              (
                  select -- cur_recovery（本次）追回金额
                         sum(cur_recovery * 10000) as zhje,
                         id_recovery_tracking -- 关联追偿跟踪ID
--                  from dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail -- 追偿跟踪详情表
				  FROM dw_nd.ods_creditmid_v2_z_migrate_bh_recovery_tracking_detail  -- 追偿跟踪详情表
                  where status = 1
                    and date_format(entry_data, '%Y%m') <= date_format('${v_sdate}', '%Y%m')
                  group by id_recovery_tracking
              ) d
                  -- t.id 主键
                  -- d.id_recovery_tracking 关联追偿跟踪ID
              on t.id = d.id_recovery_tracking
         where t.status = 1 -- 状态
           and t.id_cfbiz_underwriting in -- 关联合同ID
               (select guar_id -- 业务id
                from dw_nd.ods_tjnd_yw_business_book_new -- 每月最新业务表
                where create_year_month = date_format('${v_sdate}', '%Y%m')
                  -- 是否代偿
                  and is_compt = '是')
     ) zc on zt.guar_id = zc.id_cfbiz_underwriting
--         left join dw_nd.ods_tjnd_yw_afg_business_infomation ywsqb -- 业务申请表
           left join dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation ywsqb -- 业务申请表
                   on zt.guar_id = ywsqb.id
         left join (select id_cfbiz_underwriting,
                           if(overdue_reason is null, 13, overdue_reason)                                     as overdue_reason, -- 逾期主要原因 (码值)
                           t2.value_desc,                                                                                        -- 对应字典值
                           row_number() over (partition by ID_CFBIZ_UNDERWRITING order by CREATED_TIME desc ) as rn
                           -- 逾期登记表
--                    from dw_nd.ods_tjnd_yw_bh_overdue_plan t1
                      from dw_nd.ods_creditmid_v2_z_migrate_bh_overdue_plan t1
                             left join (select FIELDCODE as value_code, FIELDNAME as value_desc
                                        from dw_nd.ods_tjnd_yw_base_basicdataselect
                                        where classcode = 'Overdue_reason') t2
                                       on if(t1.overdue_reason is null, 13, t1.overdue_reason) COLLATE utf8mb4_0900_ai_ci = t2.value_code COLLATE utf8mb4_0900_ai_ci 
) yq on zt.guar_id = yq.id_cfbiz_underwriting and yq.rn = 1
         left join
     (
         select id,                                    -- 主键
                '本息'                    as yhfxnr,     -- 银行分险内容
                bank_org_rate           as yhfzbl,     -- 银行分险比例
                case
                    when gov_org_rate is not null then '本息'
                    else '无'
                    end                 as zffxnr,     -- 政府分险内容
                ifnull(gov_org_rate, 0) as zffxbl,     -- 政府分险比例
                '无'                     as dfdbjgfxnr, -- 地方担保机构分险内容
                '0'                     as dfdbjgfxbl, -- 地方担保机构分险比例
                '本息'                    as ndfxnr,     -- 农担分险内容
                risk_ratio              as ndfxbl,     -- 农担分险比例
                compensation_period     as dckxt       -- 代偿期限[天]
         from dw_nd.ods_tjnd_yw_base_cooperative_institution_agreement -- BO,机构合作协议,NEW
     ) xy on
         -- zt.related_agreement_id 关联协议id
         -- xy.id 主键
         zt.related_agreement_id = xy.id
         left join (select *
                    from dw_nd.ods_tjnd_yw_base_basicdataselect
                    where CLASSCODE = 'SSHY_ND'
                      and `STATUS` = 1) ind on zt.indus_gnd = ind.FIELDCODE
         left join dw_nd.ods_tjnd_yw_base_product_management pd on ywsqb.PRODUCT_GRADE = pd.fieldcode
		 left join (select * from dw_base.dwd_tjnd_report_proj_base_info where day_id = '${v_sdate}' )t 
		 on ywsqb.GUARANTEE_CODE= t.proj_no_prov
where zt.proj_status = '已代偿'
and coalesce(t.proj_stt_cd,'05') <> '04' -- 04正常解保            -- [有空值，将空值默认为05]
order by zt.proj_status, guar_start_date desc;
commit;

-- ----------------------------------------------
-- 新业务系统逻辑
insert into dw_base.ads_rpt_tjnd_risk_compt_ovd_proj_stat
(day_id, -- 数据日期
 guar_id, -- 业务id
 cust_name, -- 客户名称
 proj_status, -- 项目状态
 ind_name, -- 行业
 main_biz, -- 主营业务
 ln_inst, -- 贷款机构
 prod_name, -- 产品名称
 loan_amt, -- 放款金额（万元）
 ovd_amt, -- 逾期金额（含银行分险）（万元）
 ovd_ucompt_amt, -- 逾期未代偿金额（不含银行分险）（万元）
 bank_cont, -- 银行分险内容
 bank_ratio, -- 银行分险比例
 gover_cont, -- 政府分险内容
 gover_ratio, -- 政府分险比例
 other_cont, -- 地方担保公司等其他机构分险内容
 other_ratio, -- 地方担保公司等其他机构分险比例
 shod_compt_amt, -- 应代偿额（不含银行、政府等其他机构分险部分）（万元）
 compt_amt, -- 截至本季度末累计已代偿额（万元）
 issue_dt, -- 发放日
 exp_dt, -- 到期日
 ovd_dt, -- 逾期日期
 compt_day, -- 代偿宽限期（天）
 compt_dt, -- 代偿日
 claim_cause, -- 出险原因
 claim_cause_detail, -- 出险原因详述         详述这里有问题
 un_guar_per, -- 反担保措施-反担保人
 un_guar_obj, -- 反担保措施-反担保物
 un_guar_remark, -- 反担保措施备注
 recovery_mode, -- 追偿措施
 risk_amt, -- 截至本季度末累计代偿回收金额
 recovery_risk_amt, -- 1）向客户或反担保人追偿金额（含处置反担保物）
 gover_risk_amt, -- 2）政府分险金额
 other_inst_risk_amt, -- 3）地方担保、再担保、保险等其他机构分险金额
 other_risk_amt, -- 4）其他情况
 remark -- 备注
)
select '${v_sdate}'                                              as day_id,
       t1.guar_id,
       cust_name,
       proj_status,
       ind_name,
       main_biz,
       ln_inst,
--       prod_name,                                                                                 -- 产品名称
       t4.aggregate_scheme                                       as prod_name,                      -- 产品名称
       coalesce(loan_amt,0)                                      as loan_amt,                       -- 放款金额（万元）
       coalesce(t1.ovd_amt / 10000,0)                            as ovd_amt,                        -- 逾期金额（含银行分险）（万元）
       case
           when proj_status = '逾期' then round(t1.ovd_ucompt_amt / 10000, 2)
           else 0 end                                            as ovd_ucompt_amt,                 -- 逾期未代偿金额（不含银行分险）（万元）     [代偿为0]
       '本息'                                                    as bank_cont,                      -- 银行分险内容
       t1.bank_ratio,                                                                               -- 银行分险比例
       '本息'                                                    as gover_cont,                     -- 政府分险内容
       0                                                         as gover_ratio,
       coalesce(t6.other_cont,'无')                              as other_cont,
       coalesce(other_ratio,0)                                   as other_ratio,
       coalesce(shod_compt_amt / 10000,0)                        as shod_compt_amt,                 -- 应代偿额（不含银行、政府等其他机构分险部分）（万元）,
       coalesce(compt_amt,0)                                     as compt_amt,                      -- 截至本季度末累计已代偿额（万元）
       issue_dt,
       date_format(exp_dt,'%Y-%m-%d')                            as exp_dt,                         -- 到期日
       COALESCE(t1.ovd_dt,t5.ovd_dt)                             as ovd_dt,                         -- 逾期日期    [先取保后任务, 取不到再取代偿流程里的逾期日期]
       compt_day,
       coalesce(t1.compt_dt,t5.compt_dt) as compt_dt,     -- 代偿日   [与国农担上报代偿表采用相同逻辑]
       case when proj_status = '逾期' then t1.claim_cause  
	        else t5.claim_cause 
			end as claim_cause,                           -- 出险原因      主客观原因   【出险原因取主观原因】
       case when proj_status = '逾期' then t1.claim_cause_detail  
	        else t5.claim_cause_detail 
			end as claim_cause_detail,                    -- 出险原因详述               【出险原因详述先取客观, 客观原因是不存在再取主观原因】
       case when t7.project_id is not null then '有' else '无' end as un_guar_per,                  -- 反担保措施-反担保人
       case when t8.project_id is not null then '有' else '无' end as un_guar_obj,                  -- 反担保措施-反担保物
       if(t1.guar_id like 'TJ%'
	      ,concat_ws(',', (case
                               when t7.project_id is not null and t1.cust_type = '法人或其他组织' then '企业连带'
                               when t7.project_id is not null and t1.cust_type = '自然人' then '个人连带' end),
                     if(t8.project_id is not null, '抵押物', null))        
		  ,t9.un_guar_remark)                                    as un_guar_remark,                 -- 反担保措施备注
       '自主追偿'                                                as recovery_mode,                  -- 追偿措施
       coalesce(risk_amt,0) / 10000                              as risk_amt,                       -- 截至本季度末累计代偿回收金额
       0                                                         as recovery_risk_amt,
       0                                                         as gover_risk_amt,
       0                                                         as other_inst_risk_amt,
       0                                                         as other_risk_amt,
       null                                                      as remark
from (
         select a.guar_id       as guar_id,     -- 台账编号
                a.cust_name     as cust_name,   -- 客户名称
				a.cust_type,                    -- 客户类型
                case when f.proj_no_prov is not null and a.item_stt = '已放款' then '逾期' else  a.item_stt  end    as proj_status, -- 项目状态
                a.guar_class    as ind_name,    -- 国担行业分类
                a.loan_bank     as ln_inst,     -- 贷款银行
                a.guar_prod     as prod_name,   -- 产品名称
                a.guar_amt      as loan_amt,    -- 放款金额
                a.loan_begin_dt as issue_dt,    -- 贷款开始时间
                a.loan_end_dt   as exp_dt,      -- 贷款结束时间
				str_to_date(b.compt_dt,'%Y%m%d') as compt_dt,
				if(a.guar_id like 'TJ%', e.bank_org_rate, c.bank_risk / 100) as bank_ratio          -- 银行分险比例 [把国农担上报的逻辑拿过来了]
				,date_format(f.ovd_dt,'%Y-%m-%d') as ovd_dt
				,f.ovd_amt
				,f.ovd_ucompt_amt
				,f.obj_rk_rsn_cd as claim_cause
				,case when f.subj_rk_rsn_cd = '不存在客观风险' then f.obj_rk_rsn_cd else f.subj_rk_rsn_cd end as claim_cause_detail
				,a.cert_no         -- 证件号码
				,a.loan_no         -- 贷款合同编号
         from dw_base.dwd_guar_info_all a
		 inner join dw_base.dwd_guar_info_stat b
            on a.guar_id = b.guar_id and b.day_id = '${v_sdate}'
		 left join dw_base.dwd_tjnd_report_biz_loan_bank c -- 省担国担银行分险比例映射底表
            on a.guar_id = c.biz_no and c.day_id = '${v_sdate}'
		left join dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation d 
		    on b.project_id = d.id
		left join dw_nd.ods_tjnd_yw_base_cooperative_institution_agreement e -- 合作机构表（老逻辑底表）
            on d.related_agreement_id = e.ID
		left join (                                                                                 -- 【保后任务，逾期相关数据】
		            select proj_no_prov
					      ,max(ovd_dt) as ovd_dt-- 逾期日期
						  ,sum(ovd_amt) as ovd_amt -- 逾期金额（含银行分险）  逾期本金金额
                          ,sum(ovd_prin_rmv_bank_rk_seg_bal) as  ovd_ucompt_amt -- 逾期未代偿金额（不含银行分险）  逾期本金余额(扣除银行分险)
						  ,max(a2.value) as  subj_rk_rsn_cd  -- 客观风险类型代码
						  ,max(a3.value) as  obj_rk_rsn_cd   -- 主观风险类型代码
						  ,max(a1.ovd_rsn_desc) as ovd_rsn_desc -- 项目逾期原因详述
		            from (
                            select  t2.guar_id                                    as proj_no_prov
                                  , date_format(t1.overdue_date, '%Y-%m-%d')     as ovd_dt        -- 逾期日期
                                  , coalesce(t1.overdue_principal, 0)            as ovd_amt       -- 逾期本金金额
                                  , coalesce(t1.overdue_int, 0)                  as other_ovd_amt -- 逾期利息以及其他费用金额
                                  , coalesce(t1.overdue_int, 0)                  as other_ovd_bal -- 逾期利息以及其他费用金额余额
                                  , coalesce(t1.overdue_principal * (1 - if(t2.guar_id like 'TJ%', t23.bank_org_rate, t3.bank_risk / 100)), 0)  as ovd_prin_rmv_bank_rk_seg_amt                -- 逾期本金(扣除银行分险)                     [逾期本金金额 * （1 - 银行分险比例）]
                                  , coalesce(t1.overdue_int * (1 - if(t2.guar_id like 'TJ%', t23.bank_org_rate, t3.bank_risk / 100)), 0)        as other_ovd_rmv_bank_rk_seg_amt               -- 逾期利息以及其他费用金额(扣除银行分险)     [逾期利息 * （1 - 银行分险比例）]
                                  , coalesce(t1.overdue_principal * (1 - if(t2.guar_id like 'TJ%', t23.bank_org_rate, t3.bank_risk / 100)), 0)  as ovd_prin_rmv_bank_rk_seg_bal                -- 逾期本金余额(扣除银行分险)                 [逾期本金金额 * （1 - 银行分险比例）]
                                  , coalesce(t1.overdue_int * (1 - if(t2.guar_id like 'TJ%', t23.bank_org_rate, t3.bank_risk / 100)), 0)        as other_ovd_rmv_bank_rk_seg_bal               -- 逾期利息以及其他费用金额余额(扣除银行分险) [逾期利息 * （1 - 银行分险比例）]
                                  , coalesce(t1.objective_risk_type,t1.objective_risk_type_relation)                       as subj_rk_rsn_cd -- 客观风险类型代码
                                  , t1.subjective_risk_type                      as obj_rk_rsn_cd  -- 主观风险类型代码
                                  , t1.overdue_reason_detail                     as ovd_rsn_desc   -- 项目逾期原因详述
                                  , t1.risk_resolution_measures                  as rk_mtg_meas    -- 风险化解措施
                                  , null                                         as ovd_prin_bal
                                  , 1                                            as dict_flag
                            from (
                                   select task_id
                            	         ,project_id
                                         ,overdue_principal            --  逾期本金
                            			 ,overdue_int                  --  逾期利息（元）
                            			 ,overdue_date                 --  逾期日期
                            			 ,objective_risk_type          -- 客观风险类型
                            			 ,substring_index(regexp_replace(objective_risk_type_relation, '"|\\[|\\]', ''), ',', 1) as objective_risk_type_relation -- 客观风险类型
                            			 ,subjective_risk_type         -- 主观风险类型
                            			 ,overdue_reason_detail        -- 项目逾期原因详述
                            			 ,risk_resolution_measures     -- 风险化解措施
                                   from (select *,row_number() over (partition by project_id order by db_update_time desc) rn from dw_nd.ods_t_loan_after_check) a  -- 保后检查表
                            	   where a.rn = 1 
                            	     and is_debt_overdue != '0'    -- 本次贷款是否逾期  [判断这笔项目为逾期；0-未逾期，1-本息逾期，2-利息逾期，3-本金逾期]    
                            		 and overdue_date is not null  -- [判断这笔项目为逾期]
                            	 ) t1 
                            left join dw_base.dwd_guar_info_stat t2 -- 业务台账表
                            on t1.project_id = t2.project_id
                            left join(select biz_no,bank_risk from dw_base.dwd_tjnd_report_biz_loan_bank where day_id = '${v_sdate}') t3 -- 省担国担银行分险比例映射底表
                            on t2.guar_id = t3.biz_no
							left join dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation t21 on t2.project_id = t21.id              -- [这一块是算老系统数据的银行分险比例]
                            left join dw_nd.ods_tjnd_yw_base_cooperative_institution_agreement t23 -- 合作机构表（老逻辑底表）
                            on t21.related_agreement_id = t23.ID
						 )                                                               a1       -- 国农担上报逾期记录表
					left join dw_nd.tmp_ads_rpt_tjnd_risk_compt_ovd_proj_stat_code_value a2
					on a1.subj_rk_rsn_cd = a2.code
					left join dw_nd.tmp_ads_rpt_tjnd_risk_compt_ovd_proj_stat_code_value a3
					on a1.obj_rk_rsn_cd = a3.code					
					group by proj_no_prov
				  ) f 
		on a.guar_id = f.proj_no_prov
         where a.day_id = '${v_sdate}'
           and a.data_source = '担保业务管理系统新'          
		   and a.guar_id not in ('TJRD-2021-5S93-979U','TJRD-2021-5Z85-959X')  -- [刘志强和陶文峰现在是2个系统都有数据，需要排除新系统的数据]
     ) t1
         left join
     (
         select guar_id,  -- 台账编号
                compt_amt -- 代偿金额(本息)(万元)
         from dw_base.dwd_guar_compt_info
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select guar_id,
                project_id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t3 on t1.guar_id = t3.guar_id
         left join
     (
         select code,                          -- 项目id
                main_business_one as main_biz, -- 经营主业
                rn
			   ,case when aggregate_scheme = '01' then '种粮担'
			         when aggregate_scheme = '02' then '畜禽担'
			         when aggregate_scheme = '03' then '果香担'
			         when aggregate_scheme = '04' then '蔬菜担'
					 when aggregate_scheme = '05' then '农贸担' 
					 when aggregate_scheme = '06' then '强村保' 
					 when aggregate_scheme = '07' then '文旅保' 
					 when aggregate_scheme = '08' then '常规业务' 
					 when aggregate_scheme = '09' then '特殊业务' 
					 when aggregate_scheme = '10' then '农贸担-海吉星' 
					 when aggregate_scheme = '11' then '水产担' 
					 when aggregate_scheme = '12' then '鉴银担-宝坻' 
					 when aggregate_scheme = '13' then '王口炒货-邮储银行' 
					 when aggregate_scheme = 'CP202506160001' then '文旅担'
					 when aggregate_scheme = 'CP202504220001' then '"水产担"产品方案'
					 when aggregate_scheme = 'JQ202503050001' then '农贸担-海吉星担保服务方案'
					 when aggregate_scheme = 'CP202503050005' then '强村保"产品方案'
					 when aggregate_scheme = 'CP202503050004' then '"农贸担"产品方案'
					 when aggregate_scheme = 'CP202503050003' then '"蔬菜担"产品方案'
					 when aggregate_scheme = 'CP202503050002' then '"果香担"产品方案'
					 when aggregate_scheme = 'CP202503050001' then '"畜禽担"产品方案'
					 when aggregate_scheme = 'CP202503040001' then '"种粮担"产品方案'
					 else aggregate_scheme 
                     end   as aggregate_scheme   -- 产业集群
				,branch_manager_name  -- 农担分支机构项目经理名称
				,branch               -- 分支机构
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main
              ) t1
         where rn = 1
     ) t4 on t1.guar_id = t4.code
         left join
     (
         select project_id,
                overdue_totl                         as ovd_amt,           -- 逾期合计
                overdue_totl * (1 - risk_shar_ratio/100) as ovd_ucompt_amt,    -- 逾期未代偿金额(不含银担分险)
                TRIM(TRAILING '0' FROM FORMAT(risk_shar_ratio/ 100, 2)) as bank_ratio,        -- 银行分险比例   [去除多余的0]
                apply_comp_amount                    as shod_compt_amt,    -- 申请代偿金额
                overdue_date                         as ovd_dt,            -- 逾期日期
                str_to_date(act_disburse_date,'%Y%m%d') as compt_dt,          -- 代偿款实际拨付日期
--                case when objective_over_reason = '90'  then '政策风险-其他重要政策变动-其他'                            
--				     when objective_over_reason = '70'  then '担保客户生命健康风险-借款人或项目实际控制人突发重大疾病'   
--					 when objective_over_reason = '100' then '其他不可抗力-战争'                                         
--					 when objective_over_reason = '110' then '其他不能预见、不能避免并不能克服的客观情况'                
--					 when objective_over_reason = '20'  then '自然风险-其他自然灾害'                                     
--					 when objective_over_reason = '60'  then '担保客户生命健康风险-借款人或项目实际控制人死亡'           
--					 when objective_over_reason = '10'  then '自然风险-其他自然灾害'                                     
--					 when objective_over_reason = '40'  then '自然风险-传染病疫情'                                       
--					 when objective_over_reason = '30'  then '自然风险-动物疫情'                                         
--					 when objective_over_reason = '80'  then '政策风险-征收、征用、封锁'                                 
--					 when objective_over_reason = '50'  then '自然风险-其他自然灾害'                                     
--                     end                             as claim_cause       -- 客观风险成因
--			   ,case when subjective_over_reason = '130' then '其他主观原因'          
--				     when subjective_over_reason = '90'  then '隐性负债'              
--				     when subjective_over_reason = '100' then '其他主观原因'          
--				     when subjective_over_reason = '80'  then '银行抽贷'              
--				     when subjective_over_reason = '120' then '违法/违规/涉诉'        
--				     when subjective_over_reason = '20'  then '其他主观原因'          
--				     when subjective_over_reason = '60'  then '隐性负债'             
--				     when subjective_over_reason = '110' then '违法/违规/涉诉'       
--				     when subjective_over_reason = '30'  then '其他主观原因'         
--				     when subjective_over_reason = '70'  then '经营能力不足'         
--				     when subjective_over_reason = '50'  then '经营能力不足'         
--				     when subjective_over_reason = '40'  then '经营能力不足'         
--				     when subjective_over_reason = '10'  then '不良嗜好'              
--		             end                             as claim_cause_detail       -- 主观风险成因
               b.value as claim_cause,              -- 客观风险成因
			   c.value as claim_cause_detail        -- 主观风险成因
         from (
                  select a1.project_id,
                         case when a4.value not in ('已代偿', '已否决', '已终止') then a1.overdue_totl end as overdue_totl,
                         a1.risk_shar_ratio,
                         a1.apply_comp_amount,
                         a1.overdue_date,
                         a3.risk_reason,
                         a2.act_disburse_date, 
						 coalesce(substring_index(regexp_replace(a3.objective_over_reason, '"|\\[|\\]', ''), ',', 1),'999999') as objective_over_reason,  -- 客观原因   110
					     coalesce(substring_index(regexp_replace(a3.subjective_over_reason,'"|\\[|\\]', ''), ',', 1),'99') as subjective_over_reason, -- 主观原因       130
                         row_number() over (partition by project_id order by a1.db_update_time desc) rn
                  from dw_nd.ods_t_proj_comp_aply a1 -- 代偿申请信息
                           left join dw_nd.ods_t_proj_comp_appropriation a2 -- 拨付信息
                                     on a1.id = a2.comp_id
                           left join (select comp_id,risk_reason,objective_over_reason,subjective_over_reason
						              from (select *,row_number() over(partition by comp_id order by db_update_time desc,update_time desc) as rn from dw_nd.ods_t_proj_comp_reason where is_delete = '0') z 
                                      where z.rn = 1) a3 -- 代偿原因
                                     on a1.id = a3.comp_id
                           left join
                       (
                           select * from dw_nd.ods_t_sys_data_dict_value_v2 where dict_code = 'bhProjectStatus'
                       ) a4 on a1.status = a4.code
              ) a  
		left join dw_nd.tmp_ads_rpt_tjnd_risk_compt_ovd_proj_stat_code_value b 
		on a.objective_over_reason = b.code
		left join dw_nd.tmp_ads_rpt_tjnd_risk_compt_ovd_proj_stat_code_value c 
		on a.subjective_over_reason = c.code
         where rn = 1
     ) t5 on t3.project_id = t5.project_id
         left join
     (
         select project_id,
                other_remark    as other_cont, -- 其他机构备注
                risk_shar_other as other_ratio -- 其他机构分险比例
         from (
                  select *, row_number() over (partition by project_id order by db_update_time desc) rn
                  from dw_nd.ods_t_proj_comp_risk_share
              ) t1
         where rn = 1
     ) t6 on t3.project_id = t6.project_id
         left join
     (
         select distinct project_id
         from dw_nd.ods_t_ct_guar_person -- 反担保保证信息表
     ) t7 on t3.project_id = t7.project_id
         left join
     (
         select distinct project_id
         from dw_nd.ods_t_ct_guar_pledge -- 质押反担保方式-结构化数据
         union
         select distinct project_id
         from dw_nd.ods_t_ct_guar_mortgage -- 抵押反担保措施所需结构化数据
     ) t8 on t3.project_id = t8.project_id
         left join
     (
         select project_id,
                reply_counter_guar_desc as un_guar_remark -- 反担保措施说明
         from (
                  select *, row_number() over (partition by project_id order by db_update_time desc) rn
                  from dw_nd.ods_t_biz_proj_appr
              ) t1
         where rn = 1
     ) t9 on t3.project_id = t9.project_id
         left join
     (
         select t1.project_id,                                                        -- 项目id
                group_concat(distinct t1.reco_method separator ',') as recovery_mode, -- 追偿措施
                sum(t2.shou_comp_amt)                               as risk_amt       -- 追偿还款金额
         from dw_nd.ods_t_biz_proj_recovery_record t1
                  left join dw_nd.ods_t_biz_proj_recovery_repay_detail_record t2 on t1.reco_id = t2.record_id
         group by t1.project_id
     ) t10 on t3.project_id = t10.project_id
         left join
     (
         select *
         from (select *, row_number() over (partition by dept_id order by update_time desc) as rn
               from dw_nd.ods_t_sys_dept -- 部门表
               where del_flag = 0) t1
         where rn = 1
     ) t11 on t1.ln_inst = t11.dept_name
         left join
     (
         select t1.dept_id,
                t2.bank_name,
                comp_duran as compt_day -- 代偿宽限期
         from (
                  select *
                  from (
                           select *, row_number() over (partition by dept_id order by update_time desc) as rn
                           from dw_nd.ods_t_sys_dept
                           where del_flag = 0
                       ) t1
                  where rn = 1
              ) t1
                  join dw_nd.ods_imp_tjnd_bank_credit_detail t2 on t1.dept_name = t2.bank_name
     ) t12
         -- 祖籍列表包含银行表 或者 部门表id等于银行id
     on FIND_IN_SET(t12.dept_id, t11.ancestors) > 0 or t11.dept_id = t12.dept_id
where t1.proj_status in ('逾期','已代偿')
	 
;
commit;