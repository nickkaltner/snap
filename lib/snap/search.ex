defmodule Snap.Search do
  @moduledoc """
  Performs searches against an ElasticSearch cluster.
  """
  alias Snap.SearchResponse
  alias Snap.Cluster.Namespace

  @spec search(
          cluster :: module(),
          index_or_alias :: String.t(),
          query :: map(),
          params :: Keyword.t(),
          headers :: Keyword.t(),
          opts :: Keyword.t()
        ) :: {:ok, SearchResponse.t()} | Snap.Cluster.error()
  @doc """
  Makes a search against an ElasticSearch cluster and parses the response.

  Performs a search against an index using a POST request, and parses the
  response into a `Snap.SearchResponse`.

  `Snap.SearchResponse` implements `Enumerable`, so you can count and iterate
  directly on the struct.

  ## Examples

      query = %{query: %{match_all: %{}}}
      {:ok, response} = Snap.Search.search(Cluster, "index", query)

      IO.inspect(response.took)
      Enum.each(response, fn hit -> IO.inspect(hit.score) end)
  """
  def search(cluster, index_or_alias, query, params \\ [], headers \\ [], opts \\ []) do
    namespaced_index = Namespace.add_namespace_to_index(index_or_alias, cluster)

    case cluster.post("/#{namespaced_index}/_search", query, params, headers, opts) do
      {:ok, response} -> {:ok, SearchResponse.new(response)}
      err -> err
    end
  end

  @doc """
  Gets the next page of results in a scroll which was initiated by passing
  the scroll param into a search request, and parses the result into a
  `Snap.SearchResponse`.

  `Snap.SearchResponse` implements `Enumerable`, so you can count and iterate
  directly on the struct.

  """
  def scroll_req(cluster, scroll_id, ttl \\ "1m", params \\ [], headers \\ [], opts \\ []) do
    body = %{
      scroll: ttl,
      scroll_id: scroll_id
    }

    case cluster.post("/_search/scroll", body, params, headers, opts) do
      {:ok, response} -> {:ok, SearchResponse.new(response)}
      err -> err
    end
  end

  @doc """
  return all the results for a query via a set of scrolls, lazily as a stream
  """
  def scroll(cluster, index_or_alias, query, params \\ [], headers \\ [], opts \\ []) do
  end

  @doc """
  Runs a count of the documents in an index, using an optional query.
  """
  def count(cluster, index_or_alias, query \\ %{}, params \\ [], headers \\ [], opts \\ []) do
    namespaced_index = Namespace.add_namespace_to_index(index_or_alias, cluster)

    case cluster.post("/#{namespaced_index}/_count", query, params, headers, opts) do
      {:ok, %{"count" => count}} -> {:ok, count}
      err -> err
    end
  end
end
