# ❤️  Banco de Dados SQL SERVER

* 1  - Scripts de Backup e Restore
* 2  - Scripts de Database Console Commands (DBCC)
* 3  - Scripts de Linguagem de Controle de Dados (DCL)
* 4  - Scripts de Linguagem de Modelo de Dados e Linguagem de Definição de Dados (DML DDL)
* 5  - Scripts de Mascaramento de Dado Dinâmico (DDM)
* 6  - Scripts de Dynamic Management Views (DMV)
* 7  - Scripts de Database Email
* 8  - Scripts de Estados do Banco de Dados
* 9  - Scripts de Estatísticas
* 10 - Scripts de Fragmentação de Index
* 11 - Scripts de Jobs
* 12 - Scripts de Linked Server
* 13 - Scripts de Lock Block DeadLock
* 14 - Scripts de Performance
* 15 - Scripts de SQLCMD
* 16 - Scripts de Catalago de Dados
* 17 - Scripts de Linguagem de Controle de Transação

# ✅  Estrutura Física (O que é visível para os Administradores)

* Arquivos de Dados (.mdf .ndf .ldf)
* 1 - .mdf : Arquivo Primário do Banco de Dados chamado de Master Data File, contem toda a estrutura primária do Banco de Dados.
* 2 - .ndf : Arquivo Secundário do Banco de Dados chamado Secondary Data File, recomendado para armazenar os dados dos sistemas e aplicações, para não concorrer ou ficar no mesmo arquivo do .mdf Primário.
* 3 - .ldf : Arquivo de Log, chamado Log Data File, contêm todos os Logs de Transação do Banco de Dados

# ✅  Estrutura Lógica (O que é visível para os Desenvolvedores)

* São as estruturas que agrupam e organizam as estruturas do Banco de Dados (FileGroup, Tabela, Esquema e demais objetos do Banco de Dados)
* 1 - FileGroup - Coleções nomeadas de arquivos de Dados. Um arquivo (.mdf tem seu FileGroup padrão chamado PRIMARY, os .ndf podem ser agrupados ao FileGroup PRIMARY ou a outros FGs criados).
