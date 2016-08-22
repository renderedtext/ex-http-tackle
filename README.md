# HTTP Tackle

Receives tackle messages over HTTP and publishes them on an exchange.

## Installation

``` elixir
def deps do
  [
    {:http_tackle, github: "renderedtext/ex-http-tackle"}
  ]
end
```

Also, add it to the list of your applications:

``` elixir
def application do
  [applications: [:http_tackle]]
end
```

## Usage

First, define a HTTP tackle consumer:

``` elixir
defmodule TestConsumer do
  use HttpTackle,
    http_port: 80,
    amqp_url: "amqp://localhost",
    exchange: "test-exchange",
    routing_key: "test-key"
end
```

The above module will receive `POST` HTTP messages, and publish them on the
`test-exchange` with the routing key `test-key`.

## Handling incoming messages

Optionally, you can add a `handle_message` method to your module. This is useful
if you want to:

1. Modify incoming messages
2. Filter incoming messages
3. Measure incoming messages
4. Define custom routing keys

### Modifying incoming messages

In the next example we will add a `Hi!` string to our incoming messages:

``` elixir
defmodule TestConsumer do
  use HttpTackle,
    http_port: 80,
    amqp_url: "amqp://localhost",
    exchange: "test-exchange",
    routing_key: "test-key"

  def handle_message(_conn, payload) do
    new_payload = "#{payload} Hi!"

    {:ok, new_payload}
  end
end
```

The above module will receive the message, add a `Hi!` message to it, and
then publish it on the `test-exchange`.

### Filtering incoming messages

In the next example we reject all messages that contain the `test` substring.

``` elixir
defmodule TestConsumer do
  use HttpTackle,
    http_port: 80,
    amqp_url: "amqp://localhost",
    exchange: "test-exchange",
    routing_key: "test-key"

  def handle_message(_conn, payload) do
    if payload =~ ~r/test/ do
      {:error, "Messages with 'test' substring are rejected"}
    else
      {:ok, payload}
    end
  end
end
```

### Measuring incoming messages

In the next example we will measure the size of the incoming messages and log in
to the console.

``` elixir
defmodule TestConsumer do
  require Logger

  use HttpTackle,
    http_port: 80,
    amqp_url: "amqp://localhost",
    exchange: "test-exchange",
    routing_key: "test-key"

  def handle_message(_conn, payload) do
    size = length(payload)

    Logger.info "Message size is: #{size} bytes"

    {:ok, payload}
  end
end
```

### Defining custom routing keys

In the next example, we will choose a routing key based on the path of the
incoming message:

``` elixir
defmodule TestConsumer do
  require Logger

  use HttpTackle,
    http_port: 80,
    amqp_url: "amqp://localhost",
    exchange: "test-exchange",
    routing_key: "default-key"

  def handle_message(conn, payload) do
    if conn.request_path == "/testing" do
      {:ok, payload, "testing"}
    else
      {:ok, payload} # use default routing key
    end
  end
end
```
