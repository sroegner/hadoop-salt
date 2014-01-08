base:
  '*':
    - hostsfile
    - hostsfile.hostname
    - ntp.server
    - sun-java
    - jmxtrans

  'G@roles:hadoop_master or G@roles:hadoop_slave':
    - match: compound
    - hadoop
    - hadoop.snappy
    - hadoop.hdfs
    - hadoop.mapred
    - hadoop.yarn
    - hadoop.jmxtrans

  'roles:monitor_master':
    - match: grain
    - graphite

  'roles:monitor':
    - match: grain
    - graphite.diamond

