CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA identity;

CREATE TABLE identity.user (
    user_id uuid NOT NULL
        DEFAULT uuid_generate_v4(),
    first_name varchar(50) NOT NULL,
    last_name varchar(50) NOT NULL,
    birth_day date NOT NULL,
    nationality varchar(50) NOT NULL,
    email varchar(50) NOT NULL,
    CONSTRAINT pk_user
        PRIMARY KEY (user_id),
    CONSTRAINT ch_user_first_name
        CHECK (first_name ~ '^[A-Z][- a-zA-Z]{1,}$'),
    CONSTRAINT ch_user_last_name
        CHECK (last_name ~ '^[A-Z][- a-zA-Z]{1,}$'),
    CONSTRAINT ch_user_birth_day
        CHECK (birth_day > current_timestamp - interval '120 years'),
    CONSTRAINT ch_user_nationality
        CHECK (nationality ~ '^[A-Z][- a-zA-Z]{3,}$'),
    CONSTRAINT uq_user_email
        UNIQUE (email),
    CONSTRAINT ch_user_email
        CHECK (email ~* '^[-_.a-z]{3,}@[-_.a-z]{3,}$')
);

CREATE TABLE identity.user_audit (
    user_audit_id uuid NOT NULL
        DEFAULT uuid_generate_v4(),
    user_id uuid NOT NULL,
    subject varchar(50) NOT NULL,
    old_value jsonb NOT NULL,
    new_value jsonb NOT NULL,
    audit_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    CONSTRAINT pk_user_audit
        PRIMARY KEY (user_audit_id),
    CONSTRAINT fk_user_audit_user_audit_id
        FOREIGN KEY (user_id) REFERENCES identity.user (user_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ch_user_audit_subject
        CHECK (length(subject) > 2)
);

-- SELECT identity.put_user(
--     a_subject := 'web',
--     a_user_id := '9d8ea030-86c1-49b3-833b-0c928e507206',
--     a_first_name := 'Volodymyr',
--     a_last_name := 'Prokopyuk',
--     a_birth_day := '1984-09-14',
--     a_nationality := 'Ukrainian',
--     a_email := 'volodymyrprokopyuk@gmail.com'
-- ) user_id;

CREATE OR REPLACE FUNCTION identity.put_user(
    a_subject varchar(50),
    a_user_id uuid DEFAULT NULL,
    a_first_name varchar(50) DEFAULT NULL,
    a_last_name varchar(50) DEFAULT NULL,
    a_birth_day date DEFAULT NULL,
    a_nationality varchar(50) DEFAULT NULL,
    a_email varchar(50) DEFAULT NULL
)
RETURNS uuid
LANGUAGE sql AS $$
    WITH old_user AS (
        SELECT ou.json
        FROM (
            SELECT row_to_json(u) json
            FROM identity.user u
            WHERE u.user_id = a_user_id
            UNION ALL
            SELECT row_to_json(row()) json
        ) ou
        ORDER BY length(ou.json::text) DESC
        LIMIT 1
    ),
    user_entry AS (
        INSERT INTO identity.user AS u (
            user_id,
            first_name,
            last_name,
            birth_day,
            nationality,
            email
        )
        VALUES (
            coalesce(a_user_id, uuid_generate_v4()),
            a_first_name,
            a_last_name,
            a_birth_day,
            a_nationality,
            a_email
        )
        ON CONFLICT ON CONSTRAINT pk_user DO UPDATE SET
            first_name = coalesce(excluded.first_name, u.first_name),
            last_name = coalesce(excluded.last_name, u.last_name),
            birth_day = coalesce(excluded.birth_day, u.birth_day),
            nationality = coalesce(excluded.nationality, u.nationality),
            email = coalesce(excluded.email, u.email)
        RETURNING *
    )
    INSERT INTO identity.user_audit (
        user_id,
        subject,
        old_value,
        new_value
    )
    SELECT user_entry.user_id,
        a_subject,
        old_user.json,
        row_to_json(user_entry)
    FROM user_entry,
        old_user
    RETURNING user_id;
$$;

CREATE OR REPLACE FUNCTION identity.get_user_audit(
    a_user_id uuid DEFAULT NULL,
    a_subject varchar(50) DEFAULT NULL,
    a_since_ts timestamptz DEFAULT NULL,
    a_till_ts timestamptz DEFAULT NULL,
    a_limit integer DEFAULT 100,
    a_offset integer DEFAULT 0
)
RETURNS TABLE (
    user_audit_id uuid,
    user_id uuid,
    subject varchar(50),
    old_value jsonb,
    new_value jsonb,
    audit_ts timestamptz
)
LANGUAGE sql AS $$
    SELECT ua.user_audit_id,
        ua.user_id,
        ua.subject,
        ua.old_value,
        ua.new_value,
        ua.audit_ts
    FROM identity.user_audit ua
    WHERE (a_user_id IS NULL OR ua.user_id = a_user_id)
        AND (a_subject IS NULL OR ua.subject = a_subject)
        AND (a_since_ts IS NULL OR ua.audit_ts >= a_since_ts)
        AND (a_till_ts IS NULL OR ua.audit_ts < a_till_ts)
    ORDER BY ua.user_id, ua.audit_ts
    LIMIT a_limit OFFSET a_offset;
$$;
