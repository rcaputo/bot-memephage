/* memephage SQL schema
 *
 * $Id$ */

CREATE TABLE clique (
	sequence	SERIAL PRIMARY KEY,
	created		TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
	description	TEXT
);

CREATE TABLE url (
	sequence	SERIAL PRIMARY KEY,
	uri		TEXT NOT NULL UNIQUE,
	created		TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE url_data (
	sequence	SERIAL PRIMARY KEY,
	url		INTEGER NOT NULL UNIQUE REFERENCES url,
	title		TEXT NOT NULL,
	content_type	VARCHAR(36),
	content_size	INTEGER,
	last_updated	TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE "user" (
	sequence	SERIAL PRIMARY KEY,
	clique		INTEGER NOT NULL REFERENCES clique,
	login		VARCHAR(32) NOT NULL,
	password	TEXT NOT NULL,
	created		TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
	last_use	TIMESTAMP,
	UNIQUE (clique, login)
);

CREATE TABLE link (
	sequence	SERIAL PRIMARY KEY,
	clique		INTEGER NOT NULL REFERENCES clique,
	url		INTEGER NOT NULL REFERENCES url,
	created		TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
	UNIQUE(clique, url)
);

CREATE TABLE rating (
	sequence	SERIAL PRIMARY KEY,
	rate		REAL DEFAULT 0 NOT NULL
);

CREATE TABLE rate_link (
       	sequence	SERIAL PRIMARY KEY,
	rating		INTEGER NOT NULL REFERENCES rating,
	link		INTEGER NOT NULL REFERENCES link,
	"user"		INTEGER NOT NULL REFERENCES "user",
	created		TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
	UNIQUE (link, "user")
);

CREATE TABLE keyword (
	sequence	SERIAL PRIMARY KEY,
	clique		INTEGER NOT NULL REFERENCES clique,
	keyword		TEXT NOT NULL,
	description	TEXT,
	UNIQUE(clique, keyword)
);

CREATE TABLE keyword_link (
	sequence	SERIAL PRIMARY KEY,
	keyword		INTEGER NOT NULL REFERENCES keyword,
	link		INTEGER NOT NULL REFERENCES link,
	"user"		INTEGER NOT NULL REFERENCES "user",
	created		TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
	UNIQUE (keyword, link)
);

CREATE TABLE note (
	sequence	SERIAL PRIMARY KEY,
	link		INTEGER NOT NULL REFERENCES link,
	"user"		INTEGER NOT NULL REFERENCES "user",
	subject		TEXT NOT NULL,
	body		TEXT NOT NULL,
	created		TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE checkup (
	sequence	SERIAL PRIMARY KEY,
	url		INTEGER NOT NULL UNIQUE REFERENCES url,
	last_check	TIMESTAMP
);

CREATE TABLE setup (
	sequence	SERIAL PRIMARY KEY,
	setting_name	TEXT NOT NULL UNIQUE,
	setting_value	TEXT,
	description	TEXT
);

CREATE TABLE cookies (
	sequence	SERIAL PRIMARY KEY,
	domain		TEXT NOT NULL,
	key		text NOT NULL,
	value		TEXT,
	expires		TIMESTAMP NOT NULL,
	UNIQUE (domain, key)
);
