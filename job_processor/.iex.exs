good_job = fn -> Process.sleep(20000)
  {:ok, []}
end

bad_job = fn -> Process.sleep(20000)
  :error
end

unknown_job = fn -> Process.sleep(20000)
  raise "Boom!"
end
