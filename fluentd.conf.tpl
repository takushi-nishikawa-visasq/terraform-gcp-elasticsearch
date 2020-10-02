<source>
  @type tail
  format none
  path /var/log/elasticsearch/${cluster_name}.log
  pos_file /var/lib/google-fluentd/pos/elasticsearch.pos
  read_from_head true
  tag elasticsearch
</source>
