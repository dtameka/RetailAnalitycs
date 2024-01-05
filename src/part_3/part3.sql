create user administrator superuser password 'administrator';

CREATE user Visitor password 'visitor';
GRANT SELECT ON ALL TABLES IN SCHEMA PUBLIC TO Visitor;