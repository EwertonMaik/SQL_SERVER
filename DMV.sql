-- DMV - DYNAMIC MANAGEMENT VIEWS
-- Dividen-se em vários grupos de visualizações

ALWAYSON AVAILABILITY GROUP            SYS.DM_HADR_*
CHANGE DATA CAPTURE RELATED            SYS.DM_CDC_*
CHANGE TRACKING RELATED	               SYS.DM_TRAN_*
COMMON LANGUAGE RUNTIME RELATED        SYS.DM_CLR_*
DATABASE MIRRORING RELATED             SYS.DM_DB_MIRRORING_*
DATABASE RELATED DYNAMIC               SYS.DM_DB_*
EXECUTION RELATED DYNAMIC              SYS.DM_EXEC_*
EXTENDED EVENTS                        SYS.DM_XE_*
FILESTREAM AND FILETABLE(TRANSACT-SQL) SYS.DM_FILESTREAM_*
FULL-TEXT SEARCH AND SEMANTIC SEARCH   SYS.DM_FTS_*
I/O RELATED                            SYS.DM_IO_*
INDEX RELATED                          SYS.DM_DB_INDEX_*
OBJECT RELATED                         SYS.DM_SQL_*
QUERY NOTIFICATIONS RELATED            SYS.DM_QN_*
REPLICATION RELATED                    SYS.DM_REPL_*
RESOURCE GOVERNOR                      SYS.DM_RESOURCE_GOVERNOR_*
SECURITY RELATED                       SYS.DM_AUDIT_*/SYS.DM_CRYPTOGRAPHIC_*
SERVICE BROKER RELATED                 SYS.DM_BROKER_*
SQL SERVER OPERATING SYSTEM RELATED    SYS.DM_OS_*
TRANSACTION RELATED                    SYS.DM_TRAN_*


-- Querys a seguir usa a view ALL_OBJECTS para listar, contar e agrupar quantas DMV's seu ambiente possui
-- Listando todas DMV's
SELECT a.name, a.type_desc
FROM SYS.all_objects a
WHERE NAME LIKE ('dm%')
order by a.name;

--Lista o total de DMV's pelo tipo (VIEW e FUNCTION)
SELECT a.type_desc, COUNT(*) as QTD
FROM SYS.all_objects a
WHERE NAME LIKE ('dm%')
group by a.type_desc;

--Lista o total de DMV's por categoria
SELECT ISNULL(SUBSTRING(a.name,1,CHARINDEX('_',a.name,4)-1),'Total') MOME, COUNT(*) QTD
FROM SYS.all_objects a
WHERE NAME LIKE ('dm%')
group by SUBSTRING(a.name,1,CHARINDEX('_',a.name,4)-1) with rollup
order by 1 asc;

--############################################################################################
--Algumas querys utilizando DMV's de Banco de Dados - LOG

--DMV - Função, tenho que passar o id do Banco que desejo, traz diversas informações de LOG do banco, como modo recuperação, status, size, lsn
select 
	 db_NAME(database_id) dbname,
	 recovery_model,
	 current_vlf_size_mb,
	 total_vlf_count,
	 active_vlf_count,
	 active_log_size_mb,
	 log_truncation_holdup_reason,
	 log_since_last_checkpoint_mb
  from 
	sys.dm_db_log_Stats(5);
  
  SELECT -- A mesma query anterior, porém com um JOIN CROSS APPLY sys.databases / sys.dm_db_log_Stats(A.database_id). Lista para todos os bancos do ambiente agora
	 A.name,
	 B.recovery_model,
	 B.current_vlf_size_mb,
	 B.total_vlf_count,
	 B.active_vlf_count,
	 B.active_log_size_mb,
	 B.log_truncation_holdup_reason,
	 B.log_since_last_checkpoint_mb
  from 
  sys.databases AS A
  CROSS APPLY sys.dm_db_log_Stats(A.database_id) B
  where A.database_id=B.database_id;
  
 -- Query usando a DMV - Função sys.dm_db_log_info(), contên muitas informações relacionadas aos VLF - Virtual Log Files dos arquivos de LOG do Banco.
 select 
		 db_NAME(database_id) dbname,
		 file_id,
		 vlf_begin_offset,
		 vlf_size_mb,
		 vlf_sequence_number,
		 vlf_active,
		 vlf_status
	 from 
		sys.dm_db_log_info(5) b;
    
SELECT -- Mesma Query anterior com CROSS APPLY 
		 db_NAME(A.database_id) dbname,
		 file_id,
		 vlf_begin_offset,
		 vlf_size_mb,
		 vlf_sequence_number,
		 vlf_active,
		 vlf_status
	 from
		sys.databases AS A
		CROSS APPLY sys.dm_db_log_info(A.database_id) B
		where A.database_id=B.database_id;
    
--Query mais elaborada, usando as DMV's sys.databases / sys.dm_os_performance_counters / sys.dm_db_log_info()
-- Traz um maior detalhamento sobre Tamanho Total do LOG de cada Banco, o tamanho usado e livre, Nº de VLF livre e usado.
WITH DATA_VLF AS(
	SELECT 
		DB_ID(a.[name]) AS DatabaseID,
		a.[name] AS dbName, 
		CONVERT(DECIMAL(18,2), c.cntr_value/1024.0) AS [Log Size (MB)],
		CONVERT(DECIMAL(18,2), b.cntr_value/1024.0) AS [Log Size Used (MB)]
	FROM sys.databases AS a WITH (NOLOCK)
	INNER JOIN sys.dm_os_performance_counters AS b  WITH (NOLOCK) ON a.name = b.instance_name
	INNER JOIN sys.dm_os_performance_counters AS c  WITH (NOLOCK) ON a.name = c.instance_name
	WHERE b.counter_name LIKE N'Log File(s) Used Size (KB)%' 
	AND   c.counter_name LIKE N'Log File(s) Size (KB)%'
	AND   c.cntr_value > 0
)
SELECT	[dbName],
		[Log Size (MB)], 
		[Log Size Used (MB)], 
		[Log Size (MB)]-[Log Size Used (MB)] [Log Free (MB)], 
		cast([Log Size Used (MB)]/[Log Size (MB)]*100 as decimal(10,2)) [Log Space Used %],
		COUNT(b.database_id) AS [Number of VLFs] ,
		sum(case when b.vlf_status = 0 then 1 else 0 end) as Free,
		sum(case when b.vlf_status != 0 then 1 else 0 end) as InUse		
FROM DATA_VLF AS a  
CROSS APPLY sys.dm_db_log_info(a.DatabaseID) b
GROUP BY dbName, [Log Size (MB)],[Log Size Used (MB)];

--######################################################################################################
-- DMV's Conexões, Sessões e Requisições

-- Conexões ativas
SELECT datediff(MINUTE,a.connect_time,GETDATE()) minutos_conectado, a.* 
FROM sys.dm_exec_connections a;
 
-- Sessões ativas
SELECT datediff(MINUTE,a.login_time,GETDATE()) minutos_conectado,a.* 
FROM sys.dm_exec_sessions a --where a.status = 'running';
 
-- Requisições solicitadas / DMV Possui o campo com a informação sql_handle, que pode ser consultado para coletar a query executada em sys.dm_exec_sql_text
--Exemplo no item (sql_handle).
SELECT
datediff(MINUTE, a.start_time, GETDATE() )minutos_conectado, a.sql_handle, a.*
FROM sys.dm_exec_requests a --where a.status = 'running';

--Visualização que lista todos os processos executados independente de seu status
--Por ela consigo pegar o hostname, banco, spid, program_name, usuário e diversas outras informações do processo
select sql_handle, * from sys.sysprocesses where status = 'runnable';

-- (sql_handle) Com a query anterior, peguei o código da coluna sql_handle do processo executado
-- E passei no parâmetro da dm - sys.dm_exec_sql_text que é uma função
-- essa dm me retorna a query executada
select * from sys.dm_exec_sql_text(0x01000500F16794215041801C3302000000000000);

--#######################################################################################
-- Tabelas e Indices que mais recebe consultas (user_scans)
SELECT B.NAME AS TABLE_NAME,C.NAME AS INDEX_NAME,*
FROM SYS.DM_DB_INDEX_USAGE_STATS A
INNER JOIN SYSOBJECTS B
ON B.ID = A.OBJECT_ID
INNER JOIN SYS.INDEXES C
ON A.OBJECT_ID = C.OBJECT_ID
ORDER BY user_scans DESC;

-- Query para Identificar as consultas mais Pesadas por tempo de execução
SELECT TOP 10
    DB_NAME(C.[dbid]) as Banco_dados,
    B.text,
    (SELECT CAST(SUBSTRING(B.[text], (A.statement_start_offset/2)+1,   
        (((CASE A.statement_end_offset  
            WHEN -1 THEN DATALENGTH(B.[text]) 
            ELSE A.statement_end_offset  
        END) - A.statement_start_offset)/2) + 1) AS NVARCHAR(MAX)) FOR XML PATH(''), TYPE) AS [TSQL],
    C.query_plan,
	--Tempo
    A.last_execution_time,
    A.execution_count,
	--Tempo Decorrido
    A.total_elapsed_time / 1000 AS total_elapsed_time_ms,
    A.last_elapsed_time / 1000 AS last_elapsed_time_ms,
    A.min_elapsed_time / 1000 AS min_elapsed_time_ms,
    A.max_elapsed_time / 1000 AS max_elapsed_time_ms,
    ((A.total_elapsed_time / A.execution_count) / 1000) AS avg_elapsed_time_ms,
	--Tempo Total Trabalhado
    A.total_worker_time / 1000 AS total_worker_time_ms,
    A.last_worker_time / 1000 AS last_worker_time_ms,
    A.min_worker_time / 1000 AS min_worker_time_ms,
    A.max_worker_time / 1000 AS max_worker_time_ms,
    ((A.total_worker_time / a.execution_count) / 1000) AS avg_worker_time_ms,
    --Leitura Fisica
    A.total_physical_reads,
    A.last_physical_reads,
    A.min_physical_reads,
    A.max_physical_reads,
   --Leitura Logica
    A.total_logical_reads,
    A.last_logical_reads,
    A.min_logical_reads,
    A.max_logical_reads,
   --Escrita Logica
    A.total_logical_writes,
    A.last_logical_writes,
    A.min_logical_writes,
    A.max_logical_writes
FROM
    sys.dm_exec_query_stats A
    CROSS APPLY sys.dm_exec_sql_text(A.[sql_handle]) B
    OUTER APPLY sys.dm_exec_query_plan (A.plan_handle) AS C
	WHERE C.[dbid]=DB_ID()
ORDER BY
    A.total_elapsed_time DESC;
    
    --####################################################################################################
--Verificando o caminho e qual o arquivo de Trace
SELECT * FROM sys.traces;

--verificando arquivo TRACE
SELECT  TextData, 
		SPID, 
		LoginName, 
		NTUserName, 
		NTDomainName, 
		HostName, 
		ApplicationName, 
		StartTime, ServerName, 
		DatabaseName, 
		EventClass, 
		ObjectType
FROM fn_trace_gettable('C:\SQLSERVER2019\Microsoft SQL Server\MSSQL15.MSSQLSERVER_01\MSSQL\Log\log_17.trc', default)
where TextData is not null
and LoginName='LAPTOP-5O9S38I5\Ewerton Maik';

-- DMV'S de HA - Alwayson availability Groups
--CLUSTERS
SELECT * FROM SYS.dm_hadr_cluster

--MENBROS DO CLUSTER
SELECT * FROM SYS.dm_hadr_cluster_members

--REDES DE CLUSTER
SELECT * FROM SYS.dm_hadr_cluster_networks

--ESTADO DAS REPLICAS
SELECT * FROM SYS.dm_hadr_availability_replica_states

--NÓS DO CLUSTER
SELECT * FROM SYS.dm_hadr_availability_replica_cluster_nodes

-- QUERY PARA LISTAR AS TABELAS DO BANCO DE DADOS E QUANTAS LINHAS POSSUEM
select
    schema_name(schema_id) as 'owner',
    tabelas.name as 'tabela',
    sum(partitions.rows) as 'linhas'
from sys.tables as tabelas
join sys.partitions as partitions on tabelas.object_id = partitions.object_id and partitions.index_id in (0,1)
group by schema_name(schema_id), tabelas.name
order by 3 desc
