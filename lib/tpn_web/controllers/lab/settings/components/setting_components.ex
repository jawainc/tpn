defmodule TpnWeb.Settings.Components.SettingComponents do
  @moduledoc """
  module for defining components for the settings page
  """
  alias Plug.Parsers.JSON
  use Phoenix.Component
  import TpnWeb.CoreComponents

  @doc """
  defines the currencies dropdown selecter
  """
  attr :currencies, :list, required: true
  attr :selected, :string, required: true

  def currencies(assigns) do
    ~H"""
    <div
      class="mx-auto max-w-7xl"
      x-data={"{
              currencies: [],
              all_currencies: [#{@currencies |> Enum.map(fn currency -> "{country: '#{currency["country"]}', code: '#{currency["code"]}', symbol: '#{currency["symbol"]}', flag: '#{currency["flag"]}'}" end) |> Enum.join(",")}],
              selected_currency_record: '#{@selected}',
              selected_currency: this.selected_currency_record ? JSON.stringify(this.selected_currency_record) : {},
              open_currencies: false,
              currency_label: function() {
                if (!Object.keys(this.selected_currency).length > 0) {
                  return 'Choose a currency';
                }

                const img = '<img src=\"data:image/png;base64, ' + this.selected_currency.flag + '\" class=\"h-4 shrink-0 mr-2\" />';
                return img + this.selected_currency.country +
                (this.selected_currency.code ? ' - ' + this.selected_currency.code : '') +
                (this.selected_currency.symbol !== 'false' ? ' <span class=\"opacity-70 ml-2\">(' + this.selected_currency.symbol + ')</span' : '');
              },
              reset_search() {
                if (!this.open_currencies) {
                  this.currencies = this.all_currencies;
                  $refs.search.value = '';
                }
              },
              set_input_currency() {
                $refs['currency-input'].value = Object.keys(this.selected_currency).length ? JSON.stringify(this.selected_currency) : '';
              },
              set_currencies() {
                this.currencies = this.all_currencies;
              }
            }"}
      x-init="set_currencies();
              selected_currency = selected_currency_record ? JSON.parse(selected_currency_record) : {},
              set_input_currency();
              $watch('selected_currency', () => set_input_currency(), {deep: true});
      "
    >
      <label for="combobox" class="label">Currency</label>
      <div class="relative mt-2">
        <input type="hidden" x-ref="currency-input" name="currency" value="" />
        <div
          @click="open_currencies = !open_currencies; reset_search();"
          tabindex="0"
          class="flex items-center justify-between w-[30rem] h-10 px-2 border border-neutral rounded-md cursor-pointer"
        >
          <div class="flex items-center ml-3 truncate" x-html="currency_label()"></div>
          <.icon name="hero-chevron-up-down" class="w-4 h-4 opacity-80" />
        </div>
        <div
          x-cloak
          @click.outside="open_currencies = false; reset_search();"
          x-show="open_currencies"
          class="absolute z-10 bg-base-100 rounded-md border border-neutral w-[30rem] p-2 mt-2 shadow-md flex flex-col gap-3 divide-y divide-neutral"
        >
          <div class="input input-bordered input-sm flex items-center gap-1 w-full">
            <.icon name="hero-magnifying-glass" class="w-4 h-4 opacity-70" />
            <input
              x-ref="search"
              type="search"
              autocomplete="off"
              placeholder=""
              class="h-8 input input-sm w-full border-none focus:ring-0"
              @input="(evt) => {
              if (!evt.target.value || evt.target.value === '') {
                currencies = all_currencies;
                return;
              }
              const query = evt.target.value.toLowerCase();
              currencies = currencies.filter((currency) => {
                return currency.country.toLowerCase().includes(query) || currency.code.toLowerCase().includes(query);
              });
            }"
            />
          </div>
          <ul
            class="max-h-56 w-full overflow-auto focus:outline-none sm:text-sm"
            id="options"
            role="listbox"
          >
            <template x-for="(currency, index) in currencies" x-bind:key="currency.code + index">
              <li
                class="relative cursor-default select-none py-2 hover:bg-neutral px-2 rounded-md mt-1"
                @click="selected_currency = currency; open_currencies = false; reset_search();"
              >
                <div class="flex items-center">
                  <img
                    x-bind:src="`data:image/png;base64, ${currency.flag}`"
                    class="h-4 shrink-0"
                    alt=""
                  />
                  <span class="ml-3 truncate" x-text="currency.country"></span>
                  <template x-if="currency.code !== ''">
                    <span x-text="`- ${currency.code}`" class="ml-1" />
                  </template>
                  <template x-if="currency.symbol !== 'false'">
                    <span class="ml-1 opacity-50" x-text="`(${currency.symbol})`" />
                  </template>
                </div>
              </li>
            </template>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  defines the unit types dropdown selecter
  """
  attr :name, :string, required: true
  attr :label, :string, required: true
  attr :options, :list, required: true
  attr :value, :string, default: nil

  def setting_select(assigns) do
    ~H"""
    <div>
      <label for={@name} class="form-control w-full max-w-xs">
        <div class="label">
          <span class="label-text">
            <%= @label %>
          </span>
        </div>
        <select
          id={@name}
          name={@name}
          class="select select-bordered w-full max-w-xs h-10 p-y-0 min-h-10 leading-none"
        >
          <option value=""></option>
          <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
        </select>
      </label>
    </div>
    """
  end
end
