
from io import StringIO
import re
import pandas as pd
import numpy as np
from libfromage.data.data import round_sig_fig

from common.SPICE.simulator import SimulationResult

rmonte = re.compile(r"monte\s+carlo\s*index\s*=\s*(\d+).+?^\s*\*+\s*", re.M|re.S)
ralter = re.compile(r"^\s*\*+\s*option\s+summary.+?^\s*\*+\s+job\s+concluded", re.M|re.S)

def _read_block(self, block, index=None):
    sio = StringIO(block)
    df = pd.read_csv(sio, sep=r"\s+", dtype=str)
    sio.close()
    d0 = df.iloc[0]

    cols = [df.columns[0]]
    for i,c in enumerate(df.columns[1:]):
        try:
            cols.append(f"{int(d0[i])} {c.split('.')[0]}")
        except ValueError:
            cols.append(f"{d0[i]} {c.split('.')[0]}")

    df.columns = cols
    df = df.drop(0).astype(float).reset_index(drop=True)
    if index is not None:
        df["ensemble_id"] = index
        
    return df

def _parse_lis(self, filename):
    with open(filename) as f:
        text = f.read()
        self.lis_txt = text
    
    def f(x):
        return np.array([round_sig_fig(xi, 8) for xi in x])
    
    mc_blocks = list(self.rmonte.finditer(text))
    alt_blocks = list(self.ralter.finditer(text))
    if mc_blocks:
        outputs = []
        for mb in mc_blocks:
            index = int(mb.group(1))
            blocks = list(self.rlis.finditer(mb.group(0)))
            if blocks:
                dfs = []
                for b in blocks:
                    dfs.append(self._read_block(b.group(1), index=index)) 
                combi = pd.concat(dfs, axis=1).apply(f)
                combi = combi.loc[:,~combi.columns.duplicated()]
                outputs.append(combi)
        self.outputs = pd.concat(outputs, axis=0)
    elif alt_blocks:
        outputs = []
        for ab in alt_blocks:
            blocks = list(self.rlis.finditer(ab.group(0)))
            if blocks:
                dfs = []
                for b in blocks:
                    dfs.append(self._read_block(b.group(1))) 
                combi = pd.concat(dfs, axis=1).apply(f)
                combi = combi.loc[:,~combi.columns.duplicated()]
                outputs.append(combi)
        if len(outputs) > 1:
            self.outputs = outputs
        elif len(outputs) == 1:
            self.outputs = outputs[0]
    else:
        blocks = list(self.rlis.finditer(text))
        if blocks:
            dfs = []
            for b in blocks:
                dfs.append(self._read_block(b.group(1)))
            self.outputs =  pd.concat(dfs, axis=1).apply(f)

    errors = list(self.rerr.finditer(text))
    if errors:
        if self.errors is None:
            self.errors = []
        self.errors.extend([e.group(1) for e in errors])

    warnings = list(self.rwarn.finditer(text))
    if warnings:
        self.warnings = [w.group(1) for w in warnings]
        
print("patching .alter parsing")

SimulationResult.rmonte = rmonte   
SimulationResult.ralter = ralter
SimulationResult._read_block = _read_block
SimulationResult._parse_lis = _parse_lis
        
        
 
