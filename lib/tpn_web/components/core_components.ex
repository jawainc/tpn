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
  use Phoenix.Component, global_prefixes: ~w(hx- x-)
  import TpnWeb.Gettext
  import TpnWeb.IconComponents

  attr :classes, :string, default: "max-w-xl", doc: "the classes to apply to the modal"

  def form_modal(assigns) do
    ~H"""
    <dialog id="table_modal" class={"modal mx-auto #{@classes}"}>
      <div class="modal-box max-w-full">
        <form method="dialog">
          <button class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2">✕</button>
        </form>

        <div>
          <.htmx_content_indicator id="table_modal_indicator" />
          <div id="table_modal_contents" class="hide-on-htmx-request"></div>
        </div>
      </div>
    </dialog>
    """
  end

  attr :status, :boolean, default: false, doc: "the status of the badge"

  def empty_badge(assigns) do
    ~H"""
    <%= if @status do %>
      <svg
        xmlns="http://www.w3.org/2000/svg"
        class="size-6 text-brand"
        fill="none"
        viewBox="0 0 24 24"
        stroke-width="1.5"
        stroke="currentColor"
        class="size-6"
      >
        <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
      </svg>
    <% else %>
      <svg
        xmlns="http://www.w3.org/2000/svg"
        class="size-6 text-destructive"
        fill="none"
        viewBox="0 0 24 24"
        stroke-width="1.5"
        stroke="currentColor"
        class="size-6"
      >
        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
      </svg>
    <% end %>
    """
  end

  attr :type, :string, required: false, default: nil
  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span class={"badge#{if @type, do: "-#{@type}", else: ""}"}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr :state, :boolean, required: true
  attr :label, :string, required: true
  attr :type, :string, required: false, default: nil

  def simple_badge(assigns) do
    ~H"""
    <span class="badge-outline flex items-center gap-1 border border-muted-foreground/30">
      <svg height="10" width="10" xmlns="http://www.w3.org/2000/svg">
        <circle r="4" cx="5" cy="5" fill={if @state, do: "green", else: "red"} />
      </svg>
      {@label}
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
          class="btn-sm-ghost"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path d="m15 18-6-6 6-6" />
          </svg>
          previous
        </button>
      <% else %>
        <div></div>
      <% end %>

      <%= if @meta.has_next_page do %>
        <button
          type="button"
          class="btn-sm-ghost"
          hx-get={generate_paging_link(@url, @meta, "next")}
          hx-target={@target}
          hx-indicator={@indicator}
        >
          next
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path d="m9 18 6-6-6-6" />
          </svg>
        </button>
      <% end %>
    </div>
    """
  end

  attr :url, :string, required: true
  attr :target, :string, default: "#data-table"

  def search(assigns) do
    ~H"""
    <div class="flex items-center gap-1 max-w-7xl">
      <div class="relative">
        <.icon_search class="size-3" />
        <input
          hx-get={@url}
          hx-target={@target}
          hx-trigger="keyup delay:500ms changed"
          hx-indicator="#search_indicator"
          type="text"
          name="filter"
          class="input pl-8 h-xs text-xs"
          autocomplete="off"
          placeholder="Search..."
        />
      </div>
      <.icon_spinner id="search_indicator" />
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
        @type == :info && "alert",
        @type == :error && "alert-destructive border-destructive",
        @type == :success && "alert text-brand border-brand-default",
        @type == :warning && "alert text-warning border-warning"
      ]}
    >
      <.icon_error :if={@type == :error} />
      <.icon_success :if={@type == :success} />
      <.icon_warning :if={@type == :warning} />
      <section>{msg}</section>
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
  attr :no_styles, :boolean, default: false, doc: "the flag to disable default styles"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class={!@no_styles && "mt-10 space-y-6"}>
        {render_slot(@inner_block, f)}
        <div
          :for={action <- @actions}
          class={!@no_styles && "mt-2 flex items-center justify-between gap-6"}
        >
          {render_slot(action, f)}
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
      {render_slot(@inner_block)}
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
        type="simple-select"
        label="Local Health Network"
        prompt="Select..."
        options={@lhns}
      />

      <.input
        hx-get="/health_networks"
        hx-target={"##{@id}_campus_id"}
        field={@form[:facility_id]}
        type="simple-select"
        label="Facility"
        prompt="Select..."
        options={@facilities}
      />

      <.input
        field={@form[:campus_id]}
        type="simple-select"
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
  attr :event_name, :string, default: nil, doc: "the event name for select elements"
  attr :event_attribute, :string, default: nil, doc: "the event attribute for select elements"

  attr :label_loader, :boolean,
    default: false,
    doc: "whether to include a label loader for select elements"

  attr :include_empty, :boolean,
    default: false,
    doc: "whether to include an empty option for select elements"

  attr :type, :string,
    default: "text",
    values:
      ~w(checkbox color date datetime-local input-inside-label input-with-select email file hidden month number password
               range radio search select simple-select tel text textarea time url week)

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
                multiple pattern placeholder readonly required rows size step hx-target hx-trigger
                hx-get hx-post hx-put hx-patch hx-delete hx-headers hx-params hx-swap hx-swap-oob hx-select
                hx-indicator)

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
    <label for={@id} class="label gap-3">
      <input type="hidden" name={@name} value="false" />
      <input
        type="checkbox"
        id={@id}
        name={@name}
        value="true"
        checked={@checked}
        class="input"
        {@rest}
      />
      {@label}
    </label>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="grid gap-3" phx-feedback-for={@name} {@rest}>
      <label for={@id} class="label flex items-center gap-2">
        <div>
          {@label} <span :if={Map.has_key?(@rest, :required)} class="text-destructive">*</span>
        </div>
        <%= if (@label_loader) do %>
          <.icon_spinner id={"select-loader-#{@id}"} class="size-3" />
        <% end %>
      </label>
      <div id={"select-container-#{@id}"} class="select">
        <button
          type="button"
          class="btn-outline justify-between font-normal w-full"
          id={"select-#{@id}-trigger"}
          aria-haspopup="listbox"
          aria-expanded="false"
          aria-controls={"select-#{@id}-listbox"}
        >
          <span class="truncate"></span>
          <.icon_chevron_down />
        </button>
        <div id={"select-#{@id}-popover"} data-popover aria-hidden="true">
          <header>
            <.icon_select_search />
            <input
              type="text"
              value=""
              placeholder="Search entries..."
              autocomplete="off"
              autocorrect="off"
              spellcheck="false"
              aria-autocomplete="list"
              role="combobox"
              aria-expanded="false"
              aria-controls={"select-#{@id}-listbox"}
              aria-labelledby={"select-#{@id}-trigger"}
            />
          </header>
          <div
            role="listbox"
            class="scrollbar overflow-y-auto max-h-64"
            id={"select-#{@id}-listbox"}
            aria-orientation="vertical"
            aria-labelledby={"select-#{@id}-trigger"}
          >
            <%= if (@include_empty) do %>
              <div role="option" disabled hidden data-value="" aria-selected="true">
                &nbsp;
              </div>
            <% end %>
            <div id={"#{@id}_options"}>
              <%= for {name, id} <- @options do %>
                <div role="option" data-value={id} aria-selected={id == @value}>
                  {name}
                </div>
              <% end %>
            </div>
          </div>
        </div>
        <input type="hidden" id={"#{@id}"} name={@name} value={@value} />
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    <%= if (@event_name) do %>
      <script>
        document.querySelector("#select-container-<%= @id %>").addEventListener("change", (event) => {
          window.triggerEvent(event.detail.value, "<%= @event_name %>");
        });
      </script>
    <% end %>
    """
  end

  def input(%{type: "simple-select"} = assigns) do
    ~H"""
    <div class="grid gap-3" phx-feedback-for={@name}>
      <label for={@id} class="label">
        {@label} <span :if={Map.has_key?(@rest, :required)} class="text-destructive">*</span>
      </label>
      <select
        id={@id}
        name={@name}
        multiple={@multiple}
        class={[
          "select w-full",
          @errors != [] && "input-error"
        ]}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <label for={@id} class="form-control w-full">
        <div class="label">
          <span class="label-text">
            {@label} <span :if={Map.has_key?(@rest, :required)} class="text-error">*</span>
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
        <.error :for={msg <- @errors}>{msg}</.error>
      </label>
    </div>
    """
  end

  def input(%{type: "input-inside-label"} = assigns) do
    ~H"""
    <div class="grid gap-3" phx-feedback-for={@name}>
      <label for={@id} class="label">
        {@label} <span :if={Map.has_key?(@rest, :required)} class="text-destructive">*</span>
      </label>
      <div class="flex items-center overflow-hidden rounded w-full relative">
        <div
          :if={@label_inside_left != nil}
          class="opacity-40 flex items-center justify-center shrink-0 border-r border-muted-foreground/50 bg-muted absolute px-2 left-0 h-full text-sm"
        >
          {@label_inside_left}
        </div>

        <input
          type={@input_type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@input_type, @value)}
          class={["input", @label_inside_right != nil && "pr-14", @label_inside_left != nil && "pl-8"]}
          {@rest}
        />
        <div
          :if={@label_inside_right != nil}
          class="opacity-40 flex items-center justify-center shrink-0 border-l border-muted-foreground/50 bg-muted absolute px-2 right-0 h-full text-sm"
        >
          {@label_inside_right}
        </div>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
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
    <div class="grid gap-3" phx-feedback-for={@name}>
      <label for={@id} class="label">
        {@label} <span :if={Map.has_key?(@rest, :required)} class="text-destructive">*</span>
      </label>
      <div class="flex items-center rounded w-full relative">
        <input
          type={@input_type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@input_type, @value)}
          class="input pr-32"
          {@rest}
        />
        <div id={"select-#{@id_2}"} class="select absolute right-0 top-[1px] w-32">
          <button
            type="button"
            class="btn-outline justify-between font-normal h-[34px] w-full border-t-0 border-b-0 rounded-l-none"
            id={"select-#{@id_2}-trigger"}
            aria-haspopup="listbox"
            aria-expanded="false"
            aria-controls={"select-#{@id_2}-listbox"}
          >
            <span class="truncate"></span>

            <.icon_chevron_down />
          </button>
          <div
            id={"select-#{@id_2}-popover"}
            data-popover
            data-side="bottom"
            data-align="end"
            aria-hidden="true"
            class="w-40"
          >
            <header>
              <.icon_select_search />
              <input
                type="text"
                value=""
                placeholder="Search ..."
                autocomplete="off"
                autocorrect="off"
                spellcheck="false"
                aria-autocomplete="list"
                role="combobox"
                aria-expanded="false"
                aria-controls={"select-#{@id}-listbox"}
                aria-labelledby={"select-#{@id}-trigger"}
              />
            </header>
            <div
              role="listbox"
              class="scrollbar overflow-y-auto max-h-64"
              id={"select-#{@id}-listbox"}
              aria-orientation="vertical"
              aria-labelledby={"select-#{@id}-trigger"}
            >
              <div role="group" aria-labelledby={"group-label-select-#{@id}-items-1"}>
                <div role="heading" id={"group-label-select-#{@id}-items-1"}>{@prompt}</div>
                <%= for {name, id} <- @options do %>
                  <div role="option" data-value={id} aria-selected={id == @value}>
                    {name}
                  </div>
                <% end %>
              </div>
            </div>
          </div>
          <input type="hidden" id={"select-#{@id_2}"} name={@name_2} value={@value_2} />
        </div>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class="grid gap-3" phx-feedback-for={@name}>
      <label for={@id} class="label">
        {@label} <span :if={Map.has_key?(@rest, :required)} class="text-destructive">*</span>
      </label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "input input-bordered w-full",
          @errors != [] && "input-error"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
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
    <div class="grid gap-3">
      <label for={@id} class="label">
        {@label} <span :if={Map.has_key?(@rest, :required)} class="text-destructive">*</span>
      </label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "input",
          @errors != [] && "input-error"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
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
      {render_slot(@inner_block)}
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <div class="text-destructive text-xs">
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a modal form new button
  """
  attr :class, :string, default: nil
  attr :hx_get, :string, required: true
  slot :inner_block, required: true

  def new_button(assigns) do
    ~H"""
    <button
      type="button"
      hx-get={@hx_get}
      hx-target="#table_modal_form_contents"
      hx-swap="innerHTML"
      hx-indicator="#table_modal_contents_indicator"
      hx-on:click="document.getElementById('table_modal_contents').showModal()"
      type="button"
      class="btn-sm btn-brand text-xs h-xs flex items-center gap-2"
    >
      <.icon_plus class="text-brand-default/70 h-4 w-4" />
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Renders a modal form new button
  """
  attr :class, :string, default: nil
  attr :hx_get, :string, required: true
  slot :inner_block, required: true

  def view_button(assigns) do
    ~H"""
    <button
      type="button"
      hx-get={@hx_get}
      hx-target="#main-contents"
      hx-swap="innerHTML"
      hx-indicator="#main-contents-indicator"
      type="button"
      class="btn-sm-outline text-xs h-xs flex items-center gap-2"
    >
      <.icon_eye />
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Renders a page form new button
  """
  attr :class, :string, default: nil
  attr :hx_get, :string, required: true
  slot :inner_block, required: true

  def page_form_new_button(assigns) do
    ~H"""
    <button
      type="button"
      hx-get={@hx_get}
      hx-target="#main-contents"
      hx-swap="innerHTML"
      hx-indicator="#main-contents-indicator"
      type="button"
      class="btn-sm btn-brand text-xs h-xs flex items-center gap-2"
    >
      <.icon_plus class="text-brand-default/70 h-4 w-4" />
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  table modal
  """
  attr :id, :string, default: "table_modal_contents"
  attr :form_id, :string, default: "table_modal_form_contents"
  attr :loader_id, :string, default: "table_modal_contents_indicator"

  def table_form_modal(assigns) do
    ~H"""
    <dialog id={@id} class="dialog w-full sm:max-w-[425px] max-h-[612px]">
      <article class="bg-dialog-background text-foreground">
        <.htmx_content_indicator id={@loader_id} />
        <div id={@form_id} class="hide-on-htmx-request"></div>
        <button
          type="button"
          aria-label="Close dialog"
          onclick="this.closest('dialog').close()"
          class="absolute top-4 right-4 opacity-50 hover:opacity-70"
        >
          <.icon_cross />
        </button>
      </article>
    </dialog>
    """
  end

  @doc """
  form modal buttons
  """
  def form_modal_buttons(assigns) do
    ~H"""
    <button type="button" class="btn-sm-outline text-xs h-xs" onclick="this.closest('dialog').close()">
      Cancel
    </button>
    <button
      id="form-button"
      type="submit"
      class="btn-sm btn-brand text-xs h-xs flex items-center gap-2"
    >
      Submit <.htmx_indicator id="form-button-indicator" />
    </button>
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
    <header class="flex flex-col gap-14">
      <div>
        <h3 class="text-xl">
          {render_slot(@inner_block)}
        </h3>
        <p :if={@subtitle != []} class="mt-2 text-sm text-muted-foreground">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex items-center justify-between">{render_slot(@actions)}</div>
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
    <div class="rounded border border-card-foreground/10">
      <table class="w-full text-sm text-foreground-light">
        <thead>
          <tr>
            <th :for={col <- @col} class="py-3 px-4 bg-card font-normal text-left">
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
                {col[:label]}
              <% end %>
            </th>
            <th :if={@action != []} class="py-3 px-4 bg-card">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody>
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
            <td
              :for={{col, _i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={[
                "py-3 px-4 border-t border-card-foreground/5 bg-card/60",
                @row_click && "hover:cursor-pointer"
              ]}
            >
              {render_slot(col, @row_item.(row))}
            </td>
            <td
              :if={@action != []}
              class="flex justify-end gap-3 py-3 px-4 border-t border-card-foreground/5 bg-card/60"
            >
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  attr :record, :any, required: true
  attr :url, :string, required: true
  attr :target, :string, default: "table_modal_form_contents"
  attr :indicator, :string, default: "table_modal_contents_indicator"
  attr :model_id, :string, default: "table_modal_contents"
  attr :is_admin, :boolean, default: false, doc: "the admin status"
  attr :can_update, :boolean, default: false, doc: "the update permission"
  attr :can_delete, :boolean, default: false, doc: "the delete permission"
  attr :edit_popup, :boolean, default: true

  def table_actions_edit_delete(assigns) do
    ~H"""
    <div class="dropdown-menu text-xs">
      <button
        type="button"
        aria-haspopup="menu"
        aria-controls="demo-dropdown-menu-menu"
        aria-expanded="false"
        class="btn-sm-icon-outline"
      >
        <.icon_v_ellipsis />
      </button>
      <div
        data-popover
        data-align="end"
        aria-hidden="true"
        class="w-32 border border-card-foreground/10 rounded"
      >
        <div role="menu" aria-labelledby="demo-dropdown-menu-trigger">
          <div
            :if={@is_admin || @can_update}
            hx-get={"#{@url}/#{@record.id}/edit"}
            hx-target={
              if(!@edit_popup) do
                "#main-contents"
              else
                "##{@target}"
              end
            }
            hx-indicator={
              if(!@edit_popup) do
                "#main-contents-indicator"
              else
                "##{@indicator}"
              end
            }
            hx-on:click={
              if(!@edit_popup) do
                "return;"
              else
                "document.getElementById('#{@model_id}').showModal()"
              end
            }
            role="menuitem"
            class="flex items-center gap-3"
          >
            <.icon_square_pen /> Edit
          </div>
          <div
            :if={@is_admin || @can_delete}
            hx-delete={"#{@url}/#{@record.id}"}
            hx-confirm="Are you sure to delete?"
            role="menuitem"
            class="flex items-center gap-3"
          >
            <.icon_trash />
            <span>Delete</span>
          </div>
        </div>
      </div>
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
      <span>{@label}</span>
      <%= if(@meta.order_by == Atom.to_string(@field)) do %>
        <div class="flex flex-col items-center">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class={["w-2 h-2", @meta.order_direction == "asc" && "text-white"]}
            fill="none"
            viewBox="0 0 24 24"
            stroke-width="1.5"
            stroke="currentColor"
            class="size-6"
          >
            <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 15.75 7.5-7.5 7.5 7.5" />
          </svg>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class={["w-2 h-2", @meta.order_direction == "desc" && "text-white"]}
            fill="none"
            viewBox="0 0 24 24"
            stroke-width="1.5"
            stroke="currentColor"
            class="size-6"
          >
            <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
          </svg>
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
          <dt class="w-1/4 flex-none text-zinc-500">{item.title}</dt>
          <dd class="text-zinc-700">{render_slot(item)}</dd>
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
    <svg
      id="form-button-indicator"
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class="animate-spin htmx-indicator"
    >
      <path d="M12 2v4" /><path d="m16.2 7.8 2.9-2.9" /><path d="M18 12h4" /><path d="m16.2 16.2 2.9 2.9" /><path d="M12 18v4" /><path d="m4.9 19.1 2.9-2.9" /><path d="M2 12h4" /><path d="m4.9 4.9 2.9 2.9" />
    </svg>
    """
  end

  attr :id, :string, default: ""

  def htmx_content_indicator(assigns) do
    ~H"""
    <div id={@id} class="w-full htmx-indicator py-24">
      <div class="flex mx-auto w-[200px] items-center gap-4">
        <div class="bg-accent animate-pulse size-10 shrink-0 rounded-full"></div>
        <div class="grid gap-2">
          <div class="bg-accent animate-pulse rounded-md h-4 w-[150px]"></div>
          <div class="bg-accent animate-pulse rounded-md h-4 w-[100px]"></div>
        </div>
      </div>
    </div>
    """
  end

  attr :class, :string, default: ""
  attr :id, :string, default: ""

  def loader(assigns) do
    ~H"""
    <svg
      id={@id}
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class={[@class, "animate-spin htmx-indicator "]}
    >
      <path d="M12 2v4" /><path d="m16.2 7.8 2.9-2.9" /><path d="M18 12h4" /><path d="m16.2 16.2 2.9 2.9" /><path d="M12 18v4" /><path d="m4.9 19.1 2.9-2.9" /><path d="M2 12h4" /><path d="m4.9 4.9 2.9 2.9" />
    </svg>
    """
  end

  def no_records(assigns) do
    ~H"""
    <div class="text-center my-24">
      <h3 class="mt-2 text-sm font-semibold">No Data</h3>
      <p class="mt-1 text-sm text-muted-foreground">Get started by creating a new.</p>
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
