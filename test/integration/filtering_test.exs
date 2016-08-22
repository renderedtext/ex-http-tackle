defmodule FilteringTest do
  use ExUnit.Case, async: false
  doctest HttpTackle

  defmodule HttpTackleConsumer do
    use HttpTackle,
      http_port: 8888,
      amqp_url: "amqp://localhost",
      exchange: "test-exchange",
      routing_key: "test-key"

    def handle_message(_conn, message) do
      if String.contains?(message, "tackle") do
        {:ok, message}
      else
        {:error, "Message doesn't contains 'tacke'"}
      end
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
    {:ok, http_tackle_consumer} = HttpTackleConsumer.start_link
    {:ok, service} = TestService.start_link

    :timer.sleep(1000)

    :ok
  end

  setup do
    File.write("/tmp/messages", "No messages")

    :ok
  end

  test "rejects messages that doesn't contain the 'tackle' substring" do
    HTTPotion.post("http://localhost:8888", body: "Hi!")

    :timer.sleep(1000)

    assert File.read!("/tmp/messages") == "No messages"
  end

  test "accepts messages that contain the 'tackle' substring" do
    HTTPotion.post("http://localhost:8888", body: "Hi tackle!")

    :timer.sleep(1000)

    assert File.read!("/tmp/messages") == "Hi tackle!"
  end
end
