DROP PROC IF EXISTS InsertHubFlats
GO
CREATE PROCEDURE InsertHubFlats @stageTable nvarchar(127), @tablename NVARCHAR(50), @columnsForHash NVARCHAR(511)
AS
DECLARE @dts nvarchar(100)
SET @dts = getdate()

DECLARE @sourceID nvarchar(100)
SET @sourceID = '800A44D4-2350-4CA9-B1AA-1D4EBA7C16DA'

Declare @sql nvarchar(511)
Set @sql = 'DROP table IF EXISTS ##STAGE_SOURCE'
exec(@sql)
SET @sql = 'SELECT * INTO ##STAGE_SOURCE FROM ' + @tablename + ' where 1=0'
exec(@sql)

DECLARE @mSQL NVARCHAR(MAX) = N'';
SELECT @mSQL += N'
ALTER TABLE ' + OBJECT_NAME(PARENT_OBJECT_ID) + ' DROP CONSTRAINT ' + OBJECT_NAME(OBJECT_ID) + ';' 
FROM SYS.OBJECTS
WHERE TYPE_DESC LIKE '%CONSTRAINT' AND OBJECT_NAME(PARENT_OBJECT_ID) = '##STAGE_SOURCE';
EXECUTE(@mSQL)

SET @sql = 'INSERT INTO ##STAGE_SOURCE ([HK],[LoadDate], [RecordSourceID],' + @columnsForHash + ' )
Select 1,''' + @dts + '''
	, ''' + @sourceID      + '''
	, '   + @columnsForHash + '
	from ' + @stageTable
exec(@sql)

SET @sql = 'exec DynamicRowHash '+ @tablename +', [HK], 0'
exec(@sql)

Declare @stageColumnsForHash nvarchar(511)
SET @stageColumnsForHash =  (Select string_agg(concat('STG.',value),',') FROM STRING_SPLIT(@columnsForHash, ','))


SET @sql = 'INSERT INTO [dbo].' + @tablename + ' ( '
                + '[HK], '
                + '[LoadDate], '
                + '[RecordSourceID],'
				+ @columnsForHash
            + ' ) '
            + 'SELECT DISTINCT '
            + 'STG.' + '[HK], '
            + 'STG.' + '[LoadDate], '
            + 'STG.' + '[RecordSourceID], '
            +  @stageColumnsForHash
            + ' FROM ##STAGE_SOURCE AS STG '
            + 'LEFT OUTER JOIN '
            + '[dbo].' + @tablename + ' ON '
            + @tablename + '.[HK] = STG.[HK]'
            + ' WHERE ' + @tablename + '.[RecordSourceID] IS NULL; '
EXECUTE (@sql)
Set @sql = 'DROP table IF EXISTS ##STAGE_SOURCE'
exec(@sql)


