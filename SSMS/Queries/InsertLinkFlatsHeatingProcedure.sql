DROP PROC If exists InsertLinkFlatsHeatingProcedure
GO
CREATE PROCEDURE InsertLinkFlatsHeatingProcedure
AS

DECLARE @dts nvarchar(100)
SET @dts = getdate()

DECLARE @sourceID nvarchar(100)
SET @sourceID = '800A44D4-2350-4CA9-B1AA-1D4EBA7C16DA'

CREATE TABLE ##STAGE_SOURCE
(
	HK nvarchar(128),
	RecordSourceId nvarchar(128) NULL,
	LoadDate datetime NULL,
	FlatHK nvarchar(128) NULL,
	HeatingHK nvarchar(128) NULL,
	href nvarchar (1024),
	Heating_Type nvarchar(255),
);

INSERT INTO ##STAGE_SOURCE (RecordSourceId,LoadDate,href, Heating_Type)
select @sourceID, @dts
					  --, CONVERT(NVARCHAR(128),HASHBYTES('MD5', CONCAT('1',CAST(UPPER(href) as nvarchar(max)))),2)
					  --, CONVERT(VARCHAR(128),HASHBYTES('MD5', CONCAT('1',Heating_Type)),2) 
					  , allList.href, allList.Heating_Type
from stage.AllListings as allList


--CREATE TYPE myTableType AS TABLE(
--    hashKey nvarchar (128) NULL
--)
--declare @t myTableType
--INSERT @t exec DynamicRowHash 'HUB_FLAT'

exec DynamicRowHash 'HUB_FLAT', 'FlatHK', 0
exec DynamicRowHash 'HUB_HEATING', 'HeatingHK', 0
exec DynamicRowHash '##STAGE_SOURCE', 'HK', 1


INSERT INTO dbo.LINK_FLATSHEATING(
   HK
   ,RecordSourceId
   ,LoadDate
   ,FlatHK
   ,HeatingHK
   ,Href
   ,Heating_Type
)
SELECT DISTINCT 
   STG.HK
   ,STG.RecordSourceId
   ,STG.LoadDate
   ,STG.FlatHK
   ,STG.HeatingHK
   ,STG.Href
   ,STG.Heating_Type

FROM 
   ##STAGE_SOURCE AS STG 
   LEFT OUTER JOIN 
   LINK_FLATSHEATING on 
      LINK_FLATSHEATING.HK = STG.HK 
WHERE 
   LINK_FLATSHEATING.RecordSourceId is null;

Drop table if exists ##STAGE_SOURCE
   	 
EXEC InsertLinkFlatsHeatingProcedure
