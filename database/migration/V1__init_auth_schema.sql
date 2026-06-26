CREATE SCHEMA IF NOT EXISTS auth_schema;
CREATE SCHEMA IF NOT EXISTS user_schema;

CREATE TABLE auth_schema.guest_accounts (
    user_id character varying(36) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    device_id character varying(255) NOT NULL,
    CONSTRAINT guest_accounts_pkey PRIMARY KEY (user_id),
    CONSTRAINT uk_5cbd29d43sn72l3o7xvhkwvuq UNIQUE (device_id)
);

CREATE TABLE user_schema.user_profiles (
    user_id character varying(36) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    daily_goal_minutes integer,
    onboarding_completed boolean,
    self_assessed_level character varying(10),
    source_language character varying(10),
    target_language character varying(10),
    updated_at timestamp(6) without time zone,
    CONSTRAINT user_profiles_pkey PRIMARY KEY (user_id)
);
