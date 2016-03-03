/*****************************************************************
Author: 	Andrew Goss
Website: 	andrewrgoss.com
Purpose:	This proc will find any string in all SQL code on the server. It will not look in the data itself, only in code.
Initial: 	11/14/2015

*****************************************************************/

DECLARE @searchstring as VARCHAR(500)
DECLARE @strSQL as NVARCHAR(MAX)
DECLARE @databasename as varchar(500)

SET @searchstring = 'Refresh' -- change string search value here

SELECT @searchstring as Current_Search_String

CREATE TABLE #FIND_WORKING (DatabaseName varchar(500),ObjectName varchar(100), ObjectType varchar(50))

DECLARE Curse CURSOR local fast_forward
FOR
SELECT 
		  name
FROM
		  master.dbo.sysdatabases 
WHERE
		   dbid > 4 -- exclude system default databases
OPEN Curse

FETCH next FROM Curse INTO @databasename

WHILE @@fetch_status = 0
BEGIN

SET @strSQL= 'use '  + @databasename + '

insert into #FIND_WORKING
select distinct
	''' + @databasename + ''',	  
	cast(o.[name] as varchar(100)) as objectname,
	o.type	  --	left(c.text,50) as place
	
from 
	syscomments c
	inner join
	sysobjects o ON
	c.[id] = o.[id]
	  
where 
	c.[text] like ''%' +@searchstring+ '%'' 
order by cast(o.[name] as varchar(100))
'
EXEC dbo.sp_executesql @strSQL

FETCH next FROM Curse INTO @databasename
END
CLOSE Curse
DEALLOCATE Curse

SELECT 
	DatabaseName,
	ObjectName,
	ObjectType
FROM #FIND_WORKING
ORDER BY DatabaseName,ObjectName

--DROP TABLE #FIND_WORKING