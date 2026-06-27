-- 1. Bổ sung cột lưu phiên bản câu hỏi (cho phép NULL)
ALTER TABLE review_schema.review_items
ADD COLUMN IF NOT EXISTS question_version_id character varying(50);

-- 2. Backfill dữ liệu learning_item_id bị null bằng mã định danh duy nhất legacy
UPDATE review_schema.review_items
SET learning_item_id = 'legacy-' || review_item_id
WHERE learning_item_id IS NULL;

-- 3. Đảm bảo toàn bộ các cột trong unique key đều NOT NULL
ALTER TABLE review_schema.review_items ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE review_schema.review_items ALTER COLUMN course_id SET NOT NULL;
ALTER TABLE review_schema.review_items ALTER COLUMN learning_item_id SET NOT NULL;
ALTER TABLE review_schema.review_items ALTER COLUMN type SET NOT NULL;

-- 4. Dọn dẹp bản ghi trùng lặp, giữ lại bản ghi có tiến trình ôn tập tốt nhất
WITH ranked AS (
    SELECT
        review_item_id,
        ROW_NUMBER() OVER (
            PARTITION BY user_id, course_id, learning_item_id, type
            ORDER BY
                last_reviewed_at DESC NULLS LAST,
                repetition_count DESC NULLS LAST,
                interval_days DESC NULLS LAST,
                next_review_at DESC NULLS LAST,
                review_item_id DESC
        ) AS rn
    FROM review_schema.review_items
)
DELETE FROM review_schema.review_items ri
USING ranked r
WHERE ri.review_item_id = r.review_item_id
  AND r.rn > 1;

-- 5. Thêm ràng buộc duy nhất (Unique Constraint)
ALTER TABLE review_schema.review_items
ADD CONSTRAINT uk_review_items_user_course_item_type
UNIQUE (user_id, course_id, learning_item_id, type);
