{{ $pods := whereExist .Pods "ObjectMeta.Annotations.fluentd_target" -}}


<source>
  type tail
  path /var/log/containers/*.log
  pos_file /var/log/es-containers.log.pos
  time_format %Y-%m-%dT%H:%M:%S.%NZ
  tag kubernetes.*
  format json
  read_from_head true
</source>

<filter kubernetes.var.log.containers.*.log>
  type kubernetes_metadata
</filter>


<match **>
   type elasticsearch
   log_level info
   include_tag_key true
   host elasticsearch-logging
   port 9200
   logstash_format true
   # Set the chunk limit the same as for fluentd-gcp.
   buffer_chunk_limit 2M
   # Cap buffer memory usage to 2MiB/chunk * 32 chunks = 64 MiB
   buffer_queue_limit 32
   flush_interval 5s
   # Never wait longer than 5 minutes between retries.
   max_retry_wait 30
   # Disable the limit on the number of retries (retry forever).
   disable_retry_limit
   # Use multiple threads for processing.
   num_threads 8
</match>


{{ $target_pods := whereExist .Pods "ObjectMeta.Annotations.fluentd_target" -}}
{{- range $pod := $target_pods -}}
  {{/* get dockerid for the logfile */}}
  {{ $cID := trimPrefix (index $pod.Status.ContainerStatuses 0).ContainerID "docker://"}} 
  {{/* parse annotation to readable config */}}
  {{ $config := first (parseJson $pod.ObjectMeta.Annotations.fluentd_target) }} 
<match kubernetes.var.log.containers.{{ $cID }}.log> 
   type {{ $config.output}}
   host {{ $config.host}}
</match>
{{- end }} 



