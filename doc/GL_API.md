COTRUGLI GENERAL LEDGER API
===========================

Cotrugli is an apl workspace for keeping accounting records. A
simplified application program interface (API) allows an informed user
to keep his books just through that interface.

Cotrugli keeps its data in a PostgreSQL database.  The first step in
the API is to make a connection to postgres and store a handle that
the other parts of of API use. A sample session might look like this:

```
      handle←ctrgl_sql_connect 'localhost' 'user1' 'cotrugli_data' 'password'
	  ⍞←wp∆txt∆assemble ctrgl_open_chart 'company1'
```
See section **SQL** for more information.

The API has two types of functions: Reports and maintenance.
Information is entered through the maintenance functions and then
reports are run.

Maintenance
==========

Cotrugli maintains five tables:

  * Configuration
  * Company
  * Journal
  * Period
  * Documents
  
Configuration
-------------

The configuration table is a list of name -- value pairs the effect
how cotrugli works. Try

```      ⍞←wp∆txt∆assemble ctrgl_open_config sql_handle```

Each of these items may be changed by ctrgl_config_post:

```      sql_handle ctrgl_config_post 'name' 'value'```

Company
-------

Cotrugli will keep records for multiple companies. Each company is
independent in that the period and document tables are separate for
each company.

Try:

```      ⍞←wp∆txt∆assemble ctrgl_open_company sql_handle```

The company is a code that will be required in much of the API while
the name will be used in preparing reports

use `ctrgl_company_post` to add or change company information. viz.:

```      sql_handle ctrgl_company_post 'Newco' 'New Company, Inc.'

Journal
-------

In a hand posted accounting system different books were used to
record different transaction cycles so there might be a cash receipts
book, a cash disbursements book and a sales book. The journal table is
built for that purpose.

Each document, where actual transactions are recorded, is assigned a
journal Use ctrgl_open_journals to see defined journals.

```      ctrgl_open_journals sql_handle```

Period
------

The period table defines accounting periods.  Reports are prepared for
a particular period and transactions with in the beginning and ending
dates will be included in a report for that period.  Periods are also
used to check the accuracy of a date.  No document can be prepared for
a period not in this table. 

Use `ctrgl_open_periods` to list defined periods:

```      sql_handle ctrgl_open_periods 'company'```

Use `ctrgl_period_post` to add or change period definition:

```      sql_handle ctrgl_period_post 'company' 'period' '1/1/20xx' '1/31/20xx'```

company is a code defined in the company table and period is a unique
identifying string.  In testing we used year -- count (20xx-01, 20xx-02)
which will force the order of periods in reports.

Chart of accounts
-----------------

A chart of accounts is a list of the categories that can be used to
accumulate the totals of transactions. Each company has a separate
chart of accounts.  Each account is defined with four data:

 1. Account number
 2. Title
 3. account type (one of b, r, or i)
 4. sign type (one of d or c)
 
Account numbers are used to provide a logical order to the accounts
and title describe what should be included in an account.  

An account should be one of three types:

 1. Balance sheet or 'b'
 2. Income or 'i'
 3. Retained Earnings or 'r'
 
The basic accounting equation is Assets are equal to Liabilities plus
Equity and a Balance Sheet displays that requirement.  That is it
first lists and totals the assets, then lists and totals the
liabilities, then lists and totals the equity accounts and finally
totals liabilities and equity. 

Retained Earnings is a special equity account that is posted as the
final document of the year with the total of the income accounts.  The
income accounts are then reset to zero. 

The balance in each account is displayed as either a positive or
negative number based on where it falls in the basic accounting
equation.

Assets show positive balances when the debits exceed the credits.
Liabilities and Equity show positive balance when the credits exceed
the debits.

For income accounts revenue (which increases equity) shows a positive
credit balance, while expense (which decrease equity) show a positive
debit balance.

This leads us to the account's sign type. It is one of 'd' for debit
or 'c' for credit.

These two flags should therefore be set as follows 

<table><tr>
<tc>Accounting Equation </tc><tc> acct_type </tc><tc> sign_type </tc>
</tr>
<tc> --- </tc><tc> :-: </tc><tc> :-: </tc>
</tr>
<tc>Asset               </tc><tc> b         </tc><tc> d         </tc>
</tr>
<tc>Liability           </tc><tc> b         </tc><tc> c         </tc>
</tr>
<tc>Equity              </tc><tc> b         </tc><tc> c         </tc>
</tr>
<tc>Retained earnings   </tc><tc> r         </tc><tc> c         </tc>
</tr>
<tc>Revenue             </tc><tc> i         </tc><tc> c         </tc>
</tr>
<tc>Expense             </tc><tc> i         </tc><tc> d         </tc>
</tr>
</table>

Use `ctrgl_open_chart` to display the chart of accounts

```      sql_handle ctrgl_open_chart 'company'```

use `ctrgl_chart_post` to add or change an account:

```      sql_handle ctrgl_chart_post 'company' 'acct number' 'title' 'acct type' 'sign type'

'company' is a company code in the company table.  'acct number' is
the key to the chart.  Acct type and sign type are discussed above.

Document
--------

A document is the basic building block of cotrugli and should be used
to record each transaction (a check or an invoice for example) each
document consists of a header that has information about the
transaction and a body which records the financial effect of the
transaction. Cotrugli is a double entry accounting system.  That is
each document must contain at lease two lines and any amount is
identified as either a debit or a credit.  The total of the debit
lines must equal the total of the credit lines.

To illustrate the document entry process, first we'll record a check
paying the company's rent:

```      ch1001←ctrgl_doc_init 'company' 'journal' 'name' '1/2/20xx' 'Rapacious Landlord, Inc.' '20xx-01'```

We are creating a workspace variable name ch1001. Further down we'll
post the final transaction to the database. 

Here 'company' is the company code in the company table. 'journal' is
the journal code in the journal table. 'Rapacious Landlord, Inc.' is
the document description.

Use ctrgl_doc_debit or ctrgl_doc_credit to add lines to the document
body.

```
ch1001←ch1001 ctrgl_doc_debit '6080' 550.00
ch1001←ch1001 ctrgl_doc_credit '1010' 550.00
```
```
      ⍞← cth ctrgl_doc_show ch1001
                                      DWE                                    ck
                                    Check101                            cotrugli
                                Period 01/02/19                      06/25/2021

6080 Rent                            550           0
1010 First National Checking           0         550
     Total                           550         550
                            Repaciaous Landlord, Inc                            
```
