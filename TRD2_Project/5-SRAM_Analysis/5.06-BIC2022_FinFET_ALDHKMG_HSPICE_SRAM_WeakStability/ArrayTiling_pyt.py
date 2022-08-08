
"""
example subckt definition:

.subckt HD wll wlr blt blb nblt nblb vdd vss  vnw vpw



.ends


wl_l = "wll"	# left WL node
wl_r = "wlr"	# right WL node
bl_t = "blt"	# top BL node
bl_b = "blb"	# bottom BL node
nbl_t = "nblt" 	# top nBL node
nbl_b = "nblb" 	# bottom nBL node
vdd   = "vdd"	# Vdd node
vss   = "vss"	# Vss node
vnw   = "vnw"	# n-well tie (pMOS)
vpw   = "vpw"	# p-well tie (nMOS)
"""

def create_array(cell_subdef=".subckt HD wll wlr blt blb nblt nblb vdd vss vnw vpw", 
                 Nrows=4, Ncolumns=4, mirrorWL=True, mirrorBL=True, hollow_core=True, core_cell="HD_nomos", sn="cored", nsn="ncored"):

    if Nrows%2!=0 or Ncolumns%2!=0: raise ValueError(f"Nrows and Ncolumns must be even.")

    subname = cell_subdef.split(" ")[1]
    nodes   = cell_subdef.split(" ")[2:]
    nodes_dict = {nodes.index(a):a for a in [wl_l, wl_r, bl_t, bl_b, nbl_t, nbl_b, vdd, vss, vnw, vpw]}

    array_string = ""
    wl_stimuli_string = "" 
    bl_stimuli_string = "" 
    nbl_stimuli_string = "" 
    cell_ic_stimuli_string = ""
    cell_ic_status_string = ""

    # x is row, y is column
    for x in range(Nrows):
        for y in range(Ncolumns):
            local_nodes = " "+" ".join(nodes)+" "
            inst_name=f"xcell{x}_{y}"

            if y==0:
               wl_stimuli_string+=f"vwl_{x} {wl_l}{x}_{y} 0 0\n"

            if x==0:
               bl_stimuli_string+=f".ic v({bl_t}{x}_{y})='vdd_val*@BL_overdrive@'\n"
               nbl_stimuli_string+=f".ic v({nbl_t}{x}_{y})='vdd_val*@BL_overdrive@'\n"


            # handle y-mirroring
            if y == 0:
                left_wl_node = f"{wl_l}{x}_{y}"
                right_wl_node = f"{wl_r}{x}_{y}"
            elif mirrorWL==False:
                left_wl_node = right_wl_node
                right_wl_node = f"{wl_r}{x}_{y}" 
            elif mirrorWL==True and (y+1)%2==0:
                right_wl_node = right_wl_node
                left_wl_node = f"{wl_l}{x}_{y}"
            elif mirrorWL==True :
                left_wl_node = left_wl_node
                right_wl_node = f"{wl_r}{x}_{y}" 

            # handle x-mirroring
            # the top row is special as it incudes reference to BL_t/nBL_t
            if x == 0 and (mirrorWL==True and (y+1)%2==0):
                top_bl_node = f"{nbl_t}{x}_{y}"
                bot_bl_node = f"{nbl_b}{x}_{y}"
                top_nbl_node = f"{bl_t}{x}_{y}"
                bot_nbl_node = f"{bl_b}{x}_{y}"
            elif x ==0:
                top_bl_node = f"{bl_t}{x}_{y}"
                bot_bl_node = f"{bl_b}{x}_{y}"
                top_nbl_node = f"{nbl_t}{x}_{y}"
                bot_nbl_node = f"{nbl_b}{x}_{y}"
            # case where WL is mirrored, every 2n cell, BL and NBL are switched
            elif mirrorBL==False and mirrorWL==True and (y+1)%2==0:
                top_bl_node = f"{nbl_b}{x-1}_{y}" 
                bot_bl_node = f"{nbl_b}{x}_{y}"  
                top_nbl_node = f"{bl_b}{x-1}_{y}" 
                bot_nbl_node = f"{bl_b}{x}_{y}" 
            # no BL/WL mirroring
            elif mirrorBL==False:
                top_bl_node = f"{bl_b}{x-1}_{y}" 
                bot_bl_node = f"{bl_b}{x}_{y}" 
                top_nbl_node = f"{nbl_b}{x-1}_{y}" 
                bot_nbl_node = f"{nbl_b}{x}_{y}" 
            # if both are mirrored, handle 
            elif mirrorBL==True and mirrorWL==True and (y+1)%2==0 and (x+1)%2==1:
                top_bl_node = f"{nbl_b}{x-1}_{y}" 
                bot_bl_node = f"{nbl_b}{x}_{y}" 
                top_nbl_node = f"{bl_b}{x-1}_{y}" 
                bot_nbl_node = f"{bl_b}{x}_{y}" 
            elif mirrorBL==True and mirrorWL==True and (y+1)%2==0:
                bot_bl_node = f"{nbl_b}{x-1}_{y}" 
                top_bl_node = f"{nbl_b}{x}_{y}" 
                bot_nbl_node = f"{bl_b}{x-1}_{y}" 
                top_nbl_node = f"{bl_b}{x}_{y}" 
            elif mirrorBL==True and (x+1)%2 ==0:
                bot_bl_node = f"{bl_b}{x-1}_{y}" 
                top_bl_node = f"{bl_b}{x}_{y}" 
                bot_nbl_node = f"{nbl_b}{x-1}_{y}" 
                top_nbl_node = f"{nbl_b}{x}_{y}" 
            elif mirrorBL==True :
                top_bl_node = f"{bl_b}{x-1}_{y}" 
                bot_bl_node = f"{bl_b}{x}_{y}"  
                top_nbl_node = f"{nbl_b}{x-1}_{y}" 
                bot_nbl_node = f"{nbl_b}{x}_{y}"  
            
            local_nodes = local_nodes.replace(f" {wl_l} ", f" {left_wl_node} ")
            local_nodes = local_nodes.replace(f" {wl_r} ", f" {right_wl_node} ")
            local_nodes = local_nodes.replace(f" {bl_t} ", f" {top_bl_node} ")
            local_nodes = local_nodes.replace(f" {bl_b} ", f" {bot_bl_node} ")
            local_nodes = local_nodes.replace(f" {nbl_t} ", f" {top_nbl_node} ")
            local_nodes = local_nodes.replace(f" {nbl_b} ", f" {bot_nbl_node} ")

            if hollow_core:
                if x==0 or y==0 or x==Nrows-1 or y==Ncolumns-1:
                    instline = f"{inst_name} {local_nodes} {subname}"
                    
                else:
                    instline = f"{inst_name} {local_nodes} {core_cell}"
            else:
                instline = f"{inst_name} {local_nodes} {subname}"
            array_string+=f"{instline}\n"
            
            ##if mirrorWL and (y+1)%2==0:
            ##    cell_ic_status_string += f".ic v({inst_name}.{nsn})=vdd_val\n"
            ##else:
            cell_ic_status_string += f".ic v({inst_name}.{nsn})=vdd_val\n"


    array_string+="\n*WL biases\n"
    array_string+=wl_stimuli_string
    array_string+="\n*BL biases\n"
    array_string+=bl_stimuli_string
    array_string+="\n*nBL biases\n"
    array_string+=nbl_stimuli_string
    array_string+="\n*SRAM cell initial conditons\n"
    array_string+=cell_ic_status_string

    return array_string

#######################################################################
# Execution start
#######################################################################
#set wl_l WLL
#set wl_r WLR
#set bl_t BLU
#set bl_b BLD
#set nbl_t BLBU
#set nbl_b BLBD
#set vdd VDD
#set vss VSS
#set vnw VBP
#set vpw VBN

wl_l  = "WLL"	# left WL node
wl_r  = "WLR"	# right WL node
bl_t  = "BLU"	# top BL node
bl_b  = "BLD"	# bottom BL node
nbl_t = "BLBU" 	# top nBL node
nbl_b = "BLBD" 	# bottom nBL node
vdd   = "VDD"	# Vdd node
vss   = "VSS"	# Vss node
vnw   = "VBP"	# n-well tie (pMOS)
vpw   = "VBN"	# p-well tie (nMOS)
nsn   = "iQ2:p1g"  # storage node 
sn    = "iQ1:p1d" # nstorage node


array_string = create_array(cell_subdef=".SUBCKT @cell@ BLBD BLBU BLD BLU VDD VSS WLL WLR VBP VBN", 
                            Nrows=@nrows@, Ncolumns=@ncolumns@, mirrorWL=True, mirrorBL=True, 
                            hollow_core=False, core_cell=None, sn=sn, nsn=nsn)


with open("n@node@_sram_array.sp", 'w') as f:
    f.write(array_string)

