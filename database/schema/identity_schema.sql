CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA identity;

CREATE TABLE identity.user (
    user_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    first_name varchar(50) NOT NULL,
    last_name varchar(50) NOT NULL,
    birth_day date NOT NULL,
    nationality varchar(50) NOT NULL,
    email varchar(50) NOT NULL,
    CONSTRAINT pk_user
        PRIMARY KEY (user_id),
    CONSTRAINT ch_user_first_name_is_capitalized_and_non_empty
        CHECK (first_name ~ '^[A-Z][- a-zA-Z]{1,}$'),
    CONSTRAINT ch_user_last_name_is_capitalized_and_non_empty
        CHECK (last_name ~ '^[A-Z][- a-zA-Z]{1,}$'),
    CONSTRAINT ch_user_birth_day_is_not_too_old
        CHECK (birth_day > current_timestamp - interval '120 years'),
    CONSTRAINT ch_user_nationality_is_capitalized_and_non_empty
        CHECK (nationality ~ '^[A-Z][- a-zA-Z]{3,}$'),
    CONSTRAINT uq_user_email
        UNIQUE (email),
    CONSTRAINT ch_user_email_has_valid_email_format
        CHECK (email ~* '^[-_.a-z]{3,}@[-_.a-z]{3,}$')
);

CREATE INDEX ix_user_first_name ON identity.user (first_name);
CREATE INDEX ix_user_last_name ON identity.user (last_name);

CREATE TABLE identity.user_audit (
    user_audit_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    subject varchar(50) NOT NULL,
    old_value jsonb NOT NULL,
    new_value jsonb NOT NULL,
    audit_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    user_id uuid NOT NULL,
    CONSTRAINT pk_user_audit
        PRIMARY KEY (user_audit_id),
    CONSTRAINT ch_user_audit_subject_is_non_empty
        CHECK (length(subject) > 2),
    CONSTRAINT fk_user_audit_tracks_changes_to_user
        FOREIGN KEY (user_id) REFERENCES identity.user (user_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE INDEX ix_user_audit_user_id ON identity.user_audit (user_id);

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
    a_first_name varchar(50),
    a_last_name varchar(50),
    a_birth_day date,
    a_nationality varchar(50),
    a_email varchar(50),
    a_user_id uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE sql AS $$
    WITH old_user AS (
        SELECT
            CASE WHEN exists(
                SELECT 1 FROM identity.user u WHERE u.user_id = a_user_id
            ) THEN (
                SELECT row_to_json(u)
                FROM identity.user u
                WHERE u.user_id = a_user_id
            ) ELSE (
                SELECT row_to_json(row())
            )
            END json
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
            coalesce(a_user_id, gen_random_uuid()),
            a_first_name,
            a_last_name,
            a_birth_day,
            a_nationality,
            a_email
        )
        ON CONFLICT ON CONSTRAINT pk_user DO UPDATE SET
            first_name = excluded.first_name,
            last_name = excluded.last_name,
            birth_day = excluded.birth_day,
            nationality = excluded.nationality,
            email = excluded.email
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

-- SELECT identity.patch_user(
--     a_subject := 'web',
--     a_user_id := '9d8ea030-86c1-49b3-833b-0c928e507206',
--     a_first_name := 'Volodymyr',
--     a_last_name := 'Prokopyuk',
--     a_birth_day := '1984-09-14',
--     a_nationality := 'Ukrainian',
--     a_email := 'volodymyrprokopyuk@gmail.com'
-- ) user_id;

CREATE OR REPLACE FUNCTION identity.patch_user(
    a_subject varchar(50),
    a_user_id uuid,
    a_first_name varchar(50) DEFAULT NULL,
    a_last_name varchar(50) DEFAULT NULL,
    a_birth_day date DEFAULT NULL,
    a_nationality varchar(50) DEFAULT NULL,
    a_email varchar(50) DEFAULT NULL
)
RETURNS uuid
LANGUAGE sql AS $$
    WITH old_user AS (
        SELECT
            CASE WHEN exists(
                SELECT 1 FROM identity.user u WHERE u.user_id = a_user_id
            ) THEN (
                SELECT row_to_json(u)
                FROM identity.user u
                WHERE u.user_id = a_user_id
            ) ELSE (
                SELECT row_to_json(row())
            )
            END json
    ),
    user_entry AS (
        UPDATE identity.user u
        SET
            first_name = coalesce(a_first_name, u.first_name),
            last_name = coalesce(a_last_name, u.last_name),
            birth_day = coalesce(a_birth_day, u.birth_day),
            nationality = coalesce(a_nationality, u.nationality),
            email = coalesce(a_email, u.email)
        WHERE u.user_id = a_user_id
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

-- SELECT *
-- FROM identity.get_user_audit(
--     a_user_id := '9d8ea030-86c1-49b3-833b-0c928e507206',
--     a_subject := 'web'
-- );

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

-- SELECT *
-- FROM identity.get_user(
--     a_user_id := '9d8ea030-86c1-49b3-833b-0c928e507206',
--     a_first_name := 'Volodymyr',
--     a_last_name := 'Prokopyuk',
--     a_birth_day := '1984-09-14',
--     a_nationality := 'Ukrainian',
--     a_email := 'volodymyrprokopyuk@gmail.com'
-- );

CREATE OR REPLACE FUNCTION identity.get_user(
    a_user_id uuid DEFAULT NULL,
    a_first_name varchar(50) DEFAULT NULL,
    a_last_name varchar(50) DEFAULT NULL,
    a_birth_day date DEFAULT NULL,
    a_nationality varchar(50) DEFAULT NULL,
    a_email varchar(50) DEFAULT NULL,
    a_limit integer DEFAULT 100,
    a_offset integer DEFAULT 0
)
RETURNS TABLE (
    user_id uuid,
    first_name varchar(50),
    last_name varchar(50),
    birth_day date,
    nationality varchar(50),
    email varchar(50)
)
LANGUAGE sql AS $$
    SELECT u.user_id,
        u.first_name,
        u.last_name,
        u.birth_day,
        u.nationality,
        u.email
    FROM identity.user u
    WHERE (a_user_id IS NULL OR u.user_id = a_user_id)
        AND (a_first_name IS NULL OR u.first_name = a_first_name)
        AND (a_last_name IS NULL OR u.last_name = a_last_name)
        AND (a_birth_day IS NULL OR u.birth_day = a_birth_day)
        AND (a_nationality IS NULL OR u.nationality = a_nationality)
        AND (a_email IS NULL OR u.email = a_email)
    ORDER BY u.user_id
    LIMIT a_limit OFFSET a_offset;
$$;

-- SELECT identity.delete_user(
--     a_user_id := '9d8ea030-86c1-49b3-833b-0c928e507206'
-- ) user_id;

CREATE OR REPLACE FUNCTION identity.delete_user(
    a_user_id uuid
)
RETURNS uuid
LANGUAGE sql AS $$
    WITH user_audit_entries AS (
        DELETE FROM identity.user_audit
        WHERE user_id = a_user_id
    )
    DELETE FROM identity.user
    WHERE user_id = a_user_id
    RETURNING user_id;
$$;
