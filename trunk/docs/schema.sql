/* memephage SQL schema
 *
 * $Id$ */


--
-- Selected TOC Entries:
--
\connect - postgres
--
-- TOC Entry ID 2 (OID 18861)
--
-- Name: clique_sequence_seq Type: SEQUENCE Owner: coral
--

CREATE SEQUENCE "clique_sequence_seq" start 1 increment 1 maxvalue 2147483647 minvalue 1  cache 1 ;

--
-- TOC Entry ID 38 (OID 18880)
--
-- Name: clique Type: TABLE Owner: coral
--

CREATE TABLE "clique" (
	"sequence" integer DEFAULT nextval('"clique_sequence_seq"'::text) NOT NULL,
	"created" timestamp with time zone DEFAULT now() NOT NULL,
	"description" text,
	Constraint "clique_pkey" Primary Key ("sequence")
);

--
-- TOC Entry ID 4 (OID 18964)
--
-- Name: url-data_sequence_seq Type: SEQUENCE Owner: coral
--

CREATE SEQUENCE "url-data_sequence_seq" start 1 increment 1 maxvalue 2147483647 minvalue 1  cache 1 ;

--
-- TOC Entry ID 39 (OID 18983)
--
-- Name: url-data Type: TABLE Owner: coral
--

CREATE TABLE "url-data" (
	"sequence" integer DEFAULT nextval('"url-data_sequence_seq"'::text) NOT NULL,
	"url" integer NOT NULL,
	"title" text NOT NULL,
	"content-type" character varying(36),
	"content-size" integer,
	"last-updated" timestamp with time zone DEFAULT now() NOT NULL,
	Constraint "url-data_pkey" Primary Key ("sequence")
);

--
-- TOC Entry ID 6 (OID 19052)
--
-- Name: link_sequence_seq Type: SEQUENCE Owner: coral
--

CREATE SEQUENCE "link_sequence_seq" start 1 increment 1 maxvalue 2147483647 minvalue 1  cache 1 ;

--
-- TOC Entry ID 42 (OID 19071)
--
-- Name: link Type: TABLE Owner: coral
--

CREATE TABLE "link" (
	"sequence" integer DEFAULT nextval('"link_sequence_seq"'::text) NOT NULL,
	"clique" integer NOT NULL,
	"url" integer NOT NULL,
	"created" timestamp with time zone DEFAULT now() NOT NULL,
	Constraint "link_pkey" Primary Key ("sequence")
);

--
-- TOC Entry ID 8 (OID 19127)
--
-- Name: rate-link_sequence_seq Type: SEQUENCE Owner: coral
--

CREATE SEQUENCE "rate-link_sequence_seq" start 1 increment 1 maxvalue 2147483647 minvalue 1  cache 1 ;

--
-- TOC Entry ID 43 (OID 19146)
--
-- Name: rate-link Type: TABLE Owner: coral
--

CREATE TABLE "rate-link" (
	"sequence" integer DEFAULT nextval('"rate-link_sequence_seq"'::text) NOT NULL,
	"rating" integer NOT NULL,
	"link" integer NOT NULL,
	"user" integer NOT NULL,
	"created" timestamp with time zone DEFAULT now() NOT NULL,
	Constraint "rate-link_pkey" Primary Key ("sequence")
);

--
-- TOC Entry ID 10 (OID 19204)
--
-- Name: url_sequence_seq Type: SEQUENCE Owner: coral
--

CREATE SEQUENCE "url_sequence_seq" start 1 increment 1 maxvalue 2147483647 minvalue 1  cache 1 ;

--
-- TOC Entry ID 44 (OID 19223)
--
-- Name: url Type: TABLE Owner: coral
--

CREATE TABLE "url" (
	"sequence" integer DEFAULT nextval('"url_sequence_seq"'::text) NOT NULL,
	"uri" text NOT NULL,
	"created" timestamp with time zone DEFAULT now() NOT NULL,
	Constraint "url_pkey" Primary Key ("sequence")
);

--
-- TOC Entry ID 12 (OID 19262)
--
-- Name: keyword_sequence_seq Type: SEQUENCE Owner: coral
--

CREATE SEQUENCE "keyword_sequence_seq" start 1 increment 1 maxvalue 2147483647 minvalue 1  cache 1 ;

--
-- TOC Entry ID 45 (OID 19281)
--
-- Name: keyword Type: TABLE Owner: coral
--

CREATE TABLE "keyword" (
	"sequence" integer DEFAULT nextval('"keyword_sequence_seq"'::text) NOT NULL,
	"clique" integer NOT NULL,
	"keyword" text NOT NULL,
	"description" text,
	Constraint "keyword_pkey" Primary Key ("sequence")
);

--
-- TOC Entry ID 14 (OID 19354)
--
-- Name: keyword-link_sequence_seq Type: SEQUENCE Owner: coral
--

CREATE SEQUENCE "keyword-link_sequence_seq" start 1 increment 1 maxvalue 2147483647 minvalue 1  cache 1 ;

--
-- TOC Entry ID 46 (OID 19373)
--
-- Name: keyword-link Type: TABLE Owner: coral
--

CREATE TABLE "keyword-link" (
	"sequence" integer DEFAULT nextval('"keyword-link_sequence_seq"'::text) NOT NULL,
	"keyword" integer NOT NULL,
	"link" integer NOT NULL,
	"user" integer NOT NULL,
	"created" timestamp with time zone DEFAULT now() NOT NULL,
	Constraint "keyword-link_pkey" Primary Key ("sequence")
);

--
-- TOC Entry ID 16 (OID 19395)
--
-- Name: note_sequence_seq Type: SEQUENCE Owner: coral
--

CREATE SEQUENCE "note_sequence_seq" start 1 increment 1 maxvalue 2147483647 minvalue 1  cache 1 ;

--
-- TOC Entry ID 47 (OID 19414)
--
-- Name: note Type: TABLE Owner: coral
--

CREATE TABLE "note" (
	"sequence" integer DEFAULT nextval('"note_sequence_seq"'::text) NOT NULL,
	"link" integer NOT NULL,
	"user" integer NOT NULL,
	"subject" text NOT NULL,
	"body" text NOT NULL,
	"created" timestamp with time zone DEFAULT now() NOT NULL,
	Constraint "note_pkey" Primary Key ("sequence")
);

--
-- TOC Entry ID 18 (OID 19458)
--
-- Name: user_sequence_seq Type: SEQUENCE Owner: coral
--

CREATE SEQUENCE "user_sequence_seq" start 1 increment 1 maxvalue 2147483647 minvalue 1  cache 1 ;

--
-- TOC Entry ID 48 (OID 19477)
--
-- Name: user Type: TABLE Owner: coral
--

CREATE TABLE "user" (
	"sequence" integer DEFAULT nextval('"user_sequence_seq"'::text) NOT NULL,
	"clique" integer NOT NULL,
	"login" character varying(32) NOT NULL,
	"password" text NOT NULL,
	"created" timestamp with time zone DEFAULT now() NOT NULL,
	"last-use" timestamp with time zone,
	Constraint "user_pkey" Primary Key ("sequence")
);

--
-- TOC Entry ID 20 (OID 19515)
--
-- Name: checkup_sequence_seq Type: SEQUENCE Owner: coral
--

CREATE SEQUENCE "checkup_sequence_seq" start 1 increment 1 maxvalue 2147483647 minvalue 1  cache 1 ;

--
-- TOC Entry ID 49 (OID 19534)
--
-- Name: checkup Type: TABLE Owner: coral
--

CREATE TABLE "checkup" (
	"sequence" integer DEFAULT nextval('"checkup_sequence_seq"'::text) NOT NULL,
	"url" integer NOT NULL,
	"last-check" timestamp with time zone,
	Constraint "checkup_pkey" Primary Key ("sequence")
);

--
-- TOC Entry ID 22 (OID 19553)
--
-- Name: setup_sequence_seq Type: SEQUENCE Owner: coral
--

CREATE SEQUENCE "setup_sequence_seq" start 1 increment 1 maxvalue 2147483647 minvalue 1  cache 1 ;

--
-- TOC Entry ID 50 (OID 19572)
--
-- Name: setup Type: TABLE Owner: coral
--

CREATE TABLE "setup" (
	"sequence" integer DEFAULT nextval('"setup_sequence_seq"'::text) NOT NULL,
	"setting-name" text NOT NULL,
	"setting-value" text,
	"description" text,
	Constraint "setup_pkey" Primary Key ("sequence")
);

--
-- TOC Entry ID 24 (OID 19607)
--
-- Name: cookies_sequence_seq Type: SEQUENCE Owner: coral
--

CREATE SEQUENCE "cookies_sequence_seq" start 1 increment 1 maxvalue 2147483647 minvalue 1  cache 1 ;

--
-- TOC Entry ID 51 (OID 19626)
--
-- Name: cookies Type: TABLE Owner: coral
--

CREATE TABLE "cookies" (
	"sequence" integer DEFAULT nextval('"cookies_sequence_seq"'::text) NOT NULL,
	"domain" text NOT NULL,
	"key" text NOT NULL,
	"value" text,
	"expires" timestamp with time zone NOT NULL,
	Constraint "cookies_pkey" Primary Key ("sequence")
);

--
-- TOC Entry ID 26 (OID 19662)
--
-- Name: rating_sequence_seq Type: SEQUENCE Owner: coral
--

CREATE SEQUENCE "rating_sequence_seq" start 1 increment 1 maxvalue 2147483647 minvalue 1  cache 1 ;

--
-- TOC Entry ID 52 (OID 19681)
--
-- Name: rating Type: TABLE Owner: coral
--

CREATE TABLE "rating" (
	"sequence" integer DEFAULT nextval('"rating_sequence_seq"'::text) NOT NULL,
	"rate" real DEFAULT 0 NOT NULL,
	Constraint "rating_pkey" Primary Key ("sequence")
);


--
-- TOC Entry ID 53 (OID 18983)
--
-- Name: "url-data_url" Type: INDEX Owner: coral
--

CREATE UNIQUE INDEX "url-data_url" on "url-data" using btree ( "url" "int4_ops" );

--
-- TOC Entry ID 54 (OID 19071)
--
-- Name: "link_clique_url" Type: INDEX Owner: coral
--

CREATE UNIQUE INDEX "link_clique_url" on "link" using btree ( "clique" "int4_ops", "url" "int4_ops" );

--
-- TOC Entry ID 56 (OID 19146)
--
-- Name: "rate-link_link_user" Type: INDEX Owner: coral
--

CREATE UNIQUE INDEX "rate-link_link_user" on "rate-link" using btree ( "link" "int4_ops", "user" "int4_ops" );

--
-- TOC Entry ID 55 (OID 19223)
--
-- Name: "url_uri" Type: INDEX Owner: coral
--

CREATE UNIQUE INDEX "url_uri" on "url" using btree ( "uri" "text_ops" );

--
-- TOC Entry ID 57 (OID 19281)
--
-- Name: "keyword_clique_keyword" Type: INDEX Owner: coral
--

CREATE UNIQUE INDEX "keyword_clique_keyword" on "keyword" using btree ( "clique" "int4_ops", "keyword" "text_ops" );

--
-- TOC Entry ID 58 (OID 19373)
--
-- Name: "keyword-link_keyword_link" Type: INDEX Owner: coral
--

CREATE UNIQUE INDEX "keyword-link_keyword_link" on "keyword-link" using btree ( "keyword" "int4_ops", "link" "int4_ops" );

--
-- TOC Entry ID 59 (OID 19414)
--
-- Name: "note_link" Type: INDEX Owner: coral
--

CREATE  INDEX "note_link" on "note" using btree ( "link" "int4_ops" );

--
-- TOC Entry ID 60 (OID 19477)
--
-- Name: "user_clique_login" Type: INDEX Owner: coral
--

CREATE UNIQUE INDEX "user_clique_login" on "user" using btree ( "clique" "int4_ops", "login" "varchar_ops" );

--
-- TOC Entry ID 61 (OID 19534)
--
-- Name: "checkup_url" Type: INDEX Owner: coral
--

CREATE UNIQUE INDEX "checkup_url" on "checkup" using btree ( "url" "int4_ops" );

--
-- TOC Entry ID 62 (OID 19572)
--
-- Name: "setup_setting-name" Type: INDEX Owner: coral
--

CREATE UNIQUE INDEX "setup_setting-name" on "setup" using btree ( "setting-name" "text_ops" );

--
-- TOC Entry ID 63 (OID 19626)
--
-- Name: "cookies_domain_key" Type: INDEX Owner: coral
--

CREATE UNIQUE INDEX "cookies_domain_key" on "cookies" using btree ( "domain" "text_ops", "key" "text_ops" );

--
-- TOC Entry ID 3 (OID 18861)
--
-- Name: clique_sequence_seq Type: SEQUENCE SET Owner: 
--

SELECT setval ('"clique_sequence_seq"', 1, 'f');

--
-- TOC Entry ID 5 (OID 18964)
--
-- Name: url-data_sequence_seq Type: SEQUENCE SET Owner: 
--

SELECT setval ('"url-data_sequence_seq"', 1, 'f');

--
-- TOC Entry ID 7 (OID 19052)
--
-- Name: link_sequence_seq Type: SEQUENCE SET Owner: 
--

SELECT setval ('"link_sequence_seq"', 1, 'f');

--
-- TOC Entry ID 9 (OID 19127)
--
-- Name: rate-link_sequence_seq Type: SEQUENCE SET Owner: 
--

SELECT setval ('"rate-link_sequence_seq"', 1, 'f');

--
-- TOC Entry ID 11 (OID 19204)
--
-- Name: url_sequence_seq Type: SEQUENCE SET Owner: 
--

SELECT setval ('"url_sequence_seq"', 1, 'f');

--
-- TOC Entry ID 13 (OID 19262)
--
-- Name: keyword_sequence_seq Type: SEQUENCE SET Owner: 
--

SELECT setval ('"keyword_sequence_seq"', 1, 'f');

--
-- TOC Entry ID 15 (OID 19354)
--
-- Name: keyword-link_sequence_seq Type: SEQUENCE SET Owner: 
--

SELECT setval ('"keyword-link_sequence_seq"', 1, 'f');

--
-- TOC Entry ID 17 (OID 19395)
--
-- Name: note_sequence_seq Type: SEQUENCE SET Owner: 
--

SELECT setval ('"note_sequence_seq"', 1, 'f');

--
-- TOC Entry ID 19 (OID 19458)
--
-- Name: user_sequence_seq Type: SEQUENCE SET Owner: 
--

SELECT setval ('"user_sequence_seq"', 1, 'f');

--
-- TOC Entry ID 21 (OID 19515)
--
-- Name: checkup_sequence_seq Type: SEQUENCE SET Owner: 
--

SELECT setval ('"checkup_sequence_seq"', 1, 'f');

--
-- TOC Entry ID 23 (OID 19553)
--
-- Name: setup_sequence_seq Type: SEQUENCE SET Owner: 
--

SELECT setval ('"setup_sequence_seq"', 1, 'f');

--
-- TOC Entry ID 25 (OID 19607)
--
-- Name: cookies_sequence_seq Type: SEQUENCE SET Owner: 
--

SELECT setval ('"cookies_sequence_seq"', 1, 'f');

--
-- TOC Entry ID 27 (OID 19662)
--
-- Name: rating_sequence_seq Type: SEQUENCE SET Owner: 
--

SELECT setval ('"rating_sequence_seq"', 1, 'f');

