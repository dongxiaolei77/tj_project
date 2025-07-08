-- 记录任务执行情况
delete from creditda.data_push where push_date=DATE_FORMAT(STR_TO_DATE('${v_sdate}', '%Y%m%d'), '%Y-%m-%d %H:%i:%s');

insert into creditda.data_push(id, push_date, is_finished, is_tiffinished, is_extracted, is_rewrited, corp_code, priority, biz_type)
select 
null as id,
DATE_FORMAT(STR_TO_DATE('${v_sdate}', '%Y%m%d'), '%Y-%m-%d %H:%i:%s')  as push_date, 
'Y' as is_finished, 
'Y' as is_tiffinished, 
'N' as is_extracted, 
'N' as is_rewrited, 
'9999999' as corp_code, 
NULL as priority, 
'' as biz_type
;
commit;
