-- ---------------------Objective Questions ------------

-- 2.	Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year. (SQL)

SELECT c.CustomerId, c.Surname, c.EstimatedSalary,c.JoiningDate
FROM customerinfo c
JOIN bank_churn b ON c.CustomerId = b.CustomerId
WHERE EXTRACT(QUARTER FROM c.JoiningDate) = 4  
ORDER BY c.EstimatedSalary DESC
LIMIT 5;


-- 3.	Calculate the average number of products used by customers who have a credit card. (SQL)

SELECT AVG(NumOfProducts) AS AverageNoProducts
FROM bank_churn
WHERE HasCrcard = 1;

-- 5.	Compare the average credit score of customers who have exited and those who remain. (SQL)

SELECT Exited, AVG(CreditScore) AS CreditScoreAverage
FROM bank_churn
GROUP BY Exited;

-- 6.	Which gender has a higher average estimated salary, and how does it relate to the number of active accounts? (SQL)

WITH ActiveAccounts AS (
    SELECT CustomerId, COUNT(*) AS ActiveAccounts
    FROM bank_churn
    WHERE IsActiveMember = 1
    GROUP BY CustomerId
)
SELECT 
    CASE WHEN ci.GenderID = 1 THEN 'Male'  ELSE 'Female'   END AS Gender,
    COUNT(aa.CustomerId) AS ActiveAccounts, AVG(EstimatedSalary) AS AverageSalary
FROM customerinfo ci LEFT JOIN ActiveAccounts aa ON ci.CustomerId = aa.CustomerId
GROUP BY Gender
ORDER BY AverageSalary DESC;

-- 7.	Segment the customers based on their credit score and identify the segment with the highest exit rate. (SQL)

WITH CreditScoreSegment AS (
    SELECT CustomerId, IsActiveMember,
    CASE 
        WHEN CreditScore BETWEEN 800 AND 850 THEN 'Excellent'
        WHEN CreditScore BETWEEN 740 AND 799 THEN 'Very Good'
        WHEN CreditScore BETWEEN 670 AND 739 THEN 'Good'
        WHEN CreditScore BETWEEN 580 AND 669 THEN 'Fair'
        ELSE 'Poor'
    END AS CreditScoreSegment
    FROM bank_churn
)

SELECT CreditScoreSegment,
    AVG(CASE WHEN IsActiveMember = 0 THEN 0 ELSE 1 END) AS exit_rate
FROM CreditScoreSegment
GROUP BY CreditScoreSegment
ORDER BY exit_rate DESC
LIMIT 1;

-- 8.	Find out which geographic region has the highest number of active customers with a tenure greater than 5 years. (SQL)

SELECT g.GeographyLocation, COUNT(b.CustomerId) AS active_customers
FROM geography g
INNER JOIN customerinfo c ON g.GeographyID = c.GeographyID
INNER JOIN bank_churn b ON c.CustomerId = b.CustomerId
WHERE b.Tenure > 5
GROUP BY g.GeographyLocation
ORDER BY active_customers DESC
LIMIT 1;

-- 15.	Using SQL, write a query to find out the gender-wise average income of males and females in each geography id. Also, rank the gender according to the average value. (SQL)

WITH AverageGeographySalary AS (
    SELECT 
        g.GeographyLocation,
        CASE 
            WHEN c.GenderID = 1 THEN 'Male'
            ELSE 'Female'
        END AS Gender,
        AVG(c.EstimatedSalary) AS avg_salary
    FROM customerinfo c
    INNER JOIN geography g ON c.GeographyID = g.GeographyID
    GROUP BY g.GeographyLocation, c.GenderID
    ORDER BY g.GeographyLocation
)
SELECT *,
    RANK() OVER (PARTITION BY GeographyLocation ORDER BY avg_salary DESC) AS 'rank'
FROM AverageGeographySalary;

-- 16.	Using SQL, write a query to find out the average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+).

SELECT 
    CASE 
        WHEN age BETWEEN 18 AND 30 THEN 'Adult'
        WHEN age BETWEEN 31 AND 50 THEN 'Middle-Aged'
        ELSE 'Old-Aged'
    END AS AgeBrackets,
    AVG(b.tenure) AS avg_tenure
FROM customerinfo c
JOIN bank_churn b ON c.CustomerId = b.CustomerId
WHERE b.exited = 1
GROUP BY AgeBrackets
ORDER BY AgeBrackets;

-- 20.	According to the age buckets find the number of customers who have a credit card. Also retrieve those buckets that have lesser than average number of credit cards per bucket.

  WITH creditinfo AS (
    SELECT 
        CASE 
            WHEN age BETWEEN 18 AND 30 THEN 'Adult'
            WHEN age BETWEEN 31 AND 50 THEN 'Middle-Aged'
            ELSE 'Old-Aged'
        END AS AgeBrackets,
        COUNT(c.CustomerId) AS HasCreditCard
    FROM customerinfo c
    JOIN bank_churn b ON c.CustomerId = b.CustomerId
    WHERE b.Has_creditcard = 1  -- Ensures filtering is done before counting
    GROUP BY AgeBrackets
)
SELECT *
FROM creditinfo
WHERE HasCreditCard < (
    SELECT AVG(HasCreditCard) 
    FROM creditinfo
);


-- 21 Rank the Locations as per the number of people who have churned the bank and average balance of the customers.

SELECT 
    g.GeographyLocation, 
    COUNT(b.CustomerId) AS TotalExited, 
    AVG(b.Balance) AS avg_bal
FROM bank_churn b
JOIN customerinfo c ON b.CustomerId = c.CustomerId
JOIN geography g ON c.GeographyID = g.GeographyID
WHERE b.Exited = 1
GROUP BY g.GeographyLocation
ORDER BY COUNT(b.CustomerId) DESC;

-- 23.	Without using “Join”, can we get the “ExitCategory” from ExitCustomers table to Bank_Churn table? If yes do this using SQL.

SELECT 
    CustomerId, 
    CreditScore, 
    Tenure, 
    Balance, 
    NumOfProducts, 
    HasCrCard, 
    IsActiveMember,
    CASE 
        WHEN Exited = 0 THEN 'Retain'
        ELSE 'Exit'
    END AS ExitCategory
FROM bank_churn;

-- 25.	Write the query to get the customer IDs, their last name, and whether they are active or not for the customers whose surname ends with “on”.

SELECT 
    c.CustomerId, 
    c.Surname, 
    CASE 
        WHEN b.IsActiveMember = 1 THEN 'Active'
        ELSE 'Inactive'
    END AS ActivityStatus
FROM customerinfo c
JOIN bank_churn b ON c.CustomerId = b.CustomerId
WHERE c.Surname LIKE '%on'
ORDER BY c.Surname;

-- 26.	Can you observe any data disrupency in the Customer’s data? As a hint it’s present in the IsActiveMember and Exited columns. One more point to consider is that the data in the Exited Column is absolutely correct and accurate.

SELECT *
FROM bank_churn b join customerinfo c on b.CustomerId = c.CustomerId
WHERE b.Exited =1 and b.IsActiveMember =1;
     

-- ------------------------------- Subjective Questions ----------------------------------------------

-- 9.	Utilize SQL queries to segment customers based on demographics and account details.

SELECT 
    g.GeographyLocation,
    CASE 
        WHEN EstimatedSalary < 50000 THEN 'Low'
        WHEN EstimatedSalary < 100000 THEN 'Medium'
        ELSE 'High'
    END AS IncomeSegment,
    CASE 
        WHEN c.GenderID = 1 THEN 'Male'
        ELSE 'Female'
    END AS Gender,
    Age,
    COUNT(c.CustomerId) AS NumberOfCustomers
FROM customerinfo c
JOIN geography g ON c.GeographyID = g.GeographyID
GROUP BY IncomeSegment, g.GeographyLocation, Gender, Age
ORDER BY g.GeographyLocation, Age;
 
-- 14.	In the “Bank_Churn” table how can you modify the name of the “HasCrCard” column to “Has_creditcard”?

ALTER TABLE bank_churn
RENAME COLUMN HasCrCard TO Has_creditcard;