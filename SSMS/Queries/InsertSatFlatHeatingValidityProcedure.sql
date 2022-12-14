DROP PROC If exists InsertSatFlatHeatingValidityProcedure
GO
CREATE PROCEDURE InsertSatFlatHeatingValidityProcedure
AS

DECLARE @sourceID nvarchar(100)
SET @sourceID = '800A44D4-2350-4CA9-B1AA-1D4EBA7C16DA'--newID()
DECLARE @loadDate datetime
SET @loadDate = getdate()

CREATE TABLE ##STAGE_SOURCE
(
	HK nvarchar(128),
	FlatHK nvarchar(128),
	HeatingHK nvarchar(128),
	RecordSourceId nvarchar(255),
	LoadDate datetime,
	ValidTo datetime,
	Validity bit,
	href nvarchar(1024),
	ScrapingDate date,
	Heating_Type nvarchar(255)
);



INSERT INTO ##STAGE_SOURCE (RecordSourceId,LoadDate,ValidTo,Validity, href, Heating_Type, ScrapingDate)
select @sourceID, @loadDate, null, 1, STG.href, STG.Heating_Type, STG.ScrapingDate
from stage.AllListings as STG

exec DynamicRowHash 'HUB_FLAT', 'FlatHK', 0
exec DynamicRowHash 'HUB_HEATING', 'HeatingHK', 0
exec DynamicRowHash 'LINK_FLATSHEATING', 'HK', 0


INSERT INTO dbo.SAT_FLATHEATINGVALIDITY (
		 [HK]
		,[FlatHK]
		,[HeatingHK]
		,[RecordSourceId]
		,[LoadDate]
		,[ValidTo]
		,[Validity]
)
SELECT DISTINCT
		 STG.[HK]
		,STG.[FlatHK]
		,STG.[HeatingHK]
		,STG.[RecordSourceId]
		,STG.[LoadDate]
		,STG.[ValidTo]
		,STG.[Validity]
FROM 
   ##STAGE_SOURCE AS STG 
   LEFT OUTER JOIN 
   SAT_FLATHEATINGVALIDITY on 
	   SAT_FLATHEATINGVALIDITY.HK = STG.HK and SAT_FLATHEATINGVALIDITY.Validity = STG.Validity
      --SAT_FLATHEATINGVALIDITY.FlatHK = STG.FlatHK and SAT_FLATHEATINGVALIDITY.HeatingHK = STG.HeatingHK
	  --and SAT_FLATHEATINGVALIDITY.LoadDate != STG.LoadDate and SAT_FLATHEATINGVALIDITY.[ScrapingDate] = STG.[ScrapingDate]
WHERE 
   SAT_FLATHEATINGVALIDITY.HK is null;
   
DROP TABLE ##STAGE_SOURCE


--EXEC InsertSatFlatHeatingValidityProcedure


  select * from [SAT_FLAT] where HK = 'DDD669C67DB5D602615711F0B4C2F2FE'
  select * from LINK_FLATSHEATING where FlatHK = 'DDD669C67DB5D602615711F0B4C2F2FE'
  select * from HUB_HEATING
  select * from SAT_FLATHEATINGVALIDITY where FlatHK = 'DDD669C67DB5D602615711F0B4C2F2FE'
  select * from HUB_FLAT where HK = 'DDD669C67DB5D602615711F0B4C2F2FE'