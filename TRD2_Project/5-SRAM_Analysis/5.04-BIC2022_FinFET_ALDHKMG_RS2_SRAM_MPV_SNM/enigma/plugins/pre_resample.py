import numpy as np
import pandas as pd
from scipy.interpolate import LinearNDInterpolator


def resample_df(source, axes,  sampling=5):
    # param setup
    axes_in = []
    axes_new = []
    interpolators = {}
    fin_df = pd.DataFrame()
    to_resample = list(set(source.columns)-set(axes))

    # extract axis coords
    for axis in axes:
        axes_in.append(source[axis].values)
        axes_new.append(np.linspace(np.min(source[axis].values), np.max(source[axis].values), sampling))

    # create DF with interpolated axis values
    meshgrid = np.array(np.meshgrid(*axes_new))
    coords = np.vstack(meshgrid.T)
    for x in range(len(axes)):
        fin_df[axes[x]] = coords.T[x]

    # build interpolators for each axis
    for par in to_resample:
        par_vals = source[par].values
        interpolators[par] = LinearNDInterpolator(list(zip(*axes_in)), par_vals, rescale=True)

    # resample each paraemter to the new sampling
    for par in to_resample:
        x=0
        for coord in coords:
            fin_df.loc[x,par]=interpolators[par](*coord)
            x+=1

    # drop nans where we couldn't interpolate
    fin_df.dropna(inplace=True)

    return fin_df, to_resample

