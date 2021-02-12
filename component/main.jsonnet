local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local renderer = import 'openshift_template_renderer.libsonnet';

local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.openshift_prometheus_proxy;

local r = renderer.OpenShiftTemplateRenderer {
  template_parameters:: params.template_parameters,
};

local openshift_templates =
  std.parseJson(kap.yaml_load_stream(
    'openshift-prometheus-proxy/manifests/template.yaml'
  ));

local routeFilter(rendered) =
  std.filter(
    function(it) !(it.kind == 'Route' && !params.route_enabled),
    rendered
  );

{
  [t.template_name]: routeFilter(t.rendered_template)
  for t in [ (r { template:: t }) for t in openshift_templates ]
}
