defmodule ARI.Util do
  @moduledoc "Utility functions for ARI"
  use Bitwise

  def config_diff(old_config, new_config) do
    Enum.filter(new_config, fn %{value: value} = field ->
      field = %{field | value: cidr_to_netmask(value)}

      !Enum.any?(old_config, fn
        ^field -> true
        _ -> false
      end)
    end)
  end

  def cidr_to_netmask(cidr) do
    case String.split(cidr, [".", "/"]) do
      [p1, p2, p3, p4, block] ->
        netmask =
          block
          |> String.to_integer()
          |> cidr_netmask()
          |> Tuple.to_list()
          |> Enum.join(".")

        "#{p1}.#{p2}.#{p3}.#{p4}/#{netmask}"

      _ ->
        cidr
    end
  end

  def cidr_netmask(bits) when is_integer(bits) and bits <= 32 do
    zero_bits = 8 - rem(bits, 8)
    last = bsl(0xFF, zero_bits) |> bsl(zero_bits)

    case div(bits, 8) do
      0 ->
        {255 &&& last, 0, 0, 0}

      1 ->
        {255, 255 &&& last, 0, 0}

      2 ->
        {255, 255, 255 &&& last, 0}

      3 ->
        {255, 255, 255, 255 &&& last}

      4 ->
        {255, 255, 255, 255}
    end
  end
end
