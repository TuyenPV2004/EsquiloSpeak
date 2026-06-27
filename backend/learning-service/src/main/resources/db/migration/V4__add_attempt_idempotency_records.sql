CREATE TABLE learning_schema.attempt_idempotency_records (
    record_id character varying(50) NOT NULL,
    user_id character varying(50) NOT NULL,
    client_request_id character varying(50) NOT NULL,
    request_hash character varying(64) NOT NULL,
    status character varying(30) NOT NULL,
    snapshot_json text,
    attempt_id character varying(50),
    error_code character varying(80),
    error_message character varying(500),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT attempt_idempotency_records_pkey PRIMARY KEY (record_id),
    CONSTRAINT uk_attempt_idempotency_user_client_request UNIQUE (user_id, client_request_id),
    CONSTRAINT ck_attempt_idempotency_status CHECK (status IN ('PROCESSING', 'SUCCEEDED', 'FAILED_PERMANENT'))
);
