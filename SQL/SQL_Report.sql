/*
Final Professional Report Text

The SQL phase of this project was executed in MySQL and served as the foundational layer for 
preparing the RavenStack dataset for downstream analytics. Because the dataset is multi-table 
and relational by design, SQL was used not only for raw data ingestion, but also for structural 
validation, schema standardization, and relational integration across the five core entities: 
accounts, subscriptions, feature usage, support tickets, and churn events. This stage was 
essential to ensure that the dataset was analytically reliable before moving into Python-based 
feature engineering, exploratory analysis, and dashboard development. 

The first SQL stage focused on raw data loading and schema inspection. Each CSV source was 
imported into a dedicated raw table in MySQL, after which row-level validation and structural 
inspection were conducted using record counts and table descriptions. The review of the imported 
schemas showed that several important fields were initially stored using non-optimal data types, 
including identifier columns stored as generic text, date and datetime columns stored as text, 
boolean-style flags stored as text, and selected financial fields stored using less suitable 
numeric formats. This was observed across the source tables representing account profile, 
subscription lifecycle, product behavior, support operations, and churn events. 

To address these issues, a typed layer was created in MySQL as a cleaned structural equivalent of
the raw source. In this typed layer, identifier fields were standardized into structured `VARCHAR`
columns, date fields such as `signup_date`, `start_date`, `end_date`, `usage_date`, and 
`churn_date` were converted into `DATE`, timestamp fields such as `submitted_at` and `closed_at` 
were converted into `DATETIME`, boolean-style business flags were transformed into `TINYINT(1)`, 
and financial values such as MRR, ARR, and refund amounts were standardized into 
decimal-compatible types. This approach preserved the raw tables unchanged while producing 
a cleaner and more analytics-ready relational layer. 

After type standardization, SQL validation was used to assess key integrity and structural 
readiness. Candidate primary-key fields such as `account_id`, `subscription_id`, `usage_id`, 
`ticket_id`, and `churn_event_id` were reviewed, and the validation checks confirmed that 
no null values were present in these key candidates and no duplicate records were found at the 
key level. This result indicated that the imported and standardized tables were structurally 
stable and suitable for the next stage of relational work. In practical terms, this meant that 
the parent-child relationships across the tables could be trusted as a basis for integration 
without immediate concern over broken identifiers or duplicated key records. 

The second SQL stage focused on relational data integration. The relational logic of the 
RavenStack model was operationalized by connecting the five typed tables through the two core 
linking fields, `account_id` and `subscription_id`. In this structure, the accounts table 
functioned as the customer-level anchor, subscriptions introduced commercial lifecycle 
information, feature usage extended the model with product behavior at the subscription level, 
and support tickets and churn events linked back directly to the customer account level. 
SQL was used to verify that these relationships were logically valid and to check for orphan 
records before building analytical views. This ensured that customer-level analysis would be 
based on a connected and internally consistent relational model. 

Once relational integrity was confirmed, SQL joins were used to build the first 
account–subscription analytical base. This base linked customer profile data with 
subscription-level plan, billing, and revenue fields. From there, summarized analytical views 
were created for feature usage, support ticket activity, and churn event history. These summary 
layers were then joined back into a single customer-level analytical base table. The purpose of 
this table was not to replace the original relational model, but to provide a clean unified 
structure that could support downstream analysis more efficiently while preserving grain 
consistency. This integrated output created a stable bridge between the SQL preparation layer 
and the later Python analytics workflow. 

Overall, the SQL phase successfully transformed the RavenStack dataset from a set of 
disconnected raw CSV files into a validated and analytically structured relational foundation. 
The work completed in MySQL ensured clean data types, validated key structure, reliable 
relationships, and a business-ready analytical base for the next stages of the project. 
As a result, the Python phase could begin on top of a technically sound and business-aligned 
dataset, and the same cleaned relational tables remain suitable for future implementation in 
Power BI through a structured semantic model. 

/*
SQL Deliverables

- Typed relational tables for all five source entities
- Referential validation checks
- Orphan-record checks
- Account–subscription base view
- Customer-level analytical base table
*/
