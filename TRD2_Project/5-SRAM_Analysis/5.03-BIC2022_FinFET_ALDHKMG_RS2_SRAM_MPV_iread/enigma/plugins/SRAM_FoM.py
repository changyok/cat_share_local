from scipy.interpolate import interp1d  
import numpy as np

def calcSNM(sweep1, sweep2, xcol="vcored", ycol="vncored"):
    
    s1 = sweep1.reset_index()
    s2 = sweep2.reset_index()

    if xcol not in s1.columns.values:
        raise ValueError(f"xcol={xcol} not found in sweep1: {s1}")
    elif xcol not in s2.columns.values:
        raise ValueError(f"xcol={xcol} not found in sweep1: {s2}")
    elif ycol not in s1.columns.values:
        raise ValueError(f"ycol={ycol} not found in sweep1: {s1}")
    elif ycol not in s2.columns.values:
        raise ValueError(f"ycol={ycol} not found in sweep1: {s2}")

    sl = np.array([s1[xcol], s1[ycol]])
    sr = np.array([s2[xcol], s2[ycol]])
    

    ## Rotate by 45 degrees
    rot = np.array([[np.cos(np.pi/4), -np.sin(np.pi/4)], [np.sin(np.pi/4), np.cos(np.pi/4)]])

    rsl = np.dot(rot, sl).transpose()
    rsr = np.dot(rot, sr).transpose()

    isl = interp1d(rsl[:,0], rsl[:,1])
    isr = interp1d(rsr[:,0][::-1], rsr[:,1][::-1])

    x = np.linspace(min(rsr[:,0]), max(rsl[:,0]), num=500)
    try:
        d = isl(x) - isr(x)
    except ValueError:
        return 0,0,0
   
    import itertools
    xoverpoints = len(list(itertools.groupby(d, lambda d: d > 0)))
    if xoverpoints > 4:
        return 0,0,0

    if max(d[:int(len(d)/2)]) > 0.0 and min(d[int(len(d)/2):]) > 0.0:
        snm1 = 0
        snm2 = 0
    elif max(d[:int(len(d)/2)]) < 0.0 and min(d[int(len(d)/2):]) < 0.0:
        snm1 = 0
        snm2 = 0
    else:
        snm1 = abs(max(d[:int(len(d)/2)])/np.sqrt(2))
        snm2 = abs(min(d[int(len(d)/2):])/np.sqrt(2))

    snm = np.min([snm1, snm2])

    return snm1, snm2, snm
