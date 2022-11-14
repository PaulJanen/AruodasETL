DROP PROC If exists InsertSatFlatProcedure
GO
CREATE PROCEDURE InsertSatFlatProcedure
AS

DECLARE @sourceID nvarchar(100)
SET @sourceID = '800A44D4-2350-4CA9-B1AA-1D4EBA7C16DA'--newID()

CREATE TABLE ##STAGE_SOURCE
(
	HK nvarchar(128),
	RecordSourceId nvarchar(255) NOT NULL,
	LoadDate datetime NOT NULL,
	LoadEndDate datetime NULL,
	Price decimal(18,0) NULL,
	PricePerM2 decimal(18,0) NULL,
	Area decimal(18,0) NULL,
	[Floor] int NULL,
	NumberOfFloors int NULL,
	RoomCount int NULL,
	BuiltYear datetime NULL,
	href nvarchar(1024),
	ColumnHash nvarchar(128)
);



INSERT INTO ##STAGE_SOURCE (RecordSourceId,LoadDate,LoadEndDate,Price,PricePerM2,Area,[Floor],NumberOfFloors,RoomCount,BuiltYear, href)
select @sourceID, STG.LOAD_DTS, null, STG.Price, STG.PricePerM2, STG.Area, 
		STG.[floor], STG.[Number of floors], STG.[Room count], STG.[Built year], STG.href
from stage.AllListings as STG 
inner join HUB_FLAT as HF on STG.href = HF.href

exec DynamicRowHash 'HUB_FLAT', 'HK', 0

Update ##STAGE_SOURCE 
SET ColumnHash = CONVERT(VARCHAR(128),HASHBYTES('MD5', CONCAT(
		HK, @sourceID, LoadDate, null, Price, PricePerM2, Area, [floor], NumberOfFloors, RoomCount, Builtyear)),2)



INSERT INTO dbo.SAT_FLAT (
	 [HK]
	,[RecordSourceId]
	,[LoadDate]
	,[LoadEndDate]
	,[Price]
	,[PricePerM2]
	,[Area]
	,[Floor]
	,[NumberOfFloors]
	,[RoomCount]
	,[BuiltYear]
	,[ColumnHash]
)
SELECT DISTINCT 
     STG.[HK]
	,STG.[RecordSourceId]
	,STG.[LoadDate]
	,STG.[LoadEndDate]
	,STG.[Price]
	,STG.[PricePerM2]
	,STG.[Area]
	,STG.[Floor]
	,STG.[NumberOfFloors]
	,STG.[RoomCount]
	,STG.[BuiltYear]
	,STG.[ColumnHash]
FROM 
   ##STAGE_SOURCE AS STG 
   LEFT OUTER JOIN 
   SAT_FLAT on 
      SAT_FLAT.ColumnHash = STG.ColumnHash 
WHERE 
   SAT_FLAT.HK is null;

DROP TABLE IF EXISTS ##STAGE_SOURCE
   
EXEC InsertSatFlatProcedure

