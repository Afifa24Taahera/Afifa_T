# Window Functions (RANK vs. DENSE_RANK) in a Multi-Table Context

#Question:
#Write a query to display each student's ID, assessment ID, and their score. Additionally, include two columns: one showing the student's rank and another showing their dense rank within each assessment based on their scores in descending order. Explain the difference between the RANK() and DENSE_RANK() functions in this context.
SELECT 
    id_student,
    id_assessment,
    score,
    RANK() OVER (PARTITION BY id_assessment ORDER BY score DESC) AS ranked,
    DENSE_RANK() OVER (PARTITION BY id_assessment ORDER BY score DESC) AS dense_ranked
FROM studentAssessment;

#Rank() - Its skips the rank after ties.
#Dense_Rank() - It does not skips the rank even if there is ties.alter

#Question:
#Create a query that lists each course ID, assessment ID, and the top three students based on their scores. Use the RANK() function to determine the top performers, ensuring that ties in scores are appropriately handled.
SELECT 
    a.id_course,
    sa.id_assessment,
    sa.id_student,
    sa.score,
    RANK() OVER (
        PARTITION BY a.id_course, sa.id_assessment 
        ORDER BY sa.score DESC
    ) AS ranked
FROM studentAssessment sa
JOIN assessments a ON sa.id_assessment = a.id_assessment
WHERE ranked <= 3;

#Question:
#Generate a report that shows each course ID, the total number of students enrolled, and ranks the courses based on enrollment size using both RANK() and DENSE_RANK(). Discuss any differences observed in the rankings produced by these functions.
SELECT 
    code_module AS course_id,
    COUNT(DISTINCT id_student) AS total_students,
    RANK() OVER (ORDER BY COUNT(DISTINCT id_student) DESC) AS ranked,
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT id_student) DESC) AS dense_ranked
FROM studentRegistration 
GROUP BY code_module;


#Subtopic 2: Teaching Multiple Window Functions in Education Analytics
#Question:
#Write a query to compute the cumulative score for each student across all their assessments. Display the student's ID, assessment ID, individual assessment score, and their cumulative score, ordered by student ID and assessment date.
SELECT 
    sa.id_student,
    sa.id_assessment,
    a.date_submitted,
    sa.score,
    SUM(sa.score) OVER (
        PARTITION BY sa.id_student 
        ORDER BY a.date_submitted
	) AS cumulative_score
FROM studentAssessment sa
JOIN assessments a ON sa.id_assessment = a.id_assessment
ORDER BY sa.id_student, a.date_submitted;

#Question:
#Create a query that calculates the average assessment score for each course. Display the course ID, assessment ID, student ID, and the average score of the course. Use the PARTITION BY clause to segment the data appropriately.
SELECT 
    sa.id_student,
    sa.id_assessment,
    a.code_module AS course_id,
    AVG(sa.score) OVER (
        PARTITION BY a.code_module
    ) AS avg_course_score
FROM studentAssessment sa
JOIN assessments a ON sa.id_assessment = a.id_assessment;


#Question:
#Develop a query that shows each student's ID, assessment ID, assessment date, and their score. Include an additional column that displays the student's previous assessment score using the LAG() function. This will help in analyzing changes in performance over time.
SELECT 
    sa.id_student,
    sa.id_assessment,
    a.date_submitted,
    sa.score,
    LAG(sa.score) OVER (
        PARTITION BY sa.id_student 
        ORDER BY a.date_submitted
    ) AS previous_score
FROM studentAssessment sa
JOIN assessments a ON sa.id_assessment = a.id_assessment
ORDER BY sa.id_student, a.date_submitted;

#Subtopic 3: Business Goals & Student Tasks
#Using the dataset, analyze the activity logs to identify students who have not accessed course materials for an extended period. Write a query to list student IDs and the number of days since their last activity. This information can be used to proactively reach out to at-risk students.

#Identify courses with the lowest average number of student interactions. Write a query that calculates the average number of interactions per student for each course and lists the courses with the lowest averages. Provide recommendations on how to increase engagement in these courses.
WITH student_clicks AS (
    SELECT 
        code_module,
        code_presentation,
        id_student,
        SUM(sum_click) AS total_clicks
    FROM studentVle
    GROUP BY code_module, code_presentation, id_student
),
course_avg_interaction AS (
    SELECT 
        code_module,
        code_presentation,
        AVG(total_clicks) AS avg_clicks_per_student
    FROM student_clicks
    GROUP BY code_module, code_presentation
)
SELECT 
    code_module AS course_id,
    code_presentation AS term,
    avg_clicks_per_student
FROM course_avg_interaction
ORDER BY avg_clicks_per_student ASC;

#Analyze the dataset to find correlations between assessment submission dates and student scores. Write a query that calculates the average score for assessments submitted on different days of the week. Based on your findings, suggest the best days to schedule assessments to enhance student performance. 
WITH scored_dates AS (
    SELECT 
        sa.id_student,
        sa.id_assessment,
        sa.score,
        a.date_submitted,
        Date(a.date_submitted) AS day_of_week
    FROM studentAssessment sa
    JOIN assessments a ON sa.id_assessment = a.id_assessment
),
weekday_avg AS (
    SELECT 
        day_of_week,
        AVG(score) AS avg_score
    FROM scored_dates
    GROUP BY day_of_week
)
SELECT 
    CASE day_of_week
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END AS weekday,
    avg_score
FROM weekday_avg
ORDER BY avg_score DESC;
