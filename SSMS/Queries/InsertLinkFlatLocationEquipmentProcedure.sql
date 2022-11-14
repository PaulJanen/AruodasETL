DROP PROC If exists InsertLinkFlatLocationEquipmentProcedure
GO
CREATE PROCEDURE InsertLinkFlatLocationEquipmentProcedure
AS

DECLARE @dts nvarchar(100)
SET @dts = getdate()

DECLARE @sourceID nvarchar(100)
SET @sourceID = '800A44D4-2350-4CA9-B1AA-1D4EBA7C16DA'

CREATE TABLE ##STAGE_SOURCE
(
	HK nvarchar(128),
	RecordSourceId nvarchar(128) NOT NULL,
	LoadDate datetime NOT NULL, 
	CityHK nvarchar(128) NULL,
	DistrictHK nvarchar(128) NULL,
	FlatHK nvarchar(128) NULL,
	EquipmentHK nvarchar(128) NULL,
	Href nvarchar(1024),
	City nvarchar(255),
	District nvarchar(255),
	Equipment nvarchar(255),
);

INSERT INTO ##STAGE_SOURCE (RecordSourceId,LoadDate, Href, City, District, Equipment)
select @sourceID, @dts, href, City, District, Equipment from stage.AllListings
					  
--inner join HUB_CITY as HC on STG.City = HC.City
--inner join HUB_DISTRICT as HD on STG.District = HD.District
--inner join HUB_FLAT as HF on STG.href = HF.href
--inner join HUB_EQUIPMENT as HE on STG.Equipment = HE.Equipment


exec DynamicRowHash 'HUB_FLAT', 'FlatHK', 0
exec DynamicRowHash 'HUB_CITY', 'CityHK', 0
exec DynamicRowHash 'HUB_DISTRICT', 'DistrictHK', 0
exec DynamicRowHash 'HUB_EQUIPMENT', 'EquipmentHK', 0
exec DynamicRowHash '##STAGE_SOURCE', 'HK', 1

INSERT INTO dbo.LINK_FLATLOCATIONEQUIPMENT (
   HK
   ,RecordSourceId
   ,LoadDate
   ,CityHK
   ,DistrictHK
   ,FlatHK
   ,EquipmentHK
   ,Href
   ,City
   ,District
   ,Equipment
)
SELECT DISTINCT 
   STG.HK
   ,STG.RecordSourceId
   ,STG.LoadDate
   ,STG.CityHK
   ,STG.DistrictHK
   ,STG.FlatHK
   ,STG.EquipmentHK
   ,STG.Href
   ,STG.City
   ,STG.District
   ,STG.Equipment
FROM 
   ##STAGE_SOURCE AS STG 
   LEFT OUTER JOIN 
   LINK_FLATLOCATIONEQUIPMENT on 
      LINK_FLATLOCATIONEQUIPMENT.HK = STG.HK
WHERE 
   LINK_FLATLOCATIONEQUIPMENT.RecordSourceId is null;

Drop table if exists ##STAGE_SOURCE

EXEC InsertLinkFlatLocationEquipmentProcedure