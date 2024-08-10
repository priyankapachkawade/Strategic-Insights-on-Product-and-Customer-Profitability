/************************************************************************************************
Question 1: Get the common commodities between the Top 10 costliest commodities of 2019 and 2020.
************************************************************************************************/
select * from price_details;
SELECT * FROM commodities_info;
-- Extra Line
Create a temporary table for the top 10 costliest commodities in 2019
CREATE TEMPORARY TABLE Top10_2019 AS (
  SELECT Commodity_Id
  FROM price_details
  WHERE YEAR(Date) = 2019
  ORDER BY Retail_Price DESC
  LIMIT 10
);

-- Create a temporary table for the top 10 costliest commodities in 2020
CREATE TEMPORARY TABLE Top10_2020 AS (
  SELECT Commodity_Id
  FROM price_details
  WHERE YEAR(Date) = 2020
  ORDER BY Retail_Price DESC
  LIMIT 10
);

-- Retrieve the common commodities between the two years
SELECT ci.Commodity
FROM commodities_info ci
JOIN Top10_2019 t2019 ON ci.Id = t2019.Commodity_Id
JOIN Top10_2020 t2020 ON ci.Id = t2020.Commodity_Id;

/************************************************************************************************
Question 2: What is the maximum difference between the prices of a commodity at one place vs the other 
for the month of Jun 2020? Which commodity was it for?

Algorithm:
Input: price_details: Id, Region_Id, Commodity_Id, Date and Retail_Price; commodities_info: Id and Commodity
Expected Output: Commodity | price difference;  Retain the info for highest difference
Step 1: Filter Jun 2020 in Date column of price_details
Step 2: Aggregation – MIN(retail_price), MAX(retail_price) group by commodity
Step 3: Compute the difference between the Max and Min retail price
Step 4: Sort in descending order of price difference; Retain the top most row
************************************************************************************************/
select * from price_details;
SELECT * FROM commodities_info;

WITH Jun2020Prices AS (
    SELECT pd.Commodity_Id,
           MAX(pd.Retail_Price) AS max_price,
           MIN(pd.Retail_Price) AS min_price,
           MAX(pd.Retail_Price) - MIN(pd.Retail_Price) AS price_difference
    FROM price_details pd
    WHERE pd.Date >= '2020-06-01' AND pd.Date <= '2020-06-30'
    GROUP BY pd.Commodity_Id
    ORDER BY price_difference DESC
    LIMIT 1
)
SELECT ci.Commodity, Jun2020Prices.price_difference AS price_difference
FROM Jun2020Prices
INNER JOIN commodities_info ci ON ci.Id = Jun2020Prices.Commodity_Id;

/************************************************************************************************
Question 3: Arrange the commodities in order based on the number of varieties in which they are available, 
with the highest one shown at the top. Which is the 3rd commodity in the list?

Algorithm:
Input: commodities_info: Commodity and Variety
Expected Output: Commodity | Variety count;  Sort in descending order of Variety count
Step 1: Aggregation – COUNT(DISTINCT variety), group by Commodity
Step 2: Sort the final table in descending order of Variety count
************************************************************************************************/

SELECT * FROM commodities_info;

SELECT Commodity, COUNT(DISTINCT Variety) AS Variety_Count
FROM commodities_info 
GROUP BY Commodity
ORDER BY Variety_Count  DESC;

    SELECT Commodity, COUNT(DISTINCT Variety) AS Variety_Count
    FROM commodities_info 
    GROUP BY Commodity
    ORDER BY Variety_Count DESC
LIMIT 1 OFFSET 2;

/************************************************************************************************
Question 4: In the state with the least number of data points available. 
Which commodity has the highest number of data points available?

Algorithm:
Input: price_details: Id, region_id, commodity_id region_info: Id and State commodities_info: Id and Commodity
Expected Output: commodity;  Expecting only one value as output
Step 1: Join region info and price details using the Region_Id from price_details with Id from region_info
Step 2: From result of Step 1, perform aggregation – COUNT(Id), group by State; 
Step 3: Sort the result based on the record count computed in Step 2 in ascending order; 
		Filter for the top State
Step 4: Filter for the state identified from Step 3 from the price_details table
Step 5: Aggregation – COUNT(Id), group by commodity_id; Sort in descending order of count 
Step 6: Filter for top 1 value and join with commodities_info to get the commodity name
************************************************************************************************/
select * from region_info;
select * from price_details;
SELECT * FROM commodities_info;

WITH StateDataCounts AS (
    SELECT ri.State, COUNT(pd.Id) AS Data_Count
    FROM price_details pd
    JOIN region_info ri ON pd.Region_Id = ri.Id
    GROUP BY ri.State
    ORDER BY Data_Count ASC
    LIMIT 1
),
CommodityDataCounts AS (
    SELECT pd.Commodity_Id, COUNT(pd.Id) AS Data_Count
    FROM price_details pd
    JOIN region_info ri ON pd.Region_Id = ri.Id
    WHERE ri.State = (SELECT State FROM StateDataCounts)
    GROUP BY pd.Commodity_Id
    ORDER BY Data_Count DESC
    LIMIT 1
)
SELECT ci.Commodity
FROM commodities_info ci
INNER JOIN CommodityDataCounts cdc ON ci.Id = cdc.Commodity_Id;

/*******************************************************************************************************
Question 5: What is the price variation of commodities for each city from Jan 2019 to Dec 2020. 
			Which commodity has seen the highest price variation and in which city?
Algorithm:
Input: price_details: Id, region_id, commodity_id, date, retail_price 
	   region_info: Id and City 
	   commodities_info: Id and Commodity
Expected Output: Commodity | city | Start Price | End Price | Variation absolute | Variation Percentage;  
Sort in descending order of variation %

Step 1: Filter for Jan 2019 from Date column of the price_details table
Step 2: Filter for Dec 2020 from Date column of the price_details table
Step 3: Do an inner join between the results from Step 1 and Step 2 on region_id and commodity id
Step 4: Name the price from Step 1 result as Start Price and Step 2 result as End Price
Step 5: Calculate Variations in absolute and percentage; 
		Sort the final table in descending order of Variation Percentage
Step 6: Filter for 1st record and join with region_info, commodities_info to get city and commodity name
********************************************************************************************************/

-- Step 1: Filter for Jan 2019 from Date column of the price_details table
WITH start_price AS (
  SELECT Region_Id, Commodity_Id, Retail_Price as Start_Price
  FROM commodity_db.price_details
  WHERE YEAR(Date) = 2019 AND MONTH(Date) = 1
),
-- Step 2: Filter for Dec 2020 from Date column of the price_details table
end_price AS (
  SELECT Region_Id, Commodity_Id, Retail_Price as End_Price
  FROM commodity_db.price_details
  WHERE YEAR(Date) = 2020 AND MONTH(Date) = 12
),
-- Step 3: Do an inner join between the results from Step 1 and Step 2 on region_id and commodity id
joined_data AS (
  SELECT sp.Region_Id, sp.Commodity_Id, sp.Start_Price, ep.End_Price
  FROM start_price sp
  JOIN end_price ep ON sp.Region_Id = ep.Region_Id AND sp.Commodity_Id = ep.Commodity_Id
),
-- Step 4: Name the price from Step 1 result as Start Price and Step 2 result as End Price
-- Step 5: Calculate Variations in absolute and percentage; Sort the final table in descending order of Variation Percentage
price_variation AS (
  SELECT Region_Id, Commodity_Id, Start_Price, End_Price, 
         ABS(End_Price - Start_Price) as Variation_Absolute,
         ((End_Price - Start_Price) / Start_Price) * 100 as Variation_Percentage
  FROM joined_data
  ORDER BY Variation_Percentage DESC
),
-- Step 6: Filter for 1st record and join with region_info, commodities_info to get city and commodity name
top_variation AS (
  SELECT *
  FROM price_variation
  LIMIT 1 
)
SELECT ci.Commodity, ri.Centre as City, tv.Start_Price, tv.End_Price, tv.Variation_Absolute, tv.Variation_Percentage
FROM top_variation tv
JOIN commodity_db.region_info ri ON tv.Region_Id = ri.Id
JOIN commodity_db.commodities_info ci ON tv.Commodity_Id = ci.Id;

