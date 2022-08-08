import os


def par_mapping(cval, pval, fac=None, val_remap=None):
    ''' 
    Quick prototype, won't even do data validation for now
    '''
    
    # pull out the name of the parent parameter
    pname=list(pval.keys())[0]

    # cant remap to the same name
    if cval==pname: 
        print(f"Warning: original parameter name {pname} and mapped parameter name {cval} match, skipping remap")
        return

    # cant scale and remap values
    elif fac is not None and val_remap is not None:
         raise ValueError("No logic to apply correction factor and remap simultaneously")

    else:
        # check for remap values
        if val_remap is not None:
            if pval[pname] not in list(val_remap.keys()):
                print(f"Warning: value {pval[pname]} not in val_remap list {val_remap.keys()}, remapping ignored.")
                fval=pval[pname]
            else:
                fval=val_remap[pval[pname]]
        else:
            fval=pval[pname]

        if fac is not None:
            try:
                fval=float(fval)*float(fac)
            except TypeError:
                print(f"Warning: cannot apply factor:{fac} to value:{fval}.")

        try:
            retstr=f"DOE: {cval} {fval:.12g}"
        except ValueError:
            retstr=f"DOE: {cval} {fval}"
        print(retstr)



def set_work_dir(projectpath, node):
    ''' 
    Quick prototype, won't even do data validation for now
    '''
    if int(os.environ.get("SWB_HIERARCHICAL_PROJECT_DIR")) == 0:
        # not in heirachical mode
        return (os.path.join(projectpath, "n{node}_".format(node=node)))
    elif int(os.environ.get("SWB_HIERARCHICAL_PROJECT_DIR")) == 1:
        return (os.path.join(projectpath, "results", "nodes", str(node)))


