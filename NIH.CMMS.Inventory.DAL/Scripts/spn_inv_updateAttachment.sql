USE [msDATA]
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_UpdateEquipment]    Script Date: 9/17/2016 1:55:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[spn_inv_updateAttachment]
	(
		@isEquipmentOrFacility bit, -- required
		@invParentSysID int,		-- required
		@FileName varchar(100),		-- required
		@ContentType nvarchar(200) = null,
		@Data varbinary(max) ,   -- required
		@CreatedOn datetime = getdate,
		@CreatedBy varchar(100) = null,
		@IsActive bit = 1,
		@Title nvarchar(200),
		@ID int OUTPUT,	
		@Res int OUTPUT	
	)
AS
Begin

Set @Res = 0

/* initially, check key fields. If null then, return -1  */	
	if @invParentSysID is null or @FileName is null or @Data  is null
	Begin
		set @Res=-1
		return
	End
			
	if @@error<> 0 GOTO E_Error
			IF @isEquipmentOrFacility = 1
			Begin						
				INSERT INTO [dbo].[InvEquipmentAttachment]
						   ([InvEquipmentID]
						   ,[FileName]
						   ,[ContentType]
						   ,[Data]
						   ,[CreatedOn]
						   ,[CreatedBy]
						   ,[IsActive]
						   ,[Title])
					 VALUES
						   (@invParentSysID
						   ,@FileName
						   ,@ContentType
						   ,@Data
						   ,@CreatedOn
						   ,@CreatedBy
						   ,@IsActive
						   ,@Title
						   )

					-- INSERT as one equipment					   
					SELECT @ID = @@IDENTITY
					If @@error <> 0	GOTO E_Error					
					return				
			End
			ELSE
			Begin						
				INSERT INTO [dbo].[InvFacilityAttachment]
						   ([InvFacilityID]
						   ,[FileName]
						   ,[ContentType]
						   ,[Data]
						   ,[CreatedOn]
						   ,[CreatedBy]
						   ,[IsActive]
						   ,[Title])
					 VALUES
						   (@invParentSysID
						   ,@FileName
						   ,@ContentType
						   ,@Data
						   ,@CreatedOn
						   ,@CreatedBy
						   ,@IsActive
						   ,@Title
						   )

					-- INSERT as one equipment					   
					SELECT @ID = @@IDENTITY
					If @@error <> 0	GOTO E_Error					
					return				
			End--end for insert new			

E_Error:
	print 'Error Happened'
	set @ID = null
    set @Res=@@error	
    return	
End

