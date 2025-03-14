-- ---------------------------------------
-- 开发人   : zhangfl
-- 开发时间 ：20230314
-- 目标表   ：exp_credit_send_reminder_log
-- 源表     ：dw_nd.ods_t_send_reminder_log
--            dw_base.exp_credit_per_compt_info
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------

-- 创建临时表，转换 code 
drop table if exists dw_tmp.tmp_exp_credit_send_reminder_log_code ;
commit;

create table dw_tmp.tmp_exp_credit_send_reminder_log_code (
  `id`               varchar(32),
  `code`             varchar(32)  default null comment '业务编号',
  `project_code`     varchar(32)  default null comment '项目编号',
  `cust_name`        varchar(40)  default null comment '客户姓名',
  `cust_identity_no` varchar(60)  default null comment '身份证号/统一社会信用码',
  `cust_moblie`      varchar(20)  default null comment '客户手机号',
  `content`          varchar(500) default null comment '发送内容',
  `app_id`           varchar(32)  default null comment '调用短信服务的appId',
  `template_code`    varchar(30)  default null comment '短信服务模板code',
  `status`           char(1)      default null comment '发送状态：1-发送中 2-成功  3-失败',
  `business_type`    char(2)      default null comment '业务类型：00-逾期短信提醒 01-代偿短信提醒 02-贴息短信提醒',
  `create_time`      datetime     default null comment '发送时间',
  `update_time`      datetime     default null comment '修改时间',
   send_type         varchar(3)   comment '发送人类别：0无 1借款人（个人） 2借款人（法人） 3反担保人（个人） 4 反担保人（法人） 5 共同借款人',
   all_send_status   varchar(3)   comment '此次业务发送短信全部关联人发送状态 1全部发送 2部分已发送 3全部未发送',
   group_code        varchar(100) comment '区分短信组 业务编号+时间戳',
  index ind_tmp_exp_credit_send_reminder_log_code_id (id)
) ENGINE=InnoDB default CHARSET=utf8mb4 collate=utf8mb4_bin comment='不良短信发送日志临时表';
commit;

insert into dw_tmp.tmp_exp_credit_send_reminder_log_code
select  t1.id
       ,t1.code
       ,case when left(t1.code, 2) = 'DC' then t3.code else t1.code end as project_code -- 代偿数据的code转换为 _main 表的code
       ,t1.cust_name
       ,t1.cust_identity_no
       ,t1.cust_moblie
       ,t1.content
       ,t1.app_id
       ,t1.template_code
       ,t1.status
       ,t1.business_type
       ,t1.create_time
       ,t1.update_time
       ,t1.send_type      
       ,t1.all_send_status
       ,t1.group_code     
  from (select id
              ,code
              ,cust_name
              ,cust_identity_no
              ,cust_moblie
              ,content
              ,app_id
              ,template_code
              ,status
              ,business_type
              ,create_time
              ,update_time
              ,send_type      
              ,all_send_status
              ,group_code     
          from (select id
                       ,code
                       ,cust_name
                       ,cust_identity_no
                       ,cust_moblie
                       ,content
                       ,app_id
                       ,template_code
                       ,status
                       ,business_type
                       ,create_time
                       ,update_time
                       ,send_type      
                       ,all_send_status
                       ,group_code
                       ,row_number() over (partition by id order by create_time desc) rn
                  from dw_nd.ods_t_send_reminder_log 
				  -- where business_type = '01' -- 代偿前发送短信
              ) a where rn = 1
      ) t1
  left join (select project_id, code from (select project_id, code,row_number() over (partition by code order by db_update_time desc, update_time desc) rn from dw_nd.ods_t_proj_comp_aply) a where rn = 1) t2 -- 代偿申请
    on t2.code = t1.code
  left join (select id, code from (select id, code,row_number() over (partition by id order by db_update_time desc, update_time desc) rn from dw_nd.ods_t_biz_project_main) a where rn = 1) t3  -- 项目表
    on t3.id = t2.project_id
;
commit;
  

truncate table dw_base.exp_credit_send_reminder_log;
commit;

insert into dw_base.exp_credit_send_reminder_log 
(id
 ,code              -- 业务编号
 ,cust_name         -- 客户姓名
 ,cust_identity_no  -- 身份证号/统一社会信用码
 ,cust_id           -- 客户号
 ,cust_moblie       -- 客户手机号
 ,content           -- 发送内容
 ,app_id            -- 调用短信服务的appId
 ,template_code     -- 短信服务模板code
 ,status            -- 发送状态：1-发送中 2-成功  3-失败
 ,business_type     -- 业务类型：00-逾期短信提醒 01-代偿短信提醒 02-贴息短信提醒
 ,is_per_compt      -- 是否个人代偿报送客户，1是0否
 ,create_time       -- 发送时间
 ,update_time       -- 修改时间
 ,send_type         -- 发送人类别：0无 1借款人（个人） 2借款人（法人） 3反担保人（个人） 4 反担保人（法人） 5 共同借款人
 ,all_send_status   -- 此次业务发送短信全部关联人发送状态 1全部发送 2部分已发送 3全部未发送
 ,group_code        -- 区分短信组 业务编号+时间戳
)
select  t1.id
       ,t1.project_code
       ,t1.cust_name
       ,t1.cust_identity_no
       ,coalesce(t2.cust_id,t3.cust_id)cust_id
       ,t1.cust_moblie
       ,t1.content
       ,t1.app_id
       ,t1.template_code
       ,t1.status
       ,t1.business_type
       ,case when t2.ln_id is not null then '1' else '0' end as is_per_compt
       ,t1.create_time
       ,t1.update_time
       ,t1.send_type      
       ,t1.all_send_status
       ,t1.group_code     
  from dw_tmp.tmp_exp_credit_send_reminder_log_code t1
  left join (select ln_id, cust_id from dw_base.exp_credit_per_compt_info group by ln_id, cust_id) t2
    on t1.project_code = t2.ln_id
  left join (select distinct cert_no,cust_id from dw_base.dwd_guar_info_all )t3
    on t1.cust_identity_no = t3.cert_no
;
commit;

-- 考虑到推送任务已切换到星环，未避免mysql和星环同步运行期间产生 同时推送，现注释改脚本推送内容 20241012

-- 导入征信系统
delete from dw_pbc.exp_credit_send_reminder_log where business_type = '01'; commit;
commit;

insert into dw_pbc.exp_credit_send_reminder_log
select 
id
,code              -- 业务编号
,cust_name         -- 客户姓名
,cust_identity_no  -- 身份证号/统一社会信用码
,cust_id           -- 客户号
,cust_moblie       -- 客户手机号
,content           -- 发送内容
,app_id            -- 调用短信服务的appId
,template_code     -- 短信服务模板code
,status            -- 发送状态：1-发送中 2-成功  3-失败
,business_type     -- 业务类型：00-逾期短信提醒 01-代偿短信提醒 02-贴息短信提醒
,is_per_compt      -- 是否个人代偿报送客户，1是0否
,create_time       -- 发送时间
,update_time       -- 修改时间
,send_type         -- 发送人类别：0无 1借款人（个人） 2借款人（法人） 3反担保人（个人） 4 反担保人（法人） 5 共同借款人
,all_send_status   -- 此次业务发送短信全部关联人发送状态 1全部发送 2部分已发送 3全部未发送
,group_code        -- 区分短信组 业务编号+时间戳
from dw_base.exp_credit_send_reminder_log
where business_type = '01'
;
commit;