
import numpy as np
import pandas as pd
from libsaucisson.PlotData import Plotter
from scipy import interpolate as interp
from scipy import optimize
from itertools import product

'''
simple PCA calculation method,
will also calculate the X-sigma points
in the PCA axes.
'''
def PCA_Points(xdata, ydata, sigma_extr=3):
    # convert data to coordinate pairs
    data=np.hstack((xdata, ydata))

    # convert data to mean shifts
    mu=data.mean(axis=0)
    data=data-mu
 
    # calculate the SVD
    eigenvectors, eigenvalues, V = np.linalg.svd(data.T, full_matrices=False)
    projected_data=np.dot(data, eigenvectors)
    sigma= projected_data.std(axis=0)

    coords=[]
    for x,axis in enumerate(eigenvectors):
        start1, end1 = mu , mu + sigma[x] * axis * sigma_extr
        start2, end2 = mu - sigma[x] * axis *sigma_extr , mu 
        coords.append((start1[0],start1[1]))
        coords.append((end1[0],end1[1]))
        coords.append((start2[0],start2[1]))
        coords.append((end2[0],end2[1])) 
    return list(set(coords))


'''
Apply the PCA analysis to the dataframe.
Also produces png plots.
Also saves CSV data from plotting in svisual
'''
def DF_PCA(xdf, ydf, xname, yname, plotname, extra_points=None, output_csv=False, sigma_extr=3):
    df=pd.concat([xdf[[xname]], ydf[[yname]]],axis=1)
    df.dropna(inplace=True)
    a = PCA_Points(df[[xname]], df[[yname]], sigma_extr=sigma_extr)
    a=pd.DataFrame(a)
    a.columns=[xname, yname]
    plotter=Plotter()
    plotter._dist_data.append(df[[xname, yname]])
    plotter._dist_data.append(pd.DataFrame(a))
    if extra_points is not None:
        plotter._dist_data.append(extra_points)
    plotter.plot_xy_scatter(filename=plotname, multiplot=True, aspect=1)
    if output_csv:
        for x,f in enumerate(plotter._dist_data):
            f.to_csv(plotname+"-{0}.csv".format(x), index=False)
    plotter.reset_data()
    return a

'''
sorts corners based on type (v) or (i)
'''
def corner_sort(c_list, fom_type):
    # if fom_type = "i", higher -> Fast
    # if fom_type = "v", higher -> Slow
    xname = c_list.columns[0]
    yname = c_list.columns[1]

    c_list.columns=["x","y"]
    if fom_type=="v":
        c_list=c_list.sort_values(by=["x","y"], ascending=False)
    elif fom_type=="i":
        c_list=c_list.sort_values(by=["x","y"], ascending=True)
    c_list.index=['ss','sf','tt','fs','ff']
    c_list.columns=[xname,yname]
    return c_list


class DoESurface(object):

    def __init__(self, df, corner=None, err_scaling_list=None, verbose=True, a_scale_factors=None, target_err=1e-3):

        self._interps = {}	
        self._scaling_factors = {}
        self._means = [np.mean(d) for d in df.index.levels]
        self._dummy_params =  [1 for d in df.index.levels]
        self.target_err = target_err
        self._verbose = verbose
        self._corner = corner

        # setting up axis-scaling factors
        if a_scale_factors is not None:
            self._a_scale_factors = a_scale_factors
            self._dummy_params = self._a_scale_factors
        else:
            self._a_scale_factors =  [1 for d in df.index.levels]

        # setup then interpolated surfaces
        for col in df.columns:
            df2=df[col].dropna()
            self._interps[col] = interp.LinearNDInterpolator(df2.index.tolist(), df2.values.tolist(), fill_value=1e9)
            if corner is not None:
                if err_scaling_list is not None:
                    self._setup_scaling_function(err_scaling_list, df)

    # convert scaling list to a dict for easy access
    def _setup_scaling_function(self, err_scaling_list, df):
        if len(err_scaling_list) != len(df.columns):
             raise ValueError(f"Cannot scale {len(df.columns)} columns with scaling list of length {len(err_scaling_list)}")
        for x,i in enumerate(df.columns):
            self._scaling_factors[i]=err_scaling_list[i]
        print(df.columns, self._scaling_factors)

    # error function
    def _err_func(self, arr):
        arr = arr*self._means/self._a_scale_factors
        err = np.sqrt(np.sum([self._scaling_factors[opt]*abs(1-self._interps[opt](arr)/self._corner[opt])**2 for opt in self._interps]))

        if str(err) == 'nan':
            err=1e6
        if self._verbose:
            print(arr, err)
        return err 

    # find optimal point, will update to the optimiser library soon
    def find_optimal_point(self, cols=None, method='COBYLA'):

        cols = cols if cols is not None else self._interps.keys()
        success=False
        tries=0
        opt_err=1e99
        rhobeg=1e-5
        results_dict={}
        while (tries<8 and opt_err>self.target_err):
            tries+=1
            if self._verbose: print("MESSAGE: Try={0}, rhobeg={1}.".format(tries, rhobeg))
            err = optimize.minimize(self._err_func, self._dummy_params, method=method, options={'disp':False, 'tol':1e-9, 'rhobeg':rhobeg, 'maxiter':10000})
            print(err.keys(), err.fun)
            success=err.success
            opt_err=err.fun
            results_dict[rhobeg]=err
            rhobeg*=10

        min_e_val=1e99
        min_err=None
        for r,e in results_dict.items():
            if e.fun < min_e_val:
                min_e_val=e.fun
                min_err=e

        return min_err.x*self._means/self._a_scale_factors

	
    def get_point(self, coords, col=None):
        cols = [col] if col is not None else self._interps.keys()
        df = pd.DataFrame(columns=cols)
        for col in cols:
            df[col] = self._interps[col](coords)
        
        return df




class DoESurface2(object):

    def __init__(self, df, corner=None, err_scaling_list=None, verbose=False, sampling=3, target_err=0.05):
    
        self._interps = {}
        self._corner = corner
        self._scaling_factors = {}
        self._verbose = verbose
        self._df = df
        self._sampling = sampling
        self._target_err= target_err

        if err_scaling_list is not None:
            self._setup_scaling_function(err_scaling_list, df)
      

    # error function
    def _err_func(self, arr):
        # arr = arr*self._means/self._a_scale_factors
        err = np.sqrt(np.sum([self._scaling_factors[opt]*abs(1-self._interps[opt](arr)/self._corner[opt])**2 for opt in self._interps]))

        if str(err) == 'nan':
            err=1e6
        if self._verbose:
            print(arr, err)
        return err 



    # convert scaling list to a dict for easy access
    def _setup_scaling_function(self, err_scaling_list, df):
        if len(err_scaling_list) != len(df.columns):
             raise ValueError(f"Cannot scale {len(df.columns)} columns with scaling list of length {len(err_scaling_list)}")
        for x,i in enumerate(df.columns):
            self._scaling_factors[i]=err_scaling_list[i]
        print(df.columns, self._scaling_factors)

        # setup then interpolated surfaces
        for col in df.columns:
            df2=df[col].dropna()
            self._interps[col] = interp.LinearNDInterpolator(df2.index.tolist(), df2.values.tolist(), fill_value=1e9)


    def explicit_solve(self):
        
        result_df=pd.DataFrame()
        axis_ranges=[]
        for level in self._df.index.levels:
            data = level.data
            axis_ranges.append(np.linspace(np.min(data), np.max(data), self._sampling))

        errdict={}
        for i,ax in enumerate(product(*axis_ranges)):
            
            err = self._err_func(ax)
            if err < self._target_err:
                return(ax)

            errdict[ax]=self._err_func(ax)

        #print(pd.DataFrame.from_dict(errdict, orient="columns"))
        pd_df = pd.DataFrame.from_dict(errdict, orient="index").sort_values(0)
        print(pd_df)
        print(pd_df.iloc[0,0])
        print(pd_df.index.values[0])
        return(pd_df.index.values[0])

    def get_point(self, coords, col=None):
        cols = [col] if col is not None else self._interps.keys()
        df = pd.DataFrame(columns=cols)
        print(df)
        for col in cols:
            print(col, self._interps[col](coords))
            df[col] = [float(self._interps[col](coords))]
        
        return df
  
 


