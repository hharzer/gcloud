CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA reference;

CREATE TABLE reference.country (
    country_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
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

CREATE TABLE reference.currency (
    currency_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    iso_code varchar(3) NOT NULL,
    unit_name varchar(50) NOT NULL,
    fractional_unit_name varchar(50) NOT NULL,
    currency_symbol varchar(5) NOT NULL,
    fractional_unit integer NOT NULL,
    currency_timezone varchar(50) NOT NULL,
    currency_utc_offset interval NOT NULL,
    CONSTRAINT pk_currency
        PRIMARY KEY (currency_id),
    CONSTRAINT uq_currency_iso_code
        UNIQUE (iso_code),
    CONSTRAINT ch_fractional_unit_has_fixed_limit
        CHECK (fractional_unit = ANY ('{0, -1, -2, -3}'::integer[]))
);

CREATE SCHEMA payment;

CREATE TABLE payment.legal_entity (
    legal_entity_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    full_name varchar(50) NOT NULL,
    licence_number varchar(50) NOT NULL,
    address jsonb NOT NULL,
    registration_country varchar(2) NOT NULL,
    operation_countries jsonb NOT NULL,
    is_external boolean NOT NULL,
    creation_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    parent_legal_entity_id uuid,
    CONSTRAINT pk_legal_entity
        PRIMARY KEY (legal_entity_id),
    CONSTRAINT fk_legal_entity_is_registered_in_country
        FOREIGN KEY (registration_country) REFERENCES reference.country (alpha2_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_legal_entity_is_branch_of_parent_legal_entity
        FOREIGN KEY (parent_legal_entity_id)
        REFERENCES payment.legal_entity (legal_entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE SCHEMA customer;

CREATE TYPE customer.customer_type AS
ENUM ('INDIVIDUAL', 'SOLE_TRATED', 'SME');

CREATE TYPE customer.customer_blocking_status_type AS
ENUM ('ACTIVE', 'BLOCKED');

CREATE TABLE customer.customer (
    customer_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    email varchar(50) NOT NULL,
    first_name varchar(50) NOT NULL,
    last_name varchar(50) NOT NULL,
    birth_date date NOT NULL,
    nationalities jsonb NOT NULL,
    residence varchar(2) NOT NULL,
    customer_type customer.customer_type NOT NULL,
    blocking_status customer.customer_blocking_status_type NOT NULL,
    registration_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    legal_entity_id uuid NOT NULL,
    CONSTRAINT pk_customer
        PRIMARY KEY (customer_id),
    CONSTRAINT uq_customer_email
        UNIQUE (email),
    CONSTRAINT fk_customer_lives_in_residence_country
        FOREIGN KEY (residence) REFERENCES reference.country (alpha2_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_customer_belongs_to_legal_entity
        FOREIGN KEY (legal_entity_id) REFERENCES payment.legal_entity (legal_entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE customer.customer_address (
    customer_address_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    address jsonb NOT NULL,
    registration_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    customer_id uuid NOT NULL,
    CONSTRAINT fk_customer_address
        PRIMARY KEY (customer_address_id),
    CONSTRAINT fk_customer_address_belongs_to_customer
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TYPE customer.onboarding_stage_type AS
ENUM (
    'WAITING_FOR_BUSINESS_DETAILS',
    'WAITING_FOR_CUSTOMER_DETAILS',
    'CUSTOMER_DETAILS_COMPLETED',
    'WAITING_FOR_ID_VERIFICATION_DOCUMENTS',
    'ID_VERIFICATION_PENDING',
    'ID_VERIFICATION_NEEDS_REVIEW',
    'ID_VERIFICATION_REJECTED',
    'SCREENING_PENDING',
    'SCREENING_NEEDS_REVIEW',
    'SCREENING_REJECTED',
    'WAITING_FOR_PROOF_OF_ADDRESS_DOCUMENTS',
    'PROOF_OF_ADDRESS_NEEDS_REVIEW',
    'PROOF_OF_ADDRESS_APPROVED',
    'PROOF_OF_ADDRESS_REJECTED',
    'WAITING_FOR_ENHANCED_DUE_DILIGENCE_DOCUMENTS',
    'ENHANCED_DUE_DILIGENCE_NEEDS_REVIEW',
    'ENHANCED_DUE_DILIGENCE_APPROVED',
    'ENHANCED_DUE_DILIGENCE_REJECTED',
    'COMPLETED'
);

CREATE TABLE customer.customer_onboarding (
    customer_onboarding_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    onboarding_stage customer.onboarding_stage_type NOT NULL,
    onboarding_stage_details jsonb NOT NULL,
    onboarding_stage_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    customer_id uuid NOT NULL,
    CONSTRAINT pk_customer_onboarding
        PRIMARY KEY (customer_onboarding_id),
    CONSTRAINT fk_customer_onboarding_tracks_customer_registration_process
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

ALTER TABLE customer.customer
ADD COLUMN last_onboarding_stage_id uuid,
ADD CONSTRAINT fk_customer_is_in_last_onboarding_stage
    FOREIGN KEY (last_onboarding_stage_id)
    REFERENCES customer.customer_onboarding (customer_onboarding_id)
    ON UPDATE RESTRICT ON DELETE RESTRICT;


CREATE TYPE customer.consent_permission_type AS
ENUM ('PERMITTED', 'NOT_PERMITTED', 'BLOCKED');

CREATE TABLE customer.customer_consent (
    customer_consent_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    feature_promotion_permission customer.consent_permission_type NOT NULL,
    payment_process_permission customer.consent_permission_type NOT NULL,
    help_to_improve_permission customer.consent_permission_type NOT NULL,
    update_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    customer_id uuid NOT NULL,
    CONSTRAINT pk_customer_consent
        PRIMARY KEY (customer_consent_id),
    CONSTRAINT fk_customer_consent_is_given_by_customer
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT uq_customer_consent_is_unique_for_customer
        UNIQUE (customer_id)
);

CREATE TABLE customer.customer_device (
    customer_device_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    device_fingerprint varchar(50) NOT NULL,
    device_type varchar(50) NOT NULL,
    registration_token varchar(50) NOT NULL,
    customer_id uuid NOT NULL,
    CONSTRAINT pk_customer_device
        PRIMARY KEY (customer_device_id),
    CONSTRAINT uq_device_fingerprint
        UNIQUE (device_fingerprint),
    CONSTRAINT fk_customer_device_belongs_to_customer
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE customer.customer_document (
    customer_document_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    document_uri varchar(100) NOT NULL,
    document_type varchar(50) NOT NULL,
    document_dek varchar(50) NOT NULL,
    customer_id uuid NOT NULL,
    CONSTRAINT pk_customer_document
        PRIMARY KEY (customer_document_id),
    CONSTRAINT uq_customer_document_uri
        UNIQUE (document_uri),
    CONSTRAINT fk_customer_document_uploaded_by_customer
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE customer.customer_review (
    customer_review_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    review_type varchar(50) NOT NULL,
    review_details jsonb NOT NULL,
    customer_id uuid NOT NULL,
    CONSTRAINT pk_customer_review
        PRIMARY KEY (customer_review_id),
    CONSTRAINT fk_customer_review_describes_customer
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE customer.customer_risk_profile (
    customer_risk_profile_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    risk_profile_details jsonb NOT NULL,
    risk_calculator_version varchar(10) NOT NULL,
    risk_profile_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    risk_profile_override jsonb,
    risk_profile_override_ts timestamptz,
    customer_id uuid NOT NULL,
    CONSTRAINT pk_customer_risk_profile
        PRIMARY KEY (customer_risk_profile_id),
    CONSTRAINT fk_customer_risk_profile_describes_customer
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE customer.customer_business_profile (
    customer_business_profile_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    business_profile_details jsonb NOT NULL,
    customer_id uuid NOT NULL,
    CONSTRAINT pk_customer_business_profile
        PRIMARY KEY (customer_business_profile_id),
    CONSTRAINT fk_customer_business_profile_describes_customer
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TYPE customer.beneficiary_relationship_type AS
ENUM ('SELF_BENEFICIARY', 'FAMILY', 'FRIEND', 'BUSINESS');

CREATE TABLE customer.beneficiary (
    beneficiary_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    full_name varchar(50) NOT NULL,
    iban varchar(50) NOT NULL,
    beneficiary_details jsonb NOT NULL,
    bank_details jsonb NOT NULL,
    rlationship_type customer.beneficiary_relationship_type NOT NULL,
    registration_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    customer_id uuid NOT NULL,
    CONSTRAINT pk_beneficiary
        PRIMARY KEY (beneficiary_id),
    CONSTRAINT fk_beneficiary_is_registred_by_customer
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE customer.customer_audit (
    customer_audit_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    subject varchar(50) NOT NULL,
    old_value jsonb NOT NULL,
    new_value jsonb NOT NULL,
    audit_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    customer_id uuid NOT NULL,
    CONSTRAINT pk_customer_audit
        PRIMARY KEY (customer_audit_id),
    CONSTRAINT fk_beneficiary_is_registred_by_customer
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TYPE payment.funding_method_type AS
ENUM ('FUNDING_METHOD_1', 'FUNDING_METHOD_2');

CREATE TABLE payment.base_currency (
    base_currency_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    base_currency varchar(3),
    funding_method payment.funding_method_type NOT NULL,
    lower_bound numeric(14, 3) NOT NULL,
    upper_bound numeric(14, 3) NOT NULL,
    legal_entity_id uuid NOT NULL,
    correspondent_id uuid NOT NULL,
    CONSTRAINT pk_base_currency
        PRIMARY KEY (base_currency_id),
    CONSTRAINT fk_base_currency_is_valid_currency
        FOREIGN KEY (base_currency) REFERENCES reference.currency (iso_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_base_currency_is_supported_by_legal_entity
        FOREIGN KEY (legal_entity_id) REFERENCES payment.legal_entity (legal_entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_base_currency_has_correspondent_legal_entity
        FOREIGN KEY (correspondent_id) REFERENCES payment.legal_entity (legal_entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TYPE payment.payment_method_type AS
ENUM ('PAYMENT_METHOD_1', 'PAYMENT_METHOD_2');

CREATE TABLE payment.term_currency (
    term_currency_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    term_currency varchar(3),
    payment_method payment.payment_method_type NOT NULL,
    lower_bound numeric(14, 3) NOT NULL,
    upper_bound numeric(14, 3) NOT NULL,
    legal_entity_id uuid NOT NULL,
    correspondent_id uuid NOT NULL,
    CONSTRAINT pk_term_currency
        PRIMARY KEY (term_currency_id),
    CONSTRAINT fk_term_currency_is_valid_currency
        FOREIGN KEY (term_currency) REFERENCES reference.currency (iso_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_term_currency_is_supported_by_legal_entity
        FOREIGN KEY (legal_entity_id) REFERENCES payment.legal_entity (legal_entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_term_currency_has_correspondent_legal_entity
        FOREIGN KEY (correspondent_id) REFERENCES payment.legal_entity (legal_entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE payment.rate (
    rate_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    base_currency varchar(3) NOT NULL,
    rate numeric(17, 7) NOT NULL,
    mid_market_rate numeric(17, 7) NOT NULL,
    term_currency varchar(3) NOT NULL,
    is_market_open boolean NOT NULL,
    rate_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    expiration_ts timestamptz NOT NULL,
    counterparty_id uuid NOT NULL,
    CONSTRAINT pk_rate
        PRIMARY KEY (rate_id),
    CONSTRAINT fk_rate_base_currency_is_valid_currency
        FOREIGN KEY (base_currency) REFERENCES reference.currency (iso_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_rate_term_currency_is_valid_currency
        FOREIGN KEY (term_currency) REFERENCES reference.currency (iso_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT uq_rate_base_currency_and_term_currency
        UNIQUE (base_currency, term_currency),
    CONSTRAINT fk_rate_has_counterparty_legal_entity
        FOREIGN KEY (counterparty_id) REFERENCES payment.legal_entity (legal_entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE payment.quote (
    quote_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    base_amount numeric(14, 3) NOT NULL,
    base_currency varchar(3) NOT NULL,
    fixed_fee numeric(14, 3) NOT NULL,
    variable_fee_percentage numeric(6, 4) NOT NULL,
    rate numeric(17, 7) NOT NULL,
    term_amount numeric(14, 3) NOT NULL,
    term_currency varchar(3) NOT NULL,
    creation_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    expiration_ts timestamptz NOT NULL,
    customer_id uuid NOT NULL,
    CONSTRAINT pk_quote
        PRIMARY KEY (quote_id),
    CONSTRAINT fk_quote_base_currency_is_valid_currency
        FOREIGN KEY (base_currency) REFERENCES reference.currency (iso_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_quote_term_currency_is_valid_currency
        FOREIGN KEY (term_currency) REFERENCES reference.currency (iso_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_quote_is_selected_by_customer
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    -- varaible_fee = base_amount * variable_fee_percentage
    -- total_fee = fixed_fee + variable_fee
    -- principal = base_amount - total_fee
    -- princiapl * rate = term_amount
    CONSTRAINT ch_quote_base_amount_correctly_relates_to_term_amount
        CHECK (term_amount =
            (base_amount - (fixed_fee + base_amount * variable_fee_percentage)) * rate)
);

CREATE TABLE payment.payment (
    payment_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    payment_reference varchar(50) NOT NULL,
    customer_id uuid NOT NULL,
    beneficiary_id uuid NOT NULL,
    quote_id uuid NOT NULL,
    creation_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    CONSTRAINT pk_payment
        PRIMARY KEY (payment_id),
    CONSTRAINT uq_payment_reference
        UNIQUE (payment_reference),
    CONSTRAINT fk_payment_is_requested_by_customer
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_payment_is_directed_to_beneficiary
        FOREIGN KEY (beneficiary_id) REFERENCES customer.beneficiary (beneficiary_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_payment_uses_quote
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
    payment_status_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    payment_status payment.payment_status_type NOT NULL,
    payment_status_details jsonb NOT NULL,
    payment_status_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    payment_id uuid NOT NULL,
    CONSTRAINT pk_payment_status
        PRIMARY KEY (payment_status_id),
    CONSTRAINT fk_payment_status_tracks_payment_progress
        FOREIGN KEY (payment_id) REFERENCES payment.payment (payment_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

ALTER TABLE payment.payment
ADD COLUMN last_payment_status_id uuid,
ADD CONSTRAINT fk_payment_is_in_last_payment_status
    FOREIGN KEY (last_payment_status_id)
    REFERENCES payment.payment_status (payment_status_id)
    ON UPDATE RESTRICT ON DELETE RESTRICT;

CREATE TABLE payment.payment_funding (
    payment_funding_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    payment_status payment.payment_status_type NOT NULL,
    payment_funding_details jsonb NOT NULL,
    payment_funding_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    payment_id uuid NOT NULL,
    CONSTRAINT pk_payment_funding
        PRIMARY KEY (payment_funding_id),
    CONSTRAINT fk_payment_funding_belongs_to_payment
        FOREIGN KEY (payment_id) REFERENCES payment.payment (payment_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE payment.payment_fx (
    payment_fx_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    sell_amount numeric(14, 3) NOT NULL,
    sell_currency varchar(3) NOT NULL,
    sell_ts timestamptz NOT NULL,
    mid_market_rate numeric(17, 7) NOT NULL,
    rate numeric(17, 7) NOT NULL,
    buy_amount numeric(14, 3) NOT NULL,
    buy_currency varchar(3) NOT NULL,
    buy_ts timestamptz NOT NULL,
    fx_reference varchar(50) NOT NULL,
    payment_status payment.payment_status_type NOT NULL,
    payment_id uuid NOT NULL,
    counterparty_id uuid NOT NULL,
    CONSTRAINT pk_payment_fx
        PRIMARY KEY (payment_fx_id),
    CONSTRAINT fk_payment_fx_sell_currency_is_valid_currency
        FOREIGN KEY (sell_currency) REFERENCES reference.currency (iso_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_payment_fx_buy_currency_is_valid_currency
        FOREIGN KEY (buy_currency) REFERENCES reference.currency (iso_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_payment_fx_belongs_to_payment
        FOREIGN KEY (payment_id) REFERENCES payment.payment (payment_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_payment_fx_has_counterparty_legal_entity
        FOREIGN KEY (counterparty_id) REFERENCES payment.legal_entity (legal_entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE payment.payment_fulfillment (
    payment_fulfillment_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    payment_status payment.payment_status_type NOT NULL,
    payment_fulfillment_details jsonb NOT NULL,
    payment_fulfillment_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    payment_id uuid NOT NULL,
    correspondent_id uuid NOT NULL,
    correspondent_reference varchar(50) NOT NULL,
    CONSTRAINT pk_payment_fulfillment
        PRIMARY KEY (payment_fulfillment_id),
    CONSTRAINT fk_payment_fulfillment_belongs_to_payment
        FOREIGN KEY (payment_id) REFERENCES payment.payment (payment_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_payment_fulfillment_has_correspondent_legal_entity
        FOREIGN KEY (correspondent_id)
        REFERENCES payment.legal_entity (legal_entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT uq_correspondent_and_correspondent_reference
        UNIQUE (correspondent_id, correspondent_reference)
);

CREATE TYPE payment.payment_check_status_type AS
ENUM ('INITIATED', 'UNDER_REVIEW', 'ACCEPTED', 'REJECTED');

CREATE TABLE payment.payment_check (
    payment_check_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    payment_check_status payment.payment_check_status_type NOT NULL,
    payment_check_status_details jsonb NOT NULL,
    payment_check_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    customer_id uuid NOT NULL,
    beneficiary_id uuid NOT NULL,
    payment_id uuid NOT NULL,
    CONSTRAINT pk_payment_check
        PRIMARY KEY (payment_check_id),
    CONSTRAINT fk_payment_check_includes_customer
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_payment_check_includes_beneficiary
        FOREIGN KEY (beneficiary_id) REFERENCES customer.beneficiary (beneficiary_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_payment_check_includes_payment
        FOREIGN KEY (payment_id) REFERENCES payment.payment (payment_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE SCHEMA ledger;

CREATE TYPE ledger.account_type AS
ENUM (
    'ACQUIRER_FEES',
    'AML_CONFISCATED',
    'BENEFICIARY_SCREENING',
    'BENEFICIARY_SCREENING_APPROVED',
    'BENEFICIARY_SCREENING_NEEDS_REVIEW',
    'BENEFICIARY_SCREENING_RINGFENCED',
    'CAPTURED',
    'CLIENT_FUNDS_ALLOCATED',
    'CLIENT_FUNDS_UNALLOCATED',
    'CONTROL',
    'CONTROL_CURRENCYCLOUD_MARGIN',
    'CONTROL_MINIMUM_INTRADAY_LIQUIDITY_BALANCE',
    'CONTROL_MINIMUM_MANDATORY_BALANCE',
    'CONTROL_OFFICE',
    'CONTROL_REGULATORY_CAPITAL',
    'CONTROL_SEGREGATED',
    'CURRENCYCLOUD_MARGIN',
    'FUNDING_CAPTURE_SUCCEEDED',
    'HEDGE_INSTRUCTED',
    'HEDGE_PENDING',
    'MARGIN',
    'MARGIN_DUE',
    'MARGIN_DUE_SEGREGATED',
    'MINIMUM_INTRADAY_LIQUIDITY_BALANCE',
    'MINIMUM_MANDATORY_BALANCE',
    'OFFICE',
    'OWN_FUNDS',
    'PAYMENT_INSTRUCTED',
    'PENDING_SETTLEMENT',
    'PENDING_TRANSFER_OUT_OF_SAFEGUARDING',
    'PENDING_TRANSFER_OUT_OF_SAFEGUARDING_SEGREGATED',
    'PRINCIPAL_DUE',
    'PRINCIPAL_DUE_SEGREGATED',
    'RECONCILIATION_BREAKS',
    'REGULATORY_CAPITAL',
    'SETTLED',
    'SUPPLIER_FEES',
    'TRANSACTION_MONITORING',
    'TRANSACTION_MONITORING_APPROVED',
    'TRANSACTION_MONITORING_NEEDS_REVIEW',
    'TRANSACTION_MONITORING_RINGFENCED',
    'VOLATILITY_NEGATIVE',
    'VOLATILITY_POSITIVE',
    'WRITEOFF_FRAUD'
);

CREATE TABLE ledger.account (
    account_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    account_type ledger.account_type NOT NULL,
    currency varchar(3) NOT NULL,
    accounting_code varchar(50) NOT NULL,
    creation_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    owner_id uuid NOT NULL,
    correspondent_id uuid,
    CONSTRAINT pk_account
        PRIMARY KEY (account_id),
    CONSTRAINT fk_account_currency_is_valid_currency
        FOREIGN KEY (currency) REFERENCES reference.currency (iso_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_account_has_owner_legal_entity
        FOREIGN KEY (owner_id) REFERENCES payment.legal_entity (legal_entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_account_has_correspondent_legal_entity
        FOREIGN KEY (correspondent_id) REFERENCES payment.legal_entity (legal_entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE ledger.account_balance (
    account_balance_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    opening_balance numeric(14, 3) NOT NULL,
    credit_count integer NOT NULL,
    credit_amount numeric(14, 3) NOT NULL,
    debit_count integer NOT NULL,
    debit_amount numeric(14, 3) NOT NULL,
    closing_balance numeric(14, 3) NOT NULL,
    balance_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    account_id uuid NOT NULL,
    CONSTRAINT pk_account_balance
        PRIMARY KEY (account_balance_id),
    CONSTRAINT fk_account_balance_belongs_to_account
        FOREIGN KEY (account_id) REFERENCES ledger.account (account_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE ledger.transaction (
    transaction_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    executor varchar(50) NOT NULL,
    currency varchar(3) NOT NULL,
    transaction_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    payment_id uuid,
    CONSTRAINT pk_transaction
        PRIMARY KEY (transaction_id),
    CONSTRAINT fk_transaction_currency_is_valid_currency
        FOREIGN KEY (currency) REFERENCES reference.currency (iso_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_transaction_belongs_to_payment
        FOREIGN KEY (payment_id) REFERENCES payment.payment (payment_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE ledger.account_entry (
    account_entry_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    entry_amount numeric(14, 3) NOT NULL,
    entry_reference varchar(50),
    account_id uuid NOT NULL,
    transaction_id uuid NOT NULL,
    CONSTRAINT pk_account_entry
        PRIMARY KEY (account_entry_id),
    CONSTRAINT fk_account_entry_belongs_to_account
        FOREIGN KEY (account_id) REFERENCES ledger.account (account_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_account_entry_belongs_to_transaction
        FOREIGN KEY (transaction_id) REFERENCES ledger.transaction (transaction_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE SCHEMA reconciliation;

CREATE TABLE reconciliation.external_account (
    external_account_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    account_number varchar(50) NOT NULL,
    suplementary_reference varchar(50) NOT NULL,
    creation_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    correspondent_id uuid NOT NULL,
    account_id uuid NOT NULL,
    CONSTRAINT pk_external_account
        PRIMARY KEY (external_account_id),
    CONSTRAINT fk_external_account_has_correspondent_legal_entity
        FOREIGN KEY (correspondent_id) REFERENCES payment.legal_entity (legal_entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_external_account_belongs_and_extends_account
        FOREIGN KEY (account_id) REFERENCES ledger.account (account_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE reconciliation.external_account_entry (
    external_account_entry_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    entry_amount numeric(14, 3) NOT NULL,
    entry_reference varchar(50) NOT NULL,
    entry_details jsonb NOT NULL,
    entry_ts timestamptz NOT NULL,
    external_account_id uuid NOT NULL,
    CONSTRAINT pk_external_account_entry
        PRIMARY KEY (external_account_entry_id),
    CONSTRAINT fk_external_account_entry_belongs_to_external_account
        FOREIGN KEY (external_account_id)
        REFERENCES reconciliation.external_account (external_account_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE reconciliation.reconciliation (
    reconciliation_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    executor varchar(50) NOT NULL,
    reconciliation_details jsonb,
    reconciliation_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    external_account_entry_id uuid NOT NULL,
    account_entry_id uuid NOT NULL,
    CONSTRAINT pk_reconciliation
        PRIMARY KEY (reconciliation_id),
    CONSTRAINT fk_reconciliation_verifies_external_account_entry
        FOREIGN KEY (external_account_entry_id)
        REFERENCES reconciliation.external_account_entry (external_account_entry_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_reconciliation_verifies_account_entry
        FOREIGN KEY (account_entry_id)
        REFERENCES ledger.account_entry (account_entry_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);
