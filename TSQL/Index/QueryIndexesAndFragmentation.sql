SELECT DB_NAME(database_id) as 'Database',
	dbschemas.[name] as 'Schema',
    dbtables.[name] as 'Table',
    dbindexes.[name] as 'Index',
    indexstats.avg_fragmentation_in_percent,
	-- Default Rebuild SQL
	'ALTER INDEX ['+dbindexes.[name]+'] ON ['+dbschemas.[name]+'].['+dbtables.[name]+'] REBUILD PARTITION = ALL WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = ON, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON); RAISERROR(''Indexes on '+dbschemas.[name]+'.'+dbtables.[name]+' rebuilded...'', 0, 42) WITH NOWAIT;' AS DefaultRebuildSQL,
	-- Adaptive Index Defrag SQL
	'EXEC msdb.dbo.usp_AdaptiveIndexDefrag @sortInTempDB=1, @dbscope='''+DB_NAME(database_id)+''', '+'@tblName= '''+dbschemas.[name]+'.'+dbtables.[name]+' @onlineRebuild = 1''; RAISERROR(''Indexes on '+dbschemas.[name]+'.'+dbtables.[name]+' rebuilded...'', 0, 42) WITH NOWAIT;' AS AdaptiveIndexDefragSQL
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS indexstats
INNER JOIN sys.tables dbtables
    ON dbtables.[object_id] = indexstats.[object_id]
INNER JOIN sys.schemas dbschemas
    ON dbtables.[schema_id] = dbschemas.[schema_id]
INNER JOIN sys.indexes AS dbindexes
    ON dbindexes.[object_id] = indexstats.[object_id]
AND indexstats.index_id = dbindexes.index_id
WHERE indexstats.database_id = DB_ID()
  AND dbindexes.[name] IS NOT NULL
  AND indexstats.avg_fragmentation_in_percent > 30
ORDER BY indexstats.avg_fragmentation_in_percent DESC