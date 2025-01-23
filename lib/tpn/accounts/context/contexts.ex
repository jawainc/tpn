defmodule Tpn.Accounts.Context.Contexts do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.Helpers.PaginationHelper
  alias Tpn.Accounts.Context.Context

  def list_contexts(params \\ %{}) do
    contexts =
      from(a in Context)
      |> PaginationHelper.build_query_params(Context, params)
      |> Tpn.Repo.all()

    meta =
      from(a in Context)
      |> PaginationHelper.get_paging_meta(params, Context)

    {:ok, {contexts, meta}}
  end

  def get_context!(id), do: Repo.get!(Context, id)

  def create_context(attrs \\ %{}) do
    %Context{}
    |> Context.changeset(attrs)
    |> Repo.insert()
  end

  def update_context(%Context{} = context, attrs) do
    context
    |> Context.changeset(attrs)
    |> Repo.update()
  end

  def delete_context(%Context{} = context) do
    Repo.delete(context)
  end

  def change_context(%Context{} = context, attrs \\ %{}) do
    Context.changeset(context, attrs)
  end
end
