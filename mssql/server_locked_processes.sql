USE master;
GO

-- Kill BlockingSessionID
/*
KILL 86

KILL 114 WITH STATUSONLY
*/

-- Check all running processes
EXEC dbo.sp_WhoIsActive

-- Check blocked sessions
--/*
SELECT
    er.blocking_session_id                                      AS BlockingSessionID,
    database_name = DB_NAME(er.database_id),
    BlockingQuery = (
        SELECT text
        FROM sys.sysprocesses
        CROSS APPLY sys.dm_exec_sql_text(sql_handle)
        WHERE spid = blocking_session_id
    ),
    VictimSessionID = er.session_id,
    VictimQuery = st.text,
    WaitDurationSecond = er.wait_time / 1000,
    WaitInMinutes = er.wait_time / 1000.0 / 60,
    WaitType = er.wait_type
    --, BlockingQueryCompletePercent = er.percent_complete
FROM sys.dm_exec_requests er
CROSS APPLY sys.dm_exec_sql_text(sql_handle) st
WHERE blocking_session_id > 0
ORDER BY
    BlockingSessionID,
    VictimSessionID;
--*/

-- Check Background processes
/*
SELECT
    r.status,
    session_id,
    start_time,
    
    database_name = DB_NAME(database_id),
    command,
    text,
    blocking_session_id                 AS BlockingSessionID,
    total_elapsed_time / 1000.0 / 60    AS total_minutes,
    -- sql_handle,
    --request_id,
    --statement_start_offset,
    --statement_end_offset,
    --plan_handle,
    --database_id,
    --connection_id,
    wait_type,
    --wait_time,
    last_wait_type,
    wait_resource,
    open_transaction_count,
    open_resultset_count,
    transaction_id,
    --context_info,
    --percent_complete,
    --estimated_completion_time,
    cpu_time,
    total_elapsed_time,
    --scheduler_id,
    --task_address,
    reads,
    writes,
    logical_reads
    --,text_size
FROM sys.dm_exec_requests r
Join sys.sysusers u on r.user_id = u.uid
CROSS APPLY sys.dm_exec_sql_text([sql_handle])
ORDER BY
    total_minutes DESC,
    start_time,
    CAST(session_id AS INT);
--*/

