#setdep @node|FinalSims@

import matplotlib.pyplot as plt
from plt3d_helpers import prep_data

iread = pd.DataFrame(dbi.get_project("@node|FinalSims@").metadata["iread_df"])

iread.replace('failed',0, inplace=True)
iread["iread"] = np.log10(iread["iread"])
iread.sort_values(['vddc','vddp'], inplace=True)
iread.to_csv("n@node@_MPV_iread.csv")

X, Y, Z, z_minz, z_maxz =prep_data(iread, ["iread"], "vddc", "vddp", [], [], [], [], [], sampling=21)


import matplotlib
import matplotlib.ticker as ticker
import matplotlib.pyplot as plt
from matplotlib import cm

for measure in ["iread"]:

    contours = np.linspace(-6,-3.3,21)
    fcontours = np.linspace(-6,-3.3,201)
    #cbar = [0.0,0.01,0.02,0.03,0.04,0.05,0.06,0.07,0.08]

    plt.clf()
    fig, ax = plt.subplots(constrained_layout=True)
    CS0 = ax.contourf(X[0],Y[0],Z[0], levels=fcontours, cmap="jet")
    CS = ax.contour(X[0],Y[0],Z[0], levels=contours, colors="black", linewidths=1.0,  linestyles="dashed")
    ax.clabel(CS, colors='black', fontsize=12)
    cbar = fig.colorbar(CS0, ax=ax)
    cbar.ax.set_ylabel(r"viread (@iread@, @sim_temp@C, @targetSigma@$\sigma$)", fontsize=16)
    cbar.ax.tick_params(labelsize=16)
    #cbar.set_clim(0,2.5)
    ax.set_xlabel("VDDC (V)", fontsize=20)
    ax.set_ylabel("VDDP (V)", fontsize=20)
    #plt.grid()
    plt.savefig(f"n@node@_2d{measure}")
