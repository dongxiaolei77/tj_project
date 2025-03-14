-- ---------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20230820
-- 目标表   ：dw_base.dwd_sdnd_data_report_guar_tag
-- 源表     ：dw_nd.ods_t_proj_comp_aply           代偿申请信息
--            dw_nd.ods_t_biz_project_main         主项目表（进件表）
--            dw_base.dwd_guar_info_all            业务台账宽表
--            dw_base.dwd_guar_info_all_his        业务台账宽表——历史表
--            dw_base.dwd_guar_info_stat           业务台账宽表
--            dw_base.dwd_guar_cont_info_all       担保年度业务信息宽表
--            dw_base.dwd_guar_tag                 标签表
--            dw_base.dwd_guar_compt_info          代偿项目表
--            dw_base.dim_bank_info                银行码表
--            dw_tmp.tmp_bank_class_code_20231016
--            dw_tmp.tmp_bank_nd_risk_20231016     银行分险名单
-- 备注     ：国担上报-山东农担数据上报底层数据

-- 变更记录 ：wangyj 20231017 变更贷款银行分类，变更首担逻辑
--            dw_tmp.tmp_bank_class_code_20231016 提供缺失贷款银行名称或匹配不到银行分险表中名称的业务名单，由农担诸葛老师返回
--            dw_tmp.tmp_bank_nd_risk_20231016 银行分险名单
--            dw_tmp.tmp_dwd_sdnd_data_report_guar_tag_loan_bank 按照银行分险名单和银担合作模块定义bank_class
--            所有字段，国担上报有标准，不能随意修改
--            20241201 脚本的统一变更，MySQL5.0转MySQL8.0 zhangfl
-- ---------------------------------------
drop table if exists dw_tmp.tmp_dwd_sdnd_data_report_guar_tag_loan_bank;
commit;
create table dw_tmp.tmp_dwd_sdnd_data_report_guar_tag_loan_bank
( guar_id      varchar(64)      comment  '台账编号'
 ,loan_bank    varchar(100)     comment  '贷款银行'
 ,bank_class   varchar(100)     comment  '贷款银行分类'

 ,index idx_tmp_dwd_sdnd_data_report_guar_tag_loan_bank_id(guar_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='国担上报数据--银行分类';
commit;

insert into dw_tmp.tmp_dwd_sdnd_data_report_guar_tag_loan_bank
( guar_id
 ,loan_bank
 ,bank_class
)
select a.guar_id
,a.loan_bank
,case
when (loan_bank like '%农业银行%' or loan_bank like '%农行%' or loan_bank like '%中国农业股份有限公司%') then '农业银行'      
when loan_bank like '%工商银行%'then '工商银行'       
when (loan_bank like '%建设银行%' or loan_bank like '%建行%') then '建设银行'      
when loan_bank like '%交通银行%'then '交通银行'       
when loan_bank like '%中国银行%'then '中国银行'       
when (loan_bank like '%邮储银行%' or loan_bank like '%邮储%' or loan_bank like '%邮政%')then '邮储银行'     
when loan_bank like '%农业发展银行%'then '农发行'   -- wyx 20231017    
when loan_bank like '%北京银行%'then '北京银行'       
when loan_bank like '%齐鲁银行%'then '齐鲁银行'       
when loan_bank like '%日照银行%'then '日照银行'       
when loan_bank like '%莱商银行%'then '莱商银行'       
when loan_bank like '%威海市商业银行%'then '威海市商业银行'    
when loan_bank like '%德州银行%'then '德州银行'       
when loan_bank like '%齐商银行%'then '齐商银行'       
when loan_bank like '%潍坊银行%'then '潍坊银行'       
when loan_bank like '%东营银行%'then '东营银行'       
when loan_bank like '%青岛银行%'then '青岛银行'       
when loan_bank like '%临商银行%'then '临商银行'       
when loan_bank like '%枣庄银行%'then '枣庄银行'       
when loan_bank like '%烟台银行%'then '烟台银行'       
when loan_bank like '%济宁银行%'then '济宁银行'       
when loan_bank like '%泰安银行%'then '泰安银行'       
when loan_bank like '%天津银行%'then '天津银行'       
when loan_bank like '%广发银行%'then '广发银行'       
when loan_bank like '%招商银行%'then '招商银行'       
when loan_bank like '%兴业银行%'then '兴业银行'       
when loan_bank like '%中信银行%'then '中信银行'       
when loan_bank like '%华夏银行%'then '华夏银行'       
when loan_bank like '%浦发银行%'then '浦发银行'       
when loan_bank like '%渤海银行%'then '渤海银行'       
when loan_bank like '%光大银行%'then '光大银行'       
when loan_bank like '%民生银行%'then '民生银行'       
when loan_bank like '%浙商银行%'then '浙商银行'       
when loan_bank like '%恒丰银行%'then '恒丰银行'       
when loan_bank like '%光大银行%'then '光大银行'       
when loan_bank like '%寿光张农商村镇银行%'then '寿光张农商村镇银行'  
when loan_bank like '%临朐聚丰村镇银行%'then  '临朐聚丰村镇银行'   
when loan_bank like '%金乡蓝海村镇银行%'then  '金乡蓝海村镇银行'   
when loan_bank like '%莘县青隆村镇银行%'then  '莘县青隆村镇银行'   
when loan_bank like '%蓬莱民生村镇银行%'then  '蓬莱民生村镇银行'   
when loan_bank like '%梁山民丰村镇银行%'then  '梁山民丰村镇银行'   
when loan_bank like '%肥城民丰村镇银行%'then  '肥城民丰村镇银行'   
when loan_bank like '%郓城北海村镇银行%'then  '郓城北海村镇银行'   
when loan_bank like '%沾化青云村镇银行%'then  '沾化青云村镇银行'   
when loan_bank like '%莱阳胶东村镇银行%'then  '莱阳胶东村镇银行'   
when loan_bank like '%嘉祥中银富登村镇银行%'then '嘉祥中银富登村镇银行' 
when loan_bank like '%垦利乐安村镇银行%'then  '垦利乐安村镇银行'   
when loan_bank like '%兖州中成村镇银行%'then  '兖州中成村镇银行'   
when loan_bank like '%高密惠民村镇银行%'then  '高密惠民村镇银行'   
when loan_bank like '%临淄汇金村镇银行%'then  '临淄汇金村镇银行'   
when loan_bank like '%平阴蓝海村镇银行%'then  '平阴蓝海村镇银行'   
when loan_bank like '%庆云乐安村镇银行%'then  '庆云乐安村镇银行'   
when loan_bank like '%武城圆融村镇银行%'then  '武城圆融村镇银行'   
when loan_bank like '%昌乐乐安村镇银行%'then  '昌乐乐安村镇银行'   
when loan_bank like '%乐陵圆融村镇银行%'then  '乐陵圆融村镇银行'   
when loan_bank like '%日照沪农商村镇银行%'then '日照沪农商村镇银行'  
when loan_bank like '%东营莱商村镇银行%'then  '东营莱商村镇银行'   
when loan_bank like '%利津舜丰村镇银行%'then  '利津舜丰村镇银行'   
when loan_bank like '%鱼台青隆村镇银行%'then  '鱼台青隆村镇银行'   
when loan_bank like '%济宁儒商村镇银行%'then  '济宁儒商村镇银行'   
when loan_bank like '%邹平青隆村镇银行%'then  '邹平青隆村镇银行'   
when loan_bank like '%乳山天骄村镇银行%'then  '乳山天骄村镇银行'   
when loan_bank like '%牟平胶东村镇银行%'then  '牟平胶东村镇银行'   
when loan_bank like '%曲阜中银富登村镇银行%'then '曲阜中银富登村镇银行' 
when loan_bank like '%齐河胶东村镇银行%'then  '齐河胶东村镇银行'   
when loan_bank like '%济宁蓝海村镇银行%'then  '济宁蓝海村镇银行'   
when loan_bank like '%济宁高新村镇银行%'then  '济宁高新村镇银行'   
when loan_bank like '%五莲中银富登村镇银行%'then '五莲中银富登村镇银行' 
when loan_bank like '%夏津胶东村镇银行%'then  '夏津胶东村镇银行'   
when loan_bank like '%寒亭蒙银村镇银行%'then  '寒亭蒙银村镇银行'   
when loan_bank like '%东营融和村镇银行%'then  '东营融和村镇银行'   
when loan_bank like '%汶上中银富登村镇银行%'then '汶上中银富登村镇银行' 
when loan_bank like '%东明中银富登村镇银行%'then '东明中银富登村镇银行' 
when loan_bank like '%滕州中银富登村镇银行%'then '滕州中银富登村镇银行' 
when loan_bank like '%文登中银富登村镇银行%'then '文登中银富登村镇银行' 
when loan_bank like '%沂源博商村镇银行%'then  '沂源博商村镇银行'   
when loan_bank like '%济南槐荫沪农商村镇银行%'then '济南槐荫沪农商村镇银行'
when loan_bank like '%济南长清沪农商村镇银行%'then '济南长清沪农商村镇银行'
when loan_bank like '%聊城沪农商村镇银行%'then '聊城沪农商村镇银行'  
when loan_bank like '%茌平沪农商村镇银行%'then '茌平沪农商村镇银行'  
when loan_bank like '%阳谷沪农商村镇银行%'then '阳谷沪农商村镇银行'  
when loan_bank like '%临清沪农商村镇银行%'then '临清沪农商村镇银行'  
when loan_bank like '%泰安沪农商村镇银行%'then '泰安沪农商村镇银行'  
when loan_bank like '%宁阳沪农商村镇银行%'then '宁阳沪农商村镇银行'  
when loan_bank like '%东平沪农商村镇银行%'then '东平沪农商村镇银行'  
when loan_bank like '%周村青隆村镇银行%'then  '周村青隆村镇银行'   
when loan_bank like '%桓台青隆村镇银行%'then  '桓台青隆村镇银行'   
when loan_bank like '%宁津胶东村镇银行%'then  '宁津胶东村镇银行'   
when loan_bank like '%博兴新华村镇银行%'then  '博兴新华村镇银行'   
when loan_bank like '%章丘齐鲁村镇银行%'then  '章丘齐鲁村镇银行'   
when loan_bank like '%临邑中银富登村镇银行%'then '临邑中银富登村镇银行' 
when loan_bank like '%东阿青隆村镇银行%'then  '东阿青隆村镇银行'   
when loan_bank like '%日照九银村镇银行%'then  '日照九银村镇银行'   
when loan_bank like '%菏泽牡丹北海村镇银行%'then '菏泽牡丹北海村镇银行' 
when loan_bank like '%高青汇金村镇银行%'then  '高青汇金村镇银行'   
when loan_bank like '%商河汇金村镇银行%'then  '商河汇金村镇银行'   
when loan_bank like '%沂水中银富登村镇银行%'then '沂水中银富登村镇银行' 
when loan_bank like '%莱芜中成村镇银行%'then  '莱芜中成村镇银行'   
when loan_bank like '%诸城中银富登村镇银行%'then '诸城中银富登村镇银行' 
when loan_bank like '%高唐青隆村镇银行%'then  '高唐青隆村镇银行'   
when loan_bank like '%邹城中银富登村镇银行%'then '邹城中银富登村镇银行' 
when loan_bank like '%广饶梁邹村镇银行%'then  '广饶梁邹村镇银行'   
when loan_bank like '%潍城%北海村镇银行%'then  '潍城北海村镇银行'   
when loan_bank like '%安丘北海村镇银行%'then  '安丘北海村镇银行'   
when loan_bank like '%滨州河海村镇银行%'then  '滨州河海村镇银行'   
when loan_bank like '%鄄城牡丹村镇银行%'then  '鄄城牡丹村镇银行'   
when loan_bank like '%昌邑北海村镇银行%'then  '昌邑北海村镇银行'   
when loan_bank like '%成武汉源村镇银行%'then  '成武汉源村镇银行'   
when loan_bank like '%单县中银富登村镇银行%'then '单县中银富登村镇银行' 
when loan_bank like '%兰陵村镇银行%'then '兰陵村镇银行'     
when loan_bank like '%临沭民丰村镇银行%'then  '临沭民丰村镇银行'   
when loan_bank like '%河东齐商村镇银行%'then  '河东齐商村镇银行'   
when loan_bank like '%青州中银富登村镇银行%'then '青州中银富登村镇银行' 
when loan_bank like '%莒南村镇银行%'then '莒南村镇银行'     
when loan_bank like '%威海富民村镇银行%'then  '威海富民村镇银行'   
when loan_bank like '%阳信河海村镇银行%'then  '阳信河海村镇银行'   
when loan_bank like '%平邑汉源村镇银行%'then  '平邑汉源村镇银行'   
when loan_bank like '%郯城汉源村镇银行%'then  '郯城汉源村镇银行'   
when loan_bank like '%淄川北海村镇银行%'then  '淄川北海村镇银行'   
when loan_bank like '%邹平浦发村镇银行%'then  '邹平浦发村镇银行'   
when loan_bank like '%陵城圆融村镇银行%'then  '陵城圆融村镇银行'   
when loan_bank like '%博山北海村镇银行%'then  '博山北海村镇银行'   
when loan_bank like '%沂南蓝海村镇银行%'then  '沂南蓝海村镇银行'   
when loan_bank like '%龙口中银富登村镇银行%'then '龙口中银富登村镇银行' 
when loan_bank like '%栖霞中银富登村镇银行%'then '栖霞中银富登村镇银行' 
when loan_bank like '%莒县金谷村镇银行%'then  '莒县金谷村镇银行'   
when loan_bank like '%日照蓝海村镇银行%'then  '日照蓝海村镇银行'   
when loan_bank like '%曹县中银富登村镇银行%'then '曹县中银富登村镇银行' 
when loan_bank like '%平原圆融村镇银行%'then  '平原圆融村镇银行'   
when loan_bank like '%禹城胶东村镇银行%'then  '禹城胶东村镇银行'   
when loan_bank like '%冠县齐丰村镇银行%'then  '冠县齐丰村镇银行'   
when loan_bank like '%青州%农商行%' or loan_bank like'%青州%农村商业%' or loan_bank like'%青州%农村信用合作社%' or loan_bank like'%青州%农村信用合作联社%' or loan_bank like'%青州%农商%'then  '青州农商行'
when loan_bank like '%昌乐%农商行%' or loan_bank like'%昌乐%农村商业%' or loan_bank like'%昌乐%农村信用合作社%' or loan_bank like'%昌乐%农村信用合作联社%' or loan_bank like'%昌乐%农商%'then  '昌乐农商行'
when loan_bank like '%临朐%农商行%' or loan_bank like'%临朐%农村商业%' or loan_bank like'%临朐%农村信用合作社%' or loan_bank like'%临朐%农村信用合作联社%' or loan_bank like'%临朐%农商%'then  '临朐农商行'
when loan_bank like '%安丘%农商行%' or loan_bank like'%安丘%农村商业%' or loan_bank like'%安丘%农村信用合作社%' or loan_bank like'%安丘%农村信用合作联社%' or loan_bank like'%安丘%农商%'then  '安丘农商行'
when loan_bank like '%寿光%农商行%' or loan_bank like'%寿光%农村商业%' or loan_bank like'%寿光%农村信用合作社%' or loan_bank like'%寿光%农村信用合作联社%' or loan_bank like'%寿光%农商%'then  '寿光农商行'
when loan_bank like '%诸城%农商行%' or loan_bank like'%诸城%农村商业%' or loan_bank like'%诸城%农村信用合作社%' or loan_bank like'%诸城%农村信用合作联社%' or loan_bank like'%诸城%农商%'then  '诸城农商行'
when loan_bank like '%莘县%农商行%' or loan_bank like'%莘县%农村商业%' or loan_bank like'%莘县%农村信用合作社%' or loan_bank like'%莘县%农村信用合作联社%' or loan_bank like'%莘县%农商%'then  '莘县农商行'
when loan_bank like '%高密%农商行%' or loan_bank like'%高密%农村商业%' or loan_bank like'%高密%农村信用合作社%' or loan_bank like'%高密%农村信用合作联社%' or loan_bank like'%高密%农商%'then  '高密农商行'
when loan_bank like '%邹平%农商行%' or loan_bank like'%邹平%农村商业%' or loan_bank like'%邹平%农村信用合作社%' or loan_bank like'%邹平%农村信用合作联社%' or loan_bank like'%邹平%农商%'then  '邹平农商行'
when loan_bank like '%高青%农商行%' or loan_bank like'%高青%农村商业%' or loan_bank like'%高青%农村信用合作社%' or loan_bank like'%高青%农村信用合作联社%' or loan_bank like'%高青%农商%'then  '高青农商行'
when loan_bank like '%宁阳%农商行%' or loan_bank like'%宁阳%农村商业%' or loan_bank like'%宁阳%农村信用合作社%' or loan_bank like'%宁阳%农村信用合作联社%' or loan_bank like'%宁阳%农商%'then  '宁阳农商行'
when loan_bank like '%陵城%农商行%' or loan_bank like'%陵城%农村商业%' or loan_bank like'%陵城%农村信用合作社%' or loan_bank like'%陵城%农村信用合作联社%' or loan_bank like'%陵城%农商%'then  '陵城农商行'
when loan_bank like '%潍坊%农商行%' or loan_bank like'%潍坊%农村商业%' or loan_bank like'%潍坊%农村信用合作社%' or loan_bank like'%潍坊%农村信用合作联社%' or loan_bank like'%潍坊%农商%'then  '潍坊农商行'
when loan_bank like '%夏津%农商行%' or loan_bank like'%夏津%农村商业%' or loan_bank like'%夏津%农村信用合作社%' or loan_bank like'%夏津%农村信用合作联社%' or loan_bank like'%夏津%农商%'then  '夏津农商行'
when loan_bank like '%梁山%农商行%' or loan_bank like'%梁山%农村商业%' or loan_bank like'%梁山%农村信用合作社%' or loan_bank like'%梁山%农村信用合作联社%' or loan_bank like'%梁山%农商%'then  '梁山农商行'
when loan_bank like '%肥城%农商行%' or loan_bank like'%肥城%农村商业%' or loan_bank like'%肥城%农村信用合作社%' or loan_bank like'%肥城%农村信用合作联社%' or loan_bank like'%肥城%农商%'then  '肥城农商行'
when loan_bank like '%武城%农商行%' or loan_bank like'%武城%农村商业%' or loan_bank like'%武城%农村信用合作社%' or loan_bank like'%武城%农村信用合作联社%' or loan_bank like'%武城%农商%'then  '武城农商行'
when loan_bank like '%齐河%农商行%' or loan_bank like'%齐河%农村商业%' or loan_bank like'%齐河%农村信用合作社%' or loan_bank like'%齐河%农村信用合作联社%' or loan_bank like'%齐河%农商%'then  '齐河农商行'
when loan_bank like '%博兴%农商行%' or loan_bank like'%博兴%农村商业%' or loan_bank like'%博兴%农村信用合作社%' or loan_bank like'%博兴%农村信用合作联社%' or loan_bank like'%博兴%农商%'then  '博兴农商行'
when loan_bank like '%鄄城%农商行%' or loan_bank like'%鄄城%农村商业%' or loan_bank like'%鄄城%农村信用合作社%' or loan_bank like'%鄄城%农村信用合作联社%' or loan_bank like'%鄄城%农商%'then  '鄄城农商行'
when loan_bank like '%乳山%农商行%' or loan_bank like'%乳山%农村商业%' or loan_bank like'%乳山%农村信用合作社%' or loan_bank like'%乳山%农村信用合作联社%' or loan_bank like'%乳山%农商%'then  '乳山农商行'
when loan_bank like '%邹城%农商行%' or loan_bank like'%邹城%农村商业%' or loan_bank like'%邹城%农村信用合作社%' or loan_bank like'%邹城%农村信用合作联社%' or loan_bank like'%邹城%农商%'then  '邹城农商行'
when loan_bank like '%郓城%农商行%' or loan_bank like'%郓城%农村商业%' or loan_bank like'%郓城%农村信用合作社%' or loan_bank like'%郓城%农村信用合作联社%' or loan_bank like'%郓城%农商%'then  '郓城农商行'
when loan_bank like '%枣庄%农商行%' or loan_bank like'%枣庄%农村商业%' or loan_bank like'%枣庄%农村信用合作社%' or loan_bank like'%枣庄%农村信用合作联社%' or loan_bank like'%枣庄%农商%'then  '枣庄农商行'
when loan_bank like '%临邑%农商行%' or loan_bank like'%临邑%农村商业%' or loan_bank like'%临邑%农村信用合作社%' or loan_bank like'%临邑%农村信用合作联社%' or loan_bank like'%临邑%农商%'then  '临邑农商行'
when loan_bank like '%曹县%农商行%' or loan_bank like'%曹县%农村商业%' or loan_bank like'%曹县%农村信用合作社%' or loan_bank like'%曹县%农村信用合作联社%' or loan_bank like'%曹县%农商%'then  '曹县农商行'
when loan_bank like '%平邑%农商行%' or loan_bank like'%平邑%农村商业%' or loan_bank like'%平邑%农村信用合作社%' or loan_bank like'%平邑%农村信用合作联社%' or loan_bank like'%平邑%农商%'then  '平邑农商行'
when loan_bank like '%禹城%农商行%' or loan_bank like'%禹城%农村商业%' or loan_bank like'%禹城%农村信用合作社%' or loan_bank like'%禹城%农村信用合作联社%' or loan_bank like'%禹城%农商%'then  '禹城农商行'
when loan_bank like '%嘉祥%农商行%' or loan_bank like'%嘉祥%农村商业%' or loan_bank like'%嘉祥%农村信用合作社%' or loan_bank like'%嘉祥%农村信用合作联社%' or loan_bank like'%嘉祥%农商%'then  '嘉祥农商行'
when loan_bank like '%莱阳%农商行%' or loan_bank like'%莱阳%农村商业%' or loan_bank like'%莱阳%农村信用合作社%' or loan_bank like'%莱阳%农村信用合作联社%' or loan_bank like'%莱阳%农商%'then  '莱阳农商行'
when loan_bank like '%莱芜%农商行%' or loan_bank like'%莱芜%农村商业%' or loan_bank like'%莱芜%农村信用合作社%' or loan_bank like'%莱芜%农村信用合作联社%' or loan_bank like'%莱芜%农商%'then  '莱芜农商行'
when loan_bank like '%利津%农商行%' or loan_bank like'%利津%农村商业%' or loan_bank like'%利津%农村信用合作社%' or loan_bank like'%利津%农村信用合作联社%' or loan_bank like'%利津%农商%'then  '利津农商行'
when loan_bank like '%临淄%农商行%' or loan_bank like'%临淄%农村商业%' or loan_bank like'%临淄%农村信用合作社%' or loan_bank like'%临淄%农村信用合作联社%' or loan_bank like'%临淄%农商%'then  '临淄农商行'
when loan_bank like '%滕州%农商行%' or loan_bank like'%滕州%农村商业%' or loan_bank like'%滕州%农村信用合作社%' or loan_bank like'%滕州%农村信用合作联社%' or loan_bank like'%滕州%农商%'then  '滕州农商行'
when loan_bank like '%蒙阴%农商行%' or loan_bank like'%蒙阴%农村商业%' or loan_bank like'%蒙阴%农村信用合作社%' or loan_bank like'%蒙阴%农村信用合作联社%' or loan_bank like'%蒙阴%农商%'then  '蒙阴农商行'
when loan_bank like '%昌邑%农商行%' or loan_bank like'%昌邑%农村商业%' or loan_bank like'%昌邑%农村信用合作社%' or loan_bank like'%昌邑%农村信用合作联社%' or loan_bank like'%昌邑%农商%'then  '昌邑农商行'
when loan_bank like '%兰陵%农商行%' or loan_bank like'%兰陵%农村商业%' or loan_bank like'%兰陵%农村信用合作社%' or loan_bank like'%兰陵%农村信用合作联社%' or loan_bank like'%兰陵%农商%'then  '兰陵农商行'
when loan_bank like '%文登%农商行%' or loan_bank like'%文登%农村商业%' or loan_bank like'%文登%农村信用合作社%' or loan_bank like'%文登%农村信用合作联社%' or loan_bank like'%文登%农商%'then  '文登农商行'
when loan_bank like '%河东%农商行%' or loan_bank like'%河东%农村商业%' or loan_bank like'%河东%农村信用合作社%' or loan_bank like'%河东%农村信用合作联社%' or loan_bank like'%河东%农商%'then  '河东农商行'
when loan_bank like '%荣成%农商行%' or loan_bank like'%荣成%农村商业%' or loan_bank like'%荣成%农村信用合作社%' or loan_bank like'%荣成%农村信用合作联社%' or loan_bank like'%荣成%农商%'then  '荣成农商行'
when loan_bank like '%菏泽%农商行%' or loan_bank like'%菏泽%农村商业%' or loan_bank like'%菏泽%农村信用合作社%' or loan_bank like'%菏泽%农村信用合作联社%' or loan_bank like'%菏泽%农商%'then  '菏泽农商行'
when loan_bank like '%巨野%农商行%' or loan_bank like'%巨野%农村商业%' or loan_bank like'%巨野%农村信用合作社%' or loan_bank like'%巨野%农村信用合作联社%' or loan_bank like'%巨野%农商%'then  '巨野农商行'
when loan_bank like '%商河%农商行%' or loan_bank like'%商河%农村商业%' or loan_bank like'%商河%农村信用合作社%' or loan_bank like'%商河%农村信用合作联社%' or loan_bank like'%商河%农商%'then  '商河农商行'
when loan_bank like '%莱州%农商行%' or loan_bank like'%莱州%农村商业%' or loan_bank like'%莱州%农村信用合作社%' or loan_bank like'%莱州%农村信用合作联社%' or loan_bank like'%莱州%农商%'then  '莱州农商行'
when loan_bank like '%临清%农商行%' or loan_bank like'%临清%农村商业%' or loan_bank like'%临清%农村信用合作社%' or loan_bank like'%临清%农村信用合作联社%' or loan_bank like'%临清%农商%'then  '临清农商行'
when loan_bank like '%岱岳%农商行%' or loan_bank like'%岱岳%农村商业%' or loan_bank like'%岱岳%农村信用合作社%' or loan_bank like'%岱岳%农村信用合作联社%' or loan_bank like'%岱岳%农商%'then  '岱岳农商行'
when loan_bank like '%广饶%农商行%' or loan_bank like'%广饶%农村商业%' or loan_bank like'%广饶%农村信用合作社%' or loan_bank like'%广饶%农村信用合作联社%' or loan_bank like'%广饶%农商%'then  '广饶农商行'
when loan_bank like '%龙口%农商行%' or loan_bank like'%龙口%农村商业%' or loan_bank like'%龙口%农村信用合作社%' or loan_bank like'%龙口%农村信用合作联社%' or loan_bank like'%龙口%农商%'then  '龙口农商行'
when loan_bank like '%郯城%农商行%' or loan_bank like'%郯城%农村商业%' or loan_bank like'%郯城%农村信用合作社%' or loan_bank like'%郯城%农村信用合作联社%' or loan_bank like'%郯城%农商%'then  '郯城农商行'
when loan_bank like '%阳信%农商行%' or loan_bank like'%阳信%农村商业%' or loan_bank like'%阳信%农村信用合作社%' or loan_bank like'%阳信%农村信用合作联社%' or loan_bank like'%阳信%农商%'then  '阳信农商行'
when loan_bank like '%莒县%农商行%' or loan_bank like'%莒县%农村商业%' or loan_bank like'%莒县%农村信用合作社%' or loan_bank like'%莒县%农村信用合作联社%' or loan_bank like'%莒县%农商%'then  '莒县农商行'
when loan_bank like '%费县%农商行%' or loan_bank like'%费县%农村商业%' or loan_bank like'%费县%农村信用合作社%' or loan_bank like'%费县%农村信用合作联社%' or loan_bank like'%费县%农商%'then  '费县农商行'
when loan_bank like '%成武%农商行%' or loan_bank like'%成武%农村商业%' or loan_bank like'%成武%农村信用合作社%' or loan_bank like'%成武%农村信用合作联社%' or loan_bank like'%成武%农商%'then  '成武农商行'
when loan_bank like '%茌平%农商行%' or loan_bank like'%茌平%农村商业%' or loan_bank like'%茌平%农村信用合作社%' or loan_bank like'%茌平%农村信用合作联社%' or loan_bank like'%茌平%农商%'then  '茌平农商行'
when loan_bank like '%沂源%农商行%' or loan_bank like'%沂源%农村商业%' or loan_bank like'%沂源%农村信用合作社%' or loan_bank like'%沂源%农村信用合作联社%' or loan_bank like'%沂源%农商%'then  '沂源农商行'
when loan_bank like '%沂水%农商行%' or loan_bank like'%沂水%农村商业%' or loan_bank like'%沂水%农村信用合作社%' or loan_bank like'%沂水%农村信用合作联社%' or loan_bank like'%沂水%农商%'then  '沂水农商行'
when loan_bank like '%东平%农商行%' or loan_bank like'%东平%农村商业%' or loan_bank like'%东平%农村信用合作社%' or loan_bank like'%东平%农村信用合作联社%' or loan_bank like'%东平%农商%'then  '东平农商行'
when loan_bank like '%金乡%农商行%' or loan_bank like'%金乡%农村商业%' or loan_bank like'%金乡%农村信用合作社%' or loan_bank like'%金乡%农村信用合作联社%' or loan_bank like'%金乡%农商%'then  '金乡农商行'
when loan_bank like '%五莲%农商行%' or loan_bank like'%五莲%农村商业%' or loan_bank like'%五莲%农村信用合作社%' or loan_bank like'%五莲%农村信用合作联社%' or loan_bank like'%五莲%农商%'then  '五莲农商行'
when loan_bank like '%垦利%农商行%' or loan_bank like'%垦利%农村商业%' or loan_bank like'%垦利%农村信用合作社%' or loan_bank like'%垦利%农村信用合作联社%' or loan_bank like'%垦利%农商%'then  '垦利农商行'
when loan_bank like '%东明%农商行%' or loan_bank like'%东明%农村商业%' or loan_bank like'%东明%农村信用合作社%' or loan_bank like'%东明%农村信用合作联社%' or loan_bank like'%东明%农商%'then  '东明农商行'
when loan_bank like '%乐陵%农商行%' or loan_bank like'%乐陵%农村商业%' or loan_bank like'%乐陵%农村信用合作社%' or loan_bank like'%乐陵%农村信用合作联社%' or loan_bank like'%乐陵%农商%'then  '乐陵农商行'
when loan_bank like '%无棣%农商行%' or loan_bank like'%无棣%农村商业%' or loan_bank like'%无棣%农村信用合作社%' or loan_bank like'%无棣%农村信用合作联社%' or loan_bank like'%无棣%农商%'then  '无棣农商行'
when loan_bank like '%曲阜%农商行%' or loan_bank like'%曲阜%农村商业%' or loan_bank like'%曲阜%农村信用合作社%' or loan_bank like'%曲阜%农村信用合作联社%' or loan_bank like'%曲阜%农商%'then  '曲阜农商行'
when loan_bank like '%阳谷%农商行%' or loan_bank like'%阳谷%农村商业%' or loan_bank like'%阳谷%农村信用合作社%' or loan_bank like'%阳谷%农村信用合作联社%' or loan_bank like'%阳谷%农商%'then  '阳谷农商行'
when loan_bank like '%平原%农商行%' or loan_bank like'%平原%农村商业%' or loan_bank like'%平原%农村信用合作社%' or loan_bank like'%平原%农村信用合作联社%' or loan_bank like'%平原%农商%'then  '平原农商行'
when loan_bank like '%汶上%农商行%' or loan_bank like'%汶上%农村商业%' or loan_bank like'%汶上%农村信用合作社%' or loan_bank like'%汶上%农村信用合作联社%' or loan_bank like'%汶上%农商%'then  '汶上农商行'
when loan_bank like '%岚山%农商行%' or loan_bank like'%岚山%农村商业%' or loan_bank like'%岚山%农村信用合作社%' or loan_bank like'%岚山%农村信用合作联社%' or loan_bank like'%岚山%农商%'then  '岚山农商行'
when loan_bank like '%沂南%农商行%' or loan_bank like'%沂南%农村商业%' or loan_bank like'%沂南%农村信用合作社%' or loan_bank like'%沂南%农村信用合作联社%' or loan_bank like'%沂南%农商%'then  '沂南农商行'
when loan_bank like '%章丘%农商行%' or loan_bank like'%章丘%农村商业%' or loan_bank like'%章丘%农村信用合作社%' or loan_bank like'%章丘%农村信用合作联社%' or loan_bank like'%章丘%农商%'then  '章丘农商行'
when loan_bank like '%惠民%农商行%' or loan_bank like'%惠民%农村商业%' or loan_bank like'%惠民%农村信用合作社%' or loan_bank like'%惠民%农村信用合作联社%' or loan_bank like'%惠民%农商%'then  '惠民农商行'
when loan_bank like '%德州%农商行%' or loan_bank like'%德州%农村商业%' or loan_bank like'%德州%农村信用合作社%' or loan_bank like'%德州%农村信用合作联社%' or loan_bank like'%德州%农商%'then  '德州农商行'
when loan_bank like '%东港%农商行%' or loan_bank like'%东港%农村商业%' or loan_bank like'%东港%农村信用合作社%' or loan_bank like'%东港%农村信用合作联社%' or loan_bank like'%东港%农商%'then  '东港农商行'
when loan_bank like '%泗水%农商行%' or loan_bank like'%泗水%农村商业%' or loan_bank like'%泗水%农村信用合作社%' or loan_bank like'%泗水%农村信用合作联社%' or loan_bank like'%泗水%农商%'then  '泗水农商行'
when loan_bank like '%临沭%农商行%' or loan_bank like'%临沭%农村商业%' or loan_bank like'%临沭%农村信用合作社%' or loan_bank like'%临沭%农村信用合作联社%' or loan_bank like'%临沭%农商%'then  '临沭农商行'
when loan_bank like '%海阳%农商行%' or loan_bank like'%海阳%农村商业%' or loan_bank like'%海阳%农村信用合作社%' or loan_bank like'%海阳%农村信用合作联社%' or loan_bank like'%海阳%农商%'then  '海阳农商行'
when loan_bank like '%庆云%农商行%' or loan_bank like'%庆云%农村商业%' or loan_bank like'%庆云%农村信用合作社%' or loan_bank like'%庆云%农村信用合作联社%' or loan_bank like'%庆云%农商%'then  '庆云农商行'
when loan_bank like '%鱼台%农商行%' or loan_bank like'%鱼台%农村商业%' or loan_bank like'%鱼台%农村信用合作社%' or loan_bank like'%鱼台%农村信用合作联社%' or loan_bank like'%鱼台%农商%'then  '鱼台农商行'
when loan_bank like '%蓬莱%农商行%' or loan_bank like'%蓬莱%农村商业%' or loan_bank like'%蓬莱%农村信用合作社%' or loan_bank like'%蓬莱%农村信用合作联社%' or loan_bank like'%蓬莱%农商%'then  '蓬莱农商行'
when loan_bank like '%济宁%农商行%' or loan_bank like'%济宁%农村商业%' or loan_bank like'%济宁%农村信用合作社%' or loan_bank like'%济宁%农村信用合作联社%' or loan_bank like'%济宁%农商%'then  '济宁农商行'
when loan_bank like '%宁津%农商行%' or loan_bank like'%宁津%农村商业%' or loan_bank like'%宁津%农村信用合作社%' or loan_bank like'%宁津%农村信用合作联社%' or loan_bank like'%宁津%农商%'then  '宁津农商行'
when loan_bank like '%新泰%农商行%' or loan_bank like'%新泰%农村商业%' or loan_bank like'%新泰%农村信用合作社%' or loan_bank like'%新泰%农村信用合作联社%' or loan_bank like'%新泰%农商%'then  '新泰农商行'
when loan_bank like '%滨州%农商行%' or loan_bank like'%滨州%农村商业%' or loan_bank like'%滨州%农村信用合作社%' or loan_bank like'%滨州%农村信用合作联社%' or loan_bank like'%滨州%农商%'then  '滨州农商行'
when loan_bank like '%威海%农商行%' or loan_bank like'%威海%农村商业%' or loan_bank like'%威海%农村信用合作社%' or loan_bank like'%威海%农村信用合作联社%' or loan_bank like'%威海%农商%'then  '威海农商行'
when loan_bank like '%莒南%农商行%' or loan_bank like'%莒南%农村商业%' or loan_bank like'%莒南%农村信用合作社%' or loan_bank like'%莒南%农村信用合作联社%' or loan_bank like'%莒南%农商%'then  '莒南农商行'
when loan_bank like '%博山%农商行%' or loan_bank like'%博山%农村商业%' or loan_bank like'%博山%农村信用合作社%' or loan_bank like'%博山%农村信用合作联社%' or loan_bank like'%博山%农商%'then  '博山农商行'
when loan_bank like '%周村%农商行%' or loan_bank like'%周村%农村商业%' or loan_bank like'%周村%农村信用合作社%' or loan_bank like'%周村%农村信用合作联社%' or loan_bank like'%周村%农商%'then  '周村农商行'
when loan_bank like '%桓台%农商行%' or loan_bank like'%桓台%农村商业%' or loan_bank like'%桓台%农村信用合作社%' or loan_bank like'%桓台%农村信用合作联社%' or loan_bank like'%桓台%农商%'then  '桓台农商行'
when loan_bank like '%聊城%农商行%' or loan_bank like'%聊城%农村商业%' or loan_bank like'%聊城%农村信用合作社%' or loan_bank like'%聊城%农村信用合作联社%' or loan_bank like'%聊城%农商%'then  '聊城农商行'
when loan_bank like '%泰山%农商行%' or loan_bank like'%泰山%农村商业%' or loan_bank like'%泰山%农村信用合作社%' or loan_bank like'%泰山%农村信用合作联社%' or loan_bank like'%泰山%农商%'then  '泰山农商行'
when loan_bank like '%东阿%农商行%' or loan_bank like'%东阿%农村商业%' or loan_bank like'%东阿%农村信用合作社%' or loan_bank like'%东阿%农村信用合作联社%' or loan_bank like'%东阿%农商%'then  '东阿农商行'
when loan_bank like '%微山%农商行%' or loan_bank like'%微山%农村商业%' or loan_bank like'%微山%农村信用合作社%' or loan_bank like'%微山%农村信用合作联社%' or loan_bank like'%微山%农商%'then  '微山农商行'
when loan_bank like '%长岛%农商行%' or loan_bank like'%长岛%农村商业%' or loan_bank like'%长岛%农村信用合作社%' or loan_bank like'%长岛%农村信用合作联社%' or loan_bank like'%长岛%农商%'then  '长岛农商行'
when loan_bank like '%兰山%农商行%' or loan_bank like'%兰山%农村商业%' or loan_bank like'%兰山%农村信用合作社%' or loan_bank like'%兰山%农村信用合作联社%' or loan_bank like'%兰山%农商%'then  '兰山农商行'
when loan_bank like '%淄川%农商行%' or loan_bank like'%淄川%农村商业%' or loan_bank like'%淄川%农村信用合作社%' or loan_bank like'%淄川%农村信用合作联社%' or loan_bank like'%淄川%农商%'then  '淄川农商行'
when loan_bank like '%单县%农商行%' or loan_bank like'%单县%农村商业%' or loan_bank like'%单县%农村信用合作社%' or loan_bank like'%单县%农村信用合作联社%' or loan_bank like'%单县%农商%'then  '单县农商行'
when loan_bank like '%招远%农商行%' or loan_bank like'%招远%农村商业%' or loan_bank like'%招远%农村信用合作社%' or loan_bank like'%招远%农村信用合作联社%' or loan_bank like'%招远%农商%'then  '招远农商行'
when loan_bank like '%东营%农商行%' or loan_bank like'%东营%农村商业%' or loan_bank like'%东营%农村信用合作社%' or loan_bank like'%东营%农村信用合作联社%' or loan_bank like'%东营%农商%'then  '东营农商行'
when loan_bank like '%罗庄%农商行%' or loan_bank like'%罗庄%农村商业%' or loan_bank like'%罗庄%农村信用合作社%' or loan_bank like'%罗庄%农村信用合作联社%' or loan_bank like'%罗庄%农商%'then  '罗庄农商行'
when loan_bank like '%平阴%农商行%' or loan_bank like'%平阴%农村商业%' or loan_bank like'%平阴%农村信用合作社%' or loan_bank like'%平阴%农村信用合作联社%' or loan_bank like'%平阴%农商%'then  '平阴农商行'
when loan_bank like '%定陶%农商行%' or loan_bank like'%定陶%农村商业%' or loan_bank like'%定陶%农村信用合作社%' or loan_bank like'%定陶%农村信用合作联社%' or loan_bank like'%定陶%农商%'then  '定陶农商行'
when loan_bank like '%济阳%农商行%' or loan_bank like'%济阳%农村商业%' or loan_bank like'%济阳%农村信用合作社%' or loan_bank like'%济阳%农村信用合作联社%' or loan_bank like'%济阳%农商%'then  '济阳农商行'
when loan_bank like '%高唐%农商行%' or loan_bank like'%高唐%农村商业%' or loan_bank like'%高唐%农村信用合作社%' or loan_bank like'%高唐%农村信用合作联社%' or loan_bank like'%高唐%农商%'then  '高唐农商行'
when loan_bank like '%济南%农商行%' or loan_bank like'%济南%农村商业%' or loan_bank like'%济南%农村信用合作社%' or loan_bank like'%济南%农村信用合作联社%' or loan_bank like'%济南%农商%'then  '济南农商行'
when loan_bank like '%张店%农商行%' or loan_bank like'%张店%农村商业%' or loan_bank like'%张店%农村信用合作社%' or loan_bank like'%张店%农村信用合作联社%' or loan_bank like'%张店%农商%'then  '张店农商行'
when loan_bank like '%兖州%农商行%' or loan_bank like'%兖州%农村商业%' or loan_bank like'%兖州%农村信用合作社%' or loan_bank like'%兖州%农村信用合作联社%' or loan_bank like'%兖州%农商%'then  '兖州农商行'
when loan_bank like '%栖霞%农商行%' or loan_bank like'%栖霞%农村商业%' or loan_bank like'%栖霞%农村信用合作社%' or loan_bank like'%栖霞%农村信用合作联社%' or loan_bank like'%栖霞%农商%'then  '栖霞农商行'
when loan_bank like '%烟台%农商行%' or loan_bank like'%烟台%农村商业%' or loan_bank like'%烟台%农村信用合作社%' or loan_bank like'%烟台%农村信用合作联社%' or loan_bank like'%烟台%农商%'then  '烟台农商行'
when loan_bank like '%青岛%农商行'  or loan_bank like'%青岛%农村商业%' or loan_bank like'%青岛%农村信用合作社%' or loan_bank like'%青岛%农村信用合作联社%' or loan_bank like'%青岛%农商%'then  '青岛农商行'
when loan_bank like '%润昌%农商行'  or loan_bank like'%润昌%农村商业%' or loan_bank like'%润昌%农村信用合作社%' or loan_bank like'%润昌%农村信用合作联社%' or loan_bank like'%润昌%农商%'then  '聊城润昌农商行'
else coalesce(b.bank_class,a.loan_bank) end as bank_class
from 
(
	select guar_id,
		case when (a.loan_bank regexp '[0-9a-z]' or loan_bank is null or loan_bank = '') and c.bank_name is not null then c.bank_name 
		else a.loan_bank end as loan_bank
	from dw_base.dwd_guar_info_all a 

	left join 
	(
		select bank_id,bank_name
		from dw_base.dim_bank_info 
		where day_id = '${v_sdate}'
	)c on a.loan_bank = c.bank_id
	where day_id = '${v_sdate}' and item_stt in ('已放款','已解保','已代偿')
)a
left join dw_tmp.tmp_bank_class_code_20231016 b  -- wyx 20231017
on a.guar_id = b.guar_id
;
commit;

delete from dw_base.dwd_sdnd_data_report_guar_tag where day_id = '${v_sdate}';
commit;

insert into dw_base.dwd_sdnd_data_report_guar_tag
( day_id            -- '数据日期'
,project_no         -- '项目编号'
,guar_id            -- '业务编号'
,item_stt           -- '业务状态'
,city_name          -- '城市'
,county_name        -- '区县'
,cust_name          -- '客户名称'
,cert_no            -- '证件号'
,cust_type          -- '客户类型'
,cust_class         -- '客户分类'
,cust_class_type    -- '客户分类划分(上报分类）'
,loan_bank          -- '贷款银行'
,bank_class         -- '银行分类(上报分类)'
,loan_no            -- '借款合同编号'
,loan_amt           -- '借款合同金额'
,loan_cont_beg_dt   -- '借款合同开始日'
,loan_cont_end_dt   -- '借款合同结束日'
,loan_term          -- '担保期限'
,loan_term_type     -- '担保期限划分(上报分类）'
,guar_rate          -- '担保费率'
,loan_rate          -- '贷款利率'
,guar_class         -- '国担分类'
,guar_class_type    -- '国担分类(上报分类）'
,policy_type        -- '按照政策划分(上报分类）'
,bank_duty_rate     -- '担保责任比例'
,guar_cont_no       -- '保证合同编号'
,guar_beg_dt        -- '放款日'
,guar_end_dt        -- '到期日'
,loan_reg_dt        -- '放款登记日'
,is_first_guar      -- '是否首担'
,is_add_curryear    -- '是否本年新增业务'
,is_unguar          -- '是否解保'
,is_unguar_curryear -- '是否今年解保'
,unguar_dt          -- '解保日期'
,is_compt           -- '是否代偿'
,compt_aply_stt     -- '申请代偿状态'
,overdue_days       -- '逾期天数'
,compt_amt          -- '代偿金额'
,compt_dt           -- '代偿日期'
,compt_aply_dt      -- '代偿申请日期'
,origin_code        -- '原业务编号'
,is_fxhj            -- '是否展期业务'
)
select '${v_sdate}' as day_id
       ,t1.project_no
       ,t1.guar_id
       ,t2.item_stt
       ,t2.city_name
       ,t2.county_name
       ,t2.cust_name
       ,t2.cert_no
       ,t2.cust_type
       ,t2.cust_class
       ,case when t2.cust_type = '自然人' then '家庭农场（种养大户）'
			when t2.cust_type is null and left(t2.cert_no,1) = '3' then '家庭农场（种养大户）'
			when (t2.cust_type like '法人%' or (t2.cust_type is null and left(t2.cert_no,1) = '9')) and t2.cust_class regexp '家庭农场' then '家庭农场'
			when (t2.cust_type like '法人%' or (t2.cust_type is null and left(t2.cert_no,1) = '9')) and t2.cust_class regexp  '合作社' then '农民专业合作社'
			when (t2.cust_type like '法人%' or (t2.cust_type is null and left(t2.cert_no,1) = '9')) then '农业企业'
		else t2.cust_class
	    end as cust_class_type -- 需要细化维度到4个
       ,t8.loan_bank
       ,t8.bank_class
       ,t2.loan_no
       ,t2.loan_amt
       ,coalesce(t3.loan_beg_dt,  t2.loan_begin_dt)  as loan_cont_beg_dt -- 借款合同开始/结束时间为空,则取担保年度开始/结束时间
       ,coalesce(t3.loan_end_dt,  t2.loan_end_dt  )  as loan_cont_end_dt
       ,t2.loan_term
       ,case when t2.loan_term < 6 then '6个月以下'
             when t2.loan_term between 6 and 12 or t2.loan_term is null then '6(含)-12个月(含)' -- 为空默认为12个月
             when t2.loan_term > 12 and t2.loan_term <= 36 then '12-36个月(含)'
           else '36个月以上' end as loan_term_type
       ,t2.guar_rate
       ,t2.loan_rate
       ,t2.guar_class
       ,case when t2.guar_class regexp '农产品流通' then '农产品流通（含农产品收购、仓储保鲜、销售等）'
             when t2.guar_class in ('重要特色农产品种植','重要、特色农产品种植') then '特色农产品种植'
			 when t2.guar_class = '农资、农机、农技等社会化服务' then '农资、农机、农技等农业社会化服务'
             when t2.guar_class in ('非农项目','粮食种植','生猪养殖','其他畜牧业','渔业生产','农田建设','农产品初加工','农业新业态', '其他农业项目') then t2.guar_class
             when t2.guar_class is null then '其他农业项目' end as guar_class_type
       ,case when t2.loan_amt between 10 and 300 then '政策性业务：[10-300]'
             when t2.guar_class = '生猪养殖' and t2.loan_amt > 300 and t2.loan_amt <= 1000 then '政策性业务-生猪养殖: (300,1000]'
             when t2.loan_amt < 10 or (t2.guar_class <> '生猪养殖' and t2.loan_amt > 300 and t2.loan_amt <= 1000) then '政策外“双控”业务：<10 and (300,1000]'
             when t2.loan_amt > 1000 then '“双控”外业务：>1000' end as policy_type
       ,case when t9.risk_rate is null or t9.risk_rate not like '%:%' then null 
			when t8.bank_class = '威海市商业银行' and t2.loan_amt <= 50 then 50 -- 威海市商业银行50万元以下(含50万元)的业务，分险比例是50:50
			when t2.guar_prod = '赈灾贷' and t8.bank_class in ('青州农商行','昌乐农商行','临朐农商行','安丘农商行','寿光农商行','诸城农商行','高密农商行','潍坊农商行','昌邑农商行') then 50  -- 这些银行的赈灾贷业务分险比例是50:50
			else SUBSTRING_INDEX(t9.risk_rate,':',-1) end as bank_duty_rate
       ,t2.guar_cnot_no
       ,t2.loan_begin_dt  as guar_beg_dt
       ,t2.loan_end_dt    as guar_end_dt
       ,t1.loan_reg_dt
       ,case when t4.is_first_guar = '0' and is_xz = '0' then '是' 
			else '否' end as is_first_guar -- wyx 20231017
       ,case when t1.loan_reg_dt between concat(year('${v_sdate}'), '0101') and '${v_sdate}' then '1' else '0' end as is_add_curryear
       ,case when t1.item_stt_code = '11' then '1' else '0' end as is_unguar
       ,case when t1.item_stt_code = '11' and (t5.item_stt <> '已解保' or t5.item_stt is null ) then '1' else '0' end as is_unguar_curryear
       ,t1.unguar_dt
       ,case when t6.status = '50' then '1' else '0' end as is_compt
       ,case t6.status when '00' then '申请中'
                       when '10' then '审核中'
                       when '20' then '拨付申请中'
                       when '30' then '拨付审核中'
                       when '40' then '待拨付'
                       when '50' then '已代偿'
                       when '98' then '已终止'
                       when '99' then '已否决' end as compt_aply_stt
        ,timestampdiff(day, t6.overdue_date, '${v_sdate}') as overdue_days
        ,coalesce(t10.compt_amt, t6.overdue_totl) as compt_amt -- “已代偿”外的数据，取逾期合计金额
        ,t10.compt_dt
        ,date_format(t6.submit_time, '%Y%m%d') as compt_aply_dt
        ,t7.origin_code
        ,case when t7.is_fxhj = '1' then '1' else '0' end as is_fxhj
       
       

  from dw_base.dwd_guar_info_stat t1
 inner join dw_base.dwd_guar_info_all t2
    on t1.guar_id = t2.guar_id
  left join 
	(
		select guar_no, loan_beg_dt, loan_end_dt
		from
		(
			select guar_no, loan_beg_dt, loan_end_dt, row_number()over(partition by guar_no order by loan_beg_dt desc) rn
			from dw_base.dwd_guar_cont_info_all
		) t
		where rn = 1
	) t3
    on t1.guar_id = t3.guar_no
  left join dw_base.dwd_guar_tag t4
    on t1.guar_id = t4.guar_id
  left join (select guar_id, item_stt from dw_base.dwd_guar_info_all_his where day_id = concat(left('${v_sdate}',4)-1,'1231') ) t5
    on t1.guar_id = t5.guar_id
  left join (select proj_code, status, submit_time, overdue_date, overdue_totl
               from (select proj_code, status, submit_time, overdue_date, overdue_totl, row_number()over(partition by proj_code order by db_update_time desc, update_time desc ) rn
                       from dw_nd.ods_t_proj_comp_aply
                      where date_format( db_update_time, '%Y%m%d') <= '${v_sdate}'
                      ) a
              where rn = 1 
			) t6
    on t1.guar_id = t6.proj_code
  left join (select code, origin_code, is_fxhj
               from (select code, origin_code, is_fxhj, row_number()over(partition by code order by db_update_time desc, update_time desc ) rn
                       from dw_nd.ods_t_biz_project_main
                      where date_format( db_update_time, '%Y%m%d') <= '${v_sdate}'
                    ) a 
              where rn = 1
			) t7
    on t1.guar_id = t7.code
  left join dw_tmp.tmp_dwd_sdnd_data_report_guar_tag_loan_bank t8
    on t1.guar_id = t8.guar_id
 left join dw_tmp.tmp_bank_nd_risk_20231016 t9 -- 增加担保责任比例  -- wyx 20231017
 on  if(t8.bank_class = '农发行','农业发展银行',t8.bank_class) = t9.bank_name
 left join 
 (
    -- 这个表的代偿数据才是准的
	select guar_id,compt_amt *10000 as compt_amt,compt_time as compt_dt
	from dw_base.dwd_guar_compt_info
	where day_id = '${v_sdate}' and compt_time <= '${v_sdate}'
 )t10 on t10.guar_id = t2.guar_id
 where t2.item_stt in ('已解保','已放款','已代偿') and t2.day_id = '${v_sdate}' and t1.day_id = '${v_sdate}'
   and '${v_sdate}' = date_format(last_day('${v_sdate}'),'%Y%m%d') -- 月底跑批
;
commit;
