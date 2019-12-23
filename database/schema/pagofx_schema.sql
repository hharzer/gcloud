CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA util;

CREATE TABLE util.country (
    country_id uuid NOT NULL
        DEFAULT uuid_generate_v4(),
    alpha2_code varchar(2) NOT NULL,
    alpha3_code varchar(3) NOT NULL,
    full_name varchar(50) NOT NULL,
    CONSTRAINT pk_country
        PRIMARY KEY (country_id),
    CONSTRAINT uq_country_alpha2_code
        UNIQUE (alpha2_code),
    CONSTRAINT uq_country_alpha3_code
        UNIQUE (alpha3_code)
);

CREATE TABLE util.currency (
    currency_id uuid NOT NULL,
    iso_code varchar(3) NOT NULL,
    full_name varchar(50) NOT NULL,
    currency_symbol varchar(5) NOT NULL,
    fractional_unit varchar(10) NOT NULL,
    CONSTRAINT pk_currency
        PRIMARY KEY (currency_id),
    CONSTRAINT uq_country_iso_code
        UNIQUE (iso_code)
);

CREATE TABLE util.legal_entity (
    legal_entity_id uuid NOT NULL,
    full_name varchar(50) NOT NULL,
    licence_number varchar(50) NOT NULL,
    address jsonb NOT NULL,
    is_external boolean,
    branch_parent uuid,
    registration_country varchar(2) NOT NULL,
    operation_countries jsonb NOT NULL,
    creation_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    CONSTRAINT pk_legal_entity
        PRIMARY KEY (legal_entity_id),
    CONSTRAINT fk_legal_entity_branch_parent
        FOREIGN KEY (branch_parent) REFERENCES util.legal_entity (legal_entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_legal_entity_registration_country
        FOREIGN KEY (registration_country) REFERENCES util.country (alpha2_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE SCHEMA customer;

CREATE TABLE customer.customer (
    customer_id uuid NOT NULL
        DEFAULT uuid_generate_v4(),
    -- Customer is uniquely identified by an email
    email varchar(50) NOT NULL,
    legal_entity_id uuid NOT NULL,
    -- Residence country uniquely identifies the leagal entity that customer belongs to
    first_name varchar(50) NOT NULL,
    last_name varchar(50) NOT NULL,
    birth_date date NOT NULL,
    nationality varchar(2) NOT NULL,
    residence varchar(2) NOT NULL,
    address jsonb NOT NULL,
    registration_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    CONSTRAINT pk_customer
        PRIMARY KEY (customer_id),
    CONSTRAINT uq_customer_email
        UNIQUE (email),
    CONSTRAINT fk_customer_legal_entity_id
        FOREIGN KEY (legal_entity_id) REFERENCES util.legal_entity (legal_entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_customer_residence_country
        FOREIGN KEY (residence) REFERENCES util.country (alpha2_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_customer_nationality
        FOREIGN KEY (nationality) REFERENCES util.country (alpha2_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TYPE customer.consent_permission_type AS
ENUM ('PERMITTED', 'NOT_PERMITTED', 'BLOCKED');

CREATE TABLE customer.customer_consent (
    customer_consent_id uuid NOT NULL,
    customer_id uuid NOT NULL,
    feature_promotion_permission customer.consent_permission_type NOT NULL,
    payment_process_permission customer.consent_permission_type NOT NULL,
    help_to_improve_permission customer.consent_permission_type NOT NULL,
    CONSTRAINT pk_customer_consent
        PRIMARY KEY (customer_consent_id),
    CONSTRAINT fk_customer_consent_customer_id
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE customer.customer_device (
    customer_device_id uuid NOT NULL,
    customer_id uuid NOT NULL,
    CONSTRAINT pk_customer_device
        PRIMARY KEY (customer_device_id),
    CONSTRAINT fk_customer_device_customer_id
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE customer.customer_document (
    customer_document_id uuid NOT NULL,
    customer_id uuid NOT NULL,
    CONSTRAINT pk_customer_document
        PRIMARY KEY (customer_document_id),
    CONSTRAINT fk_customer_document_customer_id
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE customer.customer_review (
    customer_review_id uuid NOT NULL,
    customer_id uuid NOT NULL,
    CONSTRAINT pk_customer_review
        PRIMARY KEY (customer_review_id),
    CONSTRAINT fk_customer_review_customer_id
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE customer.customer_risk_profile (
    customer_risk_profile_id uuid NOT NULL,
    customer_id uuid NOT NULL,
    CONSTRAINT pk_customer_risk_profile
        PRIMARY KEY (customer_risk_profile_id),
    CONSTRAINT fk_customer_risk_profile_customer_id
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE customer.customer_business_profile (
    customer_business_profile_id uuid NOT NULL,
    customer_id uuid NOT NULL,
    CONSTRAINT pk_customer_business_profile
        PRIMARY KEY (customer_business_profile_id),
    CONSTRAINT fk_customer_business_profile_customer_id
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE customer.beneficiary (
    beneficiary_id uuid NOT NULL
        DEFAULT uuid_generate_v4(),
    -- Beneficiary belongs only to one customer
    customer_id uuid NOT NULL,
    full_name varchar(50) NOT NULL,
    iban varchar(50) NOT NULL,
    registration_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    CONSTRAINT pk_beneficiary
        PRIMARY KEY (beneficiary_id),
    CONSTRAINT fk_beneficiary_customer_id
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE SCHEMA payment;

CREATE TABLE payment.quote (
    quote_id uuid NOT NULL
        DEFAULT uuid_generate_v4(),
    -- Quotes are associated to a customer
    customer_id uuid NOT NULL,
    base_amount numeric(10, 2) NOT NULL,
    base_currency varchar(3) NOT NULL,
    fixed_fee numeric(10, 2) NOT NULL
        DEFAULT 0.00,
    variable_fee_percentage numeric(6, 4) NOT NULL
        DEFAULT 0.0000,
    rate numeric(10, 4) NOT NULL,
    term_amount numeric(10, 2) NOT NULL,
    term_currency varchar(3) NOT NULL,
    creation_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    CONSTRAINT pk_quote
        PRIMARY KEY (quote_id),
    CONSTRAINT fk_quote_customer_id
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_quote_base_currency
        FOREIGN KEY (base_currency) REFERENCES util.currency (iso_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_quote_term_currency
        FOREIGN KEY (term_currency) REFERENCES util.currency (iso_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    -- varaible_fee = base_amount * variable_fee_percentage
    -- total_fee = fixed_fee + variable_fee
    -- principal = base_amount - total_fee
    -- princiapl * rate = term_amount
    CONSTRAINT ch_quote_base_amount_term_amount
        CHECK (term_amount =
            (base_amount - (fixed_fee + base_amount * variable_fee_percentage)) * rate)
);

CREATE TABLE payment.payment (
    payment_id uuid NOT NULL,
    payment_reference varchar(50) NOT NULL,
    customer_id uuid NOT NULL,
    beneficiary_id uuid NOT NULL,
    quote_id uuid NOT NULL,
    creation_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    CONSTRAINT fk_payment
        PRIMARY KEY (payment_id),
    CONSTRAINT uq_payment_payment_reference
        UNIQUE (payment_reference),
    CONSTRAINT fk_payment_customer_id
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_payment_beneficiary_id
        FOREIGN KEY (beneficiary_id) REFERENCES customer.beneficiary (beneficiary_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_payment_quote_id
        FOREIGN KEY (quote_id) REFERENCES payment.quote (quote_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TYPE payment.payment_status_type AS
ENUM (
    'INITIATED',
    'FUNDS_AUTHORIZED',
    'FUNDS_AUTHORIZATION_REJECTED',
    'FUNDS_CAPTURED',
    'FUNDS_CAPTURE_FAILED',
    'FX_TRADED',
    'FX_FAILED',
    'PAYMENT_SETTLED',
    'PAYMENT_REJECTED',
    'SETTLED',
    'REJECTED'
);

CREATE TABLE payment.payment_status (
    payment_status_id uuid NOT NULL,
    payment_id uuid NOT NULL,
    payment_status payment.payment_status_type NOT NULL,
    payment_status_details jsonb,
    payment_status_reason jsonb,
    creation_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    CONSTRAINT pk_payment_status
        PRIMARY KEY (payment_status_id),
    CONSTRAINT fk_payment_payment_id
        FOREIGN KEY (payment_id) REFERENCES payment.payment (payment_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

ALTER TABLE payment.payment
ADD COLUMN last_payment_status_id uuid NOT NULL,
ADD CONSTRAINT fk_payment_last_payment_status_id
    FOREIGN KEY (last_payment_status_id)
    REFERENCES payment.payment_status (payment_status_id)
    ON UPDATE RESTRICT ON DELETE RESTRICT;

CREATE TABLE payment.payment_funding_authorization (
    payment_finding_authorization_id uuid NOT NULL,
    payment_id uuid NOT NULL,
    payment_status payment.payment_status_type NOT NULL,
    funding_authorization jsonb NOT NULL,
    authorization_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    CONSTRAINT pk_payment_funding_authorization
        PRIMARY KEY (payment_finding_authorization_id),
    CONSTRAINT fk_payment_funding_authorization_payment_id
        FOREIGN KEY (payment_id) REFERENCES payment.payment (payment_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE payment.payment_funding_capture (
    payment_finding_capture_id uuid NOT NULL,
    payment_id uuid NOT NULL,
    payment_status payment.payment_status_type NOT NULL,
    funding_capture jsonb NOT NULL,
    capture_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    CONSTRAINT pk_payment_funding_capture
        PRIMARY KEY (payment_finding_capture_id),
    CONSTRAINT fk_payment_funding_capture_payment_id
        FOREIGN KEY (payment_id) REFERENCES payment.payment (payment_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE payment.payment_fx (
    payment_fx_id uuid NOT NULL,
    payment_id uuid NOT NULL,
    sell_amount numeric(10, 2) NOT NULL,
    sell_currency varchar(3) NOT NULL,
    mid_market_rate numeric(10, 4) NOT NULL,
    rate numeric(10, 4) NOT NULL,
    buy_amount numeric(10, 2) NOT NULL,
    buy_currency varchar(3) NOT NULL,
    fx_reference varchar(50) NOT NULL,
    payment_status payment.payment_status_type NOT NULL,
    trading_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    CONSTRAINT pk_payment_fx
        PRIMARY KEY (payment_fx_id),
    CONSTRAINT fk_payment_fx_payment_id
        FOREIGN KEY (payment_id) REFERENCES payment.payment (payment_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_payment_fx_sell_currency
        FOREIGN KEY (sell_currency) REFERENCES util.currency (iso_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_payment_fx_buy_currency
        FOREIGN KEY (buy_currency) REFERENCES util.currency (iso_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE payment.payment_settlement (
    payment_settlement_id uuid NOT NULL,
    payment_id uuid NOT NULL,
    payment_status payment.payment_status_type NOT NULL,
    payment_settlement jsonb NOT NULL,
    payment_provider uuid NOT NULL,
    payment_provider_reference varchar(50) NOT NULL,
    settlement_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    CONSTRAINT pk_payment_settlement
        PRIMARY KEY (payment_settlement_id),
    CONSTRAINT fk_payment_settlement_payment_id
        FOREIGN KEY (payment_id) REFERENCES payment.payment (payment_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_payment_settlement_payment_provider
        FOREIGN KEY (payment_provider) REFERENCES util.legal_entity (legal_entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT uq_payment_payment_provider_payment_provider_reference
        UNIQUE (payment_provider, payment_provider_reference)
);

CREATE TYPE payment.payment_check_status_type AS
ENUM ('INITIATED', 'UNDER_REVIEW', 'ACCEPTED', 'REJECTED');

CREATE TABLE payment.payment_check (
    payment_check_id uuid NOT NULL,
    customer_id uuid NOT NULL,
    beneficiary_id uuid NOT NULL,
    payment_id uuid NOT NULL,
    payment_check_status_details jsonb,
    payment_check_status payment.payment_check_status_type,
    payment_check_status_reason jsonb,
    check_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    CONSTRAINT pk_payment_check
        PRIMARY KEY (payment_check_id),
    CONSTRAINT fk_payment_check_customer_id
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_payment_check_beneficiary_id
        FOREIGN KEY (beneficiary_id) REFERENCES customer.beneficiary (beneficiary_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_payment_check_payment_id
        FOREIGN KEY (payment_id) REFERENCES payment.payment (payment_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
)
