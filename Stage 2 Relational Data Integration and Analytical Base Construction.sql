/*
At the relational integration stage, SQL was used to operationalize the logical connections 
between the RavenStack tables and transform them into a business-ready analytical structure. 
The process began with referential validation to confirm that the child entities were correctly 
linked to their parent tables through `account_id` and `subscription_id`. 
After relationship integrity was verified, SQL joins were used to build 
a base account–subscription view, followed by controlled aggregation of feature usage, 
support activity, and churn events into account-oriented and subscription-oriented summary layers.
 These outputs were then combined into a unified analytical table designed to preserve grain 
 consistency while enabling downstream Python-based feature engineering, exploratory analysis, 
 and churn intelligence work. 
 */

/*
Step 2.1A
Check whether parent keys exist and are not null
*/

SELECT COUNT(*) AS null_account_ids
FROM typed_accounts
WHERE account_id IS NULL OR account_id = '';

SELECT COUNT(*) AS null_subscription_ids
FROM typed_subscriptions
WHERE subscription_id IS NULL OR subscription_id = '';
##########################################
/*
Step 2.1B
Check for duplicate parent keys
*/

SELECT account_id, COUNT(*) AS duplicate_count
FROM typed_accounts
GROUP BY account_id
HAVING COUNT(*) > 1;

SELECT subscription_id, COUNT(*) AS duplicate_count
FROM typed_subscriptions
GROUP BY subscription_id
HAVING COUNT(*) > 1;
############################################
/*
Find subscriptions that do not match any account
*/

SELECT s.account_id, COUNT(*) AS orphan_rows
FROM typed_subscriptions s
LEFT JOIN typed_accounts a
    ON s.account_id = a.account_id
WHERE a.account_id IS NULL
GROUP BY s.account_id;
##

/*
Find usage rows that do not match any subscription
*/

SELECT fu.subscription_id, COUNT(*) AS orphan_rows
FROM typed_feature_usage fu
LEFT JOIN typed_subscriptions s
    ON fu.subscription_id = s.subscription_id
WHERE s.subscription_id IS NULL
GROUP BY fu.subscription_id;
##

/*
Find support tickets that do not match any account
*/

SELECT st.account_id, COUNT(*) AS orphan_rows
FROM typed_support_tickets st
LEFT JOIN typed_accounts a
    ON st.account_id = a.account_id
WHERE a.account_id IS NULL
GROUP BY st.account_id;
##
/*
Find churn events that do not match any account
*/
###################################

SELECT ce.account_id, COUNT(*) AS orphan_rows
FROM typed_churn_events ce
LEFT JOIN typed_accounts a
    ON ce.account_id = a.account_id
WHERE a.account_id IS NULL
GROUP BY ce.account_id;
#####
DROP VIEW IF EXISTS vw_account_subscription_base;

CREATE VIEW vw_account_subscription_base AS
SELECT
    a.account_id,
    a.account_name,
    a.industry,
    a.country,
    a.signup_date,
    a.referral_source,
    a.plan_tier AS initial_plan_tier,
    a.seats AS account_seats,
    a.is_trial AS account_is_trial,
    a.churn_flag AS account_churn_flag,

    s.subscription_id,
    s.start_date,
    s.end_date,
    s.plan_tier AS subscription_plan_tier,
    s.seats AS subscription_seats,
    s.mrr_amount,
    s.arr_amount,
    s.is_trial AS subscription_is_trial,
    s.upgrade_flag,
    s.downgrade_flag,
    s.churn_flag AS subscription_churn_flag,
    s.billing_frequency,
    s.auto_renew_flag
FROM typed_accounts a
LEFT JOIN typed_subscriptions s
    ON a.account_id = s.account_id;
--
SELECT *
FROM vw_account_subscription_base
LIMIT 10;
#######
-- Feature Usage Summary (by subscription)
DROP VIEW IF EXISTS vw_usage_summary;

CREATE VIEW vw_usage_summary AS
SELECT
    subscription_id,
    COUNT(*) AS usage_event_count,
    COUNT(DISTINCT feature_name) AS unique_features_used,
    SUM(usage_count) AS total_feature_usage,
    SUM(usage_duration_secs) AS total_usage_duration_secs,
    SUM(error_count) AS total_error_count,
    AVG(usage_count) AS avg_usage_count,
    AVG(usage_duration_secs) AS avg_usage_duration_secs,
    MAX(is_beta_feature) AS used_beta_feature
FROM typed_feature_usage
GROUP BY subscription_id;

SELECT *
FROM vw_usage_summary
LIMIT 10;
##########
-- Support Tickets Summary (by account)
DROP VIEW IF EXISTS vw_support_summary;

CREATE VIEW vw_support_summary AS
SELECT
    account_id,
    COUNT(*) AS ticket_count,
    SUM(CASE WHEN escalation_flag = 1 THEN 1 ELSE 0 END) AS escalation_count,
    AVG(resolution_time_hours) AS avg_resolution_time_hours,
    AVG(first_response_time_minutes) AS avg_first_response_time_minutes,
    AVG(satisfaction_score) AS avg_satisfaction_score
FROM typed_support_tickets
GROUP BY account_id;

SELECT *
FROM vw_support_summary
LIMIT 10;
#####
-- Churn Events Summary (by account)
DROP VIEW IF EXISTS vw_churn_summary;

CREATE VIEW vw_churn_summary AS
SELECT
    account_id,
    COUNT(*) AS churn_event_count,
    MAX(churn_date) AS latest_churn_date,
    SUM(refund_amount_usd) AS total_refund_amount_usd,
    MAX(preceding_upgrade_flag) AS any_preceding_upgrade,
    MAX(preceding_downgrade_flag) AS any_preceding_downgrade,
    MAX(is_reactivation) AS any_reactivation
FROM typed_churn_events
GROUP BY account_id;

SELECT *
FROM vw_churn_summary
LIMIT 10;
########################
-- Build One Customer-Level Integrated Table
DROP TABLE IF EXISTS analytical_customer_base;

CREATE TABLE analytical_customer_base AS
SELECT
    b.account_id,
    b.account_name,
    b.industry,
    b.country,
    b.signup_date,
    b.referral_source,
    b.initial_plan_tier,
    b.account_seats,
    b.account_is_trial,
    b.account_churn_flag,

    b.subscription_id,
    b.start_date,
    b.end_date,
    b.subscription_plan_tier,
    b.subscription_seats,
    b.mrr_amount,
    b.arr_amount,
    b.subscription_is_trial,
    b.upgrade_flag,
    b.downgrade_flag,
    b.subscription_churn_flag,
    b.billing_frequency,
    b.auto_renew_flag,

    u.usage_event_count,
    u.unique_features_used,
    u.total_feature_usage,
    u.total_usage_duration_secs,
    u.total_error_count,
    u.avg_usage_count,
    u.avg_usage_duration_secs,
    u.used_beta_feature,

    s.ticket_count,
    s.escalation_count,
    s.avg_resolution_time_hours,
    s.avg_first_response_time_minutes,
    s.avg_satisfaction_score,

    c.churn_event_count,
    c.latest_churn_date,
    c.total_refund_amount_usd,
    c.any_preceding_upgrade,
    c.any_preceding_downgrade,
    c.any_reactivation
FROM vw_account_subscription_base b
LEFT JOIN vw_usage_summary u
    ON b.subscription_id = u.subscription_id
LEFT JOIN vw_support_summary s
    ON b.account_id = s.account_id
LEFT JOIN vw_churn_summary c
    ON b.account_id = c.account_id;

SELECT *
FROM analytical_customer_base
LIMIT 20;
