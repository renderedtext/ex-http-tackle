defmodule HttpTackleTest do
  use ExUnit.Case
  doctest HttpTackle

  defmodule HttpTackleConsumer do
    use HttpTackle,
      http_port: 8888,
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
      File.write("/tmp/messages", message, [:append])
    end
  end

  setup do
    HttpTackleConsumer.start_link
    TestService.start_link

    :timer.sleep(1000)

    on_exit fn ->
      :timer.sleep(3000) # wait for unix ports to be free again
    end
  end

  test "sending a high number of requests in a short burst" do
    File.write("/tmp/messages", "", [:write])

    (1..100) |> Enum.each(fn(index) ->
      IO.puts "Sending request #{index}"
      HTTPoison.post("http://localhost:8888", "##{index}")
    end)

    :timer.sleep(3000)

    expected_result = (1..100) |> Enum.map(fn(index) -> "##{index}" end) |> Enum.join

    assert File.read!("/tmp/messages") == expected_result
  end
end
