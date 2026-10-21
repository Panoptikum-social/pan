defmodule Pan.Repo.Migrations.SeedCategoryMappings do
  use Ecto.Migration

  # Apple's pre-2019 category names (and two strays) still used by many feeds,
  # mapped to the current categories, see PanWeb.CategoryMapping. Targets are
  # found by name; a missing one is reported and skipped.
  @mappings [
    # {feed parent, feed title, target parent, target title}
    {nil, "Games & Hobbies", nil, "Leisure"},
    {nil, "Government & Organizations", nil, "Government"},
    {nil, "Health", nil, "Health & Fitness"},
    {nil, "News & Politics", nil, "News"},
    {nil, "Science & Medicine", nil, "Science"},
    {nil, "Sports & Recreation", nil, "Sports"},
    {"Arts", "Literature", "Arts", "Books"},
    {"Business", "Business News", "News", "Business News"},
    {"Education", "Language Courses", "Education", "Language Learning"},
    {"Games & Hobbies", "Automotive", "Leisure", "Automotive"},
    {"Games & Hobbies", "Aviation", "Leisure", "Aviation"},
    {"Games & Hobbies", "Hobbies", "Leisure", "Hobbies"},
    {"Games & Hobbies", "Video Games", "Leisure", "Video Games"},
    {"Games & Hobbies", "Other Games", "Leisure", "Games"},
    {"Government & Organizations", "Local", "Government", "Local"},
    {"Government & Organizations", "National", "Government", "National"},
    {"Government & Organizations", "Regional", "Government", "Regional"},
    {"Government & Organizations", "Non-Profit", "Business", "Non-Profit"},
    {"Health", "Alternative Health", "Health & Fitness", "Alternative Health"},
    {"Health", "Fitness & Nutrition", "Health & Fitness", "Fitness & Nutrition"},
    {"Health", "Self-Help", "Education", "Self-Improvement"},
    {"Health", "Sexuality", "Health & Fitness", "Sexuality"},
    {"Religion & Spirituality", "Other", "Religion & Spirituality", "Religion"},
    {"Science & Medicine", "Medicine", "Health & Fitness", "Medicine"},
    {"Science & Medicine", "Natural Sciences", "Science", "Natural Sciences"},
    {"Science & Medicine", "Social Sciences", "Science", "Social Sciences"},
    {"Society & Culture", "History", nil, "History"},
    {"Sports & Recreation", "Amateur", "Sports", "Amateur"},
    {"Sports & Recreation", "College & High School", "Sports", "College & High School"},
    {"Sports & Recreation", "Professional", "Sports", "Professional"},
    {"Sports & Recreation", "Outdoor", "Sports", "Wilderness"},
    {"Technology", "Tech News", "News", "Tech News"},
    {nil, "Talk Radio", "Radio", "Talk Radio"},
    {"Education", "Education Technology", "Education", "Educational Technology"}
  ]

  def up do
    for {parent_title, title, target_parent, target_title} <- @mappings do
      case target_id(target_parent, target_title) do
        nil ->
          IO.puts("Category mapping skipped, no target #{inspect({target_parent, target_title})}")

        id ->
          repo().query!(
            """
            INSERT INTO category_mappings (parent_title, title, category_id, inserted_at, updated_at)
            VALUES ($1, $2, $3, now() AT TIME ZONE 'UTC', now() AT TIME ZONE 'UTC')
            ON CONFLICT ((lower(coalesce(parent_title, ''))), (lower(title))) DO NOTHING
            """,
            [parent_title, title, id]
          )
      end
    end
  end

  def down do
    for {parent_title, title, _, _} <- @mappings do
      repo().query!(
        "DELETE FROM category_mappings WHERE lower(coalesce(parent_title, '')) = lower($1) AND lower(title) = lower($2)",
        [parent_title || "", title]
      )
    end
  end

  # the Apple one first, then the oldest
  defp target_id(nil, title) do
    query_id(
      "SELECT id FROM categories WHERE parent_id IS NULL AND lower(trim(title)) = lower($1) ORDER BY apple DESC, id LIMIT 1",
      [title]
    )
  end

  defp target_id(parent_title, title) do
    query_id(
      """
      SELECT c.id FROM categories c JOIN categories p ON p.id = c.parent_id
      WHERE p.parent_id IS NULL AND lower(trim(p.title)) = lower($1) AND lower(trim(c.title)) = lower($2)
      ORDER BY p.apple DESC, c.apple DESC, c.id LIMIT 1
      """,
      [parent_title, title]
    )
  end

  defp query_id(sql, params) do
    case repo().query!(sql, params).rows do
      [[id]] -> id
      [] -> nil
    end
  end
end
