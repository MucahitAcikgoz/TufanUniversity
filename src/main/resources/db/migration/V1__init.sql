-- V1__init.sql
-- PostgreSQL schema for TufanUniversity (MVP + extensible)
-- NOTE: Seed data (roles/users) moved to V2__seed_default_users.sql

BEGIN;

-- Needed for exclusion constraints (room-timeslot conflicts)
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- =========================
--  AUTH / RBAC
-- =========================
CREATE TABLE roles (
                       id   BIGSERIAL PRIMARY KEY,
                       code VARCHAR(50) NOT NULL UNIQUE,  -- STUDENT, TEACHER, ADMIN, SECRETARY
                       name VARCHAR(100) NOT NULL
);

CREATE TABLE users (
                       id            BIGSERIAL PRIMARY KEY,
                       email         VARCHAR(255) NOT NULL UNIQUE,
                       password_hash VARCHAR(255) NOT NULL,
                       first_name    VARCHAR(100),
                       last_name     VARCHAR(100),
                       is_active     BOOLEAN NOT NULL DEFAULT TRUE,

    -- JWT support: invalidate old access tokens by bumping this number
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

-- Refresh tokens (store HASH, not raw token)
CREATE TABLE auth_refresh_tokens (
                                     id            BIGSERIAL PRIMARY KEY,
                                     user_id       BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- store a hash of the refresh token (never store raw token)
                                     token_hash    VARCHAR(255) NOT NULL UNIQUE,

    -- optional device/session metadata
                                     device_id     VARCHAR(120),
                                     user_agent    TEXT,
                                     ip_address    INET,

                                     issued_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
                                     expires_at    TIMESTAMPTZ NOT NULL,
                                     revoked_at    TIMESTAMPTZ,

    -- rotation chain (optional)
                                     replaced_by_id BIGINT REFERENCES auth_refresh_tokens(id) ON DELETE SET NULL,

                                     CHECK (expires_at > issued_at)
);

CREATE INDEX idx_auth_refresh_tokens_user_id    ON auth_refresh_tokens(user_id);
CREATE INDEX idx_auth_refresh_tokens_expires_at ON auth_refresh_tokens(expires_at);
CREATE INDEX idx_auth_refresh_tokens_revoked_at ON auth_refresh_tokens(revoked_at);

-- =========================
--  CAMPUS / BUILDING / DEPARTMENT
-- =========================
CREATE TABLE campuses (
                          id         BIGSERIAL PRIMARY KEY,
                          code       VARCHAR(50) NOT NULL UNIQUE,
                          name       VARCHAR(150) NOT NULL,
                          address    TEXT,
                          city       VARCHAR(100),
                          country    VARCHAR(100),
                          created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE buildings (
                           id         BIGSERIAL PRIMARY KEY,
                           campus_id  BIGINT NOT NULL REFERENCES campuses(id) ON DELETE RESTRICT,
                           code       VARCHAR(50) NOT NULL,
                           name       VARCHAR(150) NOT NULL,
                           address    TEXT,
                           created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                           UNIQUE (campus_id, code)
);

CREATE INDEX idx_buildings_campus_id ON buildings(campus_id);

CREATE TABLE departments (
                             id          BIGSERIAL PRIMARY KEY,
                             code        VARCHAR(50) NOT NULL UNIQUE,
                             name        VARCHAR(150) NOT NULL,
                             building_id BIGINT REFERENCES buildings(id) ON DELETE SET NULL, -- primary building
                             created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_departments_building_id ON departments(building_id);

-- Rooms (classrooms, labs, etc.)
CREATE TABLE rooms (
                       id          BIGSERIAL PRIMARY KEY,
                       building_id BIGINT NOT NULL REFERENCES buildings(id) ON DELETE RESTRICT,
                       code        VARCHAR(50) NOT NULL,
                       name        VARCHAR(150),
                       capacity    INT NOT NULL DEFAULT 0 CHECK (capacity >= 0),
                       floor       VARCHAR(20),
                       UNIQUE (building_id, code)
);

CREATE INDEX idx_rooms_building_id ON rooms(building_id);

-- =========================
--  STUDENT / TEACHER PROFILES
-- =========================
CREATE TABLE students (
                          id              BIGSERIAL PRIMARY KEY,
                          user_id         BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
                          student_no      VARCHAR(50) NOT NULL UNIQUE,
                          department_id   BIGINT REFERENCES departments(id) ON DELETE SET NULL,
                          enrollment_year INT CHECK (enrollment_year BETWEEN 1900 AND 2100),
                          status          VARCHAR(30) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE/GRADUATED/INACTIVE
                          created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_students_department_id ON students(department_id);

CREATE TABLE teachers (
                          id            BIGSERIAL PRIMARY KEY,
                          user_id       BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
                          teacher_no    VARCHAR(50) NOT NULL UNIQUE,
                          department_id BIGINT REFERENCES departments(id) ON DELETE SET NULL,
                          title         VARCHAR(80), -- Prof/Dr/etc.
                          status        VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
                          created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_teachers_department_id ON teachers(department_id);

-- =========================
--  TERM / COURSE / SECTION
-- =========================
CREATE TABLE terms (
                       id         BIGSERIAL PRIMARY KEY,
                       year       INT NOT NULL CHECK (year BETWEEN 1900 AND 2100),
                       season     VARCHAR(20) NOT NULL, -- FALL/SPRING/SUMMER
                       starts_on  DATE,
                       ends_on    DATE,
                       created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                       UNIQUE (year, season)
);

CREATE TABLE courses (
                         id            BIGSERIAL PRIMARY KEY,
                         department_id BIGINT REFERENCES departments(id) ON DELETE SET NULL,
                         code          VARCHAR(50) NOT NULL UNIQUE,  -- e.g. CENG101
                         name          VARCHAR(200) NOT NULL,
                         credits       INT NOT NULL DEFAULT 0 CHECK (credits >= 0),
                         ects          INT NOT NULL DEFAULT 0 CHECK (ects >= 0),
                         description   TEXT,
                         is_active     BOOLEAN NOT NULL DEFAULT TRUE,
                         created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_courses_department_id ON courses(department_id);

-- prerequisites (course -> course)
CREATE TABLE course_prerequisites (
                                      course_id        BIGINT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
                                      prereq_course_id BIGINT NOT NULL REFERENCES courses(id) ON DELETE RESTRICT,
                                      PRIMARY KEY (course_id, prereq_course_id),
                                      CHECK (course_id <> prereq_course_id)
);

-- Sections (course offering in a term)
CREATE TABLE sections (
                          id           BIGSERIAL PRIMARY KEY,
                          course_id    BIGINT NOT NULL REFERENCES courses(id) ON DELETE RESTRICT,
                          term_id      BIGINT NOT NULL REFERENCES terms(id) ON DELETE RESTRICT,
                          section_no   VARCHAR(20) NOT NULL,          -- e.g. 1, A, 01
                          teacher_id   BIGINT REFERENCES teachers(id) ON DELETE SET NULL,

    -- Enrollment thresholds (min to open, max to limit)
                          min_capacity INT NOT NULL DEFAULT 0 CHECK (min_capacity >= 0),
                          capacity     INT NOT NULL DEFAULT 0 CHECK (capacity >= min_capacity),

                          status       VARCHAR(30) NOT NULL DEFAULT 'OPEN', -- OPEN/CLOSED/CANCELLED
                          created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
                          UNIQUE (course_id, term_id, section_no)
);

CREATE INDEX idx_sections_course_id   ON sections(course_id);
CREATE INDEX idx_sections_term_id     ON sections(term_id);
CREATE INDEX idx_sections_teacher_id  ON sections(teacher_id);

-- Weekly meetings (timeslot model)
-- day_of_week: 1=Mon ... 7=Sun (keep consistent in app)
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

CREATE INDEX idx_section_meetings_section_id ON section_meetings(section_id);
CREATE INDEX idx_section_meetings_room_day   ON section_meetings(room_id, day_of_week);

-- Prevent ROOM conflicts on same day (time overlap)
-- Uses timestamp range: [start_time, end_time) mapped onto a fixed date
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
--  ENROLLMENT + GRADES
-- =========================
CREATE TABLE enrollments (
                             id          BIGSERIAL PRIMARY KEY,
                             student_id  BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
                             section_id  BIGINT NOT NULL REFERENCES sections(id) ON DELETE RESTRICT,
                             status      VARCHAR(30) NOT NULL DEFAULT 'ENROLLED', -- ENROLLED/DROPPED/COMPLETED
                             enrolled_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                             dropped_at  TIMESTAMPTZ,
                             UNIQUE (student_id, section_id)
);

CREATE INDEX idx_enrollments_student_id ON enrollments(student_id);
CREATE INDEX idx_enrollments_section_id ON enrollments(section_id);

-- Grade info belongs to Enrollment (1:1)
CREATE TABLE enrollment_grades (
                                   enrollment_id     BIGINT PRIMARY KEY REFERENCES enrollments(id) ON DELETE CASCADE,
                                   midterm           NUMERIC(5,2) CHECK (midterm BETWEEN 0 AND 100),
                                   final             NUMERIC(5,2) CHECK (final BETWEEN 0 AND 100),
                                   letter            VARCHAR(5), -- AA/BA/BB/CB/CC/DC/DD/FF etc.
                                   notes             TEXT,
                                   graded_by_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
                                   graded_at         TIMESTAMPTZ
);

CREATE INDEX idx_enrollment_grades_graded_by ON enrollment_grades(graded_by_user_id);

-- =========================
--  DOCUMENTS (PDF outputs)
-- =========================
CREATE TABLE generated_documents (
                                     id                 BIGSERIAL PRIMARY KEY,
                                     student_id          BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
                                     created_by_user_id  BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
                                     doc_type            VARCHAR(50) NOT NULL, -- STUDENT_CERTIFICATE / TRANSCRIPT / ...
                                     file_path           TEXT,                 -- storage path or URL
                                     payload_json        JSONB,                -- optional metadata (filters, language, etc.)
                                     created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_generated_documents_student_id  ON generated_documents(student_id);
CREATE INDEX idx_generated_documents_created_by  ON generated_documents(created_by_user_id);

-- =========================
--  OPTIONAL: STUDENT CARD + LIBRARY (extensible core)
-- =========================
CREATE TABLE student_cards (
                               id            BIGSERIAL PRIMARY KEY,
                               student_id    BIGINT NOT NULL UNIQUE REFERENCES students(id) ON DELETE CASCADE,
                               card_no       VARCHAR(50) NOT NULL UNIQUE,
                               balance_cents BIGINT NOT NULL DEFAULT 0 CHECK (balance_cents >= 0),
                               is_active     BOOLEAN NOT NULL DEFAULT TRUE,
                               issued_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
                               expires_at    TIMESTAMPTZ
);

CREATE TABLE library_books (
                               id             BIGSERIAL PRIMARY KEY,
                               isbn           VARCHAR(20),
                               title          VARCHAR(250) NOT NULL,
                               author         VARCHAR(250),
                               publisher      VARCHAR(250),
                               published_year INT CHECK (published_year BETWEEN 1000 AND 2100),
                               created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_library_books_isbn ON library_books(isbn);

CREATE TABLE library_copies (
                                id         BIGSERIAL PRIMARY KEY,
                                book_id    BIGINT NOT NULL REFERENCES library_books(id) ON DELETE CASCADE,
                                barcode    VARCHAR(80) NOT NULL UNIQUE,
                                status     VARCHAR(30) NOT NULL DEFAULT 'AVAILABLE', -- AVAILABLE/LOANED/LOST/DAMAGED
                                created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_library_copies_book_id ON library_copies(book_id);

CREATE TABLE library_loans (
                               id          BIGSERIAL PRIMARY KEY,
                               copy_id     BIGINT NOT NULL REFERENCES library_copies(id) ON DELETE RESTRICT,
                               student_id  BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
                               loaned_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
                               due_at      TIMESTAMPTZ NOT NULL,
                               returned_at TIMESTAMPTZ,
                               status      VARCHAR(30) NOT NULL DEFAULT 'OPEN' -- OPEN/CLOSED/OVERDUE
);

CREATE INDEX idx_library_loans_copy_id    ON library_loans(copy_id);
CREATE INDEX idx_library_loans_student_id ON library_loans(student_id);
CREATE INDEX idx_library_loans_due_at     ON library_loans(due_at);

COMMIT;