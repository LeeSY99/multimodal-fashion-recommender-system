INSERT INTO items (
    parent_asin,
    main_category,
    title,
    average_rating,
    rating_number,
    price,
    store,
    date_first_available,
    image_main_url
)
SELECT
    'ASIN-' || gs::text,
    (ARRAY['Shirts','Pants','Shoes','Outerwear'])[1 + (random()*3)::int],
    'fashion item ' || gs::text || ' linen cotton casual',
    round((2 + random()*3)::numeric, 2),
    (random()*5000)::int,
    round((10 + random()*190)::numeric, 2),
    (ARRAY['StoreA','StoreB','StoreC'])[1 + (random()*2)::int],
    DATE '2018-01-01' + ((random()*2500)::int),
    'https://cdn.example.com/' || gs::text || '.jpg'
FROM generate_series(1, 200000) AS gs;

INSERT INTO item_docs (item_id, doc_text)
SELECT
    id,
    lower(main_category || ' ' || title || ' ' || store)
FROM items;

ANALYZE;
