-- Creating an Empty Table "Hotel_RES":
CREATE TABLE Hotel_RES 
(Booking_ID VARCHAR(10) PRIMARY KEY,
 No_of_Adults SMALLINT  ,
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

-- After Importing the CSV file in the table, Entire Data is visible in the Database.
Select * from Hotel_RES

------------------Questions----------------------------------------------------

--1.For Jan, Feb and March(year 2017 and 2018), show avg price of bookings for weekdays and weekend month wise. 

With Weekend_collection AS
(Select arrival_month,arrival_year,avg(avg_price_per_room) as weekend_avg_price
from hotel_res where no_of_weekend_nights != 0 and no_of_week_nights = 0
group by arrival_month,arrival_year
having arrival_month<4
order by arrival_month),

Weekdays_Collection AS

(Select arrival_month,arrival_year,avg(avg_price_per_room) as weekdays_avg_price
from hotel_res where no_of_weekend_nights = 0 and no_of_week_nights != 0
group by arrival_month,arrival_year
having arrival_month<4
order by arrival_month)

Select Weekend_collection.arrival_month, Weekend_collection.arrival_year,
Weekdays_Collection.weekdays_avg_price,Weekend_collection.weekend_avg_price
From Weekend_collection INNER JOIN Weekdays_Collection
ON Weekend_collection.arrival_month = Weekdays_Collection.arrival_month
AND Weekend_collection.arrival_year = Weekdays_Collection.arrival_year;

/* Since there is no Data, for these months for year 2017, hence only 2018 is visible. First CTE is caslculating Weekend avg price,
Second is calculating  for Weekday and Main Query is joining both of them to get the final result.*/

------------------------------------------------------------------------------------------------

--2.Calculate the difference in the average price per room between consecutive months for each room type.
WITH PresentMonth AS (
SELECT Room_Type_Reserved,Arrival_Month, Arrival_Year,
AVG(Avg_Price_Per_Room) AS Current_Month_avg_price
FROM Hotel_RES
GROUP BY Room_Type_Reserved,Arrival_Month,Arrival_Year
),
PreviousMonth AS (
SELECT Room_Type_Reserved,Arrival_Month,Arrival_Year,Current_Month_avg_price,
LAG(Current_Month_avg_price, 1, 0) OVER (PARTITION BY Room_Type_Reserved ORDER BY Arrival_Year, Arrival_Month) AS Prev_Month_Avg_Price
FROM PresentMonth
)
SELECT Room_Type_Reserved,CONCAT(arrival_month,'/',arrival_year) as Month_year,Current_Month_avg_price,Prev_Month_Avg_Price,
Current_Month_avg_price - Prev_Month_Avg_Price AS Price_Difference
FROM PreviousMonth
WHERE Prev_Month_Avg_Price != 0;

/* Here also 2 CTEs used,First CTE is used to calculate the Average price of current month, second CTE is
using LAG function to get the avg proce of previous month and amin query is calculating the difference between them.*/ 

----------------------------------------------------------------------------------------------

/*3.For each market segment, identify the booking IDs that fall within the top 50th percentile
of lead time for that segment.*/

WITH MedianofLeadTime AS 
(SELECT Market_Segment_Type,
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Lead_Time) AS Median_Lead_Time
FROM Hotel_RES
GROUP BY Market_Segment_Type)
,
Above_Median AS (
SELECT  H.Booking_ID, H.Market_Segment_Type, H.Lead_Time,am.Median_Lead_Time
FROM Hotel_RES H
JOIN 
MedianofLeadTime am 
ON H.Market_Segment_Type = am.Market_Segment_Type
WHERE h.Lead_Time >= am.Median_Lead_Time
)
SELECT Booking_ID,Market_Segment_Type,Lead_Time
FROM Above_Median
ORDER BY Market_Segment_Type;

/* Two CTEs are being used , first is calculating Median time(50 percentile), Second CTE is putting join with first CTE
and filtering the lead time greater than 50th percentile. Main query is showcasing the required data.*/


-----------------------------------------------------------------------------------------------


--4.Show those months, that has 30% of the bookings made in respective month got cancelled.

WITH TB AS
(SELECT 
Arrival_Month,arrival_year,
COUNT(Booking_ID) AS TotalBookings
FROM Hotel_RES GROUP BY 
Arrival_Month,arrival_year
ORDER BY Arrival_Month)
,
CB AS
(SELECT arrival_month,arrival_year,count(booking_id) as Cancelledbookings
FROM Hotel_Res where booking_status = 'Canceled'
group by Arrival_Month,arrival_year
ORDER BY Arrival_Month)
Select CONCAT(TB.arrival_month,'/',TB.arrival_year) as Month_year,TB.TotalBookings,CB.Cancelledbookings,
((CB.Cancelledbookings*100)/TB.TotalBookings) as Prcnt_booking_cancelled
from TB inner join CB
on TB.arrival_month = CB.arrival_month
and TB.arrival_year = CB.arrival_year
where ((CB.Cancelledbookings*100)/TB.TotalBookings) >=30;
);

/* Two CTEs are being used, First is calculating total bookings, second CTE is calculating Cancelled tickets. 
Main query is calculating those bookings which is giving data of ticket being cancelled more than 30% and it is showcasing data.*/

---------------------------------------------------------------------------------------------------------

