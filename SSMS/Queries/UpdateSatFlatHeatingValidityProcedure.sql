DROP PROC If exists UpdateSatFlatHeatingValidityProcedure
GO
CREATE PROCEDURE UpdateSatFlatHeatingValidityProcedure
AS
CREATE TABLE #STAGE_SOURCE
(
	HK nvarchar(128) NOT NULL,
	FlatHK nvarchar(128) NOT NULL,
	HeatingHK nvarchar(128) NOT NULL,
	LoadDate datetime NOT NULL,
	ValidTo datetime NULL,
	Validity bit NOT NULL
);

INSERT INTO #STAGE_SOURCE (HK,FlatHK,HeatingHK,LoadDate,ValidTo,Validity)
Select HK, FlatHK, HeatingHK, LoadDate, ValidTo = LEAD (LoadDate, 1, null) OVER (PARTITION BY FlatHK ORDER BY LoadDate Asc)
	,Validity --= Case When ValidTo is NULL Then 1 Else 0 End nested select
from SAT_FLATHEATINGVALIDITY
order by LoadDate

Update #STAGE_SOURCE
SET Validity = Case When ValidTo is NULL Then 1 Else 0 End

Update sat
SET sat.ValidTo = STG.ValidTo, sat.Validity = STG.Validity
from dbo.SAT_FLATHEATINGVALIDITY sat
inner join 
#STAGE_SOURCE STG
on (sat.HK = STG.HK and sat.FlatHK = STG.FlatHK and sat.HeatingHK = STG.HeatingHK and sat.LoadDate = STG.LoadDate)
										and (sat.ValidTo != STG.ValidTo or sat.Validity != STG.Validity)

---------------------------------------
exec UpdateSatFlatHeatingValidityProcedure




Update dbo.SAT_FLAT
SET LoadEndDate = null

select * from HUB_FLAT where href = 'https://en.aruodas.lt/butai-panevezyje-centre-ukmerges-g-parduodamas-3kambariu-butas-miesto-centre-1-3237966/'
select * from SAT_FLAT where HubFlatHK = '85F126EF87457D10DCA5C3BF8DC38A1D'
select * from SAT_FLATHEATINGVALIDITY where FlatHK = '85F126EF87457D10DCA5C3BF8DC38A1D'

INSERT INTO [stage].[AllListings]
           ([index]
           ,[Price]
           ,[PricePerM2]
           ,[Area]
           ,[floor]
           ,[Number of floors]
           ,[Room count]
           ,[Built year]
           ,[Heating_Type]
           ,[Equipment]
           ,[City]
           ,[District]
           ,[href]
           ,[LOAD_DTS])
     VALUES
           (0
           ,91999
           ,1808
           ,50
           ,3
           ,4
           ,3
           ,'1962-01-01'
           ,'Central thermostat'
           ,'Fully equipped'
           ,'Panevėžys'
           ,'Centras'
           ,'https://en.aruodas.lt/butai-panevezyje-centre-ukmerges-g-parduodamas-3kambariu-butas-miesto-centre-1-3237966/'
           ,'2022-11-08 14:50:12.807')
GO
