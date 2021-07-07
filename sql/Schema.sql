-- ********************************************************************
--   $Id: $
-- $desc: Schema for Cotrugli $
-- ********************************************************************

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: accounts; Type: TABLE; Schema: public; Owner: dalyw; Tablespace: 
--

CREATE TABLE accounts (
    company character(20) NOT NULL,
    acct_no character(20) NOT NULL,
    title character varying(255) DEFAULT NULL::character varying,
    acct_type character(1) DEFAULT NULL::bpchar,
    sign_type character(1) DEFAULT NULL::bpchar,
    created date,
    last_update date
);


ALTER TABLE public.accounts OWNER TO dalyw;

--
-- Name: doc_lines; Type: TABLE; Schema: public; Owner: dalyw; Tablespace: 
--

CREATE TABLE doc_lines (
    doc_id integer NOT NULL,
    line_no integer,
    acct_no character(20) DEFAULT NULL::bpchar,
    debit numeric(14,2) DEFAULT NULL::numeric,
    credit numeric(14,2) DEFAULT NULL::numeric,
    company character(20) NOT NULL,
    created date,
    last_update date
);


ALTER TABLE public.doc_lines OWNER TO dalyw;

--
-- Name: document; Type: TABLE; Schema: public; Owner: dalyw; Tablespace: 
--

CREATE TABLE document (
    doc_id integer NOT NULL,
    company character(20) NOT NULL,
    journal character(20) NOT NULL,
    name character(50) NOT NULL,
    doc_date date NOT NULL,
    description character varying(4096) DEFAULT NULL::character varying,
    period character(10),
    created date,
    last_update date
);


ALTER TABLE public.document OWNER TO dalyw;

--
-- Name: docs; Type: VIEW; Schema: public; Owner: dalyw
--

CREATE VIEW docs AS
    SELECT btrim((document.company)::text) AS co, btrim((document.journal)::text) AS jrnl, btrim((document.name)::text) AS doc, document.doc_date, document.period, btrim((doc_lines.acct_no)::text) AS acct, document.description, doc_lines.debit, doc_lines.credit FROM (document JOIN doc_lines ON ((document.doc_id = doc_lines.doc_id)));


ALTER TABLE public.docs OWNER TO dalyw;

--
-- Name: acct_detail; Type: VIEW; Schema: public; Owner: dalyw
--

CREATE VIEW acct_detail AS
    SELECT accounts.company, accounts.acct_no, accounts.title, docs.doc, docs.doc_date, docs.period, docs.description, docs.debit, docs.credit FROM (accounts LEFT JOIN docs ON ((((accounts.company)::text = docs.co) AND ((accounts.acct_no)::text = docs.acct))));


ALTER TABLE public.acct_detail OWNER TO dalyw;

--
-- Name: acct_type; Type: TABLE; Schema: public; Owner: dalyw; Tablespace: 
--

CREATE TABLE acct_type (
    line integer,
    code character(1),
    short character(10),
    long character(255),
    created date,
    last_update date
);


ALTER TABLE public.acct_type OWNER TO dalyw;

--
-- Name: accts; Type: VIEW; Schema: public; Owner: dalyw
--

CREATE VIEW accts AS
    SELECT btrim((accounts.company)::text) AS co, btrim((accounts.acct_no)::text) AS acct, accounts.title, accounts.acct_type, accounts.sign_type FROM accounts ORDER BY accounts.acct_no;


ALTER TABLE public.accts OWNER TO dalyw;

--
-- Name: balance_type; Type: TABLE; Schema: public; Owner: dalyw; Tablespace: 
--

CREATE TABLE balance_type (
    line integer,
    code character(1),
    short character(10),
    long character(255)
);


ALTER TABLE public.balance_type OWNER TO dalyw;

--
-- Name: company; Type: TABLE; Schema: public; Owner: dalyw; Tablespace: 
--

CREATE TABLE company (
    company character(20) NOT NULL,
    coname character varying(50) DEFAULT NULL::character varying,
    addr character varying(4096) DEFAULT NULL::character varying,
    city character varying(50) DEFAULT NULL::character varying,
    state character varying(10) DEFAULT NULL::character varying,
    zip character varying(20) DEFAULT NULL::character varying,
    fein character varying(10) DEFAULT NULL::character varying,
    current_period character(10) DEFAULT NULL::bpchar,
    created date,
    last_update date
);


ALTER TABLE public.company OWNER TO dalyw;

--
-- Name: config; Type: TABLE; Schema: public; Owner: dalyw; Tablespace: 
--

CREATE TABLE config (
    name character(50) NOT NULL,
    value character varying(255) DEFAULT NULL::character varying,
    created date,
    last_update date
);


ALTER TABLE public.config OWNER TO dalyw;

--
-- Name: periods; Type: TABLE; Schema: public; Owner: dalyw; Tablespace: 
--

CREATE TABLE periods (
    company character(20) NOT NULL,
    period character(10) NOT NULL,
    begin_date date NOT NULL,
    end_date date NOT NULL,
    created date,
    last_update date
);


ALTER TABLE public.periods OWNER TO dalyw;

--
-- Name: current_period; Type: VIEW; Schema: public; Owner: dalyw
--

CREATE VIEW current_period AS
    SELECT company.company, company.coname, periods.end_date FROM (company JOIN periods ON (((company.company = periods.company) AND (company.current_period = periods.period))));


ALTER TABLE public.current_period OWNER TO dalyw;

--
-- Name: document_doc_id_seq; Type: SEQUENCE; Schema: public; Owner: dalyw
--

CREATE SEQUENCE document_doc_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.document_doc_id_seq OWNER TO dalyw;

--
-- Name: document_doc_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dalyw
--

ALTER SEQUENCE document_doc_id_seq OWNED BY document.doc_id;


--
-- Name: tb; Type: VIEW; Schema: public; Owner: dalyw
--

CREATE VIEW tb AS
    SELECT btrim((accounts.company)::text) AS co, btrim((accounts.acct_no)::text) AS acct, docs.period, sum(docs.debit) AS dr, sum(docs.credit) AS cr FROM (accounts LEFT JOIN docs ON ((((accounts.company)::text = docs.co) AND ((accounts.acct_no)::text = docs.acct)))) GROUP BY accounts.company, accounts.acct_no, docs.period;


ALTER TABLE public.tb OWNER TO dalyw;

--
-- Name: journal; Type: TABLE; Schema: public; Owner: dalyw; Tablespace: 
--

CREATE TABLE journal (
    jrnl character(10) NOT NULL,
    title character varying(255) DEFAULT NULL::character varying
);


ALTER TABLE public.journal OWNER TO dalyw;

--
-- Name: sign_type; Type: TABLE; Schema: public; Owner: dalyw; Tablespace: 
--

CREATE TABLE sign_type (
    line integer,
    code character(1),
    short character varying(10),
    long character varying(255)
);


ALTER TABLE public.sign_type OWNER TO dalyw;

--
-- Name: account(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: dalyw
--

CREATE FUNCTION account(c character varying, p character varying, a character varying) RETURNS TABLE(doc_date date, jrnl character varying, doc text, description character varying, debit numeric, credit numeric)
    LANGUAGE sql
    AS $_$
SELECT doc_date, jrnl, doc, description, debit, credit from DOCS
       WHERE co = $1 and period = $2 and acct = $3
       ORDER BY doc_date,doc;
$_$;


ALTER FUNCTION public.account(c character varying, p character varying, a character varying) OWNER TO dalyw;

--
-- Name: checkbook(character varying, character varying, character
-- varying); Type: FUNCTION; Schema: public; Owner: dalyw
-- Function returns a data set for the supplied company, period and account.
--

CREATE FUNCTION checkbook(c character varying, p character varying, a character varying) RETURNS TABLE(doc_date date, doc text, description character varying, debit numeric, credit numeric, tick character varying)
    LANGUAGE sql
    AS $_$
SELECT doc_date, doc, description, debit, credit, cast('p' as varchar) from DOCS
       WHERE co = $1 and period = $2 and acct = $3
       ORDER BY doc_date,doc;
$_$;


ALTER FUNCTION public.checkbook(c character varying, p character varying, a character varying) OWNER TO dalyw;

--
-- Name: entry(character varying, character varying, character
-- varying, character varying); Type: FUNCTION; Schema: public; Owner:
-- dalyw. Function returns a data set for the supplied company,
-- period, journal and entry name.
--

CREATE FUNCTION entry(c character varying, p character varying, j character varying, n character varying) RETURNS TABLE(doc_date date, description character varying, acct character varying, debit numeric, credit numeric)
    LANGUAGE sql
    AS $_$

SELECT doc_date, description, acct, debit, credit 
       FROM docs WHERE co = $1 and period = $2 and jrnl = $3 and doc = $4
       ORDER BY acct;

$_$;


ALTER FUNCTION public.entry(c character varying, p character varying, j character varying, n character varying) OWNER TO dalyw;

--
-- Name: find_begin_date(character, character); Type: FUNCTION;
-- Schema: public; Owner: dalyw
-- Function returns the begining date for the supplied company and period.
--

CREATE FUNCTION find_begin_date(co character, pd character) RETURNS date
    LANGUAGE plpgsql
    AS $$
BEGIN
	return (select begin_date from periods where
	company = co and period = pd);
END;
$$;


ALTER FUNCTION public.find_begin_date(co character, pd character) OWNER TO dalyw;

--
-- Name: find_config(character); Type: FUNCTION; Schema: public; Owner: dalyw
-- Function returns the value for the supplied name in the config table.
--

CREATE FUNCTION find_config(nm character) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
BEGIN
	return (select value from config where name = nm);
END;
$$;


ALTER FUNCTION public.find_config(nm character) OWNER TO dalyw;

--
-- Name: find_period(character, date); Type: FUNCTION; Schema: public; Owner: dalyw
-- Function returns the period which includes the supplied company and
-- date .
--

CREATE FUNCTION find_period(co character, dt date) RETURNS character
    LANGUAGE plpgsql
    AS $$
BEGIN
	return (select period from periods where
	company = co and begin_date <= dt and end_date >= dt);
END;
$$;


ALTER FUNCTION public.find_period(co character, dt date) OWNER TO dalyw;

--
-- Name: last_period(character, character); Type: FUNCTION; Schema:
-- public; Owner: dalyw
-- Function returns the last day of the supplied company's period.
--

CREATE FUNCTION last_period(co character, pd character) RETURNS character
    LANGUAGE plpgsql
    AS $$
declare 
	ed date;
begin
ed := max(end_date) from periods where end_date < 
(select begin_date from periods where company = co and  period = pd);
return period from periods where company = co and end_date = ed;
end;
$$;


ALTER FUNCTION public.last_period(co character, pd character) OWNER TO dalyw;

--
-- Name: post_field(character, character, character varying, character varying, text); Type: FUNCTION; Schema: public; Owner: dalyw
--

CREATE FUNCTION post_field(tl character, fd character, dc character varying, tp character varying, at text) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
	test_fld char(50);
begin

test_fld := field from html_fields where template = tl and field = fd;
if not(nullvalue(test_fld)) then
   update html_fields set
   	  description = dc,
	  type = tp,
	  attr = at
	  where template = tl and field = fd;
else
	insert into html_fields (template,field,description,type,attr)
	values
	(tl,fd,dc,tp,at);
end if;
end;
$$;


ALTER FUNCTION public.post_field(tl character, fd character, dc character varying, tp character varying, at text) OWNER TO dalyw;

--
-- Name: trial_balance(character varying, character varying); Type:
-- FUNCTION; Schema: public; Owner: dalyw
-- Fuinction returns the trial balance data set for the supplied
-- company, and period.
--

CREATE FUNCTION trial_balance(c character varying, p character varying) RETURNS TABLE(acct character, title character varying, debit numeric, credit numeric, acct_type character, sign_type character)
    LANGUAGE sql
    AS $_$
SELECT acct, title, 
       CASE WHEN dr > cr then dr - cr else 0 end as debit,
       CASE WHEN cr > dr then cr - dr else 0 end as credit,
       acct_type, sign_type
from tb join accounts 
on tb.co = accounts.company and tb.acct = accounts.acct_no
where period = $2 and co = $1 order by acct;
$_$;


ALTER FUNCTION public.trial_balance(c character varying, p character varying) OWNER TO dalyw;

--
-- Name: ts_trigger(); Type: FUNCTION; Schema: public; Owner: dalyw
-- Trigger to maintain the last_update and created fields of all records.
--

CREATE FUNCTION ts_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (tg_op = 'INSERT') THEN
	   NEW.created = current_timestamp;
	   NEW.last_update = current_timestamp;
	END IF;

	IF (tg_op = 'UPDATE') THEN
	   NEW.last_update = current_timestamp;
	END IF;

	RETURN NEW;

END;
$$;


ALTER FUNCTION public.ts_trigger() OWNER TO dalyw;

--
-- Name: begining_trans; Type: VIEW; Schema: public; Owner: dalyw
--

CREATE VIEW begining_trans AS
    SELECT doc_lines.company, doc_lines.acct_no, document.period, doc_lines.debit, doc_lines.credit FROM (doc_lines NATURAL JOIN document) WHERE (doc_lines.doc_id IN (SELECT document.doc_id FROM document WHERE (document.name = (find_config('begin_document'::bpchar))::bpchar)));


ALTER TABLE public.begining_trans OWNER TO dalyw;

--
-- Name: tb_as_entered; Type: VIEW; Schema: public; Owner: dalyw
--

CREATE VIEW tb_as_entered AS
    SELECT accounts.company, accounts.acct_no, begining_trans.period, accounts.title, accounts.acct_type, accounts.sign_type, begining_trans.debit, begining_trans.credit FROM (begining_trans RIGHT JOIN accounts ON (((accounts.company = begining_trans.company) AND (accounts.acct_no = begining_trans.acct_no))));


ALTER TABLE public.tb_as_entered OWNER TO dalyw;

-- SET default_tablespace = '';

-- SET default_with_oids = false;

--
-- Data for Name: acct_type; Type: TABLE DATA; Schema: public; Owner: dalyw
--

COPY acct_type (line, code, short, long, created, last_update) FROM stdin;
1	b	B/S       	Balance sheet account                                                                                                                                                                                                                                          	\N	\N
2	r	R/E       	Retained earnings                                                                                                                                                                                                                                              	\N	\N
3	i	Inc       	Income account                                                                                                                                                                                                                                                 	\N	\N
\.


--
-- Data for Name: balance_type; Type: TABLE DATA; Schema: public; Owner: dalyw
--

COPY balance_type (line, code, short, long) FROM stdin;
1	d	Dr        	Debit balance                                                                                                                                                                                                                                                  
2	c	Cr        	Credit balance                                                                                                                                                                                                                                                 
\.


--
-- Data for Name: sign_type; Type: TABLE DATA; Schema: public; Owner: dalyw
--

COPY sign_type (line, code, short, long) FROM stdin;
1	d	Dr	Debit balance account
2	c	Cr	Credit balance account
\.


--
-- Name: accounts_stamp; Type: TRIGGER; Schema: public; Owner: dalyw
--

CREATE TRIGGER accounts_stamp BEFORE INSERT OR UPDATE ON accounts FOR EACH ROW EXECUTE PROCEDURE ts_trigger();


--
-- Name: company_stamp; Type: TRIGGER; Schema: public; Owner: dalyw
--

CREATE TRIGGER company_stamp BEFORE INSERT OR UPDATE ON company FOR EACH ROW EXECUTE PROCEDURE ts_trigger();


--
-- Name: config_stamp; Type: TRIGGER; Schema: public; Owner: dalyw
--

CREATE TRIGGER config_stamp BEFORE INSERT OR UPDATE ON config FOR EACH ROW EXECUTE PROCEDURE ts_trigger();


--
-- Name: doc_lines_stamp; Type: TRIGGER; Schema: public; Owner: dalyw
--

CREATE TRIGGER doc_lines_stamp BEFORE INSERT OR UPDATE ON doc_lines FOR EACH ROW EXECUTE PROCEDURE ts_trigger();


--
-- Name: document_stamp; Type: TRIGGER; Schema: public; Owner: dalyw
--

CREATE TRIGGER document_stamp BEFORE INSERT OR UPDATE ON document FOR EACH ROW EXECUTE PROCEDURE ts_trigger();


--
-- Name: periods_stamp; Type: TRIGGER; Schema: public; Owner: dalyw
--

CREATE TRIGGER periods_stamp BEFORE INSERT OR UPDATE ON periods FOR EACH ROW EXECUTE PROCEDURE ts_trigger();


