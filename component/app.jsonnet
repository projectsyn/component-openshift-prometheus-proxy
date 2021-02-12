local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.openshift_prometheus_proxy;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('openshift-prometheus-proxy', params.namespace);

{
  'openshift-prometheus-proxy': app,
}
