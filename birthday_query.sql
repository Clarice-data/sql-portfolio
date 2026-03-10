-- ============================================================
-- birthday_query.sql
-- Finds patients with appointments near their birthday
-- within a specified month. Written for OpenDental (MySQL).
-- ============================================================

/* SET THESE DATES AS NEEDED */
SET @StartDate = '2025-10-01';
SET @EndDate   = '2025-10-31';

SELECT
  p.PatNum,
  CONCAT(p.FName, ' ', p.LName) AS FullName,
  p.Birthdate,
  a.AptDateTime,
  prov1.Abbr AS ScheduledProv,
  prov2.Abbr AS HygieneProv,
  CASE
    WHEN DATEDIFF(a.AptDateTime,
      DATE_FORMAT(CONCAT(YEAR(a.AptDateTime), '-', MONTH(p.Birthdate), '-', DAY(p.Birthdate)), '%Y-%m-%d')) = 0
      THEN 'On Birthday'
    WHEN DATEDIFF(a.AptDateTime,
      DATE_FORMAT(CONCAT(YEAR(a.AptDateTime), '-', MONTH(p.Birthdate), '-', DAY(p.Birthdate)), '%Y-%m-%d')) > 0
      THEN CONCAT('After (', DATEDIFF(a.AptDateTime,
        DATE_FORMAT(CONCAT(YEAR(a.AptDateTime), '-', MONTH(p.Birthdate), '-', DAY(p.Birthdate)), '%Y-%m-%d')), ' days)')
    ELSE CONCAT('Before (', ABS(DATEDIFF(a.AptDateTime,
        DATE_FORMAT(CONCAT(YEAR(a.AptDateTime), '-', MONTH(p.Birthdate), '-', DAY(p.Birthdate)), '%Y-%m-%d'))), ' days)')
  END AS DaysFromBirthday

FROM appointment a
INNER JOIN patient p    ON a.PatNum = p.PatNum
LEFT  JOIN provider prov1 ON a.ProvNum = prov1.ProvNum
LEFT  JOIN provider prov2 ON a.ProvHyg = prov2.ProvNum

WHERE
  p.PatStatus = 0                          -- active patients only
  AND a.AptDateTime BETWEEN @StartDate AND @EndDate
  AND MONTH(p.Birthdate) = MONTH(CURDATE())
  AND p.Birthdate != '0001-01-01'          -- exclude blank birthdates

ORDER BY a.AptDateTime;
