FROM elixir:slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    	git \
    	ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY mix.exs ./
RUN mix deps.get

COPY . .
RUN mix escript.build

EXPOSE 4221

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
