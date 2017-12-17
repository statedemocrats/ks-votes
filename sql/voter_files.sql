SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;
SET search_path = public, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;

drop table voter_election_codes;
drop table voters;
drop table election_codes;
drop table voter_files;

create table voter_files (
  id serial primary key,
  name character varying,
  created_at timestamp without time zone NOT NULL,
  updated_at timestamp without time zone NOT NULL
);

create table voters (
  id serial primary key,
  county character varying,
  name_first character varying,
  name_last character varying,
  name_middle character varying,
  dob character varying,
  phone character varying,
  reg_date character varying,
  voter_files jsonb,
  ks_voter_id character varying,
  res_address_nbr character varying,
  res_address_nbr_suffix character varying,
  street_name character varying,
  res_unit_nbr character varying,
  res_city character varying,
  res_zip5 character varying,
  res_zip4 character varying,
  res_carrier_rte character varying,
  party integer,
  precinct character varying,
  districts jsonb,
  election_codes jsonb,
  checksum character varying,
  created_at timestamp without time zone NOT NULL,
  updated_at timestamp without time zone NOT NULL
);

create table election_codes (
  id serial primary key,
  name character varying,
  description character varying,
  created_at timestamp without time zone NOT NULL,
  updated_at timestamp without time zone NOT NULL
);

create table voter_election_codes (
  id serial,
  voter_id integer,
  election_code_id integer
);

CREATE UNIQUE INDEX voters_on_ks_voter_id ON voters USING btree (ks_voter_id);
CREATE UNIQUE INDEX voters_on_checksum ON voters USING btree (checksum);
CREATE UNIQUE INDEX election_codes_names ON election_codes USING btree (name);
CREATE UNIQUE INDEX voter_files_name on voter_files using btree (name);
create unique index voter_election_codes_idx ON voter_election_codes USING btree(voter_id,election_code_id);
alter table only voter_election_codes add constraint vec_voter_id FOREIGN KEY (voter_id) REFERENCES voters(id);
alter table only voter_election_codes add constraint vec_election_code_id FOREIGN KEY (election_code_id) REFERENCES election_codes(id);
