#setdep @node|RO_Corner_Sim@

data=pd.DataFrame()

full_data=[]

nodes = dbi.get_project(swb__tool_label="RO_Corner_Sim")

corner = "tt"
#for corner in ["ss", "fs", "tt", "sf", "ff"]:
data=pd.DataFrame()
for node in nodes:

    isplit=node.metadata["swb"]["isplit"]
    data0=[d.data for d in dbi.get_data(project=node.name, dataset=f"{node.name}_RO_{corner}", strip=False)]
    data0[0]['isplit']=[isplit]
    data0=[{k:v[0] for k,v in data0[0].items()}]
    pex_doe = node.metadata["pex_doe"]
    data0[0].update(pex_doe)
    print(data0)
    data0=pd.DataFrame(data0)
    
    data=pd.concat([data,data0])
    print(data)

with open(f"n@node@_{corner}_@logic@X@strength@@height@.csv", 'w') as f:
    data.to_csv(f)

data.drop(["index", "isplit", "ileak"], axis=1, inplace=True)
data=data[list(pex_doe.keys())+["stage_delay","stage_energy"]]
plotter._dist_data=[data]
plotter.plot_scatter_matrix()

############################################################################
#
############################################################################
import pickle

from common.optimisers.rsm import RSM
from common.optimisers.Parameter import OptParam
from common.optimisers.linear_regression import ordinary_least_squares
from prettytable import PrettyTable


def get_quadratic_rsm(points, values):
    points = np.atleast_2d(points)
    lb = np.min(points, axis=0)
    ub = np.max(points, axis=0)

    # scale input [-1, 1]
    spoints = 2 * (points - lb[None, :]) / (ub[None, :] - lb[None, :]) - 1.0

    # scale output [0, 1]
    vmin = np.min(values)
    vmax = np.max(values)
    if vmax == vmin:
        svalues = values
    else:
        svalues = (values - vmin) / (vmax - vmin)


    order = 2
    beta, seb, t_st, p_val, r2, adj_r2, mse, msm, aic, terms =  \
            ordinary_least_squares(spoints, svalues, order=order)
    pt = PrettyTable()
    pt.add_column("r2", [r2])
    pt.add_column("r2Adj", [adj_r2])
    pt.add_column("MSE", [mse])
    pt.add_column("AICc", [aic])
    print(f"\nStatistics for polynomial regression (order {order}):")
    print(pt)
    # for t, b in zip(terms, beta):
    #     print(t, b)

    print("Lower bound for RSM:")
    print(lb)
    print("Upper bound for RSM:")
    print(ub)

    ndim = points.shape[1]
    params = [OptParam(f"p{i}", spoints[0, i], -1, 1) for i in range(ndim)]
    rsm = RSM(params, beta, order, [False]*ndim, terms, [lb, ub])
    print(rsm.beta)
    #rsm.beta = rsm.beta.T


    def unscale_rsm(rsm, vmin, vmax):
        def ursm(x, *args, **kwargs):
            x = np.atleast_2d(x)
            npoints = x.shape[0]
            if npoints == 1:
                x = np.vstack((np.zeros_like(x), x))
                v = np.array([rsm(x, *args, **kwargs)[1]])
            else:
                v = np.array(rsm(x, *args, **kwargs))
            if vmax == vmin:
                 return v
            else:
                 return v * (vmax - vmin) + vmin
        return ursm

    ursm = unscale_rsm(rsm, vmin, vmax)

    return ursm

# preprocess the data
refdata     = data

# quad rsm
f       = get_quadratic_rsm(refdata[["fin_width","gate_recess","poly_mandrel_bias","poly_sadp_spacer_thk","poly_spacer2_thk","sdc_recess"]].as_matrix(),
                            refdata[["stage_delay"]].as_matrix().ravel())
f2       = get_quadratic_rsm(refdata[["fin_width","gate_recess","poly_mandrel_bias","poly_sadp_spacer_thk","poly_spacer2_thk","sdc_recess"]].as_matrix(),
                            refdata[["stage_energy"]].as_matrix().ravel())

# resample the interpolator
spacing = 7
x_seq=np.linspace(np.min(refdata["fin_width"]), np.max(refdata["fin_width"]), spacing)
y_seq=np.linspace(np.min(refdata["gate_recess"]), np.max(refdata["gate_recess"]), spacing)
z_seq=np.linspace(np.min(refdata["poly_mandrel_bias"]), np.max(refdata["poly_mandrel_bias"]), spacing)
a_seq=np.linspace(np.min(refdata["poly_sadp_spacer_thk"]), np.max(refdata["poly_sadp_spacer_thk"]), spacing)
b_seq=np.linspace(np.min(refdata["poly_spacer2_thk"]), np.max(refdata["poly_spacer2_thk"]), spacing)
c_seq=np.linspace(np.min(refdata["sdc_recess"]), np.max(refdata["sdc_recess"]), spacing)

X1,Y1,Z1,A1,B1,C1	= np.meshgrid(x_seq, y_seq, z_seq, a_seq, b_seq, c_seq)

final_df=pd.DataFrame()

xs = range(X1.shape[0])

i=0
for x in xs:
    for y in xs:
        for z in xs:
            for a in xs:
                for b in xs:
                    for c in xs:
                        final_df.loc[i,"fin_width"] = X1[x,y,z,a,b,c]
                        final_df.loc[i,"gate_recess"] = Y1[x,y,z,a,b,c]
                        final_df.loc[i,"poly_mandrel_bias"] = Z1[x,y,z,a,b,c]
                        final_df.loc[i,"poly_sadp_spacer_thk"] = A1[x,y,z,a,b,c]
                        final_df.loc[i,"poly_spacer2_thk"] = B1[x,y,z,a,b,c]
                        final_df.loc[i,"sdc_recess"] = C1[x,y,z,a,b,c]
                        final_df.loc[i,"stage_delay"]=f(np.array([X1[x,y,z,a,b,c],Y1[x,y,z,a,b,c],Z1[x,y,z,a,b,c],A1[x,y,z,a,b,c],B1[x,y,z,a,b,c],C1[x,y,z,a,b,c]]))
                        final_df.loc[i,"stage_energy"]=f2(np.array([X1[x,y,z,a,b,c],Y1[x,y,z,a,b,c],Z1[x,y,z,a,b,c],A1[x,y,z,a,b,c],B1[x,y,z,a,b,c],C1[x,y,z,a,b,c]]))
                        i=i+1

print(final_df)
plotter._dist_data=[final_df, data]
plotter.plot_scatter_matrix(filename="rsm-combined", multiplot=True)




############################################################################
#
############################################################################


from plt3d_helpers import multiDimSurfaceMatrix
multiDimSurfaceMatrix(final_df, list(pex_doe.keys()), "stage_delay", sampling=7, outpath="@pwd@/@nodedir@/", prefix="n@node@_RespSurf_nmos_@sim_temp@")



