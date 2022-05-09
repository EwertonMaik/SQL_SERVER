-- O exemplo abaixo utiliza da Função ROW_NUMBER para gerar um sequência numérica automaticamente.

SELECT 
  ROW_NUMBER() OVER(ORDER BY name ASC) AS Row#,
  name, recovery_model_desc
FROM sys.databases 
WHERE database_id < 5;

-- Neste segundo exemplo, a sequência é quebrada / reiniciada a cada grudo definido pela coluna passada no parâmetro - PARTITION BY.

SELECT 
  ROW_NUMBER() OVER(PARTITION BY recovery_model_desc ORDER BY name ASC) 
    AS Row#,
  name, recovery_model_desc
FROM sys.databases WHERE database_id < 5;
