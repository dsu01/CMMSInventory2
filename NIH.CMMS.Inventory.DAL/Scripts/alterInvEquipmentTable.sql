USE [msDATA]
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_GetEquipmentAttachmentList]    Script Date: 9/18/2016 10:00:30 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

ALTER TABLE dbo.inve
ADD CKTSUsed varchar(6) NULL 
,VOLTSPRIMARY varchar(20) NULL 
,AMP varchar(20) NULL 
,KVA varchar(20) NULL 
,VOLTSSECONDARY varchar(20) NULL
,VOLTS varchar(20) NULL
,W varchar(6) NULL 
,PH varchar(6) NULL 
,NOofCKTS varchar(6) NULL;  




