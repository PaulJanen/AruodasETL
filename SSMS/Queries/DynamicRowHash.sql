DROP PROCEDURE IF EXISTS DynamicRowHash 
GO
CREATE PROCEDURE DynamicRowHash @tableName nvarchar(50), @columnBeingHashed  nvarchar(50), @hashingColumnsFromTemp as bit
AS
--DECLARE @hash nvarchar(128)
DECLARE @sql nvarchar(1023)
DECLARE @columnNames nvarchar(1023)

if @hashingColumnsFromTemp = 0
	SET @columnNames = (SELECT string_agg('CAST (UPPER('+column_name+') as nvarchar(max))',', ')
	from information_schema.columns 
	where table_name = @tableName
	AND column_name NOT IN ('HK', 'LoadDate', 'RecordSourceId', 'LoadEndDate', 'ValidTo', 'Validity'))
ELSE
BEGIN
	DECLARE @objId as int = (SELECT top(1) object_id FROM tempdb.sys.objects where name = '##STAGE_SOURCE')
	SET @columnNames = (SELECT string_agg('CAST (UPPER('+[name]+') as nvarchar(max))',', ')
	from tempdb.sys.all_columns
	where object_id = @objId
	AND [name] NOT IN ('HK', 'LoadDate', 'RecordSourceId', 'LoadEndDate', 'ValidTo', 'Validity'))
END

SET @sql = 'UPDATE ##STAGE_SOURCE SET '+@columnBeingHashed+' = CONVERT(VARCHAR(128),HASHBYTES(''MD5'', CONCAT(''1'','+@columnNames+')),2)'
exec (@sql)

