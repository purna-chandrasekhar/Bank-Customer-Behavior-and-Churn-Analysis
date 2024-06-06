-- Objective questions
-- 1. What is the distribution of account balances across different regions?
SELECT
	g.GeographyLocation AS region,
    COUNT(*) AS total_customers,
    AVG(bc.Balance) AS avearage_balance,
    MAX(bc.Balance) AS maximum_balance,
    MIN(bc.Balance) AS minimun_balance,
    STDDEV(bc.Balance) AS balance_standard_deviation
FROM bank_churn bc
JOIN customerinfo ci ON bc.customerId = ci.customerId
JOIN geography g ON ci.GeographyID = g.GeographyID
GROUP BY region;

-- 2. Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year. (SQL)
SELECT
	CustomerId,
    EstimatedSalary
FROM customerinfo
WHERE DATE_FORMAT(`Bank DOJ`, "%Y-%m") BETWEEN '2019-10' AND '2019-12'
ORDER BY EstimatedSalary DESC
LIMIT 5;

-- 3. Calculate the average number of products used by customers who have a credit card. (SQL)
SELECT AVG(NumOfProducts) AS AvgNumOfProductsWithCreditCard
FROM bank_churn
WHERE HasCrCard = 1;

-- 4. Determine the churn rate by gender for the most recent year in the dataset.
WITH ChurnCount AS (
	SELECT
		ci.GenderID, 
        SUM(CASE WHEN Exited = 1 THEN 1 ELSE 0 END) AS churned_Customers,
        COUNT(*) AS total_customers
	FROM customerinfo ci
	JOIN bank_churn bc ON ci.CustomerId = bc.CustomerId
	WHERE YEAR(ci.`Bank DOJ`) = (SELECT MAX(YEAR(`Bank DOJ`)) FROM customerinfo)
	GROUP BY ci.GenderID
)

SELECT
	g.GenderCategory AS gender,
    c.churned_Customers, c.total_customers,
    ROUND((c.churned_Customers * 100.0 / c.total_customers), 2) AS churn_rate_percentage
FROM ChurnCount c
JOIN gender g ON c.GenderID = g.GenderID;

-- 5. Compare the average credit score of customers who have exited and those who remain. (SQL)
SELECT
    CASE
        WHEN Exited = 1 THEN 'Exited'
        ELSE 'Remain'
    END AS CustomerStatus,
    AVG(CreditScore) AS average_credit_score
FROM bank_churn
GROUP BY CustomerStatus;

-- 6. Which gender has a higher average estimated salary, and how does it relate to the number of active accounts? (SQL)
SELECT
	g.GenderCategory AS gender,
    AVG(ci.EstimatedSalary) AS avg_estimated_salary,
    SUM(bc.IsActiveMember) AS num_active_accounts
FROM customerinfo ci
JOIN gender g ON ci.GenderID = g.GenderID
JOIN bank_churn bc ON ci.CustomerId = bc .CustomerId
GROUP BY gender
ORDER BY avg_estimated_salary DESC;

-- 7. Segment the customers based on their credit score and identify the segment with the highest exit rate. (SQL)
WITH CreditScoreSegments AS (
	SELECT
		CASE 
			WHEN CreditScore BETWEEN 800 AND 850 THEN 'Very Poor'
			WHEN CreditScore BETWEEN 740 AND 799 THEN 'Poor'
			WHEN CreditScore BETWEEN 670 AND 739 THEN 'Fair'
			WHEN CreditScore BETWEEN 580 AND 669 THEN 'Great'
			WHEN CreditScore BETWEEN 300 AND 579 THEN 'Excellent'
		END AS CreditScoreSegment,
		Exited
	FROM bank_churn
)

SELECT
	CreditScoreSegment,
    COUNT(*) AS TotalCustomers,
    SUM(Exited) AS ExitedCustomers,
    SUM(Exited) * 1.0 / COUNT(*) AS ExitRate
FROM CreditScoreSegments
GROUP BY CreditScoreSegment
ORDER BY ExitRate
LIMIT 1;

-- 8. Find out which geographic region has the highest number of active customers with a tenure greater than 5 years. (SQL)
SELECT
	g.GeographyLocation,
	COUNT(*) AS active_customers
FROM bank_churn bc
JOIN customerinfo ci ON bc.CustomerId = ci.CustomerId
JOIN geography g ON ci.GeographyID = g.GeographyID
WHERE bc.IsActiveMember = 1 AND bc.Tenure > 5
GROUP BY GeographyLocation
ORDER BY active_customers DESC
LIMIT 1;

-- 9. What is the impact of having a credit card on customer churn, based on the available data?
SELECT
    HasCrCard,
    SUM(Exited) * 100 / COUNT(CustomerId) AS churn_rate
FROM bank_churn
GROUP BY HasCrCard;
    
-- 10. For customers who have exited, what is the most common number of products they have used?
SELECT
	NumOfProducts AS most_common_num_of_products_used,
    COUNT(*) AS num_of_customers
FROM bank_churn
WHERE Exited = 1
GROUP BY NumOfProducts
ORDER BY num_of_customers DESC
LIMIT 1;

-- 11. Examine the trend of customers joining over time and identify any seasonal patterns (yearly or monthly). Prepare the data through SQL and then visualize it.
SELECT
	YEAR(`Bank DOJ`) AS join_year,
    MONTH(`Bank DOJ`) AS join_month,
	COUNT(*) AS num_of_customers
FROM customerinfo
GROUP BY
	join_year,
    join_month
ORDER BY
	join_year,
    join_month;

-- 12. Analyze the relationship between the number of products and the account balance for customers who have exited.
SELECT
	NumOfProducts,
    AVG(Balance) AS average_balance
FROM bank_churn
WHERE Exited = 1
GROUP BY NumOfProducts;

-- 13. Identify any potential outliers in terms of balance among customers who have remained with the bank.
SELECT 
	CustomerId, 
    Balance
FROM bank_churn
WHERE
	IsActiveMember = 1 AND Exited = 1
ORDER BY Balance DESC;

-- 15. Using SQL, write a query to find out the gender-wise average income of males and females in each geography id. Also, rank the gender according to the average value. (SQL)
SELECT
	RANK() OVER(PARTITION BY geo.GeographyLocation ORDER BY AVG(EstimatedSalary) DESC) AS avg_income_rank,
    gen.GenderCategory,
	geo.GeographyLocation,
    AVG(EstimatedSalary) AS avg_income
FROM customerinfo ci
JOIN gender gen ON ci.GenderID = gen.GenderID
JOIN geography geo ON ci.GeographyID = geo.GeographyID
GROUP BY
	gen.GenderCategory, 
    geo.GeographyLocation;

-- 16. Using SQL, write a query to find out the average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+).
SELECT 
	CASE
		WHEN Age BETWEEN 18 AND 30 THEN '18-30'
        WHEN Age BETWEEN 31 AND 50 THEN '31-50'
        ELSE '50+'
    END AS AgeBracket,
    AVG(Tenure) AS avg_tenure
FROM customerinfo ci
JOIN bank_churn bc ON ci.CustomerId = bc.CustomerId
WHERE Exited = 1
GROUP BY AgeBracket
ORDER BY AgeBracket;
    
-- 17. Is there any direct correlation between salary and the balance of the customers? And is it different for people who have exited or not?
-- Correlation between salary and balance for all customers
SELECT 
    (COUNT(*) * SUM(bc.Balance * ci.EstimatedSalary) - SUM(bc.Balance) * SUM(ci.EstimatedSalary)) /
    (SQRT((COUNT(*) * SUM(bc.Balance * bc.Balance) - SUM(bc.Balance) * SUM(bc.Balance)) *
          (COUNT(*) * SUM(ci.EstimatedSalary * ci.EstimatedSalary) - SUM(ci.EstimatedSalary) * SUM(ci.EstimatedSalary))))
    AS correlation_all
FROM bank_churn bc
JOIN customerinfo ci ON bc.CustomerId = ci.CustomerId;

-- Correlation between salary and balance for customers who have not exited
SELECT 
    (COUNT(*) * SUM(bc.Balance * ci.EstimatedSalary) - SUM(bc.Balance) * SUM(ci.EstimatedSalary)) /
    (SQRT((COUNT(*) * SUM(bc.Balance * bc.Balance) - SUM(bc.Balance) * SUM(bc.Balance)) *
          (COUNT(*) * SUM(ci.EstimatedSalary * ci.EstimatedSalary) - SUM(ci.EstimatedSalary) * SUM(ci.EstimatedSalary))))
    AS correlation_not_exited
FROM bank_churn bc
JOIN customerinfo ci ON bc.CustomerId = ci.CustomerId
WHERE bc.Exited = 0;

-- Correlation between salary and balance for customers who have exited
SELECT 
    (COUNT(*) * SUM(bc.Balance * ci.EstimatedSalary) - SUM(bc.Balance) * SUM(ci.EstimatedSalary)) /
    (SQRT((COUNT(*) * SUM(bc.Balance * bc.Balance) - SUM(bc.Balance) * SUM(bc.Balance)) *
          (COUNT(*) * SUM(ci.EstimatedSalary * ci.EstimatedSalary) - SUM(ci.EstimatedSalary) * SUM(ci.EstimatedSalary))))
    AS correlation_exited
FROM bank_churn bc
JOIN customerinfo ci ON bc.CustomerId = ci.CustomerId
WHERE bc.Exited = 1;

-- 18. Is there any correlation between the salary and the Credit score of customers?
SELECT 
    (COUNT(*) * SUM(bc.CreditScore * ci.EstimatedSalary) - SUM(bc.CreditScore) * SUM(ci.EstimatedSalary)) /
    (SQRT((COUNT(*) * SUM(bc.CreditScore * bc.CreditScore) - SUM(bc.CreditScore) * SUM(bc.CreditScore)) *
          (COUNT(*) * SUM(ci.EstimatedSalary * ci.EstimatedSalary) - SUM(ci.EstimatedSalary) * SUM(ci.EstimatedSalary))))
    AS correlation_creditScore_salary
FROM bank_churn bc
JOIN customerinfo ci ON bc.CustomerId = ci.CustomerId;

-- 19. Rank each bucket of credit score as per the number of customers who have churned the bank.
SELECT
	RANK() OVER(ORDER BY COUNT(*) DESC) crd_scr_rank,
	CASE 
		WHEN CreditScore BETWEEN 800 AND 850 THEN '800-850'
        WHEN CreditScore BETWEEN 740 AND 799 THEN '740-799'
        WHEN CreditScore BETWEEN 670 AND 739 THEN '670-739'
        WHEN CreditScore BETWEEN 580 AND 669 THEN '580-669'
        WHEN CreditScore BETWEEN 300 AND 579 THEN '350-579'
	END AS CreditScoreBucket,
    COUNT(*) AS num_of_churned_customers
FROM bank_churn bc
JOIN customerinfo ci ON bc.CustomerId = ci.CustomerId
WHERE Exited = 1
GROUP BY CreditScoreBucket;

-- 20. According to the age buckets find the number of customers who have a credit card. Also retrieve those buckets that have lesser than average number of credit cards per bucket.
SELECT 
	CASE
		WHEN Age BETWEEN 18 AND 30 THEN '18-30'
		WHEN Age BETWEEN 31 AND 50 THEN '31-50'
		ELSE '50+'
	END AS AgeBucket,
	COUNT(*) AS num_of_customers_with_crcd
FROM customerinfo ci
JOIN bank_churn bc ON ci.CustomerId = bc.CustomerId
WHERE HasCrCard = 1
GROUP BY AgeBucket
ORDER BY num_of_customers_with_crcd DESC;

WITH AgeBuckets AS (
	SELECT 
		CASE
			WHEN Age BETWEEN 18 AND 30 THEN '18-30'
			WHEN Age BETWEEN 31 AND 50 THEN '31-50'
			ELSE '50+'
		END AS AgeBucket,
		COUNT(*) AS num_of_customers,
		SUM(HasCrCard) AS customers_with_crcd
	FROM customerinfo ci
	JOIN bank_churn bc ON ci.CustomerId = bc.CustomerId
	GROUP BY AgeBucket
),
AvgCreditCards AS (
	SELECT AVG(customers_with_crcd) AS avg_crcds
	FROM AgeBuckets
)

SELECT
	AgeBucket,
    num_of_customers,
    customers_with_crcd
FROM AgeBuckets
CROSS JOIN AvgCreditCards
WHERE customers_with_crcd < avg_crcds;

-- 21. Rank the Locations as per the number of people who have churned the bank and average balance of the customers.
SELECT
	RANK() OVER(ORDER BY SUM(Exited) DESC, AVG(bc.Balance) DESC) AS location_rank,
	g.GeographyLocation, 
	SUM(Exited) AS num_of_customers,
    ROUND(AVG(bc.Balance), 2) AS avg_balance
FROM customerinfo ci
JOIN bank_churn bc ON ci.CustomerId = bc.CustomerId
JOIN geography g ON ci.GeographyID = g.GeographyID
GROUP BY g.GeographyLocation;

-- 22. As we can see that the “CustomerInfo” table has the CustomerID and Surname, now if we have to join it with a table where the primary key is also a combination of CustomerID and Surname, come up with a column where the format is “CustomerID_Surname”.
ALTER TABLE customerinfo
ADD COLUMN CustomerID_Surname VARCHAR(255);

UPDATE customerinfo
SET CustomerId_Surname = CONCAT(CustomerId, '_', Surname);

SELECT CustomerId_Surname
FROM customerinfo;

-- 23. Without using “Join”, can we get the “ExitCategory” from ExitCustomers table to Bank_Churn table? If yes do this using SQL.
SELECT
	CustomerId,
	Exited,
    (SELECT ExitCategory
	FROM exitcustomer 
	WHERE ExitID = bc.Exited
	) AS ExitCategory
FROM bank_churn bc;

-- 25. Write the query to get the customer IDs, their last name, and whether they are active or not for the customers whose surname ends with “on”.
SELECT
	ci.CustomerId,
    ci.Surname,
    CASE
		WHEN bc.IsActiveMember = 1 THEN 'Yes'
        ELSE 'No'
	END AS IsActiveMember
FROM customerinfo ci
JOIN bank_churn bc ON ci.CustomerId = bc.CustomerId
WHERE Surname LIKE '%on';

-- Subjective questions
-- 1. Customer Behavior Analysis: What patterns can be observed in the spending habits of long-term customers compared to new customers, and what might these patterns suggest about customer loyalty?
-- Churn Rate by Tenure Category
SELECT
	CASE
		WHEN Tenure <= 5 THEN 'New Customer'
		ELSE 'Long Term Customer'
	END AS TenureCategory,
    ROUND(AVG(Exited) *100, 2) AS churn_rate
FROM bank_churn
GROUP BY TenureCategory
ORDER BY churn_rate DESC;

-- Exit Count by Tenure Category
SELECT
	CASE
		WHEN Tenure <= 5 THEN 'New Customer'
		ELSE 'Long Term Customer'
	END AS TenureCategory,
    Exited,
    COUNT(*) AS num_of_customers
FROM bank_churn
GROUP BY
	TenureCategory,
    Exited
ORDER BY TenureCategory;

-- Active Membership by Tenure Category
SELECT
	CASE
		WHEN Tenure <= 5 THEN 'New Customer'
		ELSE 'Long Term Customer'
	END AS TenureCategory,
	IsActiveMember,
    COUNT(*) AS num_of_customers
FROM bank_churn
GROUP BY
	TenureCategory,
    IsActiveMember
ORDER BY
	TenureCategory,
    IsActiveMember;
    
-- Credit Card Usage by Tenure Category
SELECT
	CASE
		WHEN Tenure <= 5 THEN 'New Customer'
		ELSE 'Long Term Customer'
	END AS TenureCategory,
    HasCrCard,
    COUNT(*) AS num_of_customers
FROM bank_churn
GROUP BY
	TenureCategory,
    HasCrCard
ORDER BY
	TenureCategory,
	HasCrCard;

-- Product Ownership by Tenure Category
SELECT
	CASE
		WHEN Tenure <= 5 THEN 'New Customer'
		ELSE 'Long Term Customer'
	END AS TenureCategory,
    NumOfProducts,
    COUNT(*) AS num_of_customers
FROM bank_churn 
GROUP BY
	TenureCategory,
    NumOfProducts
ORDER BY TenureCategory DESC;
    
-- Average Balance by Tenure Category
SELECT
	CASE
		WHEN Tenure <= 5 THEN 'New Customer'
		ELSE 'Long Term Customer'
	END AS TenureCategory,
    ROUND(AVG(Balance), 2) AS avg_balance
FROM bank_churn
GROUP BY TenureCategory
ORDER BY avg_balance DESC;

-- 2. Product Affinity Study: Which bank products or services are most commonly used together, and how might this influence cross-selling strategies?
SELECT
    NumOfProducts,
    COUNT(*) AS num_customers
FROM bank_churn
WHERE
	IsActiveMember = 1 AND HasCrCard = 1
GROUP BY
    NumOfProducts;

-- 3. Geographic Market Trends: How do economic indicators in different geographic regions correlate with the number of active accounts and customer churn rates?
-- Average Balance by GeographyLocation and Exit Category for Active Customers
SELECT
	g.GeographyLocation,
    bc.Exited,
    AVG(bc.Balance) AS avg_balance
FROM bank_churn bc
JOIN customerinfo ci ON bc.CustomerId = ci.CustomerId
JOIN geography g ON ci.GeographyID = g.GeographyID
WHERE bc.IsActiveMember = 1
GROUP BY
	g.GeographyLocation,
    bc.Exited
ORDER BY 
	bc.Exited,
    g.GeographyLocation;

-- Active EXited Customers by GeographyLocation and Credir Score Category
SELECT
	g.GeographyLocation,
    CASE 
		WHEN bc.CreditScore BETWEEN 800 AND 850 THEN '800 - 850'
        WHEN bc.CreditScore BETWEEN 740 AND 799 THEN '740 - 799'
        WHEN bc.CreditScore BETWEEN 670 AND 739 THEN '670 - 739'
        WHEN bc.CreditScore BETWEEN 580 AND 669 THEN '580 - 699'
        WHEN bc.CreditScore BETWEEN 300 AND 579 THEN '300 - 579'
	END AS CreditScoreCategory,
    SUM(Exited) AS churned_customers
FROM bank_churn bc
JOIN customerinfo ci ON bc.CustomerId = ci.CustomerId
JOIN geography g ON ci.GeographyID = g.GeographyID
WHERE bc.IsActiveMember = 1
GROUP BY
	g.GeographyLocation,
    CreditScoreCategory
ORDER BY
	g.GeographyLocation DESC,
    CreditScoreCategory;
    
-- Active EXited Customers having Credit Cards by GeographyLocation 
SELECT
	g.GeographyLocation,
    SUM(HasCrCard) AS credit_card_users,
    SUM(Exited) AS churned_customers
FROM bank_churn bc
JOIN customerinfo ci ON bc.CustomerId = ci.CustomerId
JOIN geography g ON ci.GeographyID = g.GeographyID
WHERE bc.IsActiveMember = 1
GROUP BY g.GeographyLocation
ORDER BY
	g.GeographyLocation DESC
;

-- Active EXited Customers by GeographyLocation and Number of Customers
SELECT
	g.GeographyLocation,
    bc.NumOfProducts,
    COUNT(*) AS number_of_customers,
    SUM(Exited) AS churned_customers
FROM bank_churn bc
JOIN customerinfo ci ON bc.CustomerId = ci.CustomerId
JOIN geography g ON ci.GeographyID = g.GeographyID
WHERE bc.IsActiveMember = 1
GROUP BY 
	g.GeographyLocation,
    bc.NumOfProducts
ORDER BY
	g.GeographyLocation DESC
;

-- Average Estimated Salary by GeographyLocation and Exit Category for Active Customers
SELECT
	g.GeographyLocation,
    bc.Exited,
    AVG(ci.EstimatedSalary) AS avg_estimated_salary
FROM bank_churn bc
JOIN customerinfo ci ON bc.CustomerId = ci.CustomerId
JOIN geography g ON ci.GeographyID = g.GeographyID
WHERE bc.IsActiveMember = 1
GROUP BY
	g.GeographyLocation,
    bc.Exited
ORDER BY 
	bc.Exited,
    g.GeographyLocation;

-- 4. Risk Management Assessment: Based on customer profiles, which demographic segments appear to pose the highest financial risk to the bank, and why?
-- Customers by Credit Score Category and Age Segment
SELECT
    CASE 
		WHEN bc.CreditScore BETWEEN 800 AND 850 THEN '800 - 850'
        WHEN bc.CreditScore BETWEEN 740 AND 799 THEN '740 - 799'
        WHEN bc.CreditScore BETWEEN 670 AND 739 THEN '670 - 739'
        WHEN bc.CreditScore BETWEEN 580 AND 669 THEN '580 - 699'
        WHEN bc.CreditScore BETWEEN 300 AND 579 THEN '300 - 579'
	END AS CreditScoreCategory,
    CASE
			WHEN Age BETWEEN 18 AND 30 THEN '18-30'
			WHEN Age BETWEEN 31 AND 50 THEN '31-50'
			ELSE '50+'
		END AS AgeSegment,
    COUNT(*) AS number_of_customers
FROM bank_churn bc
JOIN customerinfo ci ON bc.CustomerId = ci.CustomerId
GROUP BY
	AgeSegment,
    CreditScoreCategory
ORDER BY 
	AgeSegment,
    CreditScoreCategory;
    
-- Customers by Tenure Category and Age Segment
SELECT
    CASE
		WHEN Tenure <= 5 THEN 'New Customer'
		ELSE 'Long Term Customer'
	END AS TenureCategory,
    CASE
			WHEN Age BETWEEN 18 AND 30 THEN '18-30'
			WHEN Age BETWEEN 31 AND 50 THEN '31-50'
			ELSE '50+'
		END AS AgeSegment,
    COUNT(*) AS number_of_customers
FROM bank_churn bc
JOIN customerinfo ci ON bc.CustomerId = ci.CustomerId
GROUP BY
	AgeSegment,
    TenureCategory
ORDER BY 
	AgeSegment,
    TenureCategory;

-- Average of Balance and Customers with Balance less than Average Balance
SELECT
	(SELECT ROUND(AVG(Balance), 2) AS average_balance FROM bank_churn) AS average_balance,
	COUNT(*) AS customers_with_balance_less_than_average_balance
FROM bank_churn
WHERE Balance < (SELECT ROUND(AVG(Balance), 2) AS average_balance FROM bank_churn);

-- Average of Estimated Salary and Customers with Estimated Salary less than Average Estimated Salary
SELECT
	(SELECT ROUND(AVG(EstimatedSalary), 2) AS average_estimated_salary FROM customerinfo) AS average_estimated_salary,
	COUNT(*) AS customers_with_estimated_salary_less_than_average_estimated_salary
FROM customerinfo
WHERE EstimatedSalary < (SELECT ROUND(AVG(EstimatedSalary), 2) AS average_estimated_salary FROM customerinfo);

-- 9. Utilize SQL queries to segment customers based on demographics and account details.
-- Segmentation by Gender and Geography:
SELECT 
    c.CustomerId,
    c.Age,
    CASE 
        WHEN c.GenderID = 1 THEN 'Male'
        WHEN c.GenderID = 2 THEN 'Female'
        ELSE 'Other'
    END AS Gender,
    CASE 
        WHEN c.GeographyID = 1 THEN 'France'
        WHEN c.GeographyID = 2 THEN 'Spain'
        WHEN c.GeographyID = 3 THEN 'Germany'
        ELSE 'Unknown'
    END AS Geography,
    c.EstimatedSalary,
    c.`Bank DOJ`,
    bc.CreditScore,
    bc.Tenure,
    bc.Balance,
    bc.NumOfProducts,
    bc.HasCrCard,
    bc.IsActiveMember,
    bc.Exited
FROM customerinfo c
JOIN bank_churn bc ON c.CustomerId = bc.CustomerId;

-- Segmentation by Credit Score:
SELECT 
    *,
    CASE 
        WHEN CreditScore >= 800 THEN 'Excellent'
        WHEN CreditScore >= 740 AND CreditScore < 800 THEN 'Very Good'
        WHEN CreditScore >= 670 AND CreditScore < 740 THEN 'Good'
        WHEN CreditScore >= 580 AND CreditScore < 670 THEN 'Fair'
        WHEN CreditScore >= 300 AND CreditScore < 580 THEN 'Poor'
        ELSE 'Unknown'
    END AS CreditScoreCategory
FROM bank_churn;

-- Segmentation by Age Group:
SELECT 
    *,
    CASE 
        WHEN Age < 18 THEN 'Under 18'
        WHEN Age BETWEEN 18 AND 24 THEN '18-24'
        WHEN Age BETWEEN 25 AND 34 THEN '25-34'
        WHEN Age BETWEEN 35 AND 44 THEN '35-44'
        WHEN Age BETWEEN 45 AND 54 THEN '45-54'
        WHEN Age BETWEEN 55 AND 64 THEN '55-64'
        WHEN Age >= 65 THEN '65+'
        ELSE 'Unknown'
    END AS AgeGroup
FROM customerinfo;

-- Segmentation by Tenure Group:
SELECT 
    *,
    CASE 
        WHEN Tenure < 1 THEN '0-1 year'
        WHEN Tenure BETWEEN 1 AND 3 THEN '1-3 years'
        WHEN Tenure BETWEEN 4 AND 6 THEN '4-6 years'
        WHEN Tenure BETWEEN 7 AND 9 THEN '7-9 years'
        ELSE 'Unknown'
    END AS TenureGroup
FROM bank_churn;

-- 11. What is the current churn rate per year and overall as well in the bank? Can you suggest some insights to the bank about which kind of customers are more likely to churn and what different strategies can be used to decrease the churn rate?

WITH CustomerData AS (
    SELECT 
        bc.CustomerId,
        bc.Tenure,
        bc.Exited,
        ci.`Bank DOJ`
    FROM bank_churn bc
    JOIN customerinfo ci ON bc.CustomerId = ci.CustomerId
)

SELECT 
    AVG(Exited) / (MAX(YEAR(`Bank DOJ`)) - MIN(YEAR(`Bank DOJ`)) + 1) AS ChurnRatePerYear,
    AVG(Exited) AS OverallChurnRate
FROM CustomerData;

-- 14. In the “Bank_Churn” table how can you modify the name of the “HasCrCard” column to “Has_creditcard”?
ALTER TABLE bank_churn
RENAME COLUMN HasCrCard TO Has_creditcard;

SELECT Has_creditcard
FROM bank_churn;