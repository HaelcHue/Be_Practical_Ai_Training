# Be_Practical_AI_Career_Training
### DAY 3 
##### Executive Summary (Top 3 Findings)
* Tenure Threshold Risk: Customer churn is most aggressive in the early lifecycle. Retained customers have a median tenure of 18 months, while churned customers leave at a median of 10 months.
* Support Ticket Predictability: High support ticket volume is a 100% accurate predictor of churn in extreme cases (>6 tickets). Even a slight increase in 'Ticket Velocity' significantly increases the likelihood of an account closing.
* Compounded Risk Segments: The 'Month-to-Month' contract combined with a lack of 'Tech Support' represents the highest risk segment, exhibiting an 86.14% churn rate compared to the baseline.

##### Methodology & Visualizations
* Univariate Analysis: Explored distributions of Monthly Charges, Tenure (right-skewed), and Support Tickets (Poisson-distributed).
* Bivariate & Multivariate EDA: Utilized boxplots for tenure comparisons, FacetGrids to see how charges and tickets interact across contract types, and correlation heatmaps to identify key drivers.
* Feature Engineering: Created Ticket_Velocity and High_Risk_Flag to quantify behavioral friction and contractual instability.
* Data Integrity: Imputed missing values in Total_Charges using the logical relationship between tenure and monthly spend to maintain statistical accuracy.
##### Recommended Strategic Interventions
* Onboarding Success Program: Deploy high-touch engagement during the first 90 days of an account's lifecycle to bridge the 10-to-18-month tenure gap.
* Predictive Support Triggers: Set automated alerts for the Customer Success team when an account exceeds 4 support tickets in a single month or shows high 'Ticket Velocity'.
* Contract Conversion Incentives: Targeted promotions to move 'Month-to-Month' users without Tech Support into 'One-Year' plans with bundled technical assistance.
