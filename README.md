# sql-portfolio

SQL queries written and improved during dental office operations and school.

i'm not a developer — i'm a data analytics student with a background in healthcare administration.
these queries reflect real problems i was asked to solve, and the process of learning to solve them better.

## context
these queries were written for use with OpenDental, a dental practice management system running on MySQL.
all patient data, provider names, and practice information has been removed.

## what's here

### recall_report.sql
tracks active patients by recall status — who's scheduled, who's overdue, and how overdue.
i revised the original logic to fix boundary conditions in the overdue buckets and added a missing 0-6 month category.

### new_patient_exam.sql
pulls new patient exam records for a given date range, including referral source and provider.

### birthday_query.sql
identifies patients with appointments near their birthday within a given month.

## tools
- MySQL
- OpenDental (dental practice management software)

---
*queries are sanitized. original versions were developed with AI assistance; revisions and improvements are my own.*
