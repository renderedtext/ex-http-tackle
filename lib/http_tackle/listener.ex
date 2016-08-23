defmodule HttpTackle.Listener do
  import Plug.Conn
  require Logger

  def init(options) do
    options
  end

  def call(conn = %{method: "POST"}, options) do
    {:ok, raw_body, _} = Plug.Conn.read_body(conn)

    callback_module = Keyword.get(options, :module)

    case apply(callback_module, :handle_message, [conn, raw_body]) do
      {:ok, message, routing_key} ->
        publish(message, Keyword.put(options, :routing_key, routing_key))
        send_resp(conn, 202, "")
      {:ok, message} ->
        publish(message, options)
        send_resp(conn, 202, "")
      {:error, reason} ->
        send_resp(conn, 400, reason)
    end
  end

  def call(conn, _) do
    send_resp(conn, 403, "Rejected")
  end

  def publish(message, options) do
    tackle_options = %{
      url: Keyword.get(options, :url),
      exchange: Keyword.get(options, :exchange),
      routing_key: Keyword.get(options, :routing_key)
    }

    Logger.info "Publishing message with routing_key: '#{Keyword.get(options, :routing_key)}'"

    Tackle.publish(message, tackle_options)
  end
end
