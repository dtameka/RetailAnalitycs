#/bin/bash
sed -i 's/iso, mdy/sql, dmy/' /var/lib/postgresql/data/postgresql.conf
