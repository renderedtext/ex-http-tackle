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
    HttpTackleConsumer.start_link
    TestService.start_link

    :timer.sleep(1000)

    on_exit fn ->
      :timer.sleep(3000) # wait for unix ports to be free again
    end

    :ok
  end

  setup do
    File.write("/tmp/messages", "No messages")

    :ok
  end

  test "rejects messages that doesn't contain the 'tackle' substring" do
    HTTPoison.post("http://localhost:8888", "Hi!")

    :timer.sleep(1000)

    assert File.read!("/tmp/messages") == "No messages"
  end

  test "accepts messages that contain the 'tackle' substring" do
    HTTPoison.post("http://localhost:8888", "Hi tackle!")

    :timer.sleep(1000)

    assert File.read!("/tmp/messages") == "Hi tackle!"
  end
end
