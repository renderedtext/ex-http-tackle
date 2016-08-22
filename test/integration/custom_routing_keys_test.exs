defmodule CustomRoutingKeysTest do
  use ExUnit.Case
  doctest HttpTackle

  defmodule HttpTackleConsumer do
    use HttpTackle,
      http_port: 8888,
      amqp_url: "amqp://localhost",
      exchange: "custom-keys-exchange",
      routing_key: "default-keys"

    def handle_message(conn, message) do
      if conn.request_path == "/special" do
        {:ok, message, "special-keys"}
      else
        {:ok, message}
      end
    end
  end

  defmodule DefaultKeysService do
    use Tackle.Consumer,
      url: "amqp://localhost",
      exchange: "custom-keys-exchange",
      routing_key: "default-keys",
      service: "default-service"

    def handle_message(message) do
      File.write("/tmp/default-messages", message, [:write])
    end
  end

  defmodule SpecialKeysService do
    use Tackle.Consumer,
      url: "amqp://localhost",
      exchange: "custom-keys-exchange",
      routing_key: "special-keys",
      service: "special-service"

    def handle_message(message) do
      File.write("/tmp/special-messages", message, [:write])
    end
  end

  setup_all do
    {:ok, _} = HttpTackleConsumer.start_link

    {:ok, default_tackle} = DefaultKeysService.start_link
    {:ok, special_tackle} = SpecialKeysService.start_link

    :timer.sleep(1000)

    :ok
  end

  setup do
    File.write("/tmp/default-messages", "No messages")
    File.write("/tmp/special-messages", "No messages")
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
