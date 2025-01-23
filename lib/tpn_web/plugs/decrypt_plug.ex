defmodule TpnWeb.Plugs.DecryptPlug do
  import Plug.Conn

  alias TpnWeb.Helpers.Encrypt

  def init(options), do: options

  def call(conn, _opts) do
    if conn.method in ["POST", "PUT"] do
      key = conn |> get_session(:encryption_key)
      iv = conn |> get_req_header("hx-key") |> List.first()

      if key && iv do
        %{"data" => data} = conn.params
        decrypted_data = decrypt_data(data, key, iv)

        params =
          decrypted_data
          |> Plug.Conn.Query.decode()
          |> add_id(conn.params)

        %{conn | params: params}
      else
        conn
      end
    else
      conn
    end
  end

  defp decrypt_data(encrypted_data, key, iv) do
    key = Base.decode64!(key)
    iv = Base.decode64!(iv)
    encrypted_data = Base.decode64!(encrypted_data)

    {:ok, decrypted_data} = Encrypt.decrypt(encrypted_data, key, iv)
    decrypted_data
  end

  defp add_id(params, conn_params) do
    if Map.has_key?(conn_params, "id") do
      Map.put(params, "id", conn_params["id"])
    else
      params
    end
  end
end
