local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local template = import 'template.jsonnet';

local inv = kap.inventory();
local params = inv.parameters.openshift_prometheus_proxy;

local namespace = kube.Namespace(params.namespace);

{
  '00_namespace': namespace,
  proxy_rbac: template.rbac,
}
+ template.manifests
