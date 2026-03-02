USE [fontes-utilization];
GO

WITH provider_stats AS (
    SELECT
        NPI,
        MAX([Provider_Last_Name])  AS LastName,
        MAX([Provider_First_Name]) AS FirstName,
        AVG(CAST([Percentile] AS float)) AS AvgPercentile
    FROM dbo.Utilization
    WHERE [Percentile] IS NOT NULL
    GROUP BY NPI
)
SELECT
    NPI,
    LastName,
    FirstName,
    AvgPercentile,
    RANK() OVER (ORDER BY AvgPercentile DESC) AS PercentileRank
FROM provider_stats;


SELECT
    NPI,
    [Provider_Last_Name],
    [Provider_First_Name],
    [Procedure_Category],
    [Percentile],
    CASE
        WHEN [Percentile] >= 80 THEN 'High Utilization'
        WHEN [Percentile] >= 60 THEN 'Moderate Utilization'
        WHEN [Percentile] IS NULL THEN 'No Score'
        ELSE 'Typical Utilization'
    END AS UtilizationCategory
FROM dbo.Utilization;

SELECT
    [Procedure_Category],
    COUNT(DISTINCT NPI) AS UniqueProviders,
    AVG(CAST([Percentile] AS float)) AS AvgPercentile
FROM dbo.Utilization
WHERE [Percentile] IS NOT NULL
GROUP BY [Procedure_Category]
ORDER BY AvgPercentile DESC;

CREATE OR ALTER VIEW dbo.v_Utilization_KPIs AS
SELECT
    COUNT(DISTINCT NPI) AS TotalProviders,
    COUNT(*) AS TotalProcedureRecords,
    AVG(CAST([Percentile] AS float)) AS AveragePercentile,
    SUM(CASE WHEN [Percentile] >= 80 THEN 1 ELSE 0 END) AS HighUtilizationRecords
FROM dbo.Utilization;
GO

CREATE OR ALTER VIEW dbo.v_Procedure_Outliers AS
SELECT
    Procedure_Category,
    COUNT(DISTINCT NPI) AS UniqueProviders,
    AVG(CAST(Percentile AS float)) AS AvgPercentile
FROM dbo.Utilization
WHERE Percentile IS NOT NULL
GROUP BY Procedure_Category
HAVING COUNT(DISTINCT NPI) >= 25   -- avoids tiny-sample noise
GO

SELECT TOP 15 *
FROM dbo.v_Procedure_Outliers
ORDER BY AvgPercentile DESC;

CREATE OR ALTER VIEW dbo.v_Provider_Utilization AS
SELECT
    NPI,
    MAX(Provider_Last_Name) AS ProviderLastName,
    MAX(Provider_First_Name) AS ProviderFirstName,
    AVG(CAST(Percentile AS float)) AS AvgPercentile,
    COUNT(*) AS ProcedureRecords,
    SUM(CASE WHEN CAST(Percentile AS float) >= 80 THEN 1 ELSE 0 END) AS HighUtilizationRecords
FROM dbo.Utilization
WHERE Percentile IS NOT NULL
GROUP BY NPI;
GO

SELECT TOP 25 *
FROM dbo.v_Provider_Utilization
ORDER BY AvgPercentile DESC;