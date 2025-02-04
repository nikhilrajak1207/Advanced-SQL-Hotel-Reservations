# Hotel Reservation Analysis using SQL:

# Project Overview:

This project analyzes hotel reservation data using SQL. It involves data extraction, transformation, and analysis to gain insights into booking trends, pricing variations, and cancellations.

Dataset
The dataset consists of hotel booking details, including:

Booking details (ID, lead time, arrival date)
Guest details (number of adults, children)
Room and pricing information
Booking status (confirmed or canceled)
SQL Implementation
1️⃣ Creating the Table
The table Hotel_RES is created to store hotel reservation data, structured with relevant attributes like booking details, pricing, and market segments.

CREATE TABLE Hotel_RES (
  Booking_ID VARCHAR(10) PRIMARY KEY,
  No_of_Adults SMALLINT,
  No_of_Children SMALLINT,
  No_of_Weekend_Nights SMALLINT,
  No_of_Week_Nights SMALLINT,
  Type_of_Meal_Plan VARCHAR(25),
  Required_Car_Parking_Space SMALLINT,
  Room_Type_Reserved VARCHAR(25),
  Lead_Time INT,
  Arrival_Year INT,
  Arrival_Month INT,
  Arrival_Date INT,
  Market_Segment_Type VARCHAR(25),
  Repeated_Guest SMALLINT,
  No_of_Previous_Cancellations SMALLINT,
  No_of_Previous_Bookings_Not_Cancelled SMALLINT,
  Avg_Price_Per_Room FLOAT,
  No_of_Special_Requests SMALLINT,
  Booking_Status VARCHAR(25)
);

After importing the dataset, we can view the records:
SELECT * FROM Hotel_RES;

# Key SQL Queries and Insights : 
1️⃣ Average Booking Price for Weekdays and Weekends (Jan–March 2017 & 2018)
Calculates the average price per room for weekdays and weekends for the first three months of each year.
Uses CTEs to separate weekday and weekend bookings before joining the results.

WITH Weekend_collection AS (
  SELECT arrival_month, arrival_year, AVG(avg_price_per_room) AS weekend_avg_price
  FROM hotel_res 
  WHERE no_of_weekend_nights != 0 AND no_of_week_nights = 0
  GROUP BY arrival_month, arrival_year
  HAVING arrival_month < 4
),
Weekdays_Collection AS (
  SELECT arrival_month, arrival_year, AVG(avg_price_per_room) AS weekdays_avg_price
  FROM hotel_res 
  WHERE no_of_weekend_nights = 0 AND no_of_week_nights != 0
  GROUP BY arrival_month, arrival_year
  HAVING arrival_month < 4
)
SELECT Weekend_collection.arrival_month, Weekend_collection.arrival_year,
       Weekdays_Collection.weekdays_avg_price, Weekend_collection.weekend_avg_price
FROM Weekend_collection 
INNER JOIN Weekdays_Collection
ON Weekend_collection.arrival_month = Weekdays_Collection.arrival_month
AND Weekend_collection.arrival_year = Weekdays_Collection.arrival_year;
✅ Insight: No data was available for these months in 2017, so only 2018 results are visible.

2️⃣ Monthly Price Difference for Each Room Type :

Compares the average price per room for consecutive months using the LAG function.
Identifies fluctuations in room pricing.

WITH PresentMonth AS (
  SELECT Room_Type_Reserved, Arrival_Month, Arrival_Year,
         AVG(Avg_Price_Per_Room) AS Current_Month_avg_price
  FROM Hotel_RES
  GROUP BY Room_Type_Reserved, Arrival_Month, Arrival_Year
),
PreviousMonth AS (
  SELECT Room_Type_Reserved, Arrival_Month, Arrival_Year, Current_Month_avg_price,
         LAG(Current_Month_avg_price, 1, 0) 
         OVER (PARTITION BY Room_Type_Reserved ORDER BY Arrival_Year, Arrival_Month) AS Prev_Month_Avg_Price
  FROM PresentMonth
)
SELECT Room_Type_Reserved, CONCAT(arrival_month, '/', arrival_year) AS Month_year, 
       Current_Month_avg_price, Prev_Month_Avg_Price,
       Current_Month_avg_price - Prev_Month_Avg_Price AS Price_Difference
FROM PreviousMonth
WHERE Prev_Month_Avg_Price != 0;

✅ Insight: Price changes over time can help in revenue optimization strategies for hotels.

3️⃣ Identifying High Lead Time Bookings (Top 50% by Market Segment) :

Finds bookings where lead time is above the median for each market segment.
Uses PERCENTILE_CONT function to determine the median.

WITH MedianofLeadTime AS (
  SELECT Market_Segment_Type,
         PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Lead_Time) AS Median_Lead_Time
  FROM Hotel_RES
  GROUP BY Market_Segment_Type
),
Above_Median AS (
  SELECT H.Booking_ID, H.Market_Segment_Type, H.Lead_Time, am.Median_Lead_Time
  FROM Hotel_RES H
  JOIN MedianofLeadTime am 
  ON H.Market_Segment_Type = am.Market_Segment_Type
  WHERE H.Lead_Time >= am.Median_Lead_Time
)
SELECT Booking_ID, Market_Segment_Type, Lead_Time
FROM Above_Median
ORDER BY Market_Segment_Type;

✅ Insight: Helps in targeting long-term bookings for better customer engagement.

4️⃣ Months with ≥30% Booking Cancellations:

Identifies months where cancellation rates exceed 30%.
Uses two CTEs to calculate total and canceled bookings before computing the percentage.

WITH TB AS (
  SELECT Arrival_Month, arrival_year, COUNT(Booking_ID) AS TotalBookings
  FROM Hotel_RES 
  GROUP BY Arrival_Month, arrival_year
),
CB AS (
  SELECT arrival_month, arrival_year, COUNT(booking_id) AS Cancelledbookings
  FROM Hotel_Res 
  WHERE booking_status = 'Canceled'
  GROUP BY Arrival_Month, arrival_year
)
SELECT CONCAT(TB.arrival_month, '/', TB.arrival_year) AS Month_year, 
       TB.TotalBookings, CB.Cancelledbookings,
       (CB.Cancelledbookings * 100) / TB.TotalBookings AS Prcnt_booking_cancelled
FROM TB 
INNER JOIN CB
ON TB.arrival_month = CB.arrival_month
AND TB.arrival_year = CB.arrival_year
WHERE (CB.Cancelledbookings * 100) / TB.TotalBookings >= 30;

✅ Insight: Useful for identifying cancellation trends and improving retention strategies.

Key Learnings & Takeaways
✔️ Common Table Expressions (CTEs) to simplify complex queries.
✔️ Window Functions like LAG() for time-based comparisons.
✔️ Aggregations & Percentile Functions for advanced analytics.
✔️ Joins and Data Filtering for efficient data processing.

How to Use the Code?
1️⃣ Clone the Repository
git clone https://github.com/nikhilrajak1207/Advanced-SQL-Hotel-Reservations/.git
2️⃣ Import the SQL File into your database (MySQL, PostgreSQL, etc.).
3️⃣ Run Queries and analyze results.

Conclusion
This project provides data-driven insights into hotel reservations using SQL. It helps in understanding booking trends, pricing strategies, and customer behavior for business optimization.

🔗 GitHub Repository Link: https://github.com/nikhilrajak1207/Advanced-SQL-Hotel-Reservations
