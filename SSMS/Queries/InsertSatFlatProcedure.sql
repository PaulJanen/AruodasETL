CREATE FUNCTION GetColumnsHK(@tableName nvarchar(50)) RETURNS varchar(128)
AS
BEGIN
DECLARE @YTDSALES AS MONEY
--SELECT @YTDSALES = SUM(SalesYTD) FROM Sales.SalesTerritory
--WHERE [GROUP] = @GROUP
RETURN @YTDSALES
END

Go

DROP PROC If exists InsertSatFlatProcedure
GO
CREATE PROCEDURE InsertSatFlatProcedure
AS

DECLARE @sourceID nvarchar(100)
SET @sourceID = 'B9A2D1F0-A136-4DC7-884F-948065342014'--newID()

CREATE TABLE #STAGE_SOURCE
(
	HubFlatHK nvarchar(128),
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
	ColumnHash nvarchar(128)
);



INSERT INTO #STAGE_SOURCE (HubFlatHK,RecordSourceId,LoadDate,LoadEndDate,Price,PricePerM2,Area,[Floor],NumberOfFloors,RoomCount,BuiltYear, ColumnHash)
select HF.HubFlatHK, @sourceID, STG.LOAD_DTS, null, STG.Price, STG.PricePerM2, STG.Area, 
		STG.[floor], STG.[Number of floors], STG.[Room count], STG.[Built year] , CONVERT(VARCHAR(128),HASHBYTES('MD5', CONCAT(
		HF.HubFlatHK, @sourceID, STG.LOAD_DTS, null, STG.Price, STG.PricePerM2, STG.Area, STG.[floor], STG.[Number of floors], STG.[Room count], STG.[Built year])),2)
from stage.AllListings as STG 
inner join HUB_FLAT as HF on STG.href = HF.href



INSERT INTO dbo.SAT_FLAT
SELECT DISTINCT 
   STG.*
FROM 
   #STAGE_SOURCE AS STG 
   LEFT OUTER JOIN 
   SAT_FLAT on 
      SAT_FLAT.ColumnHash = STG.ColumnHash 
WHERE 
   SAT_FLAT.HubFlatHK is null;
   
EXEC InsertSatFlatProcedure

