defmodule Pan.Parser.PersonaTest do
  use Pan.DataCase

  alias Pan.Parser.Persona

  defp unique_email(local_part) do
    "#{local_part}.#{System.unique_integer([:positive])}@example.com"
  end

  test "an email-only owner gets a name and uri derived from the email" do
    email = unique_email("john.doe")

    {:ok, persona} = Persona.get_or_insert(%{email: email})

    assert persona.name =~ ~r/^John Doe \d+$/
    assert persona.uri == email
  end

  test "a non-string name is dropped, so the email-derived name applies" do
    email = unique_email("jane")
    html_name = %{name: :a, value: ["[email protected]"], attr: []}

    {:ok, persona} = Persona.get_or_insert(%{email: email, name: html_name})

    assert persona.name =~ ~r/^Jane \d+$/
  end

  test "a name from the feed is kept" do
    {:ok, persona} = Persona.get_or_insert(%{email: unique_email("x"), name: "Real Name"})

    assert persona.name == "Real Name"
  end
end
