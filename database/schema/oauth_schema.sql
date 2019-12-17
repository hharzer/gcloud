CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA identity;

CREATE TABLE identity.user (
    user_id uuid NOT NULL
        DEFAULT uuid_generate_v4(),
    -- User is uniquely identified by an email
    email varchar(50) NOT NULL,
    -- User may have optional password
    password_hash varchar(50),
    -- User may be blocked on demand
    active boolean NOT NULL
        DEFAULT true,
    CONSTRAINT pk_user
        PRIMARY KEY (user_id),
    CONSTRAINT uq_user_email
        UNIQUE (email)
);

CREATE TABLE identity.device (
    device_id uuid NOT NULL
        DEFAULT uuid_generate_v4(),
    user_id uuid NOT NULL,
    -- Device is uniquely identified by device fingerprint
    device_fp varchar(50) NOT NULL,
    -- Device may be blocked on demand
    active boolean NOT NULL
        DEFAULT true,
    CONSTRAINT pk_device
        PRIMARY KEY (device_id),
    CONSTRAINT uq_device_device_fp
        UNIQUE (device_fp),
    -- User can have multiple devices
    CONSTRAINT fk_device_user_id
        FOREIGN KEY (user_id) REFERENCES identity.user (user_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE SCHEMA oauth;

-- CONFIDENTIAL client has both clinet_id and client_secret
-- PUBLIC client can only have client_id as client_secret confidentiality
-- cannot be enforced by web and mobile applications
CREATE TYPE oauth.client_type AS
    ENUM ('CONFIDENTIAL', 'PUBLIC');

CREATE TABLE oauth.client (
    client_id uuid NOT NULL
        DEFAULT uuid_generate_v4(),
    -- Optional client secret only for CONFIDENTIAL clients
    client_secret varchar(50),
    client_name varchar(50) NOT NULL,
    client_type oauth.client_type NOT NULL,
    -- Client may be blocked on demand
    active boolean NOT NULL
        DEFAULT true,
    creation_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    CONSTRAINT pk_client
        PRIMARY KEY (client_id)
);

CREATE TABLE oauth.session (
    session_id uuid NOT NULL
        DEFAULT uuid_generate_v4(),
    client_id uuid NOT NULL,
    user_id uuid,
    device_id uuid,
    -- Store email for individuals that are not yet users
    email varchar(50) NOT NULL,
    -- Store defice fingerprint for individuals that are not yet users
    device_fp varchar(50) NOT NULL,
    creation_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    -- Timestampt of explicit sign out otherwise NULL
    termination_ts timestamptz,
    CONSTRAINT pk_session
        PRIMARY KEY (session_id),
    -- Session is related to a client
    CONSTRAINT fk_session_client_id
        FOREIGN KEY (client_id) REFERENCES oauth.client (client_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    -- Session is related to a user
    CONSTRAINT fk_session_user_id
        FOREIGN KEY (user_id) REFERENCES identity.user (user_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    -- Session is related to a device
    CONSTRAINT fk_session_device_id
        FOREIGN KEY (device_id) REFERENCES identity.device (device_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE oauth.challenge (
    challenge_id uuid NOT NULL
        DEFAULT uuid_generate_v4(),
    session_id uuid NOT NULL,
    -- Randomly generated unique challenge to be included in the magic link
    challenge varchar(50) NOT NULL,
    creation_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    expiration_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp + interval '15 minutes'),
    -- Optional confirmation timestampt when the magic lint has been clicked
    confirmation_ts timestamptz,
    CONSTRAINT pk_challenge
        PRIMARY KEY (challenge_id),
    CONSTRAINT uq_challenge_challenge
        UNIQUE (challenge),
    CONSTRAINT fk_challenge_session_id
        FOREIGN KEY (session_id) REFERENCES oauth.session (session_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE oauth.otp (
    otp_id uuid NOT NULL
        DEFAULT uuid_generate_v4(),
    session_id uuid NOT NULL,
    -- Randomly generated OTP to be sent to a client and exchanged by an AT and RT
    otp varchar(50) NOT NULL,
    creation_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    expiration_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp + interval '5 minutes'),
    -- Optional redemption timestampt when the OTP is sent back to the server
    redemption_ts timestamptz,
    CONSTRAINT pk_otp
        PRIMARY KEY (otp_id),
    CONSTRAINT uq_otp_otp
        UNIQUE (otp),
    CONSTRAINT fk_otp_session_id
        FOREIGN KEY (session_id) REFERENCES oauth.session (session_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE oauth.access_token (
    access_token_id uuid NOT NULL
        DEFAULT uuid_generate_v4(),
    session_id uuid NOT NULL,
    -- Randomly generated AT to be used at the Resource server to access API
    access_token varchar(50) NOT NULL,
    creation_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    expiration_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp + interval '15 minutes'),
    CONSTRAINT pk_access_token
        PRIMARY KEY (access_token_id),
    CONSTRAINT uq_access_token_access_token
        UNIQUE (access_token),
    CONSTRAINT fk_access_token_session_id
        FOREIGN KEY (session_id) REFERENCES oauth.session (session_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE oauth.refresh_token (
    refresh_token_id uuid NOT NULL
        DEFAULT uuid_generate_v4(),
    session_id uuid NOT NULL,
    -- Randombly generated RT to renew AT on its expiration
    refresh_token varchar(50) NOT NULL,
    creation_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    expiration_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp + interval '1 month'),
    CONSTRAINT pk_refresh_token
        PRIMARY KEY (refresh_token_id),
    CONSTRAINT uq_refresh_token_refresh_token
        UNIQUE (refresh_token),
    CONSTRAINT fk_refresh_token_session_id
        FOREIGN KEY (session_id) REFERENCES oauth.session (session_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);
