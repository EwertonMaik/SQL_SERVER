-- Comandos

--Procedure para configuração de Parãmetros da Instância
--Possui diversos parâmetos que podem ser validados em
--https://docs.microsoft.com/pt-br/sql/database-engine/configure-windows/server-configuration-options-sql-server?view=sql-server-2017
--Ao definir show advanced options como 1, você pode listar as opções avançadas usando sp_configure. O padrão é 0.
USE master;  
GO  
EXEC sp_configure 'show advanced option', '1'; 
RECONFIGURE; -- Aplica as modificações de configuração

-- Configura a Instância para seu grau maximo de Paralelismo
EXECUTE SP_CONFIGURE 'Max Degree of Parallelism', 8;
GO
RECONFIGURE;
GO

-- Configura o Banco de Dados para seu Grau Máximo de Paralelismo
ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 1

-- Query para monitorar requisições/sessões em execução
select r.session_id, r.status, r.dop, t.text, r.parallel_worker_count from sys.dm_exec_requests as r
cross apply sys.dm_exec_sql_text(r.sql_handle) as t
where session_id in (58)
GO

select session_id, * from sys.dm_os_tasks
where session_id in (58) order by worker_address;

--Posso verificar os parâmetros na seguinte VIEW
SELECT a.name,a.value, a.value_in_use FROM sys.configurations a

-- Via cmd Windows
-- Executavel direto para abrir o SQL Server Configuration Manager
SqlServerManager15.msc - SQL Server 2019
SQLServerManager14.msc - SQL Server 2017
SQLServerManager13.msc - SQL Server 2016

-- Comando T-SQL do SQL Server
-- Traz as informações de LOG de todas as Bases da Instãncia - Tamanho do Log e Espaço usado!
dbcc sqlperf(logspace);

-- Traz as informações do VLF's Virtual Log Files
dbcc loginfo;

--Store Procedure do SQL Server, tráz informações de tamanho de objetos do Banco de Dados
-- Quando executado sozinho, tráz as informações de tamanho do banco atual selecionado
sp_spaceused 'Produto'; Traz informações do Objeto
sp_helptext 'sp_spaceused'; --verificar o spript de objetos do banco
sp_databases -- Lista os Bancos e seu tamanho
sp_helpdb 'NOME_BANCO'; -- Verificar informações do Banco

--INFORMAÇÕES DO OBJETOS
select * from sys.objects --INFORMAÇÕES DO ALOCACOES DE ESPACO
select * from sys.allocation_units --INFORMAÇÕES DO ALOCACOES DE ESPACO
select * from sys.partitions --INFORMAÇÕES DO PARTICOES--REGISTROS POR TABELAS

-- Query usando as visualizações de  catalago anteriores para visualisar todas tabelas e suas informações de tamanho e armazenamento
SELECT O.name AS NOME_TABELA,
       p.Rows As Linhas,
    SUM(a.Total_Pages * 8) As Reservado,
    SUM(CASE WHEN p.Index_ID > 1 THEN 0 ELSE a.Data_Pages * 8 END) As Dados,
        SUM(a.Used_Pages * 8) -
        SUM(CASE WHEN p.Index_ID > 1 THEN 0 ELSE a.Data_Pages * 8 END) As Indice,
    SUM((a.Total_Pages - a.Used_Pages) * 8) As NaoUtilizado
FROM
    sys.partitions As p
    INNER JOIN sys.allocation_units As a 
	ON p.hobt_id = a.container_id
	INNER JOIN sys.objects O
	ON O.object_id=P.object_id
	WHERE O.type='U' -- TABELAS DO USUARIOS
GROUP BY O.name,Rows
ORDER BY dados desc;

--Visualização de Usuários dos banco de Dados e Logins do Servidor
select * from sys.sysusers;
select * from sys.syslogins;

--Visualização que lista todas VIEW
select * from sys.all_views;

--Visualização de todos banco de dados da Instância
select * from sys.sysdatabases;

--Lista os arquivos de Dados do Banco
-- Posso verificar os Arquidos de Dados do Banco (MDF e NDF - Master/Second Data File) e arquivos de LOG (LDF - Log Data File)
select * from sys.database_files;
select file_id, type_desc, name, physical_name, state, size, max_size, growth
from sys.database_files;

-- Verificando Todos os arquivos dos Database pela visualização sysaltfiles;
-- Realizado calculo com a coluna size
select DB_NAME(dbid) bd,
       cast(cast(size*8 as decimal(10,2))/1024. as decimal(10,3))tamanho,
	   STR (size * 8, 15, 0) + ' KB' tamanho_str,
	   name, filename
	   from sysaltfiles;

--Visualização que lista todos os processos executados independente de seu status
--Por ela consigo pegar o hostname, banco, spid, program_name, usuário e diversas outras informações do processo
select sql_handle, * from sys.sysprocesses where status = 'runnable';

-- Com a query anterior, peguei o código da coluna sql_handle do processo executado
-- E passei no parâmetro da dm - sys.dm_exec_sql_text que é uma função
-- essa dm me retorna a query executada
select * from sys.dm_exec_sql_text(0x01000500F16794215041801C3302000000000000);

-- Variaveis SQL Server
select @@TRANCOUNT -- Informa se tem uma transação em aberto
select @@SERVERNAME; -- Informa Hostname Servidor + Nome Instância
select @@SERVICENAME; -- Informa Nome da Instância
select @@VERSION; -- Informa Dados da Versão e Compilação do Instalação
SELECT @@LANGUAGE; -- Informação da Linguagem da Intalação do Banco
SELECT @@TRANCOUNT; -- Informa a quantidade de Transações em aberto
SELECT @@SERVERNAME; --Retorna o nome do servidor local que está executando o SQL Server.
SELECT @@SPID; --Retorna a ID de sessão do processo de usuário atual.

-- É uma expressão que contém as informações de propriedade que serão retornadas para o servidor.
SELECT SERVERPROPERTY('productversion')Versao_Produto, 
       SERVERPROPERTY ('productlevel')Nivel_versao,
       SERVERPROPERTY ('edition') Edicao,
	     SERVERPROPERTY('InstanceDefaultDataPath')LOCALDADOS,
	     SERVERPROPERTY('InstanceDefaultLogPath')LOCALOGS,
	     SERVERPROPERTY('InstanceName')INSTANCIA,
	     SERVERPROPERTY('IsHadrEnabled')HADR,
	     SERVERPROPERTY('LCID')LOCALIZACAO,
	     SERVERPROPERTY('ServerName')SERVERNAME
	     
SELECT SERVERPROPERTY ( 'LicenseType'), SERVERPROPERTY ( 'NumLicenses'),
SERVERPROPERTY ( 'productversion'), SERVERPROPERTY ( 'ProductLevel'), SERVERPROPERTY ( 'Edition');

arquivo - sqlslic.cpl na pasta do servidor SQL (C: \ Arquivos de Programas \ Microsoft SQL Server \ 80 \ Tools \ Binn)

-- Procedure que traz informação de permissão do usuário
EXEC dbo.sp_helprotect @username = 'dbo';

--Alternar entre usuários para executar operações
select SYSTEM_USER; -- vejo em qual usuário estou conectado
EXECUTE AS user='user_01'; -- Comando Execute para mudar para o user_01
select SYSTEM_USER; -- Conferindo o atual usuário que esta conectado
REVERT; -- Reverte para o usuário anterior conectado

--DETTACH (DESANEXAR) e ATACH (ANEXAR) BANCO DE DADOS
-- Função pode ser usada para tirar um banco de um ambiente e levar para outro ambiente
--Desanexando Banco
USE [master]
GO
EXEC master.dbo.sp_detach_db @dbname = N'TestDB'
GO

-- ATACH (ANEXAR) -- Anexando Banco
USE [master]
GO
CREATE DATABASE [TestDB] ON 
( FILENAME = N'C:\SQLSERVER2019\Microsoft SQL Server\MSSQL15.MSSQLSERVER_01\MSSQL\DATA\BD\TestDB.mdf' ),
( FILENAME = N'C:\SQLSERVER2019\Microsoft SQL Server\MSSQL15.MSSQLSERVER_01\MSSQL\DATA\BD\TestDB_log.ldf' ),
( FILENAME = N'C:\SQLSERVER2019\Microsoft SQL Server\MSSQL15.MSSQLSERVER_01\MSSQL\DATA\BD\Index.ndf' )
 FOR ATTACH
GO

--Definindo o AUTO_SHRINK do Banco de Dados OFF ou ON
ALTER DATABASE TestDB SET AUTO_SHRINK OFF;
ALTER DATABASE TestDB SET AUTO_SHRINK ON;

--Realizando Shrink do Banco
DBCC SHRINKDATABASE (TestDB, 10);

--Truncando um banco de dados
--O exemplo a seguir reduz os arquivos de dados no banco 
--de dados de exemplo TestDB até a última extensão alocada.
DBCC SHRINKDATABASE (TestDB, TRUNCATEONLY);

--Reduzindo arquivo de dados
use TestDB
DBCC SHRINKFILE (TestDB, 10); --Reduzindo o Arquivos de Dados pelo seu nome Lógico
DBCC SHRINKFILE (TestDB_Log, 5); --Reduzindo o Arquivos de Log pelo seu nome Lógico

--HABILITANDO ESTATISCAS DE INFORMACAO
--Faz o SQL Server exibir informações referentes à quantidade de atividade em disco gerada pelas instruções Transact-SQL.
SET STATISTICS io ON
--Exibe o número de milissegundos necessários para analisar, compilar e executar cada instrução.
SET STATISTICS time ON
GO
