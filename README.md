## Flexible Logging for Kubernetes with fleuntd

This is just a little Demo for the Talk: TODO Link. The goal is to have a flexible logging pipeline in which developers (not ops) can freely defined there logging pipeline.
To archive this we use here fluend (elastic beats could be also use with some limitations to multiple outputs & routing), in combination with kube-gen, a tool that watches the API and renders data through a golang template.

## Static log forwarding with Kubernetes

The classic way to do log forwarding inside kubernetes is to deploy fluentd as a daemonset so it runs on every node. 
Kubernetes writes the log of every containter to /var/lib/*, these log files can be picked up by fluentd.
Fluentd the uses a plugin to enrich the logs with metadata and s


## Definition
The first step is to let the developers defined their outputs and parsing rules in pod annotations. Its up to the operator how much freedom he wants to give to the developers, he can allow everry target, or just a choice of exististing targets etc...

## Templating
After we defined the annotations we now write the template wich should be used for the fluentd config later. As a tempalting engine we use golang templates (LINK), since its easy and our generation tool supports thats :).
As a first basic steps we gather every pod which has our previously defined annotation key.
```
TODO
```
In the next step we now then loop over every pod and parse their annotation value as json so we can further process it.
If you have multipod container a second loop is maybe needed here, but for brevity we leave that out of the tutorial. 
Its important to extract the containerID since the logs written by kubernetes/docker dont contain any pod name/container name.
So to correctlyy identify the pods we need that id. (An alternative would be to get the k8s metadat first and then relabel the route accordingly)
From the extracted config we then compare the annotated type with a few predefined choices. 
In case of a match we just render the approapte config out with the defined hostname etc.

### Generation

For generartion we use kube-gen by kylemcc, instead of writing something on our own, since its awesome and provides everything we need in a go binary :). 




## Operations

In larger Clusters be carefull that you dont reload fluentd config to often since there is a signifikant overhead to this. Maybe genereate the config node spezfic and wrap a diff around to only reload if something on that spezific node changes.

## Alternatives

You can also do that with Beats (link), als
