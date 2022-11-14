DROP PROC If exists UpdateSatFlatLoadEndDateProcedure
GO
CREATE PROCEDURE UpdateSatFlatLoadEndDateProcedure
AS

CREATE TABLE #STAGE_SOURCE
(
	HK nvarchar(128),
	LoadDate datetime NOT NULL,
	LoadEndDate datetime NULL,
	ColumnHash nvarchar(128)
);

INSERT INTO #STAGE_SOURCE (HK, ColumnHash, LoadDate, LoadEndDate)
Select HK, ColumnHash, LoadDate, LoadEndDate = LEAD (LoadDate, 1, null) OVER (PARTITION BY HK ORDER BY LoadDate Asc) 
from SAT_FLAT 
where LoadEndDate is NULL
order by LoadDate

Update flat
SET flat.LoadEndDate = STG.LoadEndDate
from dbo.SAT_FLAT flat
inner join 
#STAGE_SOURCE STG
on flat.ColumnHash = STG.ColumnHash and flat.LoadEndDate is NULL and STG.LoadEndDate is NOT null

exec UpdateSatFlatLoadEndDateProcedure
