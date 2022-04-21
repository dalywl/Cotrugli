#! /usr/local/bin/apl --script
⍝ ********************************************************************
⍝ ctrgl_santander_import.apl Workspace to import transactions from
⍝ Santander.
⍝ Copyright (C) <year> <name of author>

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

)copy 1 utl
)copy 1 utf8
)copy 1 date
)copy 1 seq
)copy 1 import

∇rs←ctrgl∆bifurcate∆transactions tr;ix
  ⍝ Function returns the two sections of a Santander file. Section one
  ⍝ is a reconciliation of the begining and ending balance. Section
  ⍝ two is the transactions posted during the period.
  rs←ctrgl_peel_off tr
∇

∇ rs←ctrgl∆import∆transactions fname
  ⍝ Function reads a Santander transfer file and returns an array of
  ⍝ lines in that file.
  rs←⎕tc[3] utl∆split utf8∆read fname
∇

∇rs←jrnl ctrgl∆parse∆transaction tr;name;dr;cr;amt
  ⍝ Function returns the document line.
  ⍝ 1) Date,2) ABA Num,3) Currency,4) Account Num,5) Account Name,
  ⍝ 6) Description,7) BAI Code,8) Amount,9) Serial Num,10) Ref Num
  doc_id←⊂⍬
  name←jrnl ctrgl∆tr∆name 10⊃tr
  amt←utl∆import∆numbers tr[8]
  dr←0⌈amt
  cr←-0⌊amt
  rs←tr[1],doc_id,(⊂name),tr[6],dr,cr
∇

∇ name←jrnl ctrgl∆tr∆name ref
  ⍝ Function returns the transaction name.
  →(utl∆numberis ref)/Check
  name←seq∆posting∆ref jrnl
  →0
Check:
  name←'chk','000000'⍕utl∆import∆numbers ref
  →0
∇

∇rs←ctrgl_peel_off dat;b1;b2
  ⍝ Function peels off subarrays from dat where a blank line delimits
  ⍝ the subarrays.
  b1←∊0≠⍴¨dat
  b2←⍲\b1
  dat←b2/dat
  b1←b2/b1
  →(1=+/~b2←∧\b1)/end
  rs←(⊂b2/dat),ctrgl_peel_off (~b2)/dat
  →0
end:
  rs←⊂b2/dat
  →0
∇

∇rs←ctrgl∆import∆file fname
  ⍝ Function reads a delimited file and returns an array.
  rs←ctrgl∆bifurcate∆transactions ⎕av[11] utl∆split utf8∆read fname
  
  rs←⊃{'ck' ctrgl∆parse∆transaction ',' utl∆split_with_quotes ⍵ } ¨ 1↓2⊃rs
  rs←ctrgl_chk_cols,[1]⊖((1↑⍴rs),⍴ctrgl_chk_cols)↑rs
∇

∇ cbwp←cth ctrgl∆checkbook_wp args;tr;data;shape;ix
⍝ Function returns a checkbook from parsed, santander
⍝ transactions. Args are company, period, journal, acct_no,
  ⍝ transactions
  data←5⊃args
  shape←(1↑⍴data),⍴ctrgl_chk_cols
  data←shape↑data
  data←(shape[2]↑cth ctrgl_checkbook_begin args[1 2 4]),[1]data
  data[;7]←+\-/data[;5 6]
  data←ctrgl_chk_cols,[1]data
  cbwp←cth ctrgl_checkbook_init ¯1↓args
  cbwp←cbwp wp∆setData data
  cbwp←cbwp wp∆setAttributes cth ctrgl_chk_attr data
∇
  
