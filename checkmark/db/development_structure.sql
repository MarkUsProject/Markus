--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: -
--

CREATE PROCEDURAL LANGUAGE plpgsql;


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: annotation_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE annotation_categories (
    id integer NOT NULL,
    name text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: annotation_labels; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE annotation_labels (
    id integer NOT NULL,
    name text,
    content text,
    annotation_category_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: annotations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE annotations (
    id integer NOT NULL,
    pos_start integer,
    pos_end integer,
    line_start integer,
    line_end integer,
    annotation_label_id integer,
    submission_file_id integer
);


--
-- Name: assignment_files; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE assignment_files (
    id integer NOT NULL,
    assignment_id integer,
    filename character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: assignments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE assignments (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255),
    message text,
    due_date timestamp without time zone,
    group_min integer DEFAULT 1 NOT NULL,
    group_max integer DEFAULT 1 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    student_form_groups boolean,
    student_invite_until timestamp without time zone
);


--
-- Name: assignments_groups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE assignments_groups (
    group_id integer,
    assignment_id integer,
    status character varying(255)
);


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE categories (
    id integer NOT NULL,
    name text,
    token text,
    ntoken integer
);


--
-- Name: descriptions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE descriptions (
    id integer NOT NULL,
    name text,
    description text,
    token text,
    ntoken integer,
    category_id integer,
    assignment_id integer
);


--
-- Name: grades; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE grades (
    id integer NOT NULL,
    user_id integer,
    group_id integer,
    assignment_id integer,
    grade integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    status character varying(255)
);


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE groups (
    id integer NOT NULL,
    status character varying(255),
    name text
);


--
-- Name: memberships; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE memberships (
    id integer NOT NULL,
    user_id integer,
    group_id integer,
    status character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: rubric_criterias; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE rubric_criterias (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    assignment_id integer NOT NULL,
    weight numeric NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    "position" integer,
    level_0_name text,
    level_0_description text,
    level_1_name text,
    level_1_description text,
    level_2_name text,
    level_2_description text,
    level_3_name text,
    level_3_description text,
    level_4_name text,
    level_4_description text
);


--
-- Name: rubric_levels; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE rubric_levels (
    id integer NOT NULL,
    rubric_criteria_id integer NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    level integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sessions (
    id integer NOT NULL,
    session_id character varying(255) NOT NULL,
    data text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: submission_files; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE submission_files (
    id integer NOT NULL,
    user_id integer,
    submission_id integer,
    filename character varying(255),
    submitted_at timestamp without time zone,
    status character varying(255)
);


--
-- Name: submission_rules; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE submission_rules (
    id integer NOT NULL,
    assignment_id integer NOT NULL,
    allow_submit_until integer DEFAULT 0,
    type character varying(255) DEFAULT 'NullSubmissionRule'::character varying,
    grace_day_limit integer,
    penalty_limit integer,
    penalty_increment integer,
    penalty_interval integer,
    penalty_interval_unit character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: submissions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE submissions (
    id integer NOT NULL,
    user_id integer,
    group_id integer,
    assignment_id integer
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    user_name character varying(255) NOT NULL,
    user_number character varying(255),
    last_name character varying(255),
    first_name character varying(255),
    grace_days integer,
    role character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: annotation_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE annotation_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: annotation_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE annotation_categories_id_seq OWNED BY annotation_categories.id;


--
-- Name: annotation_labels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE annotation_labels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: annotation_labels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE annotation_labels_id_seq OWNED BY annotation_labels.id;


--
-- Name: annotations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE annotations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: annotations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE annotations_id_seq OWNED BY annotations.id;


--
-- Name: assignment_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE assignment_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: assignment_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE assignment_files_id_seq OWNED BY assignment_files.id;


--
-- Name: assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE assignments_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE assignments_id_seq OWNED BY assignments.id;


--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE categories_id_seq OWNED BY categories.id;


--
-- Name: descriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE descriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: descriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE descriptions_id_seq OWNED BY descriptions.id;


--
-- Name: grades_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE grades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: grades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE grades_id_seq OWNED BY grades.id;


--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE groups_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE groups_id_seq OWNED BY groups.id;


--
-- Name: memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE memberships_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE memberships_id_seq OWNED BY memberships.id;


--
-- Name: rubric_criterias_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE rubric_criterias_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: rubric_criterias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE rubric_criterias_id_seq OWNED BY rubric_criterias.id;


--
-- Name: rubric_levels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE rubric_levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: rubric_levels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE rubric_levels_id_seq OWNED BY rubric_levels.id;


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sessions_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sessions_id_seq OWNED BY sessions.id;


--
-- Name: submission_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE submission_files_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: submission_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE submission_files_id_seq OWNED BY submission_files.id;


--
-- Name: submission_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE submission_rules_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: submission_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE submission_rules_id_seq OWNED BY submission_rules.id;


--
-- Name: submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE submissions_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE submissions_id_seq OWNED BY submissions.id;


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE annotation_categories ALTER COLUMN id SET DEFAULT nextval('annotation_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE annotation_labels ALTER COLUMN id SET DEFAULT nextval('annotation_labels_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE annotations ALTER COLUMN id SET DEFAULT nextval('annotations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE assignment_files ALTER COLUMN id SET DEFAULT nextval('assignment_files_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE assignments ALTER COLUMN id SET DEFAULT nextval('assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE categories ALTER COLUMN id SET DEFAULT nextval('categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE descriptions ALTER COLUMN id SET DEFAULT nextval('descriptions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE grades ALTER COLUMN id SET DEFAULT nextval('grades_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE groups ALTER COLUMN id SET DEFAULT nextval('groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE memberships ALTER COLUMN id SET DEFAULT nextval('memberships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE rubric_criterias ALTER COLUMN id SET DEFAULT nextval('rubric_criterias_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE rubric_levels ALTER COLUMN id SET DEFAULT nextval('rubric_levels_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE sessions ALTER COLUMN id SET DEFAULT nextval('sessions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE submission_files ALTER COLUMN id SET DEFAULT nextval('submission_files_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE submission_rules ALTER COLUMN id SET DEFAULT nextval('submission_rules_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE submissions ALTER COLUMN id SET DEFAULT nextval('submissions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: annotation_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY annotation_categories
    ADD CONSTRAINT annotation_categories_pkey PRIMARY KEY (id);


--
-- Name: annotation_labels_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY annotation_labels
    ADD CONSTRAINT annotation_labels_pkey PRIMARY KEY (id);


--
-- Name: annotations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY annotations
    ADD CONSTRAINT annotations_pkey PRIMARY KEY (id);


--
-- Name: assignment_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY assignment_files
    ADD CONSTRAINT assignment_files_pkey PRIMARY KEY (id);


--
-- Name: assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY assignments
    ADD CONSTRAINT assignments_pkey PRIMARY KEY (id);


--
-- Name: categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: descriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY descriptions
    ADD CONSTRAINT descriptions_pkey PRIMARY KEY (id);


--
-- Name: grades_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY grades
    ADD CONSTRAINT grades_pkey PRIMARY KEY (id);


--
-- Name: groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY memberships
    ADD CONSTRAINT memberships_pkey PRIMARY KEY (id);


--
-- Name: rubric_criterias_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY rubric_criterias
    ADD CONSTRAINT rubric_criterias_pkey PRIMARY KEY (id);


--
-- Name: rubric_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY rubric_levels
    ADD CONSTRAINT rubric_levels_pkey PRIMARY KEY (id);


--
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: submission_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY submission_files
    ADD CONSTRAINT submission_files_pkey PRIMARY KEY (id);


--
-- Name: submission_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY submission_rules
    ADD CONSTRAINT submission_rules_pkey PRIMARY KEY (id);


--
-- Name: submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY submissions
    ADD CONSTRAINT submissions_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_annotations_on_assignmentfile_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_annotations_on_assignmentfile_id ON annotations USING btree (submission_file_id);


--
-- Name: index_annotations_on_description_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_annotations_on_description_id ON annotations USING btree (annotation_label_id);


--
-- Name: index_annotations_on_submission_file_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_annotations_on_submission_file_id ON annotations USING btree (submission_file_id);


--
-- Name: index_assignment_files_on_assignment_id_and_filename; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_assignment_files_on_assignment_id_and_filename ON assignment_files USING btree (assignment_id, filename);


--
-- Name: index_assignments_groups_on_group_id_and_assignment_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_assignments_groups_on_group_id_and_assignment_id ON assignments_groups USING btree (group_id, assignment_id);


--
-- Name: index_assignments_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_assignments_on_name ON assignments USING btree (name);


--
-- Name: index_descriptions_on_assignment_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_descriptions_on_assignment_id ON descriptions USING btree (assignment_id);


--
-- Name: index_descriptions_on_category_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_descriptions_on_category_id ON descriptions USING btree (category_id);


--
-- Name: index_memberships_on_user_id_and_group_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_memberships_on_user_id_and_group_id ON memberships USING btree (user_id, group_id);


--
-- Name: index_rubric_criterias_on_assignment_id_and_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_rubric_criterias_on_assignment_id_and_name ON rubric_criterias USING btree (assignment_id, name);


--
-- Name: index_sessions_on_session_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sessions_on_session_id ON sessions USING btree (session_id);


--
-- Name: index_sessions_on_updated_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sessions_on_updated_at ON sessions USING btree (updated_at);


--
-- Name: index_submission_files_on_filename; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_submission_files_on_filename ON submission_files USING btree (filename);


--
-- Name: index_submission_files_on_submission_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_submission_files_on_submission_id ON submission_files USING btree (submission_id);


--
-- Name: index_users_on_user_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_user_name ON users USING btree (user_name);


--
-- Name: index_users_on_user_number; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_user_number ON users USING btree (user_number);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: fk_annotation_labels_annotation_categories; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY annotation_labels
    ADD CONSTRAINT fk_annotation_labels_annotation_categories FOREIGN KEY (annotation_category_id) REFERENCES annotation_categories(id) ON DELETE CASCADE;


--
-- Name: fk_annotations_annotation_labels; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY annotations
    ADD CONSTRAINT fk_annotations_annotation_labels FOREIGN KEY (annotation_label_id) REFERENCES annotation_labels(id);


--
-- Name: fk_annotations_submission_files; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY annotations
    ADD CONSTRAINT fk_annotations_submission_files FOREIGN KEY (submission_file_id) REFERENCES submission_files(id);


--
-- Name: fk_assignment_files_assignments; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignment_files
    ADD CONSTRAINT fk_assignment_files_assignments FOREIGN KEY (assignment_id) REFERENCES assignments(id) ON DELETE CASCADE;


--
-- Name: fk_assignments_groups_assignments; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignments_groups
    ADD CONSTRAINT fk_assignments_groups_assignments FOREIGN KEY (assignment_id) REFERENCES assignments(id);


--
-- Name: fk_assignments_groups_groups; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignments_groups
    ADD CONSTRAINT fk_assignments_groups_groups FOREIGN KEY (group_id) REFERENCES groups(id);


--
-- Name: fk_descriptions_assignments; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY descriptions
    ADD CONSTRAINT fk_descriptions_assignments FOREIGN KEY (assignment_id) REFERENCES assignments(id);


--
-- Name: fk_descriptions_categories; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY descriptions
    ADD CONSTRAINT fk_descriptions_categories FOREIGN KEY (category_id) REFERENCES categories(id);


--
-- Name: fk_memberships_groups; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY memberships
    ADD CONSTRAINT fk_memberships_groups FOREIGN KEY (group_id) REFERENCES groups(id);


--
-- Name: fk_memberships_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY memberships
    ADD CONSTRAINT fk_memberships_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rubric_criterias_assignments; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY rubric_criterias
    ADD CONSTRAINT fk_rubric_criterias_assignments FOREIGN KEY (assignment_id) REFERENCES assignments(id) ON DELETE CASCADE;


--
-- Name: fk_rubric_levels_rubric_criterias; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY rubric_levels
    ADD CONSTRAINT fk_rubric_levels_rubric_criterias FOREIGN KEY (rubric_criteria_id) REFERENCES rubric_criterias(id) ON DELETE CASCADE;


--
-- Name: fk_submission_files_submissions; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY submission_files
    ADD CONSTRAINT fk_submission_files_submissions FOREIGN KEY (submission_id) REFERENCES submissions(id);


--
-- Name: fk_submission_files_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY submission_files
    ADD CONSTRAINT fk_submission_files_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_submission_rules_assignments; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY submission_rules
    ADD CONSTRAINT fk_submission_rules_assignments FOREIGN KEY (assignment_id) REFERENCES assignments(id) ON DELETE CASCADE;


--
-- Name: fk_submissions_assignments; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY submissions
    ADD CONSTRAINT fk_submissions_assignments FOREIGN KEY (assignment_id) REFERENCES assignments(id);


--
-- Name: fk_submissions_groups; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY submissions
    ADD CONSTRAINT fk_submissions_groups FOREIGN KEY (group_id) REFERENCES groups(id);


--
-- Name: fk_submissions_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY submissions
    ADD CONSTRAINT fk_submissions_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- PostgreSQL database dump complete
--

INSERT INTO schema_migrations (version) VALUES ('20080729160237');

INSERT INTO schema_migrations (version) VALUES ('20080729162213');

INSERT INTO schema_migrations (version) VALUES ('20080729162322');

INSERT INTO schema_migrations (version) VALUES ('20080806143028');

INSERT INTO schema_migrations (version) VALUES ('20080812143621');

INSERT INTO schema_migrations (version) VALUES ('20080812143641');

INSERT INTO schema_migrations (version) VALUES ('20080927052808');

INSERT INTO schema_migrations (version) VALUES ('20081001150504');

INSERT INTO schema_migrations (version) VALUES ('20081001150627');

INSERT INTO schema_migrations (version) VALUES ('20081001171713');

INSERT INTO schema_migrations (version) VALUES ('20081009115817');

INSERT INTO schema_migrations (version) VALUES ('20081009204628');

INSERT INTO schema_migrations (version) VALUES ('20081009204639');

INSERT INTO schema_migrations (version) VALUES ('20081009204730');

INSERT INTO schema_migrations (version) VALUES ('20081009204739');

INSERT INTO schema_migrations (version) VALUES ('20081009204754');

INSERT INTO schema_migrations (version) VALUES ('20081126183411');

INSERT INTO schema_migrations (version) VALUES ('20081126200403');

INSERT INTO schema_migrations (version) VALUES ('20081130222245');

INSERT INTO schema_migrations (version) VALUES ('20081130222302');

INSERT INTO schema_migrations (version) VALUES ('20090116054833');

INSERT INTO schema_migrations (version) VALUES ('20090116055742');

INSERT INTO schema_migrations (version) VALUES ('20090116063343');

INSERT INTO schema_migrations (version) VALUES ('20090122190852');

INSERT INTO schema_migrations (version) VALUES ('20090128224245');

INSERT INTO schema_migrations (version) VALUES ('20090203023227');

INSERT INTO schema_migrations (version) VALUES ('20090206022047');

INSERT INTO schema_migrations (version) VALUES ('20090211221709');