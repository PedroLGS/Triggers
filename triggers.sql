CREATE DATABASE ex_triggers_07
GO
USE ex_triggers_07
GO
CREATE TABLE cliente (
codigo        INT            NOT NULL,
nome        VARCHAR(70)    NOT NULL
PRIMARY KEY(codigo)
)
GO
CREATE TABLE venda (
codigo_venda    INT                NOT NULL,
codigo_cliente    INT                NOT NULL,
valor_total        DECIMAL(7,2)    NOT NULL
PRIMARY KEY (codigo_venda)
FOREIGN KEY (codigo_cliente) REFERENCES cliente(codigo)
)
GO
CREATE TABLE pontos (
codigo_cliente    INT                    NOT NULL,
total_pontos    DECIMAL(4,1)        NOT NULL
PRIMARY KEY (codigo_cliente)
FOREIGN KEY (codigo_cliente) REFERENCES cliente(codigo)
)

INSERT INTO cliente VALUES
(1,'Aleatorio')

INSERT INTO venda VALUES (1,1,45.00)

SELECT * FROM cliente
SELECT * FROM venda
SELECT * FROM pontos

/*
- Uma empresa vende produtos alimentícios
- A empresa dá pontos, para seus clientes, que podem ser revertidos em prêmios
- Para não prejudicar a tabela venda, nenhum produto pode ser deletado, mesmo que não venha mais a ser vendido
- Para não prejudicar os relatórios e a contabilidade, a tabela venda não pode ser alterada. 
- Ao invés de alterar a tabela venda deve-se exibir uma tabela com o nome do último cliente que comprou e o valor da 
última compra
- Após a inserção de cada linha na tabela venda, 10% do total deverá ser transformado em pontos.
- Se o cliente ainda não estiver na tabela de pontos, deve ser inserido automaticamente após sua primeira compra
- Se o cliente atingir 1 ponto, deve receber uma mensagem (PRINT SQL Server) dizendo que ganhou
*/

-- Para não prejudicar a tabela venda, nenhum produto pode ser deletado, mesmo que não venha mais a ser vendido
CREATE TRIGGER t_proddel ON venda
AFTER DELETE
AS
BEGIN
    ROLLBACK TRANSACTION
    RAISERROR('Não pode deletar nenhum produto', 16, 1)
END

-- Para não prejudicar os relatórios e a contabilidade, a tabela venda não pode ser alterada. 
CREATE TRIGGER t_altven ON venda
FOR UPDATE
AS
BEGIN
    ROLLBACK TRANSACTION
    RAISERROR('Não pode alterar nenhum produto', 16, 1)
END

-- Ao invés de alterar a tabela venda deve-se exibir uma tabela com o nome do último cliente que comprou e o valor da 
-- última compra
CREATE TRIGGER t_altven ON venda
INSTEAD OF UPDATE, DELETE
AS
BEGIN
    DECLARE @i	INT
	SET @i = 0

	SELECT c.nome, v.valor_total, MAX(codigo_venda)
	FROM cliente c
	INNER JOIN venda v
	ON c.codigo = v.codigo_cliente
	GROUP BY c.nome, v.valor_total
	HAVING @i = MAX(codigo_venda)
END

-- Após a inserção de cada linha na tabela venda, 10% do total deverá ser transformado em pontos.
CREATE TRIGGER t_transpoint ON venda
AFTER INSERT
AS
BEGIN
	DECLARE @val_ponto DECIMAL(7,2)

	SET @val_ponto = (SELECT valor_total FROM venda) * 0.10
	INSERT INTO pontos VALUES ((SELECT codigo_cliente FROM venda), @val_ponto)
END


-- Se o cliente ainda não estiver na tabela de pontos, deve ser inserido automaticamente após sua primeira compra
CREATE TRIGGER t_comcli ON pontos
AFTER INSERT
AS
BEGIN
	DECLARE @prim_compra INT

	IF (@prim_compra IS NULL)
	BEGIN
		SET @prim_compra = (SELECT codigo_cliente FROM INSERTED)
    END
END

-- Se o cliente atingir 1 ponto, deve receber uma mensagem (PRINT SQL Server) dizendo que ganhou
CREATE TRIGGER t_atinpoint ON pontos
AFTER INSERT, UPDATE
AS
BEGIN
	IF (SELECT total_pontos FROM pontos) = 1
	BEGIN
		PRINT('Ganhou')
	END
END