USE DATAWAREHOUSE;
-- TEMP_FACT_GAMETRANSACTION - Temporary table storing (daily) dump
CREATE TABLE TEMP_FACT_GAMETRANSACTION (BETID VARCHAR(70),TRANSACTIONDATE DATE, TRANSACTION_DATETIME DECIMAL(10,5), CASHAMOUNT DECIMAL(8,1), BONUSAMOUNT DECIMAL(8,1), CHANNELUID VARCHAR(10), TXCURRENCY CHAR(3), PLAYERID BIGINT, GAMEID INT, TXTYPE VARCHAR(6));
-- LOAD (daily) dump from csv to the aforementioned temporary table - TEMP_FACT_GAMETRANSACTION
LOAD DATA INFILE 'FactGameTransaction.csv' INTO TABLE TEMP_FACT_GAMETRANSACTION FIELDS TERMINATED BY ';' LINES TERMINATED BY '\r' IGNORE 1 LINES (BETID, TRANSACTIONDATE, @DATETIME, @CASH, @BONUS, CHANNELUID, TXCURRENCY, PLAYERID, GAMEID, TXTYPE) SET TRANSACTION_DATETIME = REPLACE(@DATETIME, ',', '.'), CASHAMOUNT = REPLACE(@CASH, ',', '.'), BONUSAMOUNT = REPLACE(@BONUS, ',', '.');
-- View of WAGER rows
CREATE OR REPLACE VIEW V_TURNOVER AS SELECT * FROM TEMP_FACT_GAMETRANSACTION WHERE TXTYPE='Wager';
-- View of RESULT rows: In case of multiple rows as per a single BET, get the minimum CASH AMOUNT and BONUS AMOUNT
CREATE OR REPLACE VIEW V_WINNINGS AS SELECT BETID, TRANSACTIONDATE, TRANSACTION_DATETIME, CHANNELUID, TXCURRENCY, PLAYERID, GAMEID, MIN(CASHAMOUNT) AS CASHAMOUNT, MIN(BONUSAMOUNT) AS BONUSAMOUNT FROM TEMP_FACT_GAMETRANSACTION WHERE TXTYPE='RESULT' GROUP BY BETID, TRANSACTIONDATE, TRANSACTION_DATETIME, CHANNELUID, PLAYERID, GAMEID;
-- View of joining WAGER view and RESULT view
CREATE OR REPLACE VIEW V_COMBINED AS SELECT w.BETID AS BETID, w.TRANSACTIONDATE AS TRANSACTIONDATE, w.TRANSACTION_DATETIME AS TRANSACTION_DATETIME, w.CHANNELUID AS CHANNELUID, w.TXCURRENCY AS TXCURRENCY, w.PLAYERID AS PLAYERID, w.GAMEID AS GAMEID, w.CASHAMOUNT AS CASH_TURNOVER, w.BONUSAMOUNT AS BONUS_TURNOVER, r.CASHAMOUNT AS CASH_WINNING, r.BONUSAMOUNT AS BONUS_WINNING 
FROM V_TURNOVER w 
	INNER JOIN V_WINNINGS r ON
w.BETID = r.BETID AND w.TRANSACTIONDATE=r.TRANSACTIONDATE AND w.TRANSACTION_DATETIME = r.TRANSACTION_DATETIME AND w.CHANNELUID = r.CHANNELUID AND w.TXCURRENCY = r.TXCURRENCY AND w.PLAYERID=r.PLAYERID AND w.GAMEID = r.GAMEID;
-- QUERY FOR TESTING
-- SELECT BETID, TRANSACTIONDATE, TRANSACTION_DATETIME, CHANNELUID, PLAYERID, GAMEID, COUNT(CASH_WINNING) AS c, BONUS_WINNING FROM V_COMBINED GROUP BY BETID, TRANSACTIONDATE, TRANSACTION_DATETIME, PLAYERID, GAMEID ORDER BY c DESC/ASC; -- both DESC and ASC get the value of last row's field c should be 1
CREATE OR REPLACE TABLE FACT_GAMETRANSACTION (ID BIGINT AUTO_INCREMENT PRIMARY KEY, BETID VARCHAR(70),TRANSACTIONDATE DATE, TRANSACTION_DATETIME DECIMAL(10,5), CASH_TURNOVER DECIMAL(8,1), BONUS_TURNOVER DECIMAL(8,1), CASH_WINNING DECIMAL(8,1), BONUS_WINNING DECIMAL(8,1), CHANNELUID VARCHAR(10), TXCURRENCY CHAR(3), PLAYERID BIGINT, GAMEID INT, TXTYPE VARCHAR(6)) AUTO_INCREMENT = 1;
-- Insert transformed ready data into FACT table
INSERT INTO FACT_GAMETRANSACTION (BETID, TRANSACTIONDATE, TRANSACTION_DATETIME, CHANNELUID, TXCURRENCY, PLAYERID, GAMEID, CASH_TURNOVER, BONUS_TURNOVER, CASH_WINNING, BONUS_WINNING)
SELECT * FROM V_COMBINED; 
-- DROP temporary table
DROP TABLE TEMP_FACT_GAMETRANSACTION;