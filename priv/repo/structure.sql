--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.4
-- Dumped by pg_dump version 9.5.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: alternate_feeds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE alternate_feeds (
    id integer NOT NULL,
    title character varying(255),
    url character varying(255),
    feed_id integer,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: alternate_feeds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE alternate_feeds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: alternate_feeds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE alternate_feeds_id_seq OWNED BY alternate_feeds.id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE categories (
    id integer NOT NULL,
    title character varying(255),
    parent_id integer,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE categories_id_seq OWNED BY categories.id;


--
-- Name: categories_podcasts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE categories_podcasts (
    category_id integer,
    podcast_id integer
);


--
-- Name: chapters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE chapters (
    id integer NOT NULL,
    start character varying(255),
    title character varying(255),
    episode_id integer,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: chapters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE chapters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chapters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE chapters_id_seq OWNED BY chapters.id;


--
-- Name: contributors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE contributors (
    id integer NOT NULL,
    name character varying(255),
    uri character varying(255),
    user_id integer,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: contributors_episodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE contributors_episodes (
    contributor_id integer,
    episode_id integer
);


--
-- Name: contributors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contributors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contributors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contributors_id_seq OWNED BY contributors.id;


--
-- Name: contributors_podcasts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE contributors_podcasts (
    contributor_id integer,
    podcast_id integer
);


--
-- Name: enclosures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE enclosures (
    id integer NOT NULL,
    url character varying(255),
    length character varying(255),
    type character varying(255),
    guid character varying(255),
    episode_id integer,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: enclosures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE enclosures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enclosures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE enclosures_id_seq OWNED BY enclosures.id;


--
-- Name: episodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE episodes (
    id integer NOT NULL,
    title character varying(255),
    link character varying(255),
    publishing_date timestamp without time zone,
    guid character varying(255),
    description text,
    shownotes text,
    payment_link_title character varying(255),
    payment_link_url character varying(255),
    deep_link character varying(255),
    duration character varying(255),
    author character varying(255),
    subtitle character varying(255),
    summary text,
    podcast_id integer,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: episodes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE episodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: episodes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE episodes_id_seq OWNED BY episodes.id;


--
-- Name: feeds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE feeds (
    id integer NOT NULL,
    self_link_title character varying(255),
    self_link_url character varying(255),
    next_page_url character varying(255),
    prev_page_url character varying(255),
    first_page_url character varying(255),
    last_page_url character varying(255),
    hub_link_url character varying(255),
    feed_generator character varying(255),
    podcast_id integer,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: feeds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE feeds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feeds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE feeds_id_seq OWNED BY feeds.id;


--
-- Name: followers_podcasts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE followers_podcasts (
    user_id integer,
    podcast_id integer
);


--
-- Name: followers_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE followers_users (
    follower_id integer,
    user_id integer
);


--
-- Name: languages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE languages (
    id integer NOT NULL,
    shortcode character varying(255),
    name character varying(255),
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: languages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE languages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: languages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE languages_id_seq OWNED BY languages.id;


--
-- Name: languages_podcasts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE languages_podcasts (
    language_id integer,
    podcast_id integer
);


--
-- Name: podcasts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE podcasts (
    id integer NOT NULL,
    title character varying(255),
    website character varying(255),
    description text,
    summary text,
    image_title character varying(255),
    image_url character varying(255),
    last_build_date timestamp without time zone,
    payment_link_title character varying(255),
    payment_link_url character varying(255),
    author character varying(255),
    explicit boolean DEFAULT false,
    unique_identifier uuid,
    owner_id integer,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: podcasts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE podcasts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: podcasts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE podcasts_id_seq OWNED BY podcasts.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp without time zone
);


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE subscriptions (
    user_id integer,
    podcast_id integer
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    username character varying(255) NOT NULL,
    password_hash character varying(255),
    email character varying(255) NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    admin boolean,
    podcaster boolean
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY alternate_feeds ALTER COLUMN id SET DEFAULT nextval('alternate_feeds_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY categories ALTER COLUMN id SET DEFAULT nextval('categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY chapters ALTER COLUMN id SET DEFAULT nextval('chapters_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY contributors ALTER COLUMN id SET DEFAULT nextval('contributors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY enclosures ALTER COLUMN id SET DEFAULT nextval('enclosures_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY episodes ALTER COLUMN id SET DEFAULT nextval('episodes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY feeds ALTER COLUMN id SET DEFAULT nextval('feeds_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY languages ALTER COLUMN id SET DEFAULT nextval('languages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY podcasts ALTER COLUMN id SET DEFAULT nextval('podcasts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: alternate_feeds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY alternate_feeds
    ADD CONSTRAINT alternate_feeds_pkey PRIMARY KEY (id);


--
-- Name: categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: chapters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY chapters
    ADD CONSTRAINT chapters_pkey PRIMARY KEY (id);


--
-- Name: contributors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contributors
    ADD CONSTRAINT contributors_pkey PRIMARY KEY (id);


--
-- Name: enclosures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY enclosures
    ADD CONSTRAINT enclosures_pkey PRIMARY KEY (id);


--
-- Name: episodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY episodes
    ADD CONSTRAINT episodes_pkey PRIMARY KEY (id);


--
-- Name: feeds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY feeds
    ADD CONSTRAINT feeds_pkey PRIMARY KEY (id);


--
-- Name: languages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY languages
    ADD CONSTRAINT languages_pkey PRIMARY KEY (id);


--
-- Name: podcasts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY podcasts
    ADD CONSTRAINT podcasts_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: alternate_feeds_feed_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX alternate_feeds_feed_id_index ON alternate_feeds USING btree (feed_id);


--
-- Name: categories_parent_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX categories_parent_id_index ON categories USING btree (parent_id);


--
-- Name: chapters_episode_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chapters_episode_id_index ON chapters USING btree (episode_id);


--
-- Name: contributors_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX contributors_user_id_index ON contributors USING btree (user_id);


--
-- Name: enclosures_episode_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX enclosures_episode_id_index ON enclosures USING btree (episode_id);


--
-- Name: episodes_guid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX episodes_guid_index ON episodes USING btree (guid);


--
-- Name: episodes_podcast_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX episodes_podcast_id_index ON episodes USING btree (podcast_id);


--
-- Name: feeds_podcast_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX feeds_podcast_id_index ON feeds USING btree (podcast_id);


--
-- Name: languages_shortcode_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX languages_shortcode_index ON languages USING btree (shortcode);


--
-- Name: podcasts_owner_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX podcasts_owner_id_index ON podcasts USING btree (owner_id);


--
-- Name: podcasts_title_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX podcasts_title_index ON podcasts USING btree (title);


--
-- Name: podcasts_website_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX podcasts_website_index ON podcasts USING btree (website);


--
-- Name: users_username_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_username_index ON users USING btree (username);


--
-- Name: alternate_feeds_feed_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY alternate_feeds
    ADD CONSTRAINT alternate_feeds_feed_id_fkey FOREIGN KEY (feed_id) REFERENCES feeds(id);


--
-- Name: categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY categories
    ADD CONSTRAINT categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES categories(id);


--
-- Name: categories_podcasts_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY categories_podcasts
    ADD CONSTRAINT categories_podcasts_category_id_fkey FOREIGN KEY (category_id) REFERENCES categories(id);


--
-- Name: categories_podcasts_podcast_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY categories_podcasts
    ADD CONSTRAINT categories_podcasts_podcast_id_fkey FOREIGN KEY (podcast_id) REFERENCES podcasts(id);


--
-- Name: chapters_episode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY chapters
    ADD CONSTRAINT chapters_episode_id_fkey FOREIGN KEY (episode_id) REFERENCES episodes(id);


--
-- Name: contributors_episodes_contributor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contributors_episodes
    ADD CONSTRAINT contributors_episodes_contributor_id_fkey FOREIGN KEY (contributor_id) REFERENCES contributors(id);


--
-- Name: contributors_episodes_episode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contributors_episodes
    ADD CONSTRAINT contributors_episodes_episode_id_fkey FOREIGN KEY (episode_id) REFERENCES episodes(id);


--
-- Name: contributors_podcasts_contributor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contributors_podcasts
    ADD CONSTRAINT contributors_podcasts_contributor_id_fkey FOREIGN KEY (contributor_id) REFERENCES contributors(id);


--
-- Name: contributors_podcasts_podcast_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contributors_podcasts
    ADD CONSTRAINT contributors_podcasts_podcast_id_fkey FOREIGN KEY (podcast_id) REFERENCES podcasts(id);


--
-- Name: contributors_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contributors
    ADD CONSTRAINT contributors_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: enclosures_episode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY enclosures
    ADD CONSTRAINT enclosures_episode_id_fkey FOREIGN KEY (episode_id) REFERENCES episodes(id);


--
-- Name: episodes_podcast_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY episodes
    ADD CONSTRAINT episodes_podcast_id_fkey FOREIGN KEY (podcast_id) REFERENCES podcasts(id);


--
-- Name: feeds_podcast_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY feeds
    ADD CONSTRAINT feeds_podcast_id_fkey FOREIGN KEY (podcast_id) REFERENCES podcasts(id);


--
-- Name: followers_podcasts_podcast_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY followers_podcasts
    ADD CONSTRAINT followers_podcasts_podcast_id_fkey FOREIGN KEY (podcast_id) REFERENCES podcasts(id);


--
-- Name: followers_podcasts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY followers_podcasts
    ADD CONSTRAINT followers_podcasts_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: followers_users_follower_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY followers_users
    ADD CONSTRAINT followers_users_follower_id_fkey FOREIGN KEY (follower_id) REFERENCES users(id);


--
-- Name: followers_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY followers_users
    ADD CONSTRAINT followers_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: languages_podcasts_language_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY languages_podcasts
    ADD CONSTRAINT languages_podcasts_language_id_fkey FOREIGN KEY (language_id) REFERENCES languages(id);


--
-- Name: languages_podcasts_podcast_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY languages_podcasts
    ADD CONSTRAINT languages_podcasts_podcast_id_fkey FOREIGN KEY (podcast_id) REFERENCES podcasts(id);


--
-- Name: podcasts_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY podcasts
    ADD CONSTRAINT podcasts_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES users(id);


--
-- Name: subscriptions_podcast_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscriptions
    ADD CONSTRAINT subscriptions_podcast_id_fkey FOREIGN KEY (podcast_id) REFERENCES podcasts(id);


--
-- Name: subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscriptions
    ADD CONSTRAINT subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- PostgreSQL database dump complete
--

INSERT INTO "schema_migrations" (version) VALUES (20160913115145), (20160914124011), (20160914133217), (20160914135959), (20160914140359), (20160914140759), (20160914141231), (20160914141352), (20160914141504), (20160914141851), (20160914142816), (20160915080727), (20160915081012), (20160915082024), (20160915083315), (20160915084830), (20160919125620), (20161021092108), (20161021092109);

