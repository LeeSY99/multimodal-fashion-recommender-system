\timing on

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, title, price
FROM items
WHERE main_category = 'Shirts'
ORDER BY rating_number DESC
LIMIT 20;

EXPLAIN (ANALYZE, BUFFERS)
SELECT i.id, i.title
FROM items i
JOIN item_docs d ON d.item_id = i.id
WHERE d.doc_text LIKE '%linen%'
ORDER BY i.average_rating DESC
LIMIT 20;
