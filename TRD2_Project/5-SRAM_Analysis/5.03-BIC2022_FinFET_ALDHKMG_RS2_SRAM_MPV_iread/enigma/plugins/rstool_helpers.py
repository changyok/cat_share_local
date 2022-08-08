# Synopsys tool imports

def parallelise_randomspice(randomspice, dbi, num=1000, per_job=100, dataset_name="dummy_name"):
    ''' 
    parallelise runs for speedup

    randomspice : Randomspice object
    dbi : DatabaseInterface object
    num	: overall number of circuits to simulate
    pre_job : number of circuit sims per job
    dataset_name : base dataset name. For each subjob the datasets will be named "dataset_name-{N}"

    '''
    if num < per_job:
        numProc=1
        remainder=0
        step=num
    else:
        numProc = int(int(num)/int(per_job))
        remainder = num%numProc
        step = (num-remainder)/numProc

    print(numProc, type(numProc))
    for x in range(1,numProc+1):
    # cleanup the old data
        dsname="{0}-{1}".format(dataset_name, x)
        try:
            dbi.delete_dataset(dsname)
        except:
            pass

        startnum=(x-1)*step+1
        number=step
        randomspice.inputfile._options["database"]["dataset"]=dsname
        randomspice.inputfile._options["circuit"]["startnum"]=int(startnum)
        randomspice.inputfile._options["circuit"]["number"]=int(step)
        randomspice.simulate()

    if remainder > 0:
        numProc+=1
        dsname="{0}-{1}".format(dataset_name, numProc)
        try:
            dbi.DeleteDataset(dsname)
        except DatasetError:
            pass

        startnum=numProc*step+1
        number=remainder
        randomspice.inputfile._options["database"]["dataset"]=dsname
        randomspice.inputfile._options["circuit"]["startnum"]=int(startnum)
        randomspice.inputfile._options["circuit"]["number"]=int(step)
        randomspice.simulate()
  

    return dbi, randomspice, numProc
