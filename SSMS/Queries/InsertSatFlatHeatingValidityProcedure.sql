DROP PROC If exists InsertSatFlatHeatingValidityProcedure
GO
CREATE PROCEDURE InsertSatFlatHeatingValidityProcedure
AS

DECLARE @sourceID nvarchar(100)
SET @sourceID = '800A44D4-2350-4CA9-B1AA-1D4EBA7C16DA'--newID()

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
	Heating_Type nvarchar(255)
);



INSERT INTO ##STAGE_SOURCE (RecordSourceId,LoadDate,ValidTo,Validity, href, Heating_Type)
select @sourceID, STG.LOAD_DTS, null, 1, STG.href, STG.Heating_Type
from stage.AllListings as STG 

exec DynamicRowHash 'HUB_FLAT', 'FlatHK', 0
exec DynamicRowHash 'HUB_HEATING', 'HeatingHK', 0
exec DynamicRowHash 'LINK_FLATSHEATING', 'HK', 1


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
      SAT_FLATHEATINGVALIDITY.HK = STG.HK and SAT_FLATHEATINGVALIDITY.LoadDate = STG.LoadDate
WHERE 
   SAT_FLATHEATINGVALIDITY.HK is null;
   
DROP TABLE ##STAGE_SOURCE


EXEC InsertSatFlatHeatingValidityProcedure

