CREATE SCHEMA IF NOT EXISTS learning_schema;
CREATE SCHEMA IF NOT EXISTS review_schema;

CREATE TABLE learning_schema.learning_sessions (
    session_id character varying(50) NOT NULL,
    completed_at timestamp(6) without time zone,
    course_id character varying(50) NOT NULL,
    started_at timestamp(6) without time zone NOT NULL,
    user_id character varying(50) NOT NULL,
    CONSTRAINT learning_sessions_pkey PRIMARY KEY (session_id)
);

CREATE TABLE learning_schema.lesson_progress (
    progress_id character varying(50) NOT NULL,
    completed_at timestamp(6) without time zone,
    lesson_id character varying(50) NOT NULL,
    status character varying(20) NOT NULL,
    user_id character varying(50) NOT NULL,
    CONSTRAINT lesson_progress_pkey PRIMARY KEY (progress_id)
);

CREATE TABLE learning_schema.question_attempts (
    attempt_id character varying(50) NOT NULL,
    answered_at timestamp(6) without time zone NOT NULL,
    client_request_id character varying(50) NOT NULL,
    course_id character varying(50) NOT NULL,
    is_correct boolean NOT NULL,
    lesson_id character varying(50) NOT NULL,
    question_id character varying(50) NOT NULL,
    response_time_ms integer,
    selected_answer character varying(255),
    user_id character varying(50) NOT NULL,
    question_version_id character varying(50),
    CONSTRAINT question_attempts_pkey PRIMARY KEY (attempt_id),
    CONSTRAINT ukhgjfax905uki7aknyss4q1nsa UNIQUE (user_id, client_request_id)
);

CREATE TABLE review_schema.review_attempts (
    attempt_id character varying(50) NOT NULL,
    rating character varying(20) NOT NULL,
    response_time_ms integer,
    review_item_id character varying(50) NOT NULL,
    reviewed_at timestamp(6) without time zone NOT NULL,
    user_id character varying(50) NOT NULL,
    CONSTRAINT review_attempts_pkey PRIMARY KEY (attempt_id)
);

CREATE TABLE review_schema.review_items (
    review_item_id character varying(50) NOT NULL,
    concept character varying(255) NOT NULL,
    course_id character varying(50) NOT NULL,
    ease_factor double precision NOT NULL,
    interval_days integer NOT NULL,
    last_reviewed_at timestamp(6) without time zone,
    next_review_at timestamp(6) without time zone NOT NULL,
    repetition_count integer NOT NULL,
    type character varying(50) NOT NULL,
    user_id character varying(50) NOT NULL,
    correct_answer character varying(255),
    explanation character varying(255),
    CONSTRAINT review_items_pkey PRIMARY KEY (review_item_id)
);
