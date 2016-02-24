/*****************************************************************
Author: 	Andrew Goss
Website: 	andrewrgoss.com
Purpose:	This script will get data file size, used space and free space for every database.
Base code:	http://sqldbpool.com/2014/02/19/script-to-get-data-file-size-used-space-and-free-space/
Initial: 	12/22/2015

*****************************************************************/

DECLARE @strSQL as NVARCHAR(MAX)
DECLARE @databasename as varchar(500)

CREATE TABLE #FIND_WORKING (DBName varchar(500), name varchar(100), [filename] varchar(150), [FileSize(MB)] float, [UsedSpace(MB)] float, [AvailableFreeSpace(MB)] float)

DECLARE Curse CURSOR local fast_forward
FOR
SELECT 
		  name
FROM
		  master.dbo.sysdatabases 
WHERE
		   dbid > 4
OPEN Curse

FETCH next FROM Curse INTO @databasename

WHILE @@fetch_status = 0
BEGIN

SET @strSQL= 'use '  + @databasename + '
insert into #FIND_WORKING
select
        DBName,
        name,
        [filename],
        size as ''SizeMB'',
        usedspace as ''UsedSpaceMB'',
        (size - usedspace) as ''AvailableFreeSpaceMB''
from       
(   
SELECT
db_name(s.database_id) as DBName,
s.name AS [Name],
s.physical_name AS [FileName],
(s.size * CONVERT(float,8))/1024 AS [Size],
(CAST(CASE s.type WHEN 2 THEN 0 ELSE CAST(FILEPROPERTY(s.name, ''SpaceUsed'') AS float)* CONVERT(float,8) END AS float))/1024 AS [UsedSpace],
s.file_id AS [ID]
FROM
sys.filegroups AS g
INNER JOIN sys.master_files AS s ON ((s.type = 2 or s.type = 1 or s.type = 0) and s.database_id = db_id() and (s.drop_lsn IS NULL))) DBFileSizeInfo
'
EXEC dbo.sp_executesql @strSQL

FETCH next FROM Curse INTO @databasename
END
CLOSE Curse
DEALLOCATE Curse

SELECT 
*
FROM #FIND_WORKING

--DROP TABLE #FIND_WORKING