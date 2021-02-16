local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.openshift_prometheus_proxy;
local argocd = import 'lib/argocd.libjsonnet';

local app =
  argocd.App('openshift-prometheus-proxy', params.namespace) {
    spec+: {
      ignoreDifferences+: [
        {
          group: 'image.openshift.io',
          kind: 'ImageStream',
          jsonPointers: [
            // tags[].spec.importPolicy.schedule=false gets dropped by OCP3.11
            '/spec/tags/0/importPolicy',
            // tags[].spec.annotations=null gets set by OCP3.11
            '/spec/tags/0/annotations',
          ],
        },
        {
          group: 'apps',
          kind: 'Deployment',
          jsonPointers: [
            // container image field gets overwritten by imagestream
            '/spec/template/spec/containers/0/image',
            '/spec/template/spec/containers/1/image',
          ],
        },
        {
          group: 'build.openshift.io',
          kind: 'BuildConfig',
          jsonPointers: [
            // ignore changes to spec.triggers elements
            '/spec/triggers/0',
            '/spec/triggers/1',
          ],
        },
      ],
    },
  };

{
  'openshift-prometheus-proxy': app,
}
