import os

import numpy as np
import pandas as pd
from libfromage.data import Data

from common.readers import PltFile

def write_plts_iv(plotter, pathstr, delta=1, source='generic', column_names=["Vg","Id"]):

    if source == 'generic':
        for i,x in enumerate(plotter._line_data):
            if i%delta == 0:
                plt = PltFile()
                if column_names is not None:
                    x.columns = column_names
                else:
                    column_names = x.columns.values
                x = x.reset_index(drop=True)
                x[column_names] = x[column_names].astype(float)
                for column in x.columns:
                    plt[column] = x[column]
                plt.functions = plt.datasets
                plt.write(pathstr.format(i//delta))


def plot_stat_data(garand, plotter, \
                   iv_ld=[], iv_hd=[], \
                   ivt=1e-7, vdd_nom=0.8, vdd_lin=0.5, \
                   label="foms", write_plts=True, sort=True, sort_label="ensemble_id"):

    '''
    replacement helper function for plotting of statistical data.
    assumes data will be passed in as lists of iv_ld and iv_hd.

    garand - app
        the app is always setup in enigma, so can always be passed in.
        it can be used to pass through output directories and node information to the helper function.
    plotter - Plotter object
        all plotter is always setup in enigma, so can always be passed in.


    '''


    if len(iv_ld) != len(iv_hd):
        raise ValueError(f"length of LD data {len(iv_ld)} != length of HD data.")
    else:
        ndev=len(iv_ld)
    plotter.reset_data()

    # sort the data - data is not guaranteed to come back in the "correct" order
    # here we're sortgin the data based on the "ensemble_id" identifier in the metadata
    if sort is True:
        iv_ld_sorted	=sorted(iv_ld, 	 key=lambda x:x.metadata[sort_label], reverse=False)
        iv_hd_sorted	=sorted(iv_hd, 	 key=lambda x:x.metadata[sort_label], reverse=False)
    else:
        iv_ld_sorted=iv_ld
        iv_hd_sorted=iv_hd

    # setup a FoM dataframe
    columns=["VT_lin", "VT_sat", "DIBL", "Ion_lin", "Ion_sat", "Ioff_lin", "Ioff_sat"]
    df=pd.DataFrame(index=None, columns=columns)	

    for dev in range(0,ndev):
        local_iv_ld   = iv_ld_sorted[dev]
        local_iv_hd   = iv_hd_sorted[dev]
        if write_plts is True:
            local_iv_ld.write_plt(os.path.join(garand.workdir, f"iv_ld_{dev+1}.plt"))
            local_iv_hd.write_plt(os.path.join(garand.workdir, f"iv_hd_{dev+1}.plt"))

 
        df.loc[dev, "VT_lin"]	=local_iv_ld.Vt(ic=ivt)
        df.loc[dev, "VT_sat"]	=local_iv_hd.Vt(ic=ivt)
        df.loc[dev, "DIBL"]	=(abs(df.loc[dev, "VT_lin"]) - abs(df.loc[dev, "VT_sat"]))/(abs(vdd_nom)-abs(vdd_lin))
        df.loc[dev, "Ion_lin"]	=local_iv_ld.Ion(v=vdd_nom)
        df.loc[dev, "Ion_sat"]	=local_iv_hd.Ion(v=vdd_nom)
        df.loc[dev, "Ioff_lin"]	=local_iv_ld.Ioff(v=0.0)
        df.loc[dev, "Ioff_sat"]	=local_iv_hd.Ioff(v=0.0)

    df=df.astype(float)
    df=df.dropna()
    df.to_csv(os.path.join(garand.workdir, f"{garand.project}-{label}.csv"))
    print(f"saveing CSV data to: {garand.workdir}/{garand.project}-{label}.csv")
    plotter._dist_data=[df]
    #plotter.plot_qq(filename=os.path.join(garand.workdir, "{0}-qq".format(garand.project)))
    print(f"saveing scatter matrix data to: {garand.workdir}/{garand.project}-{label}_0.png")
    plotter.plot_scatter_matrix(filename=os.path.join(garand.workdir, f"{garand.project}-{label}"))
    return plotter




def get_mystic_RSM_FoMs(projects, vt_cc=1e-7, v_ion=None, v_ioff=None):


    #########################################################################################################
    # setup the result dataframe                                                                          #
    doe	=projects[0].metadata["doe"]								  	  #
    axes_list = (doe.keys())										  #
    columns	=["VT_lin", "VT_sat", "DIBL", "Ion_lin", "Ion_sat", "Ioff_lin", "Ioff_sat"]	          #
    columns.extend(axes_list)										  #
													  #
    length	= len(projects)										  #
    # create the blank DF with NA in all columns							  #
    TCAD	=pd.DataFrame(pd.np.empty((length, len(columns)))* pd.np.nan, index=None, columns=columns)#
    MYSTIC	=pd.DataFrame(pd.np.empty((length, len(columns)))* pd.np.nan, index=None, columns=columns)#
    #########################################################################################################

    for x,prj in enumerate(projects):
        # pull data from the metadata of the project
        doe_pt	=prj.metadata["doe"]
        dtype	=prj.metadata["swb"]["Type"]
        Vdd_lin =prj.metadata["swb"]["Vdd_lin"]
        Vdd_nom =prj.metadata["swb"]["Vdd_nom"]
        drain_con = prj.metadata["swb"]["drain_con"]

        if v_ion is None: v_ion=Vdd_nom
        if v_ioff is None: v_ioff=0

        ld_query={f"bias__{drain_con}":Vdd_lin}
        hd_query={f"bias__{drain_con}":Vdd_nom}
        # pull out the data
        last_dataset=list(prj.datasets)[-1]
        data_ld	=Data.from_db(dataset=last_dataset, **ld_query)[0]
        data_hd	=Data.from_db(dataset=last_dataset, **hd_query)[0]

        for col in ["target", "fit"]:
            vt_lin	=data_ld.Vt(ic=vt_cc, col=col)
            vt_sat	=data_hd.Vt(ic=vt_cc, col=col)
            dibl	=(vt_lin - vt_sat)/(abs(Vdd_nom)-abs(Vdd_lin))
            ion_lin	=data_ld.Ion(v=v_ion, col=col)
            ion_sat	=data_hd.Ion(v=v_ion, col=col)
            ioff_lin=np.log10(abs(data_ld.Ioff(v=v_ioff, col=col)))
            ioff_sat=np.log10(abs(data_hd.Ioff(v=v_ioff, col=col)))
 
            print(vt_lin, vt_sat, dibl, ion_lin, ioff_lin, ioff_sat)

            if col=="target":
                for a in list(doe_pt.keys()): TCAD.loc[x,a]=doe_pt[a] 
                TCAD.loc[x,"VT_lin"] = vt_lin
                TCAD.loc[x,"VT_sat"] = vt_sat
                TCAD.loc[x,"Ion_lin"] = ion_lin
                TCAD.loc[x,"Ion_sat"] = ion_sat
                TCAD.loc[x,"Ioff_lin"] = ioff_lin
                TCAD.loc[x,"Ioff_sat"] = ioff_sat

            elif col=="fit":
                for a in list(doe_pt.keys()): MYSTIC.loc[x,a]=doe_pt[a] 
                MYSTIC.loc[x,"VT_lin"] = vt_lin
                MYSTIC.loc[x,"VT_sat"] = vt_sat
                MYSTIC.loc[x,"Ion_lin"] = ion_lin
                MYSTIC.loc[x,"Ion_sat"] = ion_sat
                MYSTIC.loc[x,"Ioff_lin"] = ioff_lin
                MYSTIC.loc[x,"Ioff_sat"] = ioff_sat

    return TCAD, MYSTIC
    
