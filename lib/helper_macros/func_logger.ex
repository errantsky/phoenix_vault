defmodule HelperMacros.FuncLogger do
  require Logger

  defmacro log_func({func, _, [args]} = call) do
    quote do
      func_name = unquote(Atom.to_string(func))

      arg_vals =
        Enum.map(unquote(args), fn
          {name, val} = arg ->
            """
            #{Atom.to_string(name)}:\n\t#{inspect(val, pretty: true)}
            """

          arg ->
            "#{inspect(arg, pretty: true)}"
        end)
        |> Enum.join("\n" <> String.duplicate("-", 20) <> "\n")

      Logger.debug("""
      log_func #{func_name} #{func_name} with the following params:\n
      #{arg_vals}
      #{String.duplicate("-", 20)}
      """)

      start_time = :os.system_time(:millisecond)
      result = unquote(call)
      end_time = :os.system_time(:millisecond)

      Logger.debug(
        "log_func #{func_name} Execution time was: #{:io_lib.format("~B", [end_time - start_time]) |> IO.iodata_to_binary()} ms"
      )

      Logger.debug("""
      log_func #{func_name} The result was:\n#{inspect(result, pretty: true)}
      """)

      Logger.debug("log_func #{func_name} finished.")

      result
    end
  end
end
