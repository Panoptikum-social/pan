defmodule PanWeb.Surface.Tree do
  use Surface.Component

  prop(for, :any, required: true)

  def render(assigns) do
    ~F"""
    {recurse_tree(@for)}
    """
  end

  def recurse_tree(nodes, indent \\ "") do
    if is_atom(nodes) ||
         is_bitstring(nodes) ||
         is_integer(nodes) ||
         (!Enumerable.impl_for(nodes) && Enum.all?(nodes, &is_integer/1)) do
      Phoenix.HTML.Tag.content_tag :div, class: "font-mono" do
        [
          {:safe, indent},
          {:safe, my_indent(true)},
          {:safe, symbol([])},
          presenter(nodes)
        ]
      end
    else
      for {node, index} <- Enum.with_index(nodes) do
        {node, children} =
          if(Keyword.keyword?(node) || is_tuple(node), do: node, else: {node, []})

        Phoenix.HTML.Tag.content_tag :div, class: "font-mono" do
          [
            {:safe, indent},
            {:safe, is_last(index, nodes) |> my_indent},
            {:safe, symbol(children)},
            presenter(node),
            "\n",
            recurse_tree(children, indent <> extra_indent(is_last(index, nodes)))
          ]
        end
      end
    end
  end

  def ensure_no_bytelist(value) do
    if Enum.all?(value, &is_integer/1), do: to_string(value), else: value
  end

  def pack_string(value) when is_bitstring(value), do: [value]

  def is_last(index, nodes), do: index + 1 == length(nodes)

  def presenter(label) when is_atom(label), do: Atom.to_string(label)
  def presenter(label) when is_integer(label), do: Integer.to_string(label)
  def presenter(label) when is_struct(label), do: Regex.source(label)

  def presenter(label) do
    html_escape(label)
  end

  defp extra_indent(true), do: "&nbsp;&nbsp;"
  defp extra_indent(_), do: "│&nbsp;"

  def type(value) when is_bitstring(value), do: :file
  def type(value) when is_binary(value), do: :file
  def type(value) when is_atom(value), do: :file
  def type(value) when is_list(value), do: :directory

  def type(value) do
    if Enum.all?(value, &is_integer/1), do: :file, else: :unknown
  end

  defp my_indent(true), do: "└&nbsp;"
  defp my_indent(_), do: "├&nbsp;"

  defp symbol([]), do: "📄&nbsp;"
  defp symbol(_), do: "📁&nbsp;"
end
