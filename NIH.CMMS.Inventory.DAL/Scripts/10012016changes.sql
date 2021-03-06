USE [msDATA]
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_UpdateElectricalComponent_newSite]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Alter Procedure [dbo].[spn_inv_UpdateElectricalComponent_newSite]
	(
		@EquipmentID varchar(50),		-- required - in table InvEquipment  - could be changed - update individually -  no more insert....
		@EquipmentLocation varchar(50),
		@TypeorUse varchar(50),			-- reference to spn_Inv_GetSystemEquipmentList_Mechanical or spn_Inv_GetSystemEquipmentList_electrical
		@Manufacturer varchar(50),
		@ModelNo varchar(50),
		@SerialNo varchar(50),
		@Size varchar(50),
		@InstallDate datetime,
		
		@VOLTS varchar(20),
		@AMP varchar(20),
		@KVA varchar(20),
		@VOLTSprimary varchar(20),
		@VOLTSSecondary varchar(20),
		@PH varchar(6),
		@W varchar(6),
		@NOofCKTS varchar(6),
		@CKTSUsed varchar(6),
		@ElectricalOther varchar(50),
		
		@BSLClassification varchar(50),
		@TJCValue int,
		@PMSchedule varchar(50),
								
		@UserName varchar(50),			-- required
		
		@FacilityNo varchar(50),	-- parent facility no required
		@Res int OUTPUT,
		@EquipmentNo varchar(50),		-- new column here - additional component ID
		
		@EquipmentSerial int,			-- no need to change
		--@ID int output,				-- dbo.invEquipment table ID column - 	no need to output
		@ID int,
		
		@NewStatus varchar (20)		-- new column here -- to update status that comes from invStatus table	
		
	)
AS
Begin

Set @Res = 0


/* initially, check key fields. If null then, return -1  */	
	if @id is null or @EquipmentID is null or @FacilityNo is null or @EquipmentSerial  is null or @UserName is null or @typeoruse is null 
	Begin
		set @Res=-1
		return
	End
		
	--select @EquipmentSystem = SystemTitle, @EquipmentGroup = SystemGroup
	--from dbo.InvFacilitySystem where SystemTitle = @TypeorUse and SystemGroup = 'Mechanical Equipment%'
	--if @@error<> 0 GOTO E_Error
	
	If @NewStatus is null set @NewStatus = 'Active'
	
	UPDATE dbo.InvEquipment SET					
					    EquipmentID = @EquipmentID,
						Location = @EquipmentLocation,
						[EquipmentSystem] = @TypeorUse,
--						[EquipmentGroup] = 'Electrical Equipment',
						[ModifiedBy]=@UserName,
						[ModifiedDate]=getdate(),
						
						TypeorUse = @TypeorUse,
						Manufacturer = @Manufacturer,
						Model = @ModelNo,
						SerialNo = @SerialNo,
						[Size] = @Size,
						InstallDate = @InstallDate,
						
						VOLTS = @VOLTS,
						AMP = @AMP,
						KVA = @KVA,
						VOLTSprimary = @VOLTSprimary,
						VOLTSSecondary = @VOLTSSecondary,
						PH= @PH,
						W = @W,
						NOofCKTS = @NOofCKTS,
						CKTSUsed = @CKTSUsed,
						ElectricalOther = @ElectricalOther,
						
						BSLClassification = @BSLClassification,
						TJCValue = @TJCValue,
						PMSchedule = @PMSchedule,
						
						EquipmentFacility# = @FacilityNo + @EquipmentID,
						Status = @NewStatus,			-- new column update.
						EquipmentNo = @equipmentNo		-- new column update				
					WHERE ID=@ID
					
					If @@error <> 0	GOTO E_Error
                                      			
                    return                    				
E_Error:

    set @Res=@@error
    return	
End
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_GetEquipmentList]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Alter Procedure [dbo].[spn_Inv_GetEquipmentList]
(
		@FacilityNum varchar(50)
	)
AS
 
select InvEquipment.*
from dbo.InvEquipment
where ParentFacility#=@FacilityNum
order by EquipmentSerialNo
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_AddMechanicalComponent_NewSite ]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* spn_inv_AddMechanicalComponent_NewSite 
**	on CMMS/Asset inventory Web site, create a new Mechanical Component Facility into table invEquipment after its Parents are created.
	It only accepts component columns. like 25 detail columns on Inventory Card, which will be saved into invFacility.
	
**	Parameter: FacilitySystem, ...etc
	Return: Facility#
**	return values as @RES: 0 means successfully; - 1 means missing paras. otherwise, @@error as SQL Server error number
*/


Alter Procedure [dbo].[spn_inv_AddMechanicalComponent_NewSite ]
	(
		@EquipmentID varchar(50),		-- required - the Facility# for each component
		@EquipmentLocation varchar(50),
		@TypeorUse varchar(50),			-- required - equipmentSystem in invEquipment table 
		@Manufacturer varchar(50),
		@ModelNo varchar(50),
		@SerialNo varchar(50),
		@Size varchar(50),
		@InstallDate date,
		@Capacity varchar(50),
		@CapacityHeadTest varchar(50),
		@FuelRefrigeration varchar(50),
		@MotorManufacturer varchar(50),
		@HP varchar(50),
		@MotorType varchar(50),
		@MotorSerialNo varchar(50),
		@MotorInstallDate date,
		@MotorModel varchar(50),
		@Frame varchar(50),
		@RPM varchar(50),
		@Voltage varchar(50),
		@Amperes varchar(50),
		@PhaseCycle varchar(50),
		@BSLClassification varchar(50),
		@TJCValue int,
		@PMSchedule varchar(50),
				
		@UserName varchar(50),				-- required - for InputBy
		@inventoryby varchar(50),			-- recommendation
		@inventoryDate Datetime,			-- recommendation
		@FacilityNo varchar(50),			-- required from table invFaciity - System fac# to keep as the parents between invFacility and invEquipment
		@Res int OUTPUT,
		@EquipmentNO varchar(50)			-- new column	
	)
AS
declare @Count as int
Declare @NextSeq as int

set @Count = 0
Set @NextSeq = 1
Set @Res = 0

	/* initially, check key fields. If null then, return -1  */	
	if @EquipmentID is null or @TypeorUse is null or @UserName is null or @FacilityNo is null
	Begin
		set @Res=-1
		return
	End
	
	/* second, find out if duplicate components associated with this FacilityNo */
	select @count = COUNT(*)
	from dbo.InvEquipment 
	where ParentFacility# = @facilityNo and Status = 'Active' and EquipmentFacility# = @EquipmentID
	
	if @@error<> 0 GOTO E_Error
		
	if @Count > 0
	Begin
		set @Res=-1
		return
	End
	
	/* Third, find out the next Seq number for components associated with this FacilityNo */
	select @NextSeq = isnull(max(EquipmentSerialNo), 0) + 1
	from dbo.InvEquipment 
	where ParentFacility# = @facilityNo
	
	if @@error<> 0 GOTO E_Error
		

	/*Finally, create a Mechical Equipment*/
	
--	exec [dbo].[spn_inv_AddEquipment] @EquipmentID = @EquipmentID, @EquipmentLocation = @EquipmentLocation, @TypeorUse = @TypeorUse,
--		@Manufacturer = @Manufacturer, 	@ModelNo = @ModelNo, @SerialNo = @SerialNo, @Size = @Size, @InstallDate = @InstallDate,
--		@Capacity = @Capacity, 	@CapacityHeadTest= @CapacityHeadTest, @FuelRefrigeration = @FuelRefrigeration, 
--		@MotorManufacturer = @MotorManufacturer, @HP = @HP, @MotorType = @MotorType, @MotorSerialNo=@MotorSerialNo,
--		@MotorInstallDate = @MotorInstallDate, @MotorModel=@MotorModel, @Frame = @Frame, @RPM = @RPM, @Voltage = @Voltage,
--		@Amperes = @Amperes,	@PhaseCycle=@PhaseCycle, @BSLClassification = @BSLClassification, @TJCValue = @TJCValue,
--		@PMSchedule = @PMSchedule, @UserName = @UserName, @ParentFacilityNo = @FacilityNo, @EquipmentSerial = 1, @res = @res OUTPUT
		
		
	Insert into	dbo.InvEquipment([ParentFacility#],[EquipmentGroup],[EquipmentSystem],[EquipmentID],[location],[TypeorUse],
           [Manufacturer],[Model],[SerialNo],[Size],[InstallDate],[Capacity],[CapacityHeadTest],[FuelRefrigeration],[MotorManufacturer],
           [HP],[MotorType],[MotorSerialNo],[MotorInstallDate],[MotorModel],[Frame],[RPM],[Voltage],[Amperes],[PhaseCycle],[BSLClassification],
           [TJCValue],[PMSchedule],[inputBy], [EquipmentSerialNo], inventoryby, inventoryDate, EquipmentNo)
	VALUES
           (@FacilityNo,'Mechanical Equipment',@TypeorUse, @EquipmentID,@EquipmentLocation,@TypeorUse,@Manufacturer,
           @ModelNo,@SerialNo,@Size,@InstallDate,@Capacity,@CapacityHeadTest,
           @FuelRefrigeration, @MotorManufacturer, @HP, @MotorType,@MotorSerialNo, @MotorInstallDate, @MotorModel, @Frame, @RPM, @Voltage,
           @Amperes,@PhaseCycle, @BSLClassification,@TJCValue,@PMSchedule, @UserName, @NextSeq, @inventoryby, @inventoryDate, @EquipmentNO)
           
		If @@error <> 0	GOTO E_Error
		
		return
	
E_Error:
    set @Res=@@error
    return
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_DeactivateInvEquipment]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Alter Procedure [dbo].[spn_Inv_DeactivateInvEquipment]
(
		@ID int,
		@UserName varchar(50),
		@Res int OUTPUT		
	)
AS

Begin

	Set @Res = 0

	UPDATE dbo.InvEquipment 
	SET	Status='Inactive', ModifiedDate=getdate(), ModifiedBy=@UserName
	WHERE ID=@ID
	if @@error<> 0 GOTO E_Error                                      	
 return
    
	
E_Error:
    set @Res=@@error
    return	
End
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_GetInvEquipmentDetail]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Alter Procedure [dbo].[spn_Inv_GetInvEquipmentDetail]
(
		@ID int
	)
AS
 
select InvEquipment.*
from dbo.InvEquipment
where ID=@ID
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_UpdateMechanicalComponent_newSite]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Alter Procedure [dbo].[spn_inv_UpdateMechanicalComponent_newSite]
	(
		@EquipmentID varchar(50),		-- required - in table InvEquipment  - could be changed - update individually -  no more insert....
		@EquipmentLocation varchar(50),
		@TypeorUse varchar(50),			-- key reference from spn_Inv_GetSystemEquipmentList_Mechanical or spn_Inv_GetSystemEquipmentList_electrical
		@Manufacturer varchar(50),
		@ModelNo varchar(50),
		@SerialNo varchar(50),
		@Size varchar(50),
		@InstallDate datetime,
		@Capacity varchar(50),
		@CapacityHeadTest varchar(50),
		@FuelRefrigeration varchar(50),
		@MotorManufacturer varchar(50),
		@HP varchar(50),
		@MotorType varchar(50),
		@MotorSerialNo varchar(50),
		@MotorInstallDate datetime,
		@MotorModel varchar(50),
		@Frame varchar(50),
		@RPM varchar(50),
		@Voltage varchar(50),
		@Amperes varchar(50),
		@PhaseCycle varchar(50),
		@BSLClassification varchar(50),
		@TJCValue int,
		@PMSchedule varchar(50),						
		@UserName varchar(50),			-- required
		@FacilityNo varchar(50),	--ParentFacilityNo required
		@EquipmentSerial int,			-- no need to change
		--@ID int output,				-- dbo.invEquipment table ID column - 	no need to output
		@ID int,
		@Res int OUTPUT,
		@NewStatus varchar (20),		-- new column here -- to update status that comes from invStatus table	
		@EquipmentNo varchar(50)		-- new column here - additional component ID
	)
AS
Begin
--declare @EquipmentGroup as varchar(50)

--declare @EquipmentSystem as varchar(50)

Set @Res = 0


/* initially, check key fields. If null then, return -1  */	
	if @id is null or @EquipmentID is null or @FacilityNo is null or @EquipmentSerial  is null or @UserName is null or @typeoruse is null 
	Begin
		set @Res=-1
		return
	End
		
	--select @EquipmentSystem = SystemTitle, @EquipmentGroup = SystemGroup
	--from dbo.InvFacilitySystem where SystemTitle = @TypeorUse and SystemGroup = 'Mechanical Equipment%'
	--if @@error<> 0 GOTO E_Error
	
	If @NewStatus is null set @NewStatus = 'Active'
	
	/* no need to do insert - Zhong - 9/26/2016
	IF (@ID = -1)
		Begin -- begin for insert
			Declare @maxSerial as int
			Select @maxSerial=max(EquipmentSerialNo) from InvEquipment where ParentFacility#=@ParentFacilityNo
			
			if @maxSerial is null set @EquipmentSerial = 1
			else set @EquipmentSerial = @maxSerial + 1
					
					-- INSERT as one equipment
					Insert into	dbo.InvEquipment([ParentFacility#],[EquipmentSystem],[EquipmentGroup],[EquipmentID],[location],[TypeorUse],
						   [Manufacturer],[Model],[SerialNo],[Size],[InstallDate],[Capacity],[CapacityHeadTest],[FuelRefrigeration],[MotorManufacturer],
						   [HP],[MotorType],[MotorSerialNo],[MotorInstallDate],[MotorModel],[Frame],[RPM],[Voltage],[Amperes],[PhaseCycle],[BSLClassification],
						   [TJCValue],[PMSchedule],[ModifiedBy], [EquipmentSerialNo],ModifiedDate, EquipmentFacility#)
					VALUES
					   (@ParentFacilityNo,@EquipmentSystem,@EquipmentGroup,@EquipmentID,@EquipmentLocation,@TypeorUse,@Manufacturer,
					   @ModelNo,@SerialNo,@Size,@InstallDate,@Capacity,@CapacityHeadTest,
					   @FuelRefrigeration, @MotorManufacturer, @HP, @MotorType,@MotorSerialNo, @MotorInstallDate, @MotorModel, @Frame, @RPM, @Voltage,
					   @Amperes,@PhaseCycle, @BSLClassification,@TJCValue,@PMSchedule, @UserName, @EquipmentSerial,getdate(), @ParentFacilityNo+@EquipmentID)
					   --GET THE IDENTITY VALUE
					   
					SELECT @ID = @@IDENTITY
					If @@error <> 0	GOTO E_Error
					
					return
				
		End--end for insert new
	Else
	*/
--		Begin-- begin for update			
			
					UPDATE dbo.InvEquipment SET					
					    EquipmentID = @EquipmentID,
						Location = @EquipmentLocation,
						[EquipmentSystem] = @TypeorUse,
--						[EquipmentGroup] = 'Mechanical Equipment',
						[ModifiedBy]=@UserName,
						[ModifiedDate]=getdate(),
						
						TypeorUse = @TypeorUse,
						Manufacturer = @Manufacturer,
						Model = @ModelNo,
						SerialNo = @SerialNo,
						[Size] = @Size,
						InstallDate = @InstallDate,
						Capacity = @Capacity,
						CapacityHeadTest= @CapacityHeadTest,
						FuelRefrigeration = @FuelRefrigeration,
						MotorManufacturer = @MotorManufacturer,
						HP = @HP,
						MotorType = @MotorType,
						MotorSerialNo=@MotorSerialNo, 
						MotorInstallDate = @MotorInstallDate,
						MotorModel=@MotorModel,
						Frame = @Frame,
						RPM = @RPM,
						Voltage = @Voltage,
						Amperes = @Amperes,
						PhaseCycle=@PhaseCycle,
						BSLClassification = @BSLClassification,
						TJCValue = @TJCValue,
						PMSchedule = @PMSchedule,
						
						EquipmentFacility# = @FacilityNo + @EquipmentID,
						Status = @NewStatus,			-- new column update.
						EquipmentNo = @EquipmentNo		-- new column update.
					WHERE ID=@ID
					
					If @@error <> 0	GOTO E_Error
                                      			
                    return                    				
					            
--		End -- end for update
	
E_Error:
-- @EquipmentSerial = null
    set @Res=@@error
    return	
End
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_AddElectricalComponent_NewSite]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* spn_inv_AddElectricalComponent_NewSite 
**	on CMMS/Asset inventory Web site, create a new Electrical Component, Facility into table invEquipment after its Parents are created.
	It only accepts component columns on Inventory Card.
	
**	Parameter: FacilitySystem, ...etc
	Return: Facility#
**	return values as @RES: 0 means successfully; - 1 means missing paras. otherwise, @@error as SQL Server error number
*/


Alter Procedure [dbo].[spn_inv_AddElectricalComponent_NewSite]
	(
		@EquipmentID varchar(50),		-- required - the Facility# for each component
		@EquipmentLocation varchar(50),
		@TypeorUse varchar(50),			-- required - [EquipmentSystem] column in invEquipment
		@Manufacturer varchar(50),
		@ModelNo varchar(50),
		@SerialNo varchar(50),
		@Size varchar(50),
		@InstallDate date,
		
		@VOLTS varchar(20),
		@AMP varchar(20),
		@KVA varchar(20),
		@VOLTSprimary varchar(20),
		@VOLTSSecondary varchar(20),
		@PH varchar(6),
		@W varchar(6),
		@NOofCKTS varchar(6),
		@CKTSUsed varchar(6),
		@ElectricalOther varchar(50),
		
		@BSLClassification varchar(50),
		@TJCValue int,
		@PMSchedule varchar(50),
				
		@UserName varchar(50),				-- required - for InputBy
		@FacilityNo varchar(50),			-- required from table invFaciity - System fac# to keep as the parents between invFacility and invEquipment
		@Res int OUTPUT, 
			
		@EquipmentNO varchar(50),			-- new column
		
		@inventoryby varchar(50),			-- recommendation
		@inventoryDate Datetime,		-- recommendation
		@ID_table int OUTPUT
	)
AS
declare @Count as int
Declare @NextSeq as int

set @Count = 0
Set @NextSeq = 1
Set @Res = 0

	/* initially, check key fields. If null then, return -1  */	
	if @EquipmentID is null or @TypeorUse is null or @UserName is null or @FacilityNo is null
	Begin
		set @Res=-1
		return
	End
	
	/* second, find out if duplicate components associated with this FacilityNo */
	select @count = COUNT(*)
	from dbo.InvEquipment 
	where ParentFacility# = @facilityNo and Status = 'Active' and EquipmentId = @EquipmentID
	
	if @@error<> 0 GOTO E_Error
		
	if @Count > 0
	Begin
		set @Res=-1
		return
	End
	
	/* Third, find out the next Seq number for components associated with this FacilityNo */
	select @NextSeq = isnull(max(EquipmentSerialNo), 0) + 1
	from dbo.InvEquipment 
	where ParentFacility# = @facilityNo
	
	if @@error<> 0 GOTO E_Error
		
	/*Finally, create a Electrical Equipment*/
		
	Insert into	dbo.InvEquipment([ParentFacility#],[EquipmentGroup],[EquipmentSystem],[EquipmentID],[location],[TypeorUse],
           [Manufacturer],[Model],[SerialNo],[Size],[InstallDate],
           ElectricalOther,[VOLTS],[AMP],[KVA],[VOLTSprimary],[VOLTSSecondary],[PH],[W],[NOofCKTS],[CKTSUsed],
           [inputBy], [EquipmentSerialNo], inventoryby, inventoryDate,[BSLClassification],
           [TJCValue],[PMSchedule], [equipmentNo])
	VALUES
           (@FacilityNo,'Electrical Equipment',@TypeorUse, @EquipmentID,@EquipmentLocation,@TypeorUse,@Manufacturer,
					@ModelNo,@SerialNo,@Size,@InstallDate,
					@ElectricalOther,@VOLTS,@AMP,@KVA,@VOLTSprimary,@VOLTSSecondary,@PH,@W,@NOofCKTS,@CKTSUsed,
					@UserName, @NextSeq, @inventoryby, @inventoryDate,@BSLClassification,@TJCValue,@PMSchedule, @equipmentNo)
            SELECT @ID_table = @@IDENTITY
		If @@error <> 0	GOTO E_Error
		
		return
	
E_Error:
    set @Res=@@error
    return
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_UpdateSystem_MechanicalElectrical-Regular_newsite]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Alter Procedure [dbo].[spn_inv_UpdateSystem_MechanicalElectrical-Regular_newsite]
	(
		@System varchar(50),			-- required - by invFacilitySystem table - SystemGroup = 'Mechanical System' - could be new one
		@Comments varchar(255),
		@Building varchar(50),			-- required
		@Floor varchar(20),			
		@FacilityLocation varchar(50),	-- required
		@FacilityID varchar(50),		-- required - not the FacilityNo
		@WorkRequestNo varchar(50),
		@Function varchar(50),
		@BSL smallint,					-- default 0
		@AAALAC smallint,				-- default 0
		@TJC smallint,					-- default 0
				
		@UserName varchar(50),			-- required		
		@FacilityNo varchar(50),		-- existing Facility# for regular user without change -- required
		@Status	 varchar(50),			-- new or existing - required
		@TableID int,					-- required - table invFacility ID
		@Res int OUTPUT			
	)
AS
Begin
--declare @FacilityGroup as varchar(50)
--declare @FacilityNoexisting as varchar(50)
declare @statusexisting as varchar(50)
declare @Property as varchar(50)
--declare @countFacility as int

--declare @equipmentid as varchar(50)
declare @TableID2 as int
declare @equipmentstatusexisting as varchar(50)
--declare @typeoruse as varchar(50)
--declare @parentfacilitynoexisting as varchar(50)
--declare @return int

--set @return = 0
Set @Res = 0
--Set @countFacility = 0

	/* initially, check key fields. If null then, return -1  */	
	
--	-- verify the null or duplicate of FAC#
--	select @countFacility = COUNT(Facility#)
--	from dbo.InvFacility 
--	where Facility#  = @FacilityNo and ID <> @TableID
	
--	if @@error<> 0 GOTO E_Error
	
	if @Building is null or @System is null or @FacilityLocation is null or	@FacilityID is null or @FacilityNo is null 
	Begin
		set @Res=-1
		return
	End
	
	if @status is null set @status = 'Active'

	
	-- verify the existing FAC# to avoid from T0003 to T0004
	select @statusexisting = Status
	from dbo.InvFacility where  ID = @TableID
	
	if @@error<> 0 GOTO E_Error

/*	
	if left(@FacilityNo, 1) = 'T' and left(@FacilityNoexisting, 1) = 'T' and @FacilityNo <> @FacilityNoexisting 
	Begin
		set @Res=-1
		return
	End

	-- verify the existing FAC# to avoid from 11111 to T0005
	if left(@FacilityNo, 1) = 'T' and left(@FacilityNoexisting, 1) <> 'T' 
	Begin
		set @Res=-1
		return
	End
*/	
	if @BSL is null set @BSL = 0
	if @TJC is null set @TJC = 0
	if @AAALAC is null set @BSL = 0
		
	-- if building changes, then property needs to be changeed
	select @Property = [Property]
	from dbo.InvBuilding where Building = @Building and Active = -1
	
	if @@error<> 0 GOTO E_Error
	
--	select @FacilityGroup = SystemGroup
--	from dbo.InvFacilitySystem where SystemTitle = @System and IsParent = -1
	
--	if @@error<> 0 GOTO E_Error
	
--	if @FacilityGroup is null 
--	begin
--		select @FacilityGroup = SystemGroup
--		from dbo.InvFacilitySystem where SystemTitle = @System and IsParent = 0
--	end

--	if @@error<> 0 GOTO E_Error
	
	-- begin for update	facility
	UPDATE dbo.InvFacility SET
--						[Facility#]	= @FacilityNo,		-- regular user not to change the FacilityNo
					    [WorkRequest#] = @WorkRequestNo,
					    [FacilitySystem] = @System,
--					    [FacilityGroup] = @FacilityGroup,
					    [FacilityFunction] = @Function,	
						[FacilityID] = @FacilityID,					   
					    [Comments] = @Comments,					   
					    [Property] = @Property,
						[Building] = @Building, 						
						[Floor] = @Floor,
						[Location] = @FacilityLocation,
						[BSL] = @BSL,
						[AAALAC]= @AAALAC,
						[TJC] = @TJC,
						[UpdateBy]=@UserName,
						[UpdateDate]=getdate(),
						[status] = @Status
					WHERE id = @TableID
					
	If @@error <> 0	GOTO E_Error					
				
	-- began cursor to update components  - because the FacilityNo and Status could be updated.
	
	if @statusexisting = @Status return  -- no need to update components
	
		
		DECLARE Equipment_cursor CURSOR FOR 
		SELECT  status, ID
		FROM dbo.InvEquipment
		WHERE parentfacility# = @facilityNo
	
		OPEN Equipment_cursor 

		FETCH NEXT FROM Equipment_cursor
		INTO @equipmentstatusexisting, @TABLEID2
	
		WHILE @@FETCH_STATUS = 0
			BEGIN				
				if @status <> 'Active' and @equipmentstatusexisting = 'Active'
					begin 
						UPDATE dbo.InvEquipment SET					
								[ModifiedBy]=@UserName,
								[ModifiedDate]=getdate(),
								Status = @status
						WHERE ID=@tableid2
			
						if @@error<> 0 GOTO E_Error								
					end	
						
				FETCH NEXT FROM Equipment_cursor
				INTO @equipmentstatusexisting, @tableid2

			END

		CLOSE Equipment_cursor 
		DEALLOCATE Equipment_cursor 
		
	return
			
E_Error:
    set @Res=@@error
    return	
End
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_UpdateSystem_MechanicalElectrical-Admin_newsite]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Alter Procedure [dbo].[spn_inv_UpdateSystem_MechanicalElectrical-Admin_newsite]
	(
		@System varchar(50),			-- required - by invFacilitySystem table - SystemGroup = 'Mechanical System'
		@Comments varchar(255),
		@Building varchar(50),			-- required
		@Floor varchar(20),			
		@FacilityLocation varchar(50),	-- required
		@FacilityID varchar(50),		-- required - not the FacilityNo
		@WorkRequestNo varchar(50),
		@Function varchar(50),
		@BSL smallint,					-- default 0
		@AAALAC smallint,				-- default 0
		@TJC smallint,					-- default 0
				
		@UserName varchar(50),			-- required		
		@FacilityNo varchar(50),		-- New by admin/super user - existing Facility# for regular user without no change -- required
		@Status	 varchar(50),			-- new or existing - required
		@TableID int,					-- required - table invFacility ID
		@Res int OUTPUT			
	)
AS
Begin
declare @FacilityGroup as varchar(50)
declare @FacilityNoexisting as varchar(50)
declare @statusexisting as varchar(50)
declare @Property as varchar(50)
declare @countFacility as int

declare @equipmentid as varchar(50)
declare @TableID2 as int
declare @equipmentstatusexisting as varchar(50)
--declare @typeoruse as varchar(50)
declare @parentfacilitynoexisting as varchar(50)
declare @return int

set @return = 0
Set @Res = 0
Set @countFacility = 0

	/* initially, check key fields. If null then, return -1  */	
	
	-- verify the null or duplicate of FAC#
	select @countFacility = COUNT(Facility#)
	from dbo.InvFacility 
	where Facility#  = @FacilityNo and ID <> @TableID
	
	if @@error<> 0 GOTO E_Error
	
	if @Building is null or @System is null or @FacilityLocation is null or	@FacilityID is null 
		or @countFacility > 0 or @FacilityNo is null 
	Begin
		set @Res=-1
		return
	End
	
	if @status is null set @status = 'Active'
	
	-- verify the existing FAC# to avoid from T0003 to T0004
	select @FacilityNoexisting = facility#, @statusexisting = Status
	from dbo.InvFacility where  ID = @TableID
	
	if @@error<> 0 GOTO E_Error
	
	if left(@FacilityNo, 1) = 'T' and left(@FacilityNoexisting, 1) = 'T' and @FacilityNo <> @FacilityNoexisting 
	Begin
		set @Res=-1
		return
	End

	-- verify the existing FAC# to avoid from 11111 to T0005
	if left(@FacilityNo, 1) = 'T' and left(@FacilityNoexisting, 1) <> 'T' 
	Begin
		set @Res=-1
		return
	End
	
	if @BSL is null set @BSL = 0
	if @TJC is null set @TJC = 0
	if @AAALAC is null set @BSL = 0
		
	-- if building changes, then property needs to be changeed
	select @Property = [Property]
	from dbo.InvBuilding where Building = @Building and Active = -1
	
	if @@error<> 0 GOTO E_Error
	
--	select @FacilityGroup = SystemGroup
--	from dbo.InvFacilitySystem where SystemTitle = @System and IsParent = -1
	
--	if @@error<> 0 GOTO E_Error
	
--	if @FacilityGroup is null 
--	begin
--		select @FacilityGroup = SystemGroup
--		from dbo.InvFacilitySystem where SystemTitle = @System and IsParent = 0
--	end

--	if @@error<> 0 GOTO E_Error
	
	-- begin for update	facility
	UPDATE dbo.InvFacility SET
						[Facility#]	= @FacilityNo,
					    [WorkRequest#] = @WorkRequestNo,
					    [FacilitySystem] = @System,
	--				    [FacilityGroup] = @FacilityGroup,
					    [FacilityFunction] = @Function,	
						[FacilityID] = @FacilityID,					   
					    [Comments] = @Comments,					   
					    [Property] = @Property,
						[Building] = @Building, 						
						[Floor] = @Floor,
						[Location] = @FacilityLocation,
						[BSL] = @BSL,
						[AAALAC]= @AAALAC,
						[TJC] = @TJC,
						[UpdateBy]=@UserName,
						[UpdateDate]=getdate(),
						[status] = @Status
					WHERE id = @TableID
					
	If @@error <> 0	GOTO E_Error					
				
	-- began cursor to update components  - because the FacilityNo and Status could be updated.
	
	if @FacilityNo = @FacilityNoexisting and @statusexisting = @Status return  -- no need to update components
	
		
		DECLARE Equipment_cursor CURSOR FOR 
		SELECT  equipmentid, ParentFacility#, status, ID
		FROM dbo.InvEquipment
		WHERE parentfacility# = @FacilityNoExisting
	
		OPEN Equipment_cursor 

		FETCH NEXT FROM Equipment_cursor
		INTO @equipmentid, @parentfacilitynoexisting, @equipmentstatusexisting, @TABLEID2
	
		WHILE @@FETCH_STATUS = 0
			BEGIN				
--			-- call spn_inv_UpdateFacility_Admin
--				exec [dbo].[spn_inv_Updateequipment_Admin] @equipmentid,@typeoruse,@username, @facilityno, @TableID2, @status, @return
			
				if @FacilityNo = @FacilityNoexisting 
					begin
						if @status <> 'Active' and @equipmentstatusexisting = 'Active'
							begin 
								UPDATE dbo.InvEquipment SET					
									[ModifiedBy]=@UserName,
									[ModifiedDate]=getdate(),
									Status = @status
								WHERE ID=@tableid2
			
								if @@error<> 0 GOTO E_Error								
							end
					end	
				else				
					begin
						UPDATE dbo.InvEquipment SET					
							[ModifiedBy]=@UserName,
							[ModifiedDate]=getdate(),
							EquipmentFacility# = @FacilityNo + @EquipmentID,
							Status = case when status = 'Active' then @status else status end,
							ParentFacility# = @FacilityNo
						WHERE ID=@tableid2
			
						if @@error<> 0 GOTO E_Error
								
					end
					
				FETCH NEXT FROM Equipment_cursor
				INTO @equipmentid, @parentfacilitynoexisting, @equipmentstatusexisting, @tableid2

			END

		CLOSE Equipment_cursor 
		DEALLOCATE Equipment_cursor 
		
	return
			
E_Error:
    set @Res=@@error
    return	
End
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_UpdateMechanicalEquipment_newSite]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Alter Procedure [dbo].[spn_inv_UpdateMechanicalEquipment_newSite]
	(
		@FacilitySystem varchar(50),		-- required, from table invFacilitySystem after user selects.
		@Comments varchar(255),
		@Building varchar(50),			-- required
		@Floor varchar(20),			
		@FacilityLocation varchar(50),	-- required
		@FacilityID varchar(50),		-- required - not the Facility#
		@WorkRequestNo varchar(50),
		@Function varchar(50),
		@BSL smallint,				-- default 0
		@AAALAC smallint,			-- default 0
		@TJC smallint,				-- default 0
		
		--@EquipmentID varchar(50),		-- required - no need on individual Equipment level
		--@EquipmentLocation varchar(50),
		--@TypeorUse varchar(50),			-- reference to spn_Inv_GetSystemEquipmentList_Mechanical or spn_Inv_GetSystemEquipmentList_electrical
		@Manufacturer varchar(50),
		@ModelNo varchar(50),
		@SerialNo varchar(50),
		@Size varchar(50),
		@InstallDate datetime,
		@Capacity varchar(50),
		@CapacityHeadTest varchar(50),
		@FuelRefrigeration varchar(50),
		@MotorManufacturer varchar(50),
		@HP varchar(50),
		@MotorType varchar(50),
		@MotorSerialNo varchar(50),
		@MotorInstallDate datetime,
		@MotorModel varchar(50),
		@Frame varchar(50),
		@RPM varchar(50),
		@Voltage varchar(50),
		@Amperes varchar(50),
		@PhaseCycle varchar(50),
		@BSLClassification varchar(50),
		@TJCValue int,
		@PMSchedule varchar(50),	
					
		@UserName varchar(50),				-- required
		@FacilityNo varchar(50),			-- required - could change too
		
		@ID_table int,						-- invFacility table ID - to only update invFacility
		@Res int OUTPUT,		
		@Status varchar (20)				-- new column here -- to update status that comes from invStatus table	
	)
AS
Begin

declare @systemtitle as varchar(50) 
declare @FacilityNoexisting as varchar(50) 
declare @StatusExisting as varchar(50) 
declare @property as varchar(50) 

declare @count as int

if @BSL is null set @BSL = 0
if @TJC is null set @TJC = 0
if @AAALAC is null set @BSL = 0

Set @Res = 0
If @Status is null set @Status = 'Active'

/* initially, check key fields. If null then, return -1  */	
	if @facilityid is null or @FacilityNo is null or @UserName is null or @ID_table is null or @FacilitySystem is null	
	Begin
		set @Res=-1
		return
	End
	
	select @Property = [Property]
	from dbo.InvBuilding where Building = @Building and Active = -1
	
	if @@error<> 0 GOTO E_Error
	
--	select SystemTitle = @systemtitle
--	from dbo.InvFacilitySystem where id = @facilitySystemID
	
--	if @@error<> 0 GOTO E_Error	
	
	
	/* second, find out if duplicate fac# associated */
	select @count = COUNT(*)
	from dbo.invFacility 
	where Facility# = @facilityNo 
			
	if @@error<> 0 GOTO E_Error
		
	if @Count > 0
	Begin
		set @Res=-1
		return
	End

	
	-- verify the existing FAC# to avoid from T0003 to T0004
	select @FacilityNoexisting = facility#, @statusexisting = Status
	from dbo.InvFacility where  ID = ID
	
	if @@error<> 0 GOTO E_Error
	
	if left(@FacilityNo, 1) = 'T' and left(@FacilityNoexisting, 1) = 'T' and @FacilityNo <> @FacilityNoexisting 
	Begin
		set @Res=-1
		return
	End

	-- verify the existing FAC# to avoid from 11111 to T0005
	if left(@FacilityNo, 1) = 'T' and left(@FacilityNoexisting, 1) <> 'T' 
	Begin
		set @Res=-1
		return
	End
		UPDATE dbo.InvFacility SET
						[Facility#]	= @FacilityNo,
					    [WorkRequest#] = @WorkRequestNo,
						[FacilitySystem] = @systemtitle,
	--				    [FacilityGroup] = 'Mechanical Equipment'
					    [FacilityFunction] = @Function,	
						[FacilityID] = @FacilityID,					   
					    [Comments] = @Comments,					   
					    [Property] = @Property,
						[Building] = @Building, 						
						[Floor] = @Floor,
						[Location] = @FacilityLocation,
						[BSL] = @BSL,
						[AAALAC]= @AAALAC,
						[TJC] = @TJC,
						[UpdateBy]=@UserName,
						[UpdateDate]=getdate(),
						[status] = @Status,		
--					    EquipmentID = @EquipmentID,
--						TypeorUse = @TypeorUse,
						Manufacturer = @Manufacturer,
						Model = @ModelNo,
						SerialNo = @SerialNo,
						[Size] = @Size,
						InstallDate = @InstallDate,
						Capacity = @Capacity,
						CapacityHeadTest= @CapacityHeadTest,
						FuelRefrigeration = @FuelRefrigeration,
						MotorManufacturer = @MotorManufacturer,
						HP = @HP,
						MotorType = @MotorType,
						MotorSerialNo=@MotorSerialNo, 
						MotorInstallDate = @MotorInstallDate,
						MotorModel=@MotorModel,
						Frame = @Frame,
						RPM = @RPM,
						Voltage = @Voltage,
						Amperes = @Amperes,
						PhaseCycle=@PhaseCycle,
						
						BSLClassification = @BSLClassification,
						TJCValue = @TJCValue,
						PMSchedule = @PMSchedule						
										
					WHERE ID =@ID_table
                                      			
             return
                    				
E_Error:

    set @Res=@@error
    return	
End
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_UpdateFacility_Admin]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Alter Procedure [dbo].[spn_inv_UpdateFacility_Admin]
	(
		@System varchar(50),			-- required
		@Comments varchar(255),
		@Building varchar(50),			-- required
		@Floor varchar(20),			
		@FacilityLocation varchar(50),	-- required
		@FacilityID varchar(50),		-- required
		@WorkRequestNo varchar(50),
		@Function varchar(50),
		@BSL smallint,				-- default 0
		@AAALAC smallint,			-- default 0
		@TJC smallint,				-- default 0		
		@UserName varchar(50),			-- required		
		@FacilityNo varchar(50),		-- New or existing Facility# -- required		
		@Status	 varchar(50),		-- new or existing - required
		@TableID int,		-- required - tbale invFacility ID
		@Res int OUTPUT			
	)
AS
Begin
declare @FacilityGroup as varchar(50)
declare @FacilityNoexisting as varchar(50)
declare @Property as varchar(50)
declare @countFacility as int


declare @equipmentid as varchar(50)
declare @TableID2 as int
declare @statusexisting as varchar(50)
declare @typeoruse as varchar(50)
declare @parentfacilitynoexisting as varchar(50)
declare @return int

set @return = 0
Set @Res = 0
Set @countFacility = 0

	/* initially, check key fields. If null then, return -1  */	
	
	-- verify the null or duplicate of FAC#
	select @countFacility = COUNT(Facility#)
	from dbo.InvFacility where Facility#  = @FacilityNo and ID <> @TableID
	
	if @@error<> 0 GOTO E_Error
	
	if @Building is null or @System is null or @FacilityLocation is null or 
		@FacilityID is null or @countFacility > 0 or @FacilityNo is null or
		@Status is null
	Begin
		set @Res=-1
		return
	End
	
	-- verify the existing FAC# to avoid from T0003 to T0004
	select @FacilityNoexisting = facility#
	from dbo.InvFacility where  ID = @TableID
	
	if @@error<> 0 GOTO E_Error
	
	if left(@FacilityNo, 1) = 'T' and left(@FacilityNoexisting, 1) = 'T' 
			and @FacilityNo <> @FacilityNoexisting 
	Begin
		set @Res=-1
		return
	End

	-- verify the existing FAC# to avoid from 11111 to T0005
	if left(@FacilityNo, 1) = 'T' and left(@FacilityNoexisting, 1) <> 'T' 
	Begin
		set @Res=-1
		return
	End

	
	if @BSL is null set @BSL = 0
	if @TJC is null set @TJC = 0
	if @AAALAC is null set @BSL = 0
		
	select @Property = [Property]
	from dbo.InvBuilding where Building = @Building and Active = -1
	
	if @@error<> 0 GOTO E_Error
	
	select @FacilityGroup = SystemGroup
	from dbo.InvFacilitySystem where SystemTitle = @System and IsParent = -1
	
	if @@error<> 0 GOTO E_Error
	
	if @FacilityGroup is null 
	begin
		select @FacilityGroup = SystemGroup
		from dbo.InvFacilitySystem where SystemTitle = @System and IsParent = 0
	end

	if @@error<> 0 GOTO E_Error
	
	-- begin for update	facility
	UPDATE dbo.InvFacility SET
						[Facility#]	= @FacilityNo,
					    [WorkRequest#] = @WorkRequestNo,
					    [FacilitySystem] = @System,
					    [FacilityGroup] = @FacilityGroup,
					    [FacilityFunction] = @Function,	
						[FacilityID] = @FacilityID,					   
					    [Comments] = @Comments,					   
					    [Property] = @Property,
						[Building] = @Building, 						
						[Floor] = @Floor,
						[Location] = @FacilityLocation,
						[BSL] = @BSL,
						[AAALAC]= @AAALAC,
						[TJC] = @TJC,
						[UpdateBy]=@UserName,
						[UpdateDate]=getdate(),
						[status] = @Status
					WHERE id = @TableID
					
	If @@error <> 0	GOTO E_Error					
				
	-- began cursor to update equipment
	
	if @FacilityNo = @FacilityNoexisting and @statusexisting = @Status return
	
		
		DECLARE Equipment_cursor CURSOR FOR 
		SELECT  Equipmentid, typeoruse, ParentFacility#, status, ID
		FROM dbo.InvEquipment
		WHERE parentfacility# = @FacilityNoExisting
	
		OPEN Equipment_cursor 

		FETCH NEXT FROM Equipment_cursor
		INTO @equipmentid, @typeoruse, @parentfacilitynoexisting, @statusexisting, @TABLEID2
	
		WHILE @@FETCH_STATUS = 0
			BEGIN
	
			-- call spn_inv_UpdateFacility_Admin
				exec [dbo].[spn_inv_Updateequipment_Admin] @equipmentid,@typeoruse,@username, @facilityno, @TableID2, @status, @return
				
				FETCH NEXT FROM Equipment_cursor
				INTO @equipmentid, @typeoruse, @parentfacilitynoexisting, @statusexisting, @tableid2

			END

		CLOSE Equipment_cursor 
		DEALLOCATE Equipment_cursor 
		
	return
			
E_Error:
    set @Res=@@error
    return	
End
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_UpdateFacility]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Alter Procedure [dbo].[spn_inv_UpdateFacility]
	(
		@System varchar(50),		-- required
		@Comments varchar(255),
		@Building varchar(50),		-- required
		@Floor varchar(20),			
		@FacilityLocation varchar(50),		-- required
		@FacilityID varchar(50),		-- required
		@WorkRequestNo varchar(50),
		@Function varchar(50),
		@BSL smallint,				-- default 0
		@AAALAC smallint,			-- default 0
		@TJC smallint,				-- default 0
		@EquipmentID varchar(50),
		@EquipmentLocation varchar(50),
		@TypeorUse varchar(50),
		@Manufacturer varchar(50),
		@ModelNo varchar(50),
		@SerialNo varchar(50),
		@Size varchar(50),
		@InstallDate datetime,
		@Capacity varchar(50),
		@CapacityHeadTest varchar(50),
		@FuelRefrigeration varchar(50),
		@MotorManufacturer varchar(50),
		@HP varchar(50),
		@MotorType varchar(50),
		@MotorSerialNo varchar(50),
		@MotorInstallDate datetime,
		@MotorModel varchar(50),
		@Frame varchar(50),
		@RPM varchar(50),
		@Voltage varchar(50),
		@Amperes varchar(50),
		@PhaseCycle varchar(50),
		@BSLClassification varchar(50),
		@TJCValue int,
		@PMSchedule varchar(50),				
		@UserName varchar(50),		-- required		
		
		@FacilityNo varchar(50) OUTPUT,  -- change on 3/22/11	
		@ID int OUTPUT,  -- change on 3/22/11
		@Res int OUTPUT		
	)
AS
Begin
declare @FacilityGroup as varchar(50)
declare @iden as int
declare @Property as varchar(50)
declare @countFacility as int

set @iden = 0
Set @Res = 0

	/* initially, check key fields. If null then, return -1  */	
	if @Building is null or @System is null or @FacilityLocation is null or @FacilityID is null
	Begin
		set @FacilityNo = null
		set @Res=-1
		return
	End

	-- verify the null or duplicate of FAC#
	if @FacilityNo <> ''
	begin
		select @countFacility = COUNT(Facility#)
		from dbo.InvFacility where Facility#  = @FacilityNo 
	
		if @@error<> 0 GOTO E_Error
		
		if @countFacility = 0 or @countFacility > 1 
		Begin
			set @FacilityNo = null
			set @Res=-1
			return
		end
	End	

	if @BSL is null set @BSL = 0
	if @TJC is null set @TJC = 0	
	if @AAALAC is null set @AAALAC = 0

	select @Property = [Property]
	from dbo.InvBuilding where Building = @Building
	
	if @@error<> 0 GOTO E_Error
	
	select @FacilityGroup = SystemGroup
	from dbo.InvFacilitySystem where SystemTitle = @System and IsParent = -1
	
	if @@error<> 0 GOTO E_Error
	
	if @FacilityGroup is null 
	begin
		select @FacilityGroup = SystemGroup
		from dbo.InvFacilitySystem where SystemTitle = @System and IsParent = 0
	end


	if @@error<> 0 GOTO E_Error

	
		
		IF (@ID = -1)
		Begin -- begin for insert
			set @iden = IDENT_CURRENT('invFacility')+1
			-- the first time facility# is a temp number
			set @FacilityNo = 'T' + RIGHT(Convert(varchar(6),100000+@iden), 5)

			if @EquipmentID is null	
				begin
					-- INSERT as one facility
					Insert into	dbo.InvFacility([WorkRequest#],[Facility#],[Facility#Temp],[FacilitySystem],[FacilityGroup],[FacilityFunction],
					   [FacilityID],[Comments],[Property],[Building],[Floor],[Location],[BSL],[AAALAC],[TJC],[TypeorUse],
					   [Manufacturer],[Model],[SerialNo],[Size],[InstallDate],[Capacity],[CapacityHeadTest],[FuelRefrigeration],[MotorManufacturer],
					   [HP],[MotorType],[MotorSerialNo],[MotorInstallDate],[MotorModel],[Frame],[RPM],[Voltage],[Amperes],[PhaseCycle],[BSLClassification],
					   [TJCValue],[PMSchedule],[InputBy],[InputDate])
					VALUES
					   ( @WorkRequestNo,@FacilityNo,@FacilityNo,@System,@FacilityGroup,@Function,@FacilityID, @Comments, @Property, @Building,
					   @Floor,@FacilityLocation,@BSL,@AAALAC,@TJC,@TypeorUse,@Manufacturer,@ModelNo,@SerialNo,@Size,@InstallDate,@Capacity,@CapacityHeadTest,
					   @FuelRefrigeration, @MotorManufacturer, @HP, @MotorType,@MotorSerialNo, @MotorInstallDate, @MotorModel, @Frame, @RPM, @Voltage,
					   @Amperes,@PhaseCycle, @BSLClassification,@TJCValue,@PMSchedule, @UserName, getdate())
			        SELECT @ID = @@IDENTITY
 
					If @@error <> 0	GOTO E_Error
					
					return
				End
			Else
				Begin
					-- INSERT as parent
					Insert into	dbo.InvFacility([WorkRequest#],[Facility#],[Facility#Temp],[FacilitySystem],[FacilityGroup],[FacilityFunction],
						   [FacilityID],[Comments],[Property],[Building],[Floor],[Location],[BSL],[AAALAC],[TJC],[InputBy],[InputDate])
					VALUES(@WorkRequestNo,@FacilityNo,@FacilityNo,@System,@FacilityGroup,@Function,@FacilityID, @Comments, @Property, @Building,
						   @Floor,@FacilityLocation,@BSL,@AAALAC,@TJC,@UserName, getdate())
					 SELECT @ID = @@IDENTITY
					If @@error <> 0	GOTO E_Error
					
					return
				End
		End--end for insert new
	Else
		Begin-- begin for update			
			if @EquipmentID is not null	
				Begin -- begin of update parent					
					UPDATE dbo.InvFacility SET					
					    [WorkRequest#] = @WorkRequestNo,
					    [FacilitySystem] = @System,
					    [FacilityGroup] = @FacilityGroup,
					    [FacilityFunction] = @Function,	
						[FacilityID] = @FacilityID,					   
					    [Comments] = @Comments,					   
					    [Property] = @Property,
						[Building] = @Building, 						
						[Floor] = @Floor,
						[Location] = @FacilityLocation,
						[BSL] = @BSL,
						[AAALAC]= @AAALAC,
						[TJC] = @TJC,
						[UpdateBy]=@UserName,
						[UpdateDate]=getdate()
					WHERE [ID] = @ID
					If @@error <> 0	GOTO E_Error					
					return
				End	-- end of update parent facility info		
			else
				Begin-- begin of update full detail
					UPDATE dbo.InvFacility SET					
					    [WorkRequest#] = @WorkRequestNo,
					    [FacilitySystem] = @System,
					    [FacilityGroup] = @FacilityGroup,
					    [FacilityFunction] = @Function,	
						[FacilityID] = @FacilityID,					   
					    [Comments] = @Comments,					   
					    [Property] = @Property,
						[Building] = @Building, 						
						[Floor] = @Floor,
						[Location] = @FacilityLocation,
						[BSL] = @BSL,
						[AAALAC]= @AAALAC,
						[TJC] = @TJC,
						[UpdateBy]=@UserName,
						[UpdateDate]=getdate(),

						TypeorUse = @TypeorUse,
						Manufacturer = @Manufacturer,
						Model = @ModelNo,
						SerialNo = @SerialNo,
						[Size] = @Size,
						InstallDate = @InstallDate,
						Capacity = @Capacity,
						CapacityHeadTest= @CapacityHeadTest,
						FuelRefrigeration = @FuelRefrigeration,
						MotorManufacturer = @MotorManufacturer,
						HP = @HP,
						MotorType = @MotorType,
						MotorSerialNo=@MotorSerialNo, 
						MotorInstallDate = @MotorInstallDate,
						MotorModel=@MotorModel,
						Frame = @Frame,
						RPM = @RPM,
						Voltage = @Voltage,
						Amperes = @Amperes,
						PhaseCycle=@PhaseCycle,
						BSLClassification = @BSLClassification,
						TJCValue = @TJCValue,
						PMSchedule = @PMSchedule
					WHERE [ID] = @ID
					If @@error <> 0	GOTO E_Error					
					return			
				End -- End of update full detail               
		End -- end for update
		
	
	
E_Error:
	set @FacilityNo = null
	set @ID = -1
    set @Res=@@error
    return	
End

--	exec [dbo].[spn_inv_AddEquipment] @EquipmentID = @EquipmentID, @EquipmentLocation = @EquipmentLocation, @TypeorUse = @TypeorUse,
--		@Manufacturer = @Manufacturer, 	@ModelNo = @ModelNo, @SerialNo = @SerialNo, @Size = @Size, @InstallDate = @InstallDate,
--		@Capacity = @Capacity, 	@CapacityHeadTest= @CapacityHeadTest, @FuelRefrigeration = @FuelRefrigeration, 
--		@MotorManufacturer = @MotorManufacturer, @HP = @HP, @MotorType = @MotorType, @MotorSerialNo=@MotorSerialNo,
--		@MotorInstallDate = @MotorInstallDate, @MotorModel=@MotorModel, @Frame = @Frame, @RPM = @RPM, @Voltage = @Voltage,
--		@Amperes = @Amperes,	@PhaseCycle=@PhaseCycle, @BSLClassification = @BSLClassification, @TJCValue = @TJCValue,
--		@PMSchedule = @PMSchedule, @UserName = @UserName, @ParentFacilityNo = @FacilityNo, @EquipmentSerial = 1, @res = @res OUTPUT
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_updateEquipmentAttachment]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Alter Procedure [dbo].[spn_inv_updateEquipmentAttachment]
	(
		@invEquipmentID int,		-- required
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
declare @EquipmentGroup as varchar(50)

declare @EquipmentSystem as varchar(50)

Set @Res = 0


/* initially, check key fields. If null then, return -1  */	
	if @invEquipmentID is null or @FileName is null or @Data  is null
	Begin
		set @Res=-1
		return
	End
			
	if @@error<> 0 GOTO E_Error

			-- logic only for inserts
			Begin -- begin for insert\			
						
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
						   (@invEquipmentID
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
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_UpdateEquipment_admin_delete]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Alter Procedure [dbo].[spn_inv_UpdateEquipment_admin_delete]
	(
		@EquipmentID varchar(50),		-- required, could be new or existing
		@TypeorUse varchar(50),			-- reference to spn_Inv_GetSystemEquipmentList_Mechanical or spn_Inv_GetSystemEquipmentList_electrical
		@UserName varchar(50),			-- required
		@ParentFacilityNo varchar(50),	-- required, could be new or existing
		@ID int,						--required, table invEqipment ID
		@status varchar(50),			--required, could be new or existing
		@Res int OUTPUT		
	
	)
AS
Begin
declare @EquipmentGroup as varchar(50)
declare @EquipmentSystem as varchar(50)

Set @Res = 0

	/* initially, check key fields. If null then, return -1  */	
	if @EquipmentID is null or @ParentFacilityNo is null or @UserName is null or @ID is null or @status is null	
	Begin
		set @Res=-1
		return
	End
		
	select @EquipmentSystem = SystemTitle, @EquipmentGroup = SystemGroup
	from dbo.InvFacilitySystem where SystemTitle = @TypeorUse and SystemGroup = '%Equipment%'
	
	if @@error<> 0 GOTO E_Error

	-- begin for update	invEquipment record	
	
	if @EquipmentSystem is null
		begin			
			UPDATE dbo.InvEquipment SET					
					    EquipmentID = @EquipmentID,						
						[ModifiedBy]=@UserName,
						[ModifiedDate]=getdate(),
						TypeorUse = @TypeorUse,
						EquipmentFacility# = @ParentFacilityNo + @EquipmentID,
						Status = @status,
						ParentFacility# = @ParentFacilityNo
			WHERE ID=@ID
			
			if @@error<> 0 GOTO E_Error
                                      			
			return
			
		end
		
    UPDATE dbo.InvEquipment SET					
					    EquipmentID = @EquipmentID,
					    [EquipmentSystem] = @EquipmentSystem,
						[EquipmentGroup] = @EquipmentGroup,						
						[ModifiedBy]=@UserName,
						[ModifiedDate]=getdate(),
						TypeorUse = @TypeorUse,
						EquipmentFacility# = @ParentFacilityNo + @EquipmentID,
						Status = @status,
						ParentFacility# = @ParentFacilityNo
			WHERE ID=@ID
			
	if @@error<> 0 GOTO E_Error
                                      			
	return
	-- end for update
	
E_Error:
    set @Res=@@error
    return	
End
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_UpdateEquipment]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Alter Procedure [dbo].[spn_inv_UpdateEquipment]
	(
		@EquipmentID varchar(50),		-- required
		@EquipmentLocation varchar(50),
		@TypeorUse varchar(50),			-- reference to spn_Inv_GetSystemEquipmentList_Mechanical or spn_Inv_GetSystemEquipmentList_electrical
		@Manufacturer varchar(50),
		@ModelNo varchar(50),
		@SerialNo varchar(50),
		@Size varchar(50),
		@InstallDate datetime,
		@Capacity varchar(50),
		@CapacityHeadTest varchar(50),
		@FuelRefrigeration varchar(50),
		@MotorManufacturer varchar(50),
		@HP varchar(50),
		@MotorType varchar(50),
		@MotorSerialNo varchar(50),
		@MotorInstallDate datetime,
		@MotorModel varchar(50),
		@Frame varchar(50),
		@RPM varchar(50),
		@Voltage varchar(50),
		@Amperes varchar(50),
		@PhaseCycle varchar(50),
		@BSLClassification varchar(50),
		@TJCValue int,
		@PMSchedule varchar(50),				
		@UserName varchar(50),			-- required
		@ParentFacilityNo varchar(50),	-- required
		@EquipmentSerial int,	
		@ID int OUTPUT,	
		@Res int OUTPUT		
	
	)
AS
Begin
declare @EquipmentGroup as varchar(50)

declare @EquipmentSystem as varchar(50)

Set @Res = 0


/* initially, check key fields. If null then, return -1  */	
	if @EquipmentID is null or @ParentFacilityNo is null or @EquipmentSerial  is null or @UserName is null
	Begin
		set @Res=-1
		return
	End
		
	select @EquipmentSystem = SystemTitle, @EquipmentGroup = SystemGroup
	from dbo.InvFacilitySystem where SystemTitle = @TypeorUse and SystemGroup = '%Equipment%'
	
	if @@error<> 0 GOTO E_Error


	IF (@ID = -1)
		Begin -- begin for insert
			Declare @maxSerial as int
			Select @maxSerial=max(EquipmentSerialNo) from InvEquipment where ParentFacility#=@ParentFacilityNo
			
			if @maxSerial is null set @EquipmentSerial = 1
			else set @EquipmentSerial = @maxSerial + 1
					
					-- INSERT as one equipment
					Insert into	dbo.InvEquipment([ParentFacility#],[EquipmentSystem],[EquipmentGroup],[EquipmentID],[location],[TypeorUse],
						   [Manufacturer],[Model],[SerialNo],[Size],[InstallDate],[Capacity],[CapacityHeadTest],[FuelRefrigeration],[MotorManufacturer],
						   [HP],[MotorType],[MotorSerialNo],[MotorInstallDate],[MotorModel],[Frame],[RPM],[Voltage],[Amperes],[PhaseCycle],[BSLClassification],
						   [TJCValue],[PMSchedule],[ModifiedBy], [EquipmentSerialNo],ModifiedDate, EquipmentFacility#)
					VALUES
					   (@ParentFacilityNo,@EquipmentSystem,@EquipmentGroup,@EquipmentID,@EquipmentLocation,@TypeorUse,@Manufacturer,
					   @ModelNo,@SerialNo,@Size,@InstallDate,@Capacity,@CapacityHeadTest,
					   @FuelRefrigeration, @MotorManufacturer, @HP, @MotorType,@MotorSerialNo, @MotorInstallDate, @MotorModel, @Frame, @RPM, @Voltage,
					   @Amperes,@PhaseCycle, @BSLClassification,@TJCValue,@PMSchedule, @UserName, @EquipmentSerial,getdate(), @ParentFacilityNo+@EquipmentID)
					   --GET THE IDENTITY VALUE
					   
					SELECT @ID = @@IDENTITY
					If @@error <> 0	GOTO E_Error
					
					return
				
		End--end for insert new
	Else
		Begin-- begin for update			
			
					UPDATE dbo.InvEquipment SET					
					    EquipmentID = @EquipmentID,
						Location = @EquipmentLocation,
						[EquipmentSystem] = @EquipmentSystem,
						[EquipmentGroup] = @EquipmentGroup,
						[ModifiedBy]=@UserName,
						[ModifiedDate]=getdate(),
						TypeorUse = @TypeorUse,
						Manufacturer = @Manufacturer,
						Model = @ModelNo,
						SerialNo = @SerialNo,
						[Size] = @Size,
						InstallDate = @InstallDate,
						Capacity = @Capacity,
						CapacityHeadTest= @CapacityHeadTest,
						FuelRefrigeration = @FuelRefrigeration,
						MotorManufacturer = @MotorManufacturer,
						HP = @HP,
						MotorType = @MotorType,
						MotorSerialNo=@MotorSerialNo, 
						MotorInstallDate = @MotorInstallDate,
						MotorModel=@MotorModel,
						Frame = @Frame,
						RPM = @RPM,
						Voltage = @Voltage,
						Amperes = @Amperes,
						PhaseCycle=@PhaseCycle,
						BSLClassification = @BSLClassification,
						TJCValue = @TJCValue,
						PMSchedule = @PMSchedule,
						EquipmentFacility# = @ParentFacilityNo + @EquipmentID
					WHERE ID=@ID
                                      			
                    return
                    				
					            
		End -- end for update
	
E_Error:
	set @EquipmentSerial = null
    set @Res=@@error
    return	
End
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_UpdateEletricalEquipment]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Alter Procedure [dbo].[spn_inv_UpdateEletricalEquipment]
	(
		@System varchar(50),		-- required
		@Comments varchar(255),
		@Building varchar(50),		-- required
		@Floor varchar(20),			
		@FacilityLocation varchar(50),		-- required
		
		@WorkRequestNo varchar(50),
		@Function varchar(50),
		@BSL smallint,				-- default 0
		@AAALAC smallint,			-- default 0
		@TJC smallint,				-- default 0
		@FacilityID varchar(50),
		
		@TypeorUse varchar(50),
		@Manufacturer varchar(50),
	    @VOLTS varchar(20),
		@AMP varchar(20),
		@KVA varchar(20),
		@VOLTSprimary varchar(20),
		@VOLTSSecondary varchar(20),
		@PH varchar(6),
		@W varchar(6),
		@NOofCKTS varchar(6),
		@CKTSUsed varchar(6),
		@ElectricalOther varchar(50),

		@UserName varchar(50),		-- required	
		@FacilityNo varchar(50) OUTPUT,  -- change on 3/22/11	
		@ID int OUTPUT,  -- change on 3/22/11
		@Res int OUTPUT		
	)
AS
Begin
declare @FacilityGroup as varchar(50)
declare @iden as int
declare @Property as varchar(50)

set @iden = 0
Set @Res = 0

	/* initially, check key fields. If null then, return -1  */	
	if @Building is null or @System is null or @FacilityLocation is null
	Begin
		set @FacilityNo = null
		set @Res=-1
		return
	End
		
	if @BSL is null set @BSL = 0
	if @TJC is null set @TJC = 0	
	if @AAALAC is null set @AAALAC = 0

	select @Property = [Property]
	from dbo.InvBuilding where Building = @Building
	
	if @@error<> 0 GOTO E_Error
	
	select @FacilityGroup = SystemGroup
	from dbo.InvFacilitySystem where SystemTitle = @System and IsParent = -1
	
	if @@error<> 0 GOTO E_Error
	
	if @FacilityGroup is null 
	begin
		select @FacilityGroup = SystemGroup
		from dbo.InvFacilitySystem where SystemTitle = @System and IsParent = 0
	end


	if @@error<> 0 GOTO E_Error

	--IF @FacilityNo = ''
	 IF (@ID = -1)
		Begin -- begin for insert
			set @iden = IDENT_CURRENT('invFacility')+1
			-- the first time facility# is a temp number
			set @FacilityNo = 'T' + RIGHT(Convert(varchar(6),100000+@iden), 5)

			
			begin
				-- INSERT as one facility
				Insert into	dbo.InvFacility([WorkRequest#],[Facility#],[Facility#Temp],[FacilitySystem],[FacilityGroup],[FacilityFunction],
				   [FacilityID],[Comments],[Property],[Building],[Floor],[Location],[BSL],[AAALAC],[TJC],[TypeorUse],
				   [Manufacturer],ElectricalOther
					,[VOLTS],[AMP],[KVA],[VOLTSprimary],[VOLTSSecondary],[PH],[W],[NOofCKTS],[CKTSUsed]
				   ,[InputBy],[InputDate])
				VALUES
				   ( @WorkRequestNo,@FacilityNo,@FacilityNo,@System,@FacilityGroup,@Function,@FacilityID, @Comments, @Property, @Building,
				   @Floor,@FacilityLocation,@BSL,@AAALAC,@TJC,@TypeorUse,@Manufacturer,@ElectricalOther
					,@VOLTS,@AMP,@KVA,@VOLTSprimary,@VOLTSSecondary,@PH,@W,@NOofCKTS,@CKTSUsed
				   
					, @UserName, getdate())
		        SELECT @ID = @@IDENTITY

				If @@error <> 0	GOTO E_Error
				
				return
			End
		
		End--end for insert new
	Else
		Begin-- begin for update			
			
					UPDATE dbo.InvFacility SET					
					    [WorkRequest#] = @WorkRequestNo,
					    [FacilitySystem] = @System,
					    [FacilityGroup] = @FacilityGroup,
					    [FacilityFunction] = @Function,	
						[FacilityID] = @FacilityID,					   
					    [Comments] = @Comments,					   
					    [Property] = @Property,
						[Building] = @Building, 						
						[Floor] = @Floor,
						[Location] = @FacilityLocation,
						[BSL] = @BSL,
						[AAALAC]= @AAALAC,
						[TJC] = @TJC,
						[UpdateBy]=@UserName,
						[UpdateDate]=getdate(),
						ElectricalOther=@ElectricalOther,
						TypeorUse = @TypeorUse,
						Manufacturer = @Manufacturer,
						VOLTS = @VOLTS,
						AMP = @AMP,
						KVA = @KVA,
						VOLTSprimary = @VOLTSprimary,
						VOLTSSecondary = @VOLTSSecondary,
						PH= @PH,
						W = @W,
						NOofCKTS = @NOofCKTS,
						CKTSUsed = @CKTSUsed					

					WHERE [ID] = @ID
				
					select @FacilityNo = [Facility#] from dbo.InvFacility
					where [ID] = @ID
					If @@error <> 0	GOTO E_Error					
					return     
		End -- end for update
	
E_Error:
	set @FacilityNo = null
	set @ID = -1
    set @Res=@@error
    return	
End
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_UpdateElectricalEquipment_newSite]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Alter Procedure [dbo].[spn_inv_UpdateElectricalEquipment_newSite]
	(
		@FacilitySystem varchar(50),		-- required, from table invFacilitySystem after user selects.
		@Comments varchar(255),
		@Building varchar(50),			-- required
		@Floor varchar(20),			
		@FacilityLocation varchar(50),	-- required
		@FacilityID varchar(50),		-- required - not the Facility#
		@WorkRequestNo varchar(50),
		@Function varchar(50),
		@BSL smallint,				-- default 0
		@AAALAC smallint,			-- default 0
		@TJC smallint,				-- default 0

		@Manufacturer varchar(50),
		@ModelNo varchar(50),
		@SerialNo varchar(50),
		@Size varchar(50),
		@InstallDate datetime,
		
		@VOLTS varchar(20),
		@AMP varchar(20),
		@KVA varchar(20),
		@VOLTSprimary varchar(20),
		@VOLTSSecondary varchar(20),
		@PH varchar(6),
		@W varchar(6),
		@NOofCKTS varchar(6),
		@CKTSUsed varchar(6),
		@ElectricalOther varchar(50),
		
		@BSLClassification varchar(50),
		@TJCValue int,
		@PMSchedule varchar(50),	
					
		@UserName varchar(50),				-- required
		@FacilityNo varchar(50),			-- required - could change too
		
		@ID_table int,						-- invFacility table ID - to only update invFacility
		@Res int OUTPUT,		
		@Status varchar (20)				-- new column here -- to update status that comes from invStatus table	
	)
AS
Begin

declare @systemtitle as varchar(50) 
declare @FacilityNoexisting as varchar(50) 
declare @StatusExisting as varchar(50) 
declare @property as varchar(50) 

declare @count as int

if @BSL is null set @BSL = 0
if @TJC is null set @TJC = 0
if @AAALAC is null set @BSL = 0

Set @Res = 0
If @Status is null set @Status = 'Active'

/* initially, check key fields. If null then, return -1  */	
	if @facilityid is null or @FacilityNo is null or @UserName is null or @ID_table is null or @FacilitySystem is null	
	Begin
		set @Res=-1
		return
	End
	
	select @Property = [Property]
	from dbo.InvBuilding where Building = @Building and Active = -1
	
	if @@error<> 0 GOTO E_Error
	
--	select SystemTitle = @systemtitle
--	from dbo.InvFacilitySystem where id = @facilitySystemID
	
--	if @@error<> 0 GOTO E_Error	
	
	
	/* second, find out if duplicate fac# associated */
	select @count = COUNT(*)
	from dbo.invFacility 
	where Facility# = @facilityNo 
			
	if @@error<> 0 GOTO E_Error
		
	if @Count > 0
	Begin
		set @Res=-1
		return
	End

	
	-- verify the existing FAC# to avoid from T0003 to T0004
	select @FacilityNoexisting = facility#, @statusexisting = Status
	from dbo.InvFacility where  ID = ID
	
	if @@error<> 0 GOTO E_Error
	
	if left(@FacilityNo, 1) = 'T' and left(@FacilityNoexisting, 1) = 'T' and @FacilityNo <> @FacilityNoexisting 
	Begin
		set @Res=-1
		return
	End

	-- verify the existing FAC# to avoid from 11111 to T0005
	if left(@FacilityNo, 1) = 'T' and left(@FacilityNoexisting, 1) <> 'T' 
	Begin
		set @Res=-1
		return
	End
		UPDATE dbo.InvFacility SET
						[Facility#]	= @FacilityNo,
					    [WorkRequest#] = @WorkRequestNo,
						[FacilitySystem] = @FacilitySystem,
	--				    [FacilityGroup] = 'Electrical Equipment'
					    [FacilityFunction] = @Function,	
						[FacilityID] = @FacilityID,					   
					    [Comments] = @Comments,					   
					    [Property] = @Property,
						[Building] = @Building, 						
						[Floor] = @Floor,
						[Location] = @FacilityLocation,
						[BSL] = @BSL,
						[AAALAC]= @AAALAC,
						[TJC] = @TJC,
						[UpdateBy]=@UserName,
						[UpdateDate]=getdate(),
						[status] = @Status,		

						Manufacturer = @Manufacturer,
						Model = @ModelNo,
						SerialNo = @SerialNo,
						[Size] = @Size,
						InstallDate = @InstallDate,
						
						VOLTS = @VOLTS,
						AMP = @AMP,
						KVA = @KVA,
						VOLTSprimary = @VOLTSprimary,
						VOLTSSecondary = @VOLTSSecondary,
						PH= @PH,
						W = @W,
						NOofCKTS = @NOofCKTS,
						CKTSUsed = @CKTSUsed,
						ElectricalOther = @ElectricalOther,
						
						BSLClassification = @BSLClassification,
						TJCValue = @TJCValue,
						PMSchedule = @PMSchedule						
										
					WHERE ID =@ID_table
                                      			
             return
                    				
E_Error:

    set @Res=@@error
    return	
End
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_GetFacilityDetailsByWRNum]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Alter Procedure [dbo].[spn_Inv_GetFacilityDetailsByWRNum]
(
		@WRNum varchar(50)
)
AS 

Begin
	select *
	from dbo.InvFacility
	where InvFacility.WorkRequest#=@WRNum
End
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_GetFacilityDetailsByFacNum]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Alter Procedure [dbo].[spn_Inv_GetFacilityDetailsByFacNum]
(
		@FacNum varchar(50)
)
AS 

Begin
	select *
	from dbo.InvFacility
	where InvFacility.Facility#=@FacNum
End
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_GetFacilityDetail]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Alter Procedure [dbo].[spn_Inv_GetFacilityDetail]
(
		@ID int
)
AS 

Begin
	select *
	from dbo.InvFacility
	where InvFacility.ID=@ID
End
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_GetFacility_Search]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Alter Procedure [dbo].[spn_Inv_GetFacility_Search]
(
		@System varchar(50),	-- for invFacility only, from spn_Inv_GetSystem_Search
		@Group varchar(50),		-- only two choice: Mechanical, Electrical
		@Building varchar (50),	-- spn_Inv_GetBuildingList
		@FacilityNo varchar(50),
		@WorkRequest varchar(50),
		@Status varchar(10)
	)
AS
 


select InvFacility.ID,InvFacility.Facility#Temp, InvFacility.Facility#, InvFacility.FacilityFunction, InvFacility.FacilityGroup, 
InvFacility.FacilitySystem, InvFacility.FacilityID, InvFacility.Building, InvFacility.[location], InvFacility.[ElectricalOther], 
COUNT(invequipment.id) as TotalEquipments, InvFacility.WorkRequest#, InvFacility.Floor, InvFacility.Status

from dbo.InvFacility left join dbo.InvEquipment on InvFacility.Facility# = InvEquipment.parentfacility#
where 1=1
And ((@facilityNo is null) or (InvFacility.Facility# like '%' + @FacilityNo + '%') or (InvFacility.Facility#Temp like '%' + @FacilityNo + '%'))
And ((@Status='3') or (((@Status='1') and (InvFacility.Facility# like 'T%')) or ((@Status='2') and (InvFacility.Facility# not like 'T%'))))
And ((@Building is null) or (InvFacility.Building=@Building))
And ((@System is null) or (InvFacility.FacilitySystem=@system))
And ((@Group is null) or (InvFacility.FacilityGroup like @Group + '%'))
And ((@WorkRequest is null) or (InvFacility.WorkRequest# like '%' + @WorkRequest+'%'))
AND (InvFacility.Facility# is not null)
group by InvFacility.ID,InvFacility.Facility#Temp,InvFacility.Facility#, InvFacility.FacilityFunction, InvFacility.FacilityGroup, InvFacility.FacilitySystem, 
InvFacility.FacilityID, InvFacility.Building, InvFacility.[location], InvFacility.WorkRequest#, InvFacility.WorkRequest#, InvFacility.Floor, InvFacility.Status,InvFacility.[ElectricalOther]
order by InvFacility.Facility# asc
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_Search_GetFacilityList]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Alter Procedure [dbo].[spn_Inv_Search_GetFacilityList]
(
@SystemIds int, -- numeric, 
@TypeId int, -- 0 - all, 1 - Mechanical and 3 Electrical
@BuildingIds int, -- building from invBuilding, - the ID number 
@FacilityNo varchar(50),
@WorkRequest varchar(50), 
@Status varchar(10)  -- 3 means all, 1 is unassigned, 2 assigned
)
AS

select InvFacility.ID,InvFacility.Facility#Temp, InvFacility.Facility#, InvFacility.FacilityFunction, InvFacility.FacilityGroup, 
InvFacility.FacilitySystem, InvFacility.FacilityID, InvFacility.Building, InvFacility.[location], 
invFacility.WorkRequest#, InvFacility.Floor, InvFacility.Status, COUNT(invequipment.ID) as totalequipments 
from dbo.InvFacility left join dbo.InvEquipment on InvFacility.Facility# = InvEquipment.parentfacility#
where 1=1
and ((@TypeId is null) or (@TypeId = 0))
And ((@SystemIds is null) or (InvFacility.FacilitySystem in (select InvFacilitySystem.SystemTitle from InvFacilitySystem where InvFacilitySystem.ID = @SystemIds)))
and ((@BuildingIds is null) or (InvFacility.Building in (select InvFacility.building from [invbuilding] where InvFacility.ID = @buildingIds)))
And ((@facilityNo is null) or (InvFacility.Facility# like '%' + @FacilityNo + '%') or (InvFacility.Facility#Temp like '%' + @FacilityNo + '%'))
And ((@Status='3') or (((@Status='1') and (InvFacility.Facility# like 'T%')) or ((@Status='2') and (InvFacility.Facility# not like 'T%'))))
And ((@WorkRequest is null) or (InvFacility.WorkRequest# like '%' + @WorkRequest+'%'))
AND (InvFacility.Facility# is not null)
group by InvFacility.ID,InvFacility.Facility#Temp,InvFacility.Facility#, InvFacility.FacilityFunction, InvFacility.FacilityGroup, 
InvFacility.FacilitySystem, invFacility.FacilityID, InvFacility.Building, InvFacility.[location], 
InvFacility.WorkRequest#, InvFacility.Floor, InvFacility.Status
order by InvFacility.Facility# asc
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_MechanicalElectrical_System_Update_Regular_NewSite]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* spn_inv_AddElectricalSystem_NewSite 
**	on CMMS/Asset inventory Web site, create a new Electrical System Facility into table invFacility first.
	It only accepts the common system columns. NO NEED to include other details columns for Electrical, which will be taken by spn_inv_AddElectricalComponent_NewSite 
	after the new facility record is created into the table.
	
**	Parameter: FacilitySystem, ...etc
	Return: Facility#
**	return values as @RES: 0 means successfully; - 1 means missing paras. otherwise, @@error as SQL Server error number
*/


Alter Procedure [dbo].[spn_inv_MechanicalElectrical_System_Update_Regular_NewSite]
	(
		@FacilitySystem varchar(50),		-- required, from table invFacilitySystem after user selects.
		@Comments varchar(255),
		@Building varchar(50),			-- required
		@Floor varchar(20),			
		@FacilityLocation varchar(50),	-- required
		@FacilityID varchar(50),		-- required - not the Facility#
		@WorkRequestNo varchar(50),
		@Function varchar(50),
		@BSL smallint,				-- default 0
		@AAALAC smallint,			-- default 0
		@TJC smallint,				-- default 0
--		@EquipmentID varchar(50),
--		@EquipmentLocation varchar(50),
--		@TypeorUse varchar(50),
		@Manufacturer varchar(50),
		@ModelNo varchar(50),
		@SerialNo varchar(50),
		@Size varchar(50),
		@InstallDate date,
--		@Capacity varchar(50),
--		@CapacityHeadTest varchar(50),
--		@FuelRefrigeration varchar(50),
--		@MotorManufacturer varchar(50),
--		@HP varchar(50),
--		@MotorType varchar(50),
--		@MotorSerialNo varchar(50),
--		@MotorInstallDate date,
--		@MotorModel varchar(50),
--		@Frame varchar(50),
--		@RPM varchar(50),
--		@Voltage varchar(50),
--		@Amperes varchar(50),
--		@PhaseCycle varchar(50),
--		@BSLClassification varchar(50),
--		@TJCValue int,
--		@PMSchedule varchar(50),

	
		@ID_table int,						--  table invFacility ID
		@FacilityNo varchar(50),		-- New by admin/super user - existing Facility# for regular user without no change -- required
		@Status	 varchar(50),			-- new or existing - required		
		@UserName varchar(50),				-- required
	
		@Res int OUTPUT		
	)
AS
Begin
--declare @FacilityGroup as varchar(50)
--declare @FacilityNoexisting as varchar(50)
declare @statusexisting as varchar(50)
declare @Property as varchar(50)
--declare @countFacility as int

--declare @equipmentid as varchar(50)
declare @TableID2 as int
declare @equipmentstatusexisting as varchar(50)
--declare @typeoruse as varchar(50)
--declare @parentfacilitynoexisting as varchar(50)
--declare @return int

--set @return = 0
Set @Res = 0
--Set @countFacility = 0

	/* initially, check key fields. If null then, return -1  */	
	
--	-- verify the null or duplicate of FAC#
--	select @countFacility = COUNT(Facility#)
--	from dbo.InvFacility 
--	where Facility#  = @FacilityNo and ID <> @TableID
	
--	if @@error<> 0 GOTO E_Error
	
	if @Building is null or @FacilitySystem is null or @FacilityLocation is null or	@FacilityID is null or @FacilityNo is null 
	Begin
		set @Res=-1
		return
	End
	
	if @status is null set @status = 'Active'

	
	-- verify the existing FAC# to avoid from T0003 to T0004
	select @statusexisting = Status
	from dbo.InvFacility where  ID = @ID_table
	
	if @@error<> 0 GOTO E_Error

/*	
	if left(@FacilityNo, 1) = 'T' and left(@FacilityNoexisting, 1) = 'T' and @FacilityNo <> @FacilityNoexisting 
	Begin
		set @Res=-1
		return
	End

	-- verify the existing FAC# to avoid from 11111 to T0005
	if left(@FacilityNo, 1) = 'T' and left(@FacilityNoexisting, 1) <> 'T' 
	Begin
		set @Res=-1
		return
	End
*/	
	if @BSL is null set @BSL = 0
	if @TJC is null set @TJC = 0
	if @AAALAC is null set @BSL = 0
		
	-- if building changes, then property needs to be changeed
	select @Property = [Property]
	from dbo.InvBuilding where Building = @Building and Active = -1
	
	if @@error<> 0 GOTO E_Error
	
--	select @FacilityGroup = SystemGroup
--	from dbo.InvFacilitySystem where SystemTitle = @System and IsParent = -1
	
--	if @@error<> 0 GOTO E_Error
	
--	if @FacilityGroup is null 
--	begin
--		select @FacilityGroup = SystemGroup
--		from dbo.InvFacilitySystem where SystemTitle = @System and IsParent = 0
--	end

--	if @@error<> 0 GOTO E_Error
	
	-- begin for update	facility
	UPDATE dbo.InvFacility SET
--						[Facility#]	= @FacilityNo,		-- regular user not to change the FacilityNo
					    [WorkRequest#] = @WorkRequestNo,
					    [FacilitySystem] = @FacilitySystem,
--					    [FacilityGroup] = @FacilityGroup,
					    [FacilityFunction] = @Function,	
						[FacilityID] = @FacilityID,					   
					    [Comments] = @Comments,					   
					    [Property] = @Property,
						[Building] = @Building, 						
						[Floor] = @Floor,
						[Location] = @FacilityLocation,
						[BSL] = @BSL,
						[AAALAC]= @AAALAC,
						[TJC] = @TJC,
						[UpdateBy]=@UserName,
						[UpdateDate]=getdate(),
						[status] = @Status
					WHERE id = @ID_table
					
	If @@error <> 0	GOTO E_Error					
				
	-- began cursor to update components  - because the FacilityNo and Status could be updated.
	
	if @statusexisting = @Status return  -- no need to update components
	
		
		DECLARE Equipment_cursor CURSOR FOR 
		SELECT  status, ID
		FROM dbo.InvEquipment
		WHERE parentfacility# = @facilityNo
	
		OPEN Equipment_cursor 

		FETCH NEXT FROM Equipment_cursor
		INTO @equipmentstatusexisting, @TABLEID2
	
		WHILE @@FETCH_STATUS = 0
			BEGIN				
				if @status <> 'Active' and @equipmentstatusexisting = 'Active'
					begin 
						UPDATE dbo.InvEquipment SET					
								[ModifiedBy]=@UserName,
								[ModifiedDate]=getdate(),
								Status = @status
						WHERE ID=@tableid2
			
						if @@error<> 0 GOTO E_Error								
					end	
						
				FETCH NEXT FROM Equipment_cursor
				INTO @equipmentstatusexisting, @tableid2

			END

		CLOSE Equipment_cursor 
		DEALLOCATE Equipment_cursor 
		
	return
			
E_Error:
    set @Res=@@error
    return	
End
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_MechanicalElectrical_System_Update_Admin_NewSite]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* spn_inv_AddElectricalSystem_NewSite 
**	on CMMS/Asset inventory Web site, create a new Electrical System Facility into table invFacility first.
	It only accepts the common system columns. NO NEED to include other details columns for Electrical, which will be taken by spn_inv_AddElectricalComponent_NewSite 
	after the new facility record is created into the table.
	
**	Parameter: FacilitySystem, ...etc
	Return: Facility#
**	return values as @RES: 0 means successfully; - 1 means missing paras. otherwise, @@error as SQL Server error number
*/


Alter Procedure [dbo].[spn_inv_MechanicalElectrical_System_Update_Admin_NewSite]
	(
		@FacilitySystem varchar(50),		-- required, from table invFacilitySystem after user selects.
		@Comments varchar(255),
		@Building varchar(50),			-- required
		@Floor varchar(20),			
		@FacilityLocation varchar(50),	-- required
		@FacilityID varchar(50),		-- required - not the Facility#
		@WorkRequestNo varchar(50),
		@Function varchar(50),
		@BSL smallint,				-- default 0
		@AAALAC smallint,			-- default 0
		@TJC smallint,				-- default 0
--		@EquipmentID varchar(50),
--		@EquipmentLocation varchar(50),
--		@TypeorUse varchar(50),
		@Manufacturer varchar(50),
		@ModelNo varchar(50),
		@SerialNo varchar(50),
		@Size varchar(50),
		@InstallDate date,
--		@Capacity varchar(50),
--		@CapacityHeadTest varchar(50),
--		@FuelRefrigeration varchar(50),
--		@MotorManufacturer varchar(50),
--		@HP varchar(50),
--		@MotorType varchar(50),
--		@MotorSerialNo varchar(50),
--		@MotorInstallDate date,
--		@MotorModel varchar(50),
--		@Frame varchar(50),
--		@RPM varchar(50),
--		@Voltage varchar(50),
--		@Amperes varchar(50),
--		@PhaseCycle varchar(50),
--		@BSLClassification varchar(50),
--		@TJCValue int,
--		@PMSchedule varchar(50),

	
		@ID_table int,						--  table invFacility ID
		@FacilityNo varchar(50),		-- New by admin/super user - existing Facility# for regular user without no change -- required
		@Status	 varchar(50),			-- new or existing - required		
		@UserName varchar(50),				-- required
	
		@Res int OUTPUT		
	)
AS
Begin
declare @FacilityGroup as varchar(50)
declare @FacilityNoexisting as varchar(50)
declare @statusexisting as varchar(50)
declare @Property as varchar(50)
declare @countFacility as int

declare @equipmentid as varchar(50)
declare @TableID2 as int
declare @equipmentstatusexisting as varchar(50)
--declare @typeoruse as varchar(50)
declare @parentfacilitynoexisting as varchar(50)
declare @return int

set @return = 0
Set @Res = 0
Set @countFacility = 0

	/* initially, check key fields. If null then, return -1  */	
	
	-- verify the null or duplicate of FAC#
	select @countFacility = COUNT(Facility#)
	from dbo.InvFacility 
	where Facility#  = @FacilityNo and ID <> @ID_table
	
	if @@error<> 0 GOTO E_Error
	
	if @Building is null or @FacilitySystem is null or @FacilityLocation is null or	@FacilityID is null 
		or @countFacility > 0 or @FacilityNo is null 
	Begin
		set @Res=-1
		return
	End
	
	if @status is null set @status = 'Active'
	
	-- verify the existing FAC# to avoid from T0003 to T0004
	select @FacilityNoexisting = facility#, @statusexisting = Status
	from dbo.InvFacility where  ID = @ID_table
	
	if @@error<> 0 GOTO E_Error
	
	if left(@FacilityNo, 1) = 'T' and left(@FacilityNoexisting, 1) = 'T' and @FacilityNo <> @FacilityNoexisting 
	Begin
		set @Res=-1
		return
	End

	-- verify the existing FAC# to avoid from 11111 to T0005
	if left(@FacilityNo, 1) = 'T' and left(@FacilityNoexisting, 1) <> 'T' 
	Begin
		set @Res=-1
		return
	End
	
	if @BSL is null set @BSL = 0
	if @TJC is null set @TJC = 0
	if @AAALAC is null set @BSL = 0
		
	-- if building changes, then property needs to be changeed
	select @Property = [Property]
	from dbo.InvBuilding where Building = @Building and Active = -1
	
	if @@error<> 0 GOTO E_Error
	
--	select @FacilityGroup = SystemGroup
--	from dbo.InvFacilitySystem where SystemTitle = @System and IsParent = -1
	
--	if @@error<> 0 GOTO E_Error
	
--	if @FacilityGroup is null 
--	begin
--		select @FacilityGroup = SystemGroup
--		from dbo.InvFacilitySystem where SystemTitle = @System and IsParent = 0
--	end

--	if @@error<> 0 GOTO E_Error
	
	-- begin for update	facility
	UPDATE dbo.InvFacility SET
						[Facility#]	= @FacilityNo,
					    [WorkRequest#] = @WorkRequestNo,
					    [FacilitySystem] = @FacilitySystem,
	--				    [FacilityGroup] = @FacilityGroup,
					    [FacilityFunction] = @Function,	
						[FacilityID] = @FacilityID,					   
					    [Comments] = @Comments,					   
					    [Property] = @Property,
						[Building] = @Building, 						
						[Floor] = @Floor,
						[Location] = @FacilityLocation,
						[BSL] = @BSL,
						[AAALAC]= @AAALAC,
						[TJC] = @TJC,
						[UpdateBy]=@UserName,
						[UpdateDate]=getdate(),
						[status] = @Status
					WHERE id = @ID_table
					
	If @@error <> 0	GOTO E_Error					
				
	-- began cursor to update components  - because the FacilityNo and Status could be updated.
	
	if @FacilityNo = @FacilityNoexisting and @statusexisting = @Status return  -- no need to update components
	
		
		DECLARE Equipment_cursor CURSOR FOR 
		SELECT  equipmentid, ParentFacility#, status, ID
		FROM dbo.InvEquipment
		WHERE parentfacility# = @FacilityNoExisting
	
		OPEN Equipment_cursor 

		FETCH NEXT FROM Equipment_cursor
		INTO @equipmentid, @parentfacilitynoexisting, @equipmentstatusexisting, @TABLEID2
	
		WHILE @@FETCH_STATUS = 0
			BEGIN				
--			-- call spn_inv_UpdateFacility_Admin
--				exec [dbo].[spn_inv_Updateequipment_Admin] @equipmentid,@typeoruse,@username, @facilityno, @TableID2, @status, @return
			
				if @FacilityNo = @FacilityNoexisting 
					begin
						if @status <> 'Active' and @equipmentstatusexisting = 'Active'
							begin 
								UPDATE dbo.InvEquipment SET					
									[ModifiedBy]=@UserName,
									[ModifiedDate]=getdate(),
									Status = @status
								WHERE ID=@tableid2
			
								if @@error<> 0 GOTO E_Error								
							end
					end	
				else				
					begin
						UPDATE dbo.InvEquipment SET					
							[ModifiedBy]=@UserName,
							[ModifiedDate]=getdate(),
							EquipmentFacility# = @FacilityNo + @EquipmentID,
							Status = case when status = 'Active' then @status else status end,
							ParentFacility# = @FacilityNo
						WHERE ID=@tableid2
			
						if @@error<> 0 GOTO E_Error
								
					end
					
				FETCH NEXT FROM Equipment_cursor
				INTO @equipmentid, @parentfacilitynoexisting, @equipmentstatusexisting, @tableid2

			END

		CLOSE Equipment_cursor 
		DEALLOCATE Equipment_cursor 
		
	return
			
E_Error:
    set @Res=@@error
    return	
End
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_MechanicalElectrical_System_Add_NewSite]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* spn_inv_AddElectricalSystem_NewSite 
**	on CMMS/Asset inventory Web site, create a new Electrical System Facility into table invFacility first.
	It only accepts the common system columns. NO NEED to include other details columns for Electrical, which will be taken by spn_inv_AddElectricalComponent_NewSite 
	after the new facility record is created into the table.
	
**	Parameter: FacilitySystem, ...etc
	Return: Facility#
**	return values as @RES: 0 means successfully; - 1 means missing paras. otherwise, @@error as SQL Server error number
*/


Alter Procedure [dbo].[spn_inv_MechanicalElectrical_System_Add_NewSite]
	(
		@FacilitySystem varchar(50),		-- required, from table invFacilitySystem after user selects.
		@Comments varchar(255),
		@Building varchar(50),			-- required
		@Floor varchar(20),			
		@FacilityLocation varchar(50),	-- required
		@FacilityID varchar(50),		-- required - not the Facility#
		@WorkRequestNo varchar(50),
		@Function varchar(50),
		@BSL smallint,				-- default 0
		@AAALAC smallint,			-- default 0
		@TJC smallint,				-- default 0
--		@EquipmentID varchar(50),
--		@EquipmentLocation varchar(50),
--		@TypeorUse varchar(50),
		@Manufacturer varchar(50),
		@ModelNo varchar(50),
		@SerialNo varchar(50),
		@Size varchar(50),
		@InstallDate date,
--		@Capacity varchar(50),
--		@CapacityHeadTest varchar(50),
--		@FuelRefrigeration varchar(50),
--		@MotorManufacturer varchar(50),
--		@HP varchar(50),
--		@MotorType varchar(50),
--		@MotorSerialNo varchar(50),
--		@MotorInstallDate date,
--		@MotorModel varchar(50),
--		@Frame varchar(50),
--		@RPM varchar(50),
--		@Voltage varchar(50),
--		@Amperes varchar(50),
--		@PhaseCycle varchar(50),
--		@BSLClassification varchar(50),
--		@TJCValue int,
--		@PMSchedule varchar(50),

		@SystemGroup varchar(50),	--'Electrical System' why not also 'Mechanical System'
		@ID_table int OUTPUT,						--  table invFacility ID
				
		@UserName varchar(50),				-- required
		@FacilityNo varchar(50) OUTPUT,		-- return a new Facility# as Temporary
		@Res int OUTPUT		
	)
AS

Begin

declare @SystemTitle as varchar(50) -- need for Elec, not for Mechanical
declare @iden as int
declare @Property as varchar(50)

set @iden = 0

Set @Res = 0

	/* initially, check key fields. If null then, return -1  */	
	if @Building is null or @FacilitySystem is null or @FacilityLocation is null or @FacilityID is null
	Begin
		set @FacilityNo = null
		set @Res=-1
		return
	End
		
	select @Property = Property
	from dbo.InvBuilding where Building = @Building and Active = -1
	
	if @@error<> 0 GOTO E_Error
	
--	select @SystemGroup = SystemGroup, @SystemTitle = SystemTitle
--	from dbo.InvFacilitySystem where id = @facilitySystemID
	
--	if @@error<> 0 GOTO E_Error
	
	set @SystemGroup = 'Electrical System' -- required in the table of invFacility

	/* second, create a record of mecahnical system only into table*/
--	if @EquipmentID is null
--	begin
		
		set @iden = IDENT_CURRENT('invFacility')+1
		
		set @FacilityNo = 'T' + RIGHT(Convert(varchar(6),100000+@iden), 5)
					
		Insert into	dbo.InvFacility([WorkRequest#],[Facility#],[Facility#Temp],[FacilitySystem],[FacilityGroup],[FacilityFunction],
           [FacilityID],[Comments],[Property],[Building],[Floor],[Location],[BSL],[AAALAC],[TJC],
           [Manufacturer],[Model],[SerialNo],[Size],[InstallDate],[InputBy])
		VALUES
           ( @WorkRequestNo,@FacilityNo,@FacilityNo,@FacilitySystem,@SystemGroup,@Function,@FacilityID, @Comments, @Property, @Building,
           @Floor,@FacilityLocation,@BSL,@AAALAC,@TJC,@Manufacturer,@ModelNo,@SerialNo,@Size,@InstallDate,@UserName)
           
        SELECT @ID_table = @@IDENTITY
		If @@error <> 0	GOTO E_Error
		
		return

		--select @NewWRnumber=@@identity
--	end

--	/*otherwise, create a Facility and Equipment*/
	
--	set @iden = IDENT_CURRENT('invFacility')+1
		
--	set @FacilityNo = 'T' + RIGHT(Convert(varchar(6),100000+@iden), 5)
				
--	Insert into	dbo.InvFacility([WorkRequest#],[Facility#],[Facility#Temp],[FacilitySystem],[FacilityGroup],[FacilityFunction],
--           [FacilityID],[Comments],[Property],[Building],[Floor],[Location],[BSL],[AAALAC],[TJC],[InputBy])
--	VALUES(@WorkRequestNo,@FacilityNo,@FacilityNo,@System,@FacilityGroup,@Function,@FacilityID, @Comments, @Property, @Building,
--           @Floor,@FacilityLocation,@BSL,@AAALAC,@TJC,@UserName)
           
--		If @@error <> 0	GOTO E_Error
	
--	exec [dbo].[spn_inv_AddEquipment] @EquipmentID = @EquipmentID, @EquipmentLocation = @EquipmentLocation, @TypeorUse = @TypeorUse,
--		@Manufacturer = @Manufacturer, 	@ModelNo = @ModelNo, @SerialNo = @SerialNo, @Size = @Size, @InstallDate = @InstallDate,
--		@Capacity = @Capacity, 	@CapacityHeadTest= @CapacityHeadTest, @FuelRefrigeration = @FuelRefrigeration, 
--		@MotorManufacturer = @MotorManufacturer, @HP = @HP, @MotorType = @MotorType, @MotorSerialNo=@MotorSerialNo,
--		@MotorInstallDate = @MotorInstallDate, @MotorModel=@MotorModel, @Frame = @Frame, @RPM = @RPM, @Voltage = @Voltage,
--		@Amperes = @Amperes,	@PhaseCycle=@PhaseCycle, @BSLClassification = @BSLClassification, @TJCValue = @TJCValue,
--		@PMSchedule = @PMSchedule, @UserName = @UserName, @ParentFacilityNo = @FacilityNo, @EquipmentSerial = 1, @res = @res OUTPUT

--	if @res <> 0 goto E_Error
		
--	return

E_Error:
	set @FacilityNo = null
    set @Res=@@error
    return


End
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_GetSystemList_Mechanical_newSite]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Alter Procedure [dbo].[spn_Inv_GetSystemList_Mechanical_newSite]
AS
Select distinct SystemTitle, SystemAbbreviation
from InvFacilitySystem
Where SystemGroup like 'Mechanical System'
Order By Systemtitle ASC
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_GetSystemList_Mechanical]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Alter Procedure [dbo].[spn_Inv_GetSystemList_Mechanical]
AS
Select distinct SystemTitle, SystemAbbreviation
from InvFacilitySystem
Where SystemGroup like 'Mechanical%'
Order By Systemtitle ASC
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_GetSystemList_Electrical_newsite]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Alter Procedure [dbo].[spn_Inv_GetSystemList_Electrical_newsite]
AS
Select distinct SystemTitle, SystemAbbreviation
from InvFacilitySystem
Where SystemGroup like 'Electrical System'
Order By Systemtitle ASC
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_GetSystemList_Electrical]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Alter Procedure [dbo].[spn_Inv_GetSystemList_Electrical]
AS
Select distinct SystemTitle, SystemAbbreviation
from InvFacilitySystem
Where SystemGroup like 'Electrical%'
Order By Systemtitle ASC
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_GetSystemEquipmentList_Mechanical]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Alter Procedure [dbo].[spn_Inv_GetSystemEquipmentList_Mechanical]
AS
Select distinct SystemTitle, SystemAbbreviation
from InvFacilitySystem
Where SystemGroup like 'Mechanical Equipment'
Order By Systemtitle ASC
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_GetSystemEquipmentList_Electrical]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Alter Procedure [dbo].[spn_Inv_GetSystemEquipmentList_Electrical]
AS
Select distinct SystemTitle, SystemAbbreviation
from InvFacilitySystem
Where SystemGroup like 'Electrical Equipment'
Order By Systemtitle ASC
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_GetSystem_Search_newSite]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Alter Procedure [dbo].[spn_Inv_GetSystem_Search_newSite]
 (
            @SearchIndex varchar(10) -- from the search front page, 0 for all; 1 for Mechanical and 2 for Electrical - 9/24/2016
      )
AS
  
Select ID as [Key], SystemGroup + ' - ' + SystemTitle as [Description]
from InvFacilitySystem
where (@SearchIndex = '0' and (SystemGroup like 'Mechanical%' or SystemGroup like 'Electrical%')) 
or (@Searchindex = '1' and SystemGroup like 'Mechanical%') 
or (@Searchindex = '2' and SystemGroup like 'Electrical%')
Order By SystemGroup + ' - ' + SystemTitle  ASC
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_GetSystem_Search]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Alter Procedure [dbo].[spn_Inv_GetSystem_Search]
AS
Select distinct SystemTitle
from InvFacilitySystem
Order By Systemtitle ASC
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_GetStatusList]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Alter Procedure [dbo].[spn_Inv_GetStatusList]
AS
Select distinct Status
from InvStatus
Where active=-1
Order By Status ASC
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_GetListByType_Search]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Alter Procedure [dbo].[spn_Inv_GetListByType_Search]
	@SystemGroup varchar(50)
AS
Select ID, SystemGroup + '--' + SystemTitle as [Description]
from InvFacilitySystem
where SystemGroup like @SystemGroup + '%'
Order By Systemtitle ASC
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_AddMechanicalSystem_NewSite ]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* spn_inv_AddMechanicalSystem_NewSite 
**	on CMMS/Asset inventory Web site, create a new Mechanical System Facility into table invFacility first.
	It only accepts the common system columns. NO NEED to include 25 details columns, which will be taken by spn_inv_AddMechanicalComponent_NewSite 
	after the new record is created into table invFacility.
	
**	Parameter: FacilitySystem, ...etc
	Return: Facility#
**	return values as @RES: 0 means successfully; - 1 means missing paras. otherwise, @@error as SQL Server error number
*/


Alter Procedure [dbo].[spn_inv_AddMechanicalSystem_NewSite ]
	(
		@FacilitySystem varchar(50),	-- required, from table invFacilitySystem after user selects.
		@Comments varchar(255),
		@Building varchar(50),			-- required
		@Floor varchar(20),			
		@FacilityLocation varchar(50),	-- required
		@FacilityID varchar(50),		-- required - not the Facility#
		@WorkRequestNo varchar(50),
		@Function varchar(50),
		@BSL smallint,				-- default 0
		@AAALAC smallint,			-- default 0
		@TJC smallint,				-- default 0
--		@EquipmentID varchar(50),
--		@EquipmentLocation varchar(50),
--		@TypeorUse varchar(50),
		@Manufacturer varchar(50),
		@ModelNo varchar(50),
		@SerialNo varchar(50),
		@Size varchar(50),
		@InstallDate date,
--		@Capacity varchar(50),
--		@CapacityHeadTest varchar(50),
--		@FuelRefrigeration varchar(50),
--		@MotorManufacturer varchar(50),
--		@HP varchar(50),
--		@MotorType varchar(50),
--		@MotorSerialNo varchar(50),
--		@MotorInstallDate date,
--		@MotorModel varchar(50),
--		@Frame varchar(50),
--		@RPM varchar(50),
--		@Voltage varchar(50),
--		@Amperes varchar(50),
--		@PhaseCycle varchar(50),
--		@BSLClassification varchar(50),
--		@TJCValue int,
--		@PMSchedule varchar(50),
				
		@UserName varchar(50),				-- required
		@FacilityNo varchar(50) OUTPUT,		-- return a new Facility# as Temporary
		@Res int OUTPUT		
	)
AS
declare @SystemGroup as varchar(50)
--declare @SystemTitle as varchar(50)
declare @iden as int
declare @Property as varchar(50)

set @iden = 0

Set @Res = 0

	/* initially, check key fields. If null then, return -1  */	
	if @Building is null or @FacilitySystem is null or @FacilityLocation is null or @FacilityID is null
	Begin
		set @FacilityNo = null
		set @Res=-1
		return
	End
		
	select @Property = Property
	from dbo.InvBuilding where Building = @Building and Active = -1
	
	if @@error<> 0 GOTO E_Error
	
--	select @SystemGroup = SystemGroup, @SystemTitle = SystemTitle
--	from dbo.InvFacilitySystem where id = @facilitySystemID
	
--	if @@error<> 0 GOTO E_Error
	
--	set @SystemGroup = 'Mechanical System' -- required in the table of invFacility

	/* second, create a record of mecahnical system only into table*/
--	if @EquipmentID is null
--	begin
		
		set @iden = IDENT_CURRENT('invFacility')+1
		
		set @FacilityNo = 'T' + RIGHT(Convert(varchar(6),100000+@iden), 5)
					
		Insert into	dbo.InvFacility([WorkRequest#],[Facility#],[Facility#Temp],[FacilitySystem],[FacilityGroup],[FacilityFunction],
           [FacilityID],[Comments],[Property],[Building],[Floor],[Location],[BSL],[AAALAC],[TJC],
           [Manufacturer],[Model],[SerialNo],[Size],[InstallDate],[InputBy])
		VALUES
           ( @WorkRequestNo,@FacilityNo,@FacilityNo,@FacilitySystem,@SystemGroup,@Function,@FacilityID, @Comments, @Property, @Building,
           @Floor,@FacilityLocation,@BSL,@AAALAC,@TJC,@Manufacturer,@ModelNo,@SerialNo,@Size,@InstallDate,@UserName)
           
		If @@error <> 0	GOTO E_Error
		
		return

		--select @NewWRnumber=@@identity
--	end

--	/*otherwise, create a Facility and Equipment*/
	
--	set @iden = IDENT_CURRENT('invFacility')+1
		
--	set @FacilityNo = 'T' + RIGHT(Convert(varchar(6),100000+@iden), 5)
				
--	Insert into	dbo.InvFacility([WorkRequest#],[Facility#],[Facility#Temp],[FacilitySystem],[FacilityGroup],[FacilityFunction],
--           [FacilityID],[Comments],[Property],[Building],[Floor],[Location],[BSL],[AAALAC],[TJC],[InputBy])
--	VALUES(@WorkRequestNo,@FacilityNo,@FacilityNo,@System,@FacilityGroup,@Function,@FacilityID, @Comments, @Property, @Building,
--           @Floor,@FacilityLocation,@BSL,@AAALAC,@TJC,@UserName)
           
--		If @@error <> 0	GOTO E_Error
	
--	exec [dbo].[spn_inv_AddEquipment] @EquipmentID = @EquipmentID, @EquipmentLocation = @EquipmentLocation, @TypeorUse = @TypeorUse,
--		@Manufacturer = @Manufacturer, 	@ModelNo = @ModelNo, @SerialNo = @SerialNo, @Size = @Size, @InstallDate = @InstallDate,
--		@Capacity = @Capacity, 	@CapacityHeadTest= @CapacityHeadTest, @FuelRefrigeration = @FuelRefrigeration, 
--		@MotorManufacturer = @MotorManufacturer, @HP = @HP, @MotorType = @MotorType, @MotorSerialNo=@MotorSerialNo,
--		@MotorInstallDate = @MotorInstallDate, @MotorModel=@MotorModel, @Frame = @Frame, @RPM = @RPM, @Voltage = @Voltage,
--		@Amperes = @Amperes,	@PhaseCycle=@PhaseCycle, @BSLClassification = @BSLClassification, @TJCValue = @TJCValue,
--		@PMSchedule = @PMSchedule, @UserName = @UserName, @ParentFacilityNo = @FacilityNo, @EquipmentSerial = 1, @res = @res OUTPUT

--	if @res <> 0 goto E_Error
		
--	return

E_Error:
	set @FacilityNo = null
    set @Res=@@error
    return
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_AddMechanicalEquipment_NewSite]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* spn_inv_AddMechanicalEquipment_NewSite 
**	on CMMS/Asset inventory Web site, create a new Mechanical Facility into table invFacility first, as a simple Record as Equiment,
	It only accepts ALL system columns. NEED to include 25 details columns, which will be taken care,
	
**	Parameter: FacilitySystem, ...etc
	Return: Facility#
**	return values as @RES: 0 means successfully; - 1 means missing paras. otherwise, @@error as SQL Server error number
*/


Alter Procedure [dbo].[spn_inv_AddMechanicalEquipment_NewSite]
	(
		@FacilitySystem varchar(50),		-- required, from table invFacilitySystem after user selects.
		@Comments varchar(255),
		@Building varchar(50),			-- required
		@Floor varchar(20),			
		@FacilityLocation varchar(50),	-- required
		@FacilityID varchar(50),		-- required - not the Facility#
		@WorkRequestNo varchar(50),
		@Function varchar(50),
		@BSL smallint,				-- default 0
		@AAALAC smallint,			-- default 0
		@TJC smallint,				-- default 0
--		@EquipmentID varchar(50),
--		@EquipmentLocation varchar(50),
--		@TypeorUse varchar(50),
		@Manufacturer varchar(50),
		@ModelNo varchar(50),
		@SerialNo varchar(50),
		@Size varchar(50),
		@InstallDate date,
		@Capacity varchar(50),
		@CapacityHeadTest varchar(50),
		@FuelRefrigeration varchar(50),
		@MotorManufacturer varchar(50),
		@HP varchar(50),
		@MotorType varchar(50),
		@MotorSerialNo varchar(50),
		@MotorInstallDate date,
		@MotorModel varchar(50),
		@Frame varchar(50),
		@RPM varchar(50),
		@Voltage varchar(50),
		@Amperes varchar(50),
		@PhaseCycle varchar(50),
		@BSLClassification varchar(50),
		@TJCValue int,
		@PMSchedule varchar(50),
				
		@UserName varchar(50),				-- required
		@FacilityNo varchar(50) OUTPUT,		-- return a new Facility# as Temporary
		@Res int OUTPUT,
		@ID_table int OUTPUT		
	)
AS
declare @SystemGroup as varchar(50)
--declare @SystemTitle as varchar(50)
declare @iden as int
declare @Property as varchar(50)

set @iden = 0

Set @Res = 0

	/* initially, check key fields. If null then, return -1  */	
	if @Building is null or @FacilitySystem is null or @FacilityLocation is null or @FacilityID is null
	Begin
		set @FacilityNo = null
		set @Res=-1
		return
	End
		
	select @Property = Property
	from dbo.InvBuilding where Building = @Building and Active = -1
	
	if @@error<> 0 GOTO E_Error
	
--	select @SystemGroup = SystemGroup, @SystemTitle = SystemTitle
--	from dbo.InvFacilitySystem where id = @facilitySystemID
	
--	if @@error<> 0 GOTO E_Error
	
	set @SystemGroup = 'Mechanical Equipment' -- required in the table of invFacility

	/* second, create an individula record of mecahnical equipment into table*/

		set @iden = IDENT_CURRENT('invFacility')+1
		
		set @FacilityNo = 'T' + RIGHT(Convert(varchar(6),100000+@iden), 5)
					
		Insert into	dbo.InvFacility([WorkRequest#],[Facility#],[Facility#Temp],[FacilitySystem],[FacilityGroup],[FacilityFunction],
           [FacilityID],[Comments],[Property],[Building],[Floor],[Location],[BSL],[AAALAC],[TJC],[Manufacturer],[Model],[SerialNo],
           [Size],[InstallDate],[Capacity],[CapacityHeadTest],[FuelRefrigeration],[MotorManufacturer],
           [HP],[MotorType],[MotorSerialNo],[MotorInstallDate],[MotorModel],[Frame],[RPM],[Voltage],[Amperes],[PhaseCycle],[BSLClassification],
           [TJCValue],[PMSchedule],[InputBy])
		VALUES
           ( @WorkRequestNo,@FacilityNo,@FacilityNo,@FacilitySystem,@SystemGroup,@Function,@FacilityID, @Comments, @Property, @Building,
           @Floor,@FacilityLocation,@BSL,@AAALAC,@TJC,@Manufacturer,@ModelNo,@SerialNo,@Size,@InstallDate,@Capacity,@CapacityHeadTest,
           @FuelRefrigeration, @MotorManufacturer, @HP, @MotorType,@MotorSerialNo, @MotorInstallDate, @MotorModel, @Frame, @RPM, @Voltage,
           @Amperes,@PhaseCycle, @BSLClassification,@TJCValue,@PMSchedule,@UserName)
           SELECT @ID_table = @@IDENTITY
					 
		If @@error <> 0	GOTO E_Error
		
		return


E_Error:
	set @FacilityNo = null
    set @Res=@@error
    return
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_AddElectricalSystem_NewSite ]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* spn_inv_AddElectricalSystem_NewSite 
**	on CMMS/Asset inventory Web site, create a new Electrical System Facility into table invFacility first.
	It only accepts the common system columns. NO NEED to include other details columns for Electrical, which will be taken by spn_inv_AddElectricalComponent_NewSite 
	after the new facility record is created into the table.
	
**	Parameter: FacilitySystem, ...etc
	Return: Facility#
**	return values as @RES: 0 means successfully; - 1 means missing paras. otherwise, @@error as SQL Server error number
*/


Alter Procedure [dbo].[spn_inv_AddElectricalSystem_NewSite ]
	(
		@FacilitySystem varchar(50),		-- required, from table invFacilitySystem after user selects.
		@Comments varchar(255),
		@Building varchar(50),			-- required
		@Floor varchar(20),			
		@FacilityLocation varchar(50),	-- required
		@FacilityID varchar(50),		-- required - not the Facility#
		@WorkRequestNo varchar(50),
		@Function varchar(50),
		@BSL smallint,				-- default 0
		@AAALAC smallint,			-- default 0
		@TJC smallint,				-- default 0
--		@EquipmentID varchar(50),
--		@EquipmentLocation varchar(50),
--		@TypeorUse varchar(50),
		@Manufacturer varchar(50),
		@ModelNo varchar(50),
		@SerialNo varchar(50),
		@Size varchar(50),
		@InstallDate date,
--		@Capacity varchar(50),
--		@CapacityHeadTest varchar(50),
--		@FuelRefrigeration varchar(50),
--		@MotorManufacturer varchar(50),
--		@HP varchar(50),
--		@MotorType varchar(50),
--		@MotorSerialNo varchar(50),
--		@MotorInstallDate date,
--		@MotorModel varchar(50),
--		@Frame varchar(50),
--		@RPM varchar(50),
--		@Voltage varchar(50),
--		@Amperes varchar(50),
--		@PhaseCycle varchar(50),
--		@BSLClassification varchar(50),
--		@TJCValue int,
--		@PMSchedule varchar(50),
				
		@UserName varchar(50),				-- required
		@FacilityNo varchar(50) OUTPUT,		-- return a new Facility# as Temporary
		@Res int OUTPUT		
	)
AS
declare @SystemGroup as varchar(50)
declare @SystemTitle as varchar(50)
declare @iden as int
declare @Property as varchar(50)

set @iden = 0

Set @Res = 0

	/* initially, check key fields. If null then, return -1  */	
	if @Building is null or @FacilitySystem is null or @FacilityLocation is null or @FacilityID is null
	Begin
		set @FacilityNo = null
		set @Res=-1
		return
	End
		
	select @Property = Property
	from dbo.InvBuilding where Building = @Building and Active = -1
	
	if @@error<> 0 GOTO E_Error
	
--	select @SystemGroup = SystemGroup, @SystemTitle = SystemTitle
--	from dbo.InvFacilitySystem where id = @facilitySystemID
	
--	if @@error<> 0 GOTO E_Error
	
	set @SystemGroup = 'Electrical System' -- required in the table of invFacility

	/* second, create a record of mecahnical system only into table*/
--	if @EquipmentID is null
--	begin
		
		set @iden = IDENT_CURRENT('invFacility')+1
		
		set @FacilityNo = 'T' + RIGHT(Convert(varchar(6),100000+@iden), 5)
					
		Insert into	dbo.InvFacility([WorkRequest#],[Facility#],[Facility#Temp],[FacilitySystem],[FacilityGroup],[FacilityFunction],
           [FacilityID],[Comments],[Property],[Building],[Floor],[Location],[BSL],[AAALAC],[TJC],
           [Manufacturer],[Model],[SerialNo],[Size],[InstallDate],[InputBy])
		VALUES
           ( @WorkRequestNo,@FacilityNo,@FacilityNo,@FacilitySystem,@SystemGroup,@Function,@FacilityID, @Comments, @Property, @Building,
           @Floor,@FacilityLocation,@BSL,@AAALAC,@TJC,@Manufacturer,@ModelNo,@SerialNo,@Size,@InstallDate,@UserName)
           
		If @@error <> 0	GOTO E_Error
		
		return

		--select @NewWRnumber=@@identity
--	end

--	/*otherwise, create a Facility and Equipment*/
	
--	set @iden = IDENT_CURRENT('invFacility')+1
		
--	set @FacilityNo = 'T' + RIGHT(Convert(varchar(6),100000+@iden), 5)
				
--	Insert into	dbo.InvFacility([WorkRequest#],[Facility#],[Facility#Temp],[FacilitySystem],[FacilityGroup],[FacilityFunction],
--           [FacilityID],[Comments],[Property],[Building],[Floor],[Location],[BSL],[AAALAC],[TJC],[InputBy])
--	VALUES(@WorkRequestNo,@FacilityNo,@FacilityNo,@System,@FacilityGroup,@Function,@FacilityID, @Comments, @Property, @Building,
--           @Floor,@FacilityLocation,@BSL,@AAALAC,@TJC,@UserName)
           
--		If @@error <> 0	GOTO E_Error
	
--	exec [dbo].[spn_inv_AddEquipment] @EquipmentID = @EquipmentID, @EquipmentLocation = @EquipmentLocation, @TypeorUse = @TypeorUse,
--		@Manufacturer = @Manufacturer, 	@ModelNo = @ModelNo, @SerialNo = @SerialNo, @Size = @Size, @InstallDate = @InstallDate,
--		@Capacity = @Capacity, 	@CapacityHeadTest= @CapacityHeadTest, @FuelRefrigeration = @FuelRefrigeration, 
--		@MotorManufacturer = @MotorManufacturer, @HP = @HP, @MotorType = @MotorType, @MotorSerialNo=@MotorSerialNo,
--		@MotorInstallDate = @MotorInstallDate, @MotorModel=@MotorModel, @Frame = @Frame, @RPM = @RPM, @Voltage = @Voltage,
--		@Amperes = @Amperes,	@PhaseCycle=@PhaseCycle, @BSLClassification = @BSLClassification, @TJCValue = @TJCValue,
--		@PMSchedule = @PMSchedule, @UserName = @UserName, @ParentFacilityNo = @FacilityNo, @EquipmentSerial = 1, @res = @res OUTPUT

--	if @res <> 0 goto E_Error
		
--	return

E_Error:
	set @FacilityNo = null
    set @Res=@@error
    return
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_AddElectricalEquipment_NewSite ]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* spn_inv_AddElectricalEquipment_NewSite 
**	on CMMS/Asset inventory Web site, create a new Electrical Equipment directly into table invFacility.
	It accepts all columns. NEED to include all Electrical columns, which will be taken care.
	
**	Parameter: FacilitySystem, ...etc
	Return: Facility#
**	return values as @RES: 0 means successfully; - 1 means missing paras. otherwise, @@error as SQL Server error number
*/


Alter Procedure [dbo].[spn_inv_AddElectricalEquipment_NewSite ]
	(
		@FacilitySystem varchar(50),		-- required, from table invFacilitySystem after user selects.
		
		@Comments varchar(255),
		@Building varchar(50),			-- required
		@Floor varchar(20),			
		@FacilityLocation varchar(50),	-- required
		@FacilityID varchar(50),		-- required - not the Facility#
		@WorkRequestNo varchar(50),
		@Function varchar(50),
		@BSL smallint,				-- default 0
		@AAALAC smallint,			-- default 0
		@TJC smallint,				-- default 0
--		@EquipmentID varchar(50),
--		@EquipmentLocation varchar(50),
--		@TypeorUse varchar(50),
		@Manufacturer varchar(50),
		@ModelNo varchar(50),
		@SerialNo varchar(50),
		@Size varchar(50),
		@InstallDate date,
--		@Capacity varchar(50),
--		@CapacityHeadTest varchar(50),
--		@FuelRefrigeration varchar(50),
---		@MotorManufacturer varchar(50),
--		@HP varchar(50),
--		@MotorType varchar(50),
--		@MotorSerialNo varchar(50),
--		@MotorInstallDate date,
--		@MotorModel varchar(50),
--		@Frame varchar(50),
--		@RPM varchar(50),
--		@Voltage varchar(50),
--		@Amperes varchar(50),
--		@PhaseCycle varchar(50),
		@BSLClassification varchar(50),
		@TJCValue int,
		@PMSchedule varchar(50),

		@VOLTS varchar(20),
		@AMP varchar(20),
		@KVA varchar(20),
		@VOLTSprimary varchar(20),
		@VOLTSSecondary varchar(20),
		@PH varchar(6),
		@W varchar(6),
		@NOofCKTS varchar(6),
		@CKTSUsed varchar(6),
		@ElectricalOther varchar(50),
				
		@UserName varchar(50),				-- required
		@inventoryby varchar(50),			-- recommendation
		@inventoryDate Datetime,			-- recommendation
		@ID_table int OUTPUT,		
		@FacilityNo varchar(50) OUTPUT,		-- return a new Facility# as Temporary
		@Res int OUTPUT		
	)
AS
declare @SystemGroup as varchar(50)
--declare @SystemTitle as varchar(50)
declare @iden as int
declare @Property as varchar(50)

set @iden = 0

Set @Res = 0

	/* initially, check key fields. If null then, return -1  */	
	if @Building is null or @FacilitySystem is null or @FacilityLocation is null or @FacilityID is null
	Begin
		set @FacilityNo = null
		set @Res=-1
		return
	End
		
	select @Property = Property
	from dbo.InvBuilding where Building = @Building and Active = -1
	
	if @@error<> 0 GOTO E_Error
	
--	select @SystemGroup = SystemGroup, @SystemTitle = SystemTitle
--	from dbo.InvFacilitySystem where id = @facilitySystemID
	
--	if @@error<> 0 GOTO E_Error
	
	set @SystemGroup = 'Electrical Equipment' -- required in the table of invFacility

	/* second, create a record of mecahnical system only into table*/
--	begin
		
		set @iden = IDENT_CURRENT('invFacility')+1
		
		set @FacilityNo = 'T' + RIGHT(Convert(varchar(6),100000+@iden), 5)
					
		Insert into	dbo.InvFacility([WorkRequest#],[Facility#],[Facility#Temp],[FacilitySystem],[FacilityGroup],[FacilityFunction],
           [FacilityID],[Comments],[Property],[Building],[Floor],[Location],[BSL],[AAALAC],[TJC],
           [Manufacturer],[Model],[SerialNo],[Size],[InstallDate],ElectricalOther,[VOLTS],[AMP],[KVA],[VOLTSprimary],
           [VOLTSSecondary],[PH],[W],[NOofCKTS],[CKTSUsed],[InputBy], [InventoryBy], [inventorydate] ,[BSLClassification],
           [TJCValue],[PMSchedule])
		VALUES
           ( @WorkRequestNo,@FacilityNo,@FacilityNo,@FacilitySystem,@SystemGroup,@Function,@FacilityID, @Comments, @Property, @Building,
           @Floor,@FacilityLocation,@BSL,@AAALAC,@TJC,@Manufacturer,@ModelNo,@SerialNo,@Size,@InstallDate,
           @ElectricalOther,@VOLTS,@AMP,@KVA,@VOLTSprimary,@VOLTSSecondary,@PH,@W,@NOofCKTS,@CKTSUsed,
           @UserName, @inventoryby, @inventoryDate, @BSLClassification,@TJCValue,@PMSchedule)
       SELECT @ID_table = @@IDENTITY
					
		If @@error <> 0	GOTO E_Error
		
		return


E_Error:
	set @FacilityNo = null
    set @Res=@@error
    return
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_GetBuildingList_Search]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Alter Procedure [dbo].[spn_Inv_GetBuildingList_Search]
AS
Select ID as [Key], Building as [Description]
from InvBuilding
Where active=-1
Order By Building ASC
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_GetBuildingList]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Alter Procedure [dbo].[spn_Inv_GetBuildingList]
AS
Select distinct Building
from InvBuilding
Where active=-1
Order By Building ASC
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_updateAttachment]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Alter Procedure [dbo].[spn_inv_updateAttachment]
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
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_GetAttachmentList]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Alter Procedure [dbo].[spn_Inv_GetAttachmentList]
(
		@isEquipmentOrFacility bit, -- required
		@parentSysId int
	)
AS
 
IF @isEquipmentOrFacility = 1
	SELECT [ID]
      ,[InvEquipmentID] as InvParentSysID
      ,[FileName]
      ,[ContentType]
      ,[Data]
      ,[CreatedOn]
      ,[CreatedBy]
      ,[IsActive]
      ,[Title]
	FROM [dbo].[InvEquipmentAttachment]
		where InvEquipmentID = @parentSysId and IsActive = 1
		order by Title
ELSE
	SELECT [ID]
      ,[InvFacilityID] as InvParentSysID
      ,[FileName]
      ,[ContentType]
      ,[Data]
      ,[CreatedOn]
      ,[CreatedBy]
      ,[IsActive]
      ,[Title]
	FROM [dbo].[InvFacilityAttachment]
		where InvFacilityID = @parentSysId and IsActive = 1
		order by Title
GO
/****** Object:  StoredProcedure [dbo].[spn_Inv_GetAttachmentByID]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Alter Procedure [dbo].[spn_Inv_GetAttachmentByID]
(
		@isEquipmentOrFacility bit, -- required
		@attachmentSysId int
	)
AS
Begin
IF @isEquipmentOrFacility = 1 
	SELECT [ID]
      ,[InvEquipmentID] as InvParentSysID
      ,[FileName]
      ,[ContentType]
      ,[Data]
      ,[CreatedOn]
      ,[CreatedBy]
      ,[IsActive]
      ,[Title]
	FROM [dbo].[InvEquipmentAttachment]
	where ID = @attachmentSysId
ELSE
	SELECT [ID]
      ,[InvFacilityID] as InvParentSysID
      ,[FileName]
      ,[ContentType]
      ,[Data]
      ,[CreatedOn]
      ,[CreatedBy]
      ,[IsActive]
      ,[Title]
	FROM [dbo].[InvFacilityAttachment]
	where ID = @attachmentSysId
End
GO
/****** Object:  StoredProcedure [dbo].[spn_inv_deleteAttachment]    Script Date: 10/01/2016 22:39:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Alter Procedure [dbo].[spn_inv_deleteAttachment]
	(
		@isEquipmentOrFacility bit, -- required
		@attachmentSysId int,		-- required
		@Res int OUTPUT			
	)
AS
Begin
declare @EquipmentGroup as varchar(50)
declare @EquipmentSystem as varchar(50)

Set @Res = 0

	/* initially, check key fields. If null then, return -1  */	
	if @attachmentSysId is null
	Begin
		set @Res=-1
		return
	End
	IF @isEquipmentOrFacility = 1
	BEGIN
		delete from InvEquipmentAttachment where ID = @attachmentSysId
	END
	ELSE
	BEGIN
		delete from InvFacilityAttachment where ID = @attachmentSysId
	END
					
	if @@error<> 0 GOTO E_Error
                                      			
	return	
	
E_Error:
    set @Res=@@error
    return	
End
GO
