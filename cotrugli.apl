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

)copy 5 SQL
)copy 1 wp
)copy 1 date

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
  cmd←'SELECT jrnl, title FROM journal order by jrnl'
  data←cmd SQL∆Select[handle] ''
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
  wp←wp wp∆setData 'code' 'Name',[1] ctrgl_sql_journals handle
  wp←wp wp∆setStylesheet ctrgl_default_css
  wp←wp wp∆setAuthor 'cotrugli'
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
  
∇last←handle ctrgl_period_prev args;co;pd;cmd;rs;begin
  ⍝ Function returns the previous period for the company, period
  ⍝ provided. The right argument is the company and period
  (co pd)←args
  cmd←'SELECT begin_date FROM periods WHERE company = ? and period = ?'
  rs←,⊃cmd SQL∆Select[handle] co pd
  begin←¯1 + date∆lillian date∆US date∆parse rs
  begin←date∆US date∆fmt∆3numbers date∆unlillian begin
  cmd←'SELECT period FROM periods where company = ? and end_date = ?'
  last←,⊃cmd SQL∆Select[handle] co begin
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

∇handle ctrgl_jrnl_post args;code;name;cmd;rs
  ⍝ Function to create or update a journal. The right argument is a
  ⍝ nested vector of journal code and journal name.
  utl∆es ctrgl_jrnl_post_editCheck args
  code←1⊃args ◊ name←2⊃args
  ⍝ Test for insertion or replacement
  cmd←'select jrnl from journal where jrnl = ?'
  →(0≠1↑rs←cmd SQL∆Select[handle] ⊂code)/replace
insert:
  cmd←'INSERT INTO journal (jrnl,title) VALUES (?,?)'
  rs←cmd SQL∆Exec[handle] code name
  →0
replace:
  cmd←'UPDATE journal set title to ? WHERE jrnl = ?'
  rs←cmd SQL∆Exec[handle] name code
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
  doc←(⊂head),⊂(lines[;3]≠acct)⌿lines
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
  head[6]←ctrgl_sql_escape_quotes head[6]
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

