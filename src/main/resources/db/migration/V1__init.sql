-- V1__init.sql (NEW)
-- TufanUniversity schema (MVP + extensible)
-- IMPORTANT: No INSERTs here. Seed data in V2.
BEGIN;

CREATE EXTENSION IF NOT EXISTS btree_gist;

-- =========================
--  ORGANIZATION
-- =========================
CREATE TABLE universities (
                              id           SMALLINT PRIMARY KEY DEFAULT 1,
                              name         VARCHAR(200) NOT NULL,
                              short_name   VARCHAR(50),
                              website      VARCHAR(200),
                              email        VARCHAR(200),
                              phone        VARCHAR(50),
                              address      TEXT,
                              updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
                              CONSTRAINT universities_singleton CHECK (id = 1)
);

CREATE TABLE campuses (
                          id            BIGSERIAL PRIMARY KEY,
                          university_id SMALLINT NOT NULL REFERENCES universities(id) ON DELETE RESTRICT,
                          code          VARCHAR(50) NOT NULL UNIQUE,
                          name          VARCHAR(150) NOT NULL,
                          address       TEXT,
                          city          VARCHAR(100),
                          country       VARCHAR(100),
                          created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE faculties (
                           id         BIGSERIAL PRIMARY KEY,
                           campus_id  BIGINT NOT NULL REFERENCES campuses(id) ON DELETE RESTRICT,
                           code       VARCHAR(50) NOT NULL,
                           name       VARCHAR(150) NOT NULL,
                           created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                           UNIQUE (campus_id, code)
);

CREATE TABLE departments (
                             id         BIGSERIAL PRIMARY KEY,
                             faculty_id BIGINT NOT NULL REFERENCES faculties(id) ON DELETE RESTRICT,
                             code       VARCHAR(50) NOT NULL,
                             name       VARCHAR(150) NOT NULL,
                             created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                             UNIQUE (faculty_id, code)
);

CREATE INDEX idx_faculties_campus_id   ON faculties(campus_id);
CREATE INDEX idx_departments_faculty_id ON departments(faculty_id);

-- Optional physical infra
CREATE TABLE buildings (
                           id         BIGSERIAL PRIMARY KEY,
                           campus_id  BIGINT NOT NULL REFERENCES campuses(id) ON DELETE RESTRICT,
                           code       VARCHAR(50) NOT NULL,
                           name       VARCHAR(150) NOT NULL,
                           address    TEXT,
                           created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                           UNIQUE (campus_id, code)
);

CREATE TABLE rooms (
                       id          BIGSERIAL PRIMARY KEY,
                       building_id BIGINT NOT NULL REFERENCES buildings(id) ON DELETE RESTRICT,
                       code        VARCHAR(50) NOT NULL,
                       name        VARCHAR(150),
                       capacity    INT NOT NULL DEFAULT 0 CHECK (capacity >= 0),
                       floor       VARCHAR(20),
                       UNIQUE (building_id, code)
);

CREATE INDEX idx_buildings_campus_id ON buildings(campus_id);
CREATE INDEX idx_rooms_building_id   ON rooms(building_id);

-- =========================
--  IDENTITY / RBAC
-- =========================
CREATE TABLE roles (
                       id   BIGSERIAL PRIMARY KEY,
                       code VARCHAR(50) NOT NULL UNIQUE,
                       name VARCHAR(100) NOT NULL
);

CREATE TABLE users (
                       id            BIGSERIAL PRIMARY KEY,
                       email         VARCHAR(255) NOT NULL UNIQUE,
                       password_hash VARCHAR(255) NOT NULL,
                       first_name    VARCHAR(100),
                       last_name     VARCHAR(100),
                       phone         VARCHAR(50),
                       is_active     BOOLEAN NOT NULL DEFAULT TRUE,
                       token_version INT NOT NULL DEFAULT 0,
                       created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
                       updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE user_roles (
                            user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                            role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
                            PRIMARY KEY (user_id, role_id)
);

CREATE INDEX idx_user_roles_role_id ON user_roles(role_id);

CREATE TABLE auth_refresh_tokens (
                                     id             BIGSERIAL PRIMARY KEY,
                                     user_id        BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                                     token_hash     VARCHAR(255) NOT NULL UNIQUE,
                                     device_id      VARCHAR(120),
                                     user_agent     TEXT,
                                     ip_address     INET,
                                     issued_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
                                     expires_at     TIMESTAMPTZ NOT NULL,
                                     revoked_at     TIMESTAMPTZ,
                                     replaced_by_id BIGINT REFERENCES auth_refresh_tokens(id) ON DELETE SET NULL,
                                     CHECK (expires_at > issued_at)
);

CREATE INDEX idx_auth_refresh_tokens_user_id    ON auth_refresh_tokens(user_id);
CREATE INDEX idx_auth_refresh_tokens_expires_at ON auth_refresh_tokens(expires_at);

-- =========================
--  PERSONNEL & STUDENTS
-- =========================
-- personnel_type: RECTOR, DEAN, HEAD, SECRETARY, TEACHER, LIBRARIAN, CAFETERIA, STAFF
CREATE TABLE personnel (
                           id            BIGSERIAL PRIMARY KEY,
                           user_id       BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
                           personnel_no  VARCHAR(50) NOT NULL UNIQUE,
                           personnel_type VARCHAR(30) NOT NULL,
                           title         VARCHAR(80), -- Prof. Dr., Öğr. Gör., Memur, vb.
                           campus_id     BIGINT REFERENCES campuses(id) ON DELETE SET NULL,
                           faculty_id    BIGINT REFERENCES faculties(id) ON DELETE SET NULL,
                           department_id BIGINT REFERENCES departments(id) ON DELETE SET NULL,
                           status        VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
                           created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_personnel_campus_id     ON personnel(campus_id);
CREATE INDEX idx_personnel_faculty_id    ON personnel(faculty_id);
CREATE INDEX idx_personnel_department_id ON personnel(department_id);

-- Teacher can be assigned to multiple departments with approval (dean)
CREATE TABLE personnel_department_assignments (
                                                  id            BIGSERIAL PRIMARY KEY,
                                                  personnel_id  BIGINT NOT NULL REFERENCES personnel(id) ON DELETE CASCADE,
                                                  department_id BIGINT NOT NULL REFERENCES departments(id) ON DELETE RESTRICT,
                                                  approved_by_personnel_id BIGINT REFERENCES personnel(id) ON DELETE SET NULL,
                                                  approved_at   TIMESTAMPTZ,
                                                  starts_on     DATE,
                                                  ends_on       DATE,
                                                  UNIQUE (personnel_id, department_id)
);

CREATE INDEX idx_pda_personnel_id  ON personnel_department_assignments(personnel_id);
CREATE INDEX idx_pda_department_id ON personnel_department_assignments(department_id);

CREATE TABLE students (
                          id              BIGSERIAL PRIMARY KEY,
                          user_id         BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
                          student_no      VARCHAR(50) NOT NULL UNIQUE,
                          campus_id       BIGINT REFERENCES campuses(id) ON DELETE SET NULL,
                          faculty_id      BIGINT REFERENCES faculties(id) ON DELETE SET NULL,
                          department_id   BIGINT REFERENCES departments(id) ON DELETE SET NULL,
                          enrollment_year INT CHECK (enrollment_year BETWEEN 1900 AND 2100),
                          status          VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
                          created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_students_department_id ON students(department_id);

-- =========================
--  TERM & WINDOWS
-- =========================
CREATE TABLE terms (
                       id        BIGSERIAL PRIMARY KEY,
                       campus_id BIGINT NOT NULL REFERENCES campuses(id) ON DELETE RESTRICT,
                       name      VARCHAR(80) NOT NULL, -- "2026-2027"
                       starts_on DATE NOT NULL,
                       ends_on   DATE NOT NULL,
                       created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                       CHECK (ends_on > starts_on)
);

-- window_type: STUDENT_SELF, ADVISOR_WEEK, HEAD_LATE
CREATE TABLE term_windows (
                              id        BIGSERIAL PRIMARY KEY,
                              term_id   BIGINT NOT NULL REFERENCES terms(id) ON DELETE CASCADE,
                              window_type VARCHAR(30) NOT NULL,
                              starts_at TIMESTAMPTZ NOT NULL,
                              ends_at   TIMESTAMPTZ NOT NULL,
                              CHECK (ends_at > starts_at),
                              UNIQUE (term_id, window_type)
);

CREATE INDEX idx_terms_campus_id     ON terms(campus_id);
CREATE INDEX idx_term_windows_term_id ON term_windows(term_id);

-- Advisor assignments for term
CREATE TABLE advisor_assignments (
                                     id          BIGSERIAL PRIMARY KEY,
                                     term_id     BIGINT NOT NULL REFERENCES terms(id) ON DELETE CASCADE,
                                     student_id  BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
                                     advisor_personnel_id BIGINT NOT NULL REFERENCES personnel(id) ON DELETE RESTRICT,
                                     assigned_by_personnel_id BIGINT REFERENCES personnel(id) ON DELETE SET NULL,
                                     created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
                                     UNIQUE (term_id, student_id)
);

CREATE INDEX idx_advisor_assignments_term_id ON advisor_assignments(term_id);

-- =========================
--  COURSES / SECTIONS / MEETINGS
-- =========================
-- course_scope: DEPARTMENT, FACULTY, CAMPUS
CREATE TABLE courses (
                         id          BIGSERIAL PRIMARY KEY,
                         campus_id   BIGINT NOT NULL REFERENCES campuses(id) ON DELETE RESTRICT,
                         scope_type  VARCHAR(20) NOT NULL,
                         owning_faculty_id    BIGINT REFERENCES faculties(id) ON DELETE SET NULL,
                         owning_department_id BIGINT REFERENCES departments(id) ON DELETE SET NULL,
                         code        VARCHAR(50) NOT NULL,
                         name        VARCHAR(200) NOT NULL,
                         credits     INT NOT NULL DEFAULT 0 CHECK (credits >= 0),
                         ects        INT NOT NULL DEFAULT 0 CHECK (ects >= 0),
                         description TEXT,
                         is_active   BOOLEAN NOT NULL DEFAULT TRUE,
                         created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
                         UNIQUE (campus_id, code)
);

CREATE INDEX idx_courses_campus_id ON courses(campus_id);

CREATE TABLE course_prerequisites (
                                      course_id        BIGINT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
                                      prereq_course_id BIGINT NOT NULL REFERENCES courses(id) ON DELETE RESTRICT,
                                      PRIMARY KEY (course_id, prereq_course_id),
                                      CHECK (course_id <> prereq_course_id)
);

CREATE TABLE sections (
                          id           BIGSERIAL PRIMARY KEY,
                          course_id    BIGINT NOT NULL REFERENCES courses(id) ON DELETE RESTRICT,
                          term_id      BIGINT NOT NULL REFERENCES terms(id) ON DELETE RESTRICT,
                          section_no   VARCHAR(20) NOT NULL,
                          teacher_personnel_id BIGINT REFERENCES personnel(id) ON DELETE SET NULL,
                          min_capacity INT NOT NULL DEFAULT 0 CHECK (min_capacity >= 0),
                          capacity     INT NOT NULL DEFAULT 0 CHECK (capacity >= min_capacity),
                          status       VARCHAR(30) NOT NULL DEFAULT 'OPEN', -- OPEN/CLOSED/CANCELLED
                          created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
                          UNIQUE (course_id, term_id, section_no)
);

CREATE INDEX idx_sections_term_id ON sections(term_id);
CREATE INDEX idx_sections_teacher_id ON sections(teacher_personnel_id);

CREATE TABLE section_meetings (
                                  id          BIGSERIAL PRIMARY KEY,
                                  section_id  BIGINT NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
                                  room_id     BIGINT REFERENCES rooms(id) ON DELETE SET NULL,
                                  day_of_week SMALLINT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
                                  start_time  TIME NOT NULL,
                                  end_time    TIME NOT NULL,
                                  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
                                  CHECK (end_time > start_time)
);

ALTER TABLE section_meetings
    ADD CONSTRAINT ex_room_time_conflict
    EXCLUDE USING gist (
    room_id WITH =,
    day_of_week WITH =,
    tsrange(
      ('2000-01-01'::date + start_time)::timestamp,
      ('2000-01-01'::date + end_time)::timestamp,
      '[)'
    ) WITH &&
  )
  WHERE (room_id IS NOT NULL);

-- =========================
--  ENROLLMENT + WAITLIST
-- =========================
-- status: DRAFT, PENDING_ADVISOR_APPROVAL, APPROVED, REJECTED, DROPPED
CREATE TABLE enrollments (
                             id          BIGSERIAL PRIMARY KEY,
                             student_id  BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
                             section_id  BIGINT NOT NULL REFERENCES sections(id) ON DELETE RESTRICT,
                             status      VARCHAR(40) NOT NULL DEFAULT 'DRAFT',
                             submitted_at TIMESTAMPTZ,
                             advisor_approved_by_personnel_id BIGINT REFERENCES personnel(id) ON DELETE SET NULL,
                             advisor_approved_at TIMESTAMPTZ,
                             head_approved_by_personnel_id BIGINT REFERENCES personnel(id) ON DELETE SET NULL,
                             head_approved_at TIMESTAMPTZ,
                             dropped_at  TIMESTAMPTZ,
                             UNIQUE (student_id, section_id)
);

CREATE INDEX idx_enrollments_student_id ON enrollments(student_id);
CREATE INDEX idx_enrollments_section_id ON enrollments(section_id);

CREATE TABLE waitlist_entries (
                                  id          BIGSERIAL PRIMARY KEY,
                                  student_id  BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
                                  section_id  BIGINT NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
                                  position    INT NOT NULL,
                                  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
                                  UNIQUE (student_id, section_id),
                                  UNIQUE (section_id, position)
);

CREATE INDEX idx_waitlist_section_id ON waitlist_entries(section_id);

-- Student-specific course exception (requires approval)
CREATE TABLE course_scope_exceptions (
                                         id          BIGSERIAL PRIMARY KEY,
                                         student_id  BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
                                         course_id   BIGINT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
                                         approved_by_personnel_id BIGINT REFERENCES personnel(id) ON DELETE SET NULL,
                                         approved_at TIMESTAMPTZ,
                                         reason      TEXT,
                                         UNIQUE (student_id, course_id)
);

-- =========================
--  GRADES + CURVE + REVIEW
-- =========================
-- Raw numeric 0-100 and letter grade; GPA computed from letter.
CREATE TABLE enrollment_grades (
                                   enrollment_id BIGINT PRIMARY KEY REFERENCES enrollments(id) ON DELETE CASCADE,
                                   numeric_score NUMERIC(5,2) CHECK (numeric_score BETWEEN 0 AND 100),
                                   letter_grade  VARCHAR(5),
                                   graded_by_personnel_id BIGINT REFERENCES personnel(id) ON DELETE SET NULL,
                                   graded_at     TIMESTAMPTZ,
                                   finalized_at  TIMESTAMPTZ
);

-- Section-specific letter thresholds (curve)
-- e.g. AA >= 70, BA >= 65, ...
CREATE TABLE section_letter_thresholds (
                                           id         BIGSERIAL PRIMARY KEY,
                                           section_id BIGINT NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
                                           letter     VARCHAR(5) NOT NULL,
                                           min_score  NUMERIC(5,2) NOT NULL CHECK (min_score BETWEEN 0 AND 100),
                                           UNIQUE (section_id, letter)
);

CREATE TABLE section_grading_policy (
                                        section_id BIGINT PRIMARY KEY REFERENCES sections(id) ON DELETE CASCADE,
                                        passing_score NUMERIC(5,2) NOT NULL DEFAULT 50 CHECK (passing_score BETWEEN 0 AND 100),
                                        curve_enabled BOOLEAN NOT NULL DEFAULT FALSE,
                                        curve_target_pass_ratio NUMERIC(5,2) CHECK (curve_target_pass_ratio BETWEEN 0 AND 100),
                                        updated_by_personnel_id BIGINT REFERENCES personnel(id) ON DELETE SET NULL,
                                        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Grade review workflow
-- status: REQUESTED, TEACHER_UPDATED, STUDENT_ACCEPTED, STUDENT_REJECTED, HEAD_FINALIZED
CREATE TABLE grade_review_requests (
                                       id           BIGSERIAL PRIMARY KEY,
                                       enrollment_id BIGINT NOT NULL UNIQUE REFERENCES enrollments(id) ON DELETE CASCADE,
                                       requested_by_student_id BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
                                       status       VARCHAR(40) NOT NULL DEFAULT 'REQUESTED',
                                       student_message TEXT,
                                       teacher_message TEXT,
                                       head_message TEXT,
                                       created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
                                       updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =========================
--  APPROVAL ENGINE (POLICY + DELEGATION)
-- =========================
-- type examples: STUDENT_UPDATE, TEACHER_ASSIGN_DEPT, MEETING_RESCHEDULE, COURSE_SCOPE_EXCEPTION, etc.
CREATE TABLE approval_requests (
                                   id           BIGSERIAL PRIMARY KEY,
                                   request_type VARCHAR(80) NOT NULL,
                                   status       VARCHAR(30) NOT NULL DEFAULT 'PENDING', -- PENDING/APPROVED/REJECTED/CANCELLED
                                   requested_by_personnel_id BIGINT REFERENCES personnel(id) ON DELETE SET NULL,
                                   scope_campus_id BIGINT REFERENCES campuses(id) ON DELETE SET NULL,
                                   scope_faculty_id BIGINT REFERENCES faculties(id) ON DELETE SET NULL,
                                   scope_department_id BIGINT REFERENCES departments(id) ON DELETE SET NULL,
                                   payload_json JSONB NOT NULL,
                                   reason TEXT,
                                   decided_by_personnel_id BIGINT REFERENCES personnel(id) ON DELETE SET NULL,
                                   decided_at TIMESTAMPTZ,
                                   created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_approval_requests_status ON approval_requests(status);

CREATE TABLE approval_policies (
                                   id           BIGSERIAL PRIMARY KEY,
                                   request_type VARCHAR(80) NOT NULL,
                                   scope_level  VARCHAR(20) NOT NULL, -- CAMPUS/FACULTY/DEPARTMENT/GLOBAL
                                   scope_campus_id BIGINT REFERENCES campuses(id) ON DELETE CASCADE,
                                   scope_faculty_id BIGINT REFERENCES faculties(id) ON DELETE CASCADE,
                                   scope_department_id BIGINT REFERENCES departments(id) ON DELETE CASCADE,
                                   approver_role_code VARCHAR(50) NOT NULL, -- DEAN/HEAD/SECRETARY/RECTOR etc.
                                   created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
                                   UNIQUE (request_type, scope_level, scope_campus_id, scope_faculty_id, scope_department_id)
);

CREATE TABLE approval_delegations (
                                      id          BIGSERIAL PRIMARY KEY,
                                      from_personnel_id BIGINT NOT NULL REFERENCES personnel(id) ON DELETE CASCADE,
                                      to_personnel_id   BIGINT NOT NULL REFERENCES personnel(id) ON DELETE CASCADE,
                                      request_type VARCHAR(80) NOT NULL,
                                      starts_at   TIMESTAMPTZ NOT NULL,
                                      ends_at     TIMESTAMPTZ NOT NULL,
                                      created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
                                      CHECK (ends_at > starts_at)
);

-- =========================
--  AUDIT LOG + NOTIFICATIONS
-- =========================
CREATE TABLE audit_logs (
                            id         BIGSERIAL PRIMARY KEY,
                            actor_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
                            actor_personnel_id BIGINT REFERENCES personnel(id) ON DELETE SET NULL,
                            action     VARCHAR(80) NOT NULL,
                            entity_type VARCHAR(80),
                            entity_id  VARCHAR(80),
                            before_json JSONB,
                            after_json  JSONB,
                            created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE notifications (
                               id         BIGSERIAL PRIMARY KEY,
                               user_id    BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                               type       VARCHAR(60) NOT NULL,
                               title      VARCHAR(200) NOT NULL,
                               message    TEXT NOT NULL,
                               is_read    BOOLEAN NOT NULL DEFAULT FALSE,
                               created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);

-- =========================
--  DOCUMENTS
-- =========================
CREATE TABLE generated_documents (
                                     id                BIGSERIAL PRIMARY KEY,
                                     student_id         BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
                                     created_by_user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
                                     doc_type           VARCHAR(50) NOT NULL,
                                     file_path          TEXT,
                                     payload_json       JSONB,
                                     created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_generated_documents_student_id ON generated_documents(student_id);

COMMIT;