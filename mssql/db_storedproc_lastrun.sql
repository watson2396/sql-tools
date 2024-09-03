Select
	database_name = Db_Name( ps.database_id )
  , o.name
  , ps.last_execution_time
  , ps.*
From sys.dm_exec_procedure_stats ps
Left Join sys.objects			 o
	On ps.object_id = o.object_id
Order By ps.last_execution_time Desc;



