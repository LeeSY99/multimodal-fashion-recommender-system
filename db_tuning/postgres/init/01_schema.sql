CREATE TABLE IF NOT EXISTS items (
    id BIGSERIAL PRIMARY KEY,
    parent_asin TEXT,
    main_category TEXT,
    title TEXT,
    average_rating NUMERIC(3,2),
    rating_number INT,
    price NUMERIC(10,2),
    store TEXT,
    date_first_available DATE,
    image_main_url TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS item_docs (
    item_id BIGINT PRIMARY KEY REFERENCES items(id),
    doc_text TEXT NOT NULL
);
