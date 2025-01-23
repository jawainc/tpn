defmodule TpnWeb.Helpers.ClientEvents do
  def generate_client_event(event, status \\ "", message \\ "") do
    Jason.encode!(%{"clientObey" => %{"event" => event, "status" => status, "message" => message}})
  end

  def generate_x_key_event(rest_headers, key, iv) do
    case Enum.empty?(rest_headers) do
      true ->
        Jason.encode!(%{"xKey" => %{"vek" => key, "vec" => iv}})

      false ->
        {:ok, rest} = Jason.decode(rest_headers)
        new_headers = Map.put(rest, "xKey", %{"vek" => key, "vec" => iv})
        Jason.encode!(new_headers)
    end
  end
end
