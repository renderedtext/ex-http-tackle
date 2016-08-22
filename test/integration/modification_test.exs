defmodule ModificationTest do
  use ExUnit.Case
  doctest HttpTackle

  defmodule HttpTackleConsumer do
    use HttpTackle,
      http_port: 8888,
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

  setup do
    {:ok, _} = HttpTackleConsumer.start_link
    {:ok, _} = TestService.start_link

    File.write("/tmp/messages", "No messages")

    :timer.sleep(1000)

    :ok
  end

  test "appends a string to the incomming message" do
    HTTPotion.post("http://localhost:8888", body: "Hi")

    :timer.sleep(1000)

    assert File.read!("/tmp/messages") == "Hi and some modifications"
  end
end
