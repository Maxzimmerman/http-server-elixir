FROM elixir:slim

RUN apt-get update && \
    apt-get install -y --no--install-recommends \
    	git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY mix.exs ./
RUN mix deps.get

COPY . .

CMD ["bin/app", "start"]
