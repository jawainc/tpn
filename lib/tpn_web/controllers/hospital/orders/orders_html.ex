defmodule TpnWeb.Hospital.OrdersHTML do
  use TpnWeb, :html

  import TpnWeb.Orders.OrderComponents

  @url "/patients/orders"
  embed_templates "orders_html/*"
end
