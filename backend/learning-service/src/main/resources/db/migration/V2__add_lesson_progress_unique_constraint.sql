ALTER TABLE learning_schema.lesson_progress
ADD CONSTRAINT uk_lesson_progress_user_lesson
UNIQUE (user_id, lesson_id);
