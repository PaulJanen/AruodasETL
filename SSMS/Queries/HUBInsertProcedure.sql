
Declare @columnNames  nvarchar(255)
Declare @tableName  nvarchar(255) = 'HUB_FLAT'

Set @columnNames = (select string_agg(sc.name, ',') from sys.objects so
inner join sys.columns sc
	on sc.object_id = so.object_id
where so.name = @tableName)

select @columnNames

SET @columnNames = 'href'
(select * from sys.objects so
inner join sys.columns sc
	on sc.object_id = so.object_id
where so.name = @tableName)

select * from sys.types

SELECT COL_LENGTH('HUB_FLAT','href')

select * from INFORMATION_SCHEMA.COLUMNS
Select count(*) from stage.AllListings

GO



--viska perkelt i funkcija:
--Paselectink hask key atsiusto columnu reiksmes.
--Convertuok i string 
--Atlik convertavima

DROP Function IF EXISTS CreateHK
GO

--@tablename = tempTable
CREATE FUNCTION CreateHKValues(@tablename NVARCHAR(50), @columnsForHash NVARCHAR(511)) RETURNS nvarchar(MAX)
AS
BEGIN
	DECLARE @valueToBeHashed nvarchar(MAX);
	Declare @sql nvarchar(255);
	Set @sql = 'DROP table IF EXISTS #STAGE_SOURCE'



GO

DROP PROC IF EXISTS InsertHubFlats
GO
CREATE PROCEDURE InsertHubFlats @stageTable nvarchar(127), @tablename NVARCHAR(50), @columnsForHash NVARCHAR(511), @hashColumnName NVARCHAR(511)
AS
DECLARE @dts nvarchar(100)
SET @dts = getdate()

DECLARE @sourceID nvarchar(100)
SET @sourceID = newID()

Declare @sql nvarchar(511)
Set @sql = 'DROP table IF EXISTS ##STAGE_SOURCE'
exec(@sql)
SET @sql = 'SELECT * INTO ##STAGE_SOURCE FROM ' + @tablename + ' where 1=0'
exec(@sql) 

SET @sql = 'INSERT INTO ##STAGE_SOURCE (' + @hashColumnName +', [HubLoadDate], [HubRecordSourceID],' + @columnsForHash + ' )
Select CONVERT(VARCHAR(128),HASHBYTES(''MD5'', CONCAT(1,' + @columnsForHash + ')),2)
	, ''' + @dts + '''
	, ''' + @sourceID      + '''
	, ' + @columnsForHash + '
	from ' + @stageTable

exec(@sql)

Declare @stageColumnsForHash nvarchar(511)
SET @stageColumnsForHash =  (Select string_agg(concat('STG.',value),',') FROM STRING_SPLIT(@columnsForHash, ','))


SET @sql = 'INSERT INTO [dbo].' + @tablename + ' ( '
                + @hashColumnName + ', '
                + '[HubLoadDate], '
                + '[HubRecordSourceID],'
				+ @columnsForHash
            + ' ) '
            + 'SELECT DISTINCT '
            + 'STG.' + @hashColumnName + ', '
            + 'STG.' + '[HubLoadDate], '
            + 'STG.' + '[HubRecordSourceID], '
            +  @stageColumnsForHash
            + ' FROM ##STAGE_SOURCE AS STG '
            + 'LEFT OUTER JOIN '
            + '[dbo].' + @tablename + ' ON '
            + @tablename + '.' + @hashColumnName + ' = STG.' + @hashColumnName
            + ' WHERE ' + @tablename + '.[HubRecordSourceID] IS NULL; '
EXECUTE (@sql)
Set @sql = 'DROP table IF EXISTS ##STAGE_SOURCE'
exec(@sql)

exec InsertHubFlats 'stage.AllListings', 'HUB_FLAT', 'href', 'HubFlatHK'
exec InsertHubFlats 'stage.AllListings', 'HUB_HEATING', 'Heating_Type', 'HubHeatingHK'

Truncate table hub_flat
ALTER TABLE stage.AllListings
ADD href2 varchar(600) NULL;
UPDATE stage.AllListings SET href2 = href;


DECLARE @DataSource TABLE
(
    [ID] TINYINT IDENTITY(1,1)
   ,[Value] NVARCHAR(128)
)   

DECLARE @Value NVARCHAR(MAX) = 'BAT | CAT | RAT | MAT'
INSERT INTO @DataSource ([Value])
SELECT value
FROM STRING_SPLIT(@Value, '|')  

Select * from @DataSource

DECLARE @Value NVARCHAR(MAX) = 'BAT | CAT | RAT | MAT'
select string_agg(concat('STG.',value),',') FROM STRING_SPLIT(@Value, '|')