defmodule HttpTackleTest do
  use ExUnit.Case
  doctest HttpTackle

  defmodule HttpTackleConsumer do
    use HttpTackle,
      http_port: 2222,
      amqp_url: "amqp://localhost",
      exchange: "test-exchange",
      routing_key: "test-key"
  end

  defmodule TestService do
    use Tackle.Consumer,
      url: "amqp://localhost",
      exchange: "test-exchange",
      routing_key: "test-key",
      service: "test-service"

    def handle_message(message) do
      File.write("/tmp/messages", message, [:write])
    end
  end

  test "sending message over HTTP" do
    HttpTackleConsumer.start_link
    TestService.start_link

    :timer.sleep(1000)

    HTTPotion.post("http://localhost:2222", body: "Hi!")

    :timer.sleep(1000)

    assert File.read!("/tmp/messages") == "Hi!"
  end
end
