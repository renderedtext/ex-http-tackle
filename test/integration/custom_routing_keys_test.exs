defmodule CustomRoutingKeysTest do
  use ExUnit.Case
  doctest HttpTackle

  defmodule HttpTackleConsumer do
    use HttpTackle,
      http_port: 8888,
      amqp_url: "amqp://localhost",
      exchange: "test-exchange",
      routing_key: "default-keys"

    def handle_message(conn, message) do
      if conn.request_path == "/special"
        {:ok, message, "special-key"}
      else
        {:ok, message}
      end
    end
  end

  defmodule DefaultKeysService do
    use Tackle.Consumer,
      url: "amqp://localhost",
      exchange: "test-exchange",
      routing_key: "default-keys",
      service: "test-service"

    def handle_message(message) do
      File.write("/tmp/default-messages", message, [:write])
    end
  end

  defmodule SpecialKeysService do
    use Tackle.Consumer,
      url: "amqp://localhost",
      exchange: "test-exchange",
      routing_key: "special-keys",
      service: "test-service"

    def handle_message(message) do
      File.write("/tmp/special-messages", message, [:write])
    end
  end

  setup do
    {:ok, _} = HttpTackleConsumer.start_link

    {:ok, _} = DefaultKeysService.start_link
    {:ok, _} = SpecialKeysService.start_link

    File.write("/tmp/default-messages", "No messages")
    File.write("/tmp/special-messages", "No messages")

    :timer.sleep(1000)

    :ok
  end

  test "publishes message with 'special-key' when the payload comes to '/special'" do
    HTTPotion.post("http://localhost:8888/special", body: "Hi!")

    :timer.sleep(1000)

    assert File.read!("/tmp/default-messages") == "No messages"
    assert File.read!("/tmp/special-messages") == "Hi!"
  end

  test "publishes message with 'default-key' any other path" do
    HTTPotion.post("http://localhost:8888/something", body: "Hi!")

    :timer.sleep(1000)

    assert File.read!("/tmp/default-messages") == "Hi!"
    assert File.read!("/tmp/special-messages") == "No messages"
  end

end
