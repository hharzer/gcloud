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
    full_name varchar(50) NOT NULL,
    currency_symbol varchar(5) NOT NULL,
    fractional_unit varchar(10) NOT NULL,
    CONSTRAINT pk_currency
        PRIMARY KEY (currency_id),
    CONSTRAINT uq_currency_iso_code
        UNIQUE (iso_code)
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

CREATE TABLE customer.customer (
    customer_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    email varchar(50) NOT NULL,
    first_name varchar(50) NOT NULL,
    last_name varchar(50) NOT NULL,
    birth_date date NOT NULL,
    nationality varchar(2) NOT NULL,
    residence varchar(2) NOT NULL,
    address jsonb NOT NULL,
    registration_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    legal_entity_id uuid NOT NULL,
    CONSTRAINT pk_customer
        PRIMARY KEY (customer_id),
    CONSTRAINT uq_customer_email
        UNIQUE (email),
    CONSTRAINT fk_customer_holds_nationality
        FOREIGN KEY (nationality) REFERENCES reference.country (alpha2_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_customer_lives_in_residence_country
        FOREIGN KEY (residence) REFERENCES reference.country (alpha2_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_customer_belongs_to_legal_entity
        FOREIGN KEY (legal_entity_id) REFERENCES payment.legal_entity (legal_entity_id)
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
    customer_id uuid NOT NULL,
    CONSTRAINT pk_customer_consent
        PRIMARY KEY (customer_consent_id),
    CONSTRAINT fk_customer_consent_is_given_by_customer
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE customer.customer_device (
    customer_device_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    device_type varchar(50) NOT NULL,
    registration_token varchar(50) NOT NULL,
    customer_id uuid NOT NULL,
    CONSTRAINT pk_customer_device
        PRIMARY KEY (customer_device_id),
    CONSTRAINT fk_customer_device_belongs_to_customer
        FOREIGN KEY (customer_id) REFERENCES customer.customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE customer.customer_document (
    customer_document_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    document_type varchar(50) NOT NULL,
    document_dek varchar(50) NOT NULL,
    customer_id uuid NOT NULL,
    CONSTRAINT pk_customer_document
        PRIMARY KEY (customer_document_id),
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

CREATE TABLE customer.beneficiary (
    beneficiary_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    full_name varchar(50) NOT NULL,
    iban varchar(50) NOT NULL,
    registration_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    customer_id uuid NOT NULL,
    CONSTRAINT pk_beneficiary
        PRIMARY KEY (beneficiary_id),
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
    lower_bound numeric(10, 2) NOT NULL,
    upper_bound numeric(10, 2) NOT NULL,
    legal_entity_id uuid NOT NULL,
    CONSTRAINT pk_base_currency
        PRIMARY KEY (base_currency_id),
    CONSTRAINT fk_base_currency_is_valid_currency
        FOREIGN KEY (base_currency) REFERENCES reference.currency (iso_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_base_currency_is_supported_by_legal_entity
        FOREIGN KEY (legal_entity_id) REFERENCES payment.legal_entity (legal_entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TYPE payment.payment_method_type AS
ENUM ('PAYMENT_METHOD_1', 'PAYMENT_METHOD_2');

CREATE TABLE payment.term_currency (
    term_currency_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    term_currency varchar(3),
    payment_method payment.payment_method_type NOT NULL,
    lower_bound numeric(10, 2) NOT NULL,
    upper_bound numeric(10, 2) NOT NULL,
    legal_entity_id uuid NOT NULL,
    correspondent_legal_entity_id uuid NOT NULL,
    CONSTRAINT pk_term_currency
        PRIMARY KEY (term_currency_id),
    CONSTRAINT fk_term_currency_is_valid_currency
        FOREIGN KEY (term_currency) REFERENCES reference.currency (iso_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_term_currency_is_supported_by_legal_entity
        FOREIGN KEY (legal_entity_id) REFERENCES payment.legal_entity (legal_entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_term_currency_has_correspondent_legal_entity
        FOREIGN KEY (correspondent_legal_entity_id)
        REFERENCES payment.legal_entity (legal_entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE payment.rate (
    rate_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    base_currency varchar(3) NOT NULL,
    rate numeric(10, 4) NOT NULL,
    term_currency varchar(3) NOT NULL,
    is_market_open boolean NOT NULL,
    rate_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    CONSTRAINT pk_rate
        PRIMARY KEY (rate_id),
    CONSTRAINT fk_rate_base_currency_is_valid_currency
        FOREIGN KEY (base_currency) REFERENCES reference.currency (iso_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_rate_term_currency_is_valid_currency
        FOREIGN KEY (term_currency) REFERENCES reference.currency (iso_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT uq_rate_base_currency_and_term_currency
        UNIQUE (base_currency, term_currency)
);

CREATE TABLE payment.quote (
    quote_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    base_amount numeric(10, 2) NOT NULL,
    base_currency varchar(3) NOT NULL,
    fixed_fee numeric(10, 2) NOT NULL,
    variable_fee_percentage numeric(6, 4) NOT NULL,
    rate numeric(10, 4) NOT NULL,
    term_amount numeric(10, 2) NOT NULL,
    term_currency varchar(3) NOT NULL,
    creation_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
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

CREATE TABLE payment.funding_authorization (
    funding_authorization_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    payment_status payment.payment_status_type NOT NULL,
    funding_authorization_details jsonb NOT NULL,
    funding_authorization_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    payment_id uuid NOT NULL,
    CONSTRAINT pk_funding_authorization
        PRIMARY KEY (funding_authorization_id),
    CONSTRAINT fk_funding_authorization_belongs_to_payment
        FOREIGN KEY (payment_id) REFERENCES payment.payment (payment_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE payment.funding_capture (
    funding_capture_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    payment_status payment.payment_status_type NOT NULL,
    funding_capture_details jsonb NOT NULL,
    funding_capture_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    payment_id uuid NOT NULL,
    CONSTRAINT pk_funding_capture
        PRIMARY KEY (funding_capture_id),
    CONSTRAINT fk_funding_capture_belongs_to_payment
        FOREIGN KEY (payment_id) REFERENCES payment.payment (payment_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE payment.payment_fx (
    payment_fx_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    sell_amount numeric(10, 2) NOT NULL,
    sell_currency varchar(3) NOT NULL,
    mid_market_rate numeric(10, 4) NOT NULL,
    rate numeric(10, 4) NOT NULL,
    buy_amount numeric(10, 2) NOT NULL,
    buy_currency varchar(3) NOT NULL,
    fx_reference varchar(50) NOT NULL,
    payment_status payment.payment_status_type NOT NULL,
    fx_trading_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    payment_id uuid NOT NULL,
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
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE payment.payment_settlement (
    payment_settlement_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    payment_status payment.payment_status_type NOT NULL,
    payment_provider_id uuid NOT NULL,
    payment_provider_reference varchar(50) NOT NULL,
    payment_settlement_details jsonb NOT NULL,
    payment_settlement_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    payment_id uuid NOT NULL,
    CONSTRAINT pk_payment_settlement
        PRIMARY KEY (payment_settlement_id),
    CONSTRAINT fk_payment_settlement_belongs_to_payment
        FOREIGN KEY (payment_id) REFERENCES payment.payment (payment_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_payment_settlement_provider_is_legal_entity
        FOREIGN KEY (payment_provider_id)
        REFERENCES payment.legal_entity (legal_entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT uq_payment_provider_and_payment_provider_reference
        UNIQUE (payment_provider_id, payment_provider_reference)
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
    creation_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    account_owner_id uuid NOT NULL,
    CONSTRAINT pk_account
        PRIMARY KEY (account_id),
    CONSTRAINT fk_account_currency_is_valid_currency
        FOREIGN KEY (currency) REFERENCES reference.currency (iso_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_account_owner_is_legal_entity
        FOREIGN KEY (account_owner_id) REFERENCES payment.legal_entity (legal_entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE ledger.external_account (
    external_account_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    account_number varchar(50) NOT NULL,
    accounting_code varchar(50) NOT NULL,
    suplementary_reference varchar(50) NOT NULL,
    creation_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    account_id uuid NOT NULL,
    account_correspondent_id uuid NOT NULL,
    CONSTRAINT pk_external_account
        PRIMARY KEY (external_account_id),
    CONSTRAINT fk_external_account_belongs_and_extends_account
        FOREIGN KEY (account_id) REFERENCES ledger.account (account_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_external_account_correspondent_is_legal_entity
        FOREIGN KEY (account_correspondent_id)
        REFERENCES payment.legal_entity (legal_entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE ledger.account_balance (
    account_balance_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    balance_date date NOT NULL
        DEFAULT date_trunc('days', current_timestamp),
    opening_balance numeric(10, 2) NOT NULL,
    credit_count integer NOT NULL,
    credit_amount numeric(10, 2) NOT NULL,
    debit_count integer NOT NULL,
    debit_amount numeric(10, 2) NOT NULL,
    closing_balance numeric(10, 2) NOT NULL,
    account_id uuid NOT NULL,
    CONSTRAINT pk_account_balance
        PRIMARY KEY (account_balance_id),
    CONSTRAINT fk_account_balance_belongs_to_account
        FOREIGN KEY (account_id) REFERENCES ledger.account (account_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE ledger.account_transaction (
    account_transaction_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    subject varchar(50) NOT NULL,
    currency varchar(3) NOT NULL,
    transaction_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    payment_id uuid NOT NULL,
    CONSTRAINT pk_account_transaction
        PRIMARY KEY (account_transaction_id),
    CONSTRAINT fk_account_transaction_currency_is_valid_currency
        FOREIGN KEY (currency) REFERENCES reference.currency (iso_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_account_transaction_belongs_to_payment
        FOREIGN KEY (payment_id) REFERENCES payment.payment (payment_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE ledger.transaction_entry (
    transaction_entry_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    entry_amount numeric(10, 2) NOT NULL,
    entry_reference varchar(50),
    account_id uuid NOT NULL,
    account_transaction_id uuid NOT NULL,
    CONSTRAINT pk_transaction_entry
        PRIMARY KEY (transaction_entry_id),
    CONSTRAINT fk_transaction_entry_belongs_to_account
        FOREIGN KEY (account_id) REFERENCES ledger.account (account_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_transaction_entry_belongs_to_account_transaction
        FOREIGN KEY (account_transaction_id)
        REFERENCES ledger.account_transaction (account_transaction_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE SCHEMA reconciliation;

CREATE TABLE reconciliation.external_transaction (
    external_transaction_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    transaction_amount numeric(10, 2) NOT NULL,
    transaction_reference varchar(50) NOT NULL,
    transaction_details jsonb NOT NULL,
    transaction_ts timestamptz NOT NULL,
    external_account_id uuid NOT NULL,
    CONSTRAINT pk_external_transaction
        PRIMARY KEY (external_transaction_id),
    CONSTRAINT fk_external_transaction_belongs_to_external_account
        FOREIGN KEY (external_account_id)
        REFERENCES ledger.external_account (external_account_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE reconciliation.reconciliation (
    reconciliation_id uuid NOT NULL
        DEFAULT gen_random_uuid(),
    subject varchar(50) NOT NULL,
    reconciliation_details jsonb,
    reconciliation_ts timestamptz NOT NULL
        DEFAULT date_trunc('milliseconds', current_timestamp),
    transaction_entry_id uuid NOT NULL,
    external_transaction_id uuid NOT NULL,
    CONSTRAINT pk_reconciliation
        PRIMARY KEY (reconciliation_id),
    CONSTRAINT fk_reconciliation_verifies_transaction_entry
        FOREIGN KEY (transaction_entry_id)
        REFERENCES ledger.transaction_entry (transaction_entry_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_reconciliation_verifies_external_transaction
        FOREIGN KEY (external_transaction_id)
        REFERENCES reconciliation.external_transaction (external_transaction_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);
