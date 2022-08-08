#setdep @node|RO_Corner_Sim:all@
from libfromage.frontend import DBException

results_projects = "@node|RO_Corner_Sim:all@".split()

results_df = pd.DataFrame()

if @Corners_TX@ == True:
    corners  = ["ss", "tt", "ff"]
else:
    corners  = ["tt"]

for proj in results_projects:
    try:
        proj = dbi.get_project(proj)
    except DBException:
        continue

    for corner in corners:
        d=dbi.get_dataset(f"{proj.name}_RO_{corner}")

        data=[d.data for d in dbi.get_data(project=proj.name, dataset=f"{proj.name}_RO_{corner}", strip=False)]

        data=pd.DataFrame(data[0])

        data.reset_index(drop=True, inplace=True)
        for x in range(len(data)):
            data.loc[x,"vt_mode"]=proj.metadata["swb"]["vt_mode"]
            data.loc[x,"logic"]=proj.metadata["swb"]["logic"]
            data.loc[x,"strength"]=proj.metadata["swb"]["strength"]
            data.loc[x,"height"]=proj.metadata["swb"]["height"]
            data.loc[x,"temperature"]=proj.metadata["swb"]["sim_temp"]
            data.loc[x,"nstage"]=proj.metadata["swb"]["nstage"]
            data.loc[x,"FO"]=proj.metadata["swb"]["FO"]
            data.loc[x,"Rinter"]=proj.metadata["swb"]["Rinter"]
            data.loc[x,"Cinter"]=proj.metadata["swb"]["Cinter"]
            data.loc[x,"Corners_PEX"]=proj.metadata["swb"]["Corners_PEX"]
            data.loc[x,"corner"]=corner

        results_df = pd.concat([results_df, data])

results_df.rename({"index":"Vdd"}, inplace=True, axis=1)
results_df.reset_index(inplace=True, drop=True)
print(results_df)

with open(f"full_RO_data.csv", 'w') as f:
    results_df.to_csv(f)

results_df=results_df.replace("fail", np.nan)
results_df.dropna(inplace=True)


## example plot generated by python
## create a stage_delay/ptot curve for each cell in one plot
import matplotlib.pyplot as plt
import itertools as it
import copy

figure = plt.figure()
ax = figure.add_subplot(111)


vt_modes	= list(set(results_df["vt_mode"]))
logics		= list(set(results_df["logic"])) 
strengths	= list(set(results_df["strength"]))
heights		= list(set(results_df["height"]))
temperatures    = list(set(results_df["temperature"]))
corners         = list(set(results_df["corner"]))

vt_mode_cols = it.cycle(["k","r"])
temp_symbols = it.cycle(["x","o","."])
cell_type_lines = it.cycle(["-","--",":"])

for vt_mode in vt_modes:
   col = next(vt_mode_cols)
   for temperature in temperatures:
      symb = next(temp_symbols)
      for logic in logics:
          line = next(cell_type_lines)
          for strength in strengths:
              for height in heights:
                  plot_data = copy.copy(results_df)
                  print(plot_data)
                  plot_data = plot_data[(plot_data["vt_mode"] == vt_mode) & (plot_data["temperature"] == temperature) & 
                                        (plot_data["logic"] == logic) & (plot_data["strength"] == strength) & (plot_data["height"] == height)]
                  if len(plot_data)>0:
                     for x,corner in enumerate(corners):
                         fin_data = plot_data[plot_data["corner"] == corner]
                         # add line to plot
                         if x==0:
                             ax.plot(fin_data["stage_delay"].values, fin_data["stage_energy"].values, f"{col}{symb}{line}", label=f"{logic}x{int(strength)}{height}_{vt_mode}_{temperature}C")
                         else:
                             ax.plot(fin_data["stage_delay"].values, fin_data["stage_energy"].values, f"{col}{symb}{line}")

plt.xlabel('Stage delay')
plt.ylabel('Stage_energy')
plt.xscale('log')
plt.tight_layout()
plt.grid(which='both')
plt.legend(loc='upper right')
plt.savefig('n@node@_delay_power.png')


######### plot all cells for one VT mode

for vt_mode in vt_modes:

    for temperature in temperatures:
        plt.clf()
        ax = figure.add_subplot(111)
        logic_cols = it.cycle(["k","r",'g'])
        strength_symbols = it.cycle(["x","o"])
        height_lines = it.cycle(["-","--",":"])

        for logic in logics:
            col = next(logic_cols)
            for strength in strengths:
                symb = next(strength_symbols)
                for height in heights:
                    line = next(height_lines)
                    plot_data = copy.copy(results_df)
                    print(plot_data)
                    plot_data = plot_data[(plot_data["vt_mode"] == vt_mode) & (plot_data["temperature"] == temperature) & 
                                          (plot_data["logic"] == logic) & (plot_data["strength"] == strength) & (plot_data["height"] == height)]
                    print(plot_data)
                    if len(plot_data)>0:
                        for x,corner in enumerate(corners):
                            fin_data = plot_data[plot_data["corner"] == corner]
                            # add line to plot
                            if x==0:
                                ax.plot(fin_data["stage_delay"].values , fin_data["stage_energy"].values, f"{col}{symb}{line}", label=f"{logic}x{int(strength)}{height}_{vt_mode}_{temperature}C")
                            else:
                                ax.plot(fin_data["stage_delay"].values , fin_data["stage_energy"].values, f"{col}{symb}{line}")

        plt.title(f"Vt_mode={vt_mode}, temp.={temperature}C")
        plt.xlabel('Stage delay')
        plt.ylabel('Stage_energy')
        plt.xscale('log')
        plt.tight_layout()
        plt.grid(which='both')
        plt.legend(loc='upper right')
        plt.savefig(f'n@node@_delay_power_{vt_mode}_{temperature}.png')

