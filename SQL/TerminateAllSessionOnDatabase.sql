USE [master]

go

DECLARE @kill VARCHAR(8000) = '';

SELECT @kill = @kill + 'kill '
               + CONVERT(VARCHAR(5), session_id) + ';'
FROM   sys.dm_exec_sessions
WHERE  database_id = Db_id('MyDB')

EXEC(@kill); 