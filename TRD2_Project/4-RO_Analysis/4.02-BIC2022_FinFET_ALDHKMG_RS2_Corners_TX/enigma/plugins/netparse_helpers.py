import os

from common.Parser.SpiceParser import NetlistParser
from randomspice.Components import Netlist
from common.Parser import Parameter

class RS2NetAdjust(object):
    '''
    Quickly created class to convert external netlist to
    RandomSpice simulatable ones.
    '''

    def __init__(self, source_net="netname", output_path="./"):
        
        self.source_net=source_net
        self.parser=NetlistParser(enable_passives=False)
        try:
            with open(self.source_net, "r") as f:
               self.new_net = self.parser.Parse(f)
        except TypeError:
               self.new_net = self.parser.Parse(source_net)
        self.model_call_mapping={}
        self.model_add_pars={}
        self.model_remove_pars={}

    def convert_Xmacro_to_Minst(self, net=None):
        '''
        simply replaces the initial "x" with "m".
        '''
        if net is None: net=self.new_net
        for x,c in enumerate(net):
            # if this is a macro instance and we
            # are converting this model call
            # we should convert the name 
            # only works if we have defined "model_call_mapping"
            # this is how we differentiate between legitimate subckts
            # and macro model calls
            if c[0] == "#SUBCKT":
                self.convert_Xmacro_to_Minst(c[1])

            elif c[0] == "#SUBCKTINST" and c[1]['subcircuit'] in self.model_call_mapping.keys():
                c[0] = "#MOSFET"
                c[1]['name']="m"+c[1]['name'][1:]
                subckt=c[1].pop('subcircuit')
                c[1]['model']=subckt

    def convert_Minst_to_Xmacro(self, net=None):
        '''
        simply replaces the initial "x" with "m".
        '''
        if net is None: net=self.new_net
        for x,c in enumerate(net):
            # if this is a macro instance and we
            # are converting this model call
            # we should convert the name 
            # only works if we have defined "model_call_mapping"
            # this is how we differentiate between legitimate subckts
            # and macro model calls
            if c[0] == "#SUBCKT":
                self.convert_Minst_to_Xmacro(c[1])

            elif c[0] == "#MOSFET" and c[1]['model'] in self.model_call_mapping.keys():
                c[0] = "#SUBCKTINST"
                c[1]['name']="x"+c[1]['name']
                model=c[1].pop('model')
                c[1]['subcircuit']=model


    def convert_models(self, net=None, add_subckt_rand=True):
        '''
        convert models and also manipulate the instance parameters
        '''
        if net is None: net=self.new_net
        for x,c in enumerate(net):
            # and macro model calls
            if c[0] == "#SUBCKT":
                if add_subckt_rand:
                    c[1][0][1]['subname']=c[1][0][1]['subname']+":RAND"
                self.convert_models(c[1])

            elif c[0] == "#MOSFET" and c[1]['model'] in self.model_call_mapping.keys():
                c[1]['model']=self.model_call_mapping[c[1]['model']]
                if c[1]['model'] in self.model_remove_pars.keys():
                    # create a parameter list which does not include the ones 
                    # from our remove pars list
                    final_paramlist = [x for x in c[1]['params'] if x.GetName().lower() not in self.model_remove_pars[c[1]['model']]]
                    c[1]['params'] = final_paramlist

                if c[1]['model'] in self.model_add_pars.keys():
                    # first remove any instance parameters which clash with the values we're adding
                    # then append the new parameters
                    temp_paramlist = [x for x in c[1]['params'] if x.GetName().lower() not in self.model_add_pars[c[1]['model']].keys()]
                    for k,v in self.model_add_pars[c[1]['model']].items():
                        temp_paramlist.append(Parameter(k,v))
                    c[1]['params'] = temp_paramlist

            elif c[0] == "#SUBCKTINST" and c[1]['subcircuit'] in self.model_call_mapping.keys():
                c[1]['subcircuit']=self.model_call_mapping[c[1]['subcircuit']]
                if c[1]['subcircuit'] in self.model_remove_pars.keys():
                    # create a parameter list which does not include the ones 
                    # from our remove pars list
                    final_paramlist = [x for x in c[1]['params'] if x.GetName().lower() not in self.model_remove_pars[c[1]['subcircuit']]]
                    c[1]['params'] = final_paramlist

                if c[1]['subcircuit'] in self.model_add_pars.keys():
                    # first remove any instance parameters which clash with the values we're adding
                    # then append the new parameters
                    temp_paramlist = [x for x in c[1]['params'] if x.GetName().lower() not in self.model_add_pars[c[1]['subcircuit']].keys()]
                    for k,v in self.model_add_pars[c[1]['subcircuit']].items():
                        temp_paramlist.append(Parameter(k,v))
                    c[1]['params'] = temp_paramlist

            elif c[0] == "#SUBCKTINST":
                print(c[1]['subcircuit'])
                c[1]['subcircuit']=c[1]['subcircuit']+":RAND"


    def add_instance_param(self,model_name=None,k="k",v="v"):
        '''
        Add instance parameters to the model_add_pars dict.
        I'm choosing to not support people adding "Parameter" instaces because WHY WOULD YOU?
        '''
        if model_name in self.model_call_mapping.values():
            pass
        elif model_name in self.model_call_mapping.keys():
            model_name=self.model_call_mapping[model_name]
        else:
            raise ValueError("Provided model name {0} not in model_call_mapping".format(model_name))
                
        if model_name not in self.model_add_pars.keys(): self.model_add_pars[model_name]={}
        self.model_add_pars[model_name].update({k.lower():v})


    def remove_instance_param(self,model_name=None,k="k"):
        '''
        Remopve instance parameters from the model_remove_pars list.
        Remove based on KEY only, no parameter value checking here.
        '''
        if model_name in self.model_call_mapping.values():
            pass
        elif model_name in self.model_call_mapping.keys():
            model_name=self.model_call_mapping[model_name]
        else:
            raise ValueError("Provided model name {0} not in model_call_mapping".format(model_name))
                
        if model_name not in self.model_remove_pars.keys(): self.model_remove_pars[model_name]=[]
        self.model_remove_pars[model_name].append(k.lower())


    def save_net(self,filename=None,outpath="./", net=True):
        with open(os.path.join(outpath, filename),'w') as f:
            if net is True:
                f.write(str(Netlist(self.new_net)))
            else:
                f.write(str(Netlist(self.new_net)).replace("\n.END\n", "\n"))

    def net_str(self):
        return str(Netlist(self.new_net)).replace(".END\n","")




## INCLUDE command
def stateInclude(self, data):
    l = self.lines[self.lnum]
    self.lnum += 1
        
    incfile = " ".join(l.split()[1:]).strip("'\"")
    try:
        incdata = NetlistParser(enable_passives=False).Parse(open(incfile))
    except IOError as msg:
        raise ValueError(["Couldn't read include file {0}".format(incfile), msg])

    data['output'].append(["#GEN", "*{0:*^79}\n".format(" Included from {0} ".format(incfile))])
    data['output'].extend(incdata)
    data['output'].append(["#GEN", "{0}\n".format("*" * 80)])
        
    return('Master', data)


#### patch  
NetlistParser.stateInclude=stateInclude
