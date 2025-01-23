defmodule TpnWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as modals, tables, and
  forms. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component, global_prefixes: ~w(hx-)
  import TpnWeb.Gettext

  attr :classes, :string, default: "max-w-xl", doc: "the classes to apply to the modal"

  def form_modal(assigns) do
    ~H"""
    <dialog id="table_modal" class={"modal mx-auto #{@classes}"}>
      <div class="modal-box max-w-full">
        <form method="dialog">
          <button class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2">✕</button>
        </form>

        <div>
          <.htmx_indicator id="table_modal_indicator" />
          <div id="table_modal_contents" class="hide-on-htmx-request"></div>
        </div>
      </div>
    </dialog>
    """
  end

  attr :status, :boolean, default: false, doc: "the status of the badge"

  def empty_badge(assigns) do
    ~H"""
    <div class={[
      "badge badge-xs ml-5",
      @status && "badge-success",
      !@status && "badge-error"
    ]}>
    </div>
    """
  end

  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span class="inline-flex items-center rounded-md bg-gray-400/10 px-2 py-1 text-xs font-medium text-gray-400 ring-1 ring-inset ring-gray-400/20">
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  attr :state, :boolean, required: true
  attr :label, :string, required: true

  def simple_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset",
      @state &&
        "bg-green-50 dark:bg-green-500/10 text-green-700 dark:text-green-400 ring-green-600/20 dark:ring-green-500/20",
      !@state &&
        "bg-pink-50 dark:bg-pink-400/10 text-pink-700 dark:text-pink-400 ring-pink-700/10 dark:ring-pink-400/20"
    ]}>
      <%= @label %>
    </span>
    """
  end

  attr :url, :string, required: true
  attr :meta, :map, required: true
  attr :target, :string, default: "#data-table"
  attr :indicator, :string, default: "#data-table-indicator"

  def pagination(assigns) do
    ~H"""
    <div class="mt-5 flex justify-between">
      <%= if @meta.has_previous_page do %>
        <button
          type="button"
          hx-get={generate_paging_link(@url, @meta, "prev")}
          hx-target={@target}
          hx-indicator={@indicator}
          class="btn btn-xs"
        >
          <.icon name="hero-chevron-left" class="h-4 w-4" /> previous
        </button>
      <% else %>
        <div></div>
      <% end %>

      <%= if @meta.has_next_page do %>
        <button
          type="button"
          class="btn btn-xs"
          hx-get={generate_paging_link(@url, @meta, "next")}
          hx-target={@target}
          hx-indicator={@indicator}
        >
          next <.icon name="hero-chevron-right" class="h-4 w-4" />
        </button>
      <% end %>
    </div>
    """
  end

  attr :url, :string, required: true
  attr :target, :string, default: "#data-table"

  def search(assigns) do
    ~H"""
    <div class="relative mt-10 mx-auto max-w-7xl">
      <label class="input input-bordered input-sm flex items-center gap-2 w-72">
        <.icon name="hero-magnifying-glass" class="w-4 h-4 opacity-70" />
        <input
          hx-get={@url}
          hx-target={@target}
          hx-trigger="keyup delay:500ms changed"
          hx-indicator="#search_indicator"
          type="text"
          name="filter"
          class="h-8 input input-sm border-none focus:ring-0"
          autocomplete="off"
          placeholder="Search..."
        />
        <span id="search_indicator" class="loading loading-spinner loading-xs htmx-indicator"></span>
      </label>
    </div>
    """
  end

  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :type, :atom, values: [:info, :error, :success, :warning], doc: "the type of flash message"

  def alert(assigns) do
    ~H"""
    <div
      :if={msg = Phoenix.Flash.get(@flash, @type)}
      id="form-alert"
      role="alert"
      class={[
        "alert mb-5 p-2 rounded-md ",
        @type == :info && "alert-info",
        @type == :error && "alert-error",
        @type == :success && "alert-success",
        @type == :warning && "alert-warning"
      ]}
    >
      <.icon :if={@type == :info} name="hero-exclamation-circle" class="h-6 w-6" />
      <.icon :if={@type == :error} name="hero-x-circle" class="h-6 w-6" />
      <.icon :if={@type == :warning} name="hero-exclamation-triangle" class="h-6 w-6" />
      <.icon :if={@type == :success} name="hero-check-circle" class="h-6 w-6" />
      <span><%= msg %></span>

      <button
        hx-on:click="document.getElementById('form-alert').style.display = 'none'"
        class="btn btn-square btn-ghost btn-xs"
        type="button"
      >
        <.icon name="hero-x-mark" class="h-4 w-4" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.alert type={:info} flash={@flash} />
      <.alert type={:error} flash={@flash} />
      <.alert type={:success} flash={@flash} />
      <.alert type={:warning} flash={@flash} />
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-6">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  attr :form, :any, required: true, doc: "the form struct to render"
  attr :is_admin, :boolean, default: false, doc: "the admin status"
  attr :lhns, :list, default: [], doc: "the list of local health networks"
  attr :facilities, :list, default: [], doc: "the list of facilities"
  attr :campuses, :list, default: [], doc: "the list of campuses"
  attr :id, :string, default: "", doc: "the id of the network fields"

  def network_fields(assigns) do
    ~H"""
    <div class="grid grid-cols-2 gap-4">
      <div class="divider col-span-2 ">Networks</div>
      <.input
        hx-get="/health_networks"
        hx-target={"##{@id}_facility_id"}
        hx-on:htmx-after-on-load={"selectRemoveOptions('#{@id}_campus_id');"}
        field={@form[:local_health_network_id]}
        type="select"
        label="Local Health Network"
        prompt="Select..."
        options={@lhns}
      />

      <.input
        hx-get="/health_networks"
        hx-target={"##{@id}_campus_id"}
        field={@form[:facility_id]}
        type="select"
        label="Facility"
        prompt="Select..."
        options={@facilities}
      />

      <.input
        field={@form[:campus_id]}
        type="select"
        label="Campus"
        prompt="Select..."
        options={@campuses}
      />
    </div>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :id_2, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :label_inside_left, :string, default: nil
  attr :label_inside_right, :string, default: nil
  attr :options_label, :string, default: nil
  attr :input_type, :string, values: ~w(text number)
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :field_2, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div>
      <label for={@id} class="flex items-center gap-4 text-sm leading-6 mt-4">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="checkbox checkbox-primary bg-transparent"
          {@rest}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div>
      <label for={@id} class="form-control w-full">
        <div class="label">
          <span class="label-text">
            <%= @label %>
            <span :if={Map.has_key?(@rest, :required)} class="text-error">*</span>
          </span>
        </div>
        <select
          id={@id}
          name={@name}
          multiple={@multiple}
          class={[
            "select select-bordered w-full h-10 p-y-0 min-h-10 leading-none",
            @errors != [] && "input-error"
          ]}
          {@rest}
        >
          <option :if={@prompt} value=""><%= @prompt %></option>
          <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
        </select>
        <.error :for={msg <- @errors}><%= msg %></.error>
      </label>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <label for={@id} class="form-control w-full">
        <div class="label">
          <span class="label-text">
            <%= @label %> <span :if={Map.has_key?(@rest, :required)} class="text-error">*</span>
          </span>
        </div>
        <textarea
          id={@id}
          name={@name}
          class={[
            "input input-bordered w-full h-24",
            @errors != [] && "input-error"
          ]}
          {@rest}
        ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
        <.error :for={msg <- @errors}><%= msg %></.error>
      </label>
    </div>
    """
  end

  def input(%{type: "input-inside-label"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <label for={@id} class="form-control w-full">
        <div class="label">
          <span class="label-text">
            <%= @label %> <span :if={Map.has_key?(@rest, :required)} class="text-error">*</span>
          </span>
        </div>
        <div class="input input-bordered flex items-center gap-2 h-10 overflow-hidden">
          <span :if={@label_inside_left != nil} class="opacity-50 shrink-0">
            <%= @label_inside_left %>
          </span>
          <input
            type={@input_type}
            name={@name}
            id={@id}
            value={Phoenix.HTML.Form.normalize_value(@input_type, @value)}
            class={[
              "grow h-10 border-0 focus:ring-0 px-0",
              @errors != [] && "input-error"
            ]}
            {@rest}
          />
          <span :if={@label_inside_right != nil} class="opacity-50 shrink-0">
            <%= @label_inside_right %>
          </span>
        </div>
        <.error :for={msg <- @errors}><%= msg %></.error>
      </label>
    </div>
    """
  end

  def input(%{type: "input-with-select"} = assigns) do
    %{field_2: %Phoenix.HTML.FormField{} = field_2} = assigns

    assigns =
      assigns
      |> assign_new(:name_2, fn -> field_2.name end)
      |> assign_new(:id_2, fn -> field_2.id end)
      |> assign_new(:value_2, fn -> field_2.value end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label for={@id} class="form-control w-full">
        <div class="label">
          <span class="label-text">
            <%= @label %> <span :if={Map.has_key?(@rest, :required)} class="text-error">*</span>
          </span>
        </div>
        <div class={[
          "input input-bordered flex items-center h-10 overflow-hidden pr-0",
          @errors != [] && "input-error"
        ]}>
          <input
            type={@input_type}
            name={@name}
            id={@id}
            value={Phoenix.HTML.Form.normalize_value(@input_type, @value)}
            class="w-9/12 h-10 border-0 focus:ring-0 pl-0 pr-2 focus:outline-0"
            {@rest}
          />
          <select
            name={@name_2}
            id={@id_2}
            class="select h-10 join-item border-0 focus:ring-0 focus:outline-0 border-l border-neutral grow"
          >
            <%= Phoenix.HTML.Form.options_for_select(@options, @value_2) %>
          </select>
        </div>
        <.error :for={msg <- @errors}><%= msg %></.error>
      </label>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <label for={@id} class="form-control w-full">
        <div class="label">
          <span class="label-text">
            <%= @label %> <span :if={Map.has_key?(@rest, :required)} class="text-error">*</span>
          </span>
        </div>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            "input input-bordered w-full h-10",
            @errors != [] && "input-error"
          ]}
          {@rest}
        />
        <.error :for={msg <- @errors}><%= msg %></.error>
      </label>
    </div>
    """
  end

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :type, :string, default: "text"
  attr :value, :string, default: nil
  attr :label, :string, default: nil
  attr :errors, :list, default: []

  attr :rest, :global,
    include: ~w(accept autocomplete capture disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required size step)

  def simple_input(assigns) do
    ~H"""
    <label for={@id} class="form-control w-full">
      <div class="label">
        <span class="label-text">
          <%= @label %> <span :if={Map.has_key?(@rest, :required)} class="text-error">*</span>
        </span>
      </div>

      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "input input-bordered w-full h-10",
          @errors != [] && "input-error"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </label>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <div class="label">
      <span class="label-text-alt text-error">
        <%= render_slot(@inner_block) %>
      </span>
    </div>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-base-content">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :url, :string, required: true
  attr :meta, :map, required: true
  attr :target, :string, default: "#data-table"
  attr :indicator, :string, default: "#data-table-indicator"
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
    attr :field, :atom, required: true
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="table bg-neutral rounded-md">
        <thead>
          <tr>
            <th :for={col <- @col} class="text-left">
              <%= if Enum.member?(@meta.sortable_fields, col[:field]) do %>
                <.sortable_field
                  meta={@meta}
                  label={col[:label]}
                  field={col[:field]}
                  url={@url}
                  target={@target}
                  indicator={@indicator}
                />
              <% else %>
                <%= col[:label] %>
              <% end %>
            </th>
            <th :if={@action != []}>
              <span class="sr-only"><%= gettext("Actions") %></span>
            </th>
          </tr>
        </thead>
        <tbody>
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-base-100">
            <td
              :for={{col, _i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["", @row_click && "hover:cursor-pointer"]}
            >
              <%= render_slot(col, @row_item.(row)) %>
            </td>
            <td :if={@action != []} class="flex justify-end gap-3">
              <%= for action <- @action do %>
                <%= render_slot(action, @row_item.(row)) %>
              <% end %>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  attr :meta, :map, required: true
  attr :field, :string, required: true
  attr :url, :string, required: true
  attr :label, :string, required: true
  attr :target, :string, required: true
  attr :indicator, :string, required: true

  def sortable_field(assigns) do
    ~H"""
    <div
      hx-get={"#{@url}?table=1&page=#{@meta.current_page}&filter=#{@meta.filter}&order_by=#{@field}&order_direction=#{if @meta.order_direction == "asc", do: "desc", else: "asc"}"}
      hx-indicator={@indicator}
      hx-target={@target}
      class="flex items-center gap-1 cursor-pointer"
    >
      <span><%= @label %></span>
      <%= if(@meta.order_by == Atom.to_string(@field)) do %>
        <div class="flex flex-col items-center">
          <.icon
            name="hero-chevron-up"
            class={["w-2 h-2", @meta.order_direction == "asc" && "text-white"]}
          />
          <.icon
            name="hero-chevron-down"
            class={["w-2 h-2", @meta.order_direction == "desc" && "text-white"]}
          />
        </div>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500"><%= item.title %></dt>
          <dd class="text-zinc-700"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(TpnWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(TpnWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  attr :id, :string, default: ""

  def htmx_indicator(assigns) do
    ~H"""
    <span id={@id} class="loading loading-spinner loading-lg mx-auto mt10 block htmx-indicator " />
    """
  end

  def loader(assigns) do
    ~H"""
    <span class="loading loading-spinner loading-lg mx-auto mt10 block" />
    """
  end

  def no_records(assigns) do
    ~H"""
    <div class="text-center mt-20">
      <.icon name="hero-folder-plus" class="mx-auto h-12 w-12 text-gray-400" />
      <h3 class="mt-2 text-sm font-semibold">No Data</h3>
      <p class="mt-1 text-sm text-gray-500">Get started by creating a new.</p>
    </div>
    """
  end

  def generate_paging_link(url, meta, "next") do
    "#{url}?page=#{meta.next_page}&table=1&filter=#{meta.filter}&order_by=#{meta.order_by}&order_direction=#{meta.order_direction}"
  end

  def generate_paging_link(url, meta, "prev") do
    "#{url}?page=#{meta.previous_page}&table=1&filter=#{meta.filter}&order_by=#{meta.order_by}&order_direction=#{meta.order_direction}"
  end
end
