// OpenShift template renderer
{
  OpenShiftTemplateRenderer:: {
    template_parameters:: error 'Must provide template parameters as object with parameter name as key',

    template:: error 'Must provide list of template objects',

    param_required(it)::
      std.objectHas(self.template_parameters, it.name) ||
      (std.objectHas(it, 'required') && it.required) ||
      // we cannot sanely handle generating values at compile time, so we require
      // "generate" parameters to be present in the template parameters provided
      // to the renderer.
      std.objectHas(it, 'generate'),

    tplparams::
      local r = self;
      {
        [it.name]:
          if r.param_required(it) then r.template_parameters[it.name]
          else if std.objectHas(it, 'value') then it.value
          else error 'unknown template parameter: %s' % it
        for it in self.template.parameters
      },

    paramfuns:: [
      function(it) std.strReplace(it, '${%s}' % param, self.tplparams[param])
      for param in std.objectFields(self.tplparams)
    ],

    render_params(v):: std.foldl(function(it, f) f(it), self.paramfuns, v),

    render_tpl_list(l)::
      [
        if std.isObject(it) then self.render_tpl_obj(it)
        else if std.isArray(it) then self.render_tpl_list(it)
        else if std.isString(it) then self.render_params(it)
        else it
        for it in l
      ],

    render_tpl_obj(o)::
      local r = self;
      {
        [k]:
          if std.isObject(o[k]) then r.render_tpl_obj(o[k])
          else if std.isArray(o[k]) then r.render_tpl_list(o[k])
          else if std.isString(o[k]) then r.render_params(o[k])
          else o[k]
        for k in std.objectFields(o)
      },


    // Read this variable to extract the rendered template objects as a list
    rendered_template:
      if std.assertEqual(self.template.kind, 'Template') then
        [ self.render_tpl_obj(o) for o in self.template.objects ],

    // Read this variable to extract the name of the template object
    template_name:
      if std.assertEqual(self.template.kind, 'Template') then
        self.template.metadata.name,

    // Read this variable to get an object with arrays of rendered manifests
    // for each object kind present in the template
    rendered_kinds:
      local kind(it) =
        if std.assertEqual(std.objectHas(it, 'kind'), true) then
          std.asciiLower(it.kind) + 's';

      local r = self;
      local elems = [
        {
          [kind(it)]+: [ it ],
        }
        for it in r.rendered_template
      ];
      std.foldl(function(a, it) a + it, elems, {}),
  },
}
