DROP PROC If exists InsertLinkFlatLocationEquipmentProcedure
GO
CREATE PROCEDURE InsertLinkFlatLocationEquipmentProcedure
AS

DECLARE @dts nvarchar(100)
SET @dts = getdate()

DECLARE @sourceID nvarchar(100)
SET @sourceID = newID()

CREATE TABLE #STAGE_SOURCE
(
	LinkFlatLocationEquipmentHK nvarchar(128),
	RecordSourceId nvarchar(128) NOT NULL,
	LoadDate datetime NOT NULL, 
	CityHK nvarchar(128) NULL,
	DistrictHK nvarchar(128) NULL,
	FlatHK nvarchar(128) NULL,
	EquipmentHK nvarchar(128) NULL,
);

INSERT INTO #STAGE_SOURCE (LinkFlatLocationEquipmentHK,RecordSourceId,LoadDate,CityHK,DistrictHK,FlatHK,EquipmentHK)
select CONVERT(VARCHAR(128),HASHBYTES('MD5', CONCAT(HC.HubCityHK,HD.HubDistrictHK,HF.HubFlatHK,HE.HubEquipmentHK)),2) as LinkFlatLocationEquipmentHK
,@sourceID, @dts,HC.HubCityHK, HD.HubDistrictHK, HF.HubFlatHK, HE.HubEquipmentHK from stage.AllListings as STG 
inner join HUB_CITY as HC on STG.City = HC.City
inner join HUB_DISTRICT as HD on STG.District = HD.District
inner join HUB_FLAT as HF on STG.href = HF.href
inner join HUB_EQUIPMENT as HE on STG.Equipment = HE.Equipment


INSERT INTO dbo.LINK_FLATLOCATIONEQUIPMENT (
   LinkFlatLocationEquipmentHK,
   RecordSourceId,
   LoadDate,
   CityHK,
   DistrictHK,
   FlatHK,
   EquipmentHK
)
SELECT DISTINCT 
   STG.LinkFlatLocationEquipmentHK,
   STG.RecordSourceId,
   STG.LoadDate,
   STG.CityHK,
   STG.DistrictHK,
   STG.FlatHK,
   STG.EquipmentHK
FROM 
   #STAGE_SOURCE AS STG 
   LEFT OUTER JOIN 
   LINK_FLATLOCATIONEQUIPMENT on 
      LINK_FLATLOCATIONEQUIPMENT.LinkFlatLocationEquipmentHK = STG.LinkFlatLocationEquipmentHK 
WHERE 
   LINK_FLATLOCATIONEQUIPMENT.RecordSourceId is null;

EXEC InsertLinkFlatLocationEquipmentProcedure

