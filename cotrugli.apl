#! /usr/local/bin/apl --script
⍝ ********************************************************************
⍝ cotrugli.apl APL workspace provides a bookkeeping system.
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

)copy_once 5 SQL
)copy_once 1 wp
)copy_once 1 date
)copy_once 1 cl

⍝ ********************************************************************
⍝ Integrity checking
⍝ ********************************************************************
∇b←handle ctrgl_check_company co;cmd
  ⍝ Function confirms the co is defined in the company table.
  cmd←'SELECT company from company where company = ''',co,''''
  b←0≠1↑⍴cmd SQL∆Select[handle] ''
  →0
∇

∇b←handle ctrgl_check_account args;co;acct;cmd
  ⍝ Function confirms an acct is defined in the accounts table.The
  ⍝ right argument is the company and account number.
  →(~b←∧/∊utl∆stringp ¨ args)/0	⍝ accounts as numbers not acceptable. 
  cmd←'SELECT acct_no from accounts where company = ? and acct_no = ?'
  b←0≠1↑⍴cmd SQL∆Select[handle] args
∇

∇b←handle ctrgl_check_period args;cmd
  ⍝ Function confirms that the period is defined. The right argument
  ⍝ is a nested vector of company and period.
  cmd←'SELECT period from periods where company = ? and period = ?'
  b←0≠1↑⍴cmd SQL∆Select[handle] args
∇

∇b←handle ctrgl_check_journal jrnl;cmd
  ⍝ Function confirms that a journal is defined.
  cmd←'SELECT jrnl FROM journal where jrnl = ''',jrnl,''''
  b←0≠1↑⍴cmd SQL∆Select[handle] ''
∇

∇id←handle ctrgl_check_doc head;cmd;co;nm;pd
  ⍝ Function returns the document id. Documents are
  ⍝ defined by the company, journal, name, and period.
  co←1⊃head ◊ jr←2⊃head ◊ nm←3⊃head  ◊ pd←4⊃head
  cmd←'SELECT doc_id FROM document WHERE company = ? and journal = ? and name = ? and period = ?'
  id←⍬⍴cmd SQL∆Select[handle] co jr nm pd
∇

⍝ ********************************************************************
⍝ Functions to implement the sql interface
⍝ ********************************************************************

∇handle←ctrgl_sql_connect args;constr
  ⍝ Function to connect to the postgres server
  constr←'host=',(1⊃args),' user=',(2⊃args),' dbname=',(3⊃args),' password=',4⊃args
  handle←'postgresql' SQL∆Connect constr
∇

∇ctrgl_sql_disconnect handle
  ⍝ Function to disconnect from the postgres server
  SQL∆Disconnect handle
∇

∇ctrgl_sql_rollback handle
  ⍝ Functions rolls back the current sql transaction
  SQL∆Rollback handle
∇

∇rs←ctrgl_sql_escape_quotes txt;loc
  ⍝ Function returns the text with single quotes escaped for
  ⍝ postgresql
  rs←txt
  →(∧/~txt='''')/0		⍝ Nothing to do
  loc←+/1,∧\''''≠txt
  rs←(loc↑rs),'''',ctrgl_sql_escape_quotes loc↓txt
∇


∇data←ctrgl_sql_company handle;cmd
  ⍝ Function returns the company table
  cmd←'SELECT company,coname FROM company ORDER BY company'
  data←cmd SQL∆Select[handle] ''
∇

∇data←handle ctrgl_sql_tb args;company;period;cmd
  ⍝ Function returns a trial balance array. Right argument is a nested
  ⍝ vector of company and period.
  company←1⊃args ◊ period←2⊃args
  cmd←'SELECT acct, title, '
  cmd←cmd,'CASE WHEN dr > cr then dr - cr else 0 end as debit, '
  cmd←cmd,'CASE WHEN cr > dr then cr - dr else 0 end as credit, '
  cmd←cmd,'acct_type, sign_type from tb join accounts '
  cmd←cmd,'on tb.co = accounts.company and tb.acct = accounts.acct_no '
  cmd←cmd,'where co = ''',company, ''' and period =''',period,''' order by acct'
  data←cmd SQL∆Select[handle] ''
  ⍎(1=⍴⍴data)/'data←0 6⍴data'
∇

∇ data←handle ctrgl_sql_account args;co;pd;acct;cmd
  ⍝ Function returns an array of transactions post to an
  ⍝ account. Right argument is a nested array of company, period, and
  ⍝ account_no.
  co←1⊃args ◊ pd←2⊃args ◊ acct←3⊃args
  cmd←'SELECT doc_date, jrnl, doc, description, debit, credit '
  cmd←cmd, 'from DOCS WHERE co = ''', co,''' and period = ''', pd
  cmd←cmd, ''' and acct = ''', acct, ''' ORDER BY doc_date,doc'
  data←cmd SQL∆Select[handle] ''
∇

∇ data←ctrgl_sql_config handle;cmd
  ⍝ Function returns the configuration table as a lexicon
  cmd←'SELECT trim(name),value from config order by name'
  data←cmd SQL∆Select[handle] ''
∇

∇ data←handle ctrgl_sql_chart co;cmd
  ⍝ Function returns the chart of accounts.
  cmd←'SELECT acct_no, title, acct_type, sign_type FROM accounts '
  cmd←cmd,'WHERE company = ''', co, ''' order by acct_no'
  data←cmd SQL∆Select[handle] ''
∇

∇data←handle ctrgl_sql_entry args;co;pd;jrnl;name;cmd
  ⍝ Function returns an entry. The right argument is a nested array of
  ⍝ company, period, journal, and document name.
  co←1⊃args ◊ pd←2⊃args ◊ jrnl←3⊃args ◊ name←4⊃args
  cmd←'SELECT doc_date, description, acct, debit, credit '
  cmd←cmd, 'FROM docs WHERE co=''', co, ''' and period=''', pd, '''  '
  cmd←cmd, 'and jrnl=''', jrnl, ''' and doc=''', name, ''''
  data←cmd SQL∆Select[handle] ''
∇

∇ data←handle ctrgl_sql_checkbook args;co;period;acct;cmd
  ⍝ Function returns a checkbook array. The right argument is a nested
  ⍝ array of company, period, and account number.
  co←1⊃args ◊ period←2⊃args ◊ acct←3⊃args
  cmd←'SELECT doc_date, doc, description, debit, credit, '
  cmd←cmd, 'cast(''p'' as varchar) from DOCS '
  cmd←cmd, 'WHERE co=''',co,''' and period=''',period,''' and acct=''',acct,''''
  data←cmd SQL∆Select[handle] ''
∇

∇data←handle ctrgl_sql_periods co;cmd
  ⍝ Function returns an array of the periods defined for a company
  cmd←'SELECT period, begin_date, end_date, year_end FROM periods WHERE company = ''',co,''' '
  cmd←cmd,'ORDER BY period'
  data←cmd SQL∆Select[handle] ''
∇

∇data←ctrgl_sql_journals handle;cmd
  ⍝ Function returns an array of the defined journals.
  cmd←'SELECT jrnl, title, account FROM journal order by jrnl'
  data←cmd SQL∆Select[handle] ''
∇

∇doc←handle ctrgl_sql_doc args;co;pd;jl;nm;hd;bd;cmd;doc_id
  ⍝ Function returns a document. The right argument is company,
  ⍝ period, journal, and name.
  co←1⊃args ◊ pd←2⊃args ◊ jl←3⊃args ◊ nm← 4⊃args
  cmd←"SELECT doc_id, doc_date, description from document where company = ? and period = ? and journal = ? and name = ?"
  ⍝ Head is doc_id, company, journal, name, date, description, and period.
  hd←cmd SQL∆Select[handle] co pd jl nm
  hd←1 0 0 0 1 1 0 \,hd
  hd[2]←⊂co ◊ hd[3]←⊂jl ◊ hd[4]←⊂nm ◊ hd[7]←⊂pd
  cmd←"SELECT doc_id, line_no, acct_no, debit, credit from doc_lines where doc_id = ?"
  bd←cmd SQL∆Select[handle] 1⊃hd
  doc←hd bd
∇
  
  

⍝ ********************************************************************
⍝ Function to build workpaper attributes
⍝ ********************************************************************

∇ attr←ctrgl_attr_acctNo cfg
  ⍝ Function returns a lexicon of attributes for an acct number in a
  ⍝ wp cell
  attr←((lex∆init) lex∆assign (⊂'format'),⊂cfg lex∆lookup 'accountFormat')lex∆assign  'class' 'number'
∇

∇ attr←ctrgl_attr_balance cfg
  ⍝ Function returns a lexicon of attributes for a debit or a credit
  ⍝ cell.
  attr←((lex∆init)lex∆assign (⊂'format'),⊂cfg lex∆lookup 'balanceFormat')lex∆assign 'class' 'number'
∇

⍝ ********************************************************************
⍝ Maintain the config table
⍝ ********************************************************************

∇ handle ctrgl_config_post args;cmd;name;value;rs
  ⍝ Function to post a name -- value pair to the config table.
  name←1⊃args ◊ value←2⊃args
  cmd←'SELECT EXISTS(SELECT trim(name) FROM config WHERE name = ''',name,''')'
  →('t'=''⍴⊃rs←cmd SQL∆Select[handle] '')/replace
insert:
  cmd←'INSERT INTO config (name,value) VALUES (?,?)'
  cmd SQL∆Exec[handle] name value
  →0
replace:
  cmd←'UPDATE config SET value = ? WHERE name = ?'
  cmd SQL∆Exec[handle] value name
  →0
∇

⍝ ********************************************************************
⍝ Functions to open various workspapers
⍝ ********************************************************************

∇wp←ctrgl_open_config handle
  ⍝ Function returns a list of configuration name--value pairs
  wp←wp∆init 'config'
  data←ctrgl_sql_config handle
  wp←wp wp∆setData 'name' 'value',[1]data
  wp←wp wp∆setHeading 'Cotrugli database' 'Configuration'
  wp←wp wp∆setStylesheet ctrgl_default_css
  wp←wp wp∆setAttributes (1 0+⍴data)⍴⊂lex∆init
∇ 

∇wp←ctrgl_open_company handle;id;data
  id←'company table'
  wp←wp∆init id
  data←ctrgl_sql_company handle
  wp←wp wp∆setData 'company' 'name',[1]data
  wp←wp wp∆setHeading 'Cotrugli database' 'Company Table' ''
  wp←wp wp∆setStylesheet ctrgl_default_css
  wp←wp wp∆setAttributes (1 0+⍴data)⍴⊂lex∆init
∇

∇wp←handle ctrgl_open_periods co;data
  ⍝ Function preparse a workpaper showing the periods defined for a company.
  wp←wp∆init co,'-PD'
  wp←wp wp∆setHeading co 'Periods' ''
  wp←wp wp∆setData 'Period' 'Begin' 'End' 'y/e',[1]handle ctrgl_sql_periods co
  wp←wp wp∆setStylesheet ctrgl_default_css
  wp←wp wp∆setAuthor 'cotrugli'
∇

∇wp←ctrgl_open_journals handle;data
  ⍝ Function preparse a workpaper showing the periods defined for a company.
  wp←wp∆init 'jrnls'
  wp←wp wp∆setHeading 'Cotrugli System' 'Journals' ''
  wp←wp wp∆setData 'code' 'Name' 'Account',[1] ctrgl_sql_journals handle
  wp←wp wp∆setStylesheet ctrgl_default_css
  wp←wp wp∆setAuthor 'cotrugli'
  wp←wp wp∆setAttributes (⍴wp∆getData wp)⍴⊂ lex∆init
∇

∇wp←handle ctrgl_open_tb args;company;period;id;data;attr;ix
  ⍝ Function returns a trial balance workpaper.  Right argument is a
  ⍝ nested vector of company and period.
  company←1⊃args ◊ period←2⊃args ◊ id←'TB-',period
  cfg←ctrgl_sql_config handle
  wp←wp∆init id
  data←handle ctrgl_sql_tb company period
  data←'Acct No' 'Title' 'Debit' 'Credit' 'A Type' 'S Type',[1]data
  wp←wp wp∆setData data
  wp←wp wp∆setHeading company 'Trial Balance' period
  wp←wp wp∆setStylesheet ctrgl_default_css
  attr←(⍴data)⍴⊂lex∆init
  attr[ix←1↓⍳1↑⍴data;1]←⊂ctrgl_attr_acctNo cfg
  attr[ix;3 4]←⊂ctrgl_attr_balance cfg
  wp←wp wp∆setAttributes attr
∇

∇wp←handle ctrgl_open_account args;co;pd;acct;data
  ⍝ Function returns a workpaper showing the transactions posted to an
  ⍝ account during a period.  The right argument is a nested array of
  ⍝ company, period and account.
  co←1⊃args ◊ pd←2⊃args ◊ acct←3⊃args
  wp←wp∆init 'AC_',acct
  wp←wp wp∆setHeading co acct pd
  data←handle ctrgl_sql_account co pd acct
  data←data,0
  data[1↑⍴data;1↓⍴data]←-/+⌿data[;5 6]
  data←'date' 'jrnl' 'name' 'description' 'dr' 'cr' 'balance',[1]data
  wp←wp wp∆setData data 
∇

∇wp←handle ctrgl_open_chart company;data
  ⍝ Function returns a workpaper showing the chart of accounts.
  wp←wp∆init 'CHART'
  wp←wp wp∆setHeading company 'Chart of Accounts' ''
  data← handle ctrgl_sql_chart company
  data←'Acct No' 'Title' 'acct type' 'sign type',[1]data
  wp←wp wp∆setData data
∇

⍝ ********************************************************************
⍝ Maintain the company table
⍝ ********************************************************************

∇msg←cth ctrgl_company_post_editchecks args;co;name
  ⍝ Function confirms input to ctrgl_company_post
  co←1⊃args ◊ name←2⊃args
  msg←''
  ⍎(~utl∆stringp co)/'msg←''Company must be a character string. ◊ →0'''
  ⍎(~utl∆stringp name)/'msg←''The company name must be a character string. ◊ →0'''
∇

∇cth ctrgl_company_post args;co;name;cmd;rs
  ⍝ Function posts a company to the database. The right argument is
  ⍝ company code and company name.
  utl∆es cth ctrgl_company_post_editchecks args
  co←1⊃args ◊ name←2⊃args
  cmd←'SELECT company from company WHERE company = ''',co,''''
  →(0≠1↑⍴rs←cmd SQL∆Select[cth] '')/replace
insert:
  cmd←'INSERT INTO company (company,coname) VALUES (?,?)'
  cmd SQL∆Exec[cth] co name
  →0
replace:
  cmd←'UPDATE company SET coname = ? WHERE company = ?'
  cmd SQL∆Exec[cth] name co
  →0
∇

⍝ ********************************************************************
⍝ Maintain the period table
⍝ ********************************************************************

∇ msg←cth ctrgl_period_post_editchecks pd;co;name;begin;end;ye;dtest;bv
  ⍝ Function to post a period to the database.
  (co name begin end ye)←pd
  msg←''
  ⍎(~cth ctrgl_check_company co)/'msg←''',co,' is not defined.'' ◊ →0'
  ⍎(~utl∆stringp name)/'msg←''The period name must be a character string. ◊ →0'''
  dtest←(⊂date∆US) date∆parse ¨ begin end
  ⍎(∨/bv)/'msg←',((bv←utl∆stringp ¨ dtest)/dtest),' is not a date ◊ →0'
  ⍎(~</date∆lillian ¨ dtest)/'msg←''The begining data must be less than the ending'' ◊ →0'
  ⍎(~utl∆numberp ye)/'msg←''Year-end is either true (1) or false (0).'' ◊ →0'
  ⍎(∧/1 0 ≠ ye←''⍴ye)/'msg←''Year-end is either true (1) or false (0).'' ◊ →0'
∇

∇handle ctrgl_period_post pd;cmd;name;ye
  ⍝ Function fo post a period.  A period is the company, name, begining
  ⍝ date, ending date and year end flag.
  utl∆es handle ctrgl_period_post_editchecks pd
  ye←'FT'[⎕io+5⊃pd]		⍝ Convert APL boolean to SQL boolean
  cmd←'SELECT period FROM periods WHERE company = ? and period = ?'
  →(0≠1↑⍴name←cmd SQL∆Select[handle] pd[1 2])/replace
insert:
  cmd←'INSERT INTO periods (company, period, begin_date, end_date, year_end) VALUES ('
  cmd←cmd,'''',(1⊃pd),''','
  cmd←cmd,'''',(2⊃pd),''','
  cmd←cmd,'''',(3⊃pd),''','
  cmd←cmd,'''',(4⊃pd),''','
  cmd←cmd,'''',ye,''')'
  cmd SQL∆Exec[handle] ''
  →0
replace:
  cmd←'UPDATE periods set begin_date = ''',(3⊃pd)
  cmd←cmd,''', end_date = ''',(4⊃pd),''', year_end = ''',ye
  cmd←cmd,''' WHERE company = ''',(1⊃pd),''' and period = '''
  cmd←cmd,(2⊃pd),''''
  cmd SQL∆Exec[handle] ''
  →0
∇

∇ begin←handle ctrgl_period_begin args;co;pd
  ⍝ Function returns the date a period begins
  (co pd)←args
  cmd←'SELECT begin_date FROM periods WHERE company = ? and period = ?'
  begin←,⊃cmd SQL∆Select[handle] co pd
∇

∇ end←handle ctrgl_period_end args;co;pd
  ⍝ Functionreturns the date a period ends
  (co pd)←args
  cmd←'SELECT end_date FROM periods WHERE company = ? and period = ?'
  end←,⊃cmd SQL∆Select[handle] co pd
∇

∇last←handle ctrgl_period_prev args;co;pd;cmd;rs;begin
  ⍝ Function returns the previous period for the company, period
  ⍝ provided. The right argument is the company and period
  (co pd)←args
  rs←handle ctrgl_period_begin co pd
  begin←¯1 + date∆lillian date∆US date∆parse rs
  begin←date∆US date∆fmt∆3numbers date∆unlillian begin
  cmd←'SELECT period FROM periods where company = ? and end_date = ?'
  last←,⊃cmd SQL∆Select[handle] co begin
∇

∇next←handle ctrgl_period_next args;co;pd;cmd;raw;begin
  ⍝ Function returns the next period of a company. rarg is company,
  ⍝ period.
  (co pd)←args
  raw←handle ctrgl_period_end co pd
  begin←1 + date∆lillian date∆US date∆parse raw
  begin←date∆US date∆fmt∆3numbers date∆unlillian begin
  cmd←'SELECT period FROM periods WHERE company = ? and begin_date = ?'
  next←,⊃cmd SQL∆Select[handle] co begin
∇

∇b←handle ctrgl_period_yep args;co;pd;cmd
  ⍝ Function returns true if the period is the last in a fiscal
  ⍝ year. The right argument  is a vector of company and period.
  (co pd)←args
  cmd←'SELECT year_end from periods where company = ? and period = ?'
  b←'t'=''⍴⊃cmd SQL∆Select[handle] co pd
∇


⍝ *******************************************************************
⍝ Maintain the journal table
⍝ ********************************************************************

∇msg←ctrgl_jrnl_post_editCheck args
  ⍝ Function to confirm journal information is useable
  msg←''
  ⍎(~utl∆stringp 1⊃args)/'msg←''The journal code must be a character string.'''
  ⍎(~utl∆stringp 2⊃args)/'msg←''The journal name must be a character string.'''
∇

∇handle ctrgl_jrnl_post args;code;name;account;cmd;rs
  ⍝ Function to create or update a journal. The right argument is a
  ⍝ nested vector of journal code, journal name, and optionally, account.
  utl∆es ctrgl_jrnl_post_editCheck args
  code←1⊃args ◊ name←2⊃args ◊ account←3⊃args
  ⍝ Test for insertion or replacement
  cmd←'select jrnl from journal where jrnl = ?'
  →(0≠1↑rs←cmd SQL∆Select[handle] ⊂code)/replace
insert:
  cmd←'INSERT INTO journal (jrnl,title,account) VALUES (?,?,?)'
  rs←cmd SQL∆Exec[handle] code name account
  →0
replace:
  cmd←'UPDATE journal set title to ?, account to ? WHERE jrnl = ?'
  rs←cmd SQL∆Exec[handle] name account code
  →0
∇

⍝ ********************************************************************
⍝ Functions to maintain the chart of accounts
⍝ ********************************************************************

∇acct←handle ctrgl_chart_fetch args;company;acctno;cmd
  ⍝ Function returns a record from the chart of accounts. The right
  ⍝ argument is a nested vector of company and account number
  cmd←'SELECT title, acct_type, sign_type from accounts',⎕tc[3]
  cmd←cmd,'where company = ? and acct_no = ?'
  acct←cmd SQL∆Select[handle] args
∇

∇msg←handle ctrgl_chart_post_editchecks account
  ⍝ Function checks an account entry before posting to the database.
  msg←⍬
  →(5=⍴account←,account)/more
  msg←'An account consists of a company, ',⎕tc[3]
  msg←msg,'acccount number, title, account type, and sign type'
  →0
more:
  ⍎(~handle ctrgl_check_company 1⊃account)/'msg←(1⊃account),'' is not a defined company.'''
  ⍎(0≠⍴⍴4⊃account)/'msg←''Account type is one of b, i, or r'' ◊ →0'
  ⍎(~(4⊃account)∊'b' 'i' 'r')/'msg←''Account type is one of b, i, or r'' ◊ →0'
  ⍎(0≠⍴⍴5⊃account)/'msg←''Sign type is one of ''d'' or ''c'' ◊ →0'
  ⍎(~(5⊃account)∊'d' 'c')/'msg←''Sign type is one of ''d'' or ''c'' ◊ →0'
  ⍎((utl∆stringp 1⊃account)∧utl∆numberis 1⊃account)/'msg←''An account must be the text of a integer'' ◊ →0'
∇

∇handle ctrgl_chart_post args
  ⍝ Function posts an account to the chart of accounts. An existing
  ⍝ account will be overwritten. The right argment is a nested vector
  ⍝ of company, acct_no, title, acct_type, and sign_type
  utl∆es handle ctrgl_chart_post_editchecks args
  →(handle ctrgl_check_account args[1 2])/replace
add:
  cmd←'INSERT INTO accounts (company, acct_no, title, acct_type, sign_type) VALUES (?,?,?,?,?)'
  cmd SQL∆Exec[handle] args
  →0
replace:
  cmd←'UPDATE accounts SET title = ?, acct_type = ?, sign_type = ? WHERE company = ? and acct_no = ?'
  cmd SQL∆Exec[handle] args[3 4 5 1 2]
  →0
∇

⍝ ********************************************************************
⍝ Functions about a document
⍝ A document is the basic unit of input and consists of a head and a
⍝ body. The head is a vector of doc_id, company, journal, name, date,
⍝ description, and period. A body is an array of account number, debit
⍝ and credit.  There must be at least two lines, and the total debits
⍝ must equal the total credits.
⍝ ********************************************************************

∇msg←ctrgl_doc_init_editchecks args
  ⍝   ⍝ Function checks the arguments to ctrgl_doc_init and returns an
  ⍝   ⍝ appropriate error message
  msg←⍬
  →(6=⍴args)/more
  msg←'Length error argument must be a six item vector of company,',⎕tc[3]
  msg←msg,'journal, name, date, description and period.'
  →0
more:⍎(~utl∆stringp 1⊃args)/'msg←''The company must be a string of characters.'' ◊ →0'
  ⍎(~utl∆stringp 2⊃args)/'msg←''The journal must be a string of characters.'' ◊ →0'
  ⍎(~utl∆stringp 3⊃args)/'msg←''The document name must be a string of characters.'' ◊ →0'
∇

∇doc← ctrgl_doc_init args;rootNode;flds
  ⍝ Functions creates a document.  args is a vector of six items:
  ⍝ company, journal, name, date, description, and period.
  utl∆es ctrgl_doc_init_editchecks args
  doc←(⊂0, args),⊂0 5⍴0
∇

∇new←doc ctrgl_doc_credit ln
  ⍝ Function to add or replace a line in doc with a debit.
  utl∆es (2≠⍴ln←,ln)/'LENGTH ERROR ARGUMENT MUST BE A TWO ITEM VECTOR'
  new←doc ctrgl_doc_newLine 0 0, ln[1], 0, ln[2]
∇

∇new←doc ctrgl_doc_debit ln
  ⍝ Function to add or replace a line in doc with a debit.
  utl∆es (2≠⍴ln←,ln)/'LENGTH ERROR ARGUMENT MUST BE A TWO ITEM VECTOR'
  new←doc ctrgl_doc_newLine 0 0, ln, 0
∇

∇new←ctrgl_doc_get_description entry
  new←1 6⊃entry
∇

∇new←entry ctrgl_doc_set_description desc;head;body
  (head body)←entry
  head←head[⍳5],⊂desc
  new←head body
  →0
∇

∇new←ctrgl_doc_get_name entry
  new←1 4⊃entry
∇

∇new←entry ctrgl_doc_set_name name;head;body
  (head body)←entry
  head←head[⍳3],(⊂name),head[5 6]
  new←head body
∇

∇new←doc ctrgl_doc_newLine ln;head;docLines;ix;ct
  ⍝ Function appends a new line or replaces and old line (based on
  ⍝ account) in a document. Called by ctrgl_doc_debit and ctrgl_doc_credit.
  (head docLines)←doc
  →(0=ct←1↑⍴docLines)/add
  →(ct<ix←docLines[;3]⍳ln[3])/add
replace:
  ln←ln[1],ix,2↓ln
  docLines←docLines[⍳ix-1;],[1]ln,[1](ix 0)↓docLines
  →end
add:
  ln←ln[1],(1+''⍴⍴docLines),2↓ln
  docLines←docLines,[1]ln
  →end
end:
  new←head docLines
∇

∇msg←lines ctrgl_doc_delLine_editchecks acct
  msg←⍬
  ⍎ (~utl∆stringp acct)/'msg←''ACCOUNT NUMBER IS NOT A CHARACTER STRING'' ◊ →0'
  ⍎ ((1↑⍴acct)<lines[;3] utl∆listSearch acct)/'msg←(⍕acct),'' NOT FOUND'' ◊ →0'
∇

∇doc←old ctrgl_doc_delLine acct;head;lines
  ⍝ Function to delete a line from a document.
  (head lines)←old
  utl∆es lines ctrgl_doc_delLine_editchecks acct
  doc←(⊂head),⊂(~∊{acct utl∆stringEquals ⍵}¨lines[;3])⌿lines
∇

∇wp_head←cfg ctrgl_doc_wp_head doc
  ⍝ Function returns the heading for the document report
  wp_head←(1⊃doc)[2],meta_doc[4],⊂'Period ',5⊃meta_doc
∇

∇dat←handle ctrgl_doc_wp_dat doc;co;lines;cmd
  ⍝ Function returns the array to be displayed in a document workpaper
  co←1 2⊃doc ◊ lines ← 2⊃doc
  cmd←'SELECT trim(acct_no), title from accounts WHERE company = ? and acct_no = ?'
  dat←{,cmd SQL∆Select[handle] ⍵}¨⊂[2](⊂co),[1.1]lines[;3]
  dat←(((⍴dat),2)⍴⊃dat),lines[;4 5]
  ⍝dat←accounts[{accounts[;1] utl∆listSearch ⍵}¨lines[;3];1 2],lines[;4 5]
  dat←dat,[1](⊂''),(⊂'Total'),+⌿lines[;4 5]
∇

∇list←handle ctrgl_doc_list args;hd;bd
  ⍝ Function creates a list of documents from a list of document
  ⍝ headings and a list of document bodies.  The right argment is
  ⍝ headings bodies.
  hd←⊂[2]1⊃args ◊ bd←2⊃args
  list←hd{(⊂⍺),⊂⍵}¨bd
∇

∇wp←handle ctrgl_doc_workpaper doc;aix;meta_doc;lines;attr;dat;config;accounts
  ⍝ Function returns a workpaper displaying a document
  config←ctrgl_sql_config handle 
  ⍝accounts←handle ctrgl_sql_chart 1 2⊃doc ◊
  meta_doc←1⊃doc ◊ lines←2⊃doc
  wp←wp∆init 3⊃meta_doc
  wp←wp wp∆setHeading config ctrgl_doc_wp_head doc
  wp←wp wp∆setAuthor 'cotrugli'
  wp←wp wp∆setData handle ctrgl_doc_wp_dat doc 
  wp←wp wp∆setStylesheet ctrgl_default_css
  attr←(⍴wp∆getData wp)⍴⊂lex∆init
  attr[;1]←⊂ctrgl_attr_acctNo config
  attr[;3 4]←⊂ctrgl_attr_balance config
  wp←wp lex∆assign 'Attributes' attr
  wp←wp lex∆assign 'Stylesheet' ctrgl_default_css
  wp←wp lex∆assign (⊂'Footer'), meta_doc[6]
∇

∇msg←handle ctrgl_doc_post_checkHead head
  ⍝ Function confirms that a document's head is ok.
  msg←⍬
  ⍝ company is item 2
  ⍎(~handle ctrgl_check_company 2⊃head)/'msg←''',(2⊃head),' is not defined.'''
  ⍝ journal is item 3
  ⍎( ~handle ctrgl_check_journal 3⊃head)/'msg←''',(3⊃head),' is not defined.'''
  ⍝ Document name is item 4
  ⍎(~utl∆stringp 4⊃head)/'msg←''The document name must be a character string.'''
  ⍝ Document date is item 5
  ⍎(∧/'NOT A DATE'=10↑date∆US date∆parse 5⊃head)/'msg←''',(5⊃head),' is not a date'''
  ⍝ Document description is item 6
  ⍎(~utl∆stringp 6⊃head)/'msg←''The document description must be a character string.'''
  ⍝ Period is item 7
  ⍎(~handle ctrgl_check_period head[2 7])/'msg←''',(7⊃head),' is not a valid period.'''
∇

∇msg←handle  ctrgl_doc_post_checkBody doc;cmd;head;body;co;rs
  ⍝ Function confirms the body of a document can be posted.
  head←1⊃doc ◊ body←2⊃doc ◊ co ← 2⊃head
  msg←''
  ⍝ Column 3 is account numbers
  cmd←'SELECT acct_no FROM accounts where company = ? and acct_no = ?'
  rs←{⍬⍴cmd SQL∆Select[handle] ⍵}¨⊂[2](⊂co),[1.1]body[;3]
  ⍝ rs←cmd SQL∆Select[handle] (⊂co),[1.1]body[;3]
  →(∧/rs←utl∆stringp ¨ rs)/m1
  msg←(,⍕(~rs)/body[;3]),' not in chart of accounts.'
  →0
m1:
  →(∧/rs←utl∆numberp ¨,body[;4 5])/m2
  msg←(,⍕rs/,body[;4 5]),' are not numbers.'
  →0
m2:
  →(0=¯2 utl∆round -/+⌿body[;4 5])/0
  msg←'The debits do not equal the credits.'
  →0
∇

∇handle ctrgl_doc_insert doc;head;body;cmd
  ⍝ Function inserts a new document into the database
  head←1⊃doc ◊ body←2⊃doc
  cmd←'INSERT INTO document (doc_id,company,journal,name,doc_date,description,period) VALUES('
  cmd←cmd,'nextval(''document_doc_id_seq''),'
  cmd←cmd,'''',(2⊃head),''','	        ⍝ Company
  cmd←cmd,'''',(3⊃head),''',' 	⍝ journal
  cmd←cmd,'''',(4⊃head),''',' 	⍝ name
  cmd←cmd,'DATE ''',(5⊃head),''','     ⍝ doc_date
  cmd←cmd,'''',(6⊃head),''','	        ⍝ description
  cmd←cmd,'''',(7⊃head),''')'		⍝ period
  cmd SQL∆Exec[handle] ''
  cmd←'SELECT lastval()'
  head[1]←⍬⍴cmd SQL∆Select[handle] ''
  body[;1]←head[1]
  cmd←'INSERT INTO doc_lines (doc_id,line_no,acct_no,debit,credit,company) VALUES (?,?,?,?,?,?)'
  cmd SQL∆Exec[handle] body,head[2]
∇

∇handle ctrgl_doc_replace doc;cmd
  ⍝ Function replaces a document in to database.
  head←1⊃doc ◊ body←2⊃doc
  cmd←'SELECT doc_id FROM document WHERE company = ? and journal = ? and name = ? and period = ?'
  head[1]←⍬⍴cmd SQL∆Select[handle] head[2 3 4 7]
  body[;1]←head[1]
  cmd←'UPDATE document set description= ? WHERE doc_id=?'
  cmd SQL∆Exec[handle] head[7 1]
  cmd←'DELETE FROM doc_lines WHERE doc_id = ?'
  cmd SQL∆Exec[handle] head[1]
  cmd←'INSERT INTO doc_lines (doc_id,line_no,acct_no,debit,credit,company) VALUES (?,?,?,?,?,?)'
  cmd SQL∆Exec[handle] body,head[2]
∇

∇handle ctrgl_doc_post doc;cmd;head;body;id;rs
  ⍝ Function posts a document to the database
  head←1⊃doc ◊ body←2⊃doc
  utl∆es handle ctrgl_doc_post_checkHead head
  utl∆es ¨ handle ctrgl_doc_post_checkBody head body
  head[1] ← handle ctrgl_check_doc head[2 3 4 7]
  head[6]←⊂ctrgl_sql_escape_quotes 6⊃head
  SQL∆Begin handle
  →(head[1]≠0)/replace
insert:
  ⍝'SQL∆Rollback handle ◊ ⍞←''Database  update failed.'''  ⎕ea '
  handle ctrgl_doc_insert head body
  →cm
replace:
  ⍝'SQL∆Rollback handle ◊ ⍞←''Database  update failed.'''  ⎕ea '
  handle ctrgl_doc_replace head body
  →cm
cm:
  SQL∆Commit handle
  →0
∇

∇msg←handle ctrgl_doc_show_editchecks doc;head;body
  ⍝ Function checks the document for errors.
  head←1⊃doc ◊ body←2⊃doc
  msg←''
  →(0≠1↑⍴msg←handle ctrgl_doc_post_checkHead head)/0
  msg←handle ctrgl_doc_post_checkBody head body
∇

∇rpt←handle ctrgl_doc_show doc
  ⍝ Function to display an document in general journal form
  utl∆es handle ctrgl_doc_show_editchecks doc
  rpt←wp∆txt∆assemble handle ctrgl_doc_workpaper doc
∇

⍝ ********************************************************************
⍝ Begining balance functions
⍝ ********************************************************************

∇bb←ctrgl_bb_config handle;cmd;rs;i
  ⍝ Function returns information about beging balance entries from the
  ⍝ config table.
  cmd←'SELECT trim(name),value from config where name like ''begin%'' order by name'
  rs←cmd SQL∆Select[handle] ''
  bb←lex∆from_alist ,rs
∇

∇date←handle ctrgl_bb_date arg;co;pd;cmd
  ⍝ Function returns the date of a begining balance entry.
  (co pd)←arg
  cmd←'SELECT begin_date from periods where company = ? and period = ?'
  date←,⊃cmd SQL∆Select[handle] co pd
∇


∇doc←handle ctrgl_bb_doc arg;co;pd;pv;cmd;blex;tb;dt;re_bal
  ⍝ Function returns the begining balalnce entry for a period.
  (co pd)←arg
  pv←handle ctrgl_period_prev co pd
  blex←ctrgl_bb_config handle
  dt←handle ctrgl_bb_date co pd
  tb←handle ctrgl_sql_tb co pv
  doc←ctrgl_doc_init (⊂co),(⊂blex lex∆lookup 'begin_journal'),(⊂blex lex∆lookup 'begin_document'),(⊂dt),(⊂blex lex∆lookup 'begin_desc'),⊂pd
  →(handle ctrgl_period_yep co pv)/bs_only
full_tb:
  doc[2]←⊂0,(⍳1↑⍴tb),tb[;1 3 4]
  →0
bs_only:
  tb←(∊'i' ≠ ¨ tb[;5])⌿tb
  re_bal←-/+⌿(∊'b'=¨tb[;5])⌿tb[;3 4]
  →(re_bal<0)/deficit
  tb[(∊'r'=¨tb[;5])/⍳1↑⍴tb;3 4]←0 re_bal
  →end
deficit:
  tb[(∊'r'=¨tb[;5])/⍳1↑⍴tb;3 4]←(-re_bal),0
  →end
end:
  doc[2]←⊂0,(⍳1↑⍴tb),tb[;1 3 4]
∇  

⍝ ********************************************************************
⍝ Accounts
⍝ ********************************************************************
∇ balance←handle ctrgl_acct_balance args;co;pd;acct;cmd
  ⍝ Function returns the posted balance of an account where debits are
  ⍝ positive and credits negative.  The right argument is company,
  ⍝ period, and account number.
  cmd←'select dr - cr from tb where co = ? and period = ? and acct = ?'
  balance←1⊃,cmd SQL∆Select[handle] args
∇

∇ balance←handle ctrgl_acct_begin args;cmd
  ⍝ Function returns the posted beginingf balance of an account where
  ⍝ debits are positive and credits negative.  The right argument is
  ⍝ company, period and account number.
  cmd←'select debit - credit from begining_trans where company = ? and period = ? and acct_no = ?'
  balance←1⊃,cmd SQL∆Select[handle] args
∇


⍝ ********************************************************************
⍝ Checkbooks
⍝ ********************************************************************
∇ hd←handle ctrgl_chk_heads args;company;period;jrnl;cmd
  ⍝ Function returns a vector of document headings. The right argument
  ⍝ is an array of company code, period, and journal.
  company←1⊃args ◊ period←2⊃args ◊ jrnl←3⊃args
  cmd←'SELECT doc_id, trim(company), trim(journal), trim(name), doc_date, description, period,''p'' FROM document WHERE company = ? and period = ? and journal = ?'
  hd←cmd SQL∆Select[handle] company period jrnl
∇

∇ bd←handle ctrgl_chk_bodies doc_ids;cmd
  ⍝ Function returns a vector of document bodies.  The right argument
  ⍝ is a vector of doc_ids.
  cmd←'SELECT doc_id, line_no, trim(acct_no), debit, credit from doc_lines WHERE doc_id = ? order by line_no'
  bd←{cmd SQL∆Select[handle] ⍵}¨ doc_ids
∇

∇rs←chkbook ctrgl_chk_name lnno;data
  ⍝ Function returns the document name for the given line number
  data←wp∆getData chkbook
  utl∆es (~utl∆integerp lnno)/(⍕lnno),' is not an integer.'
  utl∆es (lnno > 1↑⍴data)/(⍕lnno),' is greater than the number of lines in this checkbook.'
  rs←data[lnno;3]
∇

∇ attr←handle ctrgl_chk_attr data;shape;bfmt;afmt;cmd;dx;bcols;acols
  ⍝ Function assembles an array of attributes for the checkbook
  cmd←'SELECT value from config where name = ''balanceFormat'''
  bfmt←1⊃,cmd SQL∆Select[handle] ''
  cmd←'SELECT value from config where name = ''accountFormat'''
  afmt←1⊃,cmd SQL∆Select[handle] ''
  attr←(shape←⍴data)⍴⊂lex∆init
  acols←7+2×⍳.5×shape[2]-8
  bcols←5 6 7,1+acols
  attr[dx←1↓⍳shape[1];bcols]←⊂((lex∆init) lex∆assign 'format' bfmt)lex∆assign 'class' 'number'
  attr[dx;acols]←⊂((lex∆init) lex∆assign 'format' afmt)lex∆assign 'class' 'number'
∇

∇chk_book←handle ctrgl_checkbook args;company;period;jrnl;acct_no;hd;bd;data;coname;width
  ⍝ Function returns a checkbook, or rather check workpaper. The right
  ⍝ argument is a vector of company code, period, account, and journal
  ⍝ number.  The workpaper lexicon (see workspace wp) has additional
  ⍝ keys company, period, journal, and acct_no.
  company←1⊃args ◊ period←2⊃args ◊ acct_no ← 3⊃ args ◊ jrnl←4⊃args 
  chk_book ← cth ctrgl_checkbook_init company period acct_no jrnl 
  hd←handle ctrgl_chk_heads company period jrnl
  bd←handle ctrgl_chk_bodies hd[;1]
  data←acct_no ctrgl_checkbook_data handle ctrgl_doc_list hd bd
  data←((width←(¯1↑⍴data))↑handle ctrgl_checkbook_begin company period acct_no),[1]data
  data[;7]←+\-/data[;5 6]
  data←(width↑ctrgl_chk_cols),[1]data
  chk_book←chk_book wp∆setData data
  chk_book←chk_book wp∆setAttributes handle ctrgl_chk_attr data
  chk_book←chk_book wp∆setStylesheet wp∆defaultSS
∇

∇ chk_book←old ctrgl_checkbook_convert_wp args;company;period;acct_no;jrnl
  ⍝ Function converts a work paper to a checkbook The right argument is
  ⍝ a vector of company, period, account number, and jrnl.
  company ← 1⊃args ◊ period ← 2⊃args ◊ acct_no ← 3⊃args ◊ jrnl ← 4⊃args
  chk_book ← old lex∆assign 'company' company
  chk_book ← chk_book lex∆assign 'period' period
  chk_book ← chk_book lex∆assign 'acct_no' acct_no
  chk_book ← chk_book lex∆assign 'journal' jrnl
∇

∇chk_book←cth ctrgl_checkbook_init args;company;period;jrnl;acct_no;coname;dat;shape
  ⍝ Function returns a new check book instance.  The right argument is
  ⍝ a vector of company, period, account number, and jrnl.
  company ← 1⊃ args ◊ period ← 2⊃ args ◊ acct_no←3⊃args ◊ jrnl←4⊃args
  chk_book ← wp∆init 'ChkBook',acct_no
  chk_book ← chk_book ctrgl_checkbook_convert_wp args
  dat←(shape←¯2↑1 1,⍴ctrgl_chk_cols)⍴ctrgl_chk_cols
  dat←dat,[1]shape[2]↑cth ctrgl_checkbook_begin company period acct_no
  chk_book ← chk_book wp∆setData dat
  coname←cth ctrgl_companyName company
  chk_book←chk_book wp∆setHeading coname 'Checkbook' period
  chk_book←chk_book wp∆setAuthor 'Cotgrugli'
∇

∇ln←handle ctrgl_checkbook_begin args;co;pd;acct;cmd;name
  ⍝ Function returns a check book line with the begining balance. The
  ⍝ right argument is company, period, and acct number.
  cmd ← 'SELECT value FROM config WHERE name = ''begin_document'''
  args←args,,cmd SQL∆Select[handle] ''
  cmd ← 'SELECT doc_date, doc, description, debit, credit, ''p'' FROM acct_detail '
  cmd ← cmd,' WHERE company = ? and period = ? and acct_no = ? and doc = ?'
  utl∆es (0=⍴ln←,cmd SQL∆Select[handle] args)/'Begining balance not available.'
  ln←1 0 1 1 1 1 0 1\ln
∇  

∇data←acct_no ctrgl_checkbook_data doc_list;widths;max
  ⍝ Function creates a checkbook array from a list of documents
  max←∊⌈/widths←⍴¨data←(⊂acct_no) ctrgl_checkbook_line ¨ doc_list
  data←⊃{max↑⍵}¨data
∇

∇ ln←acct_no ctrgl_checkbook_line chk;head;body;cash_line;dist_lines;bv
  ⍝ Function returns a checkbook line from a check document.
  head←1⊃chk ◊ body←2⊃chk 
  cash_line←,(bv←(⊂acct_no) utl∆stringEquals ¨ body[;3])⌿body
  dist_lines←(~bv)⌿body
  ln←head[5],head[1],head[4],head[6],cash_line[4],cash_line[5],0,head[8]
  ln←ln,,dist_lines[;3],[1.1]-/dist_lines[;4 5]
∇

∇ data←old ctrgl_checkbook_add line;ix
  ⍝ Function adds a line to the check book.  A line consists of date, 
  ⍝ name, description, debit to cash, credit to cash, and at least one
  ⍝ pair of acct number, debit or (credit) amount.                    
  line←(¯1↑⍴old)↑(1 0 1 1 1 1 0 0,(¯5+⍴line)⍴1)\line                  
  data←old,[1]line
  ix←1↓⍳1↑⍴data
  data[ix;7]←+\-/data[ix;5 6]
∇

∇ b←handle ctrgl_check_ln_proof args;co;ln;dist;cr
  ⍝ Function confirms that a checkbook line is correct.
  co←1⊃args ◊ ln←2⊃args
  dist←8↓ln
  dist←(0 2 + .5 0 × ⍴ dist)⍴dist
  b ← ∊ {handle ctrgl_check_account co ⍵}¨(utl∆numberp ¨ dist[;2])/dist[;1]
  cr←-/ln[6 5]
  b←b ∧ cr = +/dist[;2]
∇

∇rs←handle ctrgl_checkbook_proof cb;dist;dat;bv;cr;dr;co;shape;pd_args;ac_args;col_ix
⍝ Function proves that the debits equal the credits in this
⍝ checkbook.
utl∆es (~handle ctrgl_check_company cb lex∆lookup 'company')/'The company is not properly defined'
ac_args←{cb lex∆lookup ⍵}¨ 'company' 'acct_no'
utl∆es (~handle ctrgl_check_account ac_args)/'The account is not properly defined.'
pd_args←{cb lex∆lookup ⍵}¨ 'company' 'period'
utl∆es (~handle ctrgl_check_period pd_args)/'The period is not properly defined'
utl∆es (~handle ctrgl_check_journal cb lex∆lookup 'journal')/'The journal is not properly defined'
dat←wp∆getData cb
co←cb lex∆lookup 'company'
col_ix←7+2×⍳.5×¯8+¯1↑⍴dat
dist←dat[ix←2↓⍳1↑⍴dat;col_ix]	⍝ Line 1 col heads; line 2 begining balance
shape←⍴dist
bv←,⊃{handle ctrgl_check_account  co ⍵}¨,dist
dr←+/shape⍴bv\bv/,dat[ix;1+col_ix]
cr←-/ dat[ix;6 5]
rs←dr=cr
∇

∇ch ctrgl_checkbook_post chk;shape;lb;i;je
  ⍝ Function post all the transactions in a checkbook.
  shape←⍴wp∆getData chk
  lb←(shape[1]⍴st),ed
  i←3				⍝ Line 1 is column heads; 2 is begining balance
st:
  ch ctrgl_doc_post chk ctrgl_checkbook_je i
  →lb[i←i+1]
ed:
∇

∇doc←cb ctrgl_checkbook_je ix;ln;co;pd;jr;acct;dt;nm;desc;dist;ct;sink
  ⍝ Function to prepare a document (in general journal form) from a row
  ⍝ in a check book. Left argument hd is a lexicon of company, period,
  ⍝ journal, and checkbook account number. The right is the target line.
  co←cb lex∆lookup 'company' ◊ pd←cb lex∆lookup 'period'
  jr←cb lex∆lookup 'journal' ◊ acct←cb lex∆lookup 'acct_no'
  ln←(cb lex∆lookup 'Data')[ix;]
  dt←1⊃ln ◊ nm←3⊃ln ◊ desc←4⊃ln
  doc←ctrgl_doc_init co jr nm dt desc pd
  dist←((+/utl∆numberp ¨ dist),2)⍴dist←8↓ln
  dist←0,(⍳1↑⍴dist),dist[;1],0⌈dist[;2]∘.×1 ¯1
  dist←dist,[1]0,(1+⌈/dist[;2]),(⊂acct),0⌈1 ¯1×+/-/dist[;5 4]
  sink←{doc←doc ctrgl_doc_newLine ⍵}¨⊂[2]dist
∇
⍝ ********************************************************************
⍝ Display functions
⍝ ********************************************************************

∇wp←handle ctrgl_display_journal args;co;pd;jr;names;cmd
  ⍝ Function to display all the entries on a journal. Right argument
  ⍝ is company, period, and journal.
  co←1⊃args ◊ pd←2⊃args ◊ jr←3⊃args
  cmd←'SELECT name FROM document WHERE company = ? AND period = ? and journal = ?'
  names←cmd SQL∆Select[handle] co pd jr
  wp←{handle ctrgl_sql_doc co pd jr ⍵}¨,names
  wp←⎕tc[3] utl∆join cth ctrgl_doc_show ¨ wp
∇

∇names←handle ctrgl_display_jrnl_names args;co;pd;jr;cmd
  ⍝ Function returns a list of document names from a journal. Right
  ⍝ argument is  company, period, and journal.
  co←1⊃args ◊ pd←2⊃args ◊ jr←3⊃args
  cmd←'SELECT name FROM document WHERE company = ? AND period = ? and journal = ? order by name'
  names←cmd SQL∆Select[handle] co pd jr
∇

⍝ ********************************************************************
⍝ Other stuff
⍝ ********************************************************************

∇ss←ctrgl_default_css;r1;r2;r3;r4;r5;r6;r7;r8
  ⍝ Function returns the default stylesheet
  ss←wp∆ss∆init
  r1←wp∆ssc∆init 'body'
  r1←r1 wp∆ssc∆assignProp 'font' '12pt sans-serif'
  r1←r1 wp∆ssc∆assignProp 'text-align' 'left'
  r1←r1 wp∆ssc∆assignProp 'border' 'none 2pt black'
  ss←ss wp∆ss∆assignClass r1
  ⍝ ********************************************************************
  r2←wp∆ssc∆init 'colhead'
  r2←r2 wp∆ssc∆assignProp 'text-align' 'center'
  r2←r2 wp∆ssc∆assignProp 'font-size' '8pt'
  ss←ss wp∆ss∆assignClass r2
  ⍝ ********************************************************************
  r3←wp∆ssc∆init 'number'
  r3←r3 wp∆ssc∆assignProp 'text-align' 'right'
  ss←ss wp∆ss∆assignClass r3
  ⍝ ********************************************************************
  r4←wp∆ssc∆init 'page-head'
  r4←r4 wp∆ssc∆assignProp 'font-size' 'large'
  r4←r4 wp∆ssc∆assignProp 'font-weight' 'bold'
  r4←r4 wp∆ssc∆assignProp 'text-align' 'center'
  r4←r4 wp∆ssc∆assignProp 'width' '90%'
  ss←ss wp∆ss∆assignClass r4
  ⍝ ********************************************************************
  r5←wp∆ssc∆init 'initial-block'
  r5←r5 wp∆ssc∆assignProp 'font-size' 'small'
  r5←r5 wp∆ssc∆assignProp 'border' 'solid 1pt black'
  r5←r5 wp∆ssc∆assignProp 'text-align' 'right'
  r5←r5 wp∆ssc∆assignProp 'width' '10%'
  ss←ss wp∆ss∆assignClass r5
  ⍝ ********************************************************************
  r6←wp∆ssc∆init 'last-head'
  r6←r6 wp∆ssc∆assignProp 'font-size' 'large'
  r6←r6 wp∆ssc∆assignProp 'font-weight' 'bold'
  r6←r6 wp∆ssc∆assignProp 'height' '36pt'
  r6←r6 wp∆ssc∆assignProp 'vertical-align' 'top'
  ss←ss wp∆ss∆assignClass r6
  ⍝ ********************************************************************
  r7←wp∆ssc∆init 'subtotal'
  r7←r7 wp∆ssc∆assignProp 'text-align' 'right'
  r7←r7 wp∆ssc∆assignProp 'border-top' 'solid 1px black'
  r7←r7 wp∆ssc∆assignProp 'padding-bottom' '2em'
  ss←ss wp∆ss∆assignClass r7
  ⍝ ********************************************************************
  r8←wp∆ssc∆init 'grandtotal'
  r8←r8 wp∆ssc∆assignProp 'text-align' 'right'
  r8←r8 wp∆ssc∆assignProp 'border-bottom' 'double 1px black'
  r8←r8 wp∆ssc∆assignProp 'border-top' 'solid 1px black'
  ss←ss wp∆ss∆assignClass r8
∇

∇ coname←handle ctrgl_companyName company;cmd
  ⍝ Function returns the company name from the database.
  cmd←'SELECT coname FROM company WHERE company = ?'
  coname←1⊃,cmd SQL∆Select[handle] ⊂company
∇

∇Z←ctrgl⍙metadata
  Z←0 2⍴⍬
  Z←Z⍪'Author'          'Bill Daly'
  Z←Z⍪'BugEmail'        'bugs@dalywebandedit.com'
  Z←Z⍪'Documentation'   'Info file in source code'
  Z←Z⍪'Download'        'https://sourceforge.net/projects/cotrugli/'
  Z←Z⍪'License'         'GPL v3'
  Z←Z⍪'Portability'     ''
  Z←Z⍪'Provides'        'Cotrugli application'
  Z←Z⍪'Requires'        'APL Library'
  Z←Z⍪'Version'         '0 0 1'
∇

ctrgl_chk_cols←'Date' 'Document' 'Name' 'Description' 'Debit' 'Credit' 'Balance' 'Posted' 'Distr.' 'Dr <Cr>'
