# Work in process for conference talk
## Flexible Logging for Kubernetes with fleuntd

This is just a little Demo for the Talk: [Flexible Logging Pipelines with Fluentd and Kubernetes](https://www.youtube.com/watch?v=tHY2JmvVxpw&index=14&list=PLj6h78yzYM2PAavlbv0iZkod4IVh_iGqV). 

The goal is to have a flexible logging pipeline in which developers (not ops) can freely defined there logging pipeline.
To archive this we use fluend (elastic beats could be also use with some limitations to multiple outputs & routing), in combination with [kube-gen](https://github.com/kylemcc/kube-gen), a tool that watches the API and renders data through a golang template.

## Static log forwarding with Kubernetes

The classic way to do log forwarding inside kubernetes is to deploy fluentd as a daemonset so it runs on every node. 
Kubernetes writes the log of every containter to `/var/log/containers/*`, these log files can be picked up by fluentd.
Fluentd then uses a plugin to enrich the logs with metadata and routes it to defined outputs. 
This approach is relativly fine, until you have a cluster shared between many teams. 
The fluentd config then quickly  becomes a coordination bottleneck if your debvelopers want to do more than route everything to es.
Also this forces developers to define these far away from their code/deployment spec, which shouldnt be like that.

There a few common solution to this problem:
1. Use an extra Routing/Parsing Point. This doesnt really solve the coordination problem, but it's much easier to update and manage the config on that.
2. Every Team runs their own sidecar/solution. This allows developers to be really flexible, and possibly define target rules etc in their own source. 
But this wastes a lot in resources and especially manpower.
3. Dynamicly generate the fluentd config from annotations defined by the developers.
This allows developers to defined their wanted targets/parsing rules direclty at their deployment definitions, while still have a lot of flexibility.
Also a second advantage is that now developers define these in their deployment spec which is much "closer" to their code than a central repository. 
The downside of this approach is that you need an extra moving part in your infrastructure for the generation.

## Definition
The first step is to let the developers define their outputs and parsing rules in pod annotations.
Its up to the operator how much freedom he wants to give to the developers, he can allow everry target, or just a choice of exististing targets etc...
```yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: busybox1
  annotations:
    fluentd_target: >
      [
          {
             "output": "elasticsearch",
             "host": "localhost"
          }
      ]
spec:
  containers:
```


## Templating
After we defined the annotations we now write the template wich should be used for the fluentd config later. As a templating engine we use [golang templates](https://golang.org/pkg/text/template/), since it's easy and our generation tool supports that :).
As a first basic step we gather every pod which has our previously defined annotation key.
```
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
```
In the next step we now then loop over every pod and parse their annotation value as json so we can further process it.
If you have multipod container a second loop is maybe needed here, but for brevity we leave that out of the tutorial. 
Its important to extract the containerID since the logs written by kubernetes/docker dont contain any pod name/container name.
So to correctlyy identify the pods we need that id. (An alternative would be to get the k8s metadata first and then re-label the route accordingly)
From the extracted config we then compare the annotated type with a few predefined choices. 
In case of a match we just render the approapte config out with the defined hostname etc.

### Generation

For generation we use kube-gen by kylemcc, instead of writing something on our own, since its awesome and provides everything we need in a go binary :). 
```
exec kube-gen -watch -type pods -wait 2s:8s -post-cmd ' sudo /etc/init.d/td-agent reload' /etc/td-agent/td-agent.conf.tpl /etc/td-agent/td-agent.conf
```

## Operations

In larger Clusters be carefull that you dont reload fluentd config to often since there is a signifikant overhead to this.
 Maybe generate the config node specific and wrap a diff around to only reload if something on that specific node changes.

## Alternatives

You can also do that [with Beats](https://github.com/kylemcc/kube-filebeat)
