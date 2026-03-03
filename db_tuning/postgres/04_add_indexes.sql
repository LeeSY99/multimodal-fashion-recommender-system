CREATE INDEX IF NOT EXISTS idx_items_category_rating
    ON items (main_category, rating_number DESC);

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_item_docs_trgm
    ON item_docs USING gin (doc_text gin_trgm_ops);

ANALYZE;
