import pickle, os, math, copy
from mpl_toolkits.mplot3d import Axes3D
import matplotlib.pyplot as plt
from matplotlib import cm
import numpy as np
from scipy.interpolate import griddata
import pandas as pd
from itertools import permutations
import itertools

# defaults
default_collist=['r','b','g','c','m','y']



def round_to_n(x,n):
    '''
    TODO: document the IOs and functionality of this function
    '''
    if str(x)=='nan': return x
    if x==0: return x
    if type(x) is pd.core.series.Series and len(x) < 1: return 0
    x=float(x)
    power=-int(math.floor(math.log10(abs(x)))) + ( n - 1 )
    factor=(10**power)
    return round(x * factor)/factor


def prep_data(df, parameters, xaxis, yaxis, x2_list, y2_list, z2_list, z_minz, z_maxz, sampling=10):
    '''
    TODO: document the IOs and functionality of this function
    '''
    # pull out the axes values
    for parameter in parameters:
        x_in=list(df[xaxis].values)
        y_in=list(df[yaxis].values)
        z_in=df[parameter].values

        # convert to float, round the Z axis
        x_in=[float(i) for i in x_in]
        y_in=[float(i) for i in y_in]
        z_in=[round_to_n(i,4) for i in z_in]

        # Set the sampling in the two axes to 10 - we could parameterise this
        x_seq=np.linspace(min(x_in), max(x_in), sampling)
        y_seq=np.linspace(min(y_in), max(y_in), sampling)

        # create a meshgrid then use griddata to interpolate to the new grid
        x2,y2=np.meshgrid(x_seq,y_seq)
        z2=griddata((x_in, y_in), z_in, (x2,y2), method='cubic', rescale=True)
       
        x2_list.append(x2)
        y2_list.append(y2)
        z2_list.append(z2) 

        z_minz.append(np.nanmin(z_in))
        z_maxz.append(np.nanmax(z_in))
    return(x2_list, y2_list, z2_list, z_minz, z_maxz)


def plot_param_across_doe(df, devtype='', parameters='par1', xaxis="TFIN", yaxis="LG", fontsize=20, save_plot=True, device_or_circuit='device', pathprefix=None, cmap=True, df2=None, parameters2=None, zlabel=None, sampling=10):
    '''
    TODO: document the IOs and functionality of this function
    '''
    parameters = [parameters] if parameters is not None and not isinstance(parameters, list) else parameters
    parameters2 = [parameters2] if parameters2 is not None and not isinstance(parameters2, list) else parameters2

    cols=itertools.cycle(default_collist)

    # handle both devices and circuits
    if device_or_circuit=='device':
        df=df[df["devtype"]==devtype]
        if df2 is not None:
            df2=df2[df2["devtype"]==devtype]
    else:
        devtype=None

    # sort the DF before applying the griddata transform
    df=df.sort_values([xaxis,yaxis])
    if df2 is not None:
        df2=df2.sort_values([xaxis,yaxis])

    # create a 3d figure
    fig = plt.figure()
    ax=fig.add_subplot(1,1,1,projection='3d')
    z_minz=[]
    z_maxz=[]
    x2_list=[]
    y2_list=[]
    z2_list=[]

    x2_list, y2_list, z2_list, z_minz, z_maxz=prep_data(df, parameters, xaxis, yaxis, x2_list, y2_list, z2_list, z_minz, z_maxz, sampling=sampling)
    if df2 is not None:
        x2_list, y2_list, z2_list, z_minz, z_maxz=prep_data(df2, parameters2, xaxis, yaxis, x2_list, y2_list, z2_list, z_minz, z_maxz, sampling=sampling)


    for i in range(0, len(x2_list)):
        # plot the surface - many of these can be parameterised if needed
        if cmap:
            surf= ax.plot_surface(x2_list[i],y2_list[i],z2_list[i], rstride=1, cstride=1, cmap=cm.jet, linewidth=0.1, antialiased=True, vmin=min(z_minz), vmax=max(z_maxz))
        else:
            colour=cols.next()
            surf= ax.plot_surface(x2_list[i],y2_list[i],z2_list[i], rstride=1, cstride=1, color=colour, linewidth=0.1, antialiased=True, vmin=min(z_minz), vmax=max(z_maxz))


    # scale axes, making a lot of assumptions here
    # lets fix this up when (if?) we make it an internal module of enigma
    if "error" in " ".join(parameters):
        ax.set_zlim(-1, 8)
    else:
        ax.set_zlim(min(z_minz)-0.1*abs(min(z_minz)), max(z_maxz)+0.1*abs(max(z_maxz)))

    if zlabel:
       parameter=zlabel
    else:
       parameter=parameters[-1]

    if cmap:
        fig.colorbar(surf, shrink=0.3, aspect=10)
    ax.set_xlabel(xaxis, fontsize=fontsize)
    ax.set_ylabel(yaxis, fontsize=fontsize)
    ax.set_zlabel(parameter, fontsize=fontsize)

    # view angle, also needs initialised
    ax.view_init(30, 30)

    # axes labels
    for tl in ax.get_xticklabels():
        tl.set_fontsize(fontsize*0.5)
    for tl in ax.get_yticklabels():
        tl.set_fontsize(fontsize*0.5)
    for tl in ax.get_zticklabels():
        tl.set_fontsize(fontsize*0.5)

    if devtype:
        fig.suptitle("{0}MOS - {1}".format(devtype.strip("\""),parameter))
    else:
        fig.suptitle("{0}".format(parameter))

    # currently plt.show() alone won't work, as enigma wont let
    # matplotlib drop into interactive mode
    if pathprefix:
        p=os.path.abspath(pathprefix)+'/'
    else:
        p=''
    if save_plot:
        if devtype:
            plt.savefig("{2}{0}-{1}".format(devtype.strip("\""), parameter.replace('.','_'),p))
        else:
            plt.savefig("{1}{0}".format(parameter.replace('.','_'), p))
    else:
        plt.show()
    plt.close()


def multiplot_param_across_doe(df, devtype='', parameters='par1', xaxis="TFIN", yaxis="LG", fontsize=20, save_plot=True, device_or_circuit='device', pathprefix=None, cmap=True, zlabel=None, file_prefix=None, sampling=10, errorlims=10):
    '''
    TODO: document the IOs and functionality of this function
    '''
    parameters = [parameters] if parameters is not None and not isinstance(parameters, list) else parameters
    df = [df] if df is not None and not isinstance(df, list) else df
 
    print(parameters, xaxis, yaxis)
    

    cols=itertools.cycle(default_collist)

    # handle both devices and circuits
    if device_or_circuit=='device':
        df=df[df["devtype"]==devtype]
        if df2 is not None:
            df2=df2[df2["devtype"]==devtype]
    else:
        devtype=None

    # sort the DF before applying the griddata transform
    
    df=[d.sort_values([xaxis,yaxis]) for d in df]

    # create a 3d figure
    fig = plt.figure()
    ax=fig.add_subplot(1,1,1,projection='3d')
    z_minz=[]
    z_maxz=[]
    x2_list=[]
    y2_list=[]
    z2_list=[]

#    x2_list, y2_list, z2_list, z_minz, z_maxz=prep_data(df, parameters, xaxis, yaxis, x2_list, y2_list, z2_list, z_minz, z_maxz)
    for d in df:
        x2_list, y2_list, z2_list, z_minz, z_maxz=prep_data(d, parameters, xaxis, yaxis, x2_list, y2_list, z2_list, z_minz, z_maxz, sampling=sampling)


    for i in range(0, len(x2_list)):
        # plot the surface - many of these can be parameterised if needed
        if cmap:
            surf= ax.plot_surface(x2_list[i],y2_list[i],z2_list[i], rstride=1, cstride=1, cmap=cm.jet, linewidth=0.1, antialiased=True, vmin=min(z_minz), vmax=max(z_maxz))
        else:
            colour=cols.next()
            surf= ax.plot_surface(x2_list[i],y2_list[i],z2_list[i], rstride=1, cstride=1, color=colour, linewidth=0.1, antialiased=True, vmin=min(z_minz), vmax=max(z_maxz))


    # scale axes, making a lot of assumptions here
    # lets fix this up when (if?) we make it an internal module of enigma
    if "error" in " ".join(parameters):
        ax.set_zlim(0.0, errorlims)
    else:
        ax.set_zlim(min(z_minz)-0.1*abs(min(z_minz)), max(z_maxz)+0.1*abs(max(z_maxz)))

    if zlabel:
       parameter=zlabel
    else:
       parameter=parameters[-1]

    if cmap:
        fig.colorbar(surf, shrink=0.3, aspect=10)
    ax.set_xlabel(xaxis, fontsize=fontsize)
    ax.set_ylabel(yaxis, fontsize=fontsize)
    ax.set_zlabel(parameter, fontsize=fontsize)

    # view angle, also needs initialised
    ax.view_init(45, 45)

    # axes labels
    for tl in ax.get_xticklabels():
        tl.set_fontsize(fontsize*0.5)
    for tl in ax.get_yticklabels():
        tl.set_fontsize(fontsize*0.5)
    for tl in ax.get_zticklabels():
        tl.set_fontsize(fontsize*0.5)

    if devtype:
        fig.suptitle("{0}MOS - {1}".format(devtype.strip("\""),parameter))
    else:
        fig.suptitle("{0}".format(parameter))

    # currently plt.show() alone won't work, as enigma wont let
    # matplotlib drop into interactive mode
    if pathprefix:
        p=os.path.abspath(pathprefix)+'/'
    else:
        p=''
    if save_plot:
        if devtype:
            plt.savefig("{2}{0}-{1}.png".format(devtype.strip("\""), parameter.replace('.','_'),p))
        else:
            plt.savefig("{0}{1}{2}.png".format(p,file_prefix+"-",parameter.replace('.','_')))
    else:
        plt.show()
    plt.close()




def multiDimSurfaceMatrix(df_in, axes_labels, param, sampling=11,fontsize=20, outpath="./",prefix="node", errorplot=False, errorlims=10, cmap=True):

    if len(axes_labels) < 3:
        #print("axes < 3, useing traditional potting methods")
        multiplot_param_across_doe(df_in, devtype='', parameters=param, xaxis=axes_labels[0], yaxis=axes_labels[1], fontsize=20, save_plot=True, device_or_circuit='circuit', pathprefix=outpath, cmap=cmap, zlabel=None, file_prefix=prefix, sampling=sampling, errorlims=errorlims)

        return

    plotted_axes=[]
    for axes in permutations(axes_labels):


        stat_axis_samples=[]
        stat_axis_means=[]
    
        # only plot over 3 axes at a time
        if set(list(axes[:3])) not in plotted_axes:
    
            fig = plt.figure()
            ax=fig.add_subplot(1,1,1,projection='3d')
    
            a1=axes[0]
            a2=axes[1]
            a3=axes[2]
            rem_axes=axes[3:]
    
            plotted_axes.append(set(list(axes[:3])))
    
            a1_in=df_in[a1].values
            a1_seq=np.linspace(min(a1_in), max(a1_in), 11)
            a2_in=df_in[a2].values
            a2_seq=np.linspace(min(a2_in), max(a2_in), 11)
            a3_in=df_in[a3].values
            a3_min=np.min(a3_in)
            a3_med=np.median(a3_in)
            a3_max=np.max(a3_in)
    
            for m in rem_axes:
                stat_axis_samples.append(df_in[m].values)
                stat_axis_means.append(np.median(df_in[m].values))
        
            a1_1,a2_1=np.meshgrid(a1_seq,a2_seq)
        
            var_in=df_in[param].values
        
            z_vt0=griddata(tuple([a1_in, a2_in, a3_in]+stat_axis_samples), var_in, tuple([a1_1,a2_1,a3_min]+stat_axis_means), method='linear', rescale=True)
            z_vt1=griddata(tuple([a1_in, a2_in, a3_in]+stat_axis_samples), var_in, tuple([a1_1,a2_1,a3_med]+stat_axis_means), method='linear', rescale=True)
            z_vt2=griddata(tuple([a1_in, a2_in, a3_in]+stat_axis_samples), var_in, tuple([a1_1,a2_1,a3_max]+stat_axis_means), method='linear', rescale=True)
            
            zmin=np.nanmin(var_in)
            zmax=np.nanmax(var_in)

            surf= ax.plot_surface(a1_1,a2_1,z_vt0, rstride=1, cstride=1, cmap=cm.jet, linewidth=0.1, antialiased=True, vmin=zmin, vmax=zmax)
            surf= ax.plot_surface(a1_1,a2_1,z_vt1, rstride=1, cstride=1, cmap=cm.jet, linewidth=0.1, antialiased=True, vmin=zmin, vmax=zmax)
            surf= ax.plot_surface(a1_1,a2_1,z_vt2, rstride=1, cstride=1, cmap=cm.jet, linewidth=0.1, antialiased=True, vmin=zmin, vmax=zmax)
    
            if errorplot is True:
                ax.set_zlim(-1, errorlims)
            else:
                ax.set_zlim(np.nanmin(var_in)-0.1*abs(np.nanmin(var_in)), np.nanmax(var_in)+0.1*abs(np.nanmax(var_in)))

            if cmap:
                fig.colorbar(surf, shrink=0.3, aspect=10)

            ax.set_xlabel(a1, fontsize=fontsize)
            ax.set_ylabel(a2, fontsize=fontsize)
            ax.set_zlabel(param, fontsize=fontsize)
            # axes labels
            for tl in ax.get_xticklabels():
                tl.set_fontsize(fontsize*0.5)
            for tl in ax.get_yticklabels():
                tl.set_fontsize(fontsize*0.5)
            for tl in ax.get_zticklabels():
                tl.set_fontsize(fontsize*0.5)

            # view angle, also needs initialised
            ax.view_init(45, 30)
    
            fig.suptitle(f"{a1}-{a2}-{a3}-{param}")

            plt.show()
            plt.savefig(f"{prefix}{a1}_{a2}_{a3}_{param}")
            plt.close()




def CheckErrors(labels, abstol, reltol, axes_list=None, refdata=None, fitdata=None, outpath="", prefix="n"):

    absERROR=copy.deepcopy(refdata)
    relERROR=copy.deepcopy(refdata)

    for x,col in enumerate(labels):


        relERROR[col]=abs(100*(1-(fitdata[col]/refdata[col])))
        absERROR[col]=fitdata[col]-refdata[col]
        maxerr_rel=np.max(relERROR[col].values)
        maxerr_abs=np.max(absERROR[col].values)

        if maxerr_rel > reltol[x] or maxerr_abs > abstol[x]:
            if maxerr_rel > reltol[x]:
                print(f"Max error (rel) = {maxerr_rel} vs tolerance {reltol[x]} on {col}, saving surfaces.")
                multiDimSurfaceMatrix(relERROR, axes_list, col, sampling=11, outpath=outpath, prefix=f"{prefix}_relERROR_", errorplot=True, errorlims=maxerr_rel)
            else:
               print(f"Max error (abs) = {maxerr_abs} vs tolerance {abstol[x]} on {col}, saving surfaces.")
               multiDimSurfaceMatrix(absERROR, axes_list, col, sampling=11, outpath=outpath, prefix=f"{prefix}_absERROR_", errorlims=maxerr_abs)

            multiDimSurfaceMatrix(refdata,   axes_list, col, sampling=11, outpath=outpath, prefix=f"{prefix}_refdata_")
            multiDimSurfaceMatrix(fitdata, axes_list, col, sampling=11, outpath=outpath, prefix=f"{prefix}_fitdata_")

