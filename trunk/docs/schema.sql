/* memephage SQL schema
 *
 * $Id$ */

--
-- Selected TOC Entries:
--
\connect - coral
--
-- TOC Entry ID 2 (OID 18861)
--
-- Name: clique_sequence_seq Type: SEQUENCE Owner: coral
--

CREATE SEQUENCE "clique_sequence_seq" start 1 increment 1 maxvalue 2147483647 minvalue 1  cache 1 ;

--
-- TOC Entry ID 28 (OID 18880)
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
-- TOC Entry ID 29 (OID 18983)
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
-- TOC Entry ID 30 (OID 19071)
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
-- TOC Entry ID 31 (OID 19146)
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
-- TOC Entry ID 32 (OID 19223)
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
-- TOC Entry ID 33 (OID 19281)
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
-- TOC Entry ID 34 (OID 19373)
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
-- TOC Entry ID 35 (OID 19414)
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
-- TOC Entry ID 36 (OID 19477)
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
-- TOC Entry ID 37 (OID 19534)
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
-- TOC Entry ID 38 (OID 19572)
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
-- TOC Entry ID 39 (OID 19626)
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
-- TOC Entry ID 40 (OID 19681)
--
-- Name: rating Type: TABLE Owner: coral
--

CREATE TABLE "rating" (
	"sequence" integer DEFAULT nextval('"rating_sequence_seq"'::text) NOT NULL,
	"rate" real DEFAULT 0 NOT NULL,
	Constraint "rating_pkey" Primary Key ("sequence")
);

--
-- Data for TOC Entry ID 52 (OID 18880)
--
-- Name: clique Type: TABLE DATA Owner: coral
--


COPY "clique"  FROM stdin;
\.
--
-- Data for TOC Entry ID 53 (OID 18983)
--
-- Name: url-data Type: TABLE DATA Owner: coral
--


COPY "url-data"  FROM stdin;
\.
--
-- Data for TOC Entry ID 54 (OID 19071)
--
-- Name: link Type: TABLE DATA Owner: coral
--


COPY "link"  FROM stdin;
\.
--
-- Data for TOC Entry ID 55 (OID 19146)
--
-- Name: rate-link Type: TABLE DATA Owner: coral
--


COPY "rate-link"  FROM stdin;
\.
--
-- Data for TOC Entry ID 56 (OID 19223)
--
-- Name: url Type: TABLE DATA Owner: coral
--


COPY "url"  FROM stdin;
\.
--
-- Data for TOC Entry ID 57 (OID 19281)
--
-- Name: keyword Type: TABLE DATA Owner: coral
--


COPY "keyword"  FROM stdin;
\.
--
-- Data for TOC Entry ID 58 (OID 19373)
--
-- Name: keyword-link Type: TABLE DATA Owner: coral
--


COPY "keyword-link"  FROM stdin;
\.
--
-- Data for TOC Entry ID 59 (OID 19414)
--
-- Name: note Type: TABLE DATA Owner: coral
--


COPY "note"  FROM stdin;
\.
--
-- Data for TOC Entry ID 60 (OID 19477)
--
-- Name: user Type: TABLE DATA Owner: coral
--


COPY "user"  FROM stdin;
\.
--
-- Data for TOC Entry ID 61 (OID 19534)
--
-- Name: checkup Type: TABLE DATA Owner: coral
--


COPY "checkup"  FROM stdin;
\.
--
-- Data for TOC Entry ID 62 (OID 19572)
--
-- Name: setup Type: TABLE DATA Owner: coral
--


COPY "setup"  FROM stdin;
\.
--
-- Data for TOC Entry ID 63 (OID 19626)
--
-- Name: cookies Type: TABLE DATA Owner: coral
--


COPY "cookies"  FROM stdin;
\.
--
-- Data for TOC Entry ID 64 (OID 19681)
--
-- Name: rating Type: TABLE DATA Owner: coral
--


COPY "rating"  FROM stdin;
\.
--
-- TOC Entry ID 41 (OID 18983)
--
-- Name: "url-data_url" Type: INDEX Owner: coral
--

CREATE UNIQUE INDEX "url-data_url" on "url-data" using btree ( "url" "int4_ops" );

--
-- TOC Entry ID 42 (OID 19071)
--
-- Name: "link_clique_url" Type: INDEX Owner: coral
--

CREATE UNIQUE INDEX "link_clique_url" on "link" using btree ( "clique" "int4_ops", "url" "int4_ops" );

--
-- TOC Entry ID 44 (OID 19146)
--
-- Name: "rate-link_link_user" Type: INDEX Owner: coral
--

CREATE UNIQUE INDEX "rate-link_link_user" on "rate-link" using btree ( "link" "int4_ops", "user" "int4_ops" );

--
-- TOC Entry ID 43 (OID 19223)
--
-- Name: "url_uri" Type: INDEX Owner: coral
--

CREATE UNIQUE INDEX "url_uri" on "url" using btree ( "uri" "text_ops" );

--
-- TOC Entry ID 45 (OID 19281)
--
-- Name: "keyword_clique_keyword" Type: INDEX Owner: coral
--

CREATE UNIQUE INDEX "keyword_clique_keyword" on "keyword" using btree ( "clique" "int4_ops", "keyword" "text_ops" );

--
-- TOC Entry ID 46 (OID 19373)
--
-- Name: "keyword-link_keyword_link" Type: INDEX Owner: coral
--

CREATE UNIQUE INDEX "keyword-link_keyword_link" on "keyword-link" using btree ( "keyword" "int4_ops", "link" "int4_ops" );

--
-- TOC Entry ID 47 (OID 19414)
--
-- Name: "note_link" Type: INDEX Owner: coral
--

CREATE  INDEX "note_link" on "note" using btree ( "link" "int4_ops" );

--
-- TOC Entry ID 48 (OID 19477)
--
-- Name: "user_clique_login" Type: INDEX Owner: coral
--

CREATE UNIQUE INDEX "user_clique_login" on "user" using btree ( "clique" "int4_ops", "login" "varchar_ops" );

--
-- TOC Entry ID 49 (OID 19534)
--
-- Name: "checkup_url" Type: INDEX Owner: coral
--

CREATE UNIQUE INDEX "checkup_url" on "checkup" using btree ( "url" "int4_ops" );

--
-- TOC Entry ID 50 (OID 19572)
--
-- Name: "setup_setting-name" Type: INDEX Owner: coral
--

CREATE UNIQUE INDEX "setup_setting-name" on "setup" using btree ( "setting-name" "text_ops" );

--
-- TOC Entry ID 51 (OID 19626)
--
-- Name: "cookies_domain_key" Type: INDEX Owner: coral
--

CREATE UNIQUE INDEX "cookies_domain_key" on "cookies" using btree ( "domain" "text_ops", "key" "text_ops" );

--
-- TOC Entry ID 71 (OID 19698)
--
-- Name: "RI_ConstraintTrigger_19697" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "url-data.key.url" AFTER INSERT OR UPDATE ON "url-data"  FROM "url" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_check_ins" ('url-data.key.url', 'url-data', 'url', 'FULL', 'url', 'sequence');

--
-- TOC Entry ID 83 (OID 19700)
--
-- Name: "RI_ConstraintTrigger_19699" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "url-data.key.url" AFTER DELETE ON "url"  FROM "url-data" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_noaction_del" ('url-data.key.url', 'url-data', 'url', 'FULL', 'url', 'sequence');

--
-- TOC Entry ID 84 (OID 19702)
--
-- Name: "RI_ConstraintTrigger_19701" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "url-data.key.url" AFTER UPDATE ON "url"  FROM "url-data" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_cascade_upd" ('url-data.key.url', 'url-data', 'url', 'FULL', 'url', 'sequence');

--
-- TOC Entry ID 72 (OID 19704)
--
-- Name: "RI_ConstraintTrigger_19703" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "link.key.clique" AFTER INSERT OR UPDATE ON "link"  FROM "clique" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_check_ins" ('link.key.clique', 'link', 'clique', 'FULL', 'clique', 'sequence');

--
-- TOC Entry ID 65 (OID 19706)
--
-- Name: "RI_ConstraintTrigger_19705" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "link.key.clique" AFTER DELETE ON "clique"  FROM "link" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_noaction_del" ('link.key.clique', 'link', 'clique', 'FULL', 'clique', 'sequence');

--
-- TOC Entry ID 66 (OID 19708)
--
-- Name: "RI_ConstraintTrigger_19707" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "link.key.clique" AFTER UPDATE ON "clique"  FROM "link" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_cascade_upd" ('link.key.clique', 'link', 'clique', 'FULL', 'clique', 'sequence');

--
-- TOC Entry ID 73 (OID 19710)
--
-- Name: "RI_ConstraintTrigger_19709" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "link.key.url" AFTER INSERT OR UPDATE ON "link"  FROM "url" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_check_ins" ('link.key.url', 'link', 'url', 'FULL', 'url', 'sequence');

--
-- TOC Entry ID 85 (OID 19712)
--
-- Name: "RI_ConstraintTrigger_19711" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "link.key.url" AFTER DELETE ON "url"  FROM "link" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_noaction_del" ('link.key.url', 'link', 'url', 'FULL', 'url', 'sequence');

--
-- TOC Entry ID 86 (OID 19714)
--
-- Name: "RI_ConstraintTrigger_19713" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "link.key.url" AFTER UPDATE ON "url"  FROM "link" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_cascade_upd" ('link.key.url', 'link', 'url', 'FULL', 'url', 'sequence');

--
-- TOC Entry ID 80 (OID 19716)
--
-- Name: "RI_ConstraintTrigger_19715" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "rate-link.key.link" AFTER INSERT OR UPDATE ON "rate-link"  FROM "link" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_check_ins" ('rate-link.key.link', 'rate-link', 'link', 'FULL', 'link', 'sequence');

--
-- TOC Entry ID 74 (OID 19718)
--
-- Name: "RI_ConstraintTrigger_19717" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "rate-link.key.link" AFTER DELETE ON "link"  FROM "rate-link" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_noaction_del" ('rate-link.key.link', 'rate-link', 'link', 'FULL', 'link', 'sequence');

--
-- TOC Entry ID 75 (OID 19720)
--
-- Name: "RI_ConstraintTrigger_19719" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "rate-link.key.link" AFTER UPDATE ON "link"  FROM "rate-link" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_cascade_upd" ('rate-link.key.link', 'rate-link', 'link', 'FULL', 'link', 'sequence');

--
-- TOC Entry ID 81 (OID 19722)
--
-- Name: "RI_ConstraintTrigger_19721" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "rate-link.key.rating" AFTER INSERT OR UPDATE ON "rate-link"  FROM "rating" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_check_ins" ('rate-link.key.rating', 'rate-link', 'rating', 'FULL', 'rating', 'sequence');

--
-- TOC Entry ID 105 (OID 19724)
--
-- Name: "RI_ConstraintTrigger_19723" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "rate-link.key.rating" AFTER DELETE ON "rating"  FROM "rate-link" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_noaction_del" ('rate-link.key.rating', 'rate-link', 'rating', 'FULL', 'rating', 'sequence');

--
-- TOC Entry ID 106 (OID 19726)
--
-- Name: "RI_ConstraintTrigger_19725" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "rate-link.key.rating" AFTER UPDATE ON "rating"  FROM "rate-link" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_cascade_upd" ('rate-link.key.rating', 'rate-link', 'rating', 'FULL', 'rating', 'sequence');

--
-- TOC Entry ID 82 (OID 19728)
--
-- Name: "RI_ConstraintTrigger_19727" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "rate-link.key.user" AFTER INSERT OR UPDATE ON "rate-link"  FROM "user" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_check_ins" ('rate-link.key.user', 'rate-link', 'user', 'FULL', 'user', 'sequence');

--
-- TOC Entry ID 97 (OID 19730)
--
-- Name: "RI_ConstraintTrigger_19729" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "rate-link.key.user" AFTER DELETE ON "user"  FROM "rate-link" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_noaction_del" ('rate-link.key.user', 'rate-link', 'user', 'FULL', 'user', 'sequence');

--
-- TOC Entry ID 98 (OID 19732)
--
-- Name: "RI_ConstraintTrigger_19731" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "rate-link.key.user" AFTER UPDATE ON "user"  FROM "rate-link" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_cascade_upd" ('rate-link.key.user', 'rate-link', 'user', 'FULL', 'user', 'sequence');

--
-- TOC Entry ID 89 (OID 19734)
--
-- Name: "RI_ConstraintTrigger_19733" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "keyword.key.clique" AFTER INSERT OR UPDATE ON "keyword"  FROM "clique" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_check_ins" ('keyword.key.clique', 'keyword', 'clique', 'FULL', 'clique', 'sequence');

--
-- TOC Entry ID 67 (OID 19736)
--
-- Name: "RI_ConstraintTrigger_19735" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "keyword.key.clique" AFTER DELETE ON "clique"  FROM "keyword" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_noaction_del" ('keyword.key.clique', 'keyword', 'clique', 'FULL', 'clique', 'sequence');

--
-- TOC Entry ID 68 (OID 19738)
--
-- Name: "RI_ConstraintTrigger_19737" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "keyword.key.clique" AFTER UPDATE ON "clique"  FROM "keyword" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_cascade_upd" ('keyword.key.clique', 'keyword', 'clique', 'FULL', 'clique', 'sequence');

--
-- TOC Entry ID 92 (OID 19740)
--
-- Name: "RI_ConstraintTrigger_19739" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "keyword-link.key.keyword" AFTER INSERT OR UPDATE ON "keyword-link"  FROM "keyword" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_check_ins" ('keyword-link.key.keyword', 'keyword-link', 'keyword', 'FULL', 'keyword', 'sequence');

--
-- TOC Entry ID 90 (OID 19742)
--
-- Name: "RI_ConstraintTrigger_19741" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "keyword-link.key.keyword" AFTER DELETE ON "keyword"  FROM "keyword-link" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_noaction_del" ('keyword-link.key.keyword', 'keyword-link', 'keyword', 'FULL', 'keyword', 'sequence');

--
-- TOC Entry ID 91 (OID 19744)
--
-- Name: "RI_ConstraintTrigger_19743" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "keyword-link.key.keyword" AFTER UPDATE ON "keyword"  FROM "keyword-link" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_cascade_upd" ('keyword-link.key.keyword', 'keyword-link', 'keyword', 'FULL', 'keyword', 'sequence');

--
-- TOC Entry ID 93 (OID 19746)
--
-- Name: "RI_ConstraintTrigger_19745" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "keyword-link.key.link" AFTER INSERT OR UPDATE ON "keyword-link"  FROM "link" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_check_ins" ('keyword-link.key.link', 'keyword-link', 'link', 'FULL', 'link', 'sequence');

--
-- TOC Entry ID 76 (OID 19748)
--
-- Name: "RI_ConstraintTrigger_19747" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "keyword-link.key.link" AFTER DELETE ON "link"  FROM "keyword-link" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_noaction_del" ('keyword-link.key.link', 'keyword-link', 'link', 'FULL', 'link', 'sequence');

--
-- TOC Entry ID 77 (OID 19750)
--
-- Name: "RI_ConstraintTrigger_19749" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "keyword-link.key.link" AFTER UPDATE ON "link"  FROM "keyword-link" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_cascade_upd" ('keyword-link.key.link', 'keyword-link', 'link', 'FULL', 'link', 'sequence');

--
-- TOC Entry ID 94 (OID 19752)
--
-- Name: "RI_ConstraintTrigger_19751" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "keyword-link.key.user" AFTER INSERT OR UPDATE ON "keyword-link"  FROM "user" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_check_ins" ('keyword-link.key.user', 'keyword-link', 'user', 'FULL', 'user', 'sequence');

--
-- TOC Entry ID 99 (OID 19754)
--
-- Name: "RI_ConstraintTrigger_19753" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "keyword-link.key.user" AFTER DELETE ON "user"  FROM "keyword-link" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_noaction_del" ('keyword-link.key.user', 'keyword-link', 'user', 'FULL', 'user', 'sequence');

--
-- TOC Entry ID 100 (OID 19756)
--
-- Name: "RI_ConstraintTrigger_19755" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "keyword-link.key.user" AFTER UPDATE ON "user"  FROM "keyword-link" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_cascade_upd" ('keyword-link.key.user', 'keyword-link', 'user', 'FULL', 'user', 'sequence');

--
-- TOC Entry ID 95 (OID 19758)
--
-- Name: "RI_ConstraintTrigger_19757" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "note.key.link" AFTER INSERT OR UPDATE ON "note"  FROM "link" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_check_ins" ('note.key.link', 'note', 'link', 'FULL', 'link', 'sequence');

--
-- TOC Entry ID 78 (OID 19760)
--
-- Name: "RI_ConstraintTrigger_19759" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "note.key.link" AFTER DELETE ON "link"  FROM "note" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_noaction_del" ('note.key.link', 'note', 'link', 'FULL', 'link', 'sequence');

--
-- TOC Entry ID 79 (OID 19762)
--
-- Name: "RI_ConstraintTrigger_19761" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "note.key.link" AFTER UPDATE ON "link"  FROM "note" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_cascade_upd" ('note.key.link', 'note', 'link', 'FULL', 'link', 'sequence');

--
-- TOC Entry ID 96 (OID 19764)
--
-- Name: "RI_ConstraintTrigger_19763" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "note.key.user" AFTER INSERT OR UPDATE ON "note"  FROM "user" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_check_ins" ('note.key.user', 'note', 'user', 'FULL', 'user', 'sequence');

--
-- TOC Entry ID 101 (OID 19766)
--
-- Name: "RI_ConstraintTrigger_19765" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "note.key.user" AFTER DELETE ON "user"  FROM "note" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_noaction_del" ('note.key.user', 'note', 'user', 'FULL', 'user', 'sequence');

--
-- TOC Entry ID 102 (OID 19768)
--
-- Name: "RI_ConstraintTrigger_19767" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "note.key.user" AFTER UPDATE ON "user"  FROM "note" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_cascade_upd" ('note.key.user', 'note', 'user', 'FULL', 'user', 'sequence');

--
-- TOC Entry ID 103 (OID 19770)
--
-- Name: "RI_ConstraintTrigger_19769" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "user.key.clique" AFTER INSERT OR UPDATE ON "user"  FROM "clique" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_check_ins" ('user.key.clique', 'user', 'clique', 'FULL', 'clique', 'sequence');

--
-- TOC Entry ID 69 (OID 19772)
--
-- Name: "RI_ConstraintTrigger_19771" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "user.key.clique" AFTER DELETE ON "clique"  FROM "user" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_noaction_del" ('user.key.clique', 'user', 'clique', 'FULL', 'clique', 'sequence');

--
-- TOC Entry ID 70 (OID 19774)
--
-- Name: "RI_ConstraintTrigger_19773" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "user.key.clique" AFTER UPDATE ON "clique"  FROM "user" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_cascade_upd" ('user.key.clique', 'user', 'clique', 'FULL', 'clique', 'sequence');

--
-- TOC Entry ID 104 (OID 19776)
--
-- Name: "RI_ConstraintTrigger_19775" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "checkup.key.url" AFTER INSERT OR UPDATE ON "checkup"  FROM "url" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_check_ins" ('checkup.key.url', 'checkup', 'url', 'FULL', 'url', 'sequence');

--
-- TOC Entry ID 87 (OID 19778)
--
-- Name: "RI_ConstraintTrigger_19777" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "checkup.key.url" AFTER DELETE ON "url"  FROM "checkup" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_noaction_del" ('checkup.key.url', 'checkup', 'url', 'FULL', 'url', 'sequence');

--
-- TOC Entry ID 88 (OID 19780)
--
-- Name: "RI_ConstraintTrigger_19779" Type: TRIGGER Owner: coral
--

CREATE CONSTRAINT TRIGGER "checkup.key.url" AFTER UPDATE ON "url"  FROM "checkup" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_cascade_upd" ('checkup.key.url', 'checkup', 'url', 'FULL', 'url', 'sequence');

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

