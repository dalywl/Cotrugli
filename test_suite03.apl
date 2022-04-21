#! /usr/local/bin/apl --script
⍝ ********************************************************************
⍝ test_squite02apl Workspace to test cotrugli, including closing
⍝ periods and years.
⍝ Copyright (C) 2021 Bill Daly

⍝ This program is free software: you can redistribute it and/or modify
⍝ it under the terms of the GNU General Public License as published by
⍝ the Free Software Foundation, either version 3 of the License, or
⍝ (at your option) any later version.

⍝ This program is distributed in the hope that it will be useful,
⍝ but WITHOUT ANY WARRANTY; without even the implied warranty of
⍝ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
⍝ GNU General Public License for more details.

⍝ You should have received a copy of the GNU General Public License
⍝ along with this program.  If not, see <http://www.gnu.org/licenses/>.

⍝ ********************************************************************
)copy 5 FILE_IO
)copy 1 utf8
)copy 2 cotrugli

∇b←handle ts_db_exists name;cmd
  ⍝ Function test existance of a database
  cmd←'select exists(select datname from pg_catalog.pg_database where datname = ''' ,name,''')'
  b←'t'=''⍴⊃cmd SQL∆Select[handle] ''
∇

∇ handle ts_db_create dbname
  ⍝ Function creates a new database
  ('CREATE DATABASE ',dbname) SQL∆Exec[handle] ''
∇

∇ dbname ts_db_schema fname;schema;dbh
  ⍝ Functions creates database tables, views and functions
  schema← utf8∆read fname
  schema←schema,⎕tc[3],'\q'
  dbh←'w' FIO∆popen 'psql --host=localhost --username=dalyw --dbname=',dbname
  (⎕ucs schema) FIO∆fwrite dbh
  FIO∆pclose dbh
∇

∇ ts_build_config handle
  ⍝ Function populates the config table
  handle ctrgl_config_post 'accountFormat' '0000'
  handle ctrgl_config_post 'balanceFormat' '555,555,510'
  handle ctrgl_config_post 'begin_desc'     'Begining trial balance.'
  handle ctrgl_config_post 'begin_document' 'BEG_BAL'
  handle ctrgl_config_post 'begin_journal' 'gj'
∇

∇ ts_build_company handle
  ⍝ Function adds Example Co to the company table
  handle ctrgl_company_post 'ex' 'Example Co. LLC'
∇

∇ ts_build_journal handle
  ⍝ Function populates the journal table
  handle ctrgl_jrnl_post 'gj' 'General Journal'
  handle ctrgl_jrnl_post 'ck' 'Check Book'
∇

∇ ts_build_period handle
  ⍝ Function adds 2021 quarterly periods for Example Co.
  handle ctrgl_period_post 'ex' '2020-04' '10/01/2020' '12/31/2020' 1
  handle ctrgl_period_post 'ex' '2021-01' '01/01/2021' '03/31/2021' 0
  handle ctrgl_period_post 'ex' '2021-02' '04/01/2021' '06/30/2021' 0
  handle ctrgl_period_post 'ex' '2021-03' '07/01/2021' '09/30/2021' 0
  handle ctrgl_period_post 'ex' '2021-04' '10/01/2021' '12/31/2021' 1
∇

∇ ts_build_accounts handle
  ⍝ Function populates the accounts table
  handle ctrgl_chart_post 'ex' '3100' 'Common Stock' 'b' 'c'
  handle ctrgl_chart_post 'ex' '1010' 'Cash' 'b' 'd'
  handle ctrgl_chart_post 'ex' '1110' 'Accounts Receivable' 'b' 'd'
  handle ctrgl_chart_post 'ex' '1310' 'Inventory' 'b' 'd'
  handle ctrgl_chart_post 'ex' '1320' 'Labor in inventory' 'b' 'd'
  handle ctrgl_chart_post 'ex' '1390' 'Overhead in inventory' 'b' 'd'
  handle ctrgl_chart_post 'ex' '1410' 'Prepaid expense' 'b' 'd'
  handle ctrgl_chart_post 'ex' '1510' 'Plant' 'b' 'd'
  handle ctrgl_chart_post 'ex' '1520' 'Equipment' 'b' 'd'
  handle ctrgl_chart_post 'ex' '1590' 'Accumulated Depreciation' 'b' 'd'
  handle ctrgl_chart_post 'ex' '2010' 'Current notes payable' 'b' 'c'
  handle ctrgl_chart_post 'ex' '2110' 'Accounts payable' 'b' 'c'
  handle ctrgl_chart_post 'ex' '2310' 'Accrued expense' 'b' 'c'
  handle ctrgl_chart_post 'ex' '2710' 'Long-term debt' 'b' 'c'
  handle ctrgl_chart_post 'ex' '5010' 'Sales' 'i' 'c'
  handle ctrgl_chart_post 'ex' '6010' 'Material cost of sales' 'i' 'd'
  handle ctrgl_chart_post 'ex' '6110' 'Labor cost of sales' 'i' 'd'
  handle ctrgl_chart_post 'ex' '6910' 'Overhead cost of sales' 'i' 'd'
  handle ctrgl_chart_post 'ex' '7010' 'Salaries and wages' 'i' 'd'
  handle ctrgl_chart_post 'ex' '7020' 'Payroll taxes' 'i' 'd'
  handle ctrgl_chart_post 'ex' '7030' 'Health insurance' 'i' 'd'
  handle ctrgl_chart_post 'ex' '7110' 'Janitorial supplies' 'i' 'd'
  handle ctrgl_chart_post 'ex' '7120' 'Building repairs and maintenance' 'i' 'd'
  handle ctrgl_chart_post 'ex' '7150' 'Utilities' 'i' 'd'
  handle ctrgl_chart_post 'ex' '7210' 'Professional fees' 'i' 'd'
  handle ctrgl_chart_post 'ex' '7510' 'Insurance' 'i' 'd'
  handle ctrgl_chart_post 'ex' '7610' 'Interest' 'i' 'd'
  handle ctrgl_chart_post 'ex' '8910' 'Federal income taxes' 'i' 'd'
  handle ctrgl_chart_post 'ex' '8920' 'State income taxes' 'i' 'd'
  handle ctrgl_chart_post 'ex' '3990' 'Retained Earnings' 'r' 'c'
∇

∇ ts_build_begin handle ;begin
  ⍝ Function creates begining balanes 
  begin ← ctrgl_doc_init 'ex' 'gj' 'begin' '12/31/2020' 'To record opening balances' '2020-04'
  begin←begin ctrgl_doc_debit 1010 45000
  begin←begin ctrgl_doc_debit 1410 2500
  begin←begin ctrgl_doc_debit 1510 1300000
  begin←begin ctrgl_doc_debit 1520 755000
  begin←begin ctrgl_doc_credit 1590 140400
  begin←begin ctrgl_doc_credit 2110 41750
  begin←begin ctrgl_doc_credit 2710 1644000
  begin←begin ctrgl_doc_credit 3100 1000
  begin←begin ctrgl_doc_credit 3990 273128
  begin←begin ctrgl_doc_debit 7010 25337
  begin←begin ctrgl_doc_debit 7030 2506
  begin←begin ctrgl_doc_debit 6010 57817
  begin←begin ctrgl_doc_credit 5010 87882
  ⍞←handle ctrgl_doc_show begin
  handle ctrgl_doc_post begin
∇

∇ schema main dbname;dbh
  dbh←'postgresql' SQL∆Connect 'host=localhost user=dalyw dbname=dalyw password=1BBmXEc0'
  ⍝ Remove last test results from postgres
  →(~dbh ts_db_exists 'test01')/BuildDB
  ('DROP DATABASE ',dbname) SQL∆Exec[dbh] ''
BuildDB:
  ⍝ Create and poplate a new database
  dbh ts_db_create dbname
  SQL∆Disconnect dbh
  dbname ts_db_schema schema
  dbh←'postgresql' SQL∆Connect 'host=localhost user=dalyw dbname=',dbname,' password=1BBmXEc0'
  ts_build_config dbh
  ts_build_company dbh
  ts_build_journal dbh
  ts_build_period dbh
  ts_build_accounts dbh
  ts_build_begin dbh
∇

