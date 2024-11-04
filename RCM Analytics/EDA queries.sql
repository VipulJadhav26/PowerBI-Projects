-- Creating table to store the data

CREATE TABLE IF NOT EXISTS claims_transformed (
    Claim_ID VARCHAR(20),
    Provider_ID BIGINT,
    Patient_ID BIGINT,
    Date_of_Service DATE,
    Billed_Amount DECIMAL(10, 2),
    Procedure_Code VARCHAR(10),
    Diagnosis_Code VARCHAR(10),
    Allowed_Amount DECIMAL(10, 2),
    Paid_Amount DECIMAL(10, 2),
    Insurance_Type VARCHAR(20),
    Claim_Status VARCHAR(20),
    Reason_Code VARCHAR(100),
    Follow_up_Required VARCHAR(3),
    AR_Status VARCHAR(20),
    Outcome VARCHAR(20)
);

-- Inserting data into table using "Import Flat File Option"
---------------------------------------------------------------

--checking all the records

SELECT * FROM
claims_transformed;

-- Checking for any columns having Null values

SELECT 
	column_name
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'claims_transformed'
AND column_name IS NULL;

-- There are no columns having NULL value

--Checking total number of records

SELECT
	COUNT(*) as total_count
FROM claims_transformed

-- There are total 1000 columns

-- Number of records per claim status

SELECT
	Claim_status,
	COUNT(*) as claim_status_count
FROM claims_transformed
GROUP BY Claim_Status;

-- Number of records per Insuarance Type

SELECT
	Insurance_Type,
	COUNT(*) as claim_status_count
FROM claims_transformed
GROUP BY Insurance_Type;

-- Number of records per AR Status

SELECT
	AR_Status,
	COUNT(*) as claim_status_count
FROM claims_transformed
GROUP BY AR_Status;


-- Exploring Billed amount, Allowed Amount, Paid amount per Insuarance Type

SELECT 
	Insurance_Type,
	COUNT(1) as record_count,
	SUM(Billed_Amount) as total_Billed_Amount,
	AVG(Billed_Amount) as avg_Billed_Amount,
	SUM(Allowed_Amount) as total_Allowed_Amount,
	AVG(Allowed_Amount) as avg_Allowed_Amount,
	SUM(Paid_Amount) as total_Paid_Amount,
	AVG(Paid_Amount) as avg_Paid_Amount
FROM claims_transformed
GROUP BY Insurance_Type;

-- Exploring Billed amount, Allowed Amount, Paid amount per claim status

SELECT 
	Claim_Status,
	COUNT(1) as record_count,
	SUM(Billed_Amount) as total_Billed_Amount,
	AVG(Billed_Amount) as avg_Billed_Amount,
	SUM(Allowed_Amount) as total_Allowed_Amount,
	AVG(Allowed_Amount) as avg_Allowed_Amount,
	SUM(Paid_Amount) as total_Paid_Amount,
	AVG(Paid_Amount) as avg_Paid_Amount
FROM claims_transformed
GROUP BY Claim_Status;

-- Exploring Billed amount, Allowed Amount, Paid amount per AR status

SELECT 
	AR_Status,
	count(1) as record_count,
	SUM(Billed_Amount) as total_Billed_Amount,
	AVG(Billed_Amount) as avg_Billed_Amount,
	SUM(Allowed_Amount) as total_Allowed_Amount,
	AVG(Allowed_Amount) as avg_Allowed_Amount,
	SUM(Paid_Amount) as total_Paid_Amount,
	AVG(Paid_Amount) as avg_Paid_Amount
FROM claims_transformed
GROUP BY AR_Status;

-- 

Select * from claims_transformed;

-- Calculating Days in AR

SELECT 
    Claim_ID,
    Provider_ID,
    Patient_ID,
    Date_of_Service,
    Billed_Amount,
    Paid_Amount,
    DATEDIFF(day, Date_of_Service, GETDATE()) AS Days_in_AR
FROM 
    claims_transformed;

-- Creating AR Aging buckets

SELECT 
    Claim_ID,
    Provider_ID,
    Patient_ID,
    Date_of_Service,
    Billed_Amount,
    Paid_Amount,
    DATEDIFF(day, Date_of_Service, GETDATE()) AS Days_in_AR,
    CASE 
        WHEN DATEDIFF(day, Date_of_Service, GETDATE()) <= 30 THEN '0-30 Days'
        WHEN DATEDIFF(day, Date_of_Service, GETDATE()) BETWEEN 31 AND 60 THEN '31-60 Days'
        WHEN DATEDIFF(day, Date_of_Service, GETDATE()) BETWEEN 61 AND 90 THEN '61-90 Days'
        WHEN DATEDIFF(day, Date_of_Service, GETDATE()) BETWEEN 91 AND 120 THEN '91-120 Days'
        WHEN DATEDIFF(day, Date_of_Service, GETDATE()) > 120 THEN '120+ Days'
        ELSE 'Unknown'
    END AS AR_Aging_Bucket
FROM 
    claims_transformed;


-- Aggreagating AR amount by Aging Buckets

SELECT 
    AR_Aging_Bucket,
    SUM(Billed_Amount - Paid_Amount) AS Total_AR_Amount,
    COUNT(Claim_ID) AS Total_Claims
FROM 
    ( 
        SELECT 
            Claim_ID,
            Billed_Amount,
            Paid_Amount,
            CASE 
                WHEN DATEDIFF(day, Date_of_Service, GETDATE()) <= 30 THEN '0-30 Days'
                WHEN DATEDIFF(day, Date_of_Service, GETDATE()) BETWEEN 31 AND 60 THEN '31-60 Days'
                WHEN DATEDIFF(day, Date_of_Service, GETDATE()) BETWEEN 61 AND 90 THEN '61-90 Days'
                WHEN DATEDIFF(day, Date_of_Service, GETDATE()) BETWEEN 91 AND 120 THEN '91-120 Days'
                WHEN DATEDIFF(day, Date_of_Service, GETDATE()) > 120 THEN '120+ Days'
                ELSE 'Unknown'
            END AS AR_Aging_Bucket
        FROM 
            claims_transformed
    ) AS Bucketed_Claims
GROUP BY 
    AR_Aging_Bucket
ORDER BY 
	AR_Aging_Bucket;


-- Top reason for claim denial

SELECT Reason_Code, 
       COUNT(*) AS Denial_Count
FROM claims_transformed
WHERE Claim_Status = 'Denied'
GROUP BY Reason_Code
ORDER BY Denial_Count DESC;
--- Seems Like Incorrect Billing Information has maximum number of claim denial incidents.

-- Finding claims by insuarance type

SELECT Insurance_Type,
       COUNT(*) AS Total_Claims,
       SUM(Paid_Amount) AS Total_Paid_Amount,
       SUM(Billed_Amount - Paid_Amount) AS Total_AR
FROM claims_transformed
GROUP BY Insurance_Type
ORDER BY Total_Claims DESC;

-- Calculating Average Days in AR by Insurance Type

SELECT Insurance_Type,
       AVG(DATEDIFF(DAY, Date_of_Service, GETDATE())) AS Avg_Days_in_AR
FROM claims_transformed
WHERE Claim_Status = 'Pending' OR Claim_Status = 'Open'
GROUP BY Insurance_Type
ORDER BY Avg_Days_in_AR DESC;

-- Monthly trend in Billed Vs Paid Amount

SELECT 
    FORMAT(Date_of_Service, 'yyyy-MM') AS Month,
    SUM(Billed_Amount) AS Total_Billed,
    SUM(Paid_Amount) AS Total_Paid, 
	SUM(Billed_Amount) - SUM(Paid_Amount) as Due_Amount
FROM claims_transformed
GROUP BY FORMAT(Date_of_Service, 'yyyy-MM')
ORDER BY Month;


-- Claims follow up status

SELECT Follow_up_Required,
       COUNT(*) AS Claims_Count,
       SUM(Billed_Amount - Paid_Amount) AS Total_AR
FROM claims_transformed
GROUP BY Follow_up_Required;

-- Average payment amount by procedure code

SELECT Procedure_Code,
       AVG(Paid_Amount) AS Avg_Paid_Amount,
       COUNT(*) AS Total_Claims
FROM claims_transformed
GROUP BY Procedure_Code
ORDER BY Avg_Paid_Amount DESC;

-- Top 10 Claims with High Difference Between Billed and Paid Amounts

SELECT  TOP 10
		Claim_ID, 
		Provider_ID, 
		Patient_ID, 
		Billed_Amount, 
		Paid_Amount,
       (Billed_Amount - Paid_Amount) AS Difference
FROM claims_transformed
WHERE (Billed_Amount - Paid_Amount) > (Billed_Amount * 0.2) -- Threshold for significant difference
ORDER BY Difference DESC;

-- Average and Total Charges by Diagnosis Code

SELECT TOP 10
	   Diagnosis_Code,
       COUNT(*) AS Claim_Count,
       AVG(Billed_Amount) AS Avg_Billed_Amount,
       SUM(Billed_Amount) AS Total_Billed_Amount
FROM claims_transformed
GROUP BY Diagnosis_Code
ORDER BY Total_Billed_Amount DESC;


