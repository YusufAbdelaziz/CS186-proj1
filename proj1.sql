-- Before running drop any existing views
DROP VIEW IF EXISTS q0;

DROP VIEW IF EXISTS q1i;

DROP VIEW IF EXISTS q1ii;

DROP VIEW IF EXISTS q1iii;

DROP VIEW IF EXISTS q1iv;

DROP VIEW IF EXISTS q2i;

DROP VIEW IF EXISTS q2ii;

DROP VIEW IF EXISTS q2iii;

DROP VIEW IF EXISTS q3i;

DROP VIEW IF EXISTS q3ii;

DROP VIEW IF EXISTS lslg;

DROP VIEW IF EXISTS q3iii;

DROP VIEW IF EXISTS q4i;

DROP VIEW IF EXISTS q4ii;

DROP VIEW IF EXISTS q4iii;

DROP VIEW IF EXISTS q4iv;

DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era) AS
SELECT
  MAX(era)
FROM
  pitching;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear) AS
SELECT
  nameFirst,
  nameLast,
  birthYear
FROM
  people
WHERE
  weight > 300;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear) AS
SELECT
  nameFirst,
  nameLast,
  birthYear
FROM
  people
WHERE
  nameFirst LIKE '% %'
ORDER BY
  nameFirst ASC,
  nameLast ASC;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count) AS
SELECT
  birthYear,
  AVG(height),
  COUNT(*)
FROM
  people
GROUP BY
  birthYear
ORDER BY
  birthYear ASC;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count) AS
SELECT
  *
FROM
  q1iii
WHERE
  avgheight > 70
ORDER BY
  birthyear;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid) AS
SELECT
  p.nameFirst,
  p.nameLast,
  h.playerID,
  h.yearid
FROM
  halloffame AS h
  INNER JOIN people AS p ON h.playerID = p.playerID
WHERE
  h.inducted = 'Y'
ORDER BY
  h.yearid DESC,
  h.playerid ASC;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid) AS
SELECT
  q.namefirst,
  q.namelast,
  q.playerid,
  c.schoolID,
  q.yearid
FROM
  q2i AS q
  INNER JOIN collegeplaying AS c ON c.playerid = q.playerid
  INNER JOIN schools AS s ON s.schoolID = c.schoolID
WHERE
  s.schoolState = 'CA'
ORDER BY
  q.yearid DESC,
  c.schoolid ASC,
  q.playerid ASC;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid) AS
SELECT
  q.playerid,
  q.namefirst,
  q.namelast,
  c.schoolID
FROM
  q2i AS q
  LEFT OUTER JOIN collegeplaying AS c ON q.playerid = c.playerid
ORDER BY
  q.playerid DESC,
  c.schoolid ASC;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg) AS
SELECT
  p.playerID,
  p.nameFirst,
  p.nameLast,
  b.yearID,
  (b.H + b.H2B + 2 * b.H3B + 3 * b.HR) * 1.0 / b.AB * 1.0 AS slg
FROM
  people AS p
  INNER JOIN batting AS b ON b.playerID = p.playerID
WHERE
  b.AB > 50
ORDER BY
  slg DESC,
  b.yearID ASC,
  p.playerID ASC
LIMIT
  10;

-- Question 3ii
CREATE VIEW lslg(playerid, lslgval) AS
SELECT
  playerID,
  (
    SUM(H) + SUM(H2B) + 2 * SUM(H3B) + 3 * SUM(HR)
  ) * 1.0 / SUM(AB) * 1.0
FROM
  batting
GROUP BY
  playerID
HAVING
  SUM(AB) > 50;

CREATE VIEW q3ii(playerid, namefirst, namelast, lslg) AS
SELECT
  p.playerID,
  p.nameFirst,
  p.nameLast,
  l.lslgval
FROM
  people AS p
  INNER JOIN lslg AS l ON l.playerID = p.playerID
ORDER BY
  l.lslgval DESC,
  p.playerID ASC
LIMIT
  10;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg) AS
SELECT
  p.nameFirst,
  p.nameLast,
  l.lslgval
FROM
  people AS p
  INNER JOIN lslg AS l ON l.playerID = p.playerID
WHERE
  l.lslgval > (
    SELECT
      lslgval
    FROM
      lslg
    WHERE
      playerID = 'mayswi01'
  );

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg) AS
SELECT
  yearID,
  MIN(salary),
  MAX(salary),
  AVG(salary)
FROM
  salaries
GROUP BY
  yearID;

;

-- Helper table for 4ii
DROP TABLE IF EXISTS binids;

CREATE TABLE binids(binid);

INSERT INTO
  binids
VALUES
  (0),
  (1),
  (2),
  (3),
  (4),
  (5),
  (6),
  (7),
  (8),
  (9);

DROP VIEW IF EXISTS bucketCount;

DROP VIEW IF EXISTS salaries2016;

DROP VIEW IF EXISTS salariesStats;

DROP VIEW IF EXISTS buckets;

CREATE VIEW bucketCount(num) AS
SELECT
  10;

CREATE VIEW salaries2016(salary) AS
SELECT
  salary
FROM
  salaries
WHERE
  yearid = 2016;

CREATE VIEW salariesStats AS
SELECT
  MIN(salary) AS min_num,
  MAX(salary) AS max_num
FROM
  salaries2016;

CREATE VIEW buckets AS
SELECT
  t.bucket,
  CAST(
    salariesStats.min_num + (
      (salariesStats.max_num - salariesStats.min_num) / CAST(bucketCount.num AS numeric)
    ) * t.bucket AS INT
  ) AS min_range,
  CAST(
    salariesStats.min_num + (
      (salariesStats.max_num - salariesStats.min_num) / CAST(bucketCount.num AS numeric)
    ) * (t.bucket + 1) AS INT
  ) AS max_range
FROM
  bucketCount,
  salariesStats,
  (
    SELECT
      ROW_NUMBER() OVER () - 1 AS bucket
    FROM
      salaries2016
    LIMIT
      (
        SELECT
          num
        FROM
          bucketCount
      )
  ) AS t;

CREATE VIEW q4ii(binid, low, high, count) AS
SELECT
  bucket,
  min_range * 1.0,
  max_range * 1.0,
  COUNT(salary)
FROM
  salaries2016
  INNER JOIN buckets ON (
    salaries2016.salary = max_range
    OR (
      salaries2016.salary < max_range
      AND salaries2016.salary >= min_range
    )
  )
GROUP BY
  bucket,
  min_range,
  max_range
ORDER BY
  bucket;

DROP VIEW IF EXISTS salaryStatsByYear;

CREATE VIEW salaryStatsByYear AS
SELECT
  yearID,
  MIN(salary) AS min_salary,
  MAX(salary) AS max_salary,
  AVG(salary) AS avg_salary
FROM
  salaries
GROUP BY
  yearID;

CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff) AS
SELECT
  yearID,
  min_salary_diff,
  max_salary_diff,
  avg_salary_diff
FROM
  (
    SELECT
      yearID,
      min_salary - LAG(min_salary) OVER () AS min_salary_diff,
      max_salary - LAG(max_salary) OVER () AS max_salary_diff,
      avg_salary - LAG(avg_salary) OVER () AS avg_salary_diff
    FROM
      salaryStatsByYear
  ) AS Subquery
WHERE
  yearID != '1985';

DROP VIEW IF EXISTS topSalary;

CREATE VIEW topSalary(yearID, max_salary) AS
SELECT
  yearID,
  MAX(salary)
FROM
  salaries
GROUP BY
  yearID
HAVING
  yearID = 2000
  OR yearID = 2001;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid) AS
SELECT
  p.playerID,
  p.nameFirst,
  p.nameLast,
  s.salary,
  s.yearID
FROM
  people AS p
  INNER JOIN salaries AS s ON p.playerID = s.playerID
WHERE
  s.yearID = 2000
  AND s.salary = (
    SELECT
      max_salary
    FROM
      topSalary
    WHERE
      yearid = 2000
  )
  OR s.yearID = 2001
  AND s.salary = (
    SELECT
      max_salary
    FROM
      topSalary
    WHERE
      yearid = 2001
  );

-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
SELECT
  a.teamID,
  MAX(salary) - MIN(salary)
FROM
  salaries s
  INNER JOIN allstarfull a ON s.playerid = a.playerid
  AND s.yearid = a.yearid
WHERE
  s.yearid = 2016
GROUP BY
  a.teamID;