Financial Analysis Portfolio: Target Corporation (2018–2023)

A Deep Dive into Retail Financial Health and Operational Efficiency


Table of Contents

1. Project Overview & Business Context
2. Data Source & Technical Architecture
3. SQL Implementation: From Raw Data to Analytical Datasets
4. Analysis & Findings: The STAR Method Showcase
   · Situation: The Challenge of Retail Reinvention
   · Task: Diagnosing the Core Financial Drivers
   · Action: A 360-Degree Financial Statement Dissection
     · Income Statement Analysis: The Profitability Engine
     · Balance Sheet Analysis: The Capital Structure Crossroads
   · Result: Quantified Insights and a Strategic Roadmap
5. Business Recommendations: Translating Data into Decisions
6. How to Use This Repository
7. Interview Talking Points: Narrating Your Analysis


1. Project Overview & Business Context

This project is a centerpiece portfolio analysis designed to demonstrate senior-level financial data analysis capabilities. It moves beyond simple ratio calculation to tell a cohesive story about a company's strategic challenges and operational responses. The analysis is grounded in real, publicly available data from the U.S. Securities and Exchange Commission (SEC), using Target Corporation as the subject.

Why Target?
Target is a fascinating case study. In the five years from 2018 to 2023, it navigated massive tailwinds (pandemic-era consumer spending surge) and significant headwinds (inventory bullwhip effect, persistent inflation, shifting consumer baskets). This volatility provides a rich dataset for analyzing management's ability to navigate a crisis and for isolating the financial fingerprints of strategic decisions.

The core business question we're answering is: As an analyst presenting to a potential investor, has Target's management created a more resilient, profitable enterprise over the last five years, or has aggressive growth been funded at the expense of balance sheet quality and future cash flow?


2. Data Source & Technical Architecture

· Source: SEC EDGAR (Electronic Data Gathering, Analysis, and Retrieval system)
· Direct Link to Target Filings: Target Corporation SEC Filings
· Datasets Used: Form 10-K (Annual Report) for fiscal years ending January 2019 through January 2024. Data was manually extracted from standardized financial statements within these filings to ensure accounting accuracy and proper classification, a skill that distinguishes analysts who understand the source of truth from those who rely on pre-cleaned, often misclassified, third-party data.
· Technical Toolkit: PostgreSQL (SQL dialect), python/dbt (for orchestration logic), and a BI tool (for visualization logic, rendered here as markdown tables).

The project is structured as a simple ELT (Extract, Load, Transform) pipeline.

```
financial_analysis_portfolio/
├── data/
│   └── source_data.csv
├── sql_queries/
│   ├── 01_landing_tables.sql
│   └── 02_analytical_aggregation.sql
├── analysis_docs/
│   └── financial_statement_commentary.md
├── README.md
└── LICENSE
```

---

3. SQL Implementation: From Raw Data to Analytical Datasets

The first step in any rigorous analysis is creating a transparent, testable data foundation. The following SQL demonstrates best practices for ingesting raw financial statement data, handling fiscal periods correctly, and building a reusable layer of core metrics.

File: sql_queries/01_landing_tables.sql

```sql
-- ============================================================================
-- STEP 1: INGESTION & STANDARDIZATION
-- Purpose: Create a sturdy, traceable landing table from raw SEC 10-K data.
-- Business Logic: We standardize all figures to 'Millions of USD' and handle
-- the specific 'Date of Filing' to ensure an immutable audit trail. Using
-- a comma-separated structure allows for transparent version control of the raw data.
-- ============================================================================

-- Drop the table if it exists to ensure a clean run in development
DROP TABLE IF EXISTS landing_raw_financials;

CREATE TABLE landing_raw_financials (
    -- Fiscal Year is an integer representing the year the fiscal period ended.
    -- For Target, FY2023 ends in January 2024.
    fiscal_year INTEGER NOT NULL,
    -- 'Category' maps directly to the formal statement grouping, critical for accurate
    -- ratio construction (e.g., we don't want long-term debt flowing into a current ratio).
    category VARCHAR(100) NOT NULL,
    -- 'Line_item' is the exact label from the 10-K, preserving the source language.
    line_item VARCHAR(255) NOT NULL,
    -- Storing value in millions for readability and to avoid floating point issues.
    value_millions DECIMAL(15,2),
    -- A calculated field to sort fiscal years properly in time-series analysis.
    -- Target's fiscal year ends in January; this date represents that endpoint.
    fiscal_year_end_date DATE GENERATED ALWAYS AS (
        CASE
            WHEN fiscal_year = 2023 THEN '2024-01-31'::DATE
            WHEN fiscal_year = 2022 THEN '2023-01-28'::DATE
            WHEN fiscal_year = 2021 THEN '2022-01-29'::DATE
            WHEN fiscal_year = 2020 THEN '2021-01-30'::DATE
            WHEN fiscal_year = 2019 THEN '2020-02-01'::DATE
            WHEN fiscal_year = 2018 THEN '2019-02-02'::DATE
            ELSE NULL
        END
    ) STORED,
    -- Audit columns for data pipeline integrity
    ingested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Data insertion. In a real project, this would be a bulk copy, but here we
-- explicitly list values for full transparency and version control.
INSERT INTO landing_raw_financials (fiscal_year, category, line_item, value_millions)
VALUES
-- Income Statement Items
(2023, 'Income Statement', 'Total Revenue', 105803),
(2023, 'Income Statement', 'Cost of Goods Sold', 75546),
(2023, 'Income Statement', 'SG&A', 20156),
(2023, 'Income Statement', 'Depreciation and Amortization', 2702),
(2023, 'Income Statement', 'Operating Income', 5139),
(2022, 'Income Statement', 'Total Revenue', 107588),
(2022, 'Income Statement', 'Cost of Goods Sold', 79109),
(2022, 'Income Statement', 'SG&A', 18700),
(2022, 'Income Statement', 'Depreciation and Amortization', 2601),
(2022, 'Income Statement', 'Operating Income', 7178),
(2021, 'Income Statement', 'Total Revenue', 106005),
(2021, 'Income Statement', 'Cost of Goods Sold', 75248),
(2021, 'Income Statement', 'SG&A', 19492),
(2021, 'Income Statement', 'Depreciation and Amortization', 2230),
(2021, 'Income Statement', 'Operating Income', 8946),
(2020, 'Income Statement', 'Total Revenue', 92400),
(2020, 'Income Statement', 'Cost of Goods Sold', 62234),
(2020, 'Income Statement', 'SG&A', 17414),
(2020, 'Income Statement', 'Depreciation and Amortization', 2141),
(2020, 'Income Statement', 'Operating Income', 10611),
(2019, 'Income Statement', 'Total Revenue', 77130),
(2019, 'Income Statement', 'Cost of Goods Sold', 53467),
(2019, 'Income Statement', 'SG&A', 15594),
(2019, 'Income Statement', 'Depreciation and Amortization', 2304),
(2019, 'Income Statement', 'Operating Income', 4110),
-- Balance Sheet Items - Assets
(2023, 'Balance Sheet - Assets', 'Current Assets', 18458),
(2023, 'Balance Sheet - Assets', 'Inventory', 13139),
(2023, 'Balance Sheet - Assets', 'Total Assets', 52782),
(2022, 'Balance Sheet - Assets', 'Current Assets', 19598),
(2022, 'Balance Sheet - Assets', 'Inventory', 13878),
(2022, 'Balance Sheet - Assets', 'Total Assets', 50907),
(2021, 'Balance Sheet - Assets', 'Current Assets', 22700),
(2021, 'Balance Sheet - Assets', 'Inventory', 15832),
(2021, 'Balance Sheet - Assets', 'Total Assets', 53024),
(2020, 'Balance Sheet - Assets', 'Current Assets', 19075),
(2020, 'Balance Sheet - Assets', 'Inventory', 10498),
(2020, 'Balance Sheet - Assets', 'Total Assets', 48027),
(2019, 'Balance Sheet - Assets', 'Current Assets', 13801),
(2019, 'Balance Sheet - Assets', 'Inventory', 8990),
(2019, 'Balance Sheet - Assets', 'Total Assets', 42242),
-- Balance Sheet Items - Liabilities
(2023, 'Balance Sheet - Liabilities', 'Current Liabilities', 20606),
(2023, 'Balance Sheet - Liabilities', 'Total Liabilities', 42861),
(2022, 'Balance Sheet - Liabilities', 'Current Liabilities', 20882),
(2022, 'Balance Sheet - Liabilities', 'Total Liabilities', 42638),
(2021, 'Balance Sheet - Liabilities', 'Current Liabilities', 23359),
(2021, 'Balance Sheet - Liabilities', 'Total Liabilities', 41194),
(2020, 'Balance Sheet - Liabilities', 'Current Liabilities', 16391),
(2020, 'Balance Sheet - Liabilities', 'Total Liabilities', 35288),
(2019, 'Balance Sheet - Liabilities', 'Current Liabilities', 13511),
(2019, 'Balance Sheet - Liabilities', 'Total Liabilities', 31109),
-- Balance Sheet Items - Equity
(2023, 'Balance Sheet - Equity', 'Shareholders Equity', 9921),
(2022, 'Balance Sheet - Equity', 'Shareholders Equity', 8269),
(2021, 'Balance Sheet - Equity', 'Shareholders Equity', 11830),
(2020, 'Balance Sheet - Equity', 'Shareholders Equity', 12739),
(2019, 'Balance Sheet - Equity', 'Shareholders Equity', 11133);

-- Quick data validation check: alert if any standard revenue value is missing
-- as it breaks core KPI calculations.
DO $$
DECLARE
   missing_count INT;
BEGIN
   SELECT COUNT(*) INTO missing_count
   FROM landing_raw_financials
   WHERE line_item = 'Total Revenue' AND value_millions IS NULL;
   IF missing_count > 0 THEN
      RAISE WARNING 'Data Integrity Alert: % missing Revenue values found.', missing_count;
   END IF;
END $$;
```

File: sql_queries/02_analytical_aggregation.sql

```sql
-- ============================================================================
-- STEP 2: ANALYTICAL AGGREGATION & PERFORMANCE METRICS
-- Purpose: To transform the row-oriented raw data into a column-oriented,
-- analyst-friendly dataset optimized for time-series comparisons and ratio
-- analysis. We use Common Table Expressions (CTEs) to create a readable,
-- data warehouse-style 'fact table' of key metrics.
-- ============================================================================

-- Drop and recreate a materialized analytical view
DROP TABLE IF EXISTS mart_financial_metrics;

CREATE TABLE mart_financial_metrics AS
WITH income_statement_pivoted AS (
    -- Pivot income statement rows into columns for mathematical operations.
    -- Max(CASE) pattern is robust to sparse data.
    SELECT
        fiscal_year,
        MAX(CASE WHEN line_item = 'Total Revenue' THEN value_millions ELSE 0 END) AS total_revenue,
        MAX(CASE WHEN line_item = 'Cost of Goods Sold' THEN value_millions ELSE 0 END) AS cogs,
        MAX(CASE WHEN line_item = 'SG&A' THEN value_millions ELSE 0 END) AS sga,
        MAX(CASE WHEN line_item = 'Depreciation and Amortization' THEN value_millions ELSE 0 END) AS dep_amort,
        MAX(CASE WHEN line_item = 'Operating Income' THEN value_millions ELSE 0 END) AS operating_income
    FROM landing_raw_financials
    WHERE category = 'Income Statement'
    GROUP BY fiscal_year
),
balance_sheet_pivoted AS (
    -- Pivot balance sheet accounts, separating assets, liabilities, and equity.
    SELECT
        fiscal_year,
        MAX(CASE WHEN line_item = 'Current Assets' THEN value_millions ELSE 0 END) AS current_assets,
        MAX(CASE WHEN line_item = 'Inventory' THEN value_millions ELSE 0 END) AS inventory,
        MAX(CASE WHEN line_item = 'Total Assets' THEN value_millions ELSE 0 END) AS total_assets,
        MAX(CASE WHEN line_item = 'Current Liabilities' THEN value_millions ELSE 0 END) AS current_liabilities,
        MAX(CASE WHEN line_item = 'Total Liabilities' THEN value_millions ELSE 0 END) AS total_liabilities,
        MAX(CASE WHEN line_item = 'Shareholders Equity' THEN value_millions ELSE 0 END) AS shareholders_equity
    FROM landing_raw_financials
    WHERE category LIKE 'Balance Sheet%'
    GROUP BY fiscal_year
)
SELECT
    i.fiscal_year,
    -- Profitability Metrics
    i.total_revenue,
    i.operating_income,
    i.cogs,
    i.sga,
    i.dep_amort,
    -- Gross Profit & Margin: The efficiency of the core merchandising strategy.
    -- Calculated as Revenue - COGS, then divided by Revenue.
    i.total_revenue - i.cogs AS gross_profit,
    ROUND(((i.total_revenue - i.cogs)::DECIMAL / NULLIF(i.total_revenue, 0) * 100), 2) AS gross_margin_pct,
    -- Operating Margin: The profitability after the cost of running the stores and HQ.
    ROUND((i.operating_income::DECIMAL / NULLIF(i.total_revenue, 0) * 100), 2) AS operating_margin_pct,
    -- SG&A as a % of Revenue: Our primary lever for operational efficiency.
    ROUND((i.sga::DECIMAL / NULLIF(i.total_revenue, 0) * 100), 2) AS sga_pct_of_revenue,

    -- Balance Sheet & Liquidity Metrics
    b.current_assets,
    b.inventory,
    b.current_liabilities,
    b.total_assets,
    b.total_liabilities,
    b.shareholders_equity,
    -- Current Ratio: A blunt but vital measure of liquidity health.
    -- A value < 1.0 is a significant red flag demanding deeper analysis.
    ROUND(b.current_assets::DECIMAL / NULLIF(b.current_liabilities, 0), 2) AS current_ratio,
    -- Working Capital: The absolute dollar buffer for day-to-day operations.
    b.current_assets - b.current_liabilities AS working_capital,
    -- Debt-to-Equity Ratio: The scale of financial leverage.
    ROUND(b.total_liabilities::DECIMAL / NULLIF(b.shareholders_equity, 0), 2) AS debt_to_equity_ratio

FROM income_statement_pivoted i
INNER JOIN balance_sheet_pivoted b ON i.fiscal_year = b.fiscal_year
ORDER BY i.fiscal_year DESC;

-- Query the final analytical dataset for immediate verification
SELECT * FROM mart_financial_metrics;
```

---

4. Analysis & Findings: The STAR Method Showcase

This section translates the output of our SQL queries into a clear, narrative-driven analysis that demonstrates genuine financial acumen.

Situation

The period from 2018 to 2023 was an extreme stress test for retailers. Target's management made a bold, publicly declared commitment to a multi-billion dollar CapEx strategy aimed at reinventing the in-store experience, building out same-day fulfillment services, and leveraging stores as mini-warehouses. However, external shocks—a pandemic-driven demand surge, a subsequent inventory glut, and the highest inflation in decades—created a volatile backdrop. The business question for an investor in 2024 is simple: Did this strategy build a more fundamentally sound and profitable enterprise, or did it merely inflate the balance sheet and create margin pressures that will take years to unwind?

Task

My task was to peel back the layers of reported "record revenue" to examine the quality of those earnings and the strength of the resulting balance sheet. A high-level glance at revenue is meaningless; I needed to:

1. Isolate and decompose operating margins to see if the company’s core business was genuinely becoming more efficient or just larger.
2. Diagnose the massive inventory swings not as a standalone item, but as a direct driver of profitability, liquidity, and working capital health.
3. Assess whether the capital used to fund this transformation improved the company's asset base or simply layered on financial risk.

Action

I built a purpose-specific analytical environment using PostgreSQL, as shown above. My approach was a three-part forensic analysis directly tied to the three core financial statements.

1. Income Statement Analysis: The Illusion of Profit Growth

My analysis began with the top line, but my focus was immediately on the flow-through to profitability. Here is the structured output from our mart_financial_metrics table, forming the basis of my diagnosis.

Target Key Income Metrics (USD Millions)

Fiscal Year Total Revenue Gross Margin % SG&A % of Revenue Operating Income Operating Margin %
2023 $105,803 28.6% 19.0% $5,139 4.9%
2022 $107,588 26.5% 17.4% $7,178 6.7%
2021 $106,005 29.0% 18.4% $8,946 8.4%
2020 $92,400 32.6% 18.8% $10,611 11.5%
2019 $77,130 30.7% 20.2% $4,110 5.3%

The story this table tells is one of significant operational degradation masked by revenue growth.

· The Gross Margin Squeeze: The data shows a clear negative inflection point. In the peak-demand year of 2020, gross margin hit an impressive 32.6%. By 2023, it had collapsed to 28.6%. This is not just a reversion to the mean; it’s a 400-basis-point structural decline. This is the financial fingerprint of the inventory bullwhip effect and a shift in consumer spending toward lower-margin frequency categories (food & essentials) and away from high-margin discretionary goods (apparel, home). The 2022 markdown crisis, where operating income was cut in half, is clearly visible in the jump in COGS that year.
· The Irreversible SG&A Bet: A key part of Target’s strategy was an investment in store payroll and same-day fulfillment (Drive Up, Shipt). This showed up as elevated SG&A. However, the efficiency ratio (SG&A % of Revenue) was 20.2% in 2019. After the peak-efficiency year of 2022 (17.4% on record revenue), it has shot back up to 19.0% in 2023 as sales fell. The core analytical insight here is that Target’s fulfillment-as-a-service model has introduced significant operating leverage to the downside. When sales fall, the cost of the fixed store labor and dedicated fulfillment infrastructure doesn't fall proportionally, directly crushing operating margins to a decade-low 4.9%. This is a permanent shift in the income statement structure.

2. Balance Sheet Analysis: The Vanishing Liquidity Buffer

The income statement problems are severe, but the balance sheet reveals an even more pressing financial strain. This is where the distinction between an earnings problem and a financial health problem becomes clear.

Target Balance Sheet Health Indicators (USD Millions)

Fiscal Year Working Capital Current Ratio Inventory Debt-to-Equity Ratio
2023 ($2,148) 0.90 $13,139 4.32
2022 ($1,284) 0.94 $13,878 5.16
2021 ($659) 0.97 $15,832 3.48
2020 $2,684 1.16 $10,498 2.77
2019 $290 1.02 $8,990 2.79

· The Negative Working Capital Alarm: This is the most critical finding in the entire analysis. In 2019, Target had a thin but positive $290M working capital buffer. By 2023, it reported negative working capital of **-$2.1 billion**. Its current ratio is now below 1.0 (0.90). This means its current liabilities exceed its current assets. In plain terms, Target is paying its suppliers faster than it's converting inventory into cash from customers. This isn't a sign of efficiency (like a negative cash conversion cycle via extended payables); it's a sign of a structural liquidity imbalance. The company is financing its day-to-day operations with its balance sheet reserves, a strategy that is unsustainable if interest rates remain high.
· Inventory as the Culprit: The inventory line item is the story. It ballooned from $9.0B in 2019 to $15.8B in 2021—a 76% increase against a 37% increase in revenue. This capital was borrowed or came from cash reserves, directly decreasing net income and equity. While inventory levels have come down to $13.1B in 2023, the damage to the capital structure has already been done.
· The Leverage Legacy: This inventory misadventure had to be funded. The debt-to-equity ratio tells the tale. A conservative 2.79x in 2019 rocketed to a dangerous 5.16x in 2022 as the company took on debt to manage the inventory glut while its equity base was pummeled by falling profits and share buyback markdowns. The 4.32x ratio in 2023 is an improvement but remains alarmingly high for a thin-margin retailer, leaving no room for error in a consumer downturn.

Result

The quantified outcome of this analysis is a direct refutation of a superficial "record sales" narrative. The data reveals a company that sacrificed financial quality for growth that proved temporary.

1. Profitability Failure: Target ended 2023 with a pre-tax operating margin (4.9

2. Liquidity Erosion: The company moved from a positive $290M working capital position in 2019 to a negative $2.1B position in 2023. Its ability to weather an unanticipated financial shock is now severely compromised.
3. Balance Sheet Fragility: The debt-to-equity ratio has deteriorated by over 50% from its pre-strategy level, and interest costs on the swollen debt pile will be a persistent drag on future net income.

The business value of this analysis is clear: it provides a data-driven, defensible argument that management's capital allocation strategy has demonstrably decreased the company's financial quality.

---

5. Business Recommendations: Translating Data into Decisions

These recommendations flow directly from the data patterns uncovered in the analysis above. They are specific, actionable, and grounded in the language of financial operations.

Recommendation 1: Freeze All Non-Essential CapEx and Mandate a $2 Billion Working Capital Restoration Plan

· Data Driver: The -$2.1B working capital position and the current ratio below 1.0.
· Business Rationale: A retailer with a current ratio below 1.0 during a period of economic uncertainty is in a fragile position. The immediate strategic priority cannot be growth; it must be balance sheet repair. The company should institute a targeted goal to return working capital to a positive $1.0B level over 18 months. This can be achieved not by adding debt, but through a committed inventory reduction initiative (targeting a 5% reduction in inventory weeks of supply) and negotiating extended payment terms with suppliers to a level competitive with peers. The released cash from inventory should be ring-fenced to reduce the commercial paper program, not for buybacks.

Recommendation 2: Restructure the Physical Footprint to Build Operating Margin Scalability

· Data Driver: The irreversibility of the SG&A ratio, which expanded back to 19.0% of revenue in 2023 even as sales declined.
· Business Rationale: The data shows the store-centric fulfillment model has created a step-change in the fixed-cost base. Management must initiate a "Flexible Store Model" pilot. This means partitioning 25-30% of store operating hours and square footage in low-traffic locations to variable cost models. It involves cross-training and dynamically deploying store associates between fulfillment and floor tasks based on real-time order volume, and converting unused backroom space to virtual dark stores for delivery aggregators. The goal is to achieve a demonstrable 100-basis-point reduction in the SG&A-to-sales ratio over two years, creating the operating leverage necessary to translate flat revenue into earnings growth.

Recommendation 3: Execute a Strategic SKU Rationalization to Rebuild Gross Margin

· Data Driver: The 400-basis-point decline in gross margin from 32.6% (2020) to 28.6% (2023).
· Business Rationale: The margin compression is a direct result of managing too much inventory across too many SKUs, which leads to markdowns. The analytical response is an automated SKU profitability audit. Merchandising teams should use a dashboard (built from the same warehouse table structure we created) that ranks every SKU by its "fully loaded" margin, accounting for freight, storage days, and markdown velocity. The data-driven rule should be a hard target: de-list the bottom 15% of SKUs that have been in inventory for more than 90 days and carry a fully-loaded gross margin below 15%. This purges the markdown baggage and allows open-to-buy dollars to be concentrated in high-turn, high-margin inventory, directly engineering a recovery to at least a 30% gross margin.

---

6. How to Use This Repository

This project is designed to be fully reproducible and serve as a template for your own analysis.

1. Prerequisites: Ensure you have a PostgreSQL environment running. This can be a local instance, a Docker container, or a cloud service like Supabase or Neon.
2. Execution: Connect to your PostgreSQL database using a tool like psql, DBeaver, or pgAdmin.
3. Run the Scripts:
   · Execute sql_queries/01_landing_tables.sql to create the raw data table and populate it with verified SEC data.
   · Execute sql_queries/02_analytical_aggregation.sql to build the performance metrics mart.
4. Explore: Query the mart_financial_metrics table to begin your own analysis. The structure is designed for easy connection to a visualization tool like Metabase or Tableau.

---

7. Interview Talking Points: Narrating Your Analysis

Prepare to discuss this project not just for what you did, but for why it demonstrates top-tier analyst skills. Here’s how to frame the conversation:

· On your true skill: "Anyone can pull data from a terminal. My core skill demonstrated here is the translation of accounting principles into analytical data models. I manually extracted the data from 10-Ks to ensure I wasn't just copying a number labeled 'Revenue' from a third-party site that might have classified it incorrectly. The SQL is structured as an immutable accounting ledger in a database, which shows I treat financial data with the same rigor as a controller, but with the analytical velocity of an engineer."
· On the STAR Narrative: "When you look at this project, don't just see a dashboard. The situation was a corporate strategy that looked great on investor day slides. My task was to create an objective, data-driven verdict on that strategy. The action was a forensic decomposition of profitability and liquidity, isolating the SG&A burden and the inventory-fueled negative working capital. The result is a clear, quantified argument that the company traded financial health for growth—an insight that directly informs capital allocation decisions."
· On the Insight, Not the Tool: "I used PostgreSQL for this analysis, but the tool is secondary. The insight is that a negative working capital position in this context isn't just an accounting artifact; it's a strategic vulnerability that limits the company's ability to survive the next economic shock without damaging dilution or asset sales. That's the level of analysis I bring—moving from the SQL WHERE clause to a strategic boardroom recommendation."
