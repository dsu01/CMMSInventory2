USE [msDATA]
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_GetAttachmentList]    Script Date: 9/18/2016 10:00:30 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

ALTER PROCEDURE [dbo].[spn_Inv_GetAttachmentList]
(
		@isEquipmentOrFacility bit, -- required
		@parentSysId int
	)
AS
 
IF @isEquipmentOrFacility = 1
	select * from dbo.InvEquipmentAttachment
		where InvEquipmentID = @parentSysId and IsActive = 1
		order by Title
ELSE
	select * from dbo.InvFacilityAttachment
		where InvFacilityID = @parentSysId and IsActive = 1
		order by Title
