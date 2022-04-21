#! /usr/local/bin/apl --script
⍝ ********************************************************************
⍝ test_suite02.apl Workspace tests cotrugli by posting summary transactions
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

∇ ts_cash_receipts handle; cr
  ⍝ Function posts cash receipts
  cr←ctrgl_doc_init 'ex' 'ck' 'PD2021-01' '03/31/2021' 'To post cash receipts for 2021-01' '2021-01'
  cr←cr ctrgl_doc_debit 1010 130510
  cr←cr ctrgl_doc_credit 5010 130385
  cr←cr ctrgl_doc_credit 7510 125
  ⍞←handle ctrgl_doc_show cr
  handle ctrgl_doc_post cr
∇

∇ ts_cash_disbursements handle; cd
  ⍝ Function posts cash disbursements
  cd←ctrgl_doc_init 'ex' 'ck' 'PD2021-01' '03/31/2021' 'To post cash receipts for 2021-01' '2021-01'
  cd←cd ctrgl_doc_debit 6010 13210
  cd←cd ctrgl_doc_debit 6110 26320
  cd←cd ctrgl_doc_debit 6910 15432
  cd←cd ctrgl_doc_debit 7010 6833
  cd←cd ctrgl_doc_debit 7020 3300
  cd←cd ctrgl_doc_debit 7030 5500
  cd←cd ctrgl_doc_debit 7150 8644
  cd←cd ctrgl_doc_debit 7510 778
  cd←cd ctrgl_doc_debit 7610 46310
  cd←cd ctrgl_doc_debit 8910 3500
  cd←cd ctrgl_doc_credit 1010 129827
  ⍞←handle ctrgl_doc_show cd
  handle ctrgl_doc_post cd
∇


  
