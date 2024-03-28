SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: check_repo_permissions(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_repo_permissions(user_name_ character varying, course_name character varying, repo_name_ character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    role_type varchar;
    role_id_ integer;
BEGIN
    SELECT roles.id, roles.type
    INTO role_id_, role_type
    FROM users
        JOIN roles ON roles.user_id=users.id
        JOIN courses ON roles.course_id=courses.id
    WHERE courses.name=course_name AND users.user_name=user_name_ AND roles.hidden=false
        FETCH FIRST ROW ONLY;

    IF role_type IN ('Instructor', 'AdminRole') THEN
        RETURN true;
    END IF;
    IF role_type = 'Ta' THEN
        RETURN EXISTS(
                SELECT 1
                FROM memberships
                    JOIN roles ON roles.id = memberships.role_id
                    JOIN groupings ON memberships.grouping_id = groupings.id
                    JOIN groups ON groupings.group_id = groups.id
                    JOIN assignment_properties ON assignment_properties.assessment_id = groupings.assessment_id
                WHERE memberships.type = 'TaMembership'
                  AND assignment_properties.anonymize_groups = false
                  AND roles.id = role_id_
                  AND groups.repo_name = repo_name_
            );
    END IF;
    IF role_type = 'Student' THEN
        RETURN EXISTS(
                SELECT roles.id
                FROM memberships
                    JOIN roles ON roles.id=memberships.role_id
                    JOIN groupings ON memberships.grouping_id=groupings.id
                    JOIN groups ON groupings.group_id=groups.id
                    JOIN assignment_properties ON assignment_properties.assessment_id=groupings.assessment_id
                    JOIN assessments ON groupings.assessment_id=assessments.id
                    JOIN courses ON assessments.course_id=courses.id
                    LEFT OUTER JOIN assessment_section_properties ON assessment_section_properties.assessment_id=assessments.id
                WHERE memberships.type='StudentMembership'
                  AND memberships.membership_status IN ('inviter','accepted')
                  AND assignment_properties.vcs_submit=true
                  AND roles.id=role_id_
                  AND courses.is_hidden=false
                  AND groups.repo_name=repo_name_
                  AND ((assessment_section_properties.is_hidden IS NULL AND assessments.is_hidden=false)
                           OR assessment_section_properties.is_hidden=false)
                  AND (assignment_properties.is_timed=false
                           OR groupings.start_time IS NOT NULL
                           OR (groupings.start_time IS NULL AND assessments.due_date<NOW()))
            );
    END IF;
    RETURN false;
END
$$;


--
-- Name: database_identifier(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.database_identifier() RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$SELECT CONCAT((SELECT system_identifier FROM pg_control_system()), '-', (SELECT current_database FROM current_database()));$$;


--
-- Name: get_authorized_keys(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_authorized_keys() RETURNS TABLE(authorized_keys text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  instance text;
BEGIN
  SELECT INTO instance database_identifier();
  RETURN QUERY SELECT CONCAT(
                'command="LOGIN_USER=',
                users.user_name,
                ' INSTANCE=',
                instance,
                ' markus-git-shell.sh",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ',
                key_pairs.public_key)
  FROM key_pairs JOIN users ON key_pairs.user_id = users.id;
END
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: annotation_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.annotation_categories (
    id integer NOT NULL,
    annotation_category_name text,
    "position" integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    assessment_id bigint NOT NULL,
    flexible_criterion_id bigint
);


--
-- Name: annotation_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.annotation_categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: annotation_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.annotation_categories_id_seq OWNED BY public.annotation_categories.id;


--
-- Name: annotation_texts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.annotation_texts (
    id integer NOT NULL,
    content text,
    annotation_category_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    creator_id integer,
    last_editor_id integer,
    deduction double precision
);


--
-- Name: annotation_texts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.annotation_texts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: annotation_texts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.annotation_texts_id_seq OWNED BY public.annotation_texts.id;


--
-- Name: annotations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.annotations (
    id integer NOT NULL,
    line_start integer,
    line_end integer,
    annotation_text_id integer,
    submission_file_id integer,
    x1 integer,
    x2 integer,
    y1 integer,
    y2 integer,
    type character varying,
    annotation_number integer,
    is_remark boolean DEFAULT false NOT NULL,
    page integer,
    column_start integer,
    column_end integer,
    creator_type character varying,
    creator_id integer,
    result_id integer,
    start_node character varying,
    end_node character varying,
    start_offset integer,
    end_offset integer
);


--
-- Name: annotations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.annotations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: annotations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.annotations_id_seq OWNED BY public.annotations.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: assessment_section_properties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assessment_section_properties (
    id integer NOT NULL,
    due_date timestamp without time zone,
    section_id integer,
    assessment_id bigint,
    start_time timestamp without time zone,
    is_hidden boolean
);


--
-- Name: assessment_section_properties_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assessment_section_properties_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assessment_section_properties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assessment_section_properties_id_seq OWNED BY public.assessment_section_properties.id;


--
-- Name: assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assessments (
    id integer NOT NULL,
    short_identifier character varying NOT NULL,
    type character varying NOT NULL,
    description character varying NOT NULL,
    message text DEFAULT ''::text NOT NULL,
    due_date timestamp without time zone,
    is_hidden boolean DEFAULT true NOT NULL,
    show_total boolean DEFAULT false NOT NULL,
    parent_assessment_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    course_id bigint NOT NULL
);


--
-- Name: assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assessments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assessments_id_seq OWNED BY public.assessments.id;


--
-- Name: assignment_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assignment_files (
    id integer NOT NULL,
    filename character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    assessment_id bigint
);


--
-- Name: assignment_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assignment_files_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignment_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assignment_files_id_seq OWNED BY public.assignment_files.id;


--
-- Name: assignment_properties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assignment_properties (
    id integer NOT NULL,
    assessment_id bigint,
    group_min integer DEFAULT 1 NOT NULL,
    group_max integer DEFAULT 1 NOT NULL,
    student_form_groups boolean DEFAULT false NOT NULL,
    group_name_autogenerated boolean DEFAULT true NOT NULL,
    repository_folder character varying NOT NULL,
    allow_web_submits boolean DEFAULT true NOT NULL,
    section_groups_only boolean DEFAULT false NOT NULL,
    section_due_dates_type boolean DEFAULT false NOT NULL,
    display_grader_names_to_students boolean DEFAULT false NOT NULL,
    enable_test boolean DEFAULT false NOT NULL,
    assign_graders_to_criteria boolean DEFAULT false NOT NULL,
    tokens_per_period integer DEFAULT 0 NOT NULL,
    allow_remarks boolean DEFAULT false NOT NULL,
    remark_due_date timestamp without time zone,
    remark_message text,
    unlimited_tokens boolean DEFAULT false NOT NULL,
    only_required_files boolean DEFAULT false NOT NULL,
    vcs_submit boolean DEFAULT false NOT NULL,
    token_start_date timestamp without time zone,
    token_period double precision,
    has_peer_review boolean DEFAULT false NOT NULL,
    enable_student_tests boolean DEFAULT false NOT NULL,
    non_regenerating_tokens boolean DEFAULT false NOT NULL,
    scanned_exam boolean DEFAULT false NOT NULL,
    display_median_to_students boolean DEFAULT false NOT NULL,
    anonymize_groups boolean DEFAULT false NOT NULL,
    hide_unassigned_criteria boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    duration interval,
    start_time timestamp without time zone,
    is_timed boolean DEFAULT false NOT NULL,
    starter_file_type character varying DEFAULT 'simple'::character varying NOT NULL,
    starter_file_updated_at timestamp without time zone,
    default_starter_file_group_id bigint,
    remote_autotest_settings_id integer,
    starter_files_after_due boolean DEFAULT true NOT NULL,
    url_submit boolean DEFAULT false NOT NULL,
    autotest_settings json,
    api_submit boolean DEFAULT false NOT NULL,
    release_with_urls boolean DEFAULT false NOT NULL,
    token_end_date timestamp(6) without time zone
);


--
-- Name: assignment_properties_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assignment_properties_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignment_properties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assignment_properties_id_seq OWNED BY public.assignment_properties.id;


--
-- Name: autotest_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.autotest_settings (
    id bigint NOT NULL,
    url character varying NOT NULL,
    api_key character varying NOT NULL,
    schema character varying NOT NULL
);


--
-- Name: autotest_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.autotest_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: autotest_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.autotest_settings_id_seq OWNED BY public.autotest_settings.id;


--
-- Name: courses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.courses (
    id bigint NOT NULL,
    name character varying NOT NULL,
    is_hidden boolean DEFAULT true NOT NULL,
    display_name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    autotest_setting_id bigint,
    max_file_size bigint DEFAULT 5000000 NOT NULL
);


--
-- Name: courses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.courses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: courses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.courses_id_seq OWNED BY public.courses.id;


--
-- Name: criteria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.criteria (
    id bigint NOT NULL,
    name character varying NOT NULL,
    type character varying NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    "position" integer NOT NULL,
    max_mark numeric(10,1) NOT NULL,
    assigned_groups_count integer DEFAULT 0 NOT NULL,
    ta_visible boolean DEFAULT true NOT NULL,
    peer_visible boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    assessment_id bigint NOT NULL,
    bonus boolean DEFAULT false NOT NULL
);


--
-- Name: criteria_assignment_files_joins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.criteria_assignment_files_joins (
    id integer NOT NULL,
    criterion_id integer NOT NULL,
    assignment_file_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: criteria_assignment_files_joins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.criteria_assignment_files_joins_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: criteria_assignment_files_joins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.criteria_assignment_files_joins_id_seq OWNED BY public.criteria_assignment_files_joins.id;


--
-- Name: criteria_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.criteria_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: criteria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.criteria_id_seq OWNED BY public.criteria.id;


--
-- Name: criterion_ta_associations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.criterion_ta_associations (
    id integer NOT NULL,
    ta_id integer,
    criterion_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    assessment_id bigint
);


--
-- Name: criterion_ta_associations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.criterion_ta_associations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: criterion_ta_associations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.criterion_ta_associations_id_seq OWNED BY public.criterion_ta_associations.id;


--
-- Name: exam_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_templates (
    id integer NOT NULL,
    filename character varying NOT NULL,
    num_pages integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    name character varying NOT NULL,
    cover_fields character varying DEFAULT ''::character varying NOT NULL,
    automatic_parsing boolean DEFAULT false NOT NULL,
    crop_x numeric,
    crop_y numeric,
    crop_width numeric,
    crop_height numeric,
    assessment_id bigint
);


--
-- Name: exam_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exam_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exam_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exam_templates_id_seq OWNED BY public.exam_templates.id;


--
-- Name: extensions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.extensions (
    id bigint NOT NULL,
    time_delta interval NOT NULL,
    apply_penalty boolean DEFAULT false NOT NULL,
    grouping_id bigint NOT NULL,
    note character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: extensions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.extensions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: extensions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.extensions_id_seq OWNED BY public.extensions.id;


--
-- Name: extra_marks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.extra_marks (
    id integer NOT NULL,
    result_id integer,
    description character varying,
    extra_mark double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    unit character varying
);


--
-- Name: extra_marks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.extra_marks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: extra_marks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.extra_marks_id_seq OWNED BY public.extra_marks.id;


--
-- Name: feedback_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feedback_files (
    id integer NOT NULL,
    filename character varying NOT NULL,
    file_content bytea NOT NULL,
    mime_type character varying NOT NULL,
    submission_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    test_group_result_id bigint
);


--
-- Name: feedback_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feedback_files_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feedback_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feedback_files_id_seq OWNED BY public.feedback_files.id;


--
-- Name: grace_period_deductions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grace_period_deductions (
    id integer NOT NULL,
    membership_id integer,
    deduction integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: grace_period_deductions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.grace_period_deductions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: grace_period_deductions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.grace_period_deductions_id_seq OWNED BY public.grace_period_deductions.id;


--
-- Name: grade_entry_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grade_entry_items (
    id integer NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    out_of double precision,
    "position" integer,
    bonus boolean DEFAULT false NOT NULL,
    assessment_id bigint
);


--
-- Name: grade_entry_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.grade_entry_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: grade_entry_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.grade_entry_items_id_seq OWNED BY public.grade_entry_items.id;


--
-- Name: grade_entry_students; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grade_entry_students (
    id integer NOT NULL,
    released_to_student boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    assessment_id bigint,
    role_id bigint NOT NULL
);


--
-- Name: grade_entry_students_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.grade_entry_students_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: grade_entry_students_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.grade_entry_students_id_seq OWNED BY public.grade_entry_students.id;


--
-- Name: grade_entry_students_tas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grade_entry_students_tas (
    grade_entry_student_id integer,
    ta_id integer,
    id integer NOT NULL
);


--
-- Name: grade_entry_students_tas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.grade_entry_students_tas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: grade_entry_students_tas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.grade_entry_students_tas_id_seq OWNED BY public.grade_entry_students_tas.id;


--
-- Name: grader_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grader_permissions (
    id bigint NOT NULL,
    manage_submissions boolean DEFAULT false NOT NULL,
    manage_assessments boolean DEFAULT false NOT NULL,
    run_tests boolean DEFAULT false NOT NULL,
    role_id bigint NOT NULL
);


--
-- Name: grader_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.grader_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: grader_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.grader_permissions_id_seq OWNED BY public.grader_permissions.id;


--
-- Name: grades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grades (
    id integer NOT NULL,
    grade_entry_item_id integer,
    grade_entry_student_id integer,
    grade double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: grades_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.grades_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: grades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.grades_id_seq OWNED BY public.grades.id;


--
-- Name: grouping_starter_file_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grouping_starter_file_entries (
    id bigint NOT NULL,
    grouping_id bigint NOT NULL,
    starter_file_entry_id bigint NOT NULL
);


--
-- Name: grouping_starter_file_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.grouping_starter_file_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: grouping_starter_file_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.grouping_starter_file_entries_id_seq OWNED BY public.grouping_starter_file_entries.id;


--
-- Name: groupings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groupings (
    id integer NOT NULL,
    group_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    instructor_approved boolean DEFAULT false NOT NULL,
    is_collected boolean DEFAULT false NOT NULL,
    criteria_coverage_count integer DEFAULT 0,
    test_tokens integer DEFAULT 0 NOT NULL,
    assessment_id bigint NOT NULL,
    start_time timestamp without time zone,
    starter_file_changed boolean DEFAULT false NOT NULL
);


--
-- Name: groupings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.groupings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groupings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.groupings_id_seq OWNED BY public.groupings.id;


--
-- Name: groupings_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groupings_tags (
    tag_id integer NOT NULL,
    grouping_id integer NOT NULL
);


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups (
    id integer NOT NULL,
    group_name character varying,
    repo_name character varying,
    course_id bigint NOT NULL
);


--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.groups_id_seq OWNED BY public.groups.id;


--
-- Name: job_messengers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.job_messengers (
    id integer NOT NULL,
    job_id character varying,
    status character varying,
    message character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: job_messengers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.job_messengers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: job_messengers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.job_messengers_id_seq OWNED BY public.job_messengers.id;


--
-- Name: key_pairs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.key_pairs (
    id integer NOT NULL,
    user_id integer,
    public_key character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: key_pairs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.key_pairs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: key_pairs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.key_pairs_id_seq OWNED BY public.key_pairs.id;


--
-- Name: levels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.levels (
    id bigint NOT NULL,
    criterion_id bigint NOT NULL,
    name character varying NOT NULL,
    description character varying NOT NULL,
    mark double precision NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: levels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: levels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.levels_id_seq OWNED BY public.levels.id;


--
-- Name: lti_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lti_clients (
    id bigint NOT NULL,
    client_id character varying NOT NULL,
    host character varying NOT NULL,
    course_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: lti_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lti_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lti_clients_id_seq OWNED BY public.lti_clients.id;


--
-- Name: lti_deployments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lti_deployments (
    id bigint NOT NULL,
    lti_client_id bigint NOT NULL,
    course_id bigint,
    external_deployment_id character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    lms_course_id integer NOT NULL,
    lms_course_name character varying NOT NULL
);


--
-- Name: lti_deployments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lti_deployments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_deployments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lti_deployments_id_seq OWNED BY public.lti_deployments.id;


--
-- Name: lti_line_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lti_line_items (
    id bigint NOT NULL,
    lti_line_item_id character varying NOT NULL,
    assessment_id bigint NOT NULL,
    lti_deployment_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: lti_line_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lti_line_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_line_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lti_line_items_id_seq OWNED BY public.lti_line_items.id;


--
-- Name: lti_services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lti_services (
    id bigint NOT NULL,
    lti_deployment_id bigint NOT NULL,
    service_type character varying NOT NULL,
    url character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: lti_services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lti_services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lti_services_id_seq OWNED BY public.lti_services.id;


--
-- Name: lti_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lti_users (
    id bigint NOT NULL,
    lti_client_id bigint NOT NULL,
    user_id bigint NOT NULL,
    lti_user_id character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: lti_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lti_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lti_users_id_seq OWNED BY public.lti_users.id;


--
-- Name: marking_schemes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marking_schemes (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    course_id bigint NOT NULL
);


--
-- Name: marking_schemes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.marking_schemes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: marking_schemes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.marking_schemes_id_seq OWNED BY public.marking_schemes.id;


--
-- Name: marking_weights; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marking_weights (
    id integer NOT NULL,
    marking_scheme_id integer,
    weight numeric,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    assessment_id bigint NOT NULL
);


--
-- Name: marking_weights_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.marking_weights_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: marking_weights_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.marking_weights_id_seq OWNED BY public.marking_weights.id;


--
-- Name: marks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marks (
    id integer NOT NULL,
    result_id integer,
    criterion_id integer,
    mark double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    override boolean DEFAULT false NOT NULL
);


--
-- Name: marks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.marks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: marks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.marks_id_seq OWNED BY public.marks.id;


--
-- Name: memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.memberships (
    id integer NOT NULL,
    membership_status character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    grouping_id integer NOT NULL,
    type character varying,
    role_id bigint NOT NULL
);


--
-- Name: memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.memberships_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.memberships_id_seq OWNED BY public.memberships.id;


--
-- Name: notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notes (
    id integer NOT NULL,
    notes_message text NOT NULL,
    creator_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    noteable_type character varying NOT NULL,
    noteable_id integer NOT NULL
);


--
-- Name: notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notes_id_seq OWNED BY public.notes.id;


--
-- Name: peer_reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.peer_reviews (
    id integer NOT NULL,
    result_id integer NOT NULL,
    reviewer_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: peer_reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.peer_reviews_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: peer_reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.peer_reviews_id_seq OWNED BY public.peer_reviews.id;


--
-- Name: periods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.periods (
    id integer NOT NULL,
    submission_rule_id integer,
    deduction double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    hours double precision,
    "interval" double precision,
    submission_rule_type character varying
);


--
-- Name: periods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.periods_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: periods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.periods_id_seq OWNED BY public.periods.id;


--
-- Name: results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.results (
    id integer NOT NULL,
    submission_id integer,
    marking_state character varying,
    overall_comment text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    released_to_students boolean DEFAULT false NOT NULL,
    remark_request_submitted_at timestamp without time zone,
    view_token character varying NOT NULL,
    view_token_expiry timestamp without time zone
);


--
-- Name: results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.results_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.results_id_seq OWNED BY public.results.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    course_id bigint NOT NULL,
    section_id bigint,
    type character varying NOT NULL,
    hidden boolean DEFAULT false NOT NULL,
    grace_credits integer DEFAULT 0 NOT NULL,
    receives_results_emails boolean DEFAULT false NOT NULL,
    receives_invite_emails boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: section_starter_file_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.section_starter_file_groups (
    id bigint NOT NULL,
    section_id bigint NOT NULL,
    starter_file_group_id bigint NOT NULL
);


--
-- Name: section_starter_file_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.section_starter_file_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: section_starter_file_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.section_starter_file_groups_id_seq OWNED BY public.section_starter_file_groups.id;


--
-- Name: sections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sections (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    course_id bigint NOT NULL
);


--
-- Name: sections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sections_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sections_id_seq OWNED BY public.sections.id;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id integer NOT NULL,
    session_id character varying NOT NULL,
    data text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sessions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.sessions.id;


--
-- Name: split_pages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.split_pages (
    id integer NOT NULL,
    raw_page_number integer,
    exam_page_number integer,
    filename character varying,
    status character varying,
    split_pdf_log_id integer,
    group_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: split_pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.split_pages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: split_pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.split_pages_id_seq OWNED BY public.split_pages.id;


--
-- Name: split_pdf_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.split_pdf_logs (
    id integer NOT NULL,
    uploaded_when timestamp without time zone,
    error_description character varying,
    filename character varying,
    num_groups_in_complete integer,
    num_groups_in_incomplete integer,
    num_pages_qr_scan_error integer,
    original_num_pages integer,
    qr_code_found boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    exam_template_id integer,
    role_id bigint NOT NULL
);


--
-- Name: split_pdf_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.split_pdf_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: split_pdf_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.split_pdf_logs_id_seq OWNED BY public.split_pdf_logs.id;


--
-- Name: starter_file_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.starter_file_entries (
    id bigint NOT NULL,
    starter_file_group_id bigint NOT NULL,
    path character varying NOT NULL
);


--
-- Name: starter_file_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.starter_file_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: starter_file_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.starter_file_entries_id_seq OWNED BY public.starter_file_entries.id;


--
-- Name: starter_file_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.starter_file_groups (
    id bigint NOT NULL,
    assessment_id bigint NOT NULL,
    entry_rename character varying DEFAULT ''::character varying NOT NULL,
    use_rename boolean DEFAULT false NOT NULL,
    name character varying NOT NULL
);


--
-- Name: starter_file_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.starter_file_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: starter_file_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.starter_file_groups_id_seq OWNED BY public.starter_file_groups.id;


--
-- Name: submission_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.submission_files (
    id integer NOT NULL,
    submission_id integer,
    filename character varying,
    path character varying DEFAULT '/'::character varying NOT NULL,
    is_converted boolean DEFAULT false NOT NULL,
    error_converting boolean DEFAULT false NOT NULL
);


--
-- Name: submission_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.submission_files_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: submission_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.submission_files_id_seq OWNED BY public.submission_files.id;


--
-- Name: submission_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.submission_rules (
    id integer NOT NULL,
    type character varying DEFAULT 'NoLateSubmissionRule'::character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    assessment_id bigint NOT NULL
);


--
-- Name: submission_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.submission_rules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: submission_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.submission_rules_id_seq OWNED BY public.submission_rules.id;


--
-- Name: submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.submissions (
    id integer NOT NULL,
    grouping_id integer,
    created_at timestamp without time zone,
    submission_version integer,
    submission_version_used boolean DEFAULT false NOT NULL,
    revision_identifier text,
    revision_timestamp timestamp without time zone,
    remark_request text,
    remark_request_timestamp timestamp without time zone,
    is_empty boolean DEFAULT true NOT NULL
);


--
-- Name: submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.submissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.submissions_id_seq OWNED BY public.submissions.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    id integer NOT NULL,
    name character varying NOT NULL,
    description character varying,
    assessment_id bigint,
    role_id bigint NOT NULL
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;


--
-- Name: template_divisions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.template_divisions (
    id integer NOT NULL,
    exam_template_id integer,
    start integer NOT NULL,
    "end" integer NOT NULL,
    label character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    assignment_file_id integer
);


--
-- Name: template_divisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.template_divisions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: template_divisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.template_divisions_id_seq OWNED BY public.template_divisions.id;


--
-- Name: test_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.test_batches (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    course_id bigint NOT NULL
);


--
-- Name: test_batches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.test_batches_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.test_batches_id_seq OWNED BY public.test_batches.id;


--
-- Name: test_group_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.test_group_results (
    id integer NOT NULL,
    test_group_id integer NOT NULL,
    marks_earned double precision DEFAULT 0.0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    "time" bigint NOT NULL,
    marks_total double precision DEFAULT 0.0 NOT NULL,
    test_run_id integer NOT NULL,
    extra_info text,
    error_type character varying
);


--
-- Name: test_group_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.test_group_results_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_group_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.test_group_results_id_seq OWNED BY public.test_group_results.id;


--
-- Name: test_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.test_groups (
    id integer NOT NULL,
    name text NOT NULL,
    display_output integer DEFAULT 0 NOT NULL,
    criterion_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    assessment_id bigint NOT NULL,
    autotest_settings json DEFAULT '{}'::json NOT NULL,
    "position" integer NOT NULL
);


--
-- Name: test_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.test_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.test_groups_id_seq OWNED BY public.test_groups.id;


--
-- Name: test_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.test_results (
    id integer NOT NULL,
    name text NOT NULL,
    status text NOT NULL,
    marks_earned double precision DEFAULT 0.0 NOT NULL,
    output text DEFAULT ''::text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    marks_total double precision DEFAULT 0.0 NOT NULL,
    "time" bigint,
    test_group_result_id bigint NOT NULL,
    "position" integer NOT NULL
);


--
-- Name: test_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.test_results_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.test_results_id_seq OWNED BY public.test_results.id;


--
-- Name: test_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.test_runs (
    id integer NOT NULL,
    test_batch_id integer,
    grouping_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    submission_id integer,
    revision_identifier text,
    problems text,
    autotest_test_id integer,
    status integer NOT NULL,
    role_id bigint NOT NULL
);


--
-- Name: test_runs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.test_runs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.test_runs_id_seq OWNED BY public.test_runs.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    user_name character varying NOT NULL,
    last_name character varying,
    first_name character varying,
    type character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    api_key character varying,
    email character varying,
    id_number character varying,
    display_name character varying NOT NULL,
    locale character varying DEFAULT 'en'::character varying NOT NULL,
    theme integer DEFAULT 1 NOT NULL,
    time_zone character varying NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: annotation_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.annotation_categories ALTER COLUMN id SET DEFAULT nextval('public.annotation_categories_id_seq'::regclass);


--
-- Name: annotation_texts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.annotation_texts ALTER COLUMN id SET DEFAULT nextval('public.annotation_texts_id_seq'::regclass);


--
-- Name: annotations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.annotations ALTER COLUMN id SET DEFAULT nextval('public.annotations_id_seq'::regclass);


--
-- Name: assessment_section_properties id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_section_properties ALTER COLUMN id SET DEFAULT nextval('public.assessment_section_properties_id_seq'::regclass);


--
-- Name: assessments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessments ALTER COLUMN id SET DEFAULT nextval('public.assessments_id_seq'::regclass);


--
-- Name: assignment_files id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_files ALTER COLUMN id SET DEFAULT nextval('public.assignment_files_id_seq'::regclass);


--
-- Name: assignment_properties id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_properties ALTER COLUMN id SET DEFAULT nextval('public.assignment_properties_id_seq'::regclass);


--
-- Name: autotest_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.autotest_settings ALTER COLUMN id SET DEFAULT nextval('public.autotest_settings_id_seq'::regclass);


--
-- Name: courses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses ALTER COLUMN id SET DEFAULT nextval('public.courses_id_seq'::regclass);


--
-- Name: criteria id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criteria ALTER COLUMN id SET DEFAULT nextval('public.criteria_id_seq'::regclass);


--
-- Name: criteria_assignment_files_joins id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criteria_assignment_files_joins ALTER COLUMN id SET DEFAULT nextval('public.criteria_assignment_files_joins_id_seq'::regclass);


--
-- Name: criterion_ta_associations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criterion_ta_associations ALTER COLUMN id SET DEFAULT nextval('public.criterion_ta_associations_id_seq'::regclass);


--
-- Name: exam_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_templates ALTER COLUMN id SET DEFAULT nextval('public.exam_templates_id_seq'::regclass);


--
-- Name: extensions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extensions ALTER COLUMN id SET DEFAULT nextval('public.extensions_id_seq'::regclass);


--
-- Name: extra_marks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extra_marks ALTER COLUMN id SET DEFAULT nextval('public.extra_marks_id_seq'::regclass);


--
-- Name: feedback_files id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_files ALTER COLUMN id SET DEFAULT nextval('public.feedback_files_id_seq'::regclass);


--
-- Name: grace_period_deductions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grace_period_deductions ALTER COLUMN id SET DEFAULT nextval('public.grace_period_deductions_id_seq'::regclass);


--
-- Name: grade_entry_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grade_entry_items ALTER COLUMN id SET DEFAULT nextval('public.grade_entry_items_id_seq'::regclass);


--
-- Name: grade_entry_students id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grade_entry_students ALTER COLUMN id SET DEFAULT nextval('public.grade_entry_students_id_seq'::regclass);


--
-- Name: grade_entry_students_tas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grade_entry_students_tas ALTER COLUMN id SET DEFAULT nextval('public.grade_entry_students_tas_id_seq'::regclass);


--
-- Name: grader_permissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grader_permissions ALTER COLUMN id SET DEFAULT nextval('public.grader_permissions_id_seq'::regclass);


--
-- Name: grades id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grades ALTER COLUMN id SET DEFAULT nextval('public.grades_id_seq'::regclass);


--
-- Name: grouping_starter_file_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grouping_starter_file_entries ALTER COLUMN id SET DEFAULT nextval('public.grouping_starter_file_entries_id_seq'::regclass);


--
-- Name: groupings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groupings ALTER COLUMN id SET DEFAULT nextval('public.groupings_id_seq'::regclass);


--
-- Name: groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups ALTER COLUMN id SET DEFAULT nextval('public.groups_id_seq'::regclass);


--
-- Name: job_messengers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_messengers ALTER COLUMN id SET DEFAULT nextval('public.job_messengers_id_seq'::regclass);


--
-- Name: key_pairs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.key_pairs ALTER COLUMN id SET DEFAULT nextval('public.key_pairs_id_seq'::regclass);


--
-- Name: levels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.levels ALTER COLUMN id SET DEFAULT nextval('public.levels_id_seq'::regclass);


--
-- Name: lti_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_clients ALTER COLUMN id SET DEFAULT nextval('public.lti_clients_id_seq'::regclass);


--
-- Name: lti_deployments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_deployments ALTER COLUMN id SET DEFAULT nextval('public.lti_deployments_id_seq'::regclass);


--
-- Name: lti_line_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_line_items ALTER COLUMN id SET DEFAULT nextval('public.lti_line_items_id_seq'::regclass);


--
-- Name: lti_services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_services ALTER COLUMN id SET DEFAULT nextval('public.lti_services_id_seq'::regclass);


--
-- Name: lti_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_users ALTER COLUMN id SET DEFAULT nextval('public.lti_users_id_seq'::regclass);


--
-- Name: marking_schemes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marking_schemes ALTER COLUMN id SET DEFAULT nextval('public.marking_schemes_id_seq'::regclass);


--
-- Name: marking_weights id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marking_weights ALTER COLUMN id SET DEFAULT nextval('public.marking_weights_id_seq'::regclass);


--
-- Name: marks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marks ALTER COLUMN id SET DEFAULT nextval('public.marks_id_seq'::regclass);


--
-- Name: memberships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberships ALTER COLUMN id SET DEFAULT nextval('public.memberships_id_seq'::regclass);


--
-- Name: notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes ALTER COLUMN id SET DEFAULT nextval('public.notes_id_seq'::regclass);


--
-- Name: peer_reviews id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.peer_reviews ALTER COLUMN id SET DEFAULT nextval('public.peer_reviews_id_seq'::regclass);


--
-- Name: periods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periods ALTER COLUMN id SET DEFAULT nextval('public.periods_id_seq'::regclass);


--
-- Name: results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.results ALTER COLUMN id SET DEFAULT nextval('public.results_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: section_starter_file_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.section_starter_file_groups ALTER COLUMN id SET DEFAULT nextval('public.section_starter_file_groups_id_seq'::regclass);


--
-- Name: sections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sections ALTER COLUMN id SET DEFAULT nextval('public.sections_id_seq'::regclass);


--
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- Name: split_pages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.split_pages ALTER COLUMN id SET DEFAULT nextval('public.split_pages_id_seq'::regclass);


--
-- Name: split_pdf_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.split_pdf_logs ALTER COLUMN id SET DEFAULT nextval('public.split_pdf_logs_id_seq'::regclass);


--
-- Name: starter_file_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.starter_file_entries ALTER COLUMN id SET DEFAULT nextval('public.starter_file_entries_id_seq'::regclass);


--
-- Name: starter_file_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.starter_file_groups ALTER COLUMN id SET DEFAULT nextval('public.starter_file_groups_id_seq'::regclass);


--
-- Name: submission_files id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_files ALTER COLUMN id SET DEFAULT nextval('public.submission_files_id_seq'::regclass);


--
-- Name: submission_rules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_rules ALTER COLUMN id SET DEFAULT nextval('public.submission_rules_id_seq'::regclass);


--
-- Name: submissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submissions ALTER COLUMN id SET DEFAULT nextval('public.submissions_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: template_divisions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.template_divisions ALTER COLUMN id SET DEFAULT nextval('public.template_divisions_id_seq'::regclass);


--
-- Name: test_batches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_batches ALTER COLUMN id SET DEFAULT nextval('public.test_batches_id_seq'::regclass);


--
-- Name: test_group_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_group_results ALTER COLUMN id SET DEFAULT nextval('public.test_group_results_id_seq'::regclass);


--
-- Name: test_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_groups ALTER COLUMN id SET DEFAULT nextval('public.test_groups_id_seq'::regclass);


--
-- Name: test_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_results ALTER COLUMN id SET DEFAULT nextval('public.test_results_id_seq'::regclass);


--
-- Name: test_runs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_runs ALTER COLUMN id SET DEFAULT nextval('public.test_runs_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: annotation_categories annotation_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.annotation_categories
    ADD CONSTRAINT annotation_categories_pkey PRIMARY KEY (id);


--
-- Name: annotation_texts annotation_texts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.annotation_texts
    ADD CONSTRAINT annotation_texts_pkey PRIMARY KEY (id);


--
-- Name: annotations annotations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.annotations
    ADD CONSTRAINT annotations_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: assessment_section_properties assessment_section_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_section_properties
    ADD CONSTRAINT assessment_section_properties_pkey PRIMARY KEY (id);


--
-- Name: assessments assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT assessments_pkey PRIMARY KEY (id);


--
-- Name: assignment_files assignment_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_files
    ADD CONSTRAINT assignment_files_pkey PRIMARY KEY (id);


--
-- Name: assignment_properties assignment_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_properties
    ADD CONSTRAINT assignment_properties_pkey PRIMARY KEY (id);


--
-- Name: autotest_settings autotest_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.autotest_settings
    ADD CONSTRAINT autotest_settings_pkey PRIMARY KEY (id);


--
-- Name: courses courses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_pkey PRIMARY KEY (id);


--
-- Name: criteria_assignment_files_joins criteria_assignment_files_joins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criteria_assignment_files_joins
    ADD CONSTRAINT criteria_assignment_files_joins_pkey PRIMARY KEY (id);


--
-- Name: criteria criteria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criteria
    ADD CONSTRAINT criteria_pkey PRIMARY KEY (id);


--
-- Name: criterion_ta_associations criterion_ta_associations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criterion_ta_associations
    ADD CONSTRAINT criterion_ta_associations_pkey PRIMARY KEY (id);


--
-- Name: exam_templates exam_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_templates
    ADD CONSTRAINT exam_templates_pkey PRIMARY KEY (id);


--
-- Name: extensions extensions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extensions
    ADD CONSTRAINT extensions_pkey PRIMARY KEY (id);


--
-- Name: extra_marks extra_marks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extra_marks
    ADD CONSTRAINT extra_marks_pkey PRIMARY KEY (id);


--
-- Name: feedback_files feedback_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_files
    ADD CONSTRAINT feedback_files_pkey PRIMARY KEY (id);


--
-- Name: grace_period_deductions grace_period_deductions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grace_period_deductions
    ADD CONSTRAINT grace_period_deductions_pkey PRIMARY KEY (id);


--
-- Name: grade_entry_items grade_entry_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grade_entry_items
    ADD CONSTRAINT grade_entry_items_pkey PRIMARY KEY (id);


--
-- Name: grade_entry_students grade_entry_students_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grade_entry_students
    ADD CONSTRAINT grade_entry_students_pkey PRIMARY KEY (id);


--
-- Name: grade_entry_students_tas grade_entry_students_tas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grade_entry_students_tas
    ADD CONSTRAINT grade_entry_students_tas_pkey PRIMARY KEY (id);


--
-- Name: grader_permissions grader_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grader_permissions
    ADD CONSTRAINT grader_permissions_pkey PRIMARY KEY (id);


--
-- Name: grades grades_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT grades_pkey PRIMARY KEY (id);


--
-- Name: grouping_starter_file_entries grouping_starter_file_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grouping_starter_file_entries
    ADD CONSTRAINT grouping_starter_file_entries_pkey PRIMARY KEY (id);


--
-- Name: groupings groupings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groupings
    ADD CONSTRAINT groupings_pkey PRIMARY KEY (id);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: job_messengers job_messengers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_messengers
    ADD CONSTRAINT job_messengers_pkey PRIMARY KEY (id);


--
-- Name: key_pairs key_pairs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.key_pairs
    ADD CONSTRAINT key_pairs_pkey PRIMARY KEY (id);


--
-- Name: levels levels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.levels
    ADD CONSTRAINT levels_pkey PRIMARY KEY (id);


--
-- Name: lti_clients lti_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_clients
    ADD CONSTRAINT lti_clients_pkey PRIMARY KEY (id);


--
-- Name: lti_deployments lti_deployments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_deployments
    ADD CONSTRAINT lti_deployments_pkey PRIMARY KEY (id);


--
-- Name: lti_line_items lti_line_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_line_items
    ADD CONSTRAINT lti_line_items_pkey PRIMARY KEY (id);


--
-- Name: lti_services lti_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_services
    ADD CONSTRAINT lti_services_pkey PRIMARY KEY (id);


--
-- Name: lti_users lti_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_users
    ADD CONSTRAINT lti_users_pkey PRIMARY KEY (id);


--
-- Name: marking_schemes marking_schemes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marking_schemes
    ADD CONSTRAINT marking_schemes_pkey PRIMARY KEY (id);


--
-- Name: marking_weights marking_weights_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marking_weights
    ADD CONSTRAINT marking_weights_pkey PRIMARY KEY (id);


--
-- Name: marks marks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marks
    ADD CONSTRAINT marks_pkey PRIMARY KEY (id);


--
-- Name: memberships memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT memberships_pkey PRIMARY KEY (id);


--
-- Name: notes notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (id);


--
-- Name: peer_reviews peer_reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.peer_reviews
    ADD CONSTRAINT peer_reviews_pkey PRIMARY KEY (id);


--
-- Name: periods periods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periods
    ADD CONSTRAINT periods_pkey PRIMARY KEY (id);


--
-- Name: results results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT results_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: section_starter_file_groups section_starter_file_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.section_starter_file_groups
    ADD CONSTRAINT section_starter_file_groups_pkey PRIMARY KEY (id);


--
-- Name: sections sections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sections
    ADD CONSTRAINT sections_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: split_pages split_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.split_pages
    ADD CONSTRAINT split_pages_pkey PRIMARY KEY (id);


--
-- Name: split_pdf_logs split_pdf_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.split_pdf_logs
    ADD CONSTRAINT split_pdf_logs_pkey PRIMARY KEY (id);


--
-- Name: starter_file_entries starter_file_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.starter_file_entries
    ADD CONSTRAINT starter_file_entries_pkey PRIMARY KEY (id);


--
-- Name: starter_file_groups starter_file_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.starter_file_groups
    ADD CONSTRAINT starter_file_groups_pkey PRIMARY KEY (id);


--
-- Name: submission_files submission_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_files
    ADD CONSTRAINT submission_files_pkey PRIMARY KEY (id);


--
-- Name: submission_rules submission_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_rules
    ADD CONSTRAINT submission_rules_pkey PRIMARY KEY (id);


--
-- Name: submissions submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT submissions_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: template_divisions template_divisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.template_divisions
    ADD CONSTRAINT template_divisions_pkey PRIMARY KEY (id);


--
-- Name: test_batches test_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_batches
    ADD CONSTRAINT test_batches_pkey PRIMARY KEY (id);


--
-- Name: test_group_results test_group_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_group_results
    ADD CONSTRAINT test_group_results_pkey PRIMARY KEY (id);


--
-- Name: test_groups test_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_groups
    ADD CONSTRAINT test_groups_pkey PRIMARY KEY (id);


--
-- Name: test_results test_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_results
    ADD CONSTRAINT test_results_pkey PRIMARY KEY (id);


--
-- Name: test_runs test_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_runs
    ADD CONSTRAINT test_runs_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: groupings_u1; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX groupings_u1 ON public.groupings USING btree (assessment_id, group_id);


--
-- Name: index_annotation_categories_on_assessment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_annotation_categories_on_assessment_id ON public.annotation_categories USING btree (assessment_id);


--
-- Name: index_annotation_categories_on_flexible_criterion_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_annotation_categories_on_flexible_criterion_id ON public.annotation_categories USING btree (flexible_criterion_id);


--
-- Name: index_annotation_texts_on_annotation_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_annotation_texts_on_annotation_category_id ON public.annotation_texts USING btree (annotation_category_id);


--
-- Name: index_annotations_on_creator_type_and_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_annotations_on_creator_type_and_creator_id ON public.annotations USING btree (creator_type, creator_id);


--
-- Name: index_annotations_on_submission_file_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_annotations_on_submission_file_id ON public.annotations USING btree (submission_file_id);


--
-- Name: index_assessments_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessments_on_course_id ON public.assessments USING btree (course_id);


--
-- Name: index_assessments_on_short_identifier_and_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assessments_on_short_identifier_and_course_id ON public.assessments USING btree (short_identifier, course_id);


--
-- Name: index_assessments_on_type_and_short_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessments_on_type_and_short_identifier ON public.assessments USING btree (type, short_identifier);


--
-- Name: index_assignment_files_on_assessment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_files_on_assessment_id ON public.assignment_files USING btree (assessment_id);


--
-- Name: index_assignment_files_on_assessment_id_and_filename; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assignment_files_on_assessment_id_and_filename ON public.assignment_files USING btree (assessment_id, filename);


--
-- Name: index_assignment_properties_on_assessment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assignment_properties_on_assessment_id ON public.assignment_properties USING btree (assessment_id);


--
-- Name: index_assignment_properties_on_default_starter_file_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_properties_on_default_starter_file_group_id ON public.assignment_properties USING btree (default_starter_file_group_id);


--
-- Name: index_courses_on_autotest_setting_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courses_on_autotest_setting_id ON public.courses USING btree (autotest_setting_id);


--
-- Name: index_courses_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_courses_on_name ON public.courses USING btree (name);


--
-- Name: index_criteria_on_assessment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_criteria_on_assessment_id ON public.criteria USING btree (assessment_id);


--
-- Name: index_criterion_ta_associations_on_criterion_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_criterion_ta_associations_on_criterion_id ON public.criterion_ta_associations USING btree (criterion_id);


--
-- Name: index_criterion_ta_associations_on_ta_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_criterion_ta_associations_on_ta_id ON public.criterion_ta_associations USING btree (ta_id);


--
-- Name: index_exam_templates_on_assessment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exam_templates_on_assessment_id ON public.exam_templates USING btree (assessment_id);


--
-- Name: index_extensions_on_grouping_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_extensions_on_grouping_id ON public.extensions USING btree (grouping_id);


--
-- Name: index_extra_marks_on_result_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_extra_marks_on_result_id ON public.extra_marks USING btree (result_id);


--
-- Name: index_feedback_files_on_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feedback_files_on_submission_id ON public.feedback_files USING btree (submission_id);


--
-- Name: index_feedback_files_on_test_group_result_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feedback_files_on_test_group_result_id ON public.feedback_files USING btree (test_group_result_id);


--
-- Name: index_grace_period_deductions_on_membership_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grace_period_deductions_on_membership_id ON public.grace_period_deductions USING btree (membership_id);


--
-- Name: index_grade_entry_items_on_assessment_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_grade_entry_items_on_assessment_id_and_name ON public.grade_entry_items USING btree (assessment_id, name);


--
-- Name: index_grade_entry_students_on_role_id_and_assessment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_grade_entry_students_on_role_id_and_assessment_id ON public.grade_entry_students USING btree (role_id, assessment_id);


--
-- Name: index_grade_entry_students_tas; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_grade_entry_students_tas ON public.grade_entry_students_tas USING btree (grade_entry_student_id, ta_id);


--
-- Name: index_grader_permissions_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grader_permissions_on_role_id ON public.grader_permissions USING btree (role_id);


--
-- Name: index_grades_on_grade_entry_item_id_and_grade_entry_student_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_grades_on_grade_entry_item_id_and_grade_entry_student_id ON public.grades USING btree (grade_entry_item_id, grade_entry_student_id);


--
-- Name: index_grouping_starter_file_entries_on_grouping_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grouping_starter_file_entries_on_grouping_id ON public.grouping_starter_file_entries USING btree (grouping_id);


--
-- Name: index_grouping_starter_file_entries_on_starter_file_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grouping_starter_file_entries_on_starter_file_entry_id ON public.grouping_starter_file_entries USING btree (starter_file_entry_id);


--
-- Name: index_groupings_tags_on_tag_id_and_grouping_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_groupings_tags_on_tag_id_and_grouping_id ON public.groupings_tags USING btree (tag_id, grouping_id);


--
-- Name: index_groups_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_on_course_id ON public.groups USING btree (course_id);


--
-- Name: index_groups_on_group_name_and_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_groups_on_group_name_and_course_id ON public.groups USING btree (group_name, course_id);


--
-- Name: index_job_messengers_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_job_messengers_on_job_id ON public.job_messengers USING btree (job_id);


--
-- Name: index_levels_on_criterion_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_levels_on_criterion_id ON public.levels USING btree (criterion_id);


--
-- Name: index_lti_clients_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_clients_on_course_id ON public.lti_clients USING btree (course_id);


--
-- Name: index_lti_deployments_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_deployments_on_course_id ON public.lti_deployments USING btree (course_id);


--
-- Name: index_lti_deployments_on_lti_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_deployments_on_lti_client_id ON public.lti_deployments USING btree (lti_client_id);


--
-- Name: index_lti_line_items_on_assessment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_line_items_on_assessment_id ON public.lti_line_items USING btree (assessment_id);


--
-- Name: index_lti_line_items_on_lti_deployment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_line_items_on_lti_deployment_id ON public.lti_line_items USING btree (lti_deployment_id);


--
-- Name: index_lti_line_items_on_lti_deployment_id_and_assessment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_lti_line_items_on_lti_deployment_id_and_assessment_id ON public.lti_line_items USING btree (lti_deployment_id, assessment_id);


--
-- Name: index_lti_services_on_lti_deployment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_services_on_lti_deployment_id ON public.lti_services USING btree (lti_deployment_id);


--
-- Name: index_lti_services_on_lti_deployment_id_and_service_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_lti_services_on_lti_deployment_id_and_service_type ON public.lti_services USING btree (lti_deployment_id, service_type);


--
-- Name: index_lti_users_on_lti_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_users_on_lti_client_id ON public.lti_users USING btree (lti_client_id);


--
-- Name: index_lti_users_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_users_on_user_id ON public.lti_users USING btree (user_id);


--
-- Name: index_lti_users_on_user_id_and_lti_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_lti_users_on_user_id_and_lti_client_id ON public.lti_users USING btree (user_id, lti_client_id);


--
-- Name: index_marking_schemes_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_marking_schemes_on_course_id ON public.marking_schemes USING btree (course_id);


--
-- Name: index_marking_schemes_on_course_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_marking_schemes_on_course_id_and_name ON public.marking_schemes USING btree (course_id, name);


--
-- Name: index_marking_weights_on_assessment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_marking_weights_on_assessment_id ON public.marking_weights USING btree (assessment_id);


--
-- Name: index_marks_on_criterion_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_marks_on_criterion_id ON public.marks USING btree (criterion_id);


--
-- Name: index_marks_on_result_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_marks_on_result_id ON public.marks USING btree (result_id);


--
-- Name: index_memberships_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_memberships_on_role_id ON public.memberships USING btree (role_id);


--
-- Name: index_notes_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notes_on_creator_id ON public.notes USING btree (creator_id);


--
-- Name: index_peer_reviews_on_result_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_peer_reviews_on_result_id ON public.peer_reviews USING btree (result_id);


--
-- Name: index_peer_reviews_on_result_id_and_reviewer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_peer_reviews_on_result_id_and_reviewer_id ON public.peer_reviews USING btree (result_id, reviewer_id);


--
-- Name: index_peer_reviews_on_reviewer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_peer_reviews_on_reviewer_id ON public.peer_reviews USING btree (reviewer_id);


--
-- Name: index_periods_on_submission_rule_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_periods_on_submission_rule_id ON public.periods USING btree (submission_rule_id);


--
-- Name: index_results_on_view_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_results_on_view_token ON public.results USING btree (view_token);


--
-- Name: index_roles_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_course_id ON public.roles USING btree (course_id);


--
-- Name: index_roles_on_section_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_section_id ON public.roles USING btree (section_id);


--
-- Name: index_roles_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_user_id ON public.roles USING btree (user_id);


--
-- Name: index_roles_on_user_id_and_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_roles_on_user_id_and_course_id ON public.roles USING btree (user_id, course_id);


--
-- Name: index_section_starter_file_groups_on_section_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_section_starter_file_groups_on_section_id ON public.section_starter_file_groups USING btree (section_id);


--
-- Name: index_section_starter_file_groups_on_starter_file_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_section_starter_file_groups_on_starter_file_group_id ON public.section_starter_file_groups USING btree (starter_file_group_id);


--
-- Name: index_sections_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sections_on_course_id ON public.sections USING btree (course_id);


--
-- Name: index_sections_on_name_and_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sections_on_name_and_course_id ON public.sections USING btree (name, course_id);


--
-- Name: index_sessions_on_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_session_id ON public.sessions USING btree (session_id);


--
-- Name: index_sessions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_updated_at ON public.sessions USING btree (updated_at);


--
-- Name: index_split_pages_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_split_pages_on_group_id ON public.split_pages USING btree (group_id);


--
-- Name: index_split_pages_on_split_pdf_log_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_split_pages_on_split_pdf_log_id ON public.split_pages USING btree (split_pdf_log_id);


--
-- Name: index_split_pdf_logs_on_exam_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_split_pdf_logs_on_exam_template_id ON public.split_pdf_logs USING btree (exam_template_id);


--
-- Name: index_split_pdf_logs_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_split_pdf_logs_on_role_id ON public.split_pdf_logs USING btree (role_id);


--
-- Name: index_starter_file_entries_on_starter_file_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_starter_file_entries_on_starter_file_group_id ON public.starter_file_entries USING btree (starter_file_group_id);


--
-- Name: index_starter_file_groups_on_assessment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_starter_file_groups_on_assessment_id ON public.starter_file_groups USING btree (assessment_id);


--
-- Name: index_submission_files_on_filename; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submission_files_on_filename ON public.submission_files USING btree (filename);


--
-- Name: index_submission_files_on_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submission_files_on_submission_id ON public.submission_files USING btree (submission_id);


--
-- Name: index_submission_rules_on_assessment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submission_rules_on_assessment_id ON public.submission_rules USING btree (assessment_id);


--
-- Name: index_submissions_on_grouping_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_grouping_id ON public.submissions USING btree (grouping_id);


--
-- Name: index_tags_on_assessment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tags_on_assessment_id ON public.tags USING btree (assessment_id);


--
-- Name: index_tags_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tags_on_role_id ON public.tags USING btree (role_id);


--
-- Name: index_template_divisions_on_exam_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_template_divisions_on_exam_template_id ON public.template_divisions USING btree (exam_template_id);


--
-- Name: index_test_batches_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_test_batches_on_course_id ON public.test_batches USING btree (course_id);


--
-- Name: index_test_group_results_on_test_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_test_group_results_on_test_group_id ON public.test_group_results USING btree (test_group_id);


--
-- Name: index_test_group_results_on_test_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_test_group_results_on_test_run_id ON public.test_group_results USING btree (test_run_id);


--
-- Name: index_test_groups_on_assessment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_test_groups_on_assessment_id ON public.test_groups USING btree (assessment_id);


--
-- Name: index_test_groups_on_criterion_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_test_groups_on_criterion_id ON public.test_groups USING btree (criterion_id);


--
-- Name: index_test_results_on_test_group_result_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_test_results_on_test_group_result_id ON public.test_results USING btree (test_group_result_id);


--
-- Name: index_test_runs_on_grouping_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_test_runs_on_grouping_id ON public.test_runs USING btree (grouping_id);


--
-- Name: index_test_runs_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_test_runs_on_role_id ON public.test_runs USING btree (role_id);


--
-- Name: index_test_runs_on_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_test_runs_on_submission_id ON public.test_runs USING btree (submission_id);


--
-- Name: index_test_runs_on_test_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_test_runs_on_test_batch_id ON public.test_runs USING btree (test_batch_id);


--
-- Name: index_users_on_api_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_api_key ON public.users USING btree (api_key);


--
-- Name: index_users_on_user_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_user_name ON public.users USING btree (user_name);


--
-- Name: annotation_categories fk_annotation_categories_assignments; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.annotation_categories
    ADD CONSTRAINT fk_annotation_categories_assignments FOREIGN KEY (assessment_id) REFERENCES public.assessments(id) ON DELETE CASCADE;


--
-- Name: annotation_texts fk_annotation_labels_annotation_categories; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.annotation_texts
    ADD CONSTRAINT fk_annotation_labels_annotation_categories FOREIGN KEY (annotation_category_id) REFERENCES public.annotation_categories(id) ON DELETE CASCADE;


--
-- Name: annotations fk_annotations_annotation_texts; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.annotations
    ADD CONSTRAINT fk_annotations_annotation_texts FOREIGN KEY (annotation_text_id) REFERENCES public.annotation_texts(id);


--
-- Name: annotations fk_annotations_submission_files; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.annotations
    ADD CONSTRAINT fk_annotations_submission_files FOREIGN KEY (submission_file_id) REFERENCES public.submission_files(id);


--
-- Name: assignment_files fk_assignment_files_assignments; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_files
    ADD CONSTRAINT fk_assignment_files_assignments FOREIGN KEY (assessment_id) REFERENCES public.assessments(id) ON DELETE CASCADE;


--
-- Name: extra_marks fk_extra_marks_results; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extra_marks
    ADD CONSTRAINT fk_extra_marks_results FOREIGN KEY (result_id) REFERENCES public.results(id) ON DELETE CASCADE;


--
-- Name: groupings fk_groupings_assignments; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groupings
    ADD CONSTRAINT fk_groupings_assignments FOREIGN KEY (assessment_id) REFERENCES public.assessments(id);


--
-- Name: groupings fk_groupings_groups; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groupings
    ADD CONSTRAINT fk_groupings_groups FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: marks fk_marks_results; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marks
    ADD CONSTRAINT fk_marks_results FOREIGN KEY (result_id) REFERENCES public.results(id) ON DELETE CASCADE;


--
-- Name: memberships fk_memberships_groupings; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT fk_memberships_groupings FOREIGN KEY (grouping_id) REFERENCES public.groupings(id);


--
-- Name: grouping_starter_file_entries fk_rails_00e856bc0c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grouping_starter_file_entries
    ADD CONSTRAINT fk_rails_00e856bc0c FOREIGN KEY (starter_file_entry_id) REFERENCES public.starter_file_entries(id);


--
-- Name: key_pairs fk_rails_07749372b3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.key_pairs
    ADD CONSTRAINT fk_rails_07749372b3 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: lti_line_items fk_rails_0ca6350bd4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_line_items
    ADD CONSTRAINT fk_rails_0ca6350bd4 FOREIGN KEY (lti_deployment_id) REFERENCES public.lti_deployments(id);


--
-- Name: groups fk_rails_0dbb68deda; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT fk_rails_0dbb68deda FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: marking_weights fk_rails_15c421fa93; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marking_weights
    ADD CONSTRAINT fk_rails_15c421fa93 FOREIGN KEY (assessment_id) REFERENCES public.assessments(id);


--
-- Name: peer_reviews fk_rails_1e5d815725; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.peer_reviews
    ADD CONSTRAINT fk_rails_1e5d815725 FOREIGN KEY (result_id) REFERENCES public.results(id);


--
-- Name: sections fk_rails_20b1e5de46; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sections
    ADD CONSTRAINT fk_rails_20b1e5de46 FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: test_groups fk_rails_20f798f1b3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_groups
    ADD CONSTRAINT fk_rails_20f798f1b3 FOREIGN KEY (assessment_id) REFERENCES public.assessments(id);


--
-- Name: criteria_assignment_files_joins fk_rails_29afc881e6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criteria_assignment_files_joins
    ADD CONSTRAINT fk_rails_29afc881e6 FOREIGN KEY (assignment_file_id) REFERENCES public.assignment_files(id);


--
-- Name: annotation_categories fk_rails_2a311146ea; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.annotation_categories
    ADD CONSTRAINT fk_rails_2a311146ea FOREIGN KEY (flexible_criterion_id) REFERENCES public.criteria(id);


--
-- Name: template_divisions fk_rails_2e45bc5c86; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.template_divisions
    ADD CONSTRAINT fk_rails_2e45bc5c86 FOREIGN KEY (assignment_file_id) REFERENCES public.assignment_files(id);


--
-- Name: test_runs fk_rails_3c9d686a0f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_runs
    ADD CONSTRAINT fk_rails_3c9d686a0f FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: tags fk_rails_4562903764; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT fk_rails_4562903764 FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: test_batches fk_rails_4d07755b5f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_batches
    ADD CONSTRAINT fk_rails_4d07755b5f FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: lti_line_items fk_rails_4ed33e5462; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_line_items
    ADD CONSTRAINT fk_rails_4ed33e5462 FOREIGN KEY (assessment_id) REFERENCES public.assessments(id);


--
-- Name: feedback_files fk_rails_55b6a53fc7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_files
    ADD CONSTRAINT fk_rails_55b6a53fc7 FOREIGN KEY (test_group_result_id) REFERENCES public.test_group_results(id);


--
-- Name: test_group_results fk_rails_5ad5ab0a6d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_group_results
    ADD CONSTRAINT fk_rails_5ad5ab0a6d FOREIGN KEY (test_group_id) REFERENCES public.test_groups(id);


--
-- Name: split_pages fk_rails_5d57914eb6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.split_pages
    ADD CONSTRAINT fk_rails_5d57914eb6 FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: marking_schemes fk_rails_66abcf9f61; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marking_schemes
    ADD CONSTRAINT fk_rails_66abcf9f61 FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: grouping_starter_file_entries fk_rails_6764550634; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grouping_starter_file_entries
    ADD CONSTRAINT fk_rails_6764550634 FOREIGN KEY (grouping_id) REFERENCES public.groupings(id);


--
-- Name: test_results fk_rails_706edea285; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_results
    ADD CONSTRAINT fk_rails_706edea285 FOREIGN KEY (test_group_result_id) REFERENCES public.test_group_results(id);


--
-- Name: exam_templates fk_rails_735ea14f87; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_templates
    ADD CONSTRAINT fk_rails_735ea14f87 FOREIGN KEY (assessment_id) REFERENCES public.assessments(id);


--
-- Name: assessments fk_rails_79e107ee61; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT fk_rails_79e107ee61 FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: tags fk_rails_7b5dd1aabc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT fk_rails_7b5dd1aabc FOREIGN KEY (assessment_id) REFERENCES public.assessments(id);


--
-- Name: levels fk_rails_7d6e4d7d84; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.levels
    ADD CONSTRAINT fk_rails_7d6e4d7d84 FOREIGN KEY (criterion_id) REFERENCES public.criteria(id);


--
-- Name: test_group_results fk_rails_848004f82a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_group_results
    ADD CONSTRAINT fk_rails_848004f82a FOREIGN KEY (test_run_id) REFERENCES public.test_runs(id);


--
-- Name: peer_reviews fk_rails_89cf1ffcc5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.peer_reviews
    ADD CONSTRAINT fk_rails_89cf1ffcc5 FOREIGN KEY (reviewer_id) REFERENCES public.groupings(id);


--
-- Name: test_runs fk_rails_8d1eefeaa6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_runs
    ADD CONSTRAINT fk_rails_8d1eefeaa6 FOREIGN KEY (grouping_id) REFERENCES public.groupings(id);


--
-- Name: starter_file_entries fk_rails_93b2f88720; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.starter_file_entries
    ADD CONSTRAINT fk_rails_93b2f88720 FOREIGN KEY (starter_file_group_id) REFERENCES public.starter_file_groups(id);


--
-- Name: split_pages fk_rails_9ea6507e1b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.split_pages
    ADD CONSTRAINT fk_rails_9ea6507e1b FOREIGN KEY (split_pdf_log_id) REFERENCES public.split_pdf_logs(id);


--
-- Name: split_pdf_logs fk_rails_a3bcef9f4d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.split_pdf_logs
    ADD CONSTRAINT fk_rails_a3bcef9f4d FOREIGN KEY (exam_template_id) REFERENCES public.exam_templates(id);


--
-- Name: courses fk_rails_a850991350; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT fk_rails_a850991350 FOREIGN KEY (autotest_setting_id) REFERENCES public.autotest_settings(id);


--
-- Name: assignment_properties fk_rails_aa46f38276; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_properties
    ADD CONSTRAINT fk_rails_aa46f38276 FOREIGN KEY (assessment_id) REFERENCES public.assessments(id) ON DELETE CASCADE;


--
-- Name: roles fk_rails_ab35d699f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT fk_rails_ab35d699f0 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: memberships fk_rails_ab987c7623; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT fk_rails_ab987c7623 FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: test_runs fk_rails_bb3bcd4524; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_runs
    ADD CONSTRAINT fk_rails_bb3bcd4524 FOREIGN KEY (test_batch_id) REFERENCES public.test_batches(id);


--
-- Name: lti_services fk_rails_bc988f7ae6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_services
    ADD CONSTRAINT fk_rails_bc988f7ae6 FOREIGN KEY (lti_deployment_id) REFERENCES public.lti_deployments(id);


--
-- Name: template_divisions fk_rails_c03e161c7f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.template_divisions
    ADD CONSTRAINT fk_rails_c03e161c7f FOREIGN KEY (exam_template_id) REFERENCES public.exam_templates(id);


--
-- Name: roles fk_rails_c0c49c15d4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT fk_rails_c0c49c15d4 FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: grader_permissions fk_rails_c40f429065; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grader_permissions
    ADD CONSTRAINT fk_rails_c40f429065 FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: marks fk_rails_d7d7e253ac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marks
    ADD CONSTRAINT fk_rails_d7d7e253ac FOREIGN KEY (criterion_id) REFERENCES public.criteria(id);


--
-- Name: section_starter_file_groups fk_rails_d988dc43a3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.section_starter_file_groups
    ADD CONSTRAINT fk_rails_d988dc43a3 FOREIGN KEY (starter_file_group_id) REFERENCES public.starter_file_groups(id);


--
-- Name: starter_file_groups fk_rails_dc9506afeb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.starter_file_groups
    ADD CONSTRAINT fk_rails_dc9506afeb FOREIGN KEY (assessment_id) REFERENCES public.assessments(id);


--
-- Name: roles fk_rails_de26433d35; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT fk_rails_de26433d35 FOREIGN KEY (section_id) REFERENCES public.sections(id);


--
-- Name: section_starter_file_groups fk_rails_e17dbd98da; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.section_starter_file_groups
    ADD CONSTRAINT fk_rails_e17dbd98da FOREIGN KEY (section_id) REFERENCES public.sections(id);


--
-- Name: split_pdf_logs fk_rails_e47d20d30f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.split_pdf_logs
    ADD CONSTRAINT fk_rails_e47d20d30f FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: grade_entry_students fk_rails_ec5b13f7ac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grade_entry_students
    ADD CONSTRAINT fk_rails_ec5b13f7ac FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: criteria fk_rails_f39ad88be1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criteria
    ADD CONSTRAINT fk_rails_f39ad88be1 FOREIGN KEY (assessment_id) REFERENCES public.assessments(id);


--
-- Name: test_runs fk_rails_f712000ed8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_runs
    ADD CONSTRAINT fk_rails_f712000ed8 FOREIGN KEY (submission_id) REFERENCES public.submissions(id);


--
-- Name: extensions fk_rails_fa7e3b1bbd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extensions
    ADD CONSTRAINT fk_rails_fa7e3b1bbd FOREIGN KEY (grouping_id) REFERENCES public.groupings(id);


--
-- Name: feedback_files fk_rails_fad793dc3e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_files
    ADD CONSTRAINT fk_rails_fad793dc3e FOREIGN KEY (submission_id) REFERENCES public.submissions(id);


--
-- Name: assignment_properties fk_rails_faee0a10b7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_properties
    ADD CONSTRAINT fk_rails_faee0a10b7 FOREIGN KEY (default_starter_file_group_id) REFERENCES public.starter_file_groups(id);


--
-- Name: results fk_results_submissions; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT fk_results_submissions FOREIGN KEY (submission_id) REFERENCES public.submissions(id) ON DELETE CASCADE;


--
-- Name: submission_files fk_submission_files_submissions; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_files
    ADD CONSTRAINT fk_submission_files_submissions FOREIGN KEY (submission_id) REFERENCES public.submissions(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20240313191809'),
('20230713153536'),
('20230303030615'),
('20230109190029'),
('20221219204837'),
('20221111182002'),
('20221019191315'),
('20220922131809'),
('20220826132206'),
('20220825171354'),
('20220815210513'),
('20220727161425'),
('20220726201403'),
('20220726142501'),
('20220707182822'),
('20220629225622'),
('20220624220107'),
('20220527183807'),
('20220521024317'),
('20220321145827'),
('20220206065135'),
('20220128182721'),
('20220105204341'),
('20211216152132'),
('20211213200348'),
('20211207164034'),
('20211126223421'),
('20211112202607'),
('20211029164912'),
('20211018123836'),
('20211014190400'),
('20211013190449'),
('20211013132235'),
('20210927150608'),
('20210907163338'),
('20210804184031'),
('20210730132238'),
('20210617201409'),
('20210616012947'),
('20210606103512'),
('20210505032404'),
('20210427120039'),
('20210422193041'),
('20210421152246'),
('20210419144038'),
('20210216160312'),
('20210127202444'),
('20210103155930'),
('20201126164928'),
('20201122174128'),
('20201119175937'),
('20201028233019'),
('20200813195934'),
('20200811194846'),
('20200726012622'),
('20200709165042'),
('20200608190551'),
('20200605183957'),
('20200604180812'),
('20200526185329'),
('20200522172914'),
('20200514134956'),
('20200504201055'),
('20200319204954'),
('20200225050808'),
('20200117171430'),
('20191210143220'),
('20191011182851'),
('20190924061752'),
('20190708183843'),
('20190621203403'),
('20190508132638'),
('20190423155205'),
('20190423050026'),
('20190320183952'),
('20190129131200'),
('20181014203917'),
('20180924215139'),
('20180608134554'),
('20180607221235'),
('20180528163425'),
('20180523180354'),
('20180517143503'),
('20180516181356'),
('20180430184545'),
('20180411222442'),
('20171212204015'),
('20171212191808'),
('20171128164242'),
('20170803155637'),
('20170803134441'),
('20170710203836'),
('20170623163309'),
('20170620144136'),
('20170615150045'),
('20170605184307'),
('20170605141017'),
('20170602200618'),
('20170419153405'),
('20170417202352'),
('20170219132130'),
('20170213020105'),
('20170213015726'),
('20170213014954'),
('20170212205736'),
('20170207220201'),
('20161207195428'),
('20160925144240'),
('20160907214406'),
('20160902214959'),
('20160826161005'),
('20160820143836'),
('20160810184655'),
('20160809145347'),
('20160727181814'),
('20160727173308'),
('20160623140952'),
('20160610202949'),
('20160518004516'),
('20160517142117'),
('20160511224541'),
('20160510173147'),
('20160509144712'),
('20160504175156'),
('20160503175401'),
('20160421002312'),
('20160418231321'),
('20160417225941'),
('20160417214303'),
('20160327163400'),
('20160303184449'),
('20160219001523'),
('20160202040552'),
('20160202034437'),
('20160116172051'),
('20160116172027'),
('20151129233225'),
('20151114204502'),
('20151005010958'),
('20151005010909'),
('20150919173134'),
('20150918220352'),
('20150818181645'),
('20150724162632'),
('20150527172828'),
('20150326163940'),
('20150319083515'),
('20150319083049'),
('20150304033052'),
('20150226032509'),
('20150219044256'),
('20150216001957'),
('20150216001922'),
('20150201040434'),
('20150126155628'),
('20141128075905'),
('20141017202829'),
('20141017184954'),
('20140819200608'),
('20140513140924'),
('20140513134427'),
('20140207162800'),
('20131224160912'),
('20131202053252'),
('20131010050432'),
('20131010033936'),
('20131007065920'),
('20131004123913'),
('20131003124810'),
('20130408025520'),
('20130407172918'),
('20130403002432'),
('20130402190548'),
('20130219230002'),
('20130205192032'),
('20121028211448'),
('20120121222559'),
('20110313200240'),
('20110221212124'),
('20110204023647'),
('20110123035536'),
('20101117195814'),
('20101116004008'),
('20101113165920'),
('20101112160622'),
('20101112001211'),
('20101109215909'),
('20100830154126'),
('20100816213841'),
('20100812195558'),
('20100726183357'),
('20100723155015'),
('20100723150051'),
('20100723141658'),
('20100723125503'),
('20100722185533'),
('20100722132421'),
('20100721153431'),
('20100714141139'),
('20100713172326'),
('20100712175641'),
('20100630144124'),
('20100629172944'),
('20100629142929'),
('20100629133547'),
('20100629130922'),
('20100628140408'),
('20100615200307'),
('20100615162509'),
('20100615162452'),
('20100615162438'),
('20100615162413'),
('20100606160859'),
('20100513155158'),
('20100406002059'),
('20100401222956'),
('20100310100552'),
('20100224150617'),
('20100204135303'),
('20100126204816'),
('20100123094855'),
('20100102142037'),
('20091224042140'),
('20091127212046'),
('20091125173242'),
('20091125104552'),
('20091123000907'),
('20091118064643'),
('20091116195456'),
('20091116141905'),
('20091111205229'),
('20091111065154'),
('20091105182703'),
('20091105023240'),
('20091101234310'),
('20091101221901'),
('20091029063843'),
('20091028213048'),
('20091024193107'),
('20090826182322'),
('20090811194915'),
('20090811155500'),
('20090806193116'),
('20090731201348'),
('20090731195928'),
('20090730133921'),
('20090727170851'),
('20090727153945'),
('20090723155356'),
('20090722201232'),
('20090722200411'),
('20090722195639'),
('20090721192032'),
('20090721141048'),
('20090706131528'),
('20090623140913'),
('20090609195721'),
('20090605175316'),
('20090605142342'),
('20090603200901'),
('20090601181435'),
('20090601173741'),
('20090601155401'),
('20090529022547'),
('20090528154315'),
('20090519140333'),
('20090515201727'),
('20090515172919'),
('20090515142434'),
('20090515141902'),
('20090515141319'),
('20090515135140'),
('20090515135136'),
('20090513155255'),
('20090512200945'),
('20090512193837'),
('20090512182004'),
('20090512173025'),
('20090512133912'),
('20090512133754'),
('20090511210106'),
('20090326022851'),
('20090220200053'),
('20090219215958'),
('20090219195620'),
('20090219153258'),
('20090219151533'),
('20090219150618'),
('20090212060818'),
('20090212060750'),
('20090211221709'),
('20090206022047'),
('20090203023227'),
('20090128224245'),
('20090122190852'),
('20090116063343'),
('20090116055742'),
('20090116054833'),
('20081130222302'),
('20081130222245'),
('20081126200403'),
('20081126183411'),
('20081009204754'),
('20081009204739'),
('20081009204730'),
('20081009204639'),
('20081009204628'),
('20081009115817'),
('20081001171713'),
('20081001150627'),
('20081001150504'),
('20080927052808'),
('20080812143641'),
('20080812143621'),
('20080806143028'),
('20080729162322'),
('20080729162213'),
('20080729160237');
