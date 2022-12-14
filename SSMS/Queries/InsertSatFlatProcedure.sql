DROP PROC If exists InsertSatFlatProcedure
GO
CREATE PROCEDURE InsertSatFlatProcedure
AS

DECLARE @sourceID nvarchar(100)
SET @sourceID = '800A44D4-2350-4CA9-B1AA-1D4EBA7C16DA'--newID()

DECLARE @loadDate datetime
SET @loadDate = getdate()
select @loadDate

CREATE TABLE ##STAGE_SOURCE
(
	HK nvarchar(128),
	RecordSourceId nvarchar(255) NOT NULL,
	LoadDate datetime NOT NULL,
	LoadEndDate datetime NULL,
	Price decimal(18,2) NULL,
	PredictedPrice decimal(18,2) NULL,
	Gains decimal(18,2) NULL,
	PricePerM2 decimal(18,2) NULL,
	Area decimal(18,2) NULL,
	[Floor] int NULL,
	NumberOfFloors int NULL,
	RoomCount int NULL,
	[NearestKindergarten] decimal(18,2),
	[NearestEducational] decimal(18,2),
	[NearestShop] decimal(18,2),
	[NearestStop] decimal(18,2),
	[CrimeRate] int,
	BuiltYear date NULL,
	href nvarchar(1024),
	ScrapingDate date,
	ColumnHash nvarchar(128)
);



INSERT INTO ##STAGE_SOURCE (RecordSourceId,LoadDate,LoadEndDate,Price,PredictedPrice,Gains,PricePerM2,Area,[Floor],NumberOfFloors,RoomCount,
							NearestKindergarten,NearestEducational,NearestShop,NearestStop,CrimeRate,BuiltYear, href, ScrapingDate)
select @sourceID, @loadDate, null, STG.Price, STG.PredictedPrice, STG.PredictedPrice - STG.Price, STG.PricePerM2, STG.Area, 
		STG.[floor], STG.[Number of floors], STG.[Room count], STG.NearestKindergarten,STG.NearestEducational,STG.NearestShop,
		STG.NearestStop, STG.CrimeRate, STG.[Built year], STG.href, STG.ScrapingDate
from stage.AllListings as STG
inner join HUB_FLAT as HF on STG.href = HF.href

exec DynamicRowHash 'HUB_FLAT', 'HK', 0

Update ##STAGE_SOURCE 
SET ColumnHash = CONVERT(VARCHAR(128),HASHBYTES('MD5', CONCAT(
		HK, @sourceID, null, Price, PricePerM2, Area, [floor], NumberOfFloors, RoomCount
		,NearestKindergarten, NearestEducational, NearestShop, NearestStop, CrimeRate, Builtyear, ScrapingDate)),2)



INSERT INTO dbo.SAT_FLAT (
	 [HK]
	,[RecordSourceId]
	,[LoadDate]
	,[LoadEndDate]
	,[Price]
	,[PredictedPrice]
	,[Gains]
	,[PricePerM2]
	,[Area]
	,[Floor]
	,[NumberOfFloors]
	,[RoomCount]
	,[NearestKindergarten]
	,[NearestEducational]
	,[NearestShop]
	,[NearestStop]
	,[CrimeRate]
	,[BuiltYear]
	,[ScrapingDate]
	,[ColumnHash]
)
SELECT DISTINCT 
     STG.[HK]
	,STG.[RecordSourceId]
	,STG.[LoadDate]
	,STG.[LoadEndDate]
	,STG.[Price]
	,STG.[PredictedPrice]
	,STG.[Gains]
	,STG.[PricePerM2]
	,STG.[Area]
	,STG.[Floor]
	,STG.[NumberOfFloors]
	,STG.[RoomCount]
	,STG.[NearestKindergarten]
	,STG.[NearestEducational]
	,STG.[NearestShop]
	,STG.[NearestStop]
	,STG.[CrimeRate]
	,STG.[BuiltYear]
	,STG.[ScrapingDate]
	,STG.[ColumnHash]
FROM 
   ##STAGE_SOURCE AS STG 
   LEFT OUTER JOIN 
   SAT_FLAT on 
      SAT_FLAT.ColumnHash = STG.ColumnHash 
WHERE 
   SAT_FLAT.HK is null;

DROP TABLE IF EXISTS ##STAGE_SOURCE
   
--EXEC InsertSatFlatProcedure

