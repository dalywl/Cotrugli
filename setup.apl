#! /usr/local/bin/apl --script
⍝ ********************************************************************
⍝ ctrgl_setup.apl Functions to set up a test environment for Cotrugli
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
⍝ Setup config table.
cth ctrgl_config_post 'accountFormat' '0000'
cth ctrgl_config_post 'balanceFormat' '555,555,510'
cth ctrgl_config_post 'begin_desc'     'Begining trial balance.'
cth ctrgl_config_post 'begin_document' 'BEG_BAL'
cth ctrgl_config_post 'begin_journal' 'gj'


cth ctrgl_company_post 'ex' 'Example Co. LLC'
cth ctrgl_jrnl_post 'gj' 'General Journal'
cth ctrgl_jrnl_post 'ck' 'Check Book'
cth ctrgl_period_post 'ex' '2021-01' '01/01/2021' '03/31/2021' 0
cth ctrgl_period_post 'ex' '2021-02' '04/01/2021' '06/30/2021' 0
cth ctrgl_period_post 'ex' '2021-03' '07/01/2021' '09/30/2021' 0
cth ctrgl_period_post 'ex' '2021-04' '10/01/2021' '12/31/2021' 1


cth ctrgl_chart_post 'ex' '3100' 'Common Stock' 'b' 'c'
cth ctrgl_chart_post 'ex' '1010' 'Cash' 'b' 'd'
cth ctrgl_chart_post 'ex' '1110' 'Accounts Receivable' 'b' 'd'
cth ctrgl_chart_post 'ex' '1310' 'Inventory' 'b' 'd'
cth ctrgl_chart_post 'ex' '1320' 'Labor in inventory' 'b' 'd'
cth ctrgl_chart_post 'ex' '1390' 'Overhead in inventory' 'b' 'd'
cth ctrgl_chart_post 'ex' '1410' 'Prepaid expense' 'b' 'd'
cth ctrgl_chart_post 'ex' '1510' 'Plant' 'b' 'd'
cth ctrgl_chart_post 'ex' '1520' 'Equipment' 'b' 'd'
cth ctrgl_chart_post 'ex' '1590' 'Accumulated Depreciation' 'b' 'd'
cth ctrgl_chart_post 'ex' '2010' 'Current notes payable' 'b' 'c'
cth ctrgl_chart_post 'ex' '2110' 'Accounts payable' 'b' 'c'
cth ctrgl_chart_post 'ex' '2310' 'Accrued expense' 'b' 'c'
cth ctrgl_chart_post 'ex' '2710' 'Long-term debt' 'b' 'c'
cth ctrgl_chart_post 'ex' '5010' 'Sales' 'i' 'c'
cth ctrgl_chart_post 'ex' '6010' 'Material cost of sales' 'i' 'd'
cth ctrgl_chart_post 'ex' '6110' 'Labor cost of sales' 'i' 'd'
cth ctrgl_chart_post 'ex' '6910' 'Overhead cost of sales' 'i' 'd'
cth ctrgl_chart_post 'ex' '7010' 'Salaries and wages' 'i' 'd'
cth ctrgl_chart_post 'ex' '7020' 'Payroll taxes' 'i' 'd'
cth ctrgl_chart_post 'ex' '7030' 'Health insurance' 'i' 'd'
cth ctrgl_chart_post 'ex' '7110' 'Janitorial supplies' 'i' 'd'
cth ctrgl_chart_post 'ex' '7120' 'Building repairs and maintenance' 'i' 'd'
cth ctrgl_chart_post 'ex' '7150' 'Utilities' 'i' 'd'
cth ctrgl_chart_post 'ex' '7210' 'Professional fees' 'i' 'd'
cth ctrgl_chart_post 'ex' '7510' 'Insurance' 'i' 'd'
cth ctrgl_chart_post 'ex' '7610' 'Interest' 'i' 'd'
cth ctrgl_chart_post 'ex' '8910' 'Federal income taxes' 'i' 'd'
cth ctrgl_chart_post 'ex' '8920' 'State income taxes' 'i' 'd'
cth ctrgl_chart_post 'ex' '3990' 'Retained Earnings' 'r' 'c'

⍝ Begining balances
begin ← ctrgl_doc_init 'ex' 'gj' 'begin' '1/1/2021' 'To record opening balances' '2021-01'

begin←begin ctrgl_doc_debit 1010 45000

begin←begin ctrgl_doc_debit 1410 2500

begin←begin ctrgl_doc_debit 1510 1300000

begin←begin ctrgl_doc_debit 1520 755000

begin←begin ctrgl_doc_credit 1590 140400

begin←begin ctrgl_doc_credit 2110 41750

begin←begin ctrgl_doc_credit 2710 1644000

begin←begin ctrgl_doc_credit 3100 1000

begin←begin ctrgl_doc_credit 3990 275350

⍞←cth ctrgl_doc_show begin
cth ctrgl_doc_post begin

