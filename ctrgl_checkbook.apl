#! /usr/local/bin/apl --script
⍝ ********************************************************************
⍝ ctrgl_checkbook.apl Functions to manipulate, save and display
⍝ checkbooks. 
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

ctrgl_chk_cols←'Date' 'Document' 'Name' 'Description' 'Debit' 'Credit' 'Balance' 'Posted' 'Distr.' 'Dr <Cr>'

∇ coname←handle ctrgl_companyName company;cmd
  ⍝ Function returns the company name from the database.
  cmd←'SELECT coname FROM company WHERE company = ?'
  coname←1⊃,cmd SQL∆Select[handle] ⊂company
∇

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

∇list←handle ctrgl_chk_list args;hd;bd
  ⍝ Function creates a list of documents from a list of document
  ⍝ headings and a list of document bodies.  The right argment is
  ⍝ headings bodies.
  hd←⊂[2]1⊃args ◊ bd←2⊃args
  list←hd{(⊂⍺),⊂⍵}¨bd
∇

∇chk_book←handle ctrgl_checkbook args;company;period;jrnl;acct_no;hd;bd;data;coname;width
  ⍝ Function returns a checkbook, or rather check workpaper. The right
  ⍝ argument is a vector of company code, period, journal, and accout
  ⍝ number.  The workpaper lexicon (see workspace wp) has additional
  ⍝ keys company, period, journal, and acct_no.
  company←1⊃args ◊ period←2⊃args ◊ jrnl←3⊃args ◊ acct_no ← 4⊃ args
  chk_book ← ctrgl_checkbook_init company period jrnl acct_no
  hd←handle ctrgl_chk_heads company period jrnl
  bd←handle ctrgl_chk_bodies hd[;1]
  data←acct_no ctrgl_checkbook_data handle ctrgl_chk_list hd bd
  data←((width←(¯1↑⍴data))↑handle ctrgl_checkbook_begin company period acct_no),[1]data
  data[;7]←+\-/data[;5 6]
  data←(width↑ctrgl_chk_cols),[1]data
  chk_book←chk_book wp∆setData data
  coname←handle ctrgl_companyName company
  chk_book←chk_book wp∆setHeading coname 'Checkbook' period
  chk_book←chk_book wp∆setAuthor 'Cotgrugli'
  chk_book←chk_book wp∆setAttributes handle ctrgl_chk_attr data
  chk_book←chk_book wp∆setStylesheet wp∆defaultSS
∇

∇ attr←handle ctrgl_chk_attr data;shape;bfmt;afmt;cmd;dx
  ⍝ Function assembles an array of attributes for the checkbook
  cmd←'SELECT value from config where name = ''balanceFormat'''
  bfmt←1⊃,cmd SQL∆Select[handle] ''
  cmd←'SELECT value from config where name = ''accountFormat'''
  afmt←1⊃,cmd SQL∆Select[handle] ''
  attr←(shape←((1↑⍴data),⍴ctrgl_chk_cols))⍴⊂lex∆init
  attr[dx←1↓⍳shape[1];5 6 7 9]←⊂((lex∆init) lex∆assign 'format' bfmt)lex∆assign 'class' 'number'
  attr[dx;8]←⊂((lex∆init) lex∆assign 'format' afmt)lex∆assign 'class' 'number'
∇

∇chk_book←cth ctrgl_checkbook_init args;company;period;jrnl;acct_no
  ⍝ Function returns a new check book instance.  The right argument is
  ⍝ a vector of company, period, account number, and jrnl.
  company ← 1⊃ args ◊ period ← 2⊃ args ◊ acct_no←3⊃args ◊ jrnl←4⊃args
  chk_book ← wp∆init 'ChkBook',acct_no
  chk_book ← chk_book lex∆assign 'company' company
  chk_book ← chk_book lex∆assign 'period' period
  chk_book ← chk_book lex∆assign 'acct_no' acct_no
  chk_book ← chk_book lex∆assign 'journal' jrnl
  chk_book ← chk_book wp∆setData (¯2↑1 1,⍴ctrgl_chk_cols)⍴ctrgl_chk_cols
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

∇doc←cb ctrgl_chk_je ix;ln;co;pd;jr;acct;dt;nm;desc;dist;ct;sink
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


∇rs←chkbook ctrgl_chk_name lnno;data
  ⍝ Function returns the document name for the given line number
  data←wp∆getData chkbook
  utl∆es (~utl∆integerp lnno)/(⍕lnno),' is not an integer.'
  utl∆es (lnno > 1↑⍴data)/(⍕lnno),' is greater than the number of lines in this checkbook.'
  rs←data[lnno;3]
∇

∇ch ctrgl_chk_post chk;shape;lb;i;je
  ⍝ Function post all the transactions in a checkbook.
  shape←⍴wp∆getData chk
  lb←(shape[1]⍴st),ed
  i←3				⍝ Line 1 is column heads; 2 is begining balance
st:
  ch ctrgl_doc_post chk ctrgl_chk_je i
  →lb[i←i+1]
ed:
  ∇
