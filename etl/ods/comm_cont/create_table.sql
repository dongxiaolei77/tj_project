

CREATE TABLE dw_nd.`ods_comm_cont_comm_contract_account_info` (
  `ID` varchar(30)  COMMENT '主键',
  `USER_NAME` varchar(64)  COMMENT '用户名',
  `ID_CARD_NO` varchar(32)  COMMENT '用户身份证',
  `SOCIAL_CREDIT_CODE` varchar(19)  COMMENT '统一社会信用代码',
  `COMPANY_NAME` varchar(32)  COMMENT '公司名称',
  `USER_CODE` varchar(100)  COMMENT 'E签宝注册用的信息',
  `ACCOUNT_ID` varchar(200)  COMMENT '第三方账号/机构号',
  `TYPE` char(1)  COMMENT '类型 1-个人 2-机构',
  `TEMPLATE_SEAL_ID` varchar(200)  COMMENT '模板章',
  `IMAGE_SEAL_ID` varchar(200)  COMMENT '图片章',
  `SIGN_AUTH` char(1)  COMMENT '静默签署 0-否  1-是',
  `IS_CERT` char(1)  COMMENT '是否申领证书 0-否 1-是',
  `CREATE_TIME` datetime ,
  `UPDATE_TIME` datetime ,
   KEY idx_ods_comm_cont_comm_contract_account_info_id (`ID`) USING BTREE,
   KEY idx_ods_comm_cont_comm_contract_account_info_user_code (`USER_CODE`) USING BTREE
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin  COMMENT ='合同账户映射表'
;commit;


CREATE TABLE dw_nd.`ods_comm_cont_comm_contract_detail` (
  `ID` varchar(64)  COMMENT '主键',
  `CONTRACT_ID` varchar(64)  COMMENT '合同主表ID',
  `PARAM_KEY` varchar(100)  COMMENT '参数名',
  `PARAM_VAL` varchar(2000)  COMMENT '参数值',
  `PARAM_DESC` varchar(200)  COMMENT '参数描述',
  `CREATE_TIME` datetime ,
  `UPDATE_TIME` datetime ,
   KEY idx_ods_comm_cont_comm_contract_detail_id (`ID`) USING BTREE,
   KEY `idx_ods_comm_cont_comm_contract_detail_CONTRACT_ID` (`CONTRACT_ID`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin  COMMENT ='合同详情表'
;commit;


CREATE TABLE dw_nd.`ods_comm_cont_comm_contract_offline_info` (
  `id` bigint(20)  ,
  `channel` varchar(255)   COMMENT '渠道(来源哪个系统)',
  `fileid` varchar(128)   COMMENT '文件id',
  `file_name` varchar(128)   COMMENT '文件名称',
  `doc_type` varchar(255)   COMMENT '文档类型',
  `cust_id` varchar(32)   COMMENT '用户编号',
  `create_name` varchar(32)  ,
  `create_time` datetime ,
  `update_name` varchar(32)  ,
  `update_time` datetime ,
  `creator` varchar(32)  ,
  `updator` varchar(32)  ,
  `biz_id` varchar(64)   COMMENT '业务编号',
   KEY idx_ods_comm_cont_comm_contract_offline_info_id (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin  
;commit;


CREATE TABLE dw_nd.`ods_comm_cont_comm_contract_seal` (
  `ID` varchar(64)  COMMENT '主键',
  `LESSEE_ID` varchar(32)  COMMENT '租户号(合作方编号)',
  `SOCIAL_CODE` varchar(64)  COMMENT '社会统一信用代码',
  `PRODUCT_CODE` varchar(32)  COMMENT '产品编号',
  `TEMPLATE_TYPE` char(2)  COMMENT '合同类型',
  `CONTRACT_TEMPLATE_ID` varchar(64)  COMMENT '合同模板ID',
  `SEAL_PARTY` char(1)  COMMENT '1：甲 2：乙',
  `FILE_ID` varchar(64)  COMMENT '文件服务器ID',
  `SEAL_POSITION_X` varchar(16)  COMMENT '盖章位置X轴',
  `SEAL_POSITION_Y` varchar(16) COMMENT '盖章位置Y轴',
  `PAGE_NO` int(11)  COMMENT '盖章页',
  `SEAL_IMG_SIZE` int(11) COMMENT '图片大小',
  `MAIN_TEXT` varchar(32)  COMMENT '印章主内容',
  `MAIN_TEXT_BOLD` tinyint(1)  COMMENT '字体是否加粗0：否 1：是',
  `MAIN_MARGIN_SIZE` int(4) COMMENT '印章主内容边距',
  `MAIN_FONT_FAMILY` varchar(16) COMMENT '印章主内容字体',
  `MAIN_FONT_SIZE` int(4) COMMENT '印章主内容字体大小',
  `MAIN_FONT_SPACE` double COMMENT '印章主内容空间',
  `CENTER_TEXT` varchar(32) COMMENT '印章中心内容',
  `CENTER_TEXT_BOLD` tinyint(1)  COMMENT '中心字体是否加粗0：否 1：是',
  `CENTER_MARGIN_SIZE` int(4)  COMMENT '印章中心内容边距',
  `CENTER_FONT_FAMILY` varchar(16)  COMMENT '印章中心内容字体',
  `CENTER_FONT_SIZE` int(4) COMMENT '印章中心内容字体大小',
  `CENTER_FONT_SPACE` double COMMENT '印章中心内容空间',
  `TITLE_TEXT` varchar(32)  COMMENT '印章标题内容',
  `TITLE_TEXT_BOLD` tinyint(1) COMMENT '标题字体是否加粗0：否 1：是',
  `TITLE_MARGIN_SIZE` int(4) COMMENT '印章标题内容边距',
  `TITLE_FONT_FAMILY` varchar(16) COMMENT '印章标题内容字体',
  `TITLE_FONT_SIZE` int(4) COMMENT '印章标题内容字体大小',
  `TITLE_FONT_SPACE` double COMMENT '印章标题内容空间',
  `VICE_TEXT` varchar(32)  COMMENT '印章标题内容',
  `VICE_TEXT_BOLD` tinyint(1)  COMMENT '标题字体是否加粗0：否 1：是',
  `VICE_MARGIN_SIZE` int(4)  COMMENT '印章副标题内容边距',
  `VICE_FONT_FAMILY` varchar(16) COMMENT '印章副标题内容字体',
  `VICE_FONT_SIZE` int(4)  COMMENT '印章副标题内容字体大小',
  `VICE_FONT_SPACE` double COMMENT '印章副标题内容空间',
  `SEAL_LINE_SIZE` int(4) COMMENT '印章边线粗细',
  `SEAL_LINE_WIDTH` int(4) COMMENT '印章边线半径(宽度)',
  `SEAL_LINE_HEITHT` int(4) COMMENT '印章边线半径(高度)',
  `CREATE_TIME` datetime  COMMENT '创建时间',
  `UPDATE_TIME` datetime  COMMENT '更新时间',
  `POSITION_KEY_WORD` varchar(32)  COMMENT '合同盖章位置关键字（不要小于7个字）',
   KEY idx_ods_comm_cont_comm_contract_seal_id (`ID`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin  
;commit;



CREATE TABLE dw_nd.`ods_comm_cont_comm_contract_template_info` (
  `ID` varchar(30)  COMMENT '主键ID',
  `TEMPLATE_CONTRACT_NO_RULE` varchar(30)  COMMENT '合同模板生成规则',
  `LESSEE_ID` varchar(30)  COMMENT '租户编号',
  `CONTRACT_MAIN` varchar(30)  COMMENT '合同主体',
  `PRODUCT_CODE` varchar(60)  COMMENT '产品编号',
  `TEMPLATE_NAME` varchar(100)  COMMENT '模板名称',
  `TEMPLATE_TYPE` char(2)  COMMENT '模板类型 10-产品开通协议 11-用户代扣授权协议 12-用户授权协议 13-资金方支用协议',
  `FILE_ID` varchar(200)  COMMENT '文件ID',
  `FILE_NAME` varchar(200)  COMMENT '文件名称',
  `SEAL_TYPE` char(1)  COMMENT '签章类型 0-无章签署 1-有章签署',
  `STEP` char(2)   COMMENT '步骤：1-授信，2-支用，12-实名，13-绑卡，14-开户，15-其他,16-关闭账号',
  `PARAMETER` varchar(1024)  COMMENT '合同参数',
  `SIGNERS_SUM` int(2)   COMMENT '签约人数，用于校验合同签署人',
  `REMARK` varchar(200)  COMMENT '备注',
  `STATUS` int(2)  COMMENT '状态 1-正常 2-废弃',
  `CREATE_USER` varchar(200) ,
  `CREATE_TIME` datetime ,
  `UPDATE_USER` varchar(200) ,
  `UPDATE_TIME` datetime ,
   KEY idx_ods_comm_cont_comm_contract_template_info_id (`ID`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin  
;commit;



CREATE TABLE dw_nd.`ods_comm_cont_comm_contract_third_info` (
  `id` bigint(20)   COMMENT '主键',
  `bank_code` varchar(32)   COMMENT '渠道',
  `doc_type` varchar(2)   COMMENT '文档类型',
  `app_id` varchar(64)   COMMENT '三方合同id(额度申请单号或者支用合同id)',
  `fileid` varchar(128)   COMMENT '文件id',
  `file_name` varchar(128)   COMMENT '文件名称',
  `cust_id` varchar(32)   COMMENT '用户编号(身份证号)',
  `create_name` varchar(32)   COMMENT '创建人',
  `create_time` datetime  COMMENT '创建时间',
  `update_name` varchar(32)   COMMENT '更新人',
  `update_time` datetime  COMMENT '更新时间',
  `creator` varchar(32)  ,
  `updator` varchar(32)  ,
  `biz_id` varchar(64)  ,
   KEY idx_ods_comm_cont_comm_contract_third_info_id (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin  
;commit;


