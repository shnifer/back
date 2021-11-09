FROM tarantool/tarantool

COPY . /code

COPY ./docker-entrypoint.sh /usr/local/bin

CMD ["tarantool", "init.lua"]