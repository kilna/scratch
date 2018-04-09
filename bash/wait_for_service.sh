while (( ++count <= 60 )); do
  docker stats --no-stream 2>/dev/null && break
  sleep 1
  (( count % 10 )) || echo "Waiting for docker daemon [$count] ..."
done
