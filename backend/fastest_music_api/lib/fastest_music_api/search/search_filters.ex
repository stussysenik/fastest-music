defmodule FastestMusicApi.Search.SearchFilters do
  @moduledoc """
  Post-fetch filtering for search results.

  ## Why post-fetch?

  External APIs (iTunes, MusicBrainz) have limited filtering support.
  Rather than trying to map our filter params to each API's query syntax,
  we fetch a broad result set and filter locally. This is fast because
  we're filtering a list of ~25 items in memory.
  """

  @doc "Apply genre and year filters to a list of album maps."
  def apply_filters(results, genre, year_from, year_to) do
    results
    |> filter_genre(genre)
    |> filter_year_range(year_from, year_to)
  end

  @doc "Generate a deterministic hash for filter params (used as cache key)."
  def hash_filters(nil, nil, nil), do: ""
  def hash_filters(genre, year_from, year_to) do
    parts = [
      if(genre, do: "g:#{String.downcase(genre)}", else: nil),
      if(year_from, do: "yf:#{year_from}", else: nil),
      if(year_to, do: "yt:#{year_to}", else: nil)
    ]
    parts |> Enum.reject(&is_nil/1) |> Enum.join("|")
  end

  # --- Private ---

  defp filter_genre(results, nil), do: results
  defp filter_genre(results, ""), do: results
  defp filter_genre(results, genre) do
    genre_lower = String.downcase(genre)
    Enum.filter(results, fn album ->
      genre_names = album["genreNames"] || []
      Enum.any?(genre_names, fn g ->
        String.contains?(String.downcase(g), genre_lower)
      end)
    end)
  end

  defp filter_year_range(results, nil, nil), do: results
  defp filter_year_range(results, year_from, year_to) do
    Enum.filter(results, fn album ->
      case extract_year(album["releaseDate"]) do
        nil -> true  # Keep albums with no release date
        year ->
          (is_nil(year_from) or year >= parse_int(year_from)) and
          (is_nil(year_to) or year <= parse_int(year_to))
      end
    end)
  end

  defp extract_year(nil), do: nil
  defp extract_year(""), do: nil
  defp extract_year(date) when is_binary(date) do
    case Regex.run(~r/(\d{4})/, date) do
      [_, year] -> String.to_integer(year)
      _ -> nil
    end
  end

  defp parse_int(val) when is_integer(val), do: val
  defp parse_int(val) when is_binary(val) do
    case Integer.parse(val) do
      {n, _} -> n
      :error -> nil
    end
  end
  defp parse_int(_), do: nil
end
