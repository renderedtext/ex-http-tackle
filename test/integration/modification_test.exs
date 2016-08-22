defmodule ModificationTest do
  use ExUnit.Case
  doctest HttpTackle

  defmodule HttpTackleConsumer do
    use HttpTackle,
      http_port: 7777,
      amqp_url: "amqp://localhost",
      exchange: "test-exchange",
      routing_key: "test-key"

    def handle_message(_conn, message) do
      {:ok, "#{message} and some modifications"}
    end
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

  setup_all do
    HttpTackleConsumer.start_link
    TestService.start_link

    :timer.sleep(1000)

    :ok
  end

  setup do
    File.write("/tmp/messages", "No messages")
    :ok
  end

  test "appends a string to the incomming message" do
    HTTPotion.post("http://localhost:7777", body: "Hi")

    :timer.sleep(1000)

    assert File.read!("/tmp/messages") == "Hi and some modifications"
  end
end
