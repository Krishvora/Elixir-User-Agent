defmodule WebServer do

  def local_server do
    {:ok, lsock} = :gen_tcp.listen(3000, [:binary, {:packet, 0}, {:active, false}])
    confirm_conn(lsock)
  end

  def confirm_conn(lsock) do
    {:ok, sock} = :gen_tcp.accept(lsock)
    case route_req(sock) do
      :closed ->
        confirm_conn(lsock)
      request ->
        IO.puts inspect request
        msg = case get_user_agent(request) do
          nil -> "You don't have a user-agent!"
          ua -> "Your User-Agent is: #{ua}"
        end
        :gen_tcp.send(sock, :erlang.bitstring_to_list("HTTP/1.1 200 OK\r\n\r\n" <> msg <> "\r\n"))
        :gen_tcp.close(sock) # no keep-alive for you!
        confirm_conn(lsock)
    end
  end

  def route_req(sock, request \\ '') do
    case :gen_tcp.recv(sock, 0) do
      {:ok, b} ->
        if Regex.match?(~r/\r\n\r\n/, b) do
          :erlang.list_to_bitstring([request, b])
        else
          route_req(sock, [request, b])
        end
      _ ->
        :closed
    end
  end

  def get_user_agent(request) do
    case Regex.run(~r/User-Agent: (.*)\r\n/, request) do
      nil -> nil
      [_, ua] -> ua
    end
  end
end

spawn_link(WebServer, :local_server, [])