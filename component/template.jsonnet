local kap = import 'lib/kapitan.libjsonnet';
local renderer = import 'openshift_template_renderer.libsonnet';

local inv = kap.inventory();
local params = inv.parameters.openshift_prometheus_proxy;

local r = renderer.OpenShiftTemplateRenderer {
  template_parameters:: params.template_parameters,
};

// Note: the current implementation supports rendering all OpenShift
// templates defined in the loaded YAML file.
local openshift_templates =
  std.parseJson(kap.yaml_load_stream(
    'openshift-prometheus-proxy/manifests/%s/template.yaml' % params.version
  ));

local rendered = [ (r { template:: t }) for t in openshift_templates ];

local output_name(t, kind) =
  if std.length(rendered) > 1 then
    '%s_%s' % [ t.template_name, kind ]
  else
    kind;

{
  manifests:
    // Merge output objects if input template file had multiple templates
    std.foldl(
      function(a, it) a + it,
      [
        // Generate outputs from rendered template
        {
          [if !(kind == 'routes' && !params.route_enabled) then output_name(t, kind)]: t.rendered_kinds[kind]
          for kind in std.objectFields(t.rendered_kinds)
        }
        for t in rendered
      ],
      {}
    ),
}
