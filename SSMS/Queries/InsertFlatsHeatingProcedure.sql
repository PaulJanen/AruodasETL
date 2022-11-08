DROP PROC If exists InsertFlatsHeatingProcedure
GO
CREATE PROCEDURE InsertFlatsHeatingProcedure
AS

DECLARE @dts nvarchar(100)
SET @dts = getdate()

DECLARE @sourceID nvarchar(100)
SET @sourceID = newID()

CREATE TABLE #STAGE_SOURCE
(
	FlatHeatingHK nvarchar(128),
	RecordSourceId nvarchar(128) NOT NULL,
	LoadDate datetime NOT NULL,
	FlatHK nvarchar(128) NULL,
	HeatingHK nvarchar(128) NULL,
);

INSERT INTO #STAGE_SOURCE (FlatHeatingHK,RecordSourceId,LoadDate,FlatHK,HeatingHK)
select CONVERT(VARCHAR(128),HASHBYTES('MD5', CONCAT(HF.HubFlatHK,HH.HubHeatingHK)),2) as FlatHeatingHK
,@sourceID, @dts, HF.HubFlatHK, HH.HubHeatingHK from stage.AllListings as STG 
inner join HUB_FLAT as HF on STG.href = HF.href
inner join HUB_HEATING as HH on STG.Heating_Type = HH.Heating_Type


INSERT INTO dbo.LINK_FLATSHEATING(
   FlatHeatingHK,
   RecordSourceId,
   LoadDate,
   FlatHK,
   HeatingHK
)
SELECT DISTINCT 
   STG.FlatHeatingHK,
   STG.RecordSourceId,
   STG.LoadDate,
   STG.FlatHK,
   STG.HeatingHK
FROM 
   #STAGE_SOURCE AS STG 
   LEFT OUTER JOIN 
   LINK_FLATSHEATING on 
      LINK_FLATSHEATING.FlatHeatingHK = STG.FlatHeatingHK 
WHERE 
   LINK_FLATSHEATING.RecordSourceId is null;

EXEC InsertFlatsHeatingProcedure

