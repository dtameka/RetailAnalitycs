FROM postgres:15
ENV POSTGRES_DB=dtdb
RUN apt update && apt install -y apt-utils \
                                postgresql-plperl-15 \
                                libemail-valid-perl \
                                nano \
    && apt autoclean -y && apt autoremove -y

# Copy initialization scripts
COPY src/part_1/part1.sql /docker-entrypoint-initdb.d/
COPY src/part_2/part2_1.sql /docker-entrypoint-initdb.d/
COPY src/part_2/part2_2.sql /docker-entrypoint-initdb.d/
COPY src/part_2/part2_3.sql /docker-entrypoint-initdb.d/
COPY src/part_2/part2_4.sql /docker-entrypoint-initdb.d/
COPY src/part_3/part3.sql /docker-entrypoint-initdb.d/
COPY src/part_4/part4.sql /docker-entrypoint-initdb.d/
COPY src/part_5/part5.sql /docker-entrypoint-initdb.d/
COPY src/part_6/part6.sql /docker-entrypoint-initdb.d/
COPY /datasets /docker-entrypoint-initdb.d/datasets
COPY src/zInit_data.sql /docker-entrypoint-initdb.d/


# Change file permissions
RUN chmod +x /docker-entrypoint-initdb.d/part1.sql && \
chmod +x /docker-entrypoint-initdb.d/part2_1.sql && \
chmod +x /docker-entrypoint-initdb.d/part2_2.sql && \
chmod +x /docker-entrypoint-initdb.d/part2_3.sql && \
chmod +x /docker-entrypoint-initdb.d/part2_4.sql && \
chmod +x /docker-entrypoint-initdb.d/part3.sql && \
chmod +x /docker-entrypoint-initdb.d/part4.sql && \
chmod +x /docker-entrypoint-initdb.d/part5.sql && \
chmod +x /docker-entrypoint-initdb.d/part6.sql && \
chmod +x /docker-entrypoint-initdb.d/zInit_data.sql

EXPOSE 5432

# sudo docker build -t my_postgres_image .

# sudo docker run --rm --name my_postgres -p 5431:5432 -v "$(pwd)":/var/lib/postgresql/data -e POSTGRES_PASSWORD=postgres my_postgres_image

# sudo docker run --rm --name my_postgres -p 5431:5432 -e POSTGRES_PASSWORD=postgres my_postgres_image













#some debug things
#****************************************************************

# sudo docker build -t my_postgres_image .

# sudo docker run --name my_postgres -p 5429:5432 \
# --mount type=bind,source=/home/alex/projects/sql/project_02,\
# target=/docker-entrypoint-initdb.d -e POSTGRES_PASSWORD=postgres my_postgres_image

# sudo docker run --name my_postgres -p 5431:5432 -e POSTGRES_PASSWORD=postgres my_postgres_image

# sudo docker run --rm --name my_postgres -p 5431:5432 -e POSTGRES_PASSWORD=postgres my_postgres_image

# sudo docker exec -it my_postgres psql -U postgres -d dtdb

# sudo docker exec -it my_postgres /bin/bash -c "su - postgres" 
