#setdep @node|FinalSims@

import matplotlib.pyplot as plt
from plt3d_helpers import prep_data

write = pd.DataFrame(dbi.get_project("@node|FinalSims@").metadata["write_df"])

write.replace('failed',0, inplace=True)
print(write)
write.sort_values(['vddc','vddp'], inplace=True)
write.to_csv("n@node@_MPV_Vwrite.csv")

X, Y, Z, z_minz, z_maxz =prep_data(write, ["write"], "vddc", "vddp", [], [], [], [], [], sampling=21)


import matplotlib
import matplotlib.ticker as ticker
import matplotlib.pyplot as plt
from matplotlib import cm

for measure in ["write"]:

    contours = np.linspace(0,0.4,21)
    fcontours = np.linspace(0,0.4,201)
    #cbar = [0.0,0.01,0.02,0.03,0.04,0.05,0.06,0.07,0.08]

    plt.clf()
    fig, ax = plt.subplots(constrained_layout=True)
    CS0 = ax.contourf(X[0],Y[0],Z[0], levels=fcontours, cmap="jet")
    CS = ax.contour(X[0],Y[0],Z[0], levels=contours, colors="black", linewidths=1.0,  linestyles="dashed")
    ax.clabel(CS, colors='black', fontsize=12)
    cbar = fig.colorbar(CS0, ax=ax)
    cbar.ax.set_ylabel(r"vwrite (@write@, @sim_temp@C, @targetSigma@$\sigma$)", fontsize=16)
    cbar.ax.tick_params(labelsize=16)
    #cbar.set_clim(0,2.5)
    ax.set_xlabel("VDDC (V)", fontsize=20)
    ax.set_ylabel("VDDP (V)", fontsize=20)
    #plt.grid()
    plt.savefig(f"n@node@_2d{measure}")
