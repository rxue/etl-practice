# Data Warehouse ETL Solution in SQL
## Import *Fact* Transaction Data 
* `sql/mysql/import_factBetTransaction.sql` 

This script `LOAD`/import raw transaction data from CSV into a "temporary" table at first. As per each transaction, there are 2 types of rows in the CSV, one with transaction type WAGER whose realAmount and bonusAmount corresponds to *measure* cash turnover and bonus turnover, another with transaction type RESULT whose realAmount and bonusAmount corresponds to *measure* cash winning and bonus winning. As the requirement is to combine all the 4 *measures* into one row as per each transaction, there are several steps of processing, so that eventually each row in the *fact* table contains both turnover and winning amount with a unique *surrogage key*.

NOTE! In the `LOAD DATE` line, the csv `FactGameTransaction.csv` has be replaced with an existing (daily) transaction csv dump if one wants to run it for testing

## Import *Dimension* Data - Player
* `sql/mysql/import_player_history.sql`

This script is for testing with the assumption of an existing dimension table - `DIM_PLAYER` - with some historical data

* `sql/mysql/import_dimPlayer.sql`

This script import the daily dimension - Player - data into the existing dimension table with a few cases when intending to import a player (either new or existing) into the dimension table:
 
If there are existing players in the dimension table, i.e. with the same playerid, get the latest one (i.e. `VALIDTO IS NULL`) with `COUNTRY` different from today's input player row, then update this existing player's `VALIDTO` as yeasterday (`CURDATE()-1`) and insert that player into the dimension table again but with `VALIDFROM` as today (`CURDATE()`).

If there is no existing player, insert that player into the dimension table directly with `VALIDFROM` as today       

## SUMMARY
The previous solution is done in Java in the branch https://github.com/rxue/etl-practice/tree/old_java_solution/ 

Thanks to a datawarehouse professional, after his enlightenment, pure SQL solution, which is much more maintainable than Java, came out.
