CREATE DATABASE ravenstack_churn;
USE ravenstack_churn;
------------------------------------------
# Showing tabels & validation counts and Descriptions
SHOW TABLES;
SELECT COUNT(*) AS total_rows FROM raw_accounts;
SELECT COUNT(*) AS total_rows FROM raw_subscriptions;
SELECT COUNT(*) AS total_rows FROM raw_feature_usage;
SELECT COUNT(*) AS total_rows FROM raw_support_tickets;
SELECT COUNT(*) AS total_rows FROM raw_churn_events;
----
DESCRIBE raw_accounts;
DESCRIBE raw_subscriptions;
DESCRIBE raw_feature_usage;
DESCRIBE raw_support_tickets;
DESCRIBE raw_churn_events;
 
### Accounts — Type Issues Identified

/* The `raw_accounts` table contains several fields stored with non-optimal data types for analytics in MySQL.  
The following issues were identified:

- `account_id` is stored as `text`, while it should be a shorter structured identifier type such as `VARCHAR(...)`. 【1-9862b2】
- `account_name`, `industry`, `country`, `referral_source`, and `plan_tier` are stored as `text`, which is unnecessarily broad for business descriptors and should be converted to `VARCHAR(...)`. 【1-9862b2】
- `signup_date` is stored as `text`, while it should be converted to `DATE` for time-based analysis. 【1-9862b2】
- `is_trial` and `churn_flag` are stored as `text`, but both represent boolean-style flags and should be converted to `TINYINT(1)` in MySQL. 【1-9862b2】
- `seats` is already stored as `int(11)` and is acceptable as a numeric field. */ 

DROP TABLE IF EXISTS typed_accounts;

CREATE TABLE typed_accounts (
    account_id        VARCHAR(100),
    account_name      VARCHAR(255),
    industry          VARCHAR(100),
    country           VARCHAR(10),
    signup_date       DATE,
    referral_source   VARCHAR(50),
    plan_tier         VARCHAR(50),
    seats             INT,
    is_trial          TINYINT(1),
    churn_flag        TINYINT(1)
);

INSERT INTO typed_accounts (
    account_id,
    account_name,
    industry,
    country,
    signup_date,
    referral_source,
    plan_tier,
    seats,
    is_trial,
    churn_flag
)
SELECT
    NULLIF(TRIM(account_id), '') AS account_id,
    NULLIF(TRIM(account_name), '') AS account_name,
    NULLIF(TRIM(industry), '') AS industry,
    NULLIF(TRIM(country), '') AS country,

    CASE
        WHEN TRIM(LOWER(signup_date)) IN ('', 'null', 'n/a', 'na') THEN NULL
        ELSE STR_TO_DATE(TRIM(signup_date), '%Y-%m-%d')
    END AS signup_date,

    NULLIF(TRIM(referral_source), '') AS referral_source,
    NULLIF(TRIM(plan_tier), '') AS plan_tier,

    CASE
        WHEN TRIM(seats) = '' THEN NULL
        ELSE CAST(seats AS SIGNED)
    END AS seats,

    CASE
        WHEN LOWER(TRIM(is_trial)) IN ('1', 'true', 'yes', 'y') THEN 1
        WHEN LOWER(TRIM(is_trial)) IN ('0', 'false', 'no', 'n') THEN 0
        ELSE NULL
    END AS is_trial,

    CASE
        WHEN LOWER(TRIM(churn_flag)) IN ('1', 'true', 'yes', 'y') THEN 1
        WHEN LOWER(TRIM(churn_flag)) IN ('0', 'false', 'no', 'n') THEN 0
        ELSE NULL
    END AS churn_flag
FROM raw_accounts;
#####################
### Subscriptions — Type Issues Identified

/* The `raw_subscriptions` table contains several fields stored with non-optimal types for analytical and financial work in MySQL.  
The following issues were identified:

- `subscription_id` and `account_id` are stored as `text`, while they are identifiers and should be converted to `VARCHAR(...)`. 【1-898cd5】
- `start_date` and `end_date` are stored as `text`, but both should be converted to `DATE` for lifecycle and retention analysis. 【1-898cd5】
- `plan_tier` and `billing_frequency` are stored as `text`, while they should be stored as `VARCHAR(...)`. 【1-898cd5】
- `mrr_amount` and `arr_amount` are stored as `int(11)`, but these are monetary values and are better modeled as `DECIMAL(12,2)`. 【1-898cd5】
- `is_trial`, `upgrade_flag`, `downgrade_flag`, `churn_flag`, and `auto_renew_flag` are stored as `text`, but they represent boolean-style flags and should be converted to `TINYINT(1)`. 【1-898cd5】
- `seats` is already stored as `int(11)` and is acceptable as a numeric field. */

DROP TABLE IF EXISTS typed_subscriptions;

CREATE TABLE typed_subscriptions (
    subscription_id       VARCHAR(100),
    account_id            VARCHAR(100),
    start_date            DATE,
    end_date              DATE,
    plan_tier             VARCHAR(50),
    seats                 INT,
    mrr_amount            DECIMAL(12,2),
    arr_amount            DECIMAL(12,2),
    is_trial              TINYINT(1),
    upgrade_flag          TINYINT(1),
    downgrade_flag        TINYINT(1),
    churn_flag            TINYINT(1),
    billing_frequency     VARCHAR(20),
    auto_renew_flag       TINYINT(1)
);

INSERT INTO typed_subscriptions (
    subscription_id,
    account_id,
    start_date,
    end_date,
    plan_tier,
    seats,
    mrr_amount,
    arr_amount,
    is_trial,
    upgrade_flag,
    downgrade_flag,
    churn_flag,
    billing_frequency,
    auto_renew_flag
)
SELECT
    NULLIF(TRIM(subscription_id), '') AS subscription_id,
    NULLIF(TRIM(account_id), '') AS account_id,

    CASE
        WHEN NULLIF(TRIM(start_date), '') IS NULL THEN NULL
        WHEN TRIM(start_date) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            THEN STR_TO_DATE(TRIM(start_date), '%Y-%m-%d')
        WHEN TRIM(start_date) REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$'
            THEN STR_TO_DATE(TRIM(start_date), '%c/%e/%Y')
        ELSE NULL
    END AS start_date,

    CASE
        WHEN NULLIF(TRIM(end_date), '') IS NULL THEN NULL
        WHEN TRIM(end_date) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            THEN STR_TO_DATE(TRIM(end_date), '%Y-%m-%d')
        WHEN TRIM(end_date) REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$'
            THEN STR_TO_DATE(TRIM(end_date), '%c/%e/%Y')
        ELSE NULL
    END AS end_date,

    NULLIF(TRIM(plan_tier), '') AS plan_tier,
    seats,
    CAST(NULLIF(TRIM(mrr_amount), '') AS DECIMAL(12,2)) AS mrr_amount,
    CAST(NULLIF(TRIM(arr_amount), '') AS DECIMAL(12,2)) AS arr_amount,

    CASE
        WHEN LOWER(TRIM(is_trial)) IN ('1', 'true', 'yes', 'y') THEN 1
        WHEN LOWER(TRIM(is_trial)) IN ('0', 'false', 'no', 'n') THEN 0
        ELSE NULL
    END AS is_trial,

    CASE
        WHEN LOWER(TRIM(upgrade_flag)) IN ('1', 'true', 'yes', 'y') THEN 1
        WHEN LOWER(TRIM(upgrade_flag)) IN ('0', 'false', 'no', 'n') THEN 0
        ELSE NULL
    END AS upgrade_flag,

    CASE
        WHEN LOWER(TRIM(downgrade_flag)) IN ('1', 'true', 'yes', 'y') THEN 1
        WHEN LOWER(TRIM(downgrade_flag)) IN ('0', 'false', 'no', 'n') THEN 0
        ELSE NULL
    END AS downgrade_flag,

    CASE
        WHEN LOWER(TRIM(churn_flag)) IN ('1', 'true', 'yes', 'y') THEN 1
        WHEN LOWER(TRIM(churn_flag)) IN ('0', 'false', 'no', 'n') THEN 0
        ELSE NULL
    END AS churn_flag,

    NULLIF(TRIM(billing_frequency), '') AS billing_frequency,

    CASE
        WHEN LOWER(TRIM(auto_renew_flag)) IN ('1', 'true', 'yes', 'y') THEN 1
        WHEN LOWER(TRIM(auto_renew_flag)) IN ('0', 'false', 'no', 'n') THEN 0
        ELSE NULL
    END AS auto_renew_flag

FROM raw_subscriptions;
##########################
### Feature Usage — Type Issues Identified

/*  The `raw_feature_usage` table contains several fields stored with non-optimal types for behavioral and time-based analysis.  
The following issues were identified:

- `usage_id` and `subscription_id` are stored as `text`, while they should be converted to `VARCHAR(...)` as structured identifiers. 
- `usage_date` is stored as `text`, but it should be converted to `DATE` for temporal and churn-pattern analysis. 
- `feature_name` is stored as `text`, while `VARCHAR(...)` is more appropriate. 
- `is_beta_feature` is stored as `text`, but it represents a boolean-style flag and should be converted to `TINYINT(1)`. 
- `usage_count`, `usage_duration_secs`, and `error_count` are already stored as integers and are acceptable as numeric fields. */
DROP TABLE IF EXISTS typed_feature_usage;

CREATE TABLE typed_feature_usage (
    usage_id              VARCHAR(100),
    subscription_id       VARCHAR(100),
    usage_date            DATE,
    feature_name          VARCHAR(100),
    usage_count           INT,
    usage_duration_secs   INT,
    error_count           INT,
    is_beta_feature       TINYINT(1)
);

INSERT INTO typed_feature_usage (
    usage_id,
    subscription_id,
    usage_date,
    feature_name,
    usage_count,
    usage_duration_secs,
    error_count,
    is_beta_feature
)
SELECT
    NULLIF(TRIM(usage_id), '') AS usage_id,
    NULLIF(TRIM(subscription_id), '') AS subscription_id,

    CASE
        WHEN NULLIF(TRIM(CAST(usage_date AS CHAR)), '') IS NULL THEN NULL
        WHEN TRIM(CAST(usage_date AS CHAR)) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            THEN CAST(TRIM(CAST(usage_date AS CHAR)) AS DATE)
        WHEN TRIM(CAST(usage_date AS CHAR)) REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$'
            THEN STR_TO_DATE(TRIM(CAST(usage_date AS CHAR)), '%c/%e/%Y')
        ELSE NULL
    END AS usage_date,

    NULLIF(TRIM(feature_name), '') AS feature_name,
    usage_count,
    usage_duration_secs,
    error_count,

    CASE
        WHEN LOWER(TRIM(is_beta_feature)) IN ('1', 'true', 'yes', 'y') THEN 1
        WHEN LOWER(TRIM(is_beta_feature)) IN ('0', 'false', 'no', 'n') THEN 0
        ELSE NULL
    END AS is_beta_feature

FROM raw_feature_usage;
################################
### Support Tickets — Type Issues Identified

/* The `raw_support_tickets` table contains several fields stored with non-optimal types for service quality and operational analysis.  
The following issues were identified:

- `ticket_id` and `account_id` are stored as `text`, while they should be converted to `VARCHAR(...)` as identifiers. 【2-788a9e】
- `submitted_at` and `closed_at` are stored as `text`, but they should be converted to `DATETIME` for support timeline analysis. 【2-788a9e】
- `priority` is stored as `text`, while `VARCHAR(...)` is more appropriate. 
- `satisfaction_score` is stored as `text`, but it represents a numeric score and should be converted to `TINYINT`. 【2-788a9e】
- `escalation_flag` is stored as `text`, but it represents a boolean-style flag and should be converted to `TINYINT(1)`. 【2-788a9e】
- `resolution_time_hours` is already stored as `double`, but for consistency in reporting-oriented analytics it is preferable to convert it to `DECIMAL(10,2)`. 【2-788a9e】
- `first_response_time_minutes` is already stored as `int(11)` and can remain numeric. */

DROP TABLE IF EXISTS typed_support_tickets;

CREATE TABLE typed_support_tickets (
    ticket_id                     VARCHAR(100),
    account_id                    VARCHAR(100),
    submitted_at                  DATETIME,
    closed_at                     DATETIME,
    resolution_time_hours         DECIMAL(10,2),
    priority                      VARCHAR(20),
    first_response_time_minutes   INT,
    satisfaction_score            TINYINT,
    escalation_flag               TINYINT(1)
);

INSERT INTO typed_support_tickets (
    ticket_id,
    account_id,
    submitted_at,
    closed_at,
    resolution_time_hours,
    priority,
    first_response_time_minutes,
    satisfaction_score,
    escalation_flag
)
SELECT
    NULLIF(TRIM(ticket_id), '') AS ticket_id,
    NULLIF(TRIM(account_id), '') AS account_id,

    CASE
        WHEN NULLIF(TRIM(CAST(submitted_at AS CHAR)), '') IS NULL THEN NULL
        WHEN TRIM(CAST(submitted_at AS CHAR)) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            THEN STR_TO_DATE(TRIM(CAST(submitted_at AS CHAR)), '%Y-%m-%d')
        WHEN TRIM(CAST(submitted_at AS CHAR)) REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$'
            THEN STR_TO_DATE(TRIM(CAST(submitted_at AS CHAR)), '%c/%e/%Y')
        ELSE NULL
    END AS submitted_at,

    CASE
        WHEN NULLIF(TRIM(CAST(closed_at AS CHAR)), '') IS NULL THEN NULL
        WHEN TRIM(CAST(closed_at AS CHAR)) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$'
            THEN STR_TO_DATE(TRIM(CAST(closed_at AS CHAR)), '%Y-%m-%d %H:%i:%s')
        WHEN TRIM(CAST(closed_at AS CHAR)) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}$'
            THEN STR_TO_DATE(TRIM(CAST(closed_at AS CHAR)), '%Y-%m-%d %H:%i')
        WHEN TRIM(CAST(closed_at AS CHAR)) REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4} [0-9]{1,2}:[0-9]{2}$'
            THEN STR_TO_DATE(TRIM(CAST(closed_at AS CHAR)), '%c/%e/%Y %k:%i')
        WHEN TRIM(CAST(closed_at AS CHAR)) REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$'
            THEN STR_TO_DATE(TRIM(CAST(closed_at AS CHAR)), '%c/%e/%Y')
        ELSE NULL
    END AS closed_at,

    CAST(NULLIF(TRIM(resolution_time_hours), '') AS DECIMAL(10,2)) AS resolution_time_hours,
    NULLIF(TRIM(priority), '') AS priority,
    CAST(NULLIF(TRIM(first_response_time_minutes), '') AS UNSIGNED) AS first_response_time_minutes,
    CAST(CAST(NULLIF(TRIM(satisfaction_score), '') AS DECIMAL(3,1)) AS UNSIGNED) AS satisfaction_score,

    CASE
        WHEN LOWER(TRIM(escalation_flag)) IN ('1', 'true', 'yes', 'y') THEN 1
        WHEN LOWER(TRIM(escalation_flag)) IN ('0', 'false', 'no', 'n') THEN 0
        ELSE NULL
    END AS escalation_flag

FROM raw_support_tickets;
############################
### Churn Events — Type Issues Identified

/* The `raw_churn_events` table contains several fields stored with non-optimal types for churn and retention analysis.  
The following issues were identified:

- `churn_event_id` and `account_id` are stored as `text`, while they should be converted to `VARCHAR(...)` as identifiers.
- `churn_date` is stored as `text`, but it should be converted to `DATE` for churn-timing analysis. 
- `reason_code` is stored as `text`, while `VARCHAR(...)` is a better fit for structured churn categories. 
- `preceding_upgrade_flag`, `preceding_downgrade_flag`, and `is_reactivation` are stored as `text`, but all represent boolean-style flags and should be converted to `TINYINT(1)`. 
- `refund_amount_usd` is stored as `double`, but for financial reporting it is preferable to convert it to `DECIMAL(12,2)`. 
- `feedback_text` can remain `TEXT` because it is an optional free-text field. */

DROP TABLE IF EXISTS typed_churn_events;

CREATE TABLE typed_churn_events (
    churn_event_id                VARCHAR(100),
    account_id                    VARCHAR(100),
    churn_date                    DATE,
    reason_code                   VARCHAR(100),
    refund_amount_usd             DECIMAL(12,2),
    preceding_upgrade_flag        TINYINT(1),
    preceding_downgrade_flag      TINYINT(1),
    is_reactivation               TINYINT(1),
    feedback_text                 TEXT
);

INSERT INTO typed_churn_events (
    churn_event_id,
    account_id,
    churn_date,
    reason_code,
    refund_amount_usd,
    preceding_upgrade_flag,
    preceding_downgrade_flag,
    is_reactivation,
    feedback_text
)
SELECT
    NULLIF(TRIM(churn_event_id), '') AS churn_event_id,
    NULLIF(TRIM(account_id), '') AS account_id,

    CASE
        WHEN NULLIF(TRIM(CAST(churn_date AS CHAR)), '') IS NULL THEN NULL
        WHEN TRIM(CAST(churn_date AS CHAR)) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            THEN STR_TO_DATE(TRIM(CAST(churn_date AS CHAR)), '%Y-%m-%d')
        WHEN TRIM(CAST(churn_date AS CHAR)) REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$'
            THEN STR_TO_DATE(TRIM(CAST(churn_date AS CHAR)), '%c/%e/%Y')
        ELSE NULL
    END AS churn_date,

    NULLIF(TRIM(reason_code), '') AS reason_code,
    CAST(NULLIF(TRIM(refund_amount_usd), '') AS DECIMAL(12,2)) AS refund_amount_usd,

    CASE
        WHEN LOWER(TRIM(preceding_upgrade_flag)) IN ('1', 'true', 'yes', 'y') THEN 1
        WHEN LOWER(TRIM(preceding_upgrade_flag)) IN ('0', 'false', 'no', 'n') THEN 0
        ELSE NULL
    END AS preceding_upgrade_flag,

    CASE
        WHEN LOWER(TRIM(preceding_downgrade_flag)) IN ('1', 'true', 'yes', 'y') THEN 1
        WHEN LOWER(TRIM(preceding_downgrade_flag)) IN ('0', 'false', 'no', 'n') THEN 0
        ELSE NULL
    END AS preceding_downgrade_flag,

    CASE
        WHEN LOWER(TRIM(is_reactivation)) IN ('1', 'true', 'yes', 'y') THEN 1
        WHEN LOWER(TRIM(is_reactivation)) IN ('0', 'false', 'no', 'n') THEN 0
        ELSE NULL
    END AS is_reactivation,

    NULLIF(TRIM(feedback_text), '') AS feedback_text

FROM raw_churn_events;
##############################
DESCRIBE typed_accounts;
DESCRIBE typed_subscriptions;
DESCRIBE typed_feature_usage;
DESCRIBE typed_support_tickets;
DESCRIBE typed_churn_events;

SELECT COUNT(*) FROM typed_accounts;
SELECT COUNT(*) FROM typed_subscriptions;
SELECT COUNT(*) FROM typed_feature_usage;
SELECT COUNT(*) FROM typed_support_tickets;
SELECT COUNT(*) FROM typed_churn_events;
