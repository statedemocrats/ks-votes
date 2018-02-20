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
  party_history jsonb,
  precinct character varying,
  districts jsonb,
  election_codes jsonb,
  checksum character varying,
  vtd character varying,
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

CREATE UNIQUE INDEX voters_on_ks_voter_id ON voters USING btree (ks_voter_id);
CREATE UNIQUE INDEX voters_on_checksum ON voters USING btree (checksum);
CREATE UNIQUE INDEX election_codes_names ON election_codes USING btree (name);
create index voters_name_last on voters using btree (name_last);
create index voters_name_first on voters using btree (name_first);
create index voters_county on voters using btree (county);
create index voters_precinct on voters using btree (precinct);
create index voters_vtd on voters using btree (vtd);
create index voters_dob on voters using btree (dob);
create index voters_null_vtd_idx on voters (vtd) where vtd is null;
create index voters_districts on voters using gin (districts);
create index voters_election_codes on voters using gin (election_codes);
CREATE UNIQUE INDEX voter_files_name on voter_files using btree (name);
