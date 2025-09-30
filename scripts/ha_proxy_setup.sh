if [[ ( ${include_ha_proxy} == "yes" ) || ( ${install_haproxy_on_app} == "yes" && ${is_app_node} == "yes" ) ]]; then
  echo "HAProxy Config and Install"

  # Write haproxy.cfg in one shot
  cat > /home/ec2-user/haproxy.cfg <<'CFG'
  global
    maxconn 4096

  defaults
      mode                tcp

      # Timeout values should be configured for your specific use.
      # See: https://cbonte.github.io/haproxy-dconv/1.8/configuration.html#4-timeout%20connect

      # With the timeout connect 5 secs,
      # if the backend server is not responding, haproxy will make a total
      # of 3 connection attempts waiting 5s each time before giving up on the server,
      # for a total of 15 seconds.
      retries             3
      timeout connect     2s

      # timeout client and server govern the maximum amount of time of TCP inactivity.
      # These should be larger than the time to execute the longest query,
      # but not so large that failed connections linger forever.
      # timeout client      10m
      # timeout server      10m

      # TCP keep-alive on client side. Server already enables them.
      option              clitcpka

  listen psql
      bind :26257
      mode tcp
      balance roundrobin
      option httpchk GET /health?ready=1
CFG

  counter=1
  for IP in ${ip_list}; do
    echo "    server cockroach$counter $IP:26257 check port 8080" >> /home/ec2-user/haproxy.cfg
    counter=$((counter+1))
  done

  chown ec2-user:ec2-user /home/ec2-user/haproxy.cfg

  echo "Installing HAProxy"
  yum -y install haproxy

  echo "Starting HAProxy as ec2-user"
  su ec2-user -lc 'haproxy -f haproxy.cfg > haproxy.log 2>&1 &'
else
  echo "Not running ha_proxy_setup"
  echo ${include_ha_proxy}
  echo ${install_haproxy_on_app}
fi