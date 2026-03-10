-- ============================================================
-- new_patient_exam.sql
-- Pulls new patient exam records for a given date range.
-- Written for OpenDental (MySQL).
--
-- Returns: patient name, first visit, last visit, referral
-- source, provider, exam codes, and first exam date.
-- ============================================================

/* SET THESE DATES AS NEEDED */
SET @FromDate = '2025-09-01';
SET @ToDate   = '2025-09-30';

SELECT
  p.PatNum,
  CONCAT(p.FName, ' ', p.LName)                          AS PatientName,
  DATE_FORMAT(p.DateFirstVisit, '%m-%d-%Y')              AS FirstVisit,
  (
    SELECT DATE_FORMAT(MAX(a.AptDateTime), '%m-%d-%Y')
    FROM appointment a
    WHERE a.PatNum = p.PatNum
      AND a.AptStatus IN (1, 2, 4)
  )                                                       AS LastVisit,
  CONCAT(COALESCE(r.FName, ''), ' ', COALESCE(r.LName, '')) AS ReferredBy,
  CONCAT(pr.Abbr, ' - ', pr.FName, ' ', pr.LName)        AS ProviderName,
  GROUP_CONCAT(DISTINCT pc.ProcCode ORDER BY pc.ProcCode SEPARATOR ', ') AS ExamCodes,
  MIN(DATE_FORMAT(pl.ProcDate, '%m-%d-%Y'))               AS FirstExamDate

FROM procedurelog pl
INNER JOIN procedurecode pc ON pc.CodeNum = pl.CodeNum
INNER JOIN patient p        ON p.PatNum = pl.PatNum
LEFT  JOIN refattach ra     ON p.PatNum = ra.PatNum AND ra.RefType = 1
LEFT  JOIN referral r       ON r.ReferralNum = ra.ReferralNum
LEFT  JOIN provider pr      ON pr.ProvNum = pl.ProvNum

WHERE
  pl.ProcStatus = 2
  AND pl.ProcDate BETWEEN @FromDate AND @ToDate
  AND (
    pc.ProcCode IN ('D0150', 'D0150.1')
    OR (pc.ProcCode = 'D0140' AND p.DateFirstVisit BETWEEN @FromDate AND @ToDate)
  )

GROUP BY p.PatNum
ORDER BY p.LName, p.FName;
