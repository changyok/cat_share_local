

from randomspice.Libraries.SubCktLibrary import SubCktLib

def _CalcDeltas1(self, vals, params, basemodel, baseinst):
    #print(vals, params, baseinst)
    if not (isinstance(params, list) or isinstance(params, tuple)):
        vals = [vals]
        params = [params]

    for i,val in enumerate(vals):
        if params[i] is not None:
            try:
                # vals[i] = vals[i] - basemodel.GetParam(params[i]).GetValue()
                ## vals[i] = vals[i] - basemodel.get_model_parameter(params[i])
                vals[i] = vals[i] - baseinst.GetParam(params[i]).GetValue()
            except KeyError:
                try:
                    ## vals[i] = vals[i] - baseinst.GetParam(params[i]).GetValue()
                    vals[i] = vals[i] - basemodel.get_model_parameter(params[i])
                except KeyError:
                    raise KeyError(f"Could not find the specified parameter, '{params[i]}', in model '{basemodel.GetName()}' or instance '{baseinst.GetName()}'")
    
    return vals


print("patching for phigvar LVRSM bug")
SubCktLib._CalcDeltas=_CalcDeltas1
