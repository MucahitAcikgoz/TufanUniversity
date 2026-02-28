BEGIN;

-- Roles (idempotent)
INSERT INTO roles (code, name) VALUES
                                   ('STUDENT',   'Student'),
                                   ('TEACHER',   'Teacher'),
                                   ('ADMIN',     'Admin'),
                                   ('SECRETARY', 'Secretary')
    ON CONFLICT (code) DO NOTHING;

-- Users (password placeholders)
INSERT INTO users (email, password_hash, first_name, last_name, is_active)
VALUES
    ('admin@tufanuni.local',     'CHANGE_ME_HASH', 'System', 'Admin', TRUE),
    ('secretary@tufanuni.local', 'CHANGE_ME_HASH', 'Office', 'Secretary', TRUE),
    ('teacher@tufanuni.local',   'CHANGE_ME_HASH', 'Default', 'Teacher', TRUE),
    ('student@tufanuni.local',   'CHANGE_ME_HASH', 'Default', 'Student', TRUE)
    ON CONFLICT (email) DO NOTHING;

-- Assign roles
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u JOIN roles r ON r.code = 'ADMIN'
WHERE u.email = 'admin@tufanuni.local'
    ON CONFLICT DO NOTHING;

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u JOIN roles r ON r.code = 'SECRETARY'
WHERE u.email = 'secretary@tufanuni.local'
    ON CONFLICT DO NOTHING;

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u JOIN roles r ON r.code = 'TEACHER'
WHERE u.email = 'teacher@tufanuni.local'
    ON CONFLICT DO NOTHING;

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u JOIN roles r ON r.code = 'STUDENT'
WHERE u.email = 'student@tufanuni.local'
    ON CONFLICT DO NOTHING;

COMMIT;