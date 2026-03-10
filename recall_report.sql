-- ============================================================
-- recall_report.sql
-- Tracks active patient recall status for a dental practice.
-- Written for OpenDental (MySQL).
--
-- Original query provided by practice; logic revised by author:
--   - Fixed CASE WHEN boundary conditions in overdue buckets
--   - Added missing 0-6 month overdue category
--   - Scoped overdue count to match bucket date range
-- ============================================================

-- Dates
SET @Today = CURDATE();
SET @StartDate = DATE_SUB(@Today, INTERVAL 18 MONTH);
SET @SixMonthsAgo = DATE_SUB(@Today, INTERVAL 6 MONTH);
SET @NineMonthsAgo = DATE_SUB(@Today, INTERVAL 9 MONTH);
SET @TwelveMonthsAgo = DATE_SUB(@Today, INTERVAL 12 MONTH);
SET @EighteenMonthsAgo = DATE_SUB(@Today, INTERVAL 18 MONTH);

WITH ActivePatients AS (
  SELECT DISTINCT p.PatNum
  FROM patient p
  JOIN appointment a ON a.PatNum = p.PatNum
  WHERE p.PatStatus = 0        -- active patients only
    AND a.AptStatus = 2        -- completed appointments
    AND a.AptDateTime BETWEEN @StartDate AND @Today
),

PatientsOnRecall AS (
  SELECT DISTINCT r.PatNum
  FROM recall r
  JOIN ActivePatients ap ON ap.PatNum = r.PatNum
  JOIN appointment a ON a.PatNum = r.PatNum
  WHERE r.IsDisabled = 0
    AND a.AptStatus = 1        -- scheduled
    AND a.AptDateTime > @Today
    AND r.DateDue > @Today
),

OverdueUnscheduled AS (
  SELECT DISTINCT r.PatNum, r.DateDue
  FROM recall r
  JOIN ActivePatients ap ON ap.PatNum = r.PatNum
  LEFT JOIN appointment a
    ON a.PatNum = r.PatNum
   AND a.AptStatus = 1
   AND a.AptDateTime > @Today
  WHERE r.IsDisabled = 0
    AND r.DateDue <= @Today
    AND a.AptNum IS NULL       -- no future scheduled appointment
),

OverdueBuckets AS (
  SELECT
    PatNum,
    DateDue,
    CASE
      WHEN DateDue <= @SixMonthsAgo    AND DateDue > @NineMonthsAgo    THEN '6-9 Months'
      WHEN DateDue <= @NineMonthsAgo   AND DateDue > @TwelveMonthsAgo  THEN '9-12 Months'
      WHEN DateDue <= @TwelveMonthsAgo AND DateDue >= @EighteenMonthsAgo THEN '12-18 Months'
      ELSE '0-6 Months'
    END AS OverdueCategory
  FROM OverdueUnscheduled
  WHERE DateDue BETWEEN @EighteenMonthsAgo AND @Today
)

SELECT
  (SELECT COUNT(*) FROM ActivePatients) AS `a. Active Patients`,
  (SELECT COUNT(*) FROM PatientsOnRecall) AS `b. On Recall`,
  (SELECT COUNT(*) FROM ActivePatients) - (SELECT COUNT(*) FROM PatientsOnRecall) AS `c. Not on Recall`,
  (SELECT COUNT(*) FROM OverdueUnscheduled
    WHERE DateDue BETWEEN @EighteenMonthsAgo AND @Today) AS `d. Overdue & Unscheduled (<=18 Mo)`,
  SUM(OverdueCategory = '0-6 Months')   AS `d.0 Overdue 0-6 Mo`,
  SUM(OverdueCategory = '6-9 Months')   AS `d.1 Overdue 6-9 Mo`,
  SUM(OverdueCategory = '9-12 Months')  AS `d.2 Overdue 9-12 Mo`,
  SUM(OverdueCategory = '12-18 Months') AS `d.3 Overdue 12-18 Mo`
FROM OverdueBuckets;
