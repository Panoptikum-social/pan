defmodule PanWeb.ViewHelpers do
  import Phoenix.HTML
  import Phoenix.HTML.Link
  alias PanWeb.Endpoint

  def icon(name), do: icon(name, class: "")

  def icon(name, class: class) do
    class = if class == "", do: "h-6 w-6", else: class

    case name do
      "cog-heroicons-outline" ->
        """
        <svg xmlns="http://www.w3.org/2000/svg"
             class="#{class}"
             fill="none"
             viewBox="0 0 24 24"
             stroke="currentColor">
          <path stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065
                2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572
                1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0
                00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07
                2.572-1.065z" />
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
        </svg>
        """

      "rss-heroicons-outline" ->
        """
        <svg xmlns="http://www.w3.org/2000/svg"
             class="#{class}"
             fill="none"
             viewBox="0 0 24 24"
             stroke="currentColor">
          <path stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724
                   1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724
                   0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724
                   0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724
                   0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
        </svg>
        """

      "search-heroicons-solid" ->
        """
        <svg xmlns="http://www.w3.org/2000/svg"
              class="#{class}"
              fill="currentColor"
              viewBox="0 0 20 20"
              stroke="currentColor">
          <path fill-rule="evenodd"
                d="M8 4a4 4 0 100 8 4 4 0 000-8zM2 8a6 6 0 1110.89 3.476l4.817 4.817a1 1 0 01-1.414 1.414l-4.816-4.816A6 6 0 012 8z"
                clip-rule="evenodd" />
        </svg>
        """

      "map-heroicons-outline" ->
        """
        <svg xmlns="http://www.w3.org/2000/svg"
              class="#{class}"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor">
          <path stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021
                  18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7" />
        </svg>
        """

      "beaker-heroicons-outline" ->
        """
        <svg xmlns="http://www.w3.org/2000/svg"
              class="#{class}"
              fill="none"
              viewBox="0 0 24 24"
          <path stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0
                   00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782
                   0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z" />
        </svg>
        """

      "question-mark-circle-heroicons-solid" ->
        """
        <svg xmlns="http://www.w3.org/2000/svg"
              class="#{class}"
              viewBox="0 0 20 20"
              fill="currentColor">
          <path fill-rule="evenodd"
                d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-8-3a1 1 0 00-.867.5 1 1 0 11-1.731-1A3 3 0 0113 8a3.001 3.001 0 01-2 2.83V11a1 1 0
                    11-2 0v-1a1 1 0 011-1 1 1 0 100-2zm0 8a1 1 0 100-2 1 1 0 000 2z" clip-rule="evenodd" />
        </svg>
        """

      "newspaper-heroicons-outline" ->
        """
        <svg xmlns="http://www.w3.org/2000/svg"
              class="#{class}"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor">
          <path stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7
                    16h6M7 8h6v4H7V8z" />
        </svg>
        """

      "user-secret-line-awesome-outline" ->
        """
        <svg xmlns="http://www.w3.org/2000/svg"
             class="#{class}"
             fill="none"
             viewBox="0 0 32 32"
             stroke="currentColor">
          <path fill="currentColor"
                d="M13.063 4c-.876 0-1.645.45-2.188 1.031c-.543.582-.934 1.309-1.281 2.094c-.531 1.21-.91 2.555-1.25
                    3.813c-1.086.316-2.008.71-2.75 1.187C4.727 12.684 4 13.457 4 14.5c0 .906.555 1.633 1.25 2.156c.594.446 1.324.817
                    2.188 1.125c.05.23.125.465.218.688c-.843.476-2.18 1.398-3.468 3.156l-.594.844l.844.593l3.28 2.25L6.376
                    28h19.25l-1.344-2.688l3.282-2.25l.843-.593l-.593-.844c-1.29-1.758-2.625-2.68-3.47-3.156c.095-.223.169-.457.22-.688c.863-.308
                    1.593-.68 2.187-1.125c.695-.523 1.25-1.25
                    1.25-2.156c0-1.043-.727-1.816-1.594-2.375c-.742-.477-1.664-.871-2.75-1.188c-.375-1.304-.789-2.671-1.312-3.874c-.34-.778-.715-1.493-1.25-2.063c-.535-.57-1.297-1-2.157-1c-.582
                    0-1.023.16-1.5.281c-.476.121-.957.219-1.437.219c-.96 0-1.766-.5-2.938-.5zm0 2c.207 0 1.437.5 2.937.5c.75 0 1.418-.152
                    1.938-.281c.519-.13.914-.219 1-.219c.23 0 .402.074.687.375c.285.3.621.844.906 1.5c.543 1.242.957 2.938 1.407
                    4.5c0-.004.054-.047-.094.031c-.25.137-.774.313-1.407.406c-1.269.192-3 .188-4.437.188c-1.43
                    0-3.164-.02-4.438-.219c-.636-.097-1.152-.27-1.406-.406c-.078-.043-.105-.027-.125-.031v-.031c.004-.008-.004-.024 0-.032l.031-.031a1.01
                    1.01 0 0 0 .126-.438v-.03c.359-1.329.761-2.735 1.25-3.845c.292-.667.609-1.21.906-1.53c.297-.321.5-.407.719-.407zm-4.876
                    7.094c.227.469.626.844 1.032 1.062c.61.324 1.308.477 2.062.594c1.508.234 3.274.25 4.719.25c1.438 0 3.207.008 4.719-.219c.758-.113
                    1.449-.261 2.062-.594c.41-.222.809-.617 1.032-1.093c.617.219 1.136.453 1.5.687c.582.375.687.653.687.719c0
                    .059-.05.25-.469.563c-.418.312-1.136.675-2.062.968c-1.852.59-4.516.969-7.469.969c-2.953
                    0-5.617-.379-7.469-.969c-.926-.293-1.644-.656-2.062-.968C6.05 14.75 6 14.559 6 14.5c0-.066.078-.316.656-.688c.364-.234.899-.488
                    1.532-.718zm2.594 5.469c.328.054.653.144 1 .187c.13.879.813 1.652 1.906 1.719c.844.05 1.793-.348 1.876-1.469h.875c.082 1.121 1.03 1.52
                    1.875 1.469c1.093-.067 1.777-.84 1.906-1.719c.347-.043.672-.133 1-.188l-.094.625c-.309 1.645-1.043 3.168-1.969 4.22C18.23
                    24.456 17.145 25.015 16 25c-1.176-.016-2.238-.582-3.156-1.625c-.918-1.043-1.64-2.535-1.969-4.188zM23 20c.371.219 1.348.86
                    2.469 2.094l-3.032 2.093l-.718.47l.375.78l.281.563h-3.156a7.547 7.547 0 0 0 1.437-1.281c1.102-1.25 1.84-2.887
                    2.25-4.657c.035-.019.063-.042.094-.062zm-14.031.031c.039.024.086.04.125.063c.43 1.746 1.164 3.363 2.25
                    .593c.449.512.972.95 1.531 1.313h-3.25l.281-.563l.375-.78l-.719-.47l-3.03-2.093c1.058-1.168 2.023-1.813 2.437-2.063z" />
        </svg>
        """

      "user-heroicons-outline" ->
        """
        <svg xmlns="http://www.w3.org/2000/svg"
              class="#{class}"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor">
          <path stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
        </svg>
        """

      "adjustments-heroicons-outline" ->
        """
        <svg xmlns="http://www.w3.org/2000/svg"
             class="#{class}"
             fill="none"
             viewBox="0 0 24 24"
             stroke="currentColor">
          <path stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0
                110-4m0 4v2m0-6V4" />
        </svg>
        """

      "user-circle-heroicons-outline" ->
        """
        <svg xmlns="http://www.w3.org/2000/svg"
             class="#{class}"
             fill="none"
             viewBox="0 0 24 24"
             stroke="currentColor">
          <path stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M5.121 17.804A13.937 13.937 0 0112 16c2.5 0 4.847.655 6.879 1.804M15 10a3 3 0 11-6 0 3 3 0 016 0zm6 2a9 9 0 11-18 0 9 9 0
                  0118 0z" />
        </svg>
        """

      "inbox-heroicons-outline" ->
        """
        <svg xmlns="http://www.w3.org/2000/svg"
             class="#{class}"
             fill="none"
             viewBox="0 0 24 24"
             stroke="currentColor">
          <path stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414
                   2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
        </svg>
        """

      "podcast-lineicons-solid" ->
        """
        <svg xmlns="http://www.w3.org/2000/svg"
             class="#{class}"
             fill="none"
             viewBox="0 0 32 32"
             stroke="currentColor">
          <path d="M 16.5 3 C 10.159 3 5 8.159 5 14.5 C 5 19.149 7.7788125 23.153844 11.757812 24.964844 C 11.644813 24.120844 11.555531
                23.283219 11.519531 22.574219 C 8.8125313 20.898219 7 17.911 7 14.5 C 7 9.262 11.262 5 16.5 5 C 21.738 5 26 9.262 26 14.5 C 26
                17.911 24.187469 20.898219 21.480469 22.574219 C 21.444469 23.282219 21.355187 24.120844 21.242188 24.964844 C 25.221187
                23.153844 28 19.149 28 14.5 C 28 8.159 22.841 3 16.5 3 z M 16.5 7 C 12.364 7 9 10.364 9 14.5 C 9 16.854 10.092922 18.956031
                11.794922 20.332031 C 12.020922 19.721031 12.4025 19.154641 12.9375 18.681641 C 11.7545 17.671641 11 16.173 11 14.5 C 11 11.468
                13.468 9 16.5 9 C 19.532 9 22 11.468 22 14.5 C 22 16.173 21.2455 17.671641 20.0625 18.681641 C 20.5975 19.153641 20.980078
                19.720031 21.205078 20.332031 C 22.907078 18.956031 24 16.854 24 14.5 C 24 10.364 20.636 7 16.5 7 z M 16.5 11 C 14.57 11 13
                12.57 13 14.5 C 13 16.43 14.57 18 16.5 18 C 18.43 18 20 16.43 20 14.5 C 20 12.57 18.43 11 16.5 11 z M 16.5 13 C 17.327 13 18
                13.673 18 14.5 C 18 15.327 17.327 16 16.5 16 C 15.673 16 15 15.327 15 14.5 C 15 13.673 15.673 13 16.5 13 z M 16.5 19 C 13.341 19
                13 21.07575 13 21.96875 C 13 23.61275 13.537078 26.919828 13.830078 28.173828 C 13.959078 28.723828 14.478 30 16.5 30 C 18.522
                30 19.040922 28.723828 19.169922 28.173828 C 19.462922 26.920828 20 23.61275 20 21.96875 C 20 21.07575 19.659 19 16.5 19 z M
                16.5 21 C 18 21 18 21.55975 18 21.96875 C 18 23.30375 17.529656 26.399797 17.222656 27.716797 C 17.197656 27.821797 17.156 28
                16.5 28 C 15.844 28 15.802344 27.82275 15.777344 27.71875 C 15.471344 26.40475 15 23.30475 15 21.96875 C 15 21.55975 15 21
                16.5 21 z"/>
        </svg>
        """

      _ ->
        raise "icon_missing: " <> name
    end
  end

  def la_nav_icon(name) do
    icon(name, class: "fill-current text-coolGray-200 h-6 w-6 inline")
  end

  def btn_cycle(counter) do
    Enum.at(
      [
        "btn-default",
        "btn-gray-lighter",
        "btn-gray",
        "btn-gray-darker",
        "btn-success",
        "btn-info",
        "btn-primary",
        "btn-blue-jeans",
        "btn-lavender",
        "btn-pink-rose",
        "btn-danger",
        "btn-bittersweet",
        "btn-warning"
      ],
      rem(counter, 13)
    )
  end

  def color_class_cycle(counter) do
    Enum.at(
      [
        "bg-white hover:bg-gray-lighter text-gray-darker border-gray",
        "bg-gray-lighter hover:bg-gray-lightest text-gray-darker border-gray",
        "bg-gray hover:bg-gray-light text-white",
        "bg-gray-darker hover:bg-gray-darker text-white",
        "bg-success hover:bg-success-light text-white",
        "bg-mint hover:bg-mint-light text-white",
        "bg-info hover:bg-info-light text-white",
        "bg-blue-jeans hover:bg-blue-jeans-light text-white",
        "bg-lavender hover:bg-lavender-light text-white",
        "bg-pink-rose hover:bg-pink-rose-light text-white",
        "bg-danger hover:bg-danger-light text-white",
        "bg-bittersweet hover:bg-bittersweet-light text-white",
        "bg-warning hover:bg-warning-light text-white"
      ],
      rem(counter, 13)
    )
  end

  def truncate_string(string, len) do
    length = len - 3

    if string do
      if String.length(string) > length do
        String.slice(string, 0, length) <> "..."
      else
        string
      end
    else
      ""
    end
  end

  def ej(nil), do: ""
  def ej(string), do: javascript_escape(string)

  def my_safe_to_string({:safe, string}), do: safe_to_string({:safe, string})
  def my_safe_to_string(string), do: string

  def datatable_actions(record_id, path) do
    [
      "<nobr>",
      link("Show",
        to: path.(Endpoint, :show, record_id),
        class: "btn btn-default btn-xs"
      ),
      " ",
      link("Edit",
        to: path.(Endpoint, :edit, record_id),
        class: "btn btn-warning btn-xs"
      ),
      " ",
      link("Delete",
        to: path.(Endpoint, :delete, record_id),
        method: :delete,
        data: [confirm: "Are you sure?"],
        class: "btn btn-danger btn-xs"
      ),
      "</nobr>"
    ]
    |> Enum.map(&my_safe_to_string/1)
    |> Enum.join()
  end

  def fa_icon(name) do
    ~s(<i class="fa fa-#{name}"></i>) |> raw()
  end

  def fa_icon(name, class: class) do
    ~s(<i class="fa fa-#{name} #{class}"></i>) |> raw()
  end
end
