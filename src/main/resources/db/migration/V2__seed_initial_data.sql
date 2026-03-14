-- 11) Students: 20 per department (640 total)
-- Users: ogrenci.<deptcode>.<nn>@tufanuni.local
-- StudentNo: STU-<DEPTCODE>-<NNN>
WITH
    pwd AS (
        SELECT '$2b$10$BQZWP4ZyrhDcgMd0vlfGYevXPwCAxCp66JKB976RxTmYot3sbczNa'::varchar AS hash  -- ChangeMe123!
    ),
    deps AS (
        SELECT d.id AS department_id, d.code AS dept_code,
               f.id AS faculty_id, c.id AS campus_id
        FROM departments d
                 JOIN faculties f ON f.id=d.faculty_id
                 JOIN campuses c ON c.id=f.campus_id
        WHERE c.code='TUFAN'
    ),
    gen AS (
        SELECT
            department_id, faculty_id, campus_id, dept_code,
            gs AS n,
            'ogrenci.'||lower(dept_code)||'.'||lpad(gs::text,2,'0')||'@tufanuni.local' AS email,
            (SELECT hash FROM pwd) AS password_hash
        FROM deps
                 CROSS JOIN generate_series(1,20) gs
    ),
    name_lists AS (
        SELECT
            ARRAY[
                'Ali','Veli','Mehmet','Ahmet','Mustafa','Murat','Emre','Kerem','Oğuz','Berk','Kaan','Eren','Yasin','İsmail','Sefa',
                'Hakan','Serkan','Onur','Burak','Cem','Can','Deniz','Umut','Kubilay','Furkan','Batuhan','Tolga','Tuna','Kadir','Volkan',
                'Selim','Baran','Arda','Yiğit','Efe','Alper','Sarp','Mert','Şahin','Gökhan','İlker','Bora','Enes','Halil','Cihan',
                'Zeynep','Elif','Ece','Merve','Büşra','Ceren','İlayda','Sena','Derya','Naz','Aslı','Beyza','Melisa','Gizem','Nisa'
                ]::text[] AS fn,
            ARRAY[
                'Yılmaz','Demir','Kaya','Şahin','Aydın','Çelik','Arslan','Doğan','Kurt','Koç','Öztürk','Güneş','Polat','Erdoğan','Yıldız',
                'Aslan','Kılıç','Taş','Bulut','Aksoy','Karaca','Keskin','Avcı','Yalçın','Kaplan','Özcan','Tekin','Yavuz','Bayram','Işık',
                'Gür','Sönmez','Yıldırım','Kara','Eren','Dinç','Uçar','Sezer','Bozkurt','Şimşek','Acar','Korkmaz','Turan','Özdemir','Köksal',
                'Şen','Güven','Toprak','Çetin','Köse','Bilgin','Demirtaş','Kalkan','Uzun','Ergin','Güler','Öner','Yaman','Karaaslan','Aktaş'
                ]::text[] AS ln
    ),
    with_names AS (
        SELECT
            g.*,
            -- md5(email) -> deterministic dağıtım, tekrarları azaltır
            (SELECT fn[
                        (abs((('x'||substr(md5(g.email),1,8))::bit(32)::int)) % array_length(fn,1)) + 1
                        ] FROM name_lists) AS first_name,
            (SELECT ln[
                        (abs((('x'||substr(md5(g.email),9,8))::bit(32)::int)) % array_length(ln,1)) + 1
                        ] FROM name_lists) AS last_name
        FROM gen g
    )
-- 11.a) create student users
INSERT INTO users (email, password_hash, first_name, last_name, is_active)
SELECT email, password_hash, first_name, last_name, TRUE
FROM with_names
ON CONFLICT (email) DO NOTHING;

-- 11.b) assign STUDENT role
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u
         JOIN roles r ON r.code='STUDENT'
WHERE u.email LIKE 'ogrenci.%@tufanuni.local'
ON CONFLICT DO NOTHING;

-- 11.c) create students rows
WITH deps AS (
    SELECT d.id AS department_id, d.code AS dept_code,
           f.id AS faculty_id, c.id AS campus_id
    FROM departments d
             JOIN faculties f ON f.id=d.faculty_id
             JOIN campuses c ON c.id=f.campus_id
    WHERE c.code='TUFAN'
),
     u AS (
         SELECT id AS user_id, email
         FROM users
         WHERE email LIKE 'ogrenci.%@tufanuni.local'
     ),
     parsed AS (
         SELECT
             user_id,
             split_part(split_part(email,'@',1),'.',2) AS dept_code,
             split_part(split_part(email,'@',1),'.',3)::int AS n
         FROM u
     )
INSERT INTO students (user_id, student_no, campus_id, faculty_id, department_id, enrollment_year, status)
SELECT
    p.user_id,
    'STU-'||upper(p.dept_code)||'-'||lpad(p.n::text,3,'0') AS student_no,
    d.campus_id,
    d.faculty_id,
    d.department_id,
    2026,
    'ACTIVE'
FROM parsed p
         JOIN deps d ON lower(d.dept_code) = lower(p.dept_code)
ON CONFLICT (user_id) DO NOTHING;