local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
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
  // The proxy SA needs ClusterRoles 'system:auth-delegator' to check incoming token
  // permissions and 'cluster-monitoring-view' to access openshift-monitoring
  rbac: [
    kube.ClusterRoleBinding('%s-auth-delegator' % params.namespace) {
      roleRef: {
        apiGroup: 'rbac.authorization.k8s.io',
        kind: 'ClusterRole',
        name: 'system:auth-delegator',
      },
      subjects: [
        {
          kind: 'ServiceAccount',
          namespace: params.namespace,
          name: 'openshift-prometheus-proxy',
        },
      ],
    },
    kube.ClusterRoleBinding(
      '%s-cluster-monitoring-view' % params.namespace
    ) {
      roleRef: {
        apiGroup: 'rbac.authorization.k8s.io',
        kind: 'ClusterRole',
        name: 'cluster-monitoring-view',
      },
      subjects: [
        {
          kind: 'ServiceAccount',
          namespace: params.namespace,
          name: 'openshift-prometheus-proxy',
        },
      ],
    },
  ],
}
